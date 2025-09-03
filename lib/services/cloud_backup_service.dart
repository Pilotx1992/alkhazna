import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:pointycastle/key_derivators/api.dart';
import 'package:pointycastle/key_derivators/pbkdf2.dart';
import 'package:pointycastle/macs/hmac.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:archive/archive_io.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'storage_service.dart';
import 'advanced_compression_service.dart';

class CloudBackupMetadata {
  final String id;
  final String name;
  final DateTime createdAt;
  final int size;
  final String userId;
  final String deviceInfo;
  final String appVersion;

  CloudBackupMetadata({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.size,
    required this.userId,
    required this.deviceInfo,
    required this.appVersion,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'size': size,
      'userId': userId,
      'deviceInfo': deviceInfo,
      'appVersion': appVersion,
    };
  }

  factory CloudBackupMetadata.fromMap(Map<String, dynamic> map) {
    return CloudBackupMetadata(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      size: map['size'] ?? 0,
      userId: map['userId'] ?? '',
      deviceInfo: map['deviceInfo'] ?? '',
      appVersion: map['appVersion'] ?? '',
    );
  }
}

class CloudBackupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  static const String _deviceIdKey = 'device_backup_id';

  encrypt.Key _deriveKey(String password, Uint8List salt) {
    final derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(salt, 100000, 32)); // Increased to 100,000 iterations for better security
    return encrypt.Key(
        derivator.process(Uint8List.fromList(password.codeUnits)));
  }

  /// Legacy key derivation for backward compatibility with old backups.
  encrypt.Key _deriveKeyLegacy(String password, Uint8List salt) {
    final derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(salt, 1000, 32)); // Original 1000 iterations
    return encrypt.Key(
        derivator.process(Uint8List.fromList(password.codeUnits)));
  }

  Future<String> _getOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Try to get existing device ID first
    String? deviceId = prefs.getString(_deviceIdKey);
    
    if (deviceId == null || deviceId.isEmpty) {
      // Create a device fingerprint based on device characteristics
      // This will be consistent across reinstalls on the same device
      deviceId = await _createDeviceFingerprint();
      
      // Save it for faster access next time
      await prefs.setString(_deviceIdKey, deviceId);
    }
    
    return deviceId;
  }

  Future<String> _createDeviceFingerprint() async {
    // Create a device fingerprint based on available device characteristics
    // This should remain consistent across app reinstalls
    
    try {
      // Use device information to create a consistent ID
      final deviceInfo = Platform.operatingSystem;
      final locale = Platform.localeName;
      
      // Create a hash-like string from available information
      final combined = '${deviceInfo}_${locale}_android_emulator';
      final hash = combined.hashCode.abs();
      
      return 'device_fp_$hash';
    } catch (e) {
      // Fallback to a simple but consistent approach
      return 'device_fallback_${Platform.operatingSystem.hashCode.abs()}';
    }
  }

  Future<void> _migrateOldBackupsIfNeeded() async {
    try {
      // Check if user has Firebase auth backups that need migration
      if (_auth.currentUser != null) {
        final user = _auth.currentUser!;
        final deviceId = await _getOrCreateDeviceId();
        
        // Skip if device ID is same as user UID (no migration needed)
        if (deviceId.contains(user.uid)) return;
        
        // Check if old backups exist
        final oldBackupsQuery = await _firestore
            .collection('backups')
            .doc(user.uid)
            .collection('user_backups')
            .get();
        
        if (oldBackupsQuery.docs.isEmpty) return;
        
        // Check if new location already has backups (avoid duplicate migration)
        final newBackupsQuery = await _firestore
            .collection('backups')
            .doc(deviceId)
            .collection('user_backups')
            .limit(1)
            .get();
        
        if (newBackupsQuery.docs.isNotEmpty) return; // Already migrated
        
        // Migrate backups to device ID location
        for (final doc in oldBackupsQuery.docs) {
          final backupData = doc.data();
          backupData['userId'] = deviceId; // Update userId to deviceId
          
          await _firestore
              .collection('backups')
              .doc(deviceId)
              .collection('user_backups')
              .doc(doc.id)
              .set(backupData);
          
          // Migrate chunks as well
          final chunksQuery = await _firestore
              .collection('backups')
              .doc(user.uid)
              .collection('user_backups')
              .doc(doc.id)
              .collection('chunks')
              .get();
          
          for (final chunkDoc in chunksQuery.docs) {
            await _firestore
                .collection('backups')
                .doc(deviceId)
                .collection('user_backups')
                .doc(doc.id)
                .collection('chunks')
                .doc(chunkDoc.id)
                .set(chunkDoc.data());
          }
        }
        
        debugPrint('Migrated ${oldBackupsQuery.docs.length} backups to device-based storage');
      }
    } catch (e) {
      debugPrint('Backup migration error: $e');
      // Migration failure shouldn't break the app
    }
  }

  Future<bool> signInAnonymously(BuildContext context) async {
    try {
      debugPrint('Attempting anonymous sign-in...');
      final userCredential = await _auth.signInAnonymously();
      debugPrint('Anonymous sign-in successful. User ID: ${userCredential.user?.uid}');
      
      if (!context.mounted) return false;
      
      // Store the user ID as a potential device ID for future reference
      try {
        final prefs = await SharedPreferences.getInstance();
        final storedIds = prefs.getStringList('previous_device_ids') ?? [];
        final newId = userCredential.user!.uid;
        if (!storedIds.contains(newId)) {
          storedIds.add(newId);
          await prefs.setStringList('previous_device_ids', storedIds.take(10).toList());
          debugPrint('Stored new Firebase UID as potential device ID: $newId');
        }
      } catch (e) {
        debugPrint('Failed to store Firebase UID: $e');
      }
      
      return true;
    } catch (e) {
      debugPrint('Anonymous sign-in failed: $e');
      if (!context.mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Authentication failed: $e'),
          duration: const Duration(seconds: 5),
        ),
      );
      return false;
    }
  }

  Future<String?> _getPasswordFromUser(BuildContext context, String title) async {
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    
    return await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Your data will be encrypted with this password before uploading to the cloud.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                autofocus: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Password is required';
                  }
                  if (value.length < 4) {
                    return 'Password must be at least 4 characters';
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  labelText: 'Encryption Password',
                  helperText: 'Keep this password safe - you\'ll need it to restore',
                  border: OutlineInputBorder(),
                ),
                onFieldSubmitted: (value) {
                  if (formKey.currentState?.validate() == true) {
                    Navigator.of(context).pop(passwordController.text.trim());
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() == true) {
                Navigator.of(context).pop(passwordController.text.trim());
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<bool> createCloudBackup(BuildContext context, {Function(String)? onProgress}) async {
    try {
      // Ensure user is authenticated
      if (_auth.currentUser == null) {
        onProgress?.call('Authenticating...');
        if (!await signInAnonymously(context)) return false;
      }

      final deviceId = await _getOrCreateDeviceId();
      onProgress?.call('Getting encryption password...');
      
      // Get password from user
      // ignore: use_build_context_synchronously
      final password = await _getPasswordFromUser(context, 'Create Cloud Backup');
      if (!context.mounted) return false;
      if (password == null || password.isEmpty) return false;

      onProgress?.call('Collecting data...');
      
      // Collect all data
      final appDir = await getApplicationDocumentsDirectory();
      final archive = Archive();
      final dir = Directory(appDir.path);
      final baseDirPath = dir.path;
      final allFiles = dir.listSync(recursive: true).whereType<File>().toList();
      
      for (int i = 0; i < allFiles.length; i++) {
        final entity = allFiles[i];
        final relativePath = entity.path.substring(baseDirPath.length + 1);
        archive.addFile(ArchiveFile(
            relativePath, entity.lengthSync(), entity.readAsBytesSync()));
        onProgress?.call('Processing files... ${i + 1}/${allFiles.length}');
      }

      onProgress?.call('Optimizing compression...');
      
      // First create initial archive
      final initialZip = ZipEncoder().encode(archive);
      
      // Apply advanced compression with progress tracking
      final compressionResult = await AdvancedCompressionService.compressData(
        data: Uint8List.fromList(initialZip),
        compressionLevel: 'balanced',
        onProgress: (status) => onProgress?.call('Advanced compression: $status'),
      );
      
      final outputZip = compressionResult.compressedData;
      
      // Log compression statistics
      debugPrint('Compression Stats:');
      debugPrint('  Original size: ${compressionResult.originalSize} bytes');
      debugPrint('  Compressed size: ${compressionResult.compressedSize} bytes');
      debugPrint('  Compression ratio: ${(compressionResult.compressionRatio * 100).toStringAsFixed(1)}%');
      debugPrint('  Space saved: ${compressionResult.originalSize - compressionResult.compressedSize} bytes');
      debugPrint('  Compression time: ${compressionResult.compressionTime.inMilliseconds}ms');

      // Process large backups with streaming encryption to avoid memory issues
      return await _createStreamingBackup(
        context, 
        outputZip, 
        deviceId, 
        password, 
        onProgress
      );
    } catch (e) {
      if (!context.mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cloud backup failed: $e')),
      );
      return false;
    }
  }

  Future<List<CloudBackupMetadata>> getCloudBackups(BuildContext context) async {
    try {
      // Ensure user is authenticated
      if (_auth.currentUser == null) {
        debugPrint('No authenticated user, signing in anonymously...');
        if (!await signInAnonymously(context)) {
          debugPrint('Anonymous sign-in failed');
          return [];
        }
        debugPrint('Anonymous sign-in successful: ${_auth.currentUser?.uid}');
      }

      // DEBUG: List all backups to help troubleshoot
      await debugListAllBackups();

      // Migrate old backups if needed
      await _migrateOldBackupsIfNeeded();

      // Search across ALL possible device IDs to find backups
      final possibleDeviceIds = await _getPossibleDeviceIds();
      debugPrint('Searching for backups across ${possibleDeviceIds.length} device IDs');
      
      List<CloudBackupMetadata> allBackups = [];
      
      // Search each possible device ID location
      for (final deviceId in possibleDeviceIds) {
        try {
          debugPrint('Checking device ID: ${deviceId.length > 50 ? deviceId.substring(0, 50) + "..." : deviceId}');
          
          var querySnapshot = await _firestore
              .collection('backups')
              .doc(deviceId)
              .collection('user_backups')
              .orderBy('createdAt', descending: true)
              .limit(20) // Limit to most recent 20 backups to avoid memory issues
              .get();

          if (querySnapshot.docs.isNotEmpty) {
            final backups = querySnapshot.docs
                .map((doc) => CloudBackupMetadata.fromMap(doc.data()))
                .toList();
            
            debugPrint('Found ${backups.length} backups for device ID: ${deviceId.substring(0, 12)}...');
            allBackups.addAll(backups);
            
            // If this isn't the current device ID, migrate backups
            final currentDeviceId = await _getOrCreateDeviceId();
            if (deviceId != currentDeviceId) {
              debugPrint('Migrating ${backups.length} backups to current device ID');
              await _migrateBackupsToCurrentDevice(deviceId, backups);
            }
          } else {
            debugPrint('No backups found for device ID: ${deviceId.substring(0, 12)}...');
          }
        } catch (e) {
          debugPrint('Error checking device ID $deviceId: $e');
          continue; // Continue with next device ID
        }
      }

      // Remove duplicates based on backup ID and sort by creation date
      final uniqueBackups = <String, CloudBackupMetadata>{};
      for (final backup in allBackups) {
        uniqueBackups[backup.id] = backup;
      }
      
      final result = uniqueBackups.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      debugPrint('Found ${result.length} unique cloud backups total');
      
      if (result.isEmpty) {
        debugPrint('=== NO BACKUPS FOUND ANYWHERE ===');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No cloud backups found. Create a backup first.'),
              duration: Duration(seconds: 4),
            ),
          );
        }
      }

      return result;
    } catch (e) {
      debugPrint('Critical error in getCloudBackups: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load cloud backups: $e')),
        );
      }
      return [];
    }
  }

  Future<void> _migrateBackupsToCurrentDevice(String oldDeviceId, List<CloudBackupMetadata> backups) async {
    try {
      final currentDeviceId = await _getOrCreateDeviceId();
      if (oldDeviceId == currentDeviceId) return; // No migration needed

      debugPrint('Migrating ${backups.length} backups from $oldDeviceId to $currentDeviceId');

      for (final backup in backups) {
        // Copy backup metadata
        final backupData = backup.toMap();
        backupData['userId'] = currentDeviceId;

        await _firestore
            .collection('backups')
            .doc(currentDeviceId)
            .collection('user_backups')
            .doc(backup.id)
            .set(backupData);

        // Copy backup chunks
        final chunksQuery = await _firestore
            .collection('backups')
            .doc(oldDeviceId)
            .collection('user_backups')
            .doc(backup.id)
            .collection('chunks')
            .get();

        for (final chunkDoc in chunksQuery.docs) {
          await _firestore
              .collection('backups')
              .doc(currentDeviceId)
              .collection('user_backups')
              .doc(backup.id)
              .collection('chunks')
              .doc(chunkDoc.id)
              .set(chunkDoc.data());
        }
      }

      debugPrint('Successfully migrated backups to current device');
    } catch (e) {
      debugPrint('Error migrating backups: $e');
    }
  }

  Future<bool> restoreFromCloud(BuildContext context, CloudBackupMetadata backup, {Function(String)? onProgress}) async {
    debugPrint('=== RESTORE DEBUG INFO ===');
    debugPrint('Starting cloud backup restore for: ${backup.id}');
    debugPrint('Backup userId: ${backup.userId}');
    debugPrint('Backup name: ${backup.name}');
    debugPrint('Backup size: ${backup.size} bytes');
    debugPrint('Backup created: ${backup.createdAt}');
    
    // List all available backups for comparison
    await debugListAllBackups();
    
    try {
      // Essential early checks to prevent crashes
      if (!context.mounted) {
        debugPrint('Context not mounted at start of restore');
        return false;
      }
      
      // Large backups will be restored with streaming to avoid memory issues
      final isLargeBackup = backup.size > 50 * 1024 * 1024; // 50MB+ gets special handling
      if (isLargeBackup) {
        onProgress?.call('Preparing streaming restore for large backup (${formatFileSize(backup.size)})...');
      }
      
      // Ensure user is authenticated
      if (_auth.currentUser == null) {
        onProgress?.call('Authenticating...');
        if (!await signInAnonymously(context)) return false;
      }

      onProgress?.call('Getting decryption password...');
      
      // Get password from user
      // ignore: use_build_context_synchronously
      final password = await _getPasswordFromUser(context, 'Restore Cloud Backup');
      if (!context.mounted) return false;
      if (password == null || password.isEmpty) {
        debugPrint('User cancelled password input');
        return false;
      }

      onProgress?.call('Downloading from cloud...');
      
      late List<String> base64Chunks;
      
      // Download from Firestore chunks with fallback device IDs
      try {
        debugPrint('Attempting to download backup chunks');
        base64Chunks = await _downloadBackupChunks(backup, onProgress);
        
        if (base64Chunks.isEmpty) {
          debugPrint('No backup data found in any location');
          if (!context.mounted) return false;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Backup data not found in cloud')),
          );
          return false;
        }
        
        debugPrint('Successfully downloaded ${base64Chunks.length} Base64 chunks');
        
      } catch (e) {
        debugPrint('Error downloading backup chunks: $e');
        if (!context.mounted) return false;
        
        // Handle specific OutOfMemory errors
        if (e.toString().contains('OutOfMemory') || e.toString().contains('allocation')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Not enough memory to restore this backup. Try restarting the app or use a device with more RAM.'),
              duration: Duration(seconds: 5),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to download backup: $e')),
          );
        }
        return false;
      }

      onProgress?.call('Decrypting backup...');
      
      late Archive archive;
      
      try {
        // First, try decrypting with the new, stronger key derivation
        final decryptedBytes = await _decryptChunks(base64Chunks, password, onProgress, isLegacy: false);
        archive = ZipDecoder().decodeBytes(decryptedBytes);
        debugPrint('Successfully decrypted with modern key.');

      } catch (e) {
        debugPrint('Decryption with modern key failed: $e');
        
        // If it's a password-related error OR a zip decoding error, try falling back to the legacy key derivation
        if (e.toString().contains('Invalid or corrupted pad block') ||
            e.toString().contains('Bad decrypt') ||
            e.toString().contains('Invalid padding') ||
            e is ArchiveException) { // Catching zip errors too
              
          debugPrint('Attempting decryption with legacy key...');
          onProgress?.call('Password failed, trying legacy mode...');
          
          try {
            // Second attempt: use the legacy key derivation for old backups
            final decryptedBytes = await _decryptChunks(base64Chunks, password, onProgress, isLegacy: true);
            archive = ZipDecoder().decodeBytes(decryptedBytes);
            debugPrint('Successfully decrypted with legacy key.');

          } catch (legacyError) {
            // If legacy also fails, then it's truly a wrong password or corrupted file
            debugPrint('Decryption with legacy key also failed: $legacyError');
            if (!context.mounted) return false;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Invalid password or corrupted backup file.'),
                duration: Duration(seconds: 5),
              ),
            );
            return false;
          }

        } else {
          // It's a different, non-password-related error
          if (!context.mounted) return false;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to decrypt backup: ${e.toString().length > 80 ? e.toString().substring(0, 80) + "..." : e.toString()}'),
              duration: const Duration(seconds: 5),
            ),
          );
          return false;
        }
      }

      // Same restore logic as local backup
      onProgress?.call('Verifying backup integrity...');
      final tempDir = await getTemporaryDirectory();
      final tempRestorePath = '${tempDir.path}/restore_temp_cloud';
      final tempRestoreDir = Directory(tempRestorePath);
      if (tempRestoreDir.existsSync()) {
        tempRestoreDir.deleteSync(recursive: true);
      }
      tempRestoreDir.createSync(recursive: true);

      bool isValid = false;
      for (final file in archive.files) {
        if (file.isFile) {
          final outputPath = '$tempRestorePath/${file.name}';
          File(outputPath)
            ..createSync(recursive: true)
            ..writeAsBytesSync(file.content as List<int>);
          if (file.name.contains(StorageService.incomeBoxName) ||
              file.name.contains(StorageService.outcomeBoxName)) {
            isValid = true;
          }
        }
      }

      if (!isValid) {
        if (!context.mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cloud backup is invalid or corrupted.')),
        );
        return false;
      }

      onProgress?.call('Backing up current data...');
      
      // Backup current data before overwriting (same as local restore)
      final appDir = await getApplicationDocumentsDirectory();
      final backupOfCurrentData = '${tempDir.path}/current_data_backup_cloud.zip';
      final archiveCurrent = Archive();
      if (appDir.existsSync()) {
        for (var entity in appDir.listSync(recursive: true)) {
          if (entity is File) {
            final relativePath = entity.path.substring(appDir.path.length + 1);
            archiveCurrent.addFile(ArchiveFile(relativePath,
                entity.lengthSync(), entity.readAsBytesSync()));
          }
        }
        final zipEncoder = ZipEncoder();
        final encodedArchive = zipEncoder.encode(archiveCurrent);
        File(backupOfCurrentData).writeAsBytesSync(encodedArchive);
      }

      onProgress?.call('Restoring data...');
      
      // Restore from cloud backup
      await _performRestore(appDir, tempRestorePath, context); // ignore: use_build_context_synchronously
      
      tempRestoreDir.deleteSync(recursive: true);
      onProgress?.call('Cloud restore completed successfully!');

      await _showRestartDialog(context); // ignore: use_build_context_synchronously
      return true;
    } catch (e, stackTrace) {
      debugPrint('Critical error during cloud restore: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // Always try to clean up temp directories
      try {
        final tempDir = await getTemporaryDirectory();
        final tempRestoreDir = Directory('${tempDir.path}/restore_temp_cloud');
        if (tempRestoreDir.existsSync()) {
          tempRestoreDir.deleteSync(recursive: true);
        }
      } catch (cleanupError) {
        debugPrint('Failed to cleanup temp directories: $cleanupError');
      }
      
      if (!context.mounted) return false;
      
      // Provide specific error messages for common failures
      String errorMessage = 'Cloud restore failed';
      if (e.toString().contains('OutOfMemory') || e.toString().contains('allocation')) {
        errorMessage = 'Not enough memory to restore this backup. Try restarting the app.';
      } else if (e.toString().contains('permission-denied')) {
        errorMessage = 'Permission denied. Please check your internet connection and try again.';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Network error. Please check your connection and try again.';
      } else if (e.toString().contains('decrypt')) {
        errorMessage = 'Failed to decrypt backup. Please check your password.';
      } else if (e.toString().contains('corrupt')) {
        errorMessage = 'Backup file appears to be corrupted.';
      } else {
        errorMessage = 'Cloud restore failed: ${e.toString().length > 100 ? e.toString().substring(0, 100) + "..." : e.toString()}';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          duration: const Duration(seconds: 5),
        ),
      );
      return false;
    }
  }

  Future<Uint8List> _decryptChunks(List<String> base64Chunks, String password, Function(String)? onProgress, {required bool isLegacy}) async {
    if (base64Chunks.isEmpty) {
      throw Exception('No Base64 chunks to decrypt');
    }

    debugPrint('Starting chunk-by-chunk decryption of ${base64Chunks.length} chunks (isLegacy: $isLegacy)');

    final List<Uint8List> decryptedChunks = [];
    encrypt.Key? key;
    encrypt.IV? iv;
    encrypt.Encrypter? encrypter;

    for (int i = 0; i < base64Chunks.length; i++) {
      final chunkBinary = base64Decode(base64Chunks[i]);

      if (i == 0) {
        // First chunk contains salt + IV + encrypted data
        if (chunkBinary.length < 24) {
          throw Exception('First chunk too small - expected at least 24 bytes, got ${chunkBinary.length}');
        }

        final salt = Uint8List.fromList(chunkBinary.sublist(0, 8));
        final ivBytes = Uint8List.fromList(chunkBinary.sublist(8, 24));
        final encryptedData = Uint8List.fromList(chunkBinary.sublist(24));

        key = isLegacy ? _deriveKeyLegacy(password, salt) : _deriveKey(password, salt);
        iv = encrypt.IV(ivBytes);
        encrypter = encrypt.Encrypter(encrypt.AES(key));

        debugPrint('Chunk 0: salt=${salt.length}bytes, iv=${ivBytes.length}bytes, encrypted=${encryptedData.length}bytes');

        // Decrypt first chunk
        final decryptedChunk = encrypter.decryptBytes(encrypt.Encrypted(encryptedData), iv: iv);
        decryptedChunks.add(Uint8List.fromList(decryptedChunk));
        debugPrint('Decrypted chunk 0: ${encryptedData.length} -> ${decryptedChunk.length} bytes');

      } else {
        // Subsequent chunks are just encrypted data (no header)
        if (encrypter == null || iv == null) {
          throw Exception('Encryption setup failed - missing key/IV from first chunk');
        }

        debugPrint('Chunk $i: encrypted=${chunkBinary.length}bytes');

        // Decrypt chunk
        final decryptedChunk = encrypter.decryptBytes(encrypt.Encrypted(chunkBinary), iv: iv);
        decryptedChunks.add(Uint8List.fromList(decryptedChunk));
        debugPrint('Decrypted chunk $i: ${chunkBinary.length} -> ${decryptedChunk.length} bytes');
      }

      final progress = ((i + 1) / base64Chunks.length * 50).round();
      onProgress?.call('Decrypting chunk ${i + 1}/${base64Chunks.length} ($progress%)');
    }

    if (decryptedChunks.isEmpty) {
      throw Exception('No chunks were successfully decrypted');
    }

    // Combine all decrypted chunks into final plaintext
    onProgress?.call('Reassembling decrypted data...');
    final totalLength = decryptedChunks.fold<int>(0, (sum, chunk) => sum + chunk.length);
    final decryptedBytes = Uint8List(totalLength);

    int offset = 0;
    for (final chunk in decryptedChunks) {
      decryptedBytes.setAll(offset, chunk);
      offset += chunk.length;
    }

    debugPrint('Successfully decrypted ${decryptedBytes.length} bytes from ${decryptedChunks.length} chunks');
    return decryptedBytes;
  }

  Future<void> _performRestore(Directory appDir, String tempRestorePath, BuildContext context) async {
    // Close Hive, clear data, and restore from temp
    await StorageService.closeHive();
    if (appDir.existsSync()) {
      appDir.deleteSync(recursive: true);
    }
    appDir.createSync(recursive: true);

    for (final file in Directory(tempRestorePath).listSync(recursive: true)) {
      if (file is File) {
        final relativePath = file.path.substring(tempRestorePath.length + 1);
        final newPath = '${appDir.path}/$relativePath';
        File(newPath).createSync(recursive: true);
        file.copySync(newPath);
      }
    }
  }

  Future<bool> _createStreamingBackup(
    BuildContext context, 
    Uint8List compressedData, 
    String deviceId, 
    String password, 
    Function(String)? onProgress
  ) async {
    try {
      onProgress?.call('Streaming encryption for large backup...');
      
      // Create salt and IV
      final salt = encrypt.IV.fromSecureRandom(8).bytes;
      final key = _deriveKey(password, salt);
      final iv = encrypt.IV.fromSecureRandom(16);
      final encrypter = encrypt.Encrypter(encrypt.AES(key));

      // Create backup metadata
      final timestamp = DateTime.now();
      final backupId = 'backup_${deviceId}_${timestamp.millisecondsSinceEpoch}';
      final backupName = 'Alkhazna_${DateFormat('yyyy-MM-dd_HH-mm-ss').format(timestamp)}';
      
      onProgress?.call('Processing data in chunks...');
      
      // Process data in smaller chunks to avoid memory issues
      const int chunkSize = 256 * 1024; // 256KB chunks for processing
      final List<String> base64Chunks = [];
      int totalProcessed = 0;
      
      // Add salt and IV to beginning
      final headerBytes = salt + iv.bytes;
      
      for (int i = 0; i < compressedData.length; i += chunkSize) {
        final endIndex = (i + chunkSize < compressedData.length) ? i + chunkSize : compressedData.length;
        final chunk = compressedData.sublist(i, endIndex);
        
        // Encrypt chunk
        final encryptedChunk = encrypter.encryptBytes(chunk, iv: iv);
        
        // For first chunk, prepend header (salt + iv)
        final finalChunk = i == 0 
            ? Uint8List.fromList(headerBytes + encryptedChunk.bytes)
            : encryptedChunk.bytes;
        
        // Convert to base64
        final base64Chunk = base64Encode(finalChunk);
        base64Chunks.add(base64Chunk);
        
        totalProcessed += chunk.length;
        final progress = (totalProcessed / compressedData.length * 50).round(); // First 50% for processing
        onProgress?.call('Processing: $progress% (${formatFileSize(totalProcessed)}/${formatFileSize(compressedData.length)})');
        
        // Small delay to prevent UI blocking
        await Future.delayed(const Duration(milliseconds: 10));
      }
      
      onProgress?.call('Uploading ${base64Chunks.length} chunks to cloud...');
      
      // Upload chunks with progress
      for (int i = 0; i < base64Chunks.length; i++) {
        final chunkRef = _firestore
            .collection('backups')
            .doc(deviceId)
            .collection('user_backups')
            .doc(backupId)
            .collection('chunks')
            .doc('chunk_$i');
        
        await chunkRef.set({
          'data': base64Chunks[i],
          'index': i,
          'timestamp': timestamp.toIso8601String(),
        });
        
        // Update progress (50% + 40% for upload)
        final uploadProgress = 50 + ((i + 1) / base64Chunks.length * 40).round();
        onProgress?.call('Uploading: $uploadProgress% (${i + 1}/${base64Chunks.length} chunks)');
        
        // Longer delay to prevent Firestore write stream exhaustion
        await Future.delayed(const Duration(milliseconds: 200));
      }
      
      onProgress?.call('Saving backup metadata...');
      
      // Calculate total size including encryption overhead
      final totalEncryptedSize = base64Chunks.fold<int>(0, (sum, chunk) => sum + chunk.length);
      
      // Save metadata
      final metadata = CloudBackupMetadata(
        id: backupId,
        name: backupName,
        createdAt: timestamp,
        size: totalEncryptedSize,
        userId: deviceId,
        deviceInfo: Platform.operatingSystem,
        appVersion: '1.0.0',
      );

      final metadataWithChunks = metadata.toMap();
      metadataWithChunks['chunkCount'] = base64Chunks.length;
      metadataWithChunks['storageType'] = 'firestore_streaming';
      metadataWithChunks['originalSize'] = compressedData.length;

      await _firestore
          .collection('backups')
          .doc(deviceId)
          .collection('user_backups')
          .doc(backupId)
          .set(metadataWithChunks);

      onProgress?.call('Large backup completed successfully!');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Large backup "$backupName" (${formatFileSize(totalEncryptedSize)}) created successfully!'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
      
      return true;
      
    } catch (e) {
      debugPrint('Streaming backup error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Streaming backup failed: $e')),
        );
      }
      return false;
    }
  }

  Future<void> _showRestartDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cloud Restore Complete'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Your data has been restored from the cloud backup.'),
                Text('Please restart the application for the changes to take effect.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<bool> deleteCloudBackup(BuildContext context, CloudBackupMetadata backup) async {
    try {
      debugPrint('Starting cloud backup deletion for: ${backup.id}');
      
      // Ensure user is authenticated
      if (_auth.currentUser == null) {
        if (!await signInAnonymously(context)) return false;
      }

      // Try to delete from multiple possible device IDs
      bool deleted = false;
      final possibleDeviceIds = await _getPossibleDeviceIds();
      debugPrint('Searching for backup in ${possibleDeviceIds.length} possible locations');
      
      if (possibleDeviceIds.isEmpty) {
        debugPrint('No device IDs to search for deletion');
        if (!context.mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to locate backup for deletion')),
        );
        return false;
      }
      
      for (final deviceId in possibleDeviceIds) {
        try {
          // Check if backup exists in this location
          final backupDoc = await _firestore
              .collection('backups')
              .doc(deviceId)
              .collection('user_backups')
              .doc(backup.id)
              .get();
          
          if (backupDoc.exists) {
            // Get chunk count from metadata first
            final backupData = backupDoc.data();
            final chunkCount = backupData?['chunkCount'] ?? 0;
            
            if (chunkCount > 0) {
              debugPrint('Deleting $chunkCount chunks in batches...');
              
              // Use batch deletion for very large backups
              if (chunkCount > 2000) {
                debugPrint('Using optimized batch deletion for very large backup: $chunkCount chunks');
                await _deleteChunksInOptimizedBatches(deviceId, backup.id, chunkCount);
              } else {
              
              // Delete chunks in small batches to avoid memory issues
              const batchSize = 10; // Delete 10 chunks at a time
              for (int batchStart = 0; batchStart < chunkCount; batchStart += batchSize) {
                final batchEnd = (batchStart + batchSize < chunkCount) ? batchStart + batchSize : chunkCount;
                
                try {
                  // Get a small batch of chunk references
                  final batchQuery = await _firestore
                      .collection('backups')
                      .doc(deviceId)
                      .collection('user_backups')
                      .doc(backup.id)
                      .collection('chunks')
                      .where('index', isGreaterThanOrEqualTo: batchStart)
                      .where('index', isLessThanOrEqualTo: batchEnd - 1)
                      .limit(batchSize)
                      .get();

                  // Delete chunks in this batch
                  for (final doc in batchQuery.docs) {
                    await doc.reference.delete();
                  }
                  
                  debugPrint('Deleted chunk batch $batchStart-${batchEnd-1}');
                  
                  // Small delay to prevent rate limiting and allow garbage collection
                  await Future.delayed(const Duration(milliseconds: 100));
                  
                } catch (e) {
                  debugPrint('Error deleting chunk batch $batchStart-${batchEnd-1}: $e');
                  // Continue with next batch even if one fails
                }
              }
              } // Close the else block for standard batch deletion
            }

            // Delete metadata from Firestore
            await _firestore
                .collection('backups')
                .doc(deviceId)
                .collection('user_backups')
                .doc(backup.id)
                .delete();
            
            deleted = true;
            break; // Stop after first successful deletion
          }
        } catch (e) {
          debugPrint('Failed to delete from device ID $deviceId: $e');
          continue; // Try next device ID
        }
      }

      if (!deleted) {
        if (!context.mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup not found or already deleted')),
        );
        return false;
      }

      if (!context.mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cloud backup "${backup.name}" deleted successfully')),
      );
      return true;
    } catch (e, stackTrace) {
      debugPrint('Critical error during cloud backup deletion: $e');
      debugPrint('Stack trace: $stackTrace');
      
      if (!context.mounted) return false;
      
      // Provide specific error messages for common failures
      String errorMessage = 'Failed to delete cloud backup';
      if (e.toString().contains('permission-denied')) {
        errorMessage = 'Permission denied. Please check your internet connection and try again.';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Network error. Please check your connection and try again.';
      } else if (e.toString().contains('not-found')) {
        errorMessage = 'Backup not found or already deleted.';
      } else {
        errorMessage = 'Failed to delete cloud backup: ${e.toString().length > 80 ? e.toString().substring(0, 80) + "..." : e.toString()}';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          duration: const Duration(seconds: 5),
        ),
      );
      return false;
    }
  }


  Future<List<String>> _downloadBackupChunks(CloudBackupMetadata backup, Function(String)? onProgress) async {
    try {
      final possibleDeviceIds = await _getPossibleDeviceIds();
      debugPrint('_downloadBackupChunks: Searching ${possibleDeviceIds.length} device IDs for backup: ${backup.id}');
      debugPrint('Backup userId from metadata: ${backup.userId}');
      
      // Add the backup's original userId to search list if not already there
      if (!possibleDeviceIds.contains(backup.userId)) {
        possibleDeviceIds.insert(0, backup.userId); // Try original device ID first
        debugPrint('Added backup original userId: ${backup.userId}');
      }
      
      if (possibleDeviceIds.isEmpty) {
        debugPrint('No device IDs to search');
        onProgress?.call('Error: No backup locations to search');
        throw Exception('No device IDs available for backup search');
      }
      
      Exception? lastError;
      
      for (final deviceId in possibleDeviceIds) {
        try {
          final displayId = deviceId.length > 12 ? deviceId.substring(0, 12) : deviceId;
          onProgress?.call('Searching backup in device: $displayId...');
          debugPrint('Trying device ID: $deviceId (full: ${deviceId.length > 50 ? deviceId.substring(0, 50) + "..." : deviceId})');
          
          // First, get total chunk count with a minimal query
          DocumentSnapshot? metadataDoc;
          try {
            debugPrint('Checking path: backups/$deviceId/user_backups/${backup.id}');
            metadataDoc = await _firestore
                .collection('backups')
                .doc(deviceId)
                .collection('user_backups')
                .doc(backup.id)
                .get();
          } catch (e) {
            debugPrint('Failed to get backup metadata for device $deviceId: $e');
            lastError = Exception('Failed to access backup metadata: $e');
            continue; // Try next device ID
          }
          
          if (!metadataDoc.exists) {
            debugPrint('Backup metadata not found at path: backups/$deviceId/user_backups/${backup.id}');
            lastError = Exception('Backup not found in cloud storage');
            continue; // Try next device ID
          }
          
          debugPrint('Found backup metadata at device: $deviceId');
          
          final metadataData = metadataDoc.data() as Map<String, dynamic>?;
          final chunkCount = metadataData?['chunkCount'] ?? 0;
          
          if (chunkCount == 0) {
            debugPrint('No chunks found in metadata for device: $deviceId');
            lastError = Exception('Backup contains no data chunks');
            continue; // Try next device ID
          }
          
          onProgress?.call('Found backup! Loading $chunkCount chunks...');
          
          // Download chunks in small batches to avoid memory issues
          final result = await _downloadChunksInBatches(deviceId, backup.id, chunkCount, onProgress);
          
          if (result.isNotEmpty) {
            debugPrint('Successfully downloaded backup data: ${result.length} bytes');
            return result;
          } else {
            lastError = Exception('Downloaded backup data is empty');
          }
          
        } catch (e) {
          debugPrint('Failed to download from device ID $deviceId: $e');
          lastError = Exception('Download failed: $e');
          
          if (e.toString().contains('permission-denied')) {
            onProgress?.call('Permission denied. Trying next location...');
          } else if (e.toString().contains('network')) {
            onProgress?.call('Network error. Trying next location...');
          } else {
            onProgress?.call('Error occurred. Trying next location...');
          }
          continue; // Try next device ID
        }
      }
      
      // If we get here, no device ID worked
      final errorMsg = lastError?.toString() ?? 'Backup data not found in any cloud location';
      debugPrint('All device IDs failed. Last error: $errorMsg');
      onProgress?.call('Backup data not found on cloud');
      throw Exception(errorMsg);
      
    } catch (e) {
      debugPrint('Critical error in _downloadBackupChunks: $e');
      onProgress?.call('Failed to locate backup data');
      rethrow; // Re-throw to let caller handle it
    }
  }


  Future<List<String>> _downloadChunksInBatches(String deviceId, String backupId, int chunkCount, Function(String)? onProgress) async {
    try {
      // Safety checks
      if (chunkCount <= 0) {
        debugPrint('Invalid chunk count: $chunkCount');
        return [];
      }
      
      // Use streaming download for very large backups
      if (chunkCount > 2000) { // More than 2000 chunks (~100MB)
        onProgress?.call('Using streaming download for very large backup...');
        return await _downloadChunksStreamingMode(deviceId, backupId, chunkCount, onProgress);
      }
      
      const batchSize = 20; // Increased batch size for faster restore
      final List<String> allChunkData = [];
      
      for (int batchStart = 0; batchStart < chunkCount; batchStart += batchSize) {
        final batchEnd = (batchStart + batchSize < chunkCount) ? batchStart + batchSize : chunkCount;
        
        onProgress?.call('Downloading chunks ${batchStart + 1}-$batchEnd of $chunkCount...');
        
        try {
          // Download this batch of chunks with timeout
          final batch = await _downloadChunkBatch(deviceId, backupId, batchStart, batchEnd - 1)
              .timeout(const Duration(seconds: 30));
          
          if (batch.isEmpty) {
            throw Exception('Empty batch received for chunks $batchStart-${batchEnd-1}');
          }
          
          allChunkData.addAll(batch);
          
          // Update progress
          final progress = ((batchEnd) / chunkCount * 80).round();
          onProgress?.call('Downloaded: $progress%');
          
          // Shorter delay for faster restore
          await Future.delayed(const Duration(milliseconds: 100));
          
        } catch (e) {
          debugPrint('Failed to download batch $batchStart-${batchEnd-1}: $e');
          allChunkData.clear(); // Clean up memory
          rethrow;
        }
      }
      
      onProgress?.call('Assembling backup data...');
      
      if (allChunkData.isEmpty) {
        throw Exception('No chunk data downloaded');
      }
      
      // Keep chunks as separate Base64 strings for proper decryption
      try {
        if (allChunkData.isEmpty) {
          throw Exception('Empty backup data assembled');
        }
        
        onProgress?.call('Backup download complete!');
        
        // Return the Base64 chunks as-is - decryption will handle them properly
        // Each chunk needs to be decrypted individually, not joined first
        debugPrint('Returning ${allChunkData.length} Base64 chunks for individual decryption');
        final result = List<String>.from(allChunkData);
        allChunkData.clear();
        
        return result;
        
      } catch (e) {
        debugPrint('Error assembling backup data: $e');
        allChunkData.clear(); // Ensure cleanup
        rethrow;
      }
      
    } catch (e) {
      debugPrint('Error in _downloadChunksInBatches: $e');
      rethrow; // Let caller handle the error
    }
  }

  Future<List<String>> _downloadChunkBatch(String deviceId, String backupId, int startIndex, int endIndex) async {
    try {
      final batchQuery = await _firestore
          .collection('backups')
          .doc(deviceId)
          .collection('user_backups')
          .doc(backupId)
          .collection('chunks')
          .where('index', isGreaterThanOrEqualTo: startIndex)
          .where('index', isLessThanOrEqualTo: endIndex)
          .orderBy('index')
          .get();
      
      final batchData = <String>[];
      for (final doc in batchQuery.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        final chunkData = data?['data'] as String?;
        
        if (chunkData == null || chunkData.isEmpty) {
          debugPrint('Missing chunk data at index ${data?['index']} in document ${doc.id}');
          throw Exception('Corrupted backup: missing chunk data at index ${data?['index']}');
        }
        
        batchData.add(chunkData);
      }
      
      if (batchData.isEmpty) {
        throw Exception('No chunks found in batch $startIndex-$endIndex');
      }
      
      return batchData;
      
    } catch (e) {
      debugPrint('Error downloading chunk batch $startIndex-$endIndex: $e');
      throw Exception('Failed to download chunk batch: $e');
    }
  }


  Future<List<String>> _getPossibleDeviceIds() async {
    final currentDeviceId = await _getOrCreateDeviceId();
    final possibleDeviceIds = <String>[currentDeviceId];
    
    debugPrint('Current device ID: $currentDeviceId');
    
    // Add all possible device ID patterns that could have been used historically
    final os = Platform.operatingSystem;
    final locale = Platform.localeName;
    
    // Pattern 1: Fallback pattern
    final fallbackId = 'device_fallback_${os.hashCode.abs()}';
    possibleDeviceIds.add(fallbackId);
    
    // Pattern 2: Full fingerprint pattern  
    final combined = '${os}_${locale}_android_emulator';
    final fingerprintId = 'device_fp_${combined.hashCode.abs()}';
    possibleDeviceIds.add(fingerprintId);
    
    // Pattern 3: Alternative combinations
    possibleDeviceIds.add('device_fp_${os.hashCode.abs()}');
    possibleDeviceIds.add('device_fp_${locale.hashCode.abs()}');
    possibleDeviceIds.add('device_fp_${('android_$locale').hashCode.abs()}');
    
    // Pattern 4: Common variations based on different device info combinations
    possibleDeviceIds.add('device_fp_${('${os}_android').hashCode.abs()}');
    possibleDeviceIds.add('device_fp_${('windows_android').hashCode.abs()}');
    possibleDeviceIds.add('device_fp_${('android_en_US').hashCode.abs()}');
    
    // Pattern 5: Firebase auth UIDs from current and potential previous sessions
    if (_auth.currentUser != null) {
      possibleDeviceIds.add(_auth.currentUser!.uid);
      debugPrint('Added current Firebase UID: ${_auth.currentUser!.uid}');
    }
    
    // Pattern 6: Try to get stored device IDs from SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedIds = prefs.getStringList('previous_device_ids') ?? [];
      for (final id in storedIds) {
        if (id.isNotEmpty) {
          possibleDeviceIds.add(id);
        }
      }
      
      // Store current device ID for future reference
      final updatedIds = [...storedIds];
      if (!updatedIds.contains(currentDeviceId)) {
        updatedIds.add(currentDeviceId);
        await prefs.setStringList('previous_device_ids', updatedIds.take(10).toList()); // Keep only last 10
      }
    } catch (e) {
      debugPrint('Error accessing stored device IDs: $e');
    }
    
    debugPrint('Generated ${possibleDeviceIds.length} possible device IDs:');
    for (int i = 0; i < possibleDeviceIds.length; i++) {
      final id = possibleDeviceIds[i];
      final displayId = id.length > 50 ? '${id.substring(0, 50)}...' : id;
      debugPrint('  $i: $displayId');
    }
    
    // Remove duplicates while maintaining order (current device ID should be first)
    final seen = <String>{};
    return possibleDeviceIds.where((id) => seen.add(id)).toList();
  }

  Future<void> debugListAllBackups() async {
    try {
      debugPrint('=== DEBUG: Listing all backups in Firestore ===');
      
      final possibleDeviceIds = await _getPossibleDeviceIds();
      
      for (final deviceId in possibleDeviceIds) {
        try {
          debugPrint('Checking device: $deviceId');
          final querySnapshot = await _firestore
              .collection('backups')
              .doc(deviceId)
              .collection('user_backups')
              .get();
          
          if (querySnapshot.docs.isNotEmpty) {
            debugPrint('  Found ${querySnapshot.docs.length} backups:');
            for (final doc in querySnapshot.docs) {
              final data = doc.data();
              debugPrint('    - ID: ${doc.id}');
              debugPrint('    - Name: ${data['name']}');
              debugPrint('    - Size: ${data['size']} bytes');
              debugPrint('    - Created: ${data['createdAt']}');
              debugPrint('    - Chunks: ${data['chunkCount']}');
            }
          } else {
            debugPrint('  No backups found');
          }
        } catch (e) {
          debugPrint('  Error checking device $deviceId: $e');
        }
        debugPrint('');
      }
      
      debugPrint('=== END DEBUG LIST ===');
    } catch (e) {
      debugPrint('Error in debugListAllBackups: $e');
    }
  }

  Future<List<String>> _downloadChunksStreamingMode(
    String deviceId, 
    String backupId, 
    int chunkCount, 
    Function(String)? onProgress
  ) async {
    try {
      onProgress?.call('Streaming download of ${chunkCount} chunks...');
      
      // Download and collect Base64 chunks for individual decryption
      const batchSize = 5; // Very small batches for huge files
      final List<String> resultChunks = [];
      
      for (int batchStart = 0; batchStart < chunkCount; batchStart += batchSize) {
        final batchEnd = (batchStart + batchSize < chunkCount) ? batchStart + batchSize : chunkCount;
        
        final batchData = await _downloadChunkBatch(deviceId, backupId, batchStart, batchEnd - 1);
        
        // Collect Base64 chunks directly (don't decode to binary yet)
        resultChunks.addAll(batchData);
        
        final progress = ((batchEnd) / chunkCount * 80).round();
        onProgress?.call('Streaming: $progress% (${batchEnd}/${chunkCount} chunks)');
        
        // Longer delay for very large downloads
        await Future.delayed(const Duration(milliseconds: 200));
      }
      
      onProgress?.call('Streaming download complete!');
      debugPrint('Streaming mode returning ${resultChunks.length} Base64 chunks');
      return resultChunks;
      
    } catch (e) {
      debugPrint('Streaming download error: $e');
      rethrow;
    }
  }

  Future<void> _deleteChunksInOptimizedBatches(
    String deviceId, 
    String backupId, 
    int chunkCount
  ) async {
    try {
      debugPrint('Optimized deletion of $chunkCount chunks...');
      
      // Delete in larger batches for efficiency
      const batchSize = 50;
      for (int batchStart = 0; batchStart < chunkCount; batchStart += batchSize) {
        final batchEnd = (batchStart + batchSize < chunkCount) ? batchStart + batchSize : chunkCount;
        
        // Get batch references
        final batchQuery = await _firestore
            .collection('backups')
            .doc(deviceId)
            .collection('user_backups')
            .doc(backupId)
            .collection('chunks')
            .where('index', isGreaterThanOrEqualTo: batchStart)
            .where('index', isLessThanOrEqualTo: batchEnd - 1)
            .limit(batchSize)
            .get();

        // Delete batch
        for (final doc in batchQuery.docs) {
          await doc.reference.delete();
        }
        
        debugPrint('Deleted optimized batch $batchStart-${batchEnd-1}');
        await Future.delayed(const Duration(milliseconds: 50));
      }
      
    } catch (e) {
      debugPrint('Optimized batch deletion error: $e');
      rethrow;
    }
  }

  String formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    int i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(1)} ${suffixes[i]}';
  }

  Future<void> oneClickBackup(BuildContext context) async {
    try {
      // Show progress to the user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Starting backup...')),
      );

      // Call the existing createCloudBackup method
      final success = await createCloudBackup(context, onProgress: (progress) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(progress)),
        );
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup completed successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup failed. Please try again.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during backup: $e')),
      );
    }
  }
}