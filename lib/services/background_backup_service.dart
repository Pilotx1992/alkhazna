import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'cloud_backup_service.dart';

class BackgroundBackupService {
  static final BackgroundBackupService _instance = BackgroundBackupService._internal();
  factory BackgroundBackupService() => _instance;
  BackgroundBackupService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  
  static const int _backupNotificationId = 1001;
  static const int _restoreNotificationId = 1002;
  
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/launcher_icon'),
      iOS: DarwinInitializationSettings(
        requestSoundPermission: true,
        requestBadgePermission: true,
        requestAlertPermission: true,
      ),
    );

    await _notifications.initialize(initializationSettings);
    _isInitialized = true;
  }

  Future<void> createBackgroundBackup(
    Function(String) onProgress,
    Function(bool, String?) onComplete, {
    BuildContext? context,
  }) async {
    await initialize();
    
    await _showBackupStartNotification();
    
    try {
      if (context == null) {
        throw Exception('Context is required for backup operation');
      }
      
      // Use real CloudBackupService for actual backup
      final cloudBackupService = CloudBackupService();
      
      // Progress wrapper that updates both callback and notification
      void progressWrapper(String status) {
        onProgress(status);
        // Extract progress percentage from status if available
        int progress = 50; // default progress
        if (status.contains('Preparing')) {
          progress = 10;
        } else if (status.contains('Encrypting')) {
          progress = 30;
        } else if (status.contains('Uploading')) {
          progress = 60;
        } else if (status.contains('Finalizing')) {
          progress = 90;
        } else if (status.contains('Complete')) {
          progress = 100;
        }
        
        _updateBackupProgressNotification(progress, status);
      }
      
      // Create actual cloud backup
      final success = await cloudBackupService.createCloudBackup(
        context,
        onProgress: progressWrapper,
      );
      
      if (success) {
        await _showBackupCompleteNotification();
        onComplete(true, null);
      } else {
        await _showBackupErrorNotification('Failed to create cloud backup');
        onComplete(false, 'Failed to create cloud backup');
      }
      
    } catch (e) {
      debugPrint('Background backup error: $e');
      await _showBackupErrorNotification(e.toString());
      onComplete(false, e.toString());
    }
  }

  Future<void> restoreBackgroundBackup(
    CloudBackupMetadata backup,
    Function(String) onProgress,
    Function(bool, String?) onComplete, {
    BuildContext? context,
  }) async {
    await initialize();
    
    await _showRestoreStartNotification();
    
    try {
      if (context == null) {
        throw Exception('Context is required for restore operation');
      }
      
      // Use real CloudBackupService for actual restore
      final cloudBackupService = CloudBackupService();
      
      // Progress wrapper that updates both callback and notification
      void progressWrapper(String status) {
        onProgress(status);
        // Extract progress percentage from status if available
        int progress = 50; // default progress
        if (status.contains('Downloading')) {
          progress = 20;
        } else if (status.contains('Decrypting')) {
          progress = 40;
        } else if (status.contains('Extracting')) {
          progress = 60;
        } else if (status.contains('Restoring')) {
          progress = 80;
        } else if (status.contains('Complete')) {
          progress = 100;
        }
        
        _updateRestoreProgressNotification(progress, status);
      }
      
      // Perform actual cloud restore
      final success = await cloudBackupService.restoreFromCloud(
        context,
        backup,
        onProgress: progressWrapper,
      );
      
      if (success) {
        await _showRestoreCompleteNotification();
        onComplete(true, null);
      } else {
        await _showRestoreErrorNotification('Failed to restore cloud backup');
        onComplete(false, 'Failed to restore cloud backup');
      }
      
    } catch (e) {
      debugPrint('Background restore error: $e');
      await _showRestoreErrorNotification(e.toString());
      onComplete(false, e.toString());
    }
  }

  Future<void> deleteBackgroundBackup(
    CloudBackupMetadata backup,
    Function(String) onProgress,
    Function(bool, String?) onComplete, {
    BuildContext? context,
  }) async {
    await initialize();
    
    await _showDeleteStartNotification();
    
    try {
      if (context == null) {
        throw Exception('Context is required for delete operation');
      }
      
      // Use real CloudBackupService for actual delete
      final cloudBackupService = CloudBackupService();
      
      onProgress('Locating backup...');
      await _updateDeleteProgressNotification('Locating backup...');
      
      // Perform actual cloud delete
      final success = await cloudBackupService.deleteCloudBackup(context, backup);
      
      onProgress('Deleting backup data...');
      await _updateDeleteProgressNotification('Deleting backup data...');
      
      if (success) {
        await _showDeleteCompleteNotification();
        onComplete(true, null);
      } else {
        await _showDeleteErrorNotification('Failed to delete cloud backup');
        onComplete(false, 'Failed to delete cloud backup');
      }
      
    } catch (e) {
      debugPrint('Background delete error: $e');
      await _showDeleteErrorNotification(e.toString());
      onComplete(false, e.toString());
    }
  }



  Future<void> _showBackupStartNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'backup_channel',
      'Backup Operations',
      channelDescription: 'Notifications for backup operations',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      showProgress: true,
      maxProgress: 100,
      progress: 0,
    );

    final notificationDetails = NotificationDetails(android: androidDetails);
    
    await _notifications.show(
      _backupNotificationId,
      'Creating Backup',
      'Starting backup process...',
      notificationDetails,
    );
  }

  Future<void> _updateBackupProgressNotification(int progress, String status) async {
    final androidDetails = AndroidNotificationDetails(
      'backup_channel',
      'Backup Operations',
      channelDescription: 'Notifications for backup operations',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      showProgress: true,
      maxProgress: 100,
      progress: progress,
    );

    final notificationDetails = NotificationDetails(android: androidDetails);
    
    await _notifications.show(
      _backupNotificationId,
      'Creating Backup',
      status,
      notificationDetails,
    );
  }

  Future<void> _showBackupCompleteNotification() async {
    await _notifications.cancel(_backupNotificationId);
    
    const androidDetails = AndroidNotificationDetails(
      'backup_channel',
      'Backup Operations',
      channelDescription: 'Notifications for backup operations',
      importance: Importance.high,
      priority: Priority.high,
    );

    final notificationDetails = NotificationDetails(android: androidDetails);
    
    await _notifications.show(
      _backupNotificationId + 100,
      'Backup Complete',
      'Your data has been backed up successfully!',
      notificationDetails,
    );
  }

  Future<void> _showBackupErrorNotification(String error) async {
    await _notifications.cancel(_backupNotificationId);
    
    const androidDetails = AndroidNotificationDetails(
      'backup_channel',
      'Backup Operations',
      channelDescription: 'Notifications for backup operations',
      importance: Importance.high,
      priority: Priority.high,
    );

    final notificationDetails = NotificationDetails(android: androidDetails);
    
    await _notifications.show(
      _backupNotificationId + 200,
      'Backup Failed',
      'Error: $error',
      notificationDetails,
    );
  }

  Future<void> _showRestoreStartNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'restore_channel',
      'Restore Operations',
      channelDescription: 'Notifications for restore operations',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      showProgress: true,
      maxProgress: 100,
      progress: 0,
    );

    final notificationDetails = NotificationDetails(android: androidDetails);
    
    await _notifications.show(
      _restoreNotificationId,
      'Restoring Backup',
      'Starting restore process...',
      notificationDetails,
    );
  }

  Future<void> _updateRestoreProgressNotification(int progress, String status) async {
    final androidDetails = AndroidNotificationDetails(
      'restore_channel',
      'Restore Operations',
      channelDescription: 'Notifications for restore operations',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      showProgress: true,
      maxProgress: 100,
      progress: progress,
    );

    final notificationDetails = NotificationDetails(android: androidDetails);
    
    await _notifications.show(
      _restoreNotificationId,
      'Restoring Backup',
      status,
      notificationDetails,
    );
  }

  Future<void> _showRestoreCompleteNotification() async {
    await _notifications.cancel(_restoreNotificationId);
    
    const androidDetails = AndroidNotificationDetails(
      'restore_channel',
      'Restore Operations',
      channelDescription: 'Notifications for restore operations',
      importance: Importance.high,
      priority: Priority.high,
    );

    final notificationDetails = NotificationDetails(android: androidDetails);
    
    await _notifications.show(
      _restoreNotificationId + 100,
      'Restore Complete',
      'Your data has been restored successfully!',
      notificationDetails,
    );
  }

  Future<void> _showRestoreErrorNotification(String error) async {
    await _notifications.cancel(_restoreNotificationId);
    
    const androidDetails = AndroidNotificationDetails(
      'restore_channel',
      'Restore Operations',
      channelDescription: 'Notifications for restore operations',
      importance: Importance.high,
      priority: Priority.high,
    );

    final notificationDetails = NotificationDetails(android: androidDetails);
    
    await _notifications.show(
      _restoreNotificationId + 200,
      'Restore Failed',
      'Error: $error',
      notificationDetails,
    );
  }

  // Delete notification methods
  static const int _deleteNotificationId = 1003;

  Future<void> _showDeleteStartNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'delete_channel',
      'Delete Operations',
      channelDescription: 'Notifications for delete operations',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
    );

    final notificationDetails = NotificationDetails(android: androidDetails);
    
    await _notifications.show(
      _deleteNotificationId,
      'Deleting Backup',
      'Starting delete process...',
      notificationDetails,
    );
  }

  Future<void> _updateDeleteProgressNotification(String status) async {
    const androidDetails = AndroidNotificationDetails(
      'delete_channel',
      'Delete Operations',
      channelDescription: 'Notifications for delete operations',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
    );

    final notificationDetails = NotificationDetails(android: androidDetails);
    
    await _notifications.show(
      _deleteNotificationId,
      'Deleting Backup',
      status,
      notificationDetails,
    );
  }

  Future<void> _showDeleteCompleteNotification() async {
    await _notifications.cancel(_deleteNotificationId);
    
    const androidDetails = AndroidNotificationDetails(
      'delete_channel',
      'Delete Operations',
      channelDescription: 'Notifications for delete operations',
      importance: Importance.high,
      priority: Priority.high,
    );

    final notificationDetails = NotificationDetails(android: androidDetails);
    
    await _notifications.show(
      _deleteNotificationId + 100,
      'Delete Complete',
      'Your backup has been deleted successfully!',
      notificationDetails,
    );
  }

  Future<void> _showDeleteErrorNotification(String error) async {
    await _notifications.cancel(_deleteNotificationId);
    
    const androidDetails = AndroidNotificationDetails(
      'delete_channel',
      'Delete Operations',
      channelDescription: 'Notifications for delete operations',
      importance: Importance.high,
      priority: Priority.high,
    );

    final notificationDetails = NotificationDetails(android: androidDetails);
    
    await _notifications.show(
      _deleteNotificationId + 200,
      'Delete Failed',
      'Error: $error',
      notificationDetails,
    );
  }
}

