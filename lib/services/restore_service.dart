import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:archive/archive.dart';
import '../models/backup_models.dart';
import '../models/income_entry.dart';
import '../models/outcome_entry.dart';
import 'storage_service.dart';
import 'crypto_service.dart';

class RestoreService extends ChangeNotifier {
  static final RestoreService _instance = RestoreService._internal();
  factory RestoreService() => _instance;
  RestoreService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveFileScope],
  );

  drive.DriveApi? _driveApi;
  RestoreProgress _currentProgress = RestoreProgress();
  bool _isRestoreInProgress = false;
  
  final CryptoService _cryptoService = CryptoService();

  RestoreProgress get currentProgress => _currentProgress;
  bool get isRestoreInProgress => _isRestoreInProgress;

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

  // Download backup from Google Drive
  Future<Uint8List?> _downloadFromDrive(String fileId) async {
    if (_driveApi == null) return null;

    try {
      final media = await _driveApi!.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final List<int> dataBytes = [];
      await for (var chunk in media.stream) {
        dataBytes.addAll(chunk);
      }

      return Uint8List.fromList(dataBytes);
    } catch (e) {
      print('Download from Drive failed: $e');
      return null;
    }
  }

  // Parse, decrypt, and decompress backup data
  Future<Map<String, dynamic>?> _parseBackupData(Uint8List data, String backupId) async {
    try {
      final jsonString = utf8.decode(data);
      final processedData = json.decode(jsonString) as Map<String, dynamic>;
      
      Uint8List finalBytes;
      
      // Check if data is encrypted
      if (processedData['encrypted'] == true) {
        // Data is encrypted, decrypt it first
        final encryptedDataMap = {
          'iv': processedData['iv'] as String,
          'tag': processedData['tag'] as String,
          'data': processedData['data'] as String,
        };
        
        finalBytes = await _cryptoService.decryptData(
          encryptedDataMap,
          backupId,
          'backup_data',
        );
      } else {
        // Data is not encrypted, decode directly
        finalBytes = base64.decode(processedData['data'] as String);
      }
      
      // Check if data is compressed
      if (processedData['compressed'] == true) {
        // Decompress the data
        finalBytes = _decompressData(finalBytes);
        
        // Log decompression info
        final compressedSize = processedData['compressed_size'] ?? 0;
        final compressionRatio = processedData['compression_ratio'] ?? 0.0;
        print('Data decompressed: $compressedSize bytes -> ${finalBytes.length} bytes (${compressionRatio.toStringAsFixed(1)}% was saved)');
      }
      
      final finalJson = utf8.decode(finalBytes);
      return json.decode(finalJson) as Map<String, dynamic>;
    } catch (e) {
      print('Failed to parse backup data: $e');
      return null;
    }
  }

  // Decompress data using GZip
  Uint8List _decompressData(Uint8List compressedData) {
    final gzipDecoder = GZipDecoder();
    final decompressed = gzipDecoder.decodeBytes(compressedData);
    return Uint8List.fromList(decompressed);
  }

  // Validate backup data integrity
  bool _validateBackupData(Map<String, dynamic> data) {
    try {
      // Check required fields
      if (!data.containsKey('version') || 
          !data.containsKey('timestamp') || 
          !data.containsKey('data')) {
        return false;
      }

      final backupData = data['data'] as Map<String, dynamic>;
      if (!backupData.containsKey('income_entries') || 
          !backupData.containsKey('outcome_entries')) {
        return false;
      }

      // Validate data structure
      final incomeEntries = backupData['income_entries'] as List;
      final outcomeEntries = backupData['outcome_entries'] as List;

      for (var entry in incomeEntries) {
        if (!entry.containsKey('amount') || 
            !entry.containsKey('name') || 
            !entry.containsKey('id') || 
            !entry.containsKey('date')) {
          return false;
        }
      }

      for (var entry in outcomeEntries) {
        if (!entry.containsKey('name') || 
            !entry.containsKey('amount') || 
            !entry.containsKey('date') || 
            !entry.containsKey('id')) {
          return false;
        }
      }

      return true;
    } catch (e) {
      print('Backup validation failed: $e');
      return false;
    }
  }

  // Apply restored data to local storage
  Future<bool> _applyRestoredData(Map<String, dynamic> data) async {
    try {
      final storageService = StorageService();
      final backupData = data['data'] as Map<String, dynamic>;

      // Only clear existing data if user wants to replace
      // For now, default to merge (don't clear) to preserve existing data
      // await storageService.clearAllData();

      // Restore income entries
      final incomeEntries = (backupData['income_entries'] as List)
          .map((entry) => IncomeEntry(
                id: entry['id'],
                name: entry['name'],
                amount: entry['amount'].toDouble(),
                date: DateTime.parse(entry['date']),
              ))
          .toList();

      // Restore outcome entries
      final outcomeEntries = (backupData['outcome_entries'] as List)
          .map((entry) => OutcomeEntry(
                id: entry['id'],
                name: entry['name'],
                amount: entry['amount'].toDouble(),
                date: DateTime.parse(entry['date']),
              ))
          .toList();

      // Group entries by month/year from their dates and save
      Map<String, List<IncomeEntry>> incomeByMonth = {};
      Map<String, List<OutcomeEntry>> outcomeByMonth = {};

      for (var entry in incomeEntries) {
        final monthNames = [
          'January', 'February', 'March', 'April', 'May', 'June',
          'July', 'August', 'September', 'October', 'November', 'December'
        ];
        final monthName = monthNames[entry.date.month - 1];
        final key = '${monthName}_${entry.date.year}';
        incomeByMonth.putIfAbsent(key, () => []).add(entry);
      }

      for (var entry in outcomeEntries) {
        final monthNames = [
          'January', 'February', 'March', 'April', 'May', 'June',
          'July', 'August', 'September', 'October', 'November', 'December'
        ];
        final monthName = monthNames[entry.date.month - 1];
        final key = '${monthName}_${entry.date.year}';
        outcomeByMonth.putIfAbsent(key, () => []).add(entry);
      }

      // Save grouped entries with merge (add to existing data)
      for (var entry in incomeByMonth.entries) {
        final parts = entry.key.split('_');
        final month = parts[0];
        final year = int.parse(parts[1]);
        
        // Get existing entries and merge with new ones
        final existingEntries = await storageService.getIncomeEntries(month, year);
        final mergedEntries = [...existingEntries, ...entry.value];
        await storageService.saveIncomeEntries(month, year, mergedEntries);
      }

      for (var entry in outcomeByMonth.entries) {
        final parts = entry.key.split('_');
        final month = parts[0];
        final year = int.parse(parts[1]);
        
        // Get existing entries and merge with new ones
        final existingEntries = await storageService.getOutcomeEntries(month, year);
        final mergedEntries = [...existingEntries, ...entry.value];
        await storageService.saveOutcomeEntries(month, year, mergedEntries);
      }

      return true;
    } catch (e) {
      print('Failed to apply restored data: $e');
      return false;
    }
  }

  // Start restore process
  Future<bool> startRestore(String backupId) async {
    if (_isRestoreInProgress) return false;

    _isRestoreInProgress = true;
    _updateProgress(0.0, RestoreStatus.downloading, 'Checking connectivity...', backupId);

    try {
      // Check connectivity
      final isConnected = await _checkConnectivity();
      if (!isConnected) {
        _updateProgress(0.0, RestoreStatus.failed, 'No internet connection',
            backupId, errorMessage: 'Please check your internet connection and try again.');
        return false;
      }

      // Get backup info
      final box = await Hive.openBox<BackupInfo>('backup_info');
      final backupInfo = box.get(backupId);
      if (backupInfo == null) {
        _updateProgress(0.0, RestoreStatus.failed, 'Backup not found',
            backupId, errorMessage: 'The selected backup could not be found.');
        return false;
      }

      // Initialize Google Drive
      _updateProgress(10.0, RestoreStatus.downloading, 'Connecting to Google Drive...', backupId);
      final initialized = await initialize();
      if (!initialized) {
        _updateProgress(0.0, RestoreStatus.failed, 'Failed to connect to Google Drive',
            backupId, errorMessage: 'Could not authenticate with Google Drive.');
        return false;
      }

      // Download backup data
      _updateProgress(30.0, RestoreStatus.downloading, 'Downloading backup data...', backupId);
      final backupData = await _downloadFromDrive(backupInfo.driveFileId);
      if (backupData == null) {
        _updateProgress(0.0, RestoreStatus.failed, 'Download failed',
            backupId, errorMessage: 'Failed to download backup from Google Drive.');
        return false;
      }

      // Parse backup data
      _updateProgress(60.0, RestoreStatus.decrypting, 'Processing backup data...', backupId);
      final parsedData = await _parseBackupData(backupData, backupId);
      if (parsedData == null) {
        _updateProgress(0.0, RestoreStatus.failed, 'Invalid backup data',
            backupId, errorMessage: 'The backup file appears to be corrupted or could not be decrypted.');
        return false;
      }

      // Validate data integrity
      _updateProgress(70.0, RestoreStatus.decrypting, 'Validating backup integrity...', backupId);
      final isValid = _validateBackupData(parsedData);
      if (!isValid) {
        _updateProgress(0.0, RestoreStatus.failed, 'Backup validation failed',
            backupId, errorMessage: 'The backup data failed integrity checks.');
        return false;
      }

      // Apply restored data
      _updateProgress(85.0, RestoreStatus.applying, 'Restoring your data...', backupId);
      final applied = await _applyRestoredData(parsedData);
      if (!applied) {
        _updateProgress(0.0, RestoreStatus.failed, 'Failed to apply data',
            backupId, errorMessage: 'Could not restore the data to your device.');
        return false;
      }

      _updateProgress(100.0, RestoreStatus.completed, 'Restoration completed successfully!', backupId);
      return true;

    } catch (e) {
      _updateProgress(0.0, RestoreStatus.failed, 'Restoration failed',
          backupId, errorMessage: e.toString());
      return false;
    } finally {
      _isRestoreInProgress = false;
    }
  }

  // Update progress
  void _updateProgress(double percentage, RestoreStatus status, String action, String? backupId, {String? errorMessage}) {
    _currentProgress = RestoreProgress(
      percentage: percentage,
      status: status,
      currentAction: action,
      errorMessage: errorMessage,
      backupId: backupId,
    );
    notifyListeners();
  }

  // Cancel ongoing restore
  Future<void> cancelRestore() async {
    if (_isRestoreInProgress) {
      _updateProgress(_currentProgress.percentage, RestoreStatus.cancelled, 
          'Restoration cancelled', _currentProgress.backupId);
      _isRestoreInProgress = false;
    }
  }

  // Get restore preview (what data will be restored)
  Future<Map<String, dynamic>?> getRestorePreview(String backupId) async {
    try {
      final box = await Hive.openBox<BackupInfo>('backup_info');
      final backupInfo = box.get(backupId);
      if (backupInfo == null) return null;

      // Initialize if needed
      if (_driveApi == null) {
        final initialized = await initialize();
        if (!initialized) return null;
      }

      // Download and parse just for preview
      final backupData = await _downloadFromDrive(backupInfo.driveFileId);
      if (backupData == null) return null;

      final parsedData = await _parseBackupData(backupData, backupId);
      if (parsedData == null) return null;

      final data = parsedData['data'] as Map<String, dynamic>;
      return {
        'income_entries_count': (data['income_entries'] as List).length,
        'outcome_entries_count': (data['outcome_entries'] as List).length,
        'backup_version': parsedData['version'],
        'backup_timestamp': parsedData['timestamp'],
        'device_info': parsedData['device_info'],
      };
    } catch (e) {
      print('Failed to get restore preview: $e');
      return null;
    }
  }
}