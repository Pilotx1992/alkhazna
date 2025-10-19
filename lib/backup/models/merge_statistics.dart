/// Extended statistics for merge operation (v1.1)
class MergeStatistics {
  // Income statistics
  final int incomeAdded;
  final int incomeUpdated;
  final int incomeConflicts;
  final int incomeSkipped;

  // Outcome statistics
  final int outcomeAdded;
  final int outcomeUpdated;
  final int outcomeConflicts;
  final int outcomeSkipped;

  // Conflict resolution details
  final List<ConflictDetail> conflicts;

  // Performance metrics
  final DateTime startTime;
  final DateTime endTime;
  final Duration processingTime;

  const MergeStatistics({
    required this.incomeAdded,
    required this.incomeUpdated,
    required this.incomeConflicts,
    required this.incomeSkipped,
    required this.outcomeAdded,
    required this.outcomeUpdated,
    required this.outcomeConflicts,
    required this.outcomeSkipped,
    required this.conflicts,
    required this.startTime,
    required this.endTime,
    required this.processingTime,
  });

  factory MergeStatistics.empty() {
    final now = DateTime.now();
    return MergeStatistics(
      incomeAdded: 0,
      incomeUpdated: 0,
      incomeConflicts: 0,
      incomeSkipped: 0,
      outcomeAdded: 0,
      outcomeUpdated: 0,
      outcomeConflicts: 0,
      outcomeSkipped: 0,
      conflicts: [],
      startTime: now,
      endTime: now,
      processingTime: Duration.zero,
    );
  }

  int get totalIncome => incomeAdded + incomeUpdated + incomeSkipped;
  int get totalOutcome => outcomeAdded + outcomeUpdated + outcomeSkipped;
  int get totalEntries => totalIncome + totalOutcome;
  int get totalConflicts => incomeConflicts + outcomeConflicts;

  Map<String, dynamic> toJson() => {
        'income': {
          'added': incomeAdded,
          'updated': incomeUpdated,
          'conflicts': incomeConflicts,
          'skipped': incomeSkipped,
          'total': totalIncome,
        },
        'outcome': {
          'added': outcomeAdded,
          'updated': outcomeUpdated,
          'conflicts': outcomeConflicts,
          'skipped': outcomeSkipped,
          'total': totalOutcome,
        },
        'summary': {
          'total_entries': totalEntries,
          'total_conflicts': totalConflicts,
          'processing_time_ms': processingTime.inMilliseconds,
        },
        'conflicts': conflicts.map((c) => c.toJson()).toList(),
      };

  String toReadableString() {
    final buffer = StringBuffer();
    buffer.writeln('📊 Merge Statistics:');
    buffer.writeln('');
    buffer.writeln('Income:');
    buffer.writeln('  ✅ Added: $incomeAdded');
    buffer.writeln('  🔄 Updated: $incomeUpdated');
    buffer.writeln('  ⚠️ Conflicts: $incomeConflicts');
    buffer.writeln('  ⏭️ Skipped: $incomeSkipped');
    buffer.writeln('');
    buffer.writeln('Outcome:');
    buffer.writeln('  ✅ Added: $outcomeAdded');
    buffer.writeln('  🔄 Updated: $outcomeUpdated');
    buffer.writeln('  ⚠️ Conflicts: $outcomeConflicts');
    buffer.writeln('  ⏭️ Skipped: $outcomeSkipped');
    buffer.writeln('');
    buffer.writeln('Summary:');
    buffer.writeln('  📦 Total Entries: $totalEntries');
    buffer.writeln('  ⚔️ Total Conflicts Resolved: $totalConflicts');
    buffer.writeln('  ⏱️ Processing Time: ${processingTime.inMilliseconds}ms');
    return buffer.toString();
  }
}

/// Details about a conflict resolution
class ConflictDetail {
  final String entryId;
  final String entryType; // 'income' or 'outcome'
  final String resolution; // 'backup_newer', 'local_newer', 'version_higher'
  final DateTime? backupTime;
  final DateTime? localTime;
  final int? backupVersion;
  final int? localVersion;

  const ConflictDetail({
    required this.entryId,
    required this.entryType,
    required this.resolution,
    this.backupTime,
    this.localTime,
    this.backupVersion,
    this.localVersion,
  });

  Map<String, dynamic> toJson() => {
        'entry_id': entryId,
        'entry_type': entryType,
        'resolution': resolution,
        'backup_time': backupTime?.toIso8601String(),
        'local_time': localTime?.toIso8601String(),
        'backup_version': backupVersion,
        'local_version': localVersion,
      };
}
