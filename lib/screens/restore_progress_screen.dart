import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/backup_models.dart';
import '../services/drive/drive_restore_service.dart';

class RestoreProgressScreen extends StatefulWidget {
  final String manifestFileId;
  final bool replaceExisting;
  
  const RestoreProgressScreen({
    super.key,
    required this.manifestFileId,
    this.replaceExisting = true,
  });

  @override
  State<RestoreProgressScreen> createState() => _RestoreProgressScreenState();
}

class _RestoreProgressScreenState extends State<RestoreProgressScreen>
    with TickerProviderStateMixin {
  final DriveRestoreService _restoreService = DriveRestoreService();
  late AnimationController _animationController;
  late AnimationController _stepAnimationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _stepAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _stepAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _stepAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _stepAnimationController,
      curve: Curves.elasticOut,
    ));

    _animationController.repeat(reverse: true);
    _checkAndStartRestore();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _stepAnimationController.dispose();
    super.dispose();
  }

  Future<void> _checkAndStartRestore() async {
    // Check if there's an incomplete session that can be resumed
    final canResume = await _canResumeRestore();
    
    if (canResume && mounted) {
      _showResumeDialog();
    } else {
      _startRestore();
    }
  }

  Future<bool> _canResumeRestore() async {
    try {
      // Check if there are cached chunks that can be resumed
      final downloadProgress = _restoreService.getDownloadProgress();
      return (downloadProgress['cached_chunks'] as int? ?? 0) > 0;
    } catch (e) {
      return false;
    }
  }

  void _showResumeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resume Restore'),
        content: const Text('An incomplete restore was found. Would you like to resume it or start a new restore?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startFreshRestore();
            },
            child: const Text('Start Fresh'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resumeRestore();
            },
            child: const Text('Resume'),
          ),
        ],
      ),
    );
  }

  Future<void> _startFreshRestore() async {
    // Clear cached chunks for fresh start
    _restoreService.clearChunkCache();
    await _startRestore();
  }

  Future<void> _resumeRestore() async {
    final success = await _restoreService.resumeRestore();
    
    if (mounted) {
      if (success) {
        _stepAnimationController.forward();
        _showCompletionDialog(true);
      } else {
        _showCompletionDialog(false);
      }
    }
  }

  Future<void> _startRestore() async {
    final success = await _restoreService.startDriveRestore(
      widget.manifestFileId,
      replaceExisting: widget.replaceExisting,
    );
    
    if (mounted) {
      if (success) {
        _stepAnimationController.forward();
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
        title: Text(success ? 'Restore Completed' : 'Restore Failed'),
        content: Text(
          success 
              ? 'Your data has been successfully restored from the backup.'
              : _restoreService.currentProgress.errorMessage ?? 'An unknown error occurred during restoration.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Close progress screen
              if (success) {
                Navigator.of(context).pop(); // Also close restore options screen
              }
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
        title: const Text('Restore Progress'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: ListenableBuilder(
        listenable: _restoreService,
        builder: (context, child) {
          final progress = _restoreService.currentProgress;
          
          // 🔍 Enhanced Logging for Debugging
          if (kDebugMode) {
            print('📊 RestoreProgress Update:');
            print('   Status: ${progress.status}');
            print('   Percentage: ${progress.percentage.toInt()}%');
            print('   Current Action: ${progress.currentAction}');
            if (progress.status == RestoreStatus.downloading) {
              final downloadInfo = _restoreService.getDownloadProgress();
              print('   Cached Chunks: ${downloadInfo['cached_chunks'] ?? 0}');
              print('   Cache Size: ${downloadInfo['cache_size_bytes'] ?? 0} bytes');
            }
          }
          
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Progress Steps
                _buildProgressSteps(progress, colorScheme),
                
                const SizedBox(height: 40),

                // Main Progress Circle
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: progress.status == RestoreStatus.completed 
                          ? 1.0 
                          : _pulseAnimation.value,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: _getProgressColors(progress.status),
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _getProgressColors(progress.status)[0].withValues(alpha: 0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 140,
                              height: 140,
                              child: CircularProgressIndicator(
                                value: progress.percentage / 100,
                                strokeWidth: 6,
                                backgroundColor: Colors.white.withValues(alpha: 0.3),
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${progress.percentage.toInt()}%',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Icon(
                                  _getStatusIcon(progress.status),
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 30),

                // Current Status
                Text(
                  progress.statusDisplayText,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                // 📊 Enhanced Progress Details
                if (progress.status == RestoreStatus.downloading) ...[
                  Builder(
                    builder: (context) {
                      final downloadInfo = _restoreService.getDownloadProgress();
                      return Column(
                        children: [
                          Text(
                            'Downloaded Chunks: ${downloadInfo['cached_chunks'] ?? 0}',
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            'Cache Size: ${_formatBytes((downloadInfo['cache_size_bytes'] as int?) ?? 0)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ] else if (progress.status == RestoreStatus.decrypting) ...[
                  Text(
                    '🔐 Decrypting and decompressing data...',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ] else if (progress.status == RestoreStatus.applying) ...[
                  Text(
                    '📝 Restoring data to your device...',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],

                const SizedBox(height: 40),

                // Action Buttons
                if (progress.status == RestoreStatus.failed) ...[
                  ElevatedButton.icon(
                    onPressed: () async {
                      // Try to resume first, if not possible, start fresh
                      final canResume = await _canResumeRestore();
                      if (canResume) {
                        await _resumeRestore();
                      } else {
                        await _startFreshRestore();
                      }
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ] else if (progress.status != RestoreStatus.completed && 
                          progress.status != RestoreStatus.cancelled) ...[
                  OutlinedButton.icon(
                    onPressed: () => _cancelRestore(),
                    icon: const Icon(Icons.cancel),
                    label: const Text('Cancel'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.error,
                      side: BorderSide(color: colorScheme.error),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],

                const Spacer(),

                // Warning Message
                if (progress.status == RestoreStatus.downloading ||
                    progress.status == RestoreStatus.decrypting ||
                    progress.status == RestoreStatus.applying) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info, color: Colors.orange, size: 20),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Do not close the app during restoration. Your data is being processed.',
                            style: TextStyle(color: Colors.orange, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Error Message
                if (progress.errorMessage != null) ...[
                  Container(
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
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressSteps(RestoreProgress progress, ColorScheme colorScheme) {
    final steps = [
      {'title': 'Download', 'status': RestoreStatus.downloading, 'icon': Icons.cloud_download},
      {'title': 'Process', 'status': RestoreStatus.decrypting, 'icon': Icons.settings},
      {'title': 'Apply', 'status': RestoreStatus.applying, 'icon': Icons.restore},
      {'title': 'Complete', 'status': RestoreStatus.completed, 'icon': Icons.check},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: steps.map((step) {
          final isActive = _isStepActive(step['status'] as RestoreStatus, progress.status);
          final isCompleted = _isStepCompleted(step['status'] as RestoreStatus, progress.status);
          
          return AnimatedBuilder(
            animation: _stepAnimation,
            builder: (context, child) {
              return Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isCompleted 
                          ? Colors.green 
                          : isActive 
                              ? colorScheme.primary 
                              : colorScheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      step['icon'] as IconData,
                      color: isCompleted || isActive 
                          ? Colors.white 
                          : colorScheme.onSurfaceVariant,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    step['title'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      color: isCompleted 
                          ? Colors.green 
                          : isActive 
                              ? colorScheme.primary 
                              : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              );
            },
          );
        }).toList(),
      ),
    );
  }

  bool _isStepActive(RestoreStatus stepStatus, RestoreStatus currentStatus) {
    return stepStatus == currentStatus;
  }

  bool _isStepCompleted(RestoreStatus stepStatus, RestoreStatus currentStatus) {
    final statusOrder = [
      RestoreStatus.downloading,
      RestoreStatus.decrypting,
      RestoreStatus.applying,
      RestoreStatus.completed,
    ];
    
    final stepIndex = statusOrder.indexOf(stepStatus);
    final currentIndex = statusOrder.indexOf(currentStatus);
    
    return stepIndex < currentIndex || currentStatus == RestoreStatus.completed;
  }

  List<Color> _getProgressColors(RestoreStatus status) {
    switch (status) {
      case RestoreStatus.completed:
        return [Colors.green.shade400, Colors.green.shade600];
      case RestoreStatus.failed:
        return [Colors.red.shade400, Colors.red.shade600];
      case RestoreStatus.cancelled:
        return [Colors.orange.shade400, Colors.orange.shade600];
      default:
        return [Colors.blue.shade400, Colors.blue.shade600];
    }
  }

  IconData _getStatusIcon(RestoreStatus status) {
    switch (status) {
      case RestoreStatus.downloading:
        return Icons.cloud_download;
      case RestoreStatus.decrypting:
        return Icons.lock_open;
      case RestoreStatus.applying:
        return Icons.restore;
      case RestoreStatus.completed:
        return Icons.check;
      case RestoreStatus.failed:
        return Icons.error;
      case RestoreStatus.cancelled:
        return Icons.cancel;
      default:
        return Icons.restore;
    }
  }

  void _cancelRestore() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Restoration'),
        content: const Text('Are you sure you want to cancel the restoration? Your data may be left in an inconsistent state.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue Restore'),
          ),
          TextButton(
            onPressed: () {
              _restoreService.cancelRestore();
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

  /// Format bytes for display (matches BackupProgressScreen style)
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes} B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}