import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/backup_status.dart';
import '../services/backup_service.dart';
import 'notification_helper.dart';
import '../../models/income_entry.dart';
import '../../models/outcome_entry.dart';

/// Auto-backup scheduler with OEM workarounds for Chinese devices
class BackupScheduler {
  static const String _autoBackupTaskId = 'auto_backup_task';
  static const String _lastBackupKey = 'last_backup_time';
  static const String _autoBackupEnabledKey = 'auto_backup_enabled';
  static const String _autoBackupFrequencyKey = 'auto_backup_frequency';
  static const String _networkPreferenceKey = 'network_preference';

  /// Initialize WorkManager and setup auto-backup
  static Future<void> initialize() async {
    try {
      await Workmanager().initialize(
        callbackDispatcher,
      );

      if (kDebugMode) {
        print('✅ WorkManager initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('💥 Failed to initialize WorkManager: $e');
      }
    }
  }

  /// Test auto-backup manually (for debugging)
  static Future<bool> testAutoBackup() async {
    try {
      if (kDebugMode) {
        print('🧪 Testing auto-backup manually...');
      }

      // Perform backup immediately
      final success = await _performBackgroundBackup({
        'frequency': 'test',
        'scheduled_at': DateTime.now().toIso8601String(),
        'is_oneplus': false,
      });

      if (kDebugMode) {
        print('🧪 Auto-backup test result: ${success ? 'Success' : 'Failed'}');
      }

      return success;
    } catch (e) {
      if (kDebugMode) {
        print('💥 Auto-backup test error: $e');
      }
      return false;
    }
  }

  /// Schedule auto-backup with OEM workarounds
  static Future<void> scheduleAutoBackup(BackupFrequency frequency) async {
    try {
      if (frequency == BackupFrequency.off) {
        await cancelAutoBackup();
        return;
      }

      // Cancel existing tasks
      await Workmanager().cancelByUniqueName(_autoBackupTaskId);

      // Get OnePlus/OEM optimized constraints
      final constraints = await _getOptimizedConstraints(frequency);
      final isOnePlus = await _isOnePlusDevice();

      // Schedule new task (avoid backoff on idle mode jobs)
      if (constraints.requiresDeviceIdle == true) {
        await Workmanager().registerPeriodicTask(
          _autoBackupTaskId,
          _autoBackupTaskId,
          frequency: _getWorkManagerFrequency(frequency),
          constraints: constraints,
          inputData: {
            'frequency': frequency.name,
            'scheduled_at': DateTime.now().toIso8601String(),
            'is_oneplus': isOnePlus,
          },
        );
      } else {
        await Workmanager().registerPeriodicTask(
          _autoBackupTaskId,
          _autoBackupTaskId,
          frequency: _getWorkManagerFrequency(frequency),
          constraints: constraints,
          backoffPolicy: BackoffPolicy.exponential,
          backoffPolicyDelay: const Duration(minutes: 15),
          inputData: {
            'frequency': frequency.name,
            'scheduled_at': DateTime.now().toIso8601String(),
            'is_oneplus': isOnePlus,
          },
        );
      }


      // Save settings
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_autoBackupEnabledKey, true);
      await prefs.setString(_autoBackupFrequencyKey, frequency.name);

      if (kDebugMode) {
        print('✅ Auto-backup scheduled: ${frequency.displayName}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('💥 Failed to schedule auto-backup: $e');
      }
    }
  }

  /// Cancel auto-backup
  static Future<void> cancelAutoBackup() async {
    try {
      await Workmanager().cancelByUniqueName(_autoBackupTaskId);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_autoBackupEnabledKey, false);

      if (kDebugMode) {
        print('🗑️ Auto-backup cancelled');
      }
    } catch (e) {
      if (kDebugMode) {
        print('💥 Failed to cancel auto-backup: $e');
      }
    }
  }

