import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../models/backup_status.dart';
import '../models/restore_result.dart';
import '../services/backup_service.dart';
import '../utils/notification_helper.dart';

/// WhatsApp-style backup progress sheet
class BackupProgressSheet extends StatefulWidget {
  final bool isRestore;

  const BackupProgressSheet({
    super.key,
    this.isRestore = false,
  });

  @override
  State<BackupProgressSheet> createState() => _BackupProgressSheetState();
}

class _BackupProgressSheetState extends State<BackupProgressSheet> {
  final BackupService _backupService = BackupService();
  final NotificationHelper _notificationHelper = NotificationHelper();
  
  late final bool _isRestore;
  bool _isOperationInProgress = false;
  OperationProgress _currentProgress = const OperationProgress(
    percentage: 0,
    backupStatus: BackupStatus.idle,
    currentAction: 'Ready',
  );

  @override
  void initState() {
    super.initState();
    _isRestore = widget.isRestore;
    
    // Listen to backup service progress
    _backupService.addListener(_onProgressUpdate);
    
    // Start the operation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isRestore) {
        _startRestore();
      } else {
        _startBackup();
      }
    });
  }

  @override
  void dispose() {
    _backupService.removeListener(_onProgressUpdate);
    super.dispose();
  }

  void _onProgressUpdate() {
    if (mounted) {
      setState(() {
        _currentProgress = _backupService.currentProgress;
      });

      // Update notifications
      if (_isRestore && _currentProgress.restoreStatus != null) {
        _notificationHelper.showRestoreProgress(
          stage: _currentProgress.restoreStatus!.name,
          percentage: _currentProgress.percentage,
          message: _currentProgress.currentAction,
        );
      } else if (!_isRestore && _currentProgress.backupStatus != null) {
        _notificationHelper.showBackupProgress(
          stage: _currentProgress.backupStatus!.name,
          percentage: _currentProgress.percentage,
          message: _currentProgress.currentAction,
        );
      }
    }
  }

  Future<void> _startBackup() async {
    setState(() {
      _isOperationInProgress = true;
    });

    try {
      final success = await _backupService.startBackup();
      
      await _notificationHelper.showBackupComplete(
        success: success,
        message: success ? 'Backup completed successfully' : 'Backup failed',
      );

      if (mounted) {
        if (success) {
          _showSuccessAndClose('Backup completed successfully!');
        } else {
          _showErrorDialog('Backup failed. Please try again.');
        }
      }
    } catch (e) {
      await _notificationHelper.showBackupComplete(
        success: false,
        message: 'Backup failed',
        details: e.toString(),
      );

      if (mounted) {
        _showErrorDialog('Backup failed: $e');
      }
    } finally {
      setState(() {
        _isOperationInProgress = false;
      });
    }
  }

  Future<void> _startRestore() async {
    setState(() {
      _isOperationInProgress = true;
    });

    try {
      final result = await _backupService.startRestore();
      
      await _notificationHelper.showRestoreComplete(
        success: result.success,
        message: result.success ? 'Restore completed successfully' : 'Restore failed',
        details: result.success ? result.summary : result.errorMessage,
      );

      if (mounted) {
        if (result.success) {
          _showSuccessAndClose('Restore completed successfully!');
        } else {
          _showErrorDialog(result.errorMessage ?? 'Restore failed. Please try again.');
        }
      }
    } catch (e) {
      await _notificationHelper.showRestoreComplete(
        success: false,
        message: 'Restore failed',
        details: e.toString(),
      );

      if (mounted) {
        _showErrorDialog('Restore failed: $e');
      }
    } finally {
      setState(() {
        _isOperationInProgress = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Text(
                  _isRestore ? 'Restore Progress' : 'Backup Progress',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (_isOperationInProgress && _currentProgress.percentage < 100)
                  TextButton(
                    onPressed: _cancelOperation,
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Progress indicator
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Circular progress
                CircularPercentIndicator(
                  radius: 80,
                  lineWidth: 8,
                  percent: _currentProgress.percentage / 100,
                  center: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentProgress.statusEmoji,
                        style: const TextStyle(fontSize: 32),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_currentProgress.percentage}%',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  progressColor: _getProgressColor(),
                  backgroundColor: Colors.grey[200]!,
                  animation: true,
                  animationDuration: 300,
                ),
                
                const SizedBox(height: 32),
                
                // Status text
                Text(
                  _currentProgress.statusText,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Action text
                Text(
                  _currentProgress.currentAction,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                
                // Error message
                if (_currentProgress.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      border: Border.all(color: Colors.red[200]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red[600],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _currentProgress.errorMessage!,
                            style: TextStyle(
                              color: Colors.red[700],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Bottom actions
          if (_currentProgress.isCompleted || _currentProgress.isFailed || _currentProgress.isCancelled)
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _currentProgress.isCompleted 
                        ? Colors.green[600] 
                        : Colors.grey[600],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _currentProgress.isCompleted ? 'Done' : 'Close',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getProgressColor() {
    if (_currentProgress.isFailed) {
      return Colors.red[600]!;
    } else if (_currentProgress.isCompleted) {
      return Colors.green[600]!;
    } else if (_currentProgress.isCancelled) {
      return Colors.orange[600]!;
    } else {
      return Colors.blue[600]!;
    }
  }

  void _cancelOperation() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel ${_isRestore ? 'Restore' : 'Backup'}'),
        content: Text('Are you sure you want to cancel the ${_isRestore ? 'restore' : 'backup'} operation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _backupService.cancelCurrentOperation();
              if (mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Yes', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showSuccessAndClose(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[600]),
            const SizedBox(width: 8),
            const Text('Success'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close sheet
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red[600]),
            const SizedBox(width: 8),
            const Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close sheet
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show restore progress sheet
  static void showRestore(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (context) => const BackupProgressSheet(isRestore: true),
    );
  }

  /// Show backup progress sheet
  static void showBackup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (context) => const BackupProgressSheet(isRestore: false),
    );
  }
}