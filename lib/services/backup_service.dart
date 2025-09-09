import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:archive/archive.dart';
import '../models/backup_models.dart';
import 'storage_service.dart';
import 'crypto_service.dart';
import 'key_management_service.dart';

class BackupService extends ChangeNotifier {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveFileScope],
  );

  drive.DriveApi? _driveApi;
  BackupProgress _currentProgress = BackupProgress();
  bool _isBackupInProgress = false;
  
  final CryptoService _cryptoService = CryptoService();
  final KeyManagementService _keyManagementService = KeyManagementService();

  BackupProgress get currentProgress => _currentProgress;
  bool get isBackupInProgress => _isBackupInProgress;

  // Initialize Google Drive API
  Future<bool> initialize() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return false;

      final authHeaders = await account.authHeaders;
      final authenticateClient = authenticatedClient(
        http.Client(),
        AccessCredentials(
          AccessToken('Bearer', authHeaders['authorization']!.substring(7), DateTime.now().add(Duration(hours: 1))),
          null,
          ['https://www.googleapis.com/auth/drive.file'],
        ),
      );

      _driveApi = drive.DriveApi(authenticateClient);
      return true;
    } catch (e) {
      print('Failed to initialize Google Drive: $e');
      return false;
    }
  }

  // Check network connectivity
  Future<bool> _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  // Create backup data
  Future<Map<String, dynamic>> _createBackupData() async {
    final storageService = StorageService();
    final incomeEntries = await storageService.getAllIncomeEntries();
    final outcomeEntries = await storageService.getAllOutcomeEntries();

    return {
      'version': '1.0',
      'timestamp': DateTime.now().toIso8601String(),
      'device_info': {
        'platform': Platform.operatingSystem,
        'version': Platform.operatingSystemVersion,
      },
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
  }

  // Compress and encrypt data
  Future<Map<String, dynamic>> _processData(Map<String, dynamic> data, String sessionId) async {
    final jsonString = json.encode(data);
    final originalBytes = utf8.encode(jsonString);
    final originalSize = originalBytes.length;
    
    // Step 1: Compress the data using GZip
    _updateProgress(35.0, BackupStatus.compressing, 'Compressing your data...');
    final compressedBytes = _compressData(originalBytes);
    final compressedSize = compressedBytes.length;
    
    // Calculate compression ratio for logging
    final compressionRatio = (1 - (compressedSize / originalSize)) * 100;
    print('Data compressed: ${originalSize} bytes -> ${compressedSize} bytes (${compressionRatio.toStringAsFixed(1)}% reduction)');
    
    // Step 2: Check if encryption is enabled
    final isEncryptionEnabled = await _keyManagementService.isEncryptionEnabled();
    
    if (isEncryptionEnabled) {
      _updateProgress(45.0, BackupStatus.compressing, 'Encrypting your data...');
      
      // Encrypt the compressed data
      final encryptedData = await _cryptoService.encryptData(
        compressedBytes,
        sessionId,
        'backup_data',
      );
      
      return {
        'compressed': true,
        'encrypted': true,
        'iv': encryptedData['iv'],
        'tag': encryptedData['tag'],
        'data': encryptedData['data'],
        'original_size': originalSize,
        'compressed_size': compressedSize,
        'compression_ratio': compressionRatio,
      };
    } else {
      // Return compressed but unencrypted data
      return {
        'compressed': true,
        'encrypted': false,
        'data': base64.encode(compressedBytes),
        'original_size': originalSize,
        'compressed_size': compressedSize,
        'compression_ratio': compressionRatio,
      };
    }
  }

  // Compress data using GZip
  Uint8List _compressData(Uint8List data) {
    final gzipEncoder = GZipEncoder();
    final compressed = gzipEncoder.encode(data);
    return Uint8List.fromList(compressed ?? []);
  }


  // Upload to Google Drive
  Future<String?> _uploadToDrive(Map<String, dynamic> processedData, String fileName) async {
    if (_driveApi == null) return null;

    try {
      // Convert processed data to bytes for upload
      final jsonString = json.encode(processedData);
      final bytes = utf8.encode(jsonString);
      final data = Uint8List.fromList(bytes);
      
      final driveFile = drive.File();
      driveFile.name = fileName;
      driveFile.parents = ['appDataFolder']; // Store in app's private folder

      final media = drive.Media(Stream.fromIterable([data]), data.length);
      
      final result = await _driveApi!.files.create(
        driveFile,
        uploadMedia: media,
      );

      return result.id;
    } catch (e) {
      print('Upload to Drive failed: $e');
      return null;
    }
  }

  // Start backup process
  Future<bool> startBackup() async {
    if (_isBackupInProgress) return false;
    
    _isBackupInProgress = true;
    _updateProgress(0.0, BackupStatus.preparing, 'Checking connectivity...');

    try {
      // Check connectivity
      final isConnected = await _checkConnectivity();
      if (!isConnected) {
        _updateProgress(0.0, BackupStatus.failed, 'No internet connection', 
            errorMessage: 'Please check your internet connection and try again.');
        return false;
      }

      // Initialize Google Drive
      _updateProgress(10.0, BackupStatus.preparing, 'Connecting to Google Drive...');
      final initialized = await initialize();
      if (!initialized) {
        _updateProgress(0.0, BackupStatus.failed, 'Failed to connect to Google Drive',
            errorMessage: 'Could not authenticate with Google Drive.');
        return false;
      }

      // Create backup data
      _updateProgress(25.0, BackupStatus.compressing, 'Preparing your data...');
      final backupData = await _createBackupData();
      final backupId = const Uuid().v4();
      
      // Process data (encrypt if enabled)
      _updateProgress(40.0, BackupStatus.compressing, 'Processing data...');
      final processedData = await _processData(backupData, backupId);

      // Upload to Drive
      _updateProgress(75.0, BackupStatus.uploading, 'Uploading to Google Drive...');
      final fileName = 'alkhazna_backup_${DateTime.now().millisecondsSinceEpoch}.json';
      
      final driveFileId = await _uploadToDrive(processedData, fileName);
      if (driveFileId == null) {
        _updateProgress(0.0, BackupStatus.failed, 'Upload failed',
            errorMessage: 'Failed to upload backup to Google Drive.');
        return false;
      }

      // Save backup info
      _updateProgress(95.0, BackupStatus.uploading, 'Finalizing backup...');
      await _saveBackupInfo(backupId, driveFileId, processedData, backupData);

      // Update settings
      await _updateLastBackupTime();

      _updateProgress(100.0, BackupStatus.completed, 'Backup completed successfully!');
      return true;

    } catch (e) {
      _updateProgress(0.0, BackupStatus.failed, 'Backup failed',
          errorMessage: e.toString());
      return false;
    } finally {
      _isBackupInProgress = false;
    }
  }

  // Update progress
  void _updateProgress(double percentage, BackupStatus status, String action, {String? errorMessage}) {
    _currentProgress = BackupProgress(
      percentage: percentage,
      status: status,
      currentAction: action,
      errorMessage: errorMessage,
    );
    notifyListeners();
  }

  // Save backup info to Hive
  Future<void> _saveBackupInfo(String backupId, String driveFileId, Map<String, dynamic> processedData, Map<String, dynamic> originalData) async {
    final box = await Hive.openBox<BackupInfo>('backup_info');
    
    // Calculate actual file size
    final jsonString = json.encode(processedData);
    final size = utf8.encode(jsonString).length;
    
    final backupInfo = BackupInfo(
      id: backupId,
      createdAt: DateTime.now(),
      sizeBytes: size,
      deviceName: Platform.operatingSystem,
      driveFileId: driveFileId,
      status: BackupStatus.completed,
      incomeEntriesCount: (originalData['data']['income_entries'] as List).length,
      outcomeEntriesCount: (originalData['data']['outcome_entries'] as List).length,
      isEncrypted: processedData['encrypted'] ?? false,
      encryptionIv: processedData['iv'],
      encryptionTag: processedData['tag'],
      isCompressed: processedData['compressed'] ?? false,
      originalSize: processedData['original_size'],
      compressedSize: processedData['compressed_size'],
      compressionRatio: processedData['compression_ratio'],
    );

    await box.put(backupId, backupInfo);
    
    // Keep only the latest 10 backups
    if (box.length > 10) {
      final keys = box.keys.toList();
      keys.sort();
      for (int i = 0; i < keys.length - 10; i++) {
        await box.delete(keys[i]);
      }
    }
  }

  // Update last backup time in settings
  Future<void> _updateLastBackupTime() async {
    final box = await Hive.openBox<BackupSettings>('backup_settings');
    BackupSettings settings = box.get('settings', defaultValue: BackupSettings())!;
    
    settings.lastBackupTime = DateTime.now();
    await box.put('settings', settings);
  }

  // Get all backups
  Future<List<BackupInfo>> getAllBackups() async {
    final box = await Hive.openBox<BackupInfo>('backup_info');
    final backups = box.values.toList();
    backups.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return backups;
  }

  // Cancel ongoing backup
  Future<void> cancelBackup() async {
    if (_isBackupInProgress) {
      _updateProgress(_currentProgress.percentage, BackupStatus.cancelled, 'Backup cancelled');
      _isBackupInProgress = false;
    }
  }

  // Get backup settings
  Future<BackupSettings> getBackupSettings() async {
    final box = await Hive.openBox<BackupSettings>('backup_settings');
    return box.get('settings', defaultValue: BackupSettings())!;
  }

  // Save backup settings
  Future<void> saveBackupSettings(BackupSettings settings) async {
    final box = await Hive.openBox<BackupSettings>('backup_settings');
    await box.put('settings', settings);
  }

  // Delete backup from Drive and local storage
  Future<bool> deleteBackup(String backupId) async {
    try {
      final box = await Hive.openBox<BackupInfo>('backup_info');
      final backupInfo = box.get(backupId);
      
      if (backupInfo != null && _driveApi != null) {
        // Delete from Google Drive
        await _driveApi!.files.delete(backupInfo.driveFileId);
        
        // Delete from local storage
        await box.delete(backupId);
      }
      
      return true;
    } catch (e) {
      print('Failed to delete backup: $e');
      return false;
    }
  }
}