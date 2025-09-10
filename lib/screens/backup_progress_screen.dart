import 'package:flutter/material.dart';
import '../models/backup_models.dart';
import '../services/drive/drive_backup_service.dart';

class BackupProgressScreen extends StatefulWidget {
  const BackupProgressScreen({super.key});

  @override
  State<BackupProgressScreen> createState() => _BackupProgressScreenState();
}

class _BackupProgressScreenState extends State<BackupProgressScreen> 
    with TickerProviderStateMixin {
  final DriveBackupService _backupService = DriveBackupService();
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.repeat(reverse: true);
    _checkAndStartBackup();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkAndStartBackup() async {
    // Check if there's an incomplete session that can be resumed
    final canResume = await _canResumeBackup();
    
    if (canResume && mounted) {
      _showResumeDialog();
    } else {
      _startBackup();
    }
  }

  Future<bool> _canResumeBackup() async {
    try {
      // Check if DriveBackupService has findIncompleteSession capability
      // For now, we'll always start fresh since the method is private
      return false;
    } catch (e) {
      return false;
    }
  }

  void _showResumeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resume Backup'),
        content: const Text('An incomplete backup was found. Would you like to resume it or start a new backup?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startFreshBackup();
            },
            child: const Text('Start Fresh'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resumeBackup();
            },
            child: const Text('Resume'),
          ),
        ],
      ),
    );
  }

  Future<void> _startFreshBackup() async {
    // Clean up any incomplete sessions first
    await _backupService.cleanupIncompleteSession();
    await _startBackup();
  }

  Future<void> _resumeBackup() async {
    final success = await _backupService.resumeBackup();
    
    if (mounted) {
      if (success) {
        _showCompletionDialog(true);
      } else {
        _showCompletionDialog(false);
      }
    }
  }

  Future<void> _startBackup() async {
    final success = await _backupService.startBackup();
    
    if (mounted) {
      if (success) {
        _showCompletionDialog(true);
      } else {
        _showCompletionDialog(false);
      }
    }
  }

  void _showCompletionDialog(bool success) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: Icon(
          success ? Icons.check_circle : Icons.error,
          color: success ? Colors.green : Colors.red,
          size: 64,
        ),
        title: Text(success ? 'Backup Completed' : 'Backup Failed'),
        content: Text(
          success 
              ? 'Backup Complete'
              : _backupService.currentProgress.errorMessage ?? 'An unknown error occurred.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Close progress screen
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup Progress'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        automaticallyImplyLeading: false, // Disable back button during backup
      ),
      body: ListenableBuilder(
        listenable: _backupService,
        builder: (context, child) {
          final progress = _backupService.currentProgress;
          
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height - 
                      MediaQuery.of(context).padding.top - 
                      MediaQuery.of(context).padding.bottom - 
                      kToolbarHeight - 32,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                // Progress Circle
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: progress.status == BackupStatus.completed 
                          ? 1.0 
                          : _pulseAnimation.value,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: _getProgressColors(progress.status),
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withValues(alpha: 0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Progress indicator
                            SizedBox(
                              width: 160,
                              height: 160,
                              child: CircularProgressIndicator(
                                value: progress.percentage / 100,
                                strokeWidth: 8,
                                backgroundColor: Colors.white.withValues(alpha: 0.3),
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            // Progress percentage
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${progress.percentage.toInt()}%',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Icon(
                                  _getStatusIcon(progress.status),
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 40),

                // Current Action
                Text(
                  progress.currentAction,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 20),

                // Status Details
                if (progress.status == BackupStatus.uploading) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        Text(
                          progress.formattedSpeed,
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          progress.estimatedTimeRemaining,
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 40),

                // Action Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      if (progress.status == BackupStatus.failed) ...[
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _resumeOrRetryBackup,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                        ),
                      ] else if (progress.status != BackupStatus.completed && 
                                progress.status != BackupStatus.cancelled) ...[
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _cancelBackup(),
                            icon: const Icon(Icons.cancel),
                            label: const Text('Cancel'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colorScheme.error,
                              side: BorderSide(color: colorScheme.error),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Status Messages
                if (progress.errorMessage != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error,
                            color: colorScheme.onErrorContainer,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              progress.errorMessage!,
                              style: TextStyle(
                                color: colorScheme.onErrorContainer,
                              ),
                              overflow: TextOverflow.visible,
                              softWrap: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<Color> _getProgressColors(BackupStatus status) {
    switch (status) {
      case BackupStatus.completed:
        return [Colors.green.shade400, Colors.green.shade600];
      case BackupStatus.failed:
        return [Colors.red.shade400, Colors.red.shade600];
      case BackupStatus.cancelled:
        return [Colors.orange.shade400, Colors.orange.shade600];
      default:
        return [Colors.blue.shade400, Colors.blue.shade600];
    }
  }

  IconData _getStatusIcon(BackupStatus status) {
    switch (status) {
      case BackupStatus.preparing:
        return Icons.settings;
      case BackupStatus.compressing:
        return Icons.compress;
      case BackupStatus.uploading:
        return Icons.cloud_upload;
      case BackupStatus.completed:
        return Icons.check;
      case BackupStatus.failed:
        return Icons.error;
      case BackupStatus.cancelled:
        return Icons.cancel;
      default:
        return Icons.backup;
    }
  }

  void _cancelBackup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Backup'),
        content: const Text('Are you sure you want to cancel the backup? Your data will not be saved to Google Drive.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue Backup'),
          ),
          TextButton(
            onPressed: () {
              _backupService.cancelBackup();
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Close progress screen
            },
            child: Text(
              'Cancel',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _resumeOrRetryBackup() async {
    // Try resume first, fallback to fresh backup
    final resumed = await _backupService.resumeBackup();
    if (!resumed) {
      await _startBackup();
    }
  }
}