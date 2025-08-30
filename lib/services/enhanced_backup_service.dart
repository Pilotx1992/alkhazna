import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'cloud_backup_service.dart';

enum BackupStatus {
  idle,
  syncing,
  success,
  error,
  scheduled,
}

class BackupSchedule {
  final String id;
  final Duration interval;
  final bool enabled;
  final DateTime? lastBackup;
  final DateTime? nextBackup;

  BackupSchedule({
    required this.id,
    required this.interval,
    required this.enabled,
    this.lastBackup,
    this.nextBackup,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'intervalMinutes': interval.inMinutes,
      'enabled': enabled,
      'lastBackup': lastBackup?.toIso8601String(),
      'nextBackup': nextBackup?.toIso8601String(),
    };
  }

  factory BackupSchedule.fromMap(Map<String, dynamic> map) {
    return BackupSchedule(
      id: map['id'] ?? '',
      interval: Duration(minutes: map['intervalMinutes'] ?? 60),
      enabled: map['enabled'] ?? false,
      lastBackup: map['lastBackup'] != null 
          ? DateTime.parse(map['lastBackup']) 
          : null,
      nextBackup: map['nextBackup'] != null 
          ? DateTime.parse(map['nextBackup']) 
          : null,
    );
  }
}

class BackupVersion {
  final String id;
  final DateTime createdAt;
  final String type; // 'manual', 'scheduled', 'auto'
  final int size;
  final Map<String, dynamic> metadata;

  BackupVersion({
    required this.id,
    required this.createdAt,
    required this.type,
    required this.size,
    this.metadata = const {},
  });
}

class EnhancedBackupService extends ChangeNotifier {
  static final EnhancedBackupService _instance = EnhancedBackupService._internal();
  factory EnhancedBackupService() => _instance;
  EnhancedBackupService._internal();

  final CloudBackupService _cloudBackupService = CloudBackupService();
  
  BackupStatus _status = BackupStatus.idle;
  String _statusMessage = '';
  Timer? _scheduledBackupTimer;
  BackupSchedule? _currentSchedule;
  List<BackupVersion> _versions = [];
  double _syncProgress = 0.0;

  // Getters
  BackupStatus get status => _status;
  String get statusMessage => _statusMessage;
  BackupSchedule? get currentSchedule => _currentSchedule;
  List<BackupVersion> get versions => _versions;
  double get syncProgress => _syncProgress;
  bool get hasAutoBackup => _currentSchedule?.enabled ?? false;

  // Status colors
  Color get statusColor {
    switch (_status) {
      case BackupStatus.idle:
        return Colors.grey;
      case BackupStatus.syncing:
        return Colors.blue;
      case BackupStatus.success:
        return Colors.green;
      case BackupStatus.error:
        return Colors.red;
      case BackupStatus.scheduled:
        return Colors.orange;
    }
  }

  // Status icon
  IconData get statusIcon {
    switch (_status) {
      case BackupStatus.idle:
        return Icons.cloud_off;
      case BackupStatus.syncing:
        return Icons.cloud_sync;
      case BackupStatus.success:
        return Icons.cloud_done;
      case BackupStatus.error:
        return Icons.cloud_off;
      case BackupStatus.scheduled:
        return Icons.schedule;
    }
  }

  Future<void> initialize() async {
    await _loadSchedule();
    await _loadVersionHistory();
    _startScheduledBackupTimer();
  }

  Future<void> _loadSchedule() async {
    final prefs = await SharedPreferences.getInstance();
    final scheduleData = prefs.getString('backup_schedule');
    if (scheduleData != null) {
      // Parse schedule from JSON if you want to persist it
      // For now, we'll use a simple enabled flag
      final enabled = prefs.getBool('auto_backup_enabled') ?? false;
      final intervalHours = prefs.getInt('backup_interval_hours') ?? 24;
      final lastBackup = prefs.getString('last_auto_backup');
      
      _currentSchedule = BackupSchedule(
        id: 'auto_backup',
        interval: Duration(hours: intervalHours),
        enabled: enabled,
        lastBackup: lastBackup != null ? DateTime.parse(lastBackup) : null,
        nextBackup: lastBackup != null 
            ? DateTime.parse(lastBackup).add(Duration(hours: intervalHours))
            : DateTime.now().add(Duration(hours: intervalHours)),
      );
    }
    notifyListeners();
  }

  Future<void> _loadVersionHistory() async {
    // Load backup versions from cloud
    // This would integrate with your existing CloudBackupService
    _versions = [];
    notifyListeners();
  }

