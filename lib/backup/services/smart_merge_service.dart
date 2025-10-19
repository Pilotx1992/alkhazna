import 'package:flutter/foundation.dart';
import '../../models/income_entry.dart';
import '../../models/outcome_entry.dart';
import '../models/merge_statistics.dart';

/// Smart Merge Service - WhatsApp-style intelligent merge
/// Merges backup data with local data without data loss
class SmartMergeService {
  static final SmartMergeService _instance = SmartMergeService._internal();
  factory SmartMergeService() => _instance;
  SmartMergeService._internal();

  /// Merge backup income entries with local entries
  /// Returns map of merged entries organized by month-year keys
  Future<Map<String, List<IncomeEntry>>> mergeIncomeEntries({
    required Map<String, List<IncomeEntry>> backupData,
    required Map<String, List<IncomeEntry>> localData,
    required MergeTracker tracker,
  }) async {
    final startTime = DateTime.now();
    final Map<String, List<IncomeEntry>> mergedData = {};

    if (kDebugMode) {
      print('[SmartMerge] 🔄 Starting income merge...');
      print('[SmartMerge]    Backup months: ${backupData.keys.length}');
      print('[SmartMerge]    Local months: ${localData.keys.length}');
    }

    // Step 1: Get all unique month keys
    final allMonthKeys = <String>{
      ...backupData.keys,
      ...localData.keys,
    };

    // Step 2: Merge each month's data
    for (final monthKey in allMonthKeys) {
      final backupEntries = backupData[monthKey] ?? [];
      final localEntries = localData[monthKey] ?? [];

      if (kDebugMode) {
        print('[SmartMerge] 📅 Processing month: $monthKey');
        print('[SmartMerge]    Backup entries: ${backupEntries.length}');
        print('[SmartMerge]    Local entries: ${localEntries.length}');
      }

      // Merge entries for this month
      final mergedMonthEntries = await _mergeIncomeList(
        backupEntries: backupEntries,
        localEntries: localEntries,
        tracker: tracker,
      );

      mergedData[monthKey] = mergedMonthEntries;

      if (kDebugMode) {
        print('[SmartMerge]    ✅ Merged: ${mergedMonthEntries.length} entries');
      }
    }

    final duration = DateTime.now().difference(startTime);
    if (kDebugMode) {
      print(
          '[SmartMerge] ✅ Income merge complete in ${duration.inMilliseconds}ms');
    }

    return mergedData;
  }

  /// Merge backup outcome entries with local entries
  Future<Map<String, List<OutcomeEntry>>> mergeOutcomeEntries({
    required Map<String, List<OutcomeEntry>> backupData,
    required Map<String, List<OutcomeEntry>> localData,
    required MergeTracker tracker,
  }) async {
    final startTime = DateTime.now();
    final Map<String, List<OutcomeEntry>> mergedData = {};

    if (kDebugMode) {
      print('[SmartMerge] 🔄 Starting outcome merge...');
      print('[SmartMerge]    Backup months: ${backupData.keys.length}');
      print('[SmartMerge]    Local months: ${localData.keys.length}');
    }

    // Step 1: Get all unique month keys
    final allMonthKeys = <String>{
      ...backupData.keys,
      ...localData.keys,
    };

    // Step 2: Merge each month's data
    for (final monthKey in allMonthKeys) {
      final backupEntries = backupData[monthKey] ?? [];
      final localEntries = localData[monthKey] ?? [];

      if (kDebugMode) {
        print('[SmartMerge] 📅 Processing month: $monthKey');
        print('[SmartMerge]    Backup entries: ${backupEntries.length}');
        print('[SmartMerge]    Local entries: ${localEntries.length}');
      }

      // Merge entries for this month
      final mergedMonthEntries = await _mergeOutcomeList(
        backupEntries: backupEntries,
        localEntries: localEntries,
        tracker: tracker,
      );

      mergedData[monthKey] = mergedMonthEntries;

      if (kDebugMode) {
        print('[SmartMerge]    ✅ Merged: ${mergedMonthEntries.length} entries');
      }
    }

    final duration = DateTime.now().difference(startTime);
    if (kDebugMode) {
      print(
          '[SmartMerge] ✅ Outcome merge complete in ${duration.inMilliseconds}ms');
    }

    return mergedData;
  }

