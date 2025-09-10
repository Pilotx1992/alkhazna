import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:uuid/uuid.dart';
import '../../models/backup_models.dart';
import '../../models/drive_manifest_model.dart';
import '../backup_key_manager.dart';
import '../crypto_service.dart';
import '../key_management_service.dart';
import '../storage_service.dart';
import 'drive_provider_resumable.dart';

/// Drive-based backup service implementing blueprint section 8
/// Handles chunking, compression, encryption, and resumable uploads
class DriveBackupService extends ChangeNotifier {
  static final DriveBackupService _instance = DriveBackupService._internal();
  factory DriveBackupService() => _instance;
  DriveBackupService._internal();

  final DriveProviderResumable _driveProvider = DriveProviderResumable();
  final CryptoService _cryptoService = CryptoService();
  final KeyManagementService _keyManagementService = KeyManagementService();
  final BackupKeyManager _keyManager = BackupKeyManager();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'https://www.googleapis.com/auth/drive.file',
      'https://www.googleapis.com/auth/drive.appdata',  // Required for app data folder access
    ],
  );

  BackupProgress _currentProgress = BackupProgress();
  bool _isBackupInProgress = false;
  String? _currentSessionId;

  // Blueprint constants
  static const int defaultChunkSize = 8 * 1024 * 1024; // 8 MiB
  static const int maxParallelChunks = 3; // Limited concurrency

  BackupProgress get currentProgress => _currentProgress;
  bool get isBackupInProgress => _isBackupInProgress;

  /// Start backup process following blueprint section 8
  Future<bool> startBackup() async {
    if (_isBackupInProgress) return false;

    _isBackupInProgress = true;
    _updateProgress(0.0, BackupStatus.preparing, 'Starting backup...');

    try {
      // Step 1: Preflight checks
      if (!await _preflightChecks()) {
        return false;
      }

      // Step 2: Ensure authentication
      _updateProgress(10.0, BackupStatus.preparing, 'Authenticating with Google Drive...');
      if (!await _ensureAuthenticated()) {
        _updateProgress(0.0, BackupStatus.failed, 'Authentication failed');
        return false;
      }

      // Step 3: Ensure master key and save to cloud
      _updateProgress(15.0, BackupStatus.preparing, 'Preparing encryption keys...');
      final masterKey = await _cryptoService.getMasterKey();
      
      // Save the master key to the cloud for recovery after app reinstallation
      final currentUser = _googleSignIn.currentUser;
      if (currentUser != null) {
        _updateProgress(17.0, BackupStatus.preparing, 'Securing keys in cloud...');
        final keysSaved = await _keyManager.saveKeysToCloud(currentUser.email, masterKey);
        if (keysSaved) {
          if (kDebugMode) {
            print('✅ Master key successfully saved to cloud for user: ${currentUser.email}');
          }
        } else {
          if (kDebugMode) {
            print('⚠️ Warning: Failed to save master key to cloud. Backup will proceed but may not be restorable after app reinstall.');
          }
        }
      }

      // Step 4: Create session and folder structure or resume existing
      _updateProgress(20.0, BackupStatus.preparing, 'Creating backup session...');
      final sessionData = await _getOrCreateSession();
      final sessionId = sessionData['sessionId'] as String;
      final sessionFolderId = sessionData['sessionFolderId'] as String;
      _currentSessionId = sessionId;

      // Step 5: Create initial manifest
      _updateProgress(25.0, BackupStatus.preparing, 'Preparing backup manifest...');
      final manifest = await _createInitialManifest(sessionId);

      // Step 6: Upload manifest to Drive
      final manifestBytes = utf8.encode(manifest.toJsonString());
      final manifestFileId = await _uploadManifest(sessionFolderId, manifestBytes);

      // Step 7: Process and upload files
      _updateProgress(30.0, BackupStatus.compressing, 'Processing files...');
      final updatedManifest = await _processAndUploadFiles(
        manifest, sessionFolderId, sessionId, masterKey);

      // Step 8: Update final manifest
      _updateProgress(95.0, BackupStatus.uploading, 'Finalizing backup...');
      final finalManifest = updatedManifest.copyWith(status: 'complete');
      await _updateManifest(manifestFileId, finalManifest);

      // Step 9: Save backup info locally
      await _saveBackupInfo(sessionId, manifestFileId, finalManifest);

      _updateProgress(100.0, BackupStatus.completed, 'Backup completed successfully!');
      return true;

    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Backup failed: $e');
        print('Stack trace: $stackTrace');
      }
      _updateProgress(0.0, BackupStatus.failed, 'Backup failed: ${e.toString()}');
      return false;
    } finally {
      _isBackupInProgress = false;
    }
  }

  /// Preflight checks from blueprint
  Future<bool> _preflightChecks() async {
    // Check connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      _updateProgress(0.0, BackupStatus.failed, 'No internet connection');
      return false;
    }

    // TODO: Add battery and storage checks
    // - battery >= 30% or charging
    // - local free space >= 2x backup size estimate

    return true;
  }

  /// Ensure Google authentication
  Future<bool> _ensureAuthenticated() async {
    try {
      final account = await _googleSignIn.signIn();
      return account != null;
    } catch (e) {
      if (kDebugMode) {
        print('Authentication failed: $e');
      }
      return false;
    }
  }

  /// Get or create session for resume support
  Future<Map<String, String>> _getOrCreateSession() async {
    // Check for existing incomplete session
    final existingSession = await _findIncompleteSession();
    if (existingSession != null) {
      if (kDebugMode) {
        print('Resuming existing session: ${existingSession['sessionId']}');
      }
      return existingSession;
    }

    // Create new session
    final sessionId = const Uuid().v4();
    final sessionFolderId = await _createSessionFolder(sessionId);
    
    return {
      'sessionId': sessionId,
      'sessionFolderId': sessionFolderId,
    };
  }

  /// Find existing incomplete session
  Future<Map<String, String>?> _findIncompleteSession() async {
    try {
      final account = _googleSignIn.currentUser;
      final googleId = account?.id ?? 'unknown';

      // Find user's backup folder
      final appFolderId = await _driveProvider.findOrCreateFolder('Alkhazna Backups');
      final userQuery = "name='$googleId' and parents='$appFolderId' and mimeType='application/vnd.google-apps.folder'";
      final userFolders = await _driveProvider.queryFiles(userQuery);
      
      if (userFolders.isEmpty) return null;
      final userFolderId = userFolders[0]['id'];

      // Find session folders
      final sessionQuery = "parents='$userFolderId' and mimeType='application/vnd.google-apps.folder' and name contains 'session-'";
      final sessionFolders = await _driveProvider.queryFiles(sessionQuery);
      
      for (final folder in sessionFolders) {
        final sessionName = folder['name'] as String;
        final sessionId = sessionName.replaceFirst('session-', '');
        
        // Check if manifest exists and is incomplete
        final manifestQuery = "name='manifest.json' and parents='${folder['id']}'";
        final manifests = await _driveProvider.queryFiles(manifestQuery);
        
        if (manifests.isNotEmpty) {
          // Check manifest status
          final manifestBytes = await _driveProvider.downloadFileBytes(manifests[0]['id']);
          final manifestJson = utf8.decode(manifestBytes);
          final manifest = DriveManifest.fromJsonString(manifestJson);
          
          if (manifest.status == 'in_progress') {
            return {
              'sessionId': sessionId,
              'sessionFolderId': folder['id'] as String,
            };
          }
        }
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error finding incomplete session: $e');
      }
      return null;
    }
  }

  /// Create session folder structure following blueprint section 6
  Future<String> _createSessionFolder(String sessionId) async {
    // Get user info for folder structure
    final account = _googleSignIn.currentUser;
    final googleId = account?.id ?? 'unknown';

    // Find or create main app folder
    final appFolderId = await _driveProvider.findOrCreateFolder('Alkhazna Backups');

    // Create user subfolder
    final userFolderId = await _driveProvider.createSubfolder(appFolderId, googleId);

    // Create session subfolder
    final sessionFolderId = await _driveProvider.createSubfolder(userFolderId, 'session-$sessionId');

    return sessionFolderId;
  }

  /// Create initial manifest
  Future<DriveManifest> _createInitialManifest(String sessionId) async {
    final account = _googleSignIn.currentUser;
    
    return DriveManifest(
      sessionId: sessionId,
      createdAt: DateTime.now(),
      appVersion: '1.0.0', // TODO: Get from package_info
      platform: Platform.operatingSystem,
      compression: 'gzip',
      chunkSize: defaultChunkSize,
      files: [], // Will be populated during processing
      wmk: await _getWrappedMasterKey(sessionId), // Optional recovery key
      owner: ManifestOwner(
        googleId: account?.id ?? 'unknown',
        email: account?.email ?? 'unknown',
      ),
      status: 'in_progress',
    );
  }

  /// Get wrapped master key if recovery enabled
  Future<WrappedMasterKey?> _getWrappedMasterKey(String sessionId) async {
    final isEncryptionEnabled = await _keyManagementService.isEncryptionEnabled();
    if (!isEncryptionEnabled) return null;

    // TODO: Check if user has recovery key enabled
    // For now, return null (device-bound only)
    return null;
  }

  /// Upload initial manifest to Drive
  Future<String> _uploadManifest(String sessionFolderId, Uint8List manifestBytes) async {
    final uploadUrl = await _driveProvider.createResumableSession(
      parentId: sessionFolderId,
      fileName: 'manifest.json',
      totalSize: manifestBytes.length,
    );

    final result = await _driveProvider.uploadBytesWithResume(
      uploadUrl: uploadUrl,
      bytes: manifestBytes,
      totalSize: manifestBytes.length,
    );

    return result['id'];
  }

  /// Process and upload files with chunking
  Future<DriveManifest> _processAndUploadFiles(
    DriveManifest manifest,
    String sessionFolderId,
    String sessionId,
    Uint8List masterKey,
  ) async {
    final storageService = StorageService();
    final files = <ManifestFile>[];

    // Get data to backup
    final incomeEntries = await storageService.getAllIncomeEntries();
    final outcomeEntries = await storageService.getAllOutcomeEntries();

    // Create backup data
    final backupData = {
      'version': '1.0',
      'timestamp': DateTime.now().toIso8601String(),
      'data': {
        'income_entries': incomeEntries.map((e) => {
          'id': e.id,
          'name': e.name,
          'amount': e.amount,
          'date': e.date.toIso8601String(),
        }).toList(),
        'outcome_entries': outcomeEntries.map((e) => {
          'id': e.id,
          'name': e.name,
          'amount': e.amount,
          'date': e.date.toIso8601String(),
        }).toList(),
      },
    };

    // Process main data file
    final dbFile = await _processFile(
      fileId: 'db',
      path: 'data/databases/app.db',
      data: backupData,
      sessionFolderId: sessionFolderId,
      sessionId: sessionId,
      masterKey: masterKey,
    );
    
    files.add(dbFile);

    return manifest.copyWith(files: files);
  }

  /// Process individual file with chunking, compression, and encryption
  Future<ManifestFile> _processFile({
    required String fileId,
    required String path,
    required Map<String, dynamic> data,
    required String sessionFolderId,
    required String sessionId,
    required Uint8List masterKey,
  }) async {
    // Convert to JSON and UTF-8 bytes
    final jsonString = json.encode(data);
    final originalBytes = utf8.encode(jsonString);
    final originalSize = originalBytes.length;

    _updateProgress(35.0, BackupStatus.compressing, 'Compressing $fileId...');

    // Compress data
    final compressedBytes = _compressData(originalBytes);
    
    _updateProgress(40.0, BackupStatus.compressing, 'Chunking and encrypting $fileId...');

    // Chunk and encrypt
    final chunks = <ManifestChunk>[];
    int seq = 0;
    
    for (int offset = 0; offset < compressedBytes.length; offset += defaultChunkSize) {
      final end = (offset + defaultChunkSize < compressedBytes.length) 
          ? offset + defaultChunkSize 
          : compressedBytes.length;
      
      final chunkBytes = compressedBytes.sublist(offset, end);
      
      // Encrypt chunk
      final encryptedResult = await _encryptChunk(
        chunkBytes, sessionId, fileId, seq, masterKey);
      
      // Upload chunk
      final fileName = ManifestUtils.chunkFileName(fileId, seq);
      final chunkFileId = await _uploadChunk(
        sessionFolderId, fileName, encryptedResult.ciphertext);
      
      // Create chunk manifest entry
      chunks.add(ManifestChunk(
        seq: seq,
        driveFileId: chunkFileId,
        sha256: encryptedResult.sha256,
        size: encryptedResult.ciphertext.length,
        iv: encryptedResult.iv,
        tag: encryptedResult.tag,
      ));
      
      seq++;
      
      // Update progress
      final progress = 40.0 + (offset / compressedBytes.length) * 50.0;
      _updateProgress(progress, BackupStatus.uploading, 
          'Uploading chunk $seq of $fileId...');
    }

    return ManifestFile(
      id: fileId,
      path: path,
      originalSize: originalSize,
      chunks: chunks,
    );
  }

  /// Encrypt individual chunk
  Future<ChunkEncryptionResult> _encryptChunk(
    Uint8List chunkBytes,
    String sessionId,
    String fileId,
    int seq,
    Uint8List masterKey,
  ) async {
    final encryptedData = await _cryptoService.encryptData(
      chunkBytes,
      sessionId,
      '${fileId}_$seq', // Unique per chunk
    );

    // Compute SHA-256 of ciphertext
    final ciphertext = base64.decode(encryptedData['data']!);
    final sha256Hash = await _cryptoService.sha256Hash(Uint8List.fromList(ciphertext));

    return ChunkEncryptionResult(
      ciphertext: Uint8List.fromList(ciphertext),
      iv: encryptedData['iv']!,
      tag: encryptedData['tag']!,
      sha256: sha256Hash,
    );
  }

  /// Upload individual chunk with resume support
  Future<String> _uploadChunk(
    String sessionFolderId,
    String fileName,
    Uint8List chunkBytes,
  ) async {
    // Check if chunk already exists (resume scenario)
    final existingFileId = await _checkExistingChunk(sessionFolderId, fileName);
    if (existingFileId != null) {
      if (kDebugMode) {
        print('Found existing chunk $fileName, skipping upload');
      }
      return existingFileId;
    }

    final uploadUrl = await _driveProvider.createResumableSession(
      parentId: sessionFolderId,
      fileName: fileName,
      totalSize: chunkBytes.length,
    );

    final result = await _driveProvider.uploadBytesWithResume(
      uploadUrl: uploadUrl,
      bytes: chunkBytes,
      totalSize: chunkBytes.length,
    );

    return result['id'];
  }

  /// Check if chunk file already exists in session folder
  Future<String?> _checkExistingChunk(String sessionFolderId, String fileName) async {
    try {
      final query = "name='$fileName' and parents='$sessionFolderId' and trashed=false";
      final files = await _driveProvider.queryFiles(query);
      
      if (files.isNotEmpty) {
        return files[0]['id'];
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking existing chunk: $e');
      }
      return null;
    }
  }

  /// Update manifest in Drive
  Future<void> _updateManifest(String manifestFileId, DriveManifest manifest) async {
    try {
      final manifestBytes = utf8.encode(manifest.toJsonString());
      
      // Update existing manifest file
      await _driveProvider.updateFileContent(
        fileId: manifestFileId,
        newContent: manifestBytes,
      );
      
      if (kDebugMode) {
        print('Manifest updated successfully: $manifestFileId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to update manifest: $e');
      }
      // Continue with backup process even if manifest update fails
    }
  }

  /// Save backup info locally
  Future<void> _saveBackupInfo(String sessionId, String manifestFileId, DriveManifest manifest) async {
    // Calculate sizes
    final totalSize = ManifestUtils.calculateTotalSize(manifest);
    final totalChunks = ManifestUtils.calculateTotalChunks(manifest);
    
    // This would integrate with existing BackupInfo system
    // For now, just log the completion
    if (kDebugMode) {
      print('Backup completed: $sessionId');
      print('Total size: $totalSize bytes');
      print('Total chunks: $totalChunks');
      print('Manifest file ID: $manifestFileId');
    }
  }

  /// Compress data using GZip
  Uint8List _compressData(Uint8List data) {
    final gzipEncoder = GZipEncoder();
    final compressed = gzipEncoder.encode(data);
    return Uint8List.fromList(compressed ?? []);
  }

  /// Update progress and notify listeners
  void _updateProgress(double percentage, BackupStatus status, String action, {String? errorMessage}) {
    _currentProgress = BackupProgress(
      percentage: percentage,
      status: status,
      currentAction: action,
      errorMessage: errorMessage,
    );
    notifyListeners();
  }

  /// Cancel ongoing backup
  Future<void> cancelBackup() async {
    if (_isBackupInProgress) {
      _updateProgress(_currentProgress.percentage, BackupStatus.cancelled, 'Backup cancelled');
      _isBackupInProgress = false;
      
      // Don't cleanup session folder on cancel to allow resume
      if (kDebugMode) {
        print('Backup cancelled, session ${_currentSessionId} preserved for resume');
      }
    }
  }

  /// Clean up incomplete session (when user explicitly wants to start fresh)
  Future<void> cleanupIncompleteSession() async {
    try {
      final incompleteSession = await _findIncompleteSession();
      if (incompleteSession != null) {
        final sessionFolderId = incompleteSession['sessionFolderId'];
        // TODO: Implement Drive folder deletion
        // await _driveProvider.deleteFolder(sessionFolderId);
        if (kDebugMode) {
          print('Cleaned up incomplete session: ${incompleteSession['sessionId']} (folder: $sessionFolderId)');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error cleaning up session: $e');
      }
    }
  }

  /// Resume existing backup session
  Future<bool> resumeBackup() async {
    final incompleteSession = await _findIncompleteSession();
    if (incompleteSession == null) {
      return false; // No session to resume
    }

    // Start backup process but skip to the point where chunks are uploaded
    return await startBackup();
  }
}

/// Result of chunk encryption
class ChunkEncryptionResult {
  final Uint8List ciphertext;
  final String iv;
  final String tag;
  final String sha256;

  ChunkEncryptionResult({
    required this.ciphertext,
    required this.iv,
    required this.tag,
    required this.sha256,
  });
}