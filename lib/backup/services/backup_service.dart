import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/backup_metadata.dart';
import '../models/backup_status.dart';
import '../models/restore_result.dart';
import 'key_manager.dart';
import 'encryption_service.dart';
import 'google_drive_service.dart';

/// Main backup service for WhatsApp-style backup system
class BackupService extends ChangeNotifier {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  final KeyManager _keyManager = KeyManager();
  final EncryptionService _encryptionService = EncryptionService();
  final GoogleDriveService _driveService = GoogleDriveService();

  OperationProgress _currentProgress = const OperationProgress(
    percentage: 0,
    backupStatus: BackupStatus.idle,
    currentAction: 'Ready',
  );

  bool _isBackupInProgress = false;
  bool _isRestoreInProgress = false;

  OperationProgress get currentProgress => _currentProgress;
  bool get isBackupInProgress => _isBackupInProgress;
  bool get isRestoreInProgress => _isRestoreInProgress;

  static const String _backupFileName = 'alkhazna_backup.db.crypt14';

  /// Start backup process
  Future<bool> startBackup() async {
    if (_isBackupInProgress) return false;

    _isBackupInProgress = true;
    
    try {
      _updateProgress(0, BackupStatus.preparing, 'Checking connectivity...');

      // Step 1: Check connectivity
      final isConnected = await _checkConnectivity();
      if (!isConnected) {
        _updateProgress(0, BackupStatus.failed, 'No internet connection');
        return false;
      }

      // Step 2: Initialize Drive service
      _updateProgress(10, BackupStatus.preparing, 'Connecting to Google Drive...');
      final driveInitialized = await _driveService.initialize();
      if (!driveInitialized) {
        _updateProgress(0, BackupStatus.failed, 'Failed to connect to Google Drive');
        return false;
      }

      // Step 3: Get or create master key
      _updateProgress(20, BackupStatus.preparing, 'Preparing encryption...');
      final masterKey = await _keyManager.getOrCreatePersistentMasterKey();
      if (masterKey == null) {
        _updateProgress(0, BackupStatus.failed, 'Failed to get encryption key');
        return false;
      }

      // Step 4: Create database backup
      _updateProgress(30, BackupStatus.preparing, 'Preparing your data...');
      final databaseBytes = await _createDatabaseBackup();
      if (databaseBytes == null) {
        _updateProgress(0, BackupStatus.failed, 'Failed to create database backup');
        return false;
      }

      // Step 5: Encrypt database
      _updateProgress(50, BackupStatus.encrypting, 'Encrypting your data...');
      final backupId = const Uuid().v4();
      final encryptedData = await _encryptionService.encryptDatabase(
        databaseBytes: databaseBytes,
        masterKey: masterKey,
        backupId: backupId,
      );

      if (encryptedData == null) {
        _updateProgress(0, BackupStatus.failed, 'Failed to encrypt data');
        return false;
      }

      // Step 6: Upload to Drive
      _updateProgress(70, BackupStatus.uploading, 'Uploading to Google Drive...');
      final encryptedBytes = utf8.encode(json.encode(encryptedData));
      final driveFileId = await _driveService.uploadFile(
        fileName: _backupFileName,
        content: Uint8List.fromList(encryptedBytes),
        mimeType: 'application/json',
      );

      if (driveFileId == null) {
        _updateProgress(0, BackupStatus.failed, 'Failed to upload backup');
        return false;
      }

      // Step 7: Save backup metadata
      _updateProgress(90, BackupStatus.uploading, 'Finalizing backup...');
      await _saveBackupMetadata(
        backupId: backupId,
        driveFileId: driveFileId,
        originalSize: databaseBytes.length,
        encryptedSize: encryptedBytes.length,
      );

      _updateProgress(100, BackupStatus.completed, 'Backup completed successfully!');
      
      if (kDebugMode) {
        print('✅ Backup completed successfully');
        print('   Backup ID: $backupId');
        print('   Drive File ID: $driveFileId');
        print('   Original size: ${databaseBytes.length} bytes');
        print('   Encrypted size: ${encryptedBytes.length} bytes');
      }

      return true;

    } catch (e) {
      if (kDebugMode) {
        print('💥 Backup failed: $e');
      }
      _updateProgress(0, BackupStatus.failed, 'Backup failed: ${e.toString()}');
      return false;
    } finally {
      _isBackupInProgress = false;
    }
  }

