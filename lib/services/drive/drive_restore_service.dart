import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:archive/archive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import '../../models/backup_models.dart';
import '../../models/drive_manifest_model.dart';
import '../../models/income_entry.dart';
import '../../models/outcome_entry.dart';
import '../crypto_service.dart';
import '../storage_service.dart';
import 'drive_provider_resumable.dart';

/// Drive-based restore service implementing blueprint section 9
/// Handles chunked downloads, decryption, and decompression
class DriveRestoreService extends ChangeNotifier {
  static final DriveRestoreService _instance = DriveRestoreService._internal();
  factory DriveRestoreService() => _instance;
  DriveRestoreService._internal();

  final DriveProviderResumable _driveProvider = DriveProviderResumable();
  final CryptoService _cryptoService = CryptoService();
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  RestoreProgress _currentProgress = RestoreProgress();
  bool _isRestoreInProgress = false;
  final Map<String, Uint8List> _downloadedChunks = {};
  String? _currentManifestFileId;

  // Blueprint constants
  static const int maxConcurrentDownloads = 3;
  static const int downloadRetryCount = 3;

  RestoreProgress get currentProgress => _currentProgress;
  bool get isRestoreInProgress => _isRestoreInProgress;

  /// Start restore process following blueprint section 9
  Future<bool> startDriveRestore(String manifestFileId, {bool replaceExisting = true}) async {
    if (_isRestoreInProgress) return false;

    _isRestoreInProgress = true;
    _currentManifestFileId = manifestFileId;
    _updateProgress(0.0, RestoreStatus.downloading, 'Starting restore...');

    try {
      // Step 1: Preflight checks
      if (!await _preflightChecks()) {
        return false;
      }

      // Step 2: Ensure authentication
      _updateProgress(5.0, RestoreStatus.downloading, 'Authenticating with Google Drive...');
      if (!await _ensureAuthenticated()) {
        _updateProgress(0.0, RestoreStatus.failed, 'Authentication failed');
        return false;
      }

      // Step 3: Download and parse manifest
      _updateProgress(10.0, RestoreStatus.downloading, 'Downloading backup manifest...');
      final manifest = await _downloadManifest(manifestFileId);
      if (manifest == null) {
        _updateProgress(0.0, RestoreStatus.failed, 'Failed to download manifest');
        return false;
      }

      // Step 4: Validate manifest
      _updateProgress(15.0, RestoreStatus.downloading, 'Validating backup manifest...');
      if (!_validateManifest(manifest)) {
        _updateProgress(0.0, RestoreStatus.failed, 'Invalid backup manifest');
        return false;
      }

      // Step 5: Ensure master key availability
      _updateProgress(20.0, RestoreStatus.decrypting, 'Preparing decryption keys...');
      final masterKey = await _getMasterKey(manifest);
      if (masterKey == null) {
        _updateProgress(0.0, RestoreStatus.failed, 'Cannot access encryption keys');
        return false;
      }

      // Step 6: Download and decrypt files
      _updateProgress(25.0, RestoreStatus.downloading, 'Processing backup files...');
      final restoredFiles = await _downloadAndDecryptFiles(manifest, masterKey);
      if (restoredFiles.isEmpty) {
        String errorMsg = 'No files were restored';
        
        // Try to provide more specific error information
        if (_downloadedChunks.isNotEmpty) {
          errorMsg = 'Downloaded ${_downloadedChunks.length} chunks but decryption failed. Please check your master key.';
        }
        
        _updateProgress(0.0, RestoreStatus.failed, errorMsg);
        return false;
      }

      // Step 7: Validate restored data
      _updateProgress(85.0, RestoreStatus.applying, 'Validating restored data...');
      final isValid = _validateRestoredData(restoredFiles);
      if (!isValid) {
        _updateProgress(0.0, RestoreStatus.failed, 'Restored data failed validation');
        return false;
      }

      // Step 8: Apply restored data atomically
      _updateProgress(90.0, RestoreStatus.applying, 'Applying restored data...');
      final applied = await _applyRestoredData(restoredFiles, replaceExisting: replaceExisting);
      if (!applied) {
        _updateProgress(0.0, RestoreStatus.failed, 'Failed to apply restored data');
        return false;
      }

      _updateProgress(100.0, RestoreStatus.completed, 'Restore completed successfully!');
      return true;

    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Drive restore failed: $e');
        print('Stack trace: $stackTrace');
      }
      _updateProgress(0.0, RestoreStatus.failed, 'Restore failed: ${e.toString()}');
      return false;
    } finally {
      _isRestoreInProgress = false;
    }
  }

  /// Start restore process using session ID (for compatibility with old screens)
  Future<bool> startRestore(String sessionId, {bool replaceExisting = true}) async {
    // For the new chunked backup system, sessionId is actually the manifestFileId
    return await startDriveRestore(sessionId, replaceExisting: replaceExisting);
  }


  /// Preflight checks from blueprint
  Future<bool> _preflightChecks() async {
    // Check connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      _updateProgress(0.0, RestoreStatus.failed, 'No internet connection');
      return false;
    }

    // TODO: Add battery and storage checks
    // - battery >= 20% or charging
    // - local free space >= restore size estimate

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

  /// Download and parse manifest from Drive
  Future<DriveManifest?> _downloadManifest(String manifestFileId) async {
    try {
      final manifestBytes = await _driveProvider.downloadFileBytes(manifestFileId);
      final jsonString = utf8.decode(manifestBytes);
      return DriveManifest.fromJsonString(jsonString);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to download manifest: $e');
      }
      return null;
    }
  }

  /// Validate manifest integrity
  bool _validateManifest(DriveManifest manifest) {
    // Use existing validation from ManifestUtils
    return ManifestUtils.validateManifest(manifest);
  }

  /// Get master key for decryption
  Future<Uint8List?> _getMasterKey(DriveManifest manifest) async {
    try {
      // Check if wrapped master key is available for recovery
      if (manifest.wmk != null) {
        // TODO: Implement recovery key workflow
        // This would require user to enter recovery passphrase
        if (kDebugMode) {
          print('Recovery key available but not implemented yet');
        }
      }

      // Use device-bound master key
      return await _cryptoService.getMasterKey();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to get master key: $e');
      }
      return null;
    }
  }

  /// Reset master key and try again (last resort)
  Future<void> resetMasterKeyAndRetry() async {
    if (kDebugMode) {
      print('🔄 Attempting to reset master key as last resort...');
    }
    
    await _cryptoService.resetEncryption();
    clearChunkCache();
    
    if (kDebugMode) {
      print('✅ Master key reset completed. Cache cleared.');
    }
  }

  /// Download and decrypt all files with chunking
  Future<Map<String, Uint8List>> _downloadAndDecryptFiles(
    DriveManifest manifest,
    Uint8List masterKey,
  ) async {
    final restoredFiles = <String, Uint8List>{};

    for (int fileIndex = 0; fileIndex < manifest.files.length; fileIndex++) {
      final manifestFile = manifest.files[fileIndex];
      
      _updateProgress(
        25.0 + (fileIndex / manifest.files.length) * 55.0,
        RestoreStatus.downloading,
        'Restoring ${manifestFile.id}...'
      );

      final fileData = await _downloadAndDecryptFile(
        manifestFile, manifest.sessionId, masterKey);
      
      if (fileData != null) {
        restoredFiles[manifestFile.id] = fileData;
      } else {
        if (kDebugMode) {
          print('Failed to restore file: ${manifestFile.id}');
        }
        return {};
      }
    }

    return restoredFiles;
  }

  /// Download and decrypt individual file
  Future<Uint8List?> _downloadAndDecryptFile(
    ManifestFile manifestFile,
    String sessionId,
    Uint8List masterKey,
  ) async {
    try {
      final chunks = <int, Uint8List>{};
      
      // Download chunks concurrently with limit
      final futures = <Future>[];
      final semaphore = _Semaphore(maxConcurrentDownloads);
      
      for (final chunk in manifestFile.chunks) {
        futures.add(
          semaphore.acquire().then((_) async {
            try {
              final chunkData = await _downloadAndDecryptChunk(
                chunk, sessionId, manifestFile.id, masterKey);
              if (chunkData != null) {
                chunks[chunk.seq] = chunkData;
              }
            } finally {
              semaphore.release();
            }
          })
        );
      }
      
      await Future.wait(futures);
      
      // Verify all chunks downloaded
      if (chunks.length != manifestFile.chunks.length) {
        if (kDebugMode) {
          print('Missing chunks for file ${manifestFile.id}: ${chunks.length}/${manifestFile.chunks.length}');
        }
        return null;
      }
      
      // Reassemble chunks in order
      final assembledBytes = <int>[];
      for (int seq = 0; seq < manifestFile.chunks.length; seq++) {
        final chunkData = chunks[seq];
        if (chunkData == null) {
          if (kDebugMode) {
            print('Missing chunk $seq for file ${manifestFile.id}');
          }
          return null;
        }
        assembledBytes.addAll(chunkData);
      }
      
      // Decompress assembled data
      final decompressedData = _decompressData(Uint8List.fromList(assembledBytes));
      
      // Verify file size matches original
      if (decompressedData.length != manifestFile.originalSize) {
        if (kDebugMode) {
          print('File size mismatch for ${manifestFile.id}: ${decompressedData.length} != ${manifestFile.originalSize}');
        }
        return null;
      }
      
      return decompressedData;
      
    } catch (e) {
      if (kDebugMode) {
        print('Failed to download/decrypt file ${manifestFile.id}: $e');
      }
      return null;
    }
  }

  /// Download and decrypt individual chunk with resume support
  Future<Uint8List?> _downloadAndDecryptChunk(
    ManifestChunk chunk,
    String sessionId,
    String fileId,
    Uint8List masterKey,
  ) async {
    // Check if chunk already downloaded
    final chunkKey = '${fileId}_${chunk.seq}';
    if (_downloadedChunks.containsKey(chunkKey)) {
      if (kDebugMode) {
        print('Using cached chunk $chunkKey');
      }
      return _downloadedChunks[chunkKey];
    }

    int attempt = 0;
    
    while (attempt < downloadRetryCount) {
      try {
        // Download encrypted chunk from Drive
        final encryptedData = await _driveProvider.downloadFileBytes(chunk.driveFileId);
        
        // Verify SHA-256 hash
        final computedHash = await _cryptoService.sha256Hash(encryptedData);
        if (computedHash != chunk.sha256) {
          throw Exception('Chunk hash verification failed');
        }
        
        // Decrypt chunk
        final encryptedDataMap = {
          'data': base64.encode(encryptedData),
          'iv': chunk.iv,
          'tag': chunk.tag,
        };
        
        if (kDebugMode) {
          print('🔓 Attempting to decrypt chunk ${chunk.seq} for file $fileId');
          print('   SessionId: $sessionId');
          print('   FileId for AAD: ${fileId}_${chunk.seq}');
          print('   IV: ${chunk.iv}');
          print('   Tag: ${chunk.tag}');
          print('   Data length: ${encryptedData.length}');
        }
        
        final decryptedData = await _cryptoService.decryptData(
          encryptedDataMap,
          sessionId,
          '${fileId}_${chunk.seq}',
        );
        
        // Cache the decrypted chunk
        _downloadedChunks[chunkKey] = decryptedData;
        
        return decryptedData;
        
      } catch (e) {
        attempt++;
        if (kDebugMode) {
          print('❌ Attempt $attempt failed for chunk ${chunk.seq}: $e');
          if (e.toString().contains('SecretBox')) {
            print('   This is a decryption error - the chunk data or keys may be corrupted');
            print('   Trying to recover by clearing chunk cache and re-downloading...');
            
            // Remove this chunk from cache if it exists
            final chunkKey = '${fileId}_${chunk.seq}';
            _downloadedChunks.remove(chunkKey);
          }
        }
        
        if (attempt >= downloadRetryCount) {
          if (kDebugMode) {
            print('💥 Failed to download chunk ${chunk.seq} after $downloadRetryCount attempts: $e');
          }
          return null;
        }
        
        // Wait before retry with exponential backoff
        final delay = 1000 * pow(2, attempt - 1).round();
        if (kDebugMode) {
          print('⏳ Waiting ${delay}ms before retry attempt ${attempt + 1}');
        }
        await Future.delayed(Duration(milliseconds: delay));
      }
    }
    
    return null;
  }

  /// Decompress data using GZip
  Uint8List _decompressData(Uint8List compressedData) {
    final gzipDecoder = GZipDecoder();
    final decompressed = gzipDecoder.decodeBytes(compressedData);
    return Uint8List.fromList(decompressed);
  }

  /// Validate restored data integrity
  bool _validateRestoredData(Map<String, Uint8List> restoredFiles) {
    try {
      // Validate main database file
      if (!restoredFiles.containsKey('db')) {
        return false;
      }
      
      final dbData = restoredFiles['db']!;
      final jsonString = utf8.decode(dbData);
      final data = json.decode(jsonString) as Map<String, dynamic>;
      
      // Validate structure
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
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Data validation failed: $e');
      }
      return false;
    }
  }

  /// Apply restored data with merge option
  Future<bool> _applyRestoredData(Map<String, Uint8List> restoredFiles, {bool replaceExisting = false}) async {
    try {
      final storageService = StorageService();
      
      // Parse main database file
      final dbData = restoredFiles['db']!;
      final jsonString = utf8.decode(dbData);
      final data = json.decode(jsonString) as Map<String, dynamic>;
      final backupData = data['data'] as Map<String, dynamic>;
      
      // Only clear existing data if user chose to replace
      if (replaceExisting) {
        await storageService.clearAllData();
      }
      
      // Restore income entries
      final incomeEntries = (backupData['income_entries'] as List)
          .map((entry) {
                if (kDebugMode) {
                  print('DriveRestore - Parsing income entry: ${entry['name']} with date string: ${entry['date']}');
                }
                final parsedDate = DateTime.parse(entry['date']);
                if (kDebugMode) {
                  print('DriveRestore - Parsed date: $parsedDate (month: ${parsedDate.month})');
                }
                return IncomeEntry(
                  id: entry['id'],
                  name: entry['name'],
                  amount: entry['amount'].toDouble(),
                  date: parsedDate,
                );
              })
          .toList();

      // Restore outcome entries
      final outcomeEntries = (backupData['outcome_entries'] as List)
          .map((entry) {
                if (kDebugMode) {
                  print('DriveRestore - Parsing outcome entry: ${entry['name']} with date string: ${entry['date']}');
                }
                final parsedDate = DateTime.parse(entry['date']);
                if (kDebugMode) {
                  print('DriveRestore - Parsed date: $parsedDate (month: ${parsedDate.month})');
                }
                return OutcomeEntry(
                  id: entry['id'],
                  name: entry['name'],
                  amount: entry['amount'].toDouble(),
                  date: parsedDate,
                );
              })
          .toList();

      // Group and save by month/year (this will merge with existing data if replaceExisting is false)
      await _saveEntriesByMonth(storageService, incomeEntries, outcomeEntries, replaceExisting: replaceExisting);
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to apply restored data: $e');
      }
      return false;
    }
  }

  /// Save entries grouped by month/year with merge option
  Future<void> _saveEntriesByMonth(
    StorageService storageService,
    List<IncomeEntry> incomeEntries,
    List<OutcomeEntry> outcomeEntries,
    {bool replaceExisting = false}
  ) async {
    // Use full month names to match what the UI expects
    const monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    // Group income entries using direct date information (no re-parsing needed)
    final incomeByMonth = <String, List<IncomeEntry>>{};
    for (final entry in incomeEntries) {
      // Use the already correctly parsed date directly
      final entryDate = entry.date;
      final monthName = monthNames[entryDate.month - 1];
      final monthKey = '${monthName}_${entryDate.year}';
      incomeByMonth.putIfAbsent(monthKey, () => []).add(entry);
      
      if (kDebugMode) {
        print('✅ DriveRestore - Income entry: ${entry.name}');
        print('   Entry date: $entryDate');
        print('   Month: ${entryDate.month} -> $monthName');
        print('   Year: ${entryDate.year}');
        print('   Storage key: $monthKey');
      }
    }

    // Group outcome entries using direct date information (no re-parsing needed)
    final outcomeByMonth = <String, List<OutcomeEntry>>{};
    for (final entry in outcomeEntries) {
      // Use the already correctly parsed date directly
      final entryDate = entry.date;
      final monthName = monthNames[entryDate.month - 1];
      final monthKey = '${monthName}_${entryDate.year}';
      outcomeByMonth.putIfAbsent(monthKey, () => []).add(entry);
      
      if (kDebugMode) {
        print('✅ DriveRestore - Outcome entry: ${entry.name}');
        print('   Entry date: $entryDate');
        print('   Month: ${entryDate.month} -> $monthName');
        print('   Year: ${entryDate.year}');
        print('   Storage key: $monthKey');
      }
    }

    // Save grouped entries using full month names
    for (final entry in incomeByMonth.entries) {
      final parts = entry.key.split('_');
      final month = parts[0];
      final year = int.parse(parts[1]);
      
      if (replaceExisting) {
        // Replace existing entries for this month
        await storageService.saveIncomeEntries(month, year, entry.value);
      } else {
        // Merge with existing entries for this month, preserving original order
        final existingEntries = await storageService.getIncomeEntries(month, year);
        final mergedEntries = _mergeEntriesPreservingOrder(existingEntries, entry.value);
        await storageService.saveIncomeEntries(month, year, mergedEntries);
      }
    }

    for (final entry in outcomeByMonth.entries) {
      final parts = entry.key.split('_');
      final month = parts[0];
      final year = int.parse(parts[1]);
      
      if (replaceExisting) {
        // Replace existing entries for this month
        await storageService.saveOutcomeEntries(month, year, entry.value);
      } else {
        // Merge with existing entries for this month, preserving original order
        final existingEntries = await storageService.getOutcomeEntries(month, year);
        final mergedEntries = _mergeOutcomeEntriesPreservingOrder(existingEntries, entry.value);
        await storageService.saveOutcomeEntries(month, year, mergedEntries);
      }
    }
  }

  /// Merge income entries while preserving original order
  List<IncomeEntry> _mergeEntriesPreservingOrder(
    List<IncomeEntry> existing, 
    List<IncomeEntry> backup
  ) {
    // Create a map of existing entries by ID for quick lookup
    final existingMap = <String, IncomeEntry>{};
    for (final entry in existing) {
      existingMap[entry.id] = entry;
    }

    // Create the merged list, preserving backup order and adding new entries
    final mergedList = <IncomeEntry>[];
    final processedIds = <String>{};

    // First, add all backup entries (this preserves the original backup order)
    for (final backupEntry in backup) {
      mergedList.add(backupEntry);
      processedIds.add(backupEntry.id);
      
      // Remove from existing map since we're using the backup version
      existingMap.remove(backupEntry.id);
    }

    // Then add any existing entries that weren't in the backup
    // These will be added at the end
    for (final remainingEntry in existingMap.values) {
      mergedList.add(remainingEntry);
    }

    return mergedList;
  }

  /// Merge outcome entries while preserving original order
  List<OutcomeEntry> _mergeOutcomeEntriesPreservingOrder(
    List<OutcomeEntry> existing, 
    List<OutcomeEntry> backup
  ) {
    // Create a map of existing entries by ID for quick lookup
    final existingMap = <String, OutcomeEntry>{};
    for (final entry in existing) {
      existingMap[entry.id] = entry;
    }

    // Create the merged list, preserving backup order and adding new entries
    final mergedList = <OutcomeEntry>[];
    final processedIds = <String>{};

    // First, add all backup entries (this preserves the original backup order)
    for (final backupEntry in backup) {
      mergedList.add(backupEntry);
      processedIds.add(backupEntry.id);
      
      // Remove from existing map since we're using the backup version
      existingMap.remove(backupEntry.id);
    }

    // Then add any existing entries that weren't in the backup
    // These will be added at the end
    for (final remainingEntry in existingMap.values) {
      mergedList.add(remainingEntry);
    }

    return mergedList;
  }

  /// Update progress and notify listeners
  void _updateProgress(double percentage, RestoreStatus status, String action, {String? errorMessage}) {
    _currentProgress = RestoreProgress(
      percentage: percentage,
      status: status,
      currentAction: action,
      errorMessage: errorMessage,
    );
    notifyListeners();
  }

  /// Cancel ongoing restore
  Future<void> cancelRestore() async {
    if (_isRestoreInProgress) {
      _updateProgress(_currentProgress.percentage, RestoreStatus.cancelled, 'Restore cancelled');
      _isRestoreInProgress = false;
      
      // Keep downloaded chunks cache for potential resume
      if (kDebugMode) {
        print('Restore cancelled, ${_downloadedChunks.length} chunks cached for resume');
      }
    }
  }

  /// Clear downloaded chunks cache
  void clearChunkCache() {
    _downloadedChunks.clear();
    if (kDebugMode) {
      print('Chunk cache cleared');
    }
  }

  /// Resume restore with cached chunks
  Future<bool> resumeRestore() async {
    if (_currentManifestFileId == null) {
      return false; // No restore session to resume
    }

    if (kDebugMode) {
      print('Resuming restore with ${_downloadedChunks.length} cached chunks');
    }

    return await startDriveRestore(_currentManifestFileId!);
  }

  /// Get download progress info
  Map<String, int> getDownloadProgress() {
    return {
      'cached_chunks': _downloadedChunks.length,
      'cache_size_bytes': _downloadedChunks.values.fold(0, (sum, chunk) => sum + chunk.length),
    };
  }

  /// Get restore preview without actually restoring
  Future<Map<String, dynamic>?> getRestorePreview(String manifestFileId) async {
    try {
      // Download and parse manifest
      final manifest = await _downloadManifest(manifestFileId);
      if (manifest == null) return null;

      // Calculate preview info
      final totalSize = ManifestUtils.calculateTotalSize(manifest);
      final totalChunks = ManifestUtils.calculateTotalChunks(manifest);

      return {
        'session_id': manifest.sessionId,
        'created_at': manifest.createdAt.toIso8601String(),
        'app_version': manifest.appVersion,
        'platform': manifest.platform,
        'file_count': manifest.files.length,
        'total_size': totalSize,
        'total_chunks': totalChunks,
        'compression': manifest.compression,
        'chunk_size': manifest.chunkSize,
        'has_recovery_key': manifest.wmk != null,
        'owner_email': manifest.owner.email,
        'status': manifest.status,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Failed to get restore preview: $e');
      }
      return null;
    }
  }

  /// List available backups for current user
  Future<List<DriveManifest>> listAvailableBackups() async {
    try {
      if (!await _ensureAuthenticated()) {
        return [];
      }

      final account = _googleSignIn.currentUser;

      // Query for manifest files - simplified approach
      // First find all manifest.json files, then filter by structure later
      final query = "name='manifest.json'";
      final allManifestFiles = await _driveProvider.queryFiles(query);

      final manifests = <DriveManifest>[];
      for (final file in allManifestFiles) {
        try {
          final manifest = await _downloadManifest(file['id']);
          if (manifest != null) {
            manifests.add(manifest);
          }
        } catch (e) {
          if (kDebugMode) {
            print('Failed to parse manifest ${file['id']}: $e');
          }
        }
      }

      // Sort by creation date (newest first)
      manifests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return manifests;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to list available backups: $e');
      }
      return [];
    }
  }

  /// List available backups with manifest file IDs for restore operations
  Future<List<Map<String, dynamic>>> listAvailableBackupsWithIds() async {
    try {
      if (!await _ensureAuthenticated()) {
        return [];
      }

      final account = _googleSignIn.currentUser;

      // Query for manifest files - simplified approach
      final query = "name='manifest.json'";
      final allManifestFiles = await _driveProvider.queryFiles(query);

      final backupsWithIds = <Map<String, dynamic>>[];
      for (final file in allManifestFiles) {
        try {
          final manifest = await _downloadManifest(file['id']);
          if (manifest != null) {
            backupsWithIds.add({
              'id': manifest.sessionId,
              'manifestFileId': file['id'], // Actual Drive file ID
              'date': manifest.createdAt,
              'size': manifest.files.fold(0, (sum, manifestFile) => sum + manifestFile.originalSize),
              'platform': manifest.platform,
              'appVersion': manifest.appVersion,
              'owner': manifest.owner.email,
              'status': manifest.status,
              'manifest': manifest, // Include full manifest if needed
            });
          }
        } catch (e) {
          if (kDebugMode) {
            print('Failed to parse manifest ${file['id']}: $e');
          }
        }
      }

      // Sort by creation date (newest first)
      backupsWithIds.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
      
      return backupsWithIds;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to list available backups with IDs: $e');
      }
      return [];
    }
  }

  /// Delete a backup by manifest file ID
  Future<void> deleteBackup(String manifestFileId) async {
    try {
      if (!await _ensureAuthenticated()) {
        throw Exception('Authentication required');
      }

      // First download the manifest to get all chunk file IDs
      final manifest = await _downloadManifest(manifestFileId);
      if (manifest == null) {
        throw Exception('Manifest not found or corrupted');
      }

      if (kDebugMode) {
        print('Deleting backup session: ${manifest.sessionId}');
      }

      // Collect all chunk file IDs
      final chunkFileIds = <String>[];
      for (final file in manifest.files) {
        for (final chunk in file.chunks) {
          chunkFileIds.add(chunk.driveFileId);
        }
      }

      if (kDebugMode) {
        print('Found ${chunkFileIds.length} chunk files to delete');
      }

      // Delete all chunk files
      int deletedCount = 0;
      for (final chunkFileId in chunkFileIds) {
        try {
          await _driveProvider.deleteFile(chunkFileId);
          deletedCount++;
          
          if (kDebugMode && deletedCount % 10 == 0) {
            print('Deleted $deletedCount/${chunkFileIds.length} chunk files');
          }
        } catch (e) {
          if (kDebugMode) {
            print('Warning: Failed to delete chunk file $chunkFileId: $e');
          }
          // Continue deleting other files even if one fails
        }
      }

      // Finally delete the manifest file itself
      await _driveProvider.deleteFile(manifestFileId);
      
      if (kDebugMode) {
        print('Backup deletion complete. Deleted $deletedCount chunk files + manifest');
      }

    } catch (e) {
      if (kDebugMode) {
        print('Failed to delete backup: $e');
      }
      throw Exception('Failed to delete backup: $e');
    }
  }
}

/// Semaphore for limiting concurrent operations
class _Semaphore {
  final int maxCount;
  int _currentCount = 0;
  final List<Function> _waitQueue = [];

  _Semaphore(this.maxCount) : _currentCount = maxCount;

  Future<void> acquire() async {
    if (_currentCount > 0) {
      _currentCount--;
      return;
    }

    final completer = Completer<void>();
    _waitQueue.add(() => completer.complete());
    return completer.future;
  }

  void release() {
    if (_waitQueue.isNotEmpty) {
      final next = _waitQueue.removeAt(0);
      next();
    } else {
      _currentCount++;
    }
  }
}