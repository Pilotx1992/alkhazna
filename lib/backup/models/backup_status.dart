/// Backup operation status for progress tracking
enum BackupStatus {
  idle,
  preparing,
  encrypting,
  uploading,
  completed,
  failed,
  cancelled,
}

/// Restore operation status for progress tracking
enum RestoreStatus {
  idle,
  downloading,
  decrypting,
  applying,
  completed,
  failed,
  cancelled,
}

/// Backup frequency options
enum BackupFrequency {
  off,
  daily,
  weekly,
  monthly,
}

/// Network preference for backup
enum NetworkPreference {
  wifiOnly,
  wifiAndMobile,
}

extension BackupStatusExtension on BackupStatus {
  String get displayName {
    switch (this) {
      case BackupStatus.idle:
        return 'Ready';
      case BackupStatus.preparing:
        return 'Preparing...';
      case BackupStatus.encrypting:
        return 'Encrypting...';
      case BackupStatus.uploading:
        return 'Uploading...';
      case BackupStatus.completed:
        return 'Completed';
      case BackupStatus.failed:
        return 'Failed';
      case BackupStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get emoji {
    switch (this) {
      case BackupStatus.idle:
        return '📱';
      case BackupStatus.preparing:
        return '🔄';
      case BackupStatus.encrypting:
        return '🔐';
      case BackupStatus.uploading:
        return '☁️';
      case BackupStatus.completed:
        return '✅';
      case BackupStatus.failed:
        return '❌';
      case BackupStatus.cancelled:
        return '⏹️';
    }
  }
}

extension RestoreStatusExtension on RestoreStatus {
  String get displayName {
    switch (this) {
      case RestoreStatus.idle:
        return 'Ready';
      case RestoreStatus.downloading:
        return 'Downloading...';
      case RestoreStatus.decrypting:
        return 'Decrypting...';
      case RestoreStatus.applying:
        return 'Restoring...';
      case RestoreStatus.completed:
        return 'Completed';
      case RestoreStatus.failed:
        return 'Failed';
      case RestoreStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get emoji {
    switch (this) {
      case RestoreStatus.idle:
        return '📱';
      case RestoreStatus.downloading:
        return '⬇️';
      case RestoreStatus.decrypting:
        return '🔓';
      case RestoreStatus.applying:
        return '📲';
      case RestoreStatus.completed:
        return '✅';
      case RestoreStatus.failed:
        return '❌';
      case RestoreStatus.cancelled:
        return '⏹️';
    }
  }
}

extension BackupFrequencyExtension on BackupFrequency {
  String get displayName {
    switch (this) {
      case BackupFrequency.off:
        return 'Off';
      case BackupFrequency.daily:
        return 'Daily';
      case BackupFrequency.weekly:
        return 'Weekly';
      case BackupFrequency.monthly:
        return 'Monthly';
    }
  }

  int get reminderDays {
    switch (this) {
      case BackupFrequency.off:
        return 999;
      case BackupFrequency.daily:
        return 2; // Remind after 2 days
      case BackupFrequency.weekly:
        return 10; // Remind after 10 days
      case BackupFrequency.monthly:
        return 35; // Remind after 35 days
    }
  }
}