/// Constants for WhatsApp-style backup system
class BackupConstants {
  // File names
  static const String backupFileName = 'alkhazna_backup.db.crypt14';
  static const String keyFileName = 'alkhazna_backup_keys.encrypted';
  static const String mediaFolderName = 'AlKhazna_Media';

  // Version info
  static const String backupVersion = '1.1';
  static const double keyFileVersion = 1.1;

  // Encryption
  static const int keySize = 32; // 256 bits
  static const int nonceSize = 12; // 96 bits for AES-GCM
  static const int tagSize = 16; // 128 bits for AES-GCM

  // Performance
  static const int maxBackupSize = 100 * 1024 * 1024; // 100 MB
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 5);
  static const Duration operationTimeout = Duration(minutes: 10);

  // Network
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration uploadTimeout = Duration(minutes: 5);
  static const Duration downloadTimeout = Duration(minutes: 5);

  // Notification IDs
  static const int backupProgressNotificationId = 1;
  static const int restoreProgressNotificationId = 2;
  static const int backupCompleteNotificationId = 3;
  static const int restoreCompleteNotificationId = 4;
  static const int reminderNotificationId = 5;

  // Notification channels
  static const String backupChannelId = 'alkhazna_backup_channel';
  static const String reminderChannelId = 'alkhazna_reminder_channel';

  // Shared preferences keys
  static const String lastBackupTimeKey = 'last_backup_time';
  static const String autoBackupEnabledKey = 'auto_backup_enabled';
  static const String autoBackupFrequencyKey = 'auto_backup_frequency';
  static const String networkPreferenceKey = 'network_preference';
  static const String localKeyName = 'alkhazna_master_key_v2';

  // Google Drive
  static const List<String> requiredScopes = [
    'https://www.googleapis.com/auth/drive.appdata',
    'email',
    'profile',
  ];

  // OEM manufacturers that require special handling
  static const List<String> aggressiveOEMs = [
    'xiaomi',
    'oppo', 
    'vivo',
    'huawei',
    'realme',
    'oneplus',
    'honor',
    'meizu',
    'lenovo',
  ];

  // Error messages
  static const Map<String, String> errorMessages = {
    'no_internet': 'No connection. Please connect to Wi-Fi and try again.',
    'signin_failed': 'Google sign-in failed. Please try again.',
    'no_backup_found': 'No backup available for this Google account.',
    'decryption_failed': 'Could not decrypt backup. The backup may be corrupted.',
    'drive_quota_exceeded': 'Google Drive storage is full. Free up space and try again.',
    'upload_failed': 'Upload failed. Check your connection and try again.',
    'download_failed': 'Download failed. Check your connection and try again.',
    'key_generation_failed': 'Failed to generate encryption key.',
    'key_storage_failed': 'Failed to store encryption key.',
    'database_backup_failed': 'Failed to create database backup.',
    'database_restore_failed': 'Failed to restore database.',
    'permission_denied': 'Permission denied. Please grant necessary permissions.',
    'storage_insufficient': 'Insufficient storage space.',
    'operation_cancelled': 'Operation was cancelled.',
    'unknown_error': 'An unexpected error occurred. Please try again.',
  };

  // Success messages
  static const Map<String, String> successMessages = {
    'backup_complete': 'Backup completed successfully!',
    'restore_complete': 'Restore completed successfully!',
    'key_generated': 'Encryption key generated successfully.',
    'drive_connected': 'Connected to Google Drive.',
    'auto_backup_enabled': 'Auto backup enabled.',
    'auto_backup_disabled': 'Auto backup disabled.',
  };

  // Progress messages
  static const Map<String, String> progressMessages = {
    'checking_connectivity': 'Checking connectivity...',
    'connecting_drive': 'Connecting to Google Drive...',
    'preparing_encryption': 'Preparing encryption...',
    'preparing_data': 'Preparing your data...',
    'encrypting_data': 'Encrypting your data...',
    'uploading_backup': 'Uploading to Google Drive...',
    'finalizing_backup': 'Finalizing backup...',
    'looking_for_backup': 'Looking for backup...',
    'downloading_backup': 'Downloading backup...',
    'preparing_decryption': 'Preparing decryption...',
    'decrypting_backup': 'Decrypting backup...',
    'restoring_data': 'Restoring your data...',
    'finalizing_restore': 'Finalizing restore...',
  };

  // Debug settings
  static const bool enableVerboseLogging = true;
  static const bool enableEncryptionLogging = false; // Security: Never log encryption details in production
  static const bool enableNetworkLogging = true;
  static const bool enableNotificationLogging = true;

  // Feature flags
  static const bool enableAutoBackup = true;
  static const bool enableBackgroundSync = true;
  static const bool enableOEMWorkarounds = true;
  static const bool enableNotifications = true;
  static const bool enableProgressNotifications = true;
  static const bool enableReminderNotifications = true;

  // UI constants
  static const double backupButtonHeight = 50.0;
  static const double progressIndicatorSize = 24.0;
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration notificationDisplayDuration = Duration(seconds: 3);

  // Validation
  static const int minPasswordLength = 8;
  static const int maxEmailLength = 254;
  static const int maxDeviceNameLength = 50;

  // Backup metadata
  static const String devicePlatform = 'android';
  static const String appName = 'alkhazna';
  static const String backupFormat = 'crypt14';

  /// Get user-friendly error message
  static String getUserFriendlyError(String errorKey) {
    return errorMessages[errorKey] ?? errorMessages['unknown_error']!;
  }

  /// Get success message
  static String getSuccessMessage(String successKey) {
    return successMessages[successKey] ?? 'Operation completed successfully.';
  }

  /// Get progress message
  static String getProgressMessage(String progressKey) {
    return progressMessages[progressKey] ?? 'Processing...';
  }

  /// Check if manufacturer requires special handling
  static bool isAggressiveOEM(String manufacturer) {
    return aggressiveOEMs.contains(manufacturer.toLowerCase());
  }

  /// Get backup file size limit in bytes
  static int get maxBackupSizeBytes => maxBackupSize;

  /// Get formatted max backup size
  static String get maxBackupSizeFormatted => '${maxBackupSize ~/ (1024 * 1024)} MB';

  /// Get retry configuration
  static Map<String, dynamic> get retryConfig => {
    'maxRetries': maxRetries,
    'retryDelay': retryDelay.inMilliseconds,
    'operationTimeout': operationTimeout.inMilliseconds,
  };

  /// Get notification configuration
  static Map<String, dynamic> get notificationConfig => {
    'backupChannelId': backupChannelId,
    'reminderChannelId': reminderChannelId,
    'enableProgress': enableProgressNotifications,
    'enableReminders': enableReminderNotifications,
  };

  /// Get network configuration
  static Map<String, dynamic> get networkConfig => {
    'connectTimeout': connectTimeout.inMilliseconds,
    'uploadTimeout': uploadTimeout.inMilliseconds,
    'downloadTimeout': downloadTimeout.inMilliseconds,
  };
}