  /// Merge two lists of income entries using smart conflict resolution
  Future<List<IncomeEntry>> _mergeIncomeList({
    required List<IncomeEntry> backupEntries,
    required List<IncomeEntry> localEntries,
    required MergeTracker tracker,
  }) async {
    // Create maps for efficient lookup by ID
    final Map<String, IncomeEntry> localMap = {
      for (var entry in localEntries) entry.id: entry
    };

    final List<IncomeEntry> mergedList = [];
    final Set<String> processedIds = {};

    // Step 1: Process backup entries
    for (final backupEntry in backupEntries) {
      final id = backupEntry.id;
      processedIds.add(id);

      if (localMap.containsKey(id)) {
        // CONFLICT: Entry exists in both backup and local
        final localEntry = localMap[id]!;
        final winner = _resolveIncomeConflict(
          backupEntry: backupEntry,
          localEntry: localEntry,
          tracker: tracker,
        );
        mergedList.add(winner);
        tracker.incomeConflicts++;
      } else {
        // NEW: Entry only in backup
        mergedList.add(backupEntry);
        tracker.incomeAdded++;
      }
    }

    // Step 2: Add local entries that don't exist in backup
    for (final localEntry in localEntries) {
      if (!processedIds.contains(localEntry.id)) {
        mergedList.add(localEntry);
        tracker.incomeSkipped++;
      }
    }

    return mergedList;
  }

  /// Merge two lists of outcome entries
  Future<List<OutcomeEntry>> _mergeOutcomeList({
    required List<OutcomeEntry> backupEntries,
    required List<OutcomeEntry> localEntries,
    required MergeTracker tracker,
  }) async {
    final Map<String, OutcomeEntry> localMap = {
      for (var entry in localEntries) entry.id: entry
    };

    final List<OutcomeEntry> mergedList = [];
    final Set<String> processedIds = {};

    // Step 1: Process backup entries
    for (final backupEntry in backupEntries) {
      final id = backupEntry.id;
      processedIds.add(id);

      if (localMap.containsKey(id)) {
        // CONFLICT: Entry exists in both
        final localEntry = localMap[id]!;
        final winner = _resolveOutcomeConflict(
          backupEntry: backupEntry,
          localEntry: localEntry,
          tracker: tracker,
        );
        mergedList.add(winner);
        tracker.outcomeConflicts++;
      } else {
        // NEW: Entry only in backup
        mergedList.add(backupEntry);
        tracker.outcomeAdded++;
      }
    }

    // Step 2: Add local entries not in backup
    for (final localEntry in localEntries) {
      if (!processedIds.contains(localEntry.id)) {
        mergedList.add(localEntry);
        tracker.outcomeSkipped++;
      }
    }

    return mergedList;
  }

  /// Resolve conflict between backup and local income entry
  /// Returns the "winning" entry based on smart rules
  IncomeEntry _resolveIncomeConflict({
    required IncomeEntry backupEntry,
    required IncomeEntry localEntry,
    required MergeTracker tracker,
  }) {
    String resolution;
    IncomeEntry winner;

    // Rule 1: Compare versions (higher version wins)
    if (backupEntry.version != localEntry.version) {
      winner =
          backupEntry.version > localEntry.version ? backupEntry : localEntry;
      resolution = winner == backupEntry
          ? 'backup_version_higher'
          : 'local_version_higher';
    }
    // Rule 2: Compare updatedAt timestamps (newer wins)
    else if (backupEntry.updatedAt != null && localEntry.updatedAt != null) {
      winner = backupEntry.updatedAt!.isAfter(localEntry.updatedAt!)
          ? backupEntry
          : localEntry;
      resolution = winner == backupEntry ? 'backup_newer' : 'local_newer';
    }
    // Rule 3: Fallback to createdAt (newer wins)
    else if (backupEntry.createdAt != null && localEntry.createdAt != null) {
      winner = backupEntry.createdAt!.isAfter(localEntry.createdAt!)
          ? backupEntry
          : localEntry;
      resolution = winner == backupEntry
          ? 'backup_created_later'
          : 'local_created_later';
    }
    // Rule 4: Default to backup
    else {
      winner = backupEntry;
      resolution = 'backup_default';
    }

    // Track conflict details
    tracker.conflicts.add(ConflictDetail(
      entryId: backupEntry.id,
      entryType: 'income',
      resolution: resolution,
      backupTime: backupEntry.updatedAt ?? backupEntry.createdAt,
      localTime: localEntry.updatedAt ?? localEntry.createdAt,
      backupVersion: backupEntry.version,
      localVersion: localEntry.version,
    ));

    if (kDebugMode) {
      print(
          '[SmartMerge] ⚔️ Conflict resolved: ${backupEntry.id} → $resolution');
    }

    return winner;
  }