  /// Start restore process
  Future<RestoreResult> startRestore() async {
    if (_isRestoreInProgress) {
      return RestoreResult.failure('Restore already in progress');
    }

    _isRestoreInProgress = true;

    try {
      _updateProgress(0, null, 'Checking for backup...', RestoreStatus.downloading);

      // Step 1: Check connectivity
      final isConnected = await _checkConnectivity();
      if (!isConnected) {
        _updateProgress(0, null, 'No internet connection', RestoreStatus.failed);
        return RestoreResult.failure('No internet connection');
      }

      // Step 2: Initialize Drive service
      _updateProgress(10, null, 'Connecting to Google Drive...', RestoreStatus.downloading);
      final driveInitialized = await _driveService.initialize();
      if (!driveInitialized) {
        _updateProgress(0, null, 'Failed to connect to Google Drive', RestoreStatus.failed);
        return RestoreResult.failure('Failed to connect to Google Drive');
      }

      // Step 3: Find backup file
      _updateProgress(20, null, 'Looking for backup...', RestoreStatus.downloading);
      final backupFiles = await _driveService.listFiles(query: "name='$_backupFileName'");
      
      if (backupFiles.isEmpty) {
        _updateProgress(0, null, 'No backup found', RestoreStatus.failed);
        return RestoreResult.failure('No backup found for this Google account');
      }

      // Step 4: Download backup
      _updateProgress(40, null, 'Downloading backup...', RestoreStatus.downloading);
      final backupFile = backupFiles.first;
      final encryptedBytes = await _driveService.downloadFile(backupFile.id!);
      
      if (encryptedBytes == null) {
        _updateProgress(0, null, 'Failed to download backup', RestoreStatus.failed);
        return RestoreResult.failure('Failed to download backup file');
      }

      // Step 5: Get master key
      _updateProgress(60, null, 'Preparing decryption...', RestoreStatus.decrypting);
      final masterKey = await _keyManager.getOrCreatePersistentMasterKey();
      if (masterKey == null) {
        _updateProgress(0, null, 'Failed to get encryption key', RestoreStatus.failed);
        return RestoreResult.failure('Failed to get encryption key');
      }

      // Step 6: Decrypt backup
      _updateProgress(70, null, 'Decrypting backup...', RestoreStatus.decrypting);
      final encryptedData = json.decode(utf8.decode(encryptedBytes)) as Map<String, dynamic>;
      final databaseBytes = await _encryptionService.decryptDatabase(
        encryptedBackup: encryptedData,
        masterKey: masterKey,
      );

      if (databaseBytes == null) {
        _updateProgress(0, null, 'Failed to decrypt backup', RestoreStatus.failed);
        return RestoreResult.failure('Failed to decrypt backup. The backup may be corrupted.');
      }

      // Step 7: Restore database
      _updateProgress(85, null, 'Restoring your data...', RestoreStatus.applying);
      final restoreResult = await _restoreDatabase(databaseBytes);
      
      if (!restoreResult.success) {
        _updateProgress(0, null, 'Failed to restore data', RestoreStatus.failed);
        return restoreResult;
      }

      _updateProgress(100, null, 'Restore completed!', RestoreStatus.completed);
      
      if (kDebugMode) {
        print('✅ Restore completed successfully');
      }

      return RestoreResult.success(
        incomeEntries: restoreResult.incomeEntriesRestored ?? 0,
        outcomeEntries: restoreResult.outcomeEntriesRestored ?? 0,
        backupDate: backupFile.modifiedTime ?? DateTime.now(),
        sourceDevice: 'Unknown Device',
      );

    } catch (e) {
      if (kDebugMode) {
        print('💥 Restore failed: $e');
      }
      _updateProgress(0, null, 'Restore failed', RestoreStatus.failed);
      return RestoreResult.failure('Restore failed: ${e.toString()}');
    } finally {
      _isRestoreInProgress = false;
    }
  }

  /// Check for existing backup
  Future<BackupMetadata?> findExistingBackup() async {
    try {
      if (!await _driveService.initialize()) {
        return null;
      }

      final backupFiles = await _driveService.listFiles(query: "name='$_backupFileName'");
      
      if (backupFiles.isEmpty) {
        return null;
      }

      final backupFile = backupFiles.first;
      final currentUser = _driveService.currentUser;
      
      return BackupMetadata(
        version: '1.0',
        userEmail: currentUser?.email ?? 'Unknown',
        normalizedEmail: currentUser?.email?.split('@').first ?? 'unknown',
        googleId: currentUser?.id ?? 'unknown',
        deviceId: 'Unknown Device',
        createdAt: backupFile.modifiedTime ?? DateTime.now(),
        checksum: 'unknown',
        fileSizeBytes: int.tryParse(backupFile.size ?? '0') ?? 0,
        driveFileId: backupFile.id!,
      );
    } catch (e) {
      if (kDebugMode) {
        print('💥 Error finding backup: $e');
      }
      return null;
    }
  }

