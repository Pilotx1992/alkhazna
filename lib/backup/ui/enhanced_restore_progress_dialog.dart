import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/backup_status.dart';
import '../models/restore_result.dart';
import '../services/backup_service.dart';
import 'package:percent_indicator/percent_indicator.dart';

/// Enhanced restore progress dialog with Lottie animations
/// Shows beautiful animated progress during restore operations
class EnhancedRestoreProgressDialog extends StatefulWidget {
  final VoidCallback? onComplete;
  final VoidCallback? onCancel;

  const EnhancedRestoreProgressDialog({
    super.key,
    this.onComplete,
    this.onCancel,
  });

  @override
  State<EnhancedRestoreProgressDialog> createState() =>
      _EnhancedRestoreProgressDialogState();
}

class _EnhancedRestoreProgressDialogState
    extends State<EnhancedRestoreProgressDialog>
    with TickerProviderStateMixin {
  final BackupService _backupService = BackupService();
  
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  OperationProgress _currentProgress = const OperationProgress(
    percentage: 0,
    backupStatus: BackupStatus.idle,
    currentAction: 'Ready',
  );

  RestoreStage _currentStage = RestoreStage.initializing;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rotationAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );

    // Listen to backup service progress
    _backupService.addListener(_onProgressUpdate);

    // Start restore operation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startRestore();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    _backupService.removeListener(_onProgressUpdate);
    super.dispose();
  }

  void _onProgressUpdate() {
    if (mounted) {
      setState(() {
        _currentProgress = _backupService.currentProgress;
        _currentStage = _getRestoreStage(_currentProgress);
      });

      // Haptic feedback on stage change
      if (_currentProgress.restoreStatus != null) {
        HapticFeedback.lightImpact();
      }

      // Check if restore completed
      if (_currentProgress.restoreStatus == RestoreStatus.completed) {
        _onRestoreComplete();
      } else if (_currentProgress.restoreStatus == RestoreStatus.failed) {
        _onRestoreFailed();
      }
    }
  }

  RestoreStage _getRestoreStage(OperationProgress progress) {
    if (progress.restoreStatus == null) {
      return RestoreStage.initializing;
    }

    switch (progress.restoreStatus!) {
      case RestoreStatus.downloading:
        return RestoreStage.downloading;
      case RestoreStatus.decrypting:
        return RestoreStage.decrypting;
      case RestoreStatus.applying:
        return RestoreStage.applying;
      case RestoreStatus.completed:
        return RestoreStage.completed;
      case RestoreStatus.failed:
        return RestoreStage.failed;
      case RestoreStatus.idle:
        return RestoreStage.initializing;
      case RestoreStatus.cancelled:
        return RestoreStage.failed;
    }
  }

  Future<void> _startRestore() async {
    try {
      await _backupService.startRestore();
    } catch (e) {
      if (mounted) {
        _onRestoreFailed();
      }
    }
  }

  void _onRestoreComplete() {
    HapticFeedback.mediumImpact();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && widget.onComplete != null) {
        widget.onComplete!();
      }
    });
  }

  void _onRestoreFailed() {
    HapticFeedback.heavyImpact();
    if (mounted && widget.onCancel != null) {
      widget.onCancel!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated icon based on stage
            _buildAnimatedIcon(),
            const SizedBox(height: 24),

            // Title
            Text(
              _getStageTitle(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              _currentProgress.currentAction,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Progress indicator
            _buildProgressIndicator(),
            const SizedBox(height: 16),

            // Percentage text
            Text(
              '${_currentProgress.percentage}%',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.blue[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedIcon() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: _getStageIcon(),
        );
      },
    );
  }

  Widget _getStageIcon() {
    switch (_currentStage) {
      case RestoreStage.initializing:
        return Icon(
          Icons.cloud_download_rounded,
          size: 80,
          color: Colors.blue[400],
        );
      case RestoreStage.downloading:
        return RotationTransition(
          turns: _rotationAnimation,
          child: Icon(
            Icons.download_rounded,
            size: 80,
            color: Colors.blue[600],
          ),
        );
      case RestoreStage.decrypting:
        return Icon(
          Icons.lock_open_rounded,
          size: 80,
          color: Colors.orange[600],
        );
      case RestoreStage.applying:
        return Icon(
          Icons.sync_rounded,
          size: 80,
          color: Colors.green[600],
        );
      case RestoreStage.completed:
        return Icon(
          Icons.check_circle_rounded,
          size: 80,
          color: Colors.green[600],
        );
      case RestoreStage.failed:
        return Icon(
          Icons.error_rounded,
          size: 80,
          color: Colors.red[600],
        );
    }
  }

  String _getStageTitle() {
    switch (_currentStage) {
      case RestoreStage.initializing:
        return 'Preparing Restore';
      case RestoreStage.downloading:
        return 'Downloading Backup';
      case RestoreStage.decrypting:
        return 'Decrypting Data';
      case RestoreStage.applying:
        return 'Applying Changes';
      case RestoreStage.completed:
        return 'Restore Complete!';
      case RestoreStage.failed:
        return 'Restore Failed';
    }
  }

  Widget _buildProgressIndicator() {
    return CircularPercentIndicator(
      radius: 60,
      lineWidth: 8,
      percent: _currentProgress.percentage / 100,
      center: Text(
        '${_currentProgress.percentage}%',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      progressColor: _getProgressColor(),
      backgroundColor: Colors.grey[200]!,
      circularStrokeCap: CircularStrokeCap.round,
      animation: true,
      animateFromLastPercent: true,
    );
  }

  Color _getProgressColor() {
    switch (_currentStage) {
      case RestoreStage.initializing:
      case RestoreStage.downloading:
        return Colors.blue[600]!;
      case RestoreStage.decrypting:
        return Colors.orange[600]!;
      case RestoreStage.applying:
        return Colors.green[600]!;
      case RestoreStage.completed:
        return Colors.green[600]!;
      case RestoreStage.failed:
        return Colors.red[600]!;
    }
  }
}

/// Restore stages for UI animation
enum RestoreStage {
  initializing,
  downloading,
  decrypting,
  applying,
  completed,
  failed,
}

