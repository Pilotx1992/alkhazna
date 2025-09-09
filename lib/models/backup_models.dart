import 'package:hive/hive.dart';

part 'backup_models.g.dart';

// Backup frequency options
enum BackupFrequency {
  daily,
  weekly,
  monthly,
  manual,
}

// Backup status states
enum BackupStatus {
  idle,
  preparing,
  compressing,
  uploading,
  completed,
  failed,
  cancelled,
}

// Restore status states
enum RestoreStatus {
  idle,
  downloading,
  decrypting,
  applying,
  completed,
  failed,
  cancelled,
}

@HiveType(typeId: 4)
class BackupInfo extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  DateTime createdAt;

  @HiveField(2)
  int sizeBytes;

  @HiveField(3)
  String deviceName;

  @HiveField(4)
  String driveFileId;

  @HiveField(5)
  BackupStatus status;

  @HiveField(6)
  String? errorMessage;

  @HiveField(7)
  int incomeEntriesCount;

  @HiveField(8)
  int outcomeEntriesCount;

  @HiveField(9)
  bool isEncrypted;

  @HiveField(10)
  String? encryptionIv;

  @HiveField(11)
  String? encryptionTag;

  @HiveField(12)
  bool isCompressed;

  @HiveField(13)
  int? originalSize;

  @HiveField(14)
  int? compressedSize;

  @HiveField(15)
  double? compressionRatio;

  BackupInfo({
    required this.id,
    required this.createdAt,
    required this.sizeBytes,
    required this.deviceName,
    required this.driveFileId,
    this.status = BackupStatus.idle,
    this.errorMessage,
    this.incomeEntriesCount = 0,
    this.outcomeEntriesCount = 0,
    this.isEncrypted = false,
    this.encryptionIv,
    this.encryptionTag,
    this.isCompressed = false,
    this.originalSize,
    this.compressedSize,
    this.compressionRatio,
  });

  String get formattedSize {
    if (sizeBytes < 1024) return '${sizeBytes}B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)}KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays == 0) {
      return 'Today ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  String get compressionInfo {
    if (!isCompressed || compressionRatio == null) return 'No compression';
    return 'Compressed ${compressionRatio!.toStringAsFixed(1)}%';
  }

  String get formattedOriginalSize {
    if (originalSize == null) return 'Unknown';
    if (originalSize! < 1024) return '${originalSize!}B';
    if (originalSize! < 1024 * 1024) return '${(originalSize! / 1024).toStringAsFixed(1)}KB';
    return '${(originalSize! / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}

@HiveType(typeId: 5)
class BackupProgress {
  @HiveField(0)
  double percentage;

  @HiveField(1)
  BackupStatus status;

  @HiveField(2)
  String currentAction;

  @HiveField(3)
  int bytesTransferred;

  @HiveField(4)
  int totalBytes;

  @HiveField(5)
  double speedBytesPerSecond;

  @HiveField(6)
  DateTime? estimatedCompletion;

  @HiveField(7)
  String? errorMessage;

  BackupProgress({
    this.percentage = 0.0,
    this.status = BackupStatus.idle,
    this.currentAction = 'Preparing...',
    this.bytesTransferred = 0,
    this.totalBytes = 0,
    this.speedBytesPerSecond = 0.0,
    this.estimatedCompletion,
    this.errorMessage,
  });

  String get formattedSpeed {
    if (speedBytesPerSecond < 1024) return '${speedBytesPerSecond.toStringAsFixed(0)}B/s';
    if (speedBytesPerSecond < 1024 * 1024) return '${(speedBytesPerSecond / 1024).toStringAsFixed(1)}KB/s';
    return '${(speedBytesPerSecond / (1024 * 1024)).toStringAsFixed(1)}MB/s';
  }

  String get estimatedTimeRemaining {
    if (estimatedCompletion == null || speedBytesPerSecond <= 0) return 'Calculating...';
    
    final remaining = estimatedCompletion!.difference(DateTime.now());
    if (remaining.inSeconds < 60) return '${remaining.inSeconds}s remaining';
    if (remaining.inMinutes < 60) return '${remaining.inMinutes}m remaining';
    return '${remaining.inHours}h ${remaining.inMinutes % 60}m remaining';
  }
}

@HiveType(typeId: 6)
class RestoreProgress {
  @HiveField(0)
  double percentage;

  @HiveField(1)
  RestoreStatus status;

  @HiveField(2)
  String currentAction;

  @HiveField(3)
  int bytesTransferred;

  @HiveField(4)
  int totalBytes;

  @HiveField(5)
  String? errorMessage;

  @HiveField(6)
  String? backupId;

  RestoreProgress({
    this.percentage = 0.0,
    this.status = RestoreStatus.idle,
    this.currentAction = 'Preparing restoration...',
    this.bytesTransferred = 0,
    this.totalBytes = 0,
    this.errorMessage,
    this.backupId,
  });

  String get statusDisplayText {
    switch (status) {
      case RestoreStatus.downloading:
        return 'Downloading backup from Google Drive...';
      case RestoreStatus.decrypting:
        return 'Decrypting and validating data...';
      case RestoreStatus.applying:
        return 'Restoring your data...';
      case RestoreStatus.completed:
        return 'Restoration completed successfully!';
      case RestoreStatus.failed:
        return 'Restoration failed: ${errorMessage ?? 'Unknown error'}';
      case RestoreStatus.cancelled:
        return 'Restoration cancelled by user';
      default:
        return currentAction;
    }
  }
}

@HiveType(typeId: 7)
class BackupSettings extends HiveObject {
  @HiveField(0)
  bool autoBackupEnabled;

  @HiveField(1)
  BackupFrequency frequency;

  @HiveField(2)
  DateTime? lastBackupTime;

  @HiveField(3)
  DateTime? nextScheduledBackup;

  @HiveField(4)
  bool backupOnWifiOnly;

  @HiveField(5)
  bool includeImages;

  @HiveField(6)
  String? googleAccountEmail;

  @HiveField(7)
  int maxBackupsToKeep;

  BackupSettings({
    this.autoBackupEnabled = false,
    this.frequency = BackupFrequency.weekly,
    this.lastBackupTime,
    this.nextScheduledBackup,
    this.backupOnWifiOnly = true,
    this.includeImages = true,
    this.googleAccountEmail,
    this.maxBackupsToKeep = 5,
  });

  String get frequencyDisplayText {
    switch (frequency) {
      case BackupFrequency.daily:
        return 'Daily';
      case BackupFrequency.weekly:
        return 'Weekly';
      case BackupFrequency.monthly:
        return 'Monthly';
      case BackupFrequency.manual:
        return 'Manual only';
    }
  }

  String get lastBackupDisplayText {
    if (lastBackupTime == null) return 'Never';
    
    final now = DateTime.now();
    final difference = now.difference(lastBackupTime!);
    
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes} minutes ago';
    if (difference.inDays < 1) return '${difference.inHours} hours ago';
    if (difference.inDays < 7) return '${difference.inDays} days ago';
    
    return '${lastBackupTime!.day}/${lastBackupTime!.month}/${lastBackupTime!.year}';
  }

  Map<String, dynamic> toJson() => {
    'autoBackupEnabled': autoBackupEnabled,
    'frequency': frequency.name,
    'lastBackupTime': lastBackupTime?.toIso8601String(),
    'nextScheduledBackup': nextScheduledBackup?.toIso8601String(),
    'backupOnWifiOnly': backupOnWifiOnly,
    'includeImages': includeImages,
    'googleAccountEmail': googleAccountEmail,
    'maxBackupsToKeep': maxBackupsToKeep,
  };
}