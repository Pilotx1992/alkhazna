import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
/// Enhanced notification system for backup operations
class NotificationHelper {
  static final NotificationHelper _instance = NotificationHelper._internal();
  factory NotificationHelper() => _instance;
  NotificationHelper._internal();

  static const String channelId = 'alkhazna_backup_channel';
  static const String reminderChannelId = 'alkhazna_reminder_channel';
  
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Initialize notification system
  Future<bool> initialize() async {
    if (_initialized) return true;

    try {
      // Android settings
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // iOS settings (if needed in future)
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      final initialized = await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      if (initialized == true) {
        await _createNotificationChannels();
        _initialized = true;
        
        if (kDebugMode) {
          print('✅ Notifications initialized');
        }
      }

      return _initialized;
    } catch (e) {
      if (kDebugMode) {
        print('💥 Failed to initialize notifications: $e');
      }
      return false;
    }
  }

  /// Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    // Backup progress channel
    const backupChannel = AndroidNotificationChannel(
      channelId,
      'Backup Notifications',
      description: 'Notifications for backup and restore operations',
      importance: Importance.low,
      showBadge: false,
    );

    // Reminder channel
    const reminderChannel = AndroidNotificationChannel(
      reminderChannelId,
      'Backup Reminders',
      description: 'Reminders to create backups',
      importance: Importance.defaultImportance,
      showBadge: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(backupChannel);

    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(reminderChannel);
  }

  /// Show backup progress notification
  Future<void> showBackupProgress({
    required String stage,
    required int percentage,
    required String message,
  }) async {
    if (!_initialized && !await initialize()) return;

    try {
      final icon = _getIconForStage(stage);
      
      await _notifications.show(
        1, // Backup notification ID
        '$icon Backup in progress',
        '$message ($percentage%)',
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            'Backup Notifications',
            channelDescription: 'Notifications for backup operations',
            ongoing: true,
            autoCancel: false,
            showProgress: true,
            maxProgress: 100,
            progress: percentage,
            onlyAlertOnce: true,
            category: AndroidNotificationCategory.progress,
            visibility: NotificationVisibility.public,
          ),
        ),
      );

