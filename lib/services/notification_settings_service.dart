import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing notification settings
class NotificationSettingsService extends ChangeNotifier {
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _backupNotificationsKey = 'backup_notifications';
  static const String _reminderNotificationsKey = 'reminder_notifications';

  bool _notificationsEnabled = true;
  bool _backupNotifications = true;
  bool _reminderNotifications = false;
  bool _isInitialized = false;

  bool get notificationsEnabled => _notificationsEnabled;
  bool get backupNotifications => _backupNotifications;
  bool get reminderNotifications => _reminderNotifications;
  bool get isInitialized => _isInitialized;

  /// Initialize notification settings from saved preferences
  Future<void> initialize() async {
    if (_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    _notificationsEnabled = prefs.getBool(_notificationsEnabledKey) ?? true;
    _backupNotifications = prefs.getBool(_backupNotificationsKey) ?? true;
    _reminderNotifications = prefs.getBool(_reminderNotificationsKey) ?? false;

    _isInitialized = true;
    notifyListeners();
  }

  /// Toggle master notifications
  Future<void> toggleNotifications() async {
    _notificationsEnabled = !_notificationsEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, _notificationsEnabled);
    notifyListeners();
  }

  /// Toggle backup notifications
  Future<void> toggleBackupNotifications() async {
    _backupNotifications = !_backupNotifications;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_backupNotificationsKey, _backupNotifications);
    notifyListeners();
  }

  /// Toggle reminder notifications
  Future<void> toggleReminderNotifications() async {
    _reminderNotifications = !_reminderNotifications;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reminderNotificationsKey, _reminderNotifications);
    notifyListeners();
  }
}
