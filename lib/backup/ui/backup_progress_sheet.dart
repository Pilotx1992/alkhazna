import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../models/backup_status.dart';
import '../models/restore_result.dart';
import '../services/backup_service.dart';
import '../services/safety_backup_service.dart';
import '../utils/notification_helper.dart';
import '../utils/haptic_feedback_helper.dart';
import 'rollback_dialog.dart';
import 'animated_success_dialog.dart';

/// WhatsApp-style backup progress sheet
class BackupProgressSheet extends StatefulWidget {
  final bool isRestore;
  final VoidCallback? onRestoreComplete;
  final VoidCallback? onBackupComplete;

  const BackupProgressSheet({
    super.key,
    this.isRestore = false,
    this.onRestoreComplete,
    this.onBackupComplete,
  });

  @override
  State<BackupProgressSheet> createState() => _BackupProgressSheetState();
}

class _BackupProgressSheetState extends State<BackupProgressSheet> {
  final BackupService _backupService = BackupService();
  final NotificationHelper _notificationHelper = NotificationHelper();
  
  late final bool _isRestore;
  bool _isOperationInProgress = false;
  bool _hasCalledCallback = false;
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

      // Check if backup just completed or failed and handle accordingly
      if (!_isRestore && !_hasCalledCallback) {
        if (_currentProgress.backupStatus == BackupStatus.completed &&
            _currentProgress.percentage == 100) {
          _hasCalledCallback = true;
          
          // ✨ NEW: Haptic feedback on backup complete
          HapticFeedbackHelper.backupComplete();
          
          // Give a small delay to ensure backup time is saved
          Future.delayed(const Duration(milliseconds: 500), () {
            if (widget.onBackupComplete != null) {
              widget.onBackupComplete!();
            }
            if (mounted) {
              Navigator.pop(context);
              
              // ✨ NEW: Show animated success dialog
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => AnimatedSuccessDialog(
                  title: 'Backup Complete!',
                  message: 'Your data has been backed up successfully.',
                  onClose: () => Navigator.of(context).pop(),
                ),
              );
            }
          });
        } else if (_currentProgress.backupStatus == BackupStatus.failed) {
          _hasCalledCallback = true;
          
          // ✨ NEW: Haptic feedback on error
          HapticFeedbackHelper.error();
          
          if (mounted) {
            // Check if it's a Wi-Fi connection error
            if (_currentProgress.currentAction.contains('Wi-Fi connection required')) {
              _showWifiRequiredDialog();
            } else {
              _showErrorDialog('Backup failed. Please try again.');
            }
          }
        }
      }

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

    // ✨ NEW: Haptic feedback on backup start
    HapticFeedbackHelper.backupStart();

    try {
      // Just start the backup, don't handle completion here
      // Completion is handled through the progress listener
      await _backupService.startBackup();

      if (kDebugMode) {
        print('🐛 DEBUG: Backup operation started');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🐛 DEBUG: Error starting backup: $e');
      }

      // ✨ NEW: Haptic feedback on error
      HapticFeedbackHelper.error();

      await _notificationHelper.showBackupComplete(
        success: false,
        message: 'Failed to start backup',
        details: e.toString(),
      );

      if (mounted) {
        _showErrorDialog('Failed to start backup: $e');
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

    // ✨ NEW: Haptic feedback on restore start
    HapticFeedbackHelper.restoreStart();

    // ✨ NEW: Get safety backup ID before restore
    String? safetyBackupId;
    try {
      safetyBackupId = await SafetyBackupService().createPreRestoreBackup();
    } catch (e) {
      // Continue even if safety backup fails
    }

    try {
      final result = await _backupService.startRestore();
      
      await _notificationHelper.showRestoreComplete(
        success: result.success,
        message: result.success ? 'Restore completed successfully' : 'Restore failed',
        details: result.success ? result.summary : result.errorMessage,
      );

      if (mounted) {
        if (result.success) {
          // ✨ NEW: Haptic feedback on success
          HapticFeedbackHelper.restoreComplete();
          
          // Call the refresh callback to update the UI immediately
          if (widget.onRestoreComplete != null) {
            widget.onRestoreComplete!();
          }
          
          // ✨ NEW: Show animated success dialog
          Navigator.of(context).pop(); // Close progress sheet
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AnimatedSuccessDialog(
              title: 'Restore Complete!',
              message: result.summary,
              onClose: () => Navigator.of(context).pop(),
            ),
          );
        } else {
          // ✨ NEW: Haptic feedback on error
          HapticFeedbackHelper.error();
          
          // ✨ NEW: Show rollback dialog instead of simple error dialog
          await _showRollbackDialog(
            result.errorMessage ?? 'Restore failed. Please try again.',
            safetyBackupId,
          );
        }
      }
    } catch (e) {
      // ✨ NEW: Haptic feedback on error
      HapticFeedbackHelper.error();
      
      await _notificationHelper.showRestoreComplete(
        success: false,
        message: 'Restore failed',
        details: e.toString(),
      );

      if (mounted) {
        // ✨ NEW: Show rollback dialog instead of simple error dialog
        await _showRollbackDialog('Restore failed: $e', safetyBackupId);
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
              if (!mounted) return;
              Navigator.pop(context);
            },
            child: const Text('Yes', style: TextStyle(color: Colors.red)),
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

  /// ✨ NEW: Show rollback dialog when restore fails
  Future<void> _showRollbackDialog(String errorMessage, String? safetyBackupId) async {
    // Close the progress sheet first
    Navigator.of(context).pop();

    // Show rollback dialog
    await RollbackDialog.show(
      context,
      errorMessage: errorMessage,
      safetyBackupId: safetyBackupId,
    );
  }

  void _showWifiRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.orange[700]),
            const SizedBox(width: 8),
            const Text('Wi-Fi Connection Required'),
          ],
        ),
        content: const Text(
          'Your network preference is set to "Wi-Fi only".\n\n'
          'Please connect to Wi-Fi to create a backup, or change your network preference to "Wi-Fi + Mobile" in backup settings.',
          style: TextStyle(fontSize: 15),
        ),
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

}