  /// Create database backup
  Future<Uint8List?> _createDatabaseBackup() async {
    try {
      final databasesPath = await getDatabasesPath();
      final dbPath = '$databasesPath/app.db';
      
      // Check if database exists
      if (!await File(dbPath).exists()) {
        if (kDebugMode) {
          print('⚠️ Database file not found: $dbPath');
        }
        // Create empty database backup
        return Uint8List(0);
      }

      // Read database file
      final dbFile = File(dbPath);
      final bytes = await dbFile.readAsBytes();
      
      if (kDebugMode) {
        print('📱 Database backup created: ${bytes.length} bytes');
      }
      
      return bytes;
    } catch (e) {
      if (kDebugMode) {
        print('💥 Error creating database backup: $e');
      }
      return null;
    }
  }

  /// Restore database from backup
  Future<RestoreResult> _restoreDatabase(Uint8List databaseBytes) async {
    try {
      final databasesPath = await getDatabasesPath();
      final dbPath = '$databasesPath/app.db';
      
      // Close any existing database connections
      try {
        await databaseFactory.deleteDatabase(dbPath);
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Could not delete existing database: $e');
        }
      }

      // Write restored database
      if (databaseBytes.isNotEmpty) {
        final dbFile = File(dbPath);
        await dbFile.writeAsBytes(databaseBytes);
        
        if (kDebugMode) {
          print('📱 Database restored: ${databaseBytes.length} bytes');
        }
      }

      // TODO: Count restored entries by opening database and querying
      // For now, return dummy counts
      return RestoreResult.success(
        incomeEntries: 0,
        outcomeEntries: 0,
        backupDate: DateTime.now(),
        sourceDevice: 'Unknown Device',
      );
    } catch (e) {
      if (kDebugMode) {
        print('💥 Error restoring database: $e');
      }
      return RestoreResult.failure('Failed to restore database: ${e.toString()}');
    }
  }

  /// Save backup metadata
  Future<void> _saveBackupMetadata({
    required String backupId,
    required String driveFileId,
    required int originalSize,
    required int encryptedSize,
  }) async {
    try {
      final currentUser = _driveService.currentUser;
      // This would typically be saved to SharedPreferences or local database
      // For now, we'll just log it
      if (kDebugMode) {
        print('💾 Backup metadata:');
        print('   ID: $backupId');
        print('   Drive File ID: $driveFileId');
        print('   User: ${currentUser?.email}');
        print('   Original size: $originalSize bytes');
        print('   Encrypted size: $encryptedSize bytes');
      }
    } catch (e) {
      if (kDebugMode) {
        print('💥 Error saving backup metadata: $e');
      }
    }
  }

  /// Check network connectivity
  Future<bool> _checkConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult.contains(ConnectivityResult.mobile) || 
             connectivityResult.contains(ConnectivityResult.wifi);
    } catch (e) {
      if (kDebugMode) {
        print('💥 Error checking connectivity: $e');
      }
      return false;
    }
  }

  /// Update progress and notify listeners
  void _updateProgress(
    int percentage, 
    BackupStatus? backupStatus, 
    String action, 
    [RestoreStatus? restoreStatus]
  ) {
    _currentProgress = OperationProgress(
      percentage: percentage,
      backupStatus: backupStatus,
      restoreStatus: restoreStatus,
      currentAction: action,
    );
    notifyListeners();
  }

  /// Cancel current operation
  Future<void> cancelCurrentOperation() async {
    if (_isBackupInProgress) {
      _updateProgress(_currentProgress.percentage, BackupStatus.cancelled, 'Backup cancelled');
      _isBackupInProgress = false;
    }
    
    if (_isRestoreInProgress) {
      _updateProgress(_currentProgress.percentage, null, 'Restore cancelled', RestoreStatus.cancelled);
      _isRestoreInProgress = false;
    }
  }

  /// Get available storage in Google Drive
  Future<int?> getAvailableStorage() async {
    try {
      if (!await _driveService.initialize()) {
        return null;
      }
      return await _driveService.getAvailableStorage();
    } catch (e) {
      if (kDebugMode) {
        print('💥 Error getting storage info: $e');
      }
      return null;
    }
  }

  /// Sign out from Google Drive
  Future<void> signOut() async {
    await _driveService.signOut();
    await _keyManager.clearAllKeys();
    notifyListeners();
  }

  /// Check if user is signed in
  bool get isSignedIn => _driveService.isSignedIn;

  /// Get current user
  get currentUser => _driveService.currentUser;
}