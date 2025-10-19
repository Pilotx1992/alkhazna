import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:hive/hive.dart';
import 'package:logger/logger.dart';
import '../../models/income_entry.dart';
import '../../models/outcome_entry.dart';
import '../../utils/app_logger.dart';

/// Service for creating safety backups before critical operations
/// Provides rollback capability in case of failures
/// 
/// Usage:
/// ```dart
/// final safetyService = SafetyBackupService();
/// final backupId = await safetyService.createPreRestoreBackup();
/// // ... perform restore operation ...
/// // If restore fails:
/// await safetyService.restoreFromSafetyBackup(backupId);
/// ```
class SafetyBackupService {
  static final SafetyBackupService _instance = SafetyBackupService._internal();
  factory SafetyBackupService() => _instance;
  SafetyBackupService._internal();

  final Logger _logger = AppLogger.instance;

  /// Create a safety backup before restore operation
  /// Returns backup ID for rollback reference
  /// 
  /// This creates a complete snapshot of current data and saves it:
  /// 1. Locally in safety_backups/ directory
  /// 2. Optionally to Firebase Storage (if user is authenticated)
  /// 
  /// The backup is automatically cleaned up after successful restore.
  Future<String> createPreRestoreBackup() async {
    final stopwatch = Stopwatch()..start();
    final backupId = DateTime.now().toIso8601String().replaceAll(':', '-');
    final backupName = 'pre_restore_$backupId.json';

    _logger.i('🛡️ Creating safety backup: $backupName');

    try {
      // Step 1: Load current data from Hive
      final incomeBox = await Hive.openBox<List<dynamic>>('income_entries');
      final outcomeBox = await Hive.openBox<List<dynamic>>('outcome_entries');

      // Step 2: Serialize to JSON
      final backupData = {
        'backup_id': backupId,
        'timestamp': DateTime.now().toIso8601String(),
        'type': 'safety_backup',
        'version': '2.0',
        'income_entries': {},
        'outcome_entries': {},
        'metadata': {
          'total_income_entries': 0,
          'total_outcome_entries': 0,
          'month_count': 0,
        },
      };

      int totalIncome = 0;
      int totalOutcome = 0;

      // Convert income entries
      for (final key in incomeBox.keys) {
        final entries = incomeBox.get(key);
        if (entries is List) {
          final jsonList = entries
              .whereType<IncomeEntry>()
              .map((e) => e.toJson())
              .toList();
          
          (backupData['income_entries'] as Map<String, dynamic>)[key.toString()] = jsonList;
          totalIncome += jsonList.length;
        }
      }

      // Convert outcome entries
      for (final key in outcomeBox.keys) {
        final entries = outcomeBox.get(key);
        if (entries is List) {
          final jsonList = entries
              .whereType<OutcomeEntry>()
              .map((e) => e.toJson())
              .toList();
          
          (backupData['outcome_entries'] as Map<String, dynamic>)[key.toString()] = jsonList;
          totalOutcome += jsonList.length;
        }
      }

      // Update metadata
      (backupData['metadata'] as Map<String, dynamic>)['total_income_entries'] = totalIncome;
      (backupData['metadata'] as Map<String, dynamic>)['total_outcome_entries'] = totalOutcome;
      (backupData['metadata'] as Map<String, dynamic>)['month_count'] = incomeBox.keys.length;

      // Step 3: Save to local file
      final directory = await getApplicationDocumentsDirectory();
      final safetyBackupDir = Directory('${directory.path}/safety_backups');
      if (!safetyBackupDir.existsSync()) {
        safetyBackupDir.createSync(recursive: true);
      }

      final file = File('${safetyBackupDir.path}/$backupName');
      await file.writeAsString(jsonEncode(backupData));

      _logger.i('✅ Safety backup created locally: ${file.path}');
      _logger.d('   Income entries: $totalIncome');
      _logger.d('   Outcome entries: $totalOutcome');
      _logger.d('   Months: ${incomeBox.keys.length}');

      // Step 4: Optional - Upload to Firebase Storage (for cloud safety)
      // Note: Firebase Storage upload commented out as it requires Firebase setup
      // Uncomment and configure if you want cloud backup
      /*
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('users/${user.uid}/safety_backups/$backupName');

          await storageRef.putString(
            jsonEncode(backupData),
            metadata: SettableMetadata(contentType: 'application/json'),
          );

          _logger.i('✅ Safety backup uploaded to cloud');
        }
      } catch (cloudError) {
        _logger.w('⚠️ Failed to upload safety backup to cloud: $cloudError');
        // Continue - local backup is sufficient
      }
      */

      // Step 5: Clean up old safety backups (keep last 5)
      await _cleanupOldSafetyBackups(safetyBackupDir);

      stopwatch.stop();
      _logger.i('✅ Safety backup complete in ${stopwatch.elapsedMilliseconds}ms');

      return backupId;
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to create safety backup', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Restore from safety backup
  /// Used for rollback in case of restore failure
  /// 
  /// Returns true if restoration was successful, false otherwise.
  Future<bool> restoreFromSafetyBackup(String backupId) async {
    _logger.i('🔄 Restoring from safety backup: $backupId');

    try {
      // Step 1: Find backup file
      final directory = await getApplicationDocumentsDirectory();
      final safetyBackupDir = Directory('${directory.path}/safety_backups');
      
      if (!safetyBackupDir.existsSync()) {
        _logger.e('❌ Safety backup directory not found');
        return false;
      }

      final backupFile = File('${safetyBackupDir.path}/pre_restore_$backupId.json');
      if (!backupFile.existsSync()) {
        _logger.e('❌ Safety backup file not found: ${backupFile.path}');
        return false;
      }

      // Step 2: Load backup data
      final jsonString = await backupFile.readAsString();
      final backupData = json.decode(jsonString) as Map<String, dynamic>;

      // Step 3: Validate data
      if (!_validateBackupData(backupData)) {
        _logger.e('❌ Invalid safety backup data');
        return false;
      }

      // Step 4: Restore to Hive
      final incomeBox = await Hive.openBox<List<dynamic>>('income_entries');
      final outcomeBox = await Hive.openBox<List<dynamic>>('outcome_entries');

      // Clear existing data
      await incomeBox.clear();
      await outcomeBox.clear();

      // Restore income entries
      final incomeData = backupData['income_entries'] as Map<String, dynamic>;
      for (final entry in incomeData.entries) {
        final entries = (entry.value as List)
            .map((e) => IncomeEntry.fromJson(e as Map<String, dynamic>))
            .toList();
        await incomeBox.put(entry.key, entries);
      }

      // Restore outcome entries
      final outcomeData = backupData['outcome_entries'] as Map<String, dynamic>;
      for (final entry in outcomeData.entries) {
        final entries = (entry.value as List)
            .map((e) => OutcomeEntry.fromJson(e as Map<String, dynamic>))
            .toList();
        await outcomeBox.put(entry.key, entries);
      }

      _logger.i('✅ Safety backup restored successfully');
      _logger.d('   Income entries: ${incomeData.length} months');
      _logger.d('   Outcome entries: ${outcomeData.length} months');

      return true;
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to restore safety backup', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Delete a safety backup file
  /// Called after successful restore to clean up
  Future<bool> deleteSafetyBackup(String backupId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final safetyBackupDir = Directory('${directory.path}/safety_backups');
      
      if (!safetyBackupDir.existsSync()) {
        return true; // Nothing to delete
      }

      final backupFile = File('${safetyBackupDir.path}/pre_restore_$backupId.json');
      if (backupFile.existsSync()) {
        await backupFile.delete();
        _logger.d('🗑️ Deleted safety backup: $backupId');
        return true;
      }

      return true;
    } catch (e) {
      _logger.w('⚠️ Failed to delete safety backup: $e');
      return false;
    }
  }

  /// Clean up old safety backups, keeping only the last 5
  Future<void> _cleanupOldSafetyBackups(Directory safetyBackupDir) async {
    try {
      final files = safetyBackupDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList();

      // Sort by modified time (oldest first)
      files.sort((a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));

      // Keep only last 5, delete the rest
      if (files.length > 5) {
        for (var i = 0; i < files.length - 5; i++) {
          await files[i].delete();
          _logger.d('🗑️ Deleted old safety backup: ${files[i].path}');
        }
      }
    } catch (e) {
      _logger.w('⚠️ Failed to cleanup old safety backups: $e');
    }
  }

  /// Validate backup data structure
  bool _validateBackupData(Map<String, dynamic> data) {
    try {
      // Check required fields
      if (!data.containsKey('backup_id')) return false;
      if (!data.containsKey('timestamp')) return false;
      if (!data.containsKey('income_entries')) return false;
      if (!data.containsKey('outcome_entries')) return false;

      // Check data types
      if (data['income_entries'] is! Map) return false;
      if (data['outcome_entries'] is! Map) return false;

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get list of available safety backups
  Future<List<SafetyBackupInfo>> getAvailableSafetyBackups() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final safetyBackupDir = Directory('${directory.path}/safety_backups');
      
      if (!safetyBackupDir.existsSync()) {
        return [];
      }

      final files = safetyBackupDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList();

      return files.map((file) {
        final stat = file.statSync();
        return SafetyBackupInfo(
          backupId: file.path.split(Platform.pathSeparator).last.replaceAll('.json', ''),
          filePath: file.path,
          createdAt: stat.modified,
          fileSize: stat.size,
        );
      }).toList();
    } catch (e) {
      _logger.e('❌ Failed to get safety backups list', error: e);
      return [];
    }
  }

  /// Get safety backup info by ID
  Future<SafetyBackupInfo?> getSafetyBackupInfo(String backupId) async {
    try {
      final backups = await getAvailableSafetyBackups();
      return backups.firstWhere(
        (backup) => backup.backupId == backupId,
        orElse: () => SafetyBackupInfo(
          backupId: '',
          filePath: '',
          createdAt: DateTime.now(),
          fileSize: 0,
        ),
      );
    } catch (e) {
      _logger.e('❌ Failed to get safety backup info', error: e);
      return null;
    }
  }
}

/// Information about a safety backup
class SafetyBackupInfo {
  final String backupId;
  final String filePath;
  final DateTime createdAt;
  final int fileSize;

  SafetyBackupInfo({
    required this.backupId,
    required this.filePath,
    required this.createdAt,
    required this.fileSize,
  });

  String get formattedSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get formattedDate {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}';
  }

  @override
  String toString() {
    return 'SafetyBackupInfo(id: $backupId, size: $formattedSize, date: $formattedDate)';
  }
}

