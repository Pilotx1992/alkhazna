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
      ..init(Pbkdf2Parameters(salt, 1000, 32));
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
      await _auth.signInAnonymously();
      if (!context.mounted) return false;
      return true;
    } catch (e) {
      if (!context.mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Authentication failed: $e')),
      );
      return false;
    }
  }

  Future<String?> _getPasswordFromUser(BuildContext context, String title) async {
    final passwordController = TextEditingController();
    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Your data will be encrypted with this password before uploading to the cloud.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Encryption Password',
                helperText: 'Keep this password safe - you\'ll need it to restore',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(passwordController.text),
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

      onProgress?.call('Compressing data...');
      final outputZip = ZipEncoder().encode(archive);

      onProgress?.call('Encrypting backup...');
      final salt = encrypt.IV.fromSecureRandom(8).bytes;
      final key = _deriveKey(password, salt);
      final iv = encrypt.IV.fromSecureRandom(16);

      final encrypter = encrypt.Encrypter(encrypt.AES(key));
      final encrypted = encrypter.encryptBytes(outputZip, iv: iv);
      final encryptedData = salt + iv.bytes + encrypted.bytes;

      onProgress?.call('Uploading to cloud...');
      
      // Create backup metadata
      final timestamp = DateTime.now();
      final backupId = 'backup_${deviceId}_${timestamp.millisecondsSinceEpoch}';
      final backupName = 'Alkhazna_${DateFormat('yyyy-MM-dd_HH-mm-ss').format(timestamp)}';
      
      // Store backup data directly in Firestore (bypassing Firebase Storage issues)
      onProgress?.call('Preparing cloud backup...');
      
      // Split large backup into chunks for Firestore storage
      final base64Data = base64Encode(encryptedData);
      const chunkSize = 500000; // ~500KB chunks to stay well under Firestore limits
      final chunks = <String>[];
      
      try {
        onProgress?.call('Encrypting and compressing backup... 50%');
        
        for (int i = 0; i < base64Data.length; i += chunkSize) {
          final end = (i + chunkSize < base64Data.length) ? i + chunkSize : base64Data.length;
          chunks.add(base64Data.substring(i, end));
        }
        
        onProgress?.call('Uploading backup ... 75%');
        
        // Store chunks individually with delays to avoid rate limiting
        for (int i = 0; i < chunks.length; i++) {
          final chunkRef = _firestore
              .collection('backups')
              .doc(deviceId)
              .collection('user_backups')
              .doc(backupId)
              .collection('chunks')
              .doc('chunk_$i');
          
          await chunkRef.set({
            'data': chunks[i],
            'index': i,
            'timestamp': timestamp.toIso8601String(),
          });
          
          // Update progress for each chunk
          final progress = 1 + ((i + 1) / chunks.length * 20).round();
          onProgress?.call('Uploading backup $progress%');
          
          // Add small delay to prevent Firestore rate limiting
          if (i < chunks.length - 1) {
            await Future.delayed(const Duration(milliseconds: 100));
          }
        }
        
        onProgress?.call('Cloud backup completed successfully!');
        
      } catch (e) {
        debugPrint('Firestore backup error: $e');
        if (e.toString().contains('permission-denied')) {
          throw Exception('Permission denied. Please check Firestore security rules.');
        } else if (e.toString().contains('quota-exceeded')) {
          throw Exception('Storage quota exceeded. Please upgrade your Firebase plan.');
        } else if (e.toString().contains('network')) {
          throw Exception('Network error. Please check your internet connection.');
        } else {
          throw Exception('Cloud backup failed: ${e.toString()}');
        }
      }
      onProgress?.call('Saving backup metadata...');

      // Save metadata to Firestore with chunk info
      final metadata = CloudBackupMetadata(
        id: backupId,
        name: backupName,
        createdAt: timestamp,
        size: encryptedData.length,
        userId: deviceId,
        deviceInfo: Platform.operatingSystem,
        appVersion: '1.0.0',
      );

      final metadataWithChunks = metadata.toMap();
      metadataWithChunks['chunkCount'] = chunks.length;
      metadataWithChunks['storageType'] = 'firestore';

      await _firestore
          .collection('backups')
          .doc(deviceId)
          .collection('user_backups')
          .doc(backupId)
          .set(metadataWithChunks);

      onProgress?.call('Cloud backup completed successfully!');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cloud backup "$backupName" created successfully!')),
        );
      }
      return true;
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
        if (!await signInAnonymously(context)) return [];
      }

      // Migrate old backups if needed
      await _migrateOldBackupsIfNeeded();

      final deviceId = await _getOrCreateDeviceId();
      
      // First try to get backups from current device ID
      var querySnapshot = await _firestore
          .collection('backups')
          .doc(deviceId)
          .collection('user_backups')
          .orderBy('createdAt', descending: true)
          .get();

      List<CloudBackupMetadata> backups = querySnapshot.docs
          .map((doc) => CloudBackupMetadata.fromMap(doc.data()))
          .toList();

      // If no backups found, try to search for backups from previous installations
      if (backups.isEmpty) {
        if (context.mounted) {
          backups = await _searchForBackupsFromOldDeviceIds(context);
        }
      }

      return backups;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load cloud backups: $e')),
        );
      }
      return [];
    }
  }

  Future<List<CloudBackupMetadata>> _searchForBackupsFromOldDeviceIds(BuildContext context) async {
    try {
      // Search for backups that might belong to this device but under different IDs
      // We'll look for common patterns that might match this device
      
      final possibleDeviceIds = [
        'device_fallback_${Platform.operatingSystem.hashCode.abs()}',
        'device_fp_${('${Platform.operatingSystem}_${Platform.localeName}_android_emulator').hashCode.abs()}',
      ];

      // Also try some Firebase auth UIDs from recent sessions
      if (_auth.currentUser != null) {
        possibleDeviceIds.add(_auth.currentUser!.uid);
      }

      List<CloudBackupMetadata> foundBackups = [];

      for (final deviceId in possibleDeviceIds) {
        try {
          final querySnapshot = await _firestore
              .collection('backups')
              .doc(deviceId)
              .collection('user_backups')
              .orderBy('createdAt', descending: true)
              .limit(10) // Limit to avoid too many queries
              .get();

          final backups = querySnapshot.docs
              .map((doc) => CloudBackupMetadata.fromMap(doc.data()))
              .toList();

          if (backups.isNotEmpty) {
            foundBackups.addAll(backups);
            
            // If we found backups, migrate them to current device ID
            await _migrateBackupsToCurrentDevice(deviceId, backups);
            break; // Stop searching once we find backups
          }
        } catch (e) {
          // Continue searching even if one device ID fails
          debugPrint('Failed to search device ID $deviceId: $e');
        }
      }

      return foundBackups;
    } catch (e) {
      debugPrint('Error searching for old backups: $e');
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
    try {
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
      if (password == null || password.isEmpty) return false;

      onProgress?.call('Downloading from cloud...');
      
      late List<int> fileBytes;
      
      // Download from Firestore chunks
      try {
        // Use deviceId for consistent access across reinstalls
        final deviceId = await _getOrCreateDeviceId();
        final chunksQuery = await _firestore
            .collection('backups')
            .doc(deviceId)
            .collection('user_backups')
            .doc(backup.id)
            .collection('chunks')
            .orderBy('index')
            .get();
        
        if (chunksQuery.docs.isEmpty) {
          if (!context.mounted) return false;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Backup data not found in cloud')),
          );
          return false;
        }
        
        // Reassemble chunks
        final buffer = StringBuffer();
        for (final doc in chunksQuery.docs) {
          buffer.write(doc.data()['data'] ?? '');
        }
        
        final base64String = buffer.toString();
        fileBytes = base64Decode(base64String);
        
      } catch (e) {
        if (!context.mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download backup: $e')),
        );
        return false;
      }

      onProgress?.call('Decrypting backup...');
      
      // Decrypt the data (same as local backup restore)
      final salt = Uint8List.fromList(fileBytes.sublist(0, 8));
      final ivBytes = Uint8List.fromList(fileBytes.sublist(8, 24));
      final encryptedBytes = Uint8List.fromList(fileBytes.sublist(24));

      final key = _deriveKey(password, salt);
      final iv = encrypt.IV(ivBytes);

      final encrypter = encrypt.Encrypter(encrypt.AES(key));
      final decryptedBytes =
          encrypter.decryptBytes(encrypt.Encrypted(encryptedBytes), iv: iv);

      onProgress?.call('Extracting backup contents...');
      final archive = ZipDecoder().decodeBytes(decryptedBytes);

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
    } catch (e) {
      if (!context.mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cloud restore failed: $e')),
      );
      return false;
    }
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
      // Ensure user is authenticated
      if (_auth.currentUser == null) {
        if (!await signInAnonymously(context)) return false;
      }

      // Delete chunks from Firestore subcollection
      final deviceId = await _getOrCreateDeviceId();
      final chunksQuery = await _firestore
          .collection('backups')
          .doc(deviceId)
          .collection('user_backups')
          .doc(backup.id)
          .collection('chunks')
          .get();

      // Delete chunks individually to avoid batch size limits
      for (final doc in chunksQuery.docs) {
        await doc.reference.delete();
      }

      // Delete metadata from Firestore
      await _firestore
          .collection('backups')
          .doc(deviceId)
          .collection('user_backups')
          .doc(backup.id)
          .delete();

      if (!context.mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cloud backup "${backup.name}" deleted successfully')),
      );
      return true;
    } catch (e) {
      if (!context.mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete cloud backup: $e')),
      );
      return false;
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
}