      if (kDebugMode) {
        print('📱 Backup progress notification: $percentage% - $message');
      }
    } catch (e) {
      if (kDebugMode) {
        print('💥 Error showing backup progress: $e');
      }
    }
  }

  /// Show restore progress notification
  Future<void> showRestoreProgress({
    required String stage,
    required int percentage,
    required String message,
  }) async {
    if (!_initialized && !await initialize()) return;

    try {
      final icon = _getIconForStage(stage);
      
      await _notifications.show(
        2, // Restore notification ID
        '$icon Restore in progress',
        '$message ($percentage%)',
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            'Backup Notifications',
            channelDescription: 'Notifications for restore operations',
            ongoing: true,
            autoCancel: false,
            showProgress: true,
            maxProgress: 100,
            progress: percentage,
            onlyAlertOnce: true,
            category: AndroidNotificationCategory.progress,
            visibility: NotificationVisibility.public,
          ),
        ),
      );

      if (kDebugMode) {
        print('📱 Restore progress notification: $percentage% - $message');
      }
    } catch (e) {
      if (kDebugMode) {
        print('💥 Error showing restore progress: $e');
      }
    }
  }

  /// Show backup completion notification
  Future<void> showBackupComplete({
    required bool success,
    required String message,
    String? details,
  }) async {
    if (!_initialized && !await initialize()) return;

    try {
      final icon = success ? '✅' : '❌';
      final title = success ? 'Backup completed' : 'Backup failed';

      await _notifications.show(
        3, // Completion notification ID
        '$icon $title',
        details ?? message,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            'Backup Notifications',
            channelDescription: 'Backup completion notifications',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            autoCancel: true,
            category: success
                ? AndroidNotificationCategory.status
                : AndroidNotificationCategory.error,
            colorized: true,
            timeoutAfter: 2000, // 2 seconds
          ),
        ),
      );

      if (kDebugMode) {
        print('📱 Backup completion notification: $message');
      }
    } catch (e) {
      if (kDebugMode) {
        print('💥 Error showing completion notification: $e');
      }
    }
  }

  /// Show restore completion notification
  Future<void> showRestoreComplete({
    required bool success,
    required String message,
    String? details,
  }) async {
    if (!_initialized && !await initialize()) return;

    try {
      final icon = success ? '✅' : '❌';
      final title = success ? 'Restore completed' : 'Restore failed';

      await _notifications.show(
        4, // Restore completion notification ID
        '$icon $title',
        details ?? message,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            'Backup Notifications',
            channelDescription: 'Restore completion notifications',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            autoCancel: true,
            category: success
                ? AndroidNotificationCategory.status
                : AndroidNotificationCategory.error,
            colorized: true,
            timeoutAfter: 2000, // 2 seconds
          ),
        ),
      );

      if (kDebugMode) {
        print('📱 Restore completion notification: $message');
      }
    } catch (e) {
      if (kDebugMode) {
        print('💥 Error showing restore completion: $e');
      }
    }
  }

  /// Show backup reminder notification (fallback for OEM issues)
  Future<void> showReminder({
    required String title,
    required String body,
    String? action,
  }) async {
    if (!_initialized && !await initialize()) return;

    try {
      await _notifications.show(
        5, // Reminder notification ID
        '🔔 $title',
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            reminderChannelId,
            'Backup Reminders',
            channelDescription: 'Reminders to create backups',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            autoCancel: true,
            category: AndroidNotificationCategory.reminder,
            timeoutAfter: 2000, // 2seconds
            actions: action != null ? [
              AndroidNotificationAction(
                action,
                'Backup Now',
                showsUserInterface: true,
              ),
            ] : null,
          ),
        ),
      );

      if (kDebugMode) {
        print('📱 Backup reminder notification: $title');
      }
    } catch (e) {
      if (kDebugMode) {
        print('💥 Error showing reminder: $e');
      }
    }
  }

  /// Clear all progress notifications
  Future<void> clearProgressNotifications() async {
    try {
      await _notifications.cancel(1); // Backup progress
      await _notifications.cancel(2); // Restore progress
      
      if (kDebugMode) {
        print('🧹 Progress notifications cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        print('💥 Error clearing notifications: $e');
      }
    }
  }

  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    try {
      await _notifications.cancelAll();
      
      if (kDebugMode) {
        print('🧹 All notifications cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        print('💥 Error clearing all notifications: $e');
      }
    }
  }

  /// Get icon for stage
  String _getIconForStage(String stage) {
    switch (stage.toLowerCase()) {
      case 'preparing':
        return '🔄';
      case 'encrypting':
        return '🔐';
      case 'uploading':
        return '☁️';
      case 'downloading':
        return '⬇️';
      case 'decrypting':
        return '🔓';
      case 'applying':
      case 'restoring':
        return '📲';
      case 'completed':
        return '✅';
      case 'failed':
        return '❌';
      default:
        return '📱';
    }
  }

  /// Handle notification taps
  void _onNotificationTapped(NotificationResponse response) {
    if (kDebugMode) {
      print('📱 Notification tapped: ${response.payload}');
    }

    // Handle different notification actions
    switch (response.actionId) {
      case 'BACKUP_NOW':
        // TODO: Trigger backup from notification
        if (kDebugMode) {
          print('🔔 Backup now action triggered');
        }
        break;
      default:
        // Handle general notification tap
        break;
    }
  }

  /// Request notification permissions (Android 13+)
  Future<bool> requestPermissions() async {
    try {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        
        if (kDebugMode) {
          print('📱 Notification permission granted: $granted');
        }
        
        return granted ?? false;
      }
      
      return true; // Assume granted on older Android versions
    } catch (e) {
      if (kDebugMode) {
        print('💥 Error requesting notification permissions: $e');
      }
      return false;
    }
  }
}

/// Simple Color class for notification colors
class NotificationColor {
  final int a, r, g, b;
  
  const NotificationColor(int value) : 
    a = (value >> 24) & 0xFF,
    r = (value >> 16) & 0xFF,
    g = (value >> 8) & 0xFF,
    b = value & 0xFF;

  int get value => (a << 24) | (r << 16) | (g << 8) | b;
}