  /// Check if auto-backup is enabled
  static Future<bool> isAutoBackupEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_autoBackupEnabledKey) ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('💥 Error checking auto-backup status: $e');
      }
      return false;
    }
  }

  /// Get current backup frequency
  static Future<BackupFrequency> getBackupFrequency() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final frequencyString = prefs.getString(_autoBackupFrequencyKey) ?? 'off';
      
      return BackupFrequency.values.firstWhere(
        (freq) => freq.name == frequencyString,
        orElse: () => BackupFrequency.off,
      );
    } catch (e) {
      if (kDebugMode) {
        print('💥 Error getting backup frequency: $e');
      }
      return BackupFrequency.off;
    }
  }

  /// Set network preference
  static Future<void> setNetworkPreference(NetworkPreference preference) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_networkPreferenceKey, preference.name);

      if (kDebugMode) {
        print('📶 Network preference set: ${preference.name}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('💥 Error setting network preference: $e');
      }
    }
  }

  /// Get network preference
  static Future<NetworkPreference> getNetworkPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final preferenceString = prefs.getString(_networkPreferenceKey) ?? 'wifiOnly';
      
      return NetworkPreference.values.firstWhere(
        (pref) => pref.name == preferenceString,
        orElse: () => NetworkPreference.wifiOnly,
      );
    } catch (e) {
      if (kDebugMode) {
        print('💥 Error getting network preference: $e');
      }
      return NetworkPreference.wifiOnly;
    }
  }

  /// Update last backup time
  static Future<void> updateLastBackupTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastBackupKey, DateTime.now().toUtc().millisecondsSinceEpoch);
    } catch (e) {
      if (kDebugMode) {
        print('💥 Error updating last backup time: $e');
      }
    }
  }

  /// Explicitly set last backup time (stored as UTC milliseconds)
  static Future<void> setLastBackupTime(DateTime time) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastBackupKey, time.toUtc().millisecondsSinceEpoch);
    } catch (e) {
      if (kDebugMode) {
        print('Error setting last backup time: $e');
      }
    }
  }

  /// Get last backup time
  static Future<DateTime> getLastBackupTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_lastBackupKey);
      
      if (timestamp != null) {
        int ms = timestamp;
        // Handle legacy seconds-based values by converting to milliseconds
        if (ms < 1000000000000) {
          ms = ms * 1000;
        }
        // Interpret stored value as UTC and convert to local time for display
        return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toLocal();
      }
    } catch (e) {
      if (kDebugMode) {
        print('💥 Error getting last backup time: $e');
      }
    }
    
    // Return epoch if no backup time found
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  /// Check if device requires special handling (Chinese OEMs)
  static Future<bool> requiresSpecialHandling() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final manufacturer = androidInfo.manufacturer.toLowerCase();
      
      final aggressiveOEMs = [
        'xiaomi', 'oppo', 'vivo', 'huawei', 'realme', 
        'oneplus', 'honor', 'meizu', 'lenovo'
      ];
      
      return aggressiveOEMs.contains(manufacturer);
    } catch (e) {
      if (kDebugMode) {
        print('💥 Error checking device manufacturer: $e');
      }
      return false;
    }
  }


  /// Get WorkManager frequency from backup frequency
  static Duration _getWorkManagerFrequency(BackupFrequency frequency) {
    switch (frequency) {
      case BackupFrequency.daily:
        return const Duration(days: 1);
      case BackupFrequency.weekly:
        return const Duration(days: 7);
      case BackupFrequency.monthly:
        return const Duration(days: 30);
      default:
        return const Duration(days: 999); // Effectively disabled
    }
  }

  /// Get network constraint based on user preference
  static Future<NetworkType> _getNetworkConstraint() async {
    final preference = await getNetworkPreference();
    switch (preference) {
      case NetworkPreference.wifiOnly:
        return NetworkType.unmetered;
      case NetworkPreference.wifiAndMobile:
        return NetworkType.connected;
    }
  }

  /// Get OnePlus/OEM optimized constraints
  static Future<Constraints> _getOptimizedConstraints(BackupFrequency frequency) async {
    final isOnePlus = await _isOnePlusDevice();

    return Constraints(
      networkType: await _getNetworkConstraint(),
      requiresBatteryNotLow: !isOnePlus, // OnePlus: don't wait for high battery
      requiresCharging: false,
      requiresDeviceIdle: !isOnePlus, // OnePlus: don't wait for idle
    );
  }

  /// Check if device is OnePlus
  static Future<bool> _isOnePlusDevice() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.manufacturer.toLowerCase().contains('oneplus');
    } catch (e) {
      return false;
    }
  }

  /// Trigger manual backup (for testing or user action)
  static Future<void> triggerManualBackup() async {
    try {
      if (kDebugMode) {
        print('🚀 Triggering manual backup...');
      }

      final backupService = BackupService();
      final success = await backupService.startBackup();

      if (success) {
        final notificationHelper = NotificationHelper();
        await notificationHelper.showBackupComplete(
          success: true,
          message: 'Manual backup completed successfully',
        );
      } else {
        final notificationHelper = NotificationHelper();
        await notificationHelper.showBackupComplete(
          success: false,
          message: 'Manual backup failed',
          details: 'Please check your internet connection and try again',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('💥 Manual backup failed: $e');
      }
    }
  }

}