  /// Resolve conflict for outcome entries
  OutcomeEntry _resolveOutcomeConflict({
    required OutcomeEntry backupEntry,
    required OutcomeEntry localEntry,
    required MergeTracker tracker,
  }) {
    String resolution;
    OutcomeEntry winner;

    // Rule 1: Compare versions
    if (backupEntry.version != localEntry.version) {
      winner =
          backupEntry.version > localEntry.version ? backupEntry : localEntry;
      resolution = winner == backupEntry
          ? 'backup_version_higher'
          : 'local_version_higher';
    }
    // Rule 2: Compare updatedAt
    else if (backupEntry.updatedAt != null && localEntry.updatedAt != null) {
      winner = backupEntry.updatedAt!.isAfter(localEntry.updatedAt!)
          ? backupEntry
          : localEntry;
      resolution = winner == backupEntry ? 'backup_newer' : 'local_newer';
    }
    // Rule 3: Fallback to createdAt
    else if (backupEntry.createdAt != null && localEntry.createdAt != null) {
      winner = backupEntry.createdAt!.isAfter(localEntry.createdAt!)
          ? backupEntry
          : localEntry;
      resolution = winner == backupEntry
          ? 'backup_created_later'
          : 'local_created_later';
    }
    // Rule 4: Default to backup
    else {
      winner = backupEntry;
      resolution = 'backup_default';
    }

    tracker.conflicts.add(ConflictDetail(
      entryId: backupEntry.id,
      entryType: 'outcome',
      resolution: resolution,
      backupTime: backupEntry.updatedAt ?? backupEntry.createdAt,
      localTime: localEntry.updatedAt ?? localEntry.createdAt,
      backupVersion: backupEntry.version,
      localVersion: localEntry.version,
    ));

    if (kDebugMode) {
      print(
          '[SmartMerge] ⚔️ Conflict resolved: ${backupEntry.id} → $resolution');
    }

    return winner;
  }
}

/// Tracks merge statistics during the merge process
class MergeTracker {
  int incomeAdded = 0;
  int incomeUpdated = 0;
  int incomeConflicts = 0;
  int incomeSkipped = 0;

  int outcomeAdded = 0;
  int outcomeUpdated = 0;
  int outcomeConflicts = 0;
  int outcomeSkipped = 0;

  final List<ConflictDetail> conflicts = [];
  late DateTime startTime;
  late DateTime endTime;

  void start() {
    startTime = DateTime.now();
  }

  void finish() {
    endTime = DateTime.now();
  }

  Duration get duration => endTime.difference(startTime);

  MergeStatistics toStatistics() {
    return MergeStatistics(
      incomeAdded: incomeAdded,
      incomeUpdated: incomeUpdated,
      incomeConflicts: incomeConflicts,
      incomeSkipped: incomeSkipped,
      outcomeAdded: outcomeAdded,
      outcomeUpdated: outcomeUpdated,
      outcomeConflicts: outcomeConflicts,
      outcomeSkipped: outcomeSkipped,
      conflicts: conflicts,
      startTime: startTime,
      endTime: endTime,
      processingTime: duration,
    );
  }
}
