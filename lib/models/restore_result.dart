import 'backup_status.dart';

/// Result of a restore operation
class RestoreResult {
  final bool success;
  final String? errorMessage;
  final int? incomeEntriesRestored;
  final int? outcomeEntriesRestored;
  final DateTime? backupDate;
  final String? sourceDevice;

  const RestoreResult({
    required this.success,
    this.errorMessage,
    this.incomeEntriesRestored,
    this.outcomeEntriesRestored,
    this.backupDate,
    this.sourceDevice,
  });

  factory RestoreResult.success({
    required int incomeEntries,
    required int outcomeEntries,
    required DateTime backupDate,
    required String sourceDevice,
  }) => RestoreResult(
    success: true,
    incomeEntriesRestored: incomeEntries,
    outcomeEntriesRestored: outcomeEntries,
    backupDate: backupDate,
    sourceDevice: sourceDevice,
  );

  factory RestoreResult.failure(String errorMessage) => RestoreResult(
    success: false,
    errorMessage: errorMessage,
  );

  String get summary {
    if (!success) return errorMessage ?? 'Restore failed';
    
    final total = (incomeEntriesRestored ?? 0) + (outcomeEntriesRestored ?? 0);
    return 'Restored $total entries from $sourceDevice';
  }
}

/// Progress information for backup/restore operations
class OperationProgress {
  final int percentage;
  final BackupStatus? backupStatus;
  final RestoreStatus? restoreStatus;
  final String currentAction;
  final String? errorMessage;

  const OperationProgress({
    required this.percentage,
    this.backupStatus,
    this.restoreStatus,
    required this.currentAction,
    this.errorMessage,
  });

  bool get isCompleted => percentage >= 100;
  bool get isFailed => backupStatus == BackupStatus.failed || restoreStatus == RestoreStatus.failed;
  bool get isCancelled => backupStatus == BackupStatus.cancelled || restoreStatus == RestoreStatus.cancelled;

  String get statusEmoji {
    if (backupStatus != null) return backupStatus!.emoji;
    if (restoreStatus != null) return restoreStatus!.emoji;
    return '📱';
  }

  String get statusText {
    if (backupStatus != null) return backupStatus!.displayName;
    if (restoreStatus != null) return restoreStatus!.displayName;
    return 'Ready';
  }
}