/// Background task callback dispatcher
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (kDebugMode) {
        print('🔄 Background task started: $task');
        print('   Input data: $inputData');
      }

      // Initialize Hive for background task
      try {
        await _initializeBackgroundServices();
      } catch (e) {
        if (kDebugMode) {
          print('💥 Failed to initialize background services: $e');
        }
        return false;
      }

      switch (task) {
        case BackupScheduler._autoBackupTaskId:
          return await _performBackgroundBackup(inputData);
        default:
          return Future.value(true);
      }
    } catch (e) {
      if (kDebugMode) {
        print('💥 Background task failed: $e');
      }
      return Future.value(false);
    }
  });
}

/// Initialize services for background task
Future<void> _initializeBackgroundServices() async {
  try {
    // Initialize Hive
    await Hive.initFlutter();

    // Register adapters if not already registered
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(IncomeEntryAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(OutcomeEntryAdapter());
    }

    if (kDebugMode) {
      print('✅ Background services initialized');
    }
  } catch (e) {
    if (kDebugMode) {
      print('⚠️ Background services init warning: $e');
    }
    // Continue anyway - services might already be initialized
  }
}

/// Perform background backup
Future<bool> _performBackgroundBackup(Map<String, dynamic>? inputData) async {
  try {
    if (kDebugMode) {
      print('📱 Starting background backup...');
      final isOnePlus = inputData?['is_oneplus'] ?? false;
      print('📱 OnePlus device: $isOnePlus');
    }

    // Initialize services
    if (kDebugMode) print('📱 Initializing services...');
    final backupService = BackupService();
    final notificationHelper = NotificationHelper();
    
    // Initialize notifications
    if (kDebugMode) print('📱 Initializing notifications...');
    await notificationHelper.initialize();

    // Listen to backup progress and update notifications
    backupService.addListener(() {
      final progress = backupService.currentProgress;
      
      if (progress.backupStatus != null) {
        if (kDebugMode) {
          print('📱 Backup progress: ${progress.percentage}% - ${progress.currentAction}');
        }
        notificationHelper.showBackupProgress(
          stage: progress.backupStatus!.name,
          percentage: progress.percentage,
          message: progress.currentAction,
        );
      }
    });

    // Start backup
    if (kDebugMode) print('📱 Starting backup process...');
    final success = await backupService.startBackup();

    if (success) {
      await notificationHelper.showBackupComplete(
        success: true,
        message: 'Auto backup completed successfully',
      );
      
      if (kDebugMode) {
        print('✅ Background backup completed successfully');
      }
    } else {
      await notificationHelper.showBackupComplete(
        success: false,
        message: 'Auto backup failed',
        details: 'Will retry later',
      );
      
      if (kDebugMode) {
        print('❌ Background backup failed');
      }
    }

    // Clear progress notifications
    await notificationHelper.clearProgressNotifications();
    
    return success;
  } catch (e) {
    if (kDebugMode) {
      print('💥 Background backup error: $e');
    }
    
    try {
      final notificationHelper = NotificationHelper();
      await notificationHelper.showBackupComplete(
        success: false,
        message: 'Auto backup error',
        details: e.toString(),
      );
    } catch (notificationError) {
      if (kDebugMode) {
        print('💥 Failed to show error notification: $notificationError');
      }
    }
    
    return false;
  }
}
