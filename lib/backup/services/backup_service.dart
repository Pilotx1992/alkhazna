import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../models/income_entry.dart';
import '../../models/outcome_entry.dart';
import '../models/backup_metadata.dart';
import '../models/backup_status.dart';
import '../models/restore_result.dart';
import 'key_manager.dart';
import 'encryption_service.dart';
import 'google_drive_service.dart';
import '../utils/backup_scheduler.dart';
import '../../services/drive_auth_service.dart';
import '../../services/connectivity_service.dart';
import '../../services/hive_snapshot_service.dart';

/// Main backup service for WhatsApp-style backup system
class BackupService extends ChangeNotifier {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  final KeyManager _keyManager = KeyManager();
  final EncryptionService _encryptionService = EncryptionService();
  final GoogleDriveService _driveService = GoogleDriveService();
  final DriveAuthService _driveAuthService = DriveAuthService();
  final ConnectivityService _connectivityService = ConnectivityService();
  final HiveSnapshotService _snapshotService = HiveSnapshotService();

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

  static const String _backupPrefix = 'alkhazna_backup_';

  /// Create backup with silent authentication (Offline-First approach)
  Future<bool> createBackup() async {
    if (_isBackupInProgress) return false;

    _isBackupInProgress = true;

    try {
      _updateProgress(0, BackupStatus.preparing, 'Checking connectivity...');

      // Step 1: Check connectivity
      final isConnected = await _connectivityService.isOnline();
      if (!isConnected) {
        _updateProgress(0, BackupStatus.failed, 'No internet connection');
        return false;
      }

      // Step 1.5: Check network preference (Wi-Fi only or Wi-Fi + Mobile)
      final networkPreference = await BackupScheduler.getNetworkPreference();
      if (networkPreference == NetworkPreference.wifiOnly) {
        final isWifi = await _connectivityService.isWifiConnected();
        if (!isWifi) {
          _updateProgress(0, BackupStatus.failed, 'Wi-Fi connection required');
          return false;
        }
      }

      // Step 2: Silent authentication
      _updateProgress(10, BackupStatus.preparing, 'Signing in...');
      final authHeaders = await _driveAuthService.getAuthHeaders(interactiveFallback: true);
      if (authHeaders == null) {
        _updateProgress(0, BackupStatus.failed, 'Sign-in failed');
        return false;
      }

      // Step 3: Create database snapshot
      _updateProgress(30, BackupStatus.preparing, 'Packaging local data...');
      final databaseBytes = await _snapshotService.packageAll();

      // Step 4: Get or create master key
      _updateProgress(40, BackupStatus.preparing, 'Preparing encryption...');
      final masterKey = await _keyManager.getOrCreatePersistentMasterKey();
      if (masterKey == null) {
        _updateProgress(0, BackupStatus.failed, 'Failed to get encryption key');
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
      final fileName = '${_backupPrefix}' + DateTime.now().millisecondsSinceEpoch.toString() + '.crypt14';
      final driveFileId = await _driveService.uploadFile(
        fileName: fileName,
        content: Uint8List.fromList(encryptedBytes),
        mimeType: 'application/json',
      );

      if (driveFileId != null) {
        await _pruneOldBackups(keep: 5);
      }

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

      // Update last backup time only after successful backup
      await BackupScheduler.updateLastBackupTime();

      if (kDebugMode) {
        print('? Backup completed successfully');
        print('   Backup ID: $backupId');
        print('   Drive File ID: $driveFileId');
        print('   Original size: ${databaseBytes.length} bytes');
        print('   Encrypted size: ${encryptedBytes.length} bytes');
      }

      // Auto-verify backup silently in background
      _verifyBackupSilently(backupId, driveFileId);

      return true;

    } catch (e) {
      if (kDebugMode) {
        print('? Backup failed: $e');
      }
      _updateProgress(0, BackupStatus.failed, 'Backup failed: ${e.toString()}');
      return false;
    } finally {
      _isBackupInProgress = false;
    }
  }

  /// Start backup process (legacy method - kept for compatibility)
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

      // Step 1.5: Check network preference (Wi-Fi only or Wi-Fi + Mobile)
      final networkPreference = await BackupScheduler.getNetworkPreference();
      if (networkPreference == NetworkPreference.wifiOnly) {
        final isWifi = await _connectivityService.isWifiConnected();
        if (!isWifi) {
          _updateProgress(0, BackupStatus.failed, 'Wi-Fi connection required');
          return false;
        }
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
      final fileName = '${_backupPrefix}' + DateTime.now().millisecondsSinceEpoch.toString() + '.crypt14';
      final driveFileId = await _driveService.uploadFile(
        fileName: fileName,
        content: Uint8List.fromList(encryptedBytes),
        mimeType: 'application/json',
      );

      if (driveFileId != null) {
        await _pruneOldBackups(keep: 5);
      }

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

      // Update last backup time only after successful backup
      await BackupScheduler.updateLastBackupTime();

      if (kDebugMode) {
        print('✅ Backup completed successfully');
        print('   Backup ID: $backupId');
        print('   Drive File ID: $driveFileId');
        print('   Original size: ${databaseBytes.length} bytes');
        print('   Encrypted size: ${encryptedBytes.length} bytes');
      }

      // Auto-verify backup silently in background
      _verifyBackupSilently(backupId, driveFileId);

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
      final backupFiles = await _driveService.listFiles(query: "name contains '$_backupPrefix'");
      
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

  /// Keep only last [keep] backups in Drive (by modifiedTime desc)
  Future<void> _pruneOldBackups({int keep = 5}) async {
    try {
      final files = await _driveService.listFiles(query: "name contains '$_backupPrefix'");
      if (files.length <= keep) return;
      for (var i = keep; i < files.length; i++) {
        final f = files[i];
        if (f.id != null) {
          await _driveService.deleteFileById(f.id!);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Retention prune error: ' + e.toString());
      }
    }
  }

  /// Check for existing backup
  Future<BackupMetadata?> findExistingBackup() async {
    try {
      if (!await _driveService.initialize()) {
        return null;
      }

      final backupFiles = await _driveService.listFiles(query: "name contains '$_backupPrefix'");
      
      if (backupFiles.isEmpty) {
        return null;
      }

      final backupFile = backupFiles.first;
      final currentUser = _driveService.currentUser;
      
      // Get detailed file info to ensure we have the correct size
      final detailedFileInfo = await _driveService.getFileInfo(backupFile.id!);
      final fileSize = int.tryParse(detailedFileInfo?.size ?? backupFile.size ?? '0') ?? 0;
      
      if (kDebugMode) {
        print('📊 Backup file size from API: ${backupFile.size}');
        print('📊 Detailed file size: ${detailedFileInfo?.size}');
        print('📊 Final file size: $fileSize bytes');
      }
      
      return BackupMetadata(
        version: '1.0',
        userEmail: currentUser?.email ?? 'Unknown',
        normalizedEmail: currentUser?.email.split('@').first ?? 'unknown',
        googleId: currentUser?.id ?? 'unknown',
        deviceId: 'Unknown Device',
        createdAt: backupFile.modifiedTime ?? DateTime.now(),
        checksum: 'unknown',
        fileSizeBytes: fileSize,
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
      if (kDebugMode) {
        print('💾 Creating Hive database backup...');
      }

      // Get all data from Hive boxes
      final Map<String, dynamic> backupData = {};
      
      // Backup income entries
      final incomeBox = await Hive.openBox<List<dynamic>>('income_entries');
      final incomeData = <String, dynamic>{};
      
      if (kDebugMode) {
        print('📊 Income box keys: ${incomeBox.keys.toList()}');
        print('📊 Income box length: ${incomeBox.length}');
      }
      
      for (final key in incomeBox.keys) {
        final value = incomeBox.get(key);
        if (value is List) {
          // Convert IncomeEntry objects to JSON for serialization
          final jsonList = value.map((item) {
            if (item is IncomeEntry) {
              return item.toJson();
            } else if (item is Map<String, dynamic>) {
              return item; // Already in JSON format
            } else {
              // Try to convert dynamic object to IncomeEntry
              return (item as dynamic).toJson();
            }
          }).toList();
          incomeData[key.toString()] = jsonList;
        } else {
          incomeData[key.toString()] = value;
        }
        if (kDebugMode) {
          print('📊 Income key: $key, value type: ${value.runtimeType}, length: ${value is List ? value.length : 'not a list'}');
        }
      }
      backupData['income_entries'] = incomeData;
      
      // Backup outcome entries  
      final outcomeBox = await Hive.openBox<List<dynamic>>('outcome_entries');
      final outcomeData = <String, dynamic>{};
      
      if (kDebugMode) {
        print('📊 Outcome box keys: ${outcomeBox.keys.toList()}');
        print('📊 Outcome box length: ${outcomeBox.length}');
      }
      
      for (final key in outcomeBox.keys) {
        final value = outcomeBox.get(key);
        if (value is List) {
          // Convert OutcomeEntry objects to JSON for serialization
          final jsonList = value.map((item) {
            if (item is OutcomeEntry) {
              return item.toJson();
            } else if (item is Map<String, dynamic>) {
              return item; // Already in JSON format
            } else {
              // Try to convert dynamic object to OutcomeEntry
              return (item as dynamic).toJson();
            }
          }).toList();
          outcomeData[key.toString()] = jsonList;
        } else {
          outcomeData[key.toString()] = value;
        }
        if (kDebugMode) {
          print('📊 Outcome key: $key, value type: ${value.runtimeType}, length: ${value is List ? value.length : 'not a list'}');
        }
      }
      backupData['outcome_entries'] = outcomeData;

      // Convert to JSON bytes
      final jsonString = json.encode(backupData);
      final bytes = utf8.encode(jsonString);
      
      if (kDebugMode) {
        print('💾 Encrypting database for backup...');
        print('   Database size: ${bytes.length} bytes');
        print('   Income entries: ${incomeData.length} months');
        print('   Outcome entries: ${outcomeData.length} months');
      }
      
      return Uint8List.fromList(bytes);
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
      if (kDebugMode) {
        print('💾 Restoring Hive database from backup...');
      }

      if (databaseBytes.isEmpty) {
        if (kDebugMode) {
          print('⚠️ No data to restore (empty backup)');
        }

        return RestoreResult.success(
          incomeEntries: 0,
          outcomeEntries: 0,
          backupDate: DateTime.now(),
          sourceDevice: 'Unknown Device',
        );
      }

      // Parse JSON from backup
      final jsonString = utf8.decode(databaseBytes);
      final Map<String, dynamic> backupData = json.decode(jsonString);
      
      int restoredIncomeEntries = 0;
      int restoredOutcomeEntries = 0;

      // Restore income entries
      if (backupData.containsKey('income_entries')) {
        final incomeBox = await Hive.openBox<List<dynamic>>('income_entries');
        await incomeBox.clear(); // Clear existing data
        
        final incomeData = backupData['income_entries'] as Map<String, dynamic>;
        for (final entry in incomeData.entries) {
          if (entry.value is List) {
            // Convert JSON objects back to IncomeEntry objects
            final entryList = (entry.value as List).map((item) {
              try {
                if (item is Map<String, dynamic>) {
                  // Backward compatibility: add createdAt if missing
                  if (!item.containsKey('createdAt') && item['amount'] != null && (item['amount'] as num) > 0) {
                    item['createdAt'] = item['date'];
                  }
                  return IncomeEntry.fromJson(item);
                } else if (item is IncomeEntry) {
                  return item; // Already correct type
                } else {
                  // Try to convert from dynamic
                  return IncomeEntry.fromJson(item as Map<String, dynamic>);
                }
              } catch (e) {
                if (kDebugMode) {
                  print('⚠️ Error converting income entry: $e, item: $item');
                }
                rethrow;
              }
            }).toList();
            
            await incomeBox.put(entry.key, entryList);
            restoredIncomeEntries += entryList.length;
            
            if (kDebugMode) {
              print('📱 Restored ${entry.key}: ${entryList.length} income entries');
            }
          } else {
            await incomeBox.put(entry.key, entry.value);
          }
        }
        
        if (kDebugMode) {
          print('📱 Restored ${incomeData.length} income months total');
        }
      }

      // Restore outcome entries
      if (backupData.containsKey('outcome_entries')) {
        final outcomeBox = await Hive.openBox<List<dynamic>>('outcome_entries');
        await outcomeBox.clear(); // Clear existing data
        
        final outcomeData = backupData['outcome_entries'] as Map<String, dynamic>;
        for (final entry in outcomeData.entries) {
          if (entry.value is List) {
            // Convert JSON objects back to OutcomeEntry objects
            final entryList = (entry.value as List).map((item) {
              try {
                if (item is Map<String, dynamic>) {
                  return OutcomeEntry.fromJson(item);
                } else if (item is OutcomeEntry) {
                  return item; // Already correct type
                } else {
                  // Try to convert from dynamic
                  return OutcomeEntry.fromJson(item as Map<String, dynamic>);
                }
              } catch (e) {
                if (kDebugMode) {
                  print('⚠️ Error converting outcome entry: $e, item: $item');
                }
                rethrow;
              }
            }).toList();
            
            await outcomeBox.put(entry.key, entryList);
            restoredOutcomeEntries += entryList.length;
            
            if (kDebugMode) {
              print('📱 Restored ${entry.key}: ${entryList.length} outcome entries');
            }
          } else {
            await outcomeBox.put(entry.key, entry.value);
          }
        }
        
        if (kDebugMode) {
          print('📱 Restored ${outcomeData.length} outcome months total');
        }
      }

      if (kDebugMode) {
        print('✅ Database restored successfully');
        print('   Total income entries: $restoredIncomeEntries');
        print('   Total outcome entries: $restoredOutcomeEntries');
      }

      return RestoreResult.success(
        incomeEntries: restoredIncomeEntries,
        outcomeEntries: restoredOutcomeEntries,
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

  /// Sign in to Google (interactive)
  Future<bool> signIn() async {
    final success = await _driveService.signIn();
    notifyListeners();
    return success;
  }

  /// Check if user is signed in
  bool get isSignedIn => _driveService.isSignedIn;

  /// Get current user
  get currentUser => _driveService.currentUser;

  /// Perform automatic silent sign in
  Future<bool> performAutoSignIn() async {
    try {
      // Check if already signed in
      if (isSignedIn) {
        return true;
      }

      // Try to initialize the drive service which will attempt silent sign in
      final success = await _driveService.initialize();
      
      if (success) {
        return isSignedIn;
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Auto sign in error: $e');
      }
      return false;
    }
  }

  /// Verify backup silently in background (no UI updates)
  Future<void> _verifyBackupSilently(String backupId, String driveFileId) async {
    try {
      if (kDebugMode) {
        print('?? Starting silent verification for backup: $backupId');
      }

      // Get file info from Drive
      final fileInfo = await _driveService.getFileInfo(driveFileId);
      if (fileInfo == null) {
        if (kDebugMode) {
          print('? Verification failed: File not found on Drive');
        }
        return;
      }

      // Download the backup file
      final downloadedBytes = await _driveService.downloadFile(driveFileId);
      if (downloadedBytes == null || downloadedBytes.isEmpty) {
        if (kDebugMode) {
          print('? Verification failed: Could not download file');
        }
        return;
      }

      // Verify file size (skip if size info is not available from Drive)
      final sizeString = fileInfo.size;
      if (sizeString != null && sizeString.isNotEmpty) {
        final expectedSize = int.tryParse(sizeString) ?? 0;
        if (expectedSize > 0 && downloadedBytes.length != expectedSize) {
          if (kDebugMode) {
            print('? Verification failed: Size mismatch (expected: $expectedSize, actual: ${downloadedBytes.length})');
          }
          return;
        }
      }

      // Try to decrypt to verify integrity
      final encryptedDataJson = String.fromCharCodes(downloadedBytes);
      final encryptedData = json.decode(encryptedDataJson);

      final masterKey = await _keyManager.getOrCreatePersistentMasterKey();
      if (masterKey == null) {
        if (kDebugMode) {
          print('? Verification failed: Could not get master key');
        }
        return;
      }

      final decryptedBytes = await _encryptionService.decryptDatabase(
        encryptedBackup: encryptedData,
        masterKey: masterKey,
      );

      if (decryptedBytes == null || decryptedBytes.isEmpty) {
        if (kDebugMode) {
          print('? Verification failed: Decryption failed');
        }
        return;
      }

      if (kDebugMode) {
        print('? Backup verified successfully!');
        print('   Backup ID: $backupId');
        print('   File ID: $driveFileId');
        print('   Size: ${downloadedBytes.length} bytes');
        print('   Decrypted size: ${decryptedBytes.length} bytes');
      }

    } catch (e) {
      if (kDebugMode) {
        print('? Silent verification error: $e');
      }
    }
  }
}

/// Verification report for a single Drive backup file
class BackupVerificationReport {
  final String fileName;
  final String fileId;
  final bool isValid;
  final String? expectedChecksum;
  final String? actualChecksum;
  final int sizeBytes;
  final DateTime? modifiedTime;
  final String? error;

  const BackupVerificationReport({
    required this.fileName,
    required this.fileId,
    required this.isValid,
    required this.expectedChecksum,
    required this.actualChecksum,
    required this.sizeBytes,
    required this.modifiedTime,
    this.error,
  });
}