  Future<void> enableAutoBackup({
    Duration interval = const Duration(hours: 24),
    bool enabled = true,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    _currentSchedule = BackupSchedule(
      id: 'auto_backup',
      interval: interval,
      enabled: enabled,
      lastBackup: _currentSchedule?.lastBackup,
      nextBackup: enabled 
          ? DateTime.now().add(interval)
          : null,
    );

    await prefs.setBool('auto_backup_enabled', enabled);
    await prefs.setInt('backup_interval_hours', interval.inHours);
    
    if (enabled) {
      _startScheduledBackupTimer();
      _updateStatus(BackupStatus.scheduled, 'Auto backup enabled');
    } else {
      _scheduledBackupTimer?.cancel();
      _updateStatus(BackupStatus.idle, 'Auto backup disabled');
    }
    
    notifyListeners();
  }

  void _startScheduledBackupTimer() {
    _scheduledBackupTimer?.cancel();
    
    if (_currentSchedule?.enabled != true) return;
    
    final now = DateTime.now();
    final nextBackup = _currentSchedule!.nextBackup ?? now.add(_currentSchedule!.interval);
    final timeUntilNextBackup = nextBackup.difference(now);
    
    if (timeUntilNextBackup.inSeconds > 0) {
      _scheduledBackupTimer = Timer(timeUntilNextBackup, () {
        _performScheduledBackup();
      });
    } else {
      // Next backup is overdue, schedule it in 1 minute
      _scheduledBackupTimer = Timer(const Duration(minutes: 1), () {
        _performScheduledBackup();
      });
    }
  }

  Future<void> _performScheduledBackup() async {
    if (_status == BackupStatus.syncing) return; // Already backing up
    
    _updateStatus(BackupStatus.syncing, 'Performing scheduled backup...');
    
    try {
      final context = NavigationService.navigatorKey.currentContext;
      if (context == null) {
        _updateStatus(BackupStatus.error, 'Unable to access app context for backup');
        return;
      }
      
      final success = await _cloudBackupService.createCloudBackup(
        context,
        onProgress: (progress) {
          _updateStatus(BackupStatus.syncing, progress);
        },
      );
      
      if (success) {
        final prefs = await SharedPreferences.getInstance();
        final now = DateTime.now();
        await prefs.setString('last_auto_backup', now.toIso8601String());
        
        _currentSchedule = BackupSchedule(
          id: _currentSchedule!.id,
          interval: _currentSchedule!.interval,
          enabled: _currentSchedule!.enabled,
          lastBackup: now,
          nextBackup: now.add(_currentSchedule!.interval),
        );
        
        _updateStatus(BackupStatus.success, 'Scheduled backup completed');
        
        // Schedule next backup
        _startScheduledBackupTimer();
      } else {
        _updateStatus(BackupStatus.error, 'Scheduled backup failed');
      }
    } catch (e) {
      _updateStatus(BackupStatus.error, 'Scheduled backup error: $e');
    }
    
    notifyListeners();
  }

  Future<bool> createManualBackup(BuildContext context) async {
    _updateStatus(BackupStatus.syncing, 'Creating manual backup...');
    
    try {
      final success = await _cloudBackupService.createCloudBackup(
        context,
        onProgress: (progress) {
          _updateStatus(BackupStatus.syncing, progress);
          // Extract progress percentage if available
          final progressMatch = RegExp(r'(\d+)%').firstMatch(progress);
          if (progressMatch != null) {
            _syncProgress = double.parse(progressMatch.group(1)!) / 100.0;
          }
          notifyListeners();
        },
      );
      
      if (success) {
        _updateStatus(BackupStatus.success, 'Manual backup completed successfully');
        await _loadVersionHistory(); // Refresh versions
      } else {
        _updateStatus(BackupStatus.error, 'Manual backup failed');
      }
      
      return success;
    } catch (e) {
      String errorMessage;
      if (e.toString().contains('object-not-found')) {
        errorMessage = 'Storage not initialized - please check Firebase setup';
      } else if (e.toString().contains('permission-denied')) {
        errorMessage = 'Permission denied - please check Firebase rules';
      } else {
        errorMessage = 'Backup error: ${e.toString()}';
      }
      
      _updateStatus(BackupStatus.error, errorMessage);
      print('Manual backup error: $e'); // For debugging
      return false;
    } finally {
      _syncProgress = 0.0;
      notifyListeners();
    }
  }

  void _updateStatus(BackupStatus status, String message) {
    _status = status;
    _statusMessage = message;
    notifyListeners();
  }

  String getTimeUntilNextBackup() {
    if (_currentSchedule?.nextBackup == null || !hasAutoBackup) {
      return 'No scheduled backup';
    }
    
    final now = DateTime.now();
    final nextBackup = _currentSchedule!.nextBackup!;
    final difference = nextBackup.difference(now);
    
    if (difference.isNegative) {
      return 'Backup overdue';
    }
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ${difference.inHours % 24}h';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ${difference.inMinutes % 60}m';
    } else {
      return '${difference.inMinutes}m';
    }
  }

  String getLastBackupTime() {
    if (_currentSchedule?.lastBackup == null) {
      return 'Never';
    }
    
    final now = DateTime.now();
    final lastBackup = _currentSchedule!.lastBackup!;
    final difference = now.difference(lastBackup);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    }
  }

  @override
  void dispose() {
    _scheduledBackupTimer?.cancel();
    super.dispose();
  }
}

// Navigation service for accessing context from background tasks
class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
}