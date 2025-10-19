import 'merge_statistics.dart';

/// Result of a smart merge operation
class MergeResult {
  final bool success;
  final int totalEntries;
  final int entriesFromBackup;
  final int entriesFromLocal;
  final int conflictsResolved;
  final int duplicatesSkipped;
  final String? errorMessage;
  final Duration duration;
  final MergeStatistics statistics;

  const MergeResult({
    required this.success,
    required this.totalEntries,
    required this.entriesFromBackup,
    required this.entriesFromLocal,
    required this.conflictsResolved,
    required this.duplicatesSkipped,
    this.errorMessage,
    required this.duration,
    required this.statistics,
  });

  factory MergeResult.success({
    required int totalEntries,
    required int entriesFromBackup,
    required int entriesFromLocal,
    required int conflictsResolved,
    required int duplicatesSkipped,
    required Duration duration,
    required MergeStatistics statistics,
  }) {
    return MergeResult(
      success: true,
      totalEntries: totalEntries,
      entriesFromBackup: entriesFromBackup,
      entriesFromLocal: entriesFromLocal,
      conflictsResolved: conflictsResolved,
      duplicatesSkipped: duplicatesSkipped,
      duration: duration,
      statistics: statistics,
    );
  }

  factory MergeResult.failure(String errorMessage) {
    return MergeResult(
      success: false,
      totalEntries: 0,
      entriesFromBackup: 0,
      entriesFromLocal: 0,
      conflictsResolved: 0,
      duplicatesSkipped: 0,
      errorMessage: errorMessage,
      duration: Duration.zero,
      statistics: MergeStatistics.empty(),
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'total_entries': totalEntries,
        'entries_from_backup': entriesFromBackup,
        'entries_from_local': entriesFromLocal,
        'conflicts_resolved': conflictsResolved,
        'duplicates_skipped': duplicatesSkipped,
        'error_message': errorMessage,
        'duration_ms': duration.inMilliseconds,
        'statistics': statistics.toJson(),
      };

  String toUserMessage() {
    if (!success) {
      return 'فشل الاستعادة: $errorMessage';
    }

    final buffer = StringBuffer();
    buffer.writeln('✅ تمت الاستعادة بنجاح!');
    buffer.writeln('');
    buffer.writeln('📊 الإحصائيات:');
    buffer.writeln('• إجمالي الإدخالات: $totalEntries');
    buffer.writeln('• من النسخة الاحتياطية: $entriesFromBackup');
    buffer.writeln('• من البيانات المحلية: $entriesFromLocal');

    if (conflictsResolved > 0) {
      buffer.writeln('• تم حل $conflictsResolved تعارض');
    }

    if (duplicatesSkipped > 0) {
      buffer.writeln('• تم تخطي $duplicatesSkipped مكرر');
    }

    buffer.writeln('');
    buffer.writeln('⏱️ الوقت المستغرق: ${duration.inMilliseconds}ms');

    return buffer.toString();
  }

  String toDetailedReport() {
    if (!success) {
      return 'Restore Failed: $errorMessage';
    }

    final buffer = StringBuffer();
    buffer.writeln('=' * 60);
    buffer.writeln('SMART RESTORE - DETAILED REPORT');
    buffer.writeln('=' * 60);
    buffer.writeln('');
    buffer.writeln('Status: ${success ? "SUCCESS ✅" : "FAILED ❌"}');
    buffer.writeln('Duration: ${duration.inMilliseconds}ms');
    buffer.writeln('');
    buffer.writeln('Summary:');
    buffer.writeln('  Total Entries: $totalEntries');
    buffer.writeln('  From Backup: $entriesFromBackup');
    buffer.writeln('  From Local: $entriesFromLocal');
    buffer.writeln('  Conflicts Resolved: $conflictsResolved');
    buffer.writeln('  Duplicates Skipped: $duplicatesSkipped');
    buffer.writeln('');
    buffer.writeln(statistics.toReadableString());
    buffer.writeln('=' * 60);

    return buffer.toString();
  }
}
