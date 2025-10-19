import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/backup_service.dart';
import '../utils/backup_constants.dart';
import '../../services/connectivity_service.dart';

/// Bottom sheet for one-tap backup functionality
class BackupBottomSheet extends StatefulWidget {
  const BackupBottomSheet({super.key});

  @override
  State<BackupBottomSheet> createState() => _BackupBottomSheetState();
}

class _BackupBottomSheetState extends State<BackupBottomSheet> {
  final ConnectivityService _connectivityService = ConnectivityService();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          
          // Title
          const Text(
            'Backup & Restore',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          // Subtitle
          Text(
            'Keep your data safe with encrypted backups',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          // Backup button
          Consumer<BackupService>(
            builder: (context, backupService, child) {
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: backupService.isBackupInProgress 
                      ? null 
                      : () => _handleBackup(backupService),
                  icon: backupService.isBackupInProgress
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.cloud_upload_rounded),
                  label: Text(
                    backupService.isBackupInProgress
                        ? 'Backing up...'
                        : 'Backup Now',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          
          // Progress indicator
          Consumer<BackupService>(
            builder: (context, backupService, child) {
              if (backupService.isBackupInProgress) {
                return Column(
                  children: [
                    LinearProgressIndicator(
                      value: backupService.currentProgress.percentage / 100,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      backupService.currentProgress.currentAction,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
          const SizedBox(height: 16),
          
          // Connectivity status
          _buildConnectivityStatus(),
          const SizedBox(height: 16),
          
          // Restore button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _handleRestore(),
              icon: const Icon(Icons.cloud_download_rounded),
              label: const Text('Restore from Backup'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Close button
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectivityStatus() {
    return FutureBuilder<bool>(
      future: _connectivityService.isOnline(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 8),
              Text(
                'Checking connection...',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          );
        }

        final isOnline = snapshot.data ?? false;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isOnline ? Icons.wifi : Icons.wifi_off,
              size: 16,
              color: isOnline ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(
              isOnline ? 'Connected' : 'No Internet',
              style: TextStyle(
                fontSize: 12,
                color: isOnline ? Colors.green : Colors.red,
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleBackup(BackupService backupService) async {
    try {
      // Check connectivity first
      final isOnline = await _connectivityService.isOnline();

      if (!isOnline) {
        _showSnackBar('No internet connection. Please check your network and try again.');
        return;
      }

      // Start backup
      final success = await backupService.createBackup();
      
      if (!mounted) return;
      
      if (success) {
        _showSnackBar('✅ Backup completed successfully!');
        Navigator.pop(context);
      } else {
        _showSnackBar('❌ Backup failed. Please try again.');
      }
    } catch (e) {
      _showSnackBar('❌ Backup failed: ${e.toString()}');
    }
  }

  Future<void> _handleRestore() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Restore Backup'),
        content: const Text(
          'This will replace all current data with the backup data.\n\n'
          'Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final backupService = context.read<BackupService>();

      // Check connectivity first
      final isOnline = await _connectivityService.isOnline();
      if (!mounted) return;

      if (!isOnline) {
        _showSnackBar('No internet connection. Please check your network and try again.');
        return;
      }

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Restoring data...'),
                ],
              ),
            ),
          ),
        ),
      );

      // Start restore
      final result = await backupService.startRestore();

      // Close loading dialog
      if (!mounted) return;
      Navigator.pop(context);

      if (result.success) {
        _showSnackBar('✅ Restore completed successfully!');

        // Small delay to show the success message
        await Future.delayed(const Duration(milliseconds: 500));

        if (!mounted) return;

        // Close bottom sheet first
        Navigator.pop(context);

        // Pop all routes to go back to home screen
        // The HomeScreen will reload data in its didChangeDependencies
        while (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }

        // Trigger rebuild by calling setState on a parent if possible
        // Or show a snackbar to indicate data has been restored
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('📥 Data restored! Please pull to refresh or reopen the app.'),
              duration: Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        _showSnackBar('❌ Restore failed: ${result.errorMessage}');
      }
    } catch (e) {
      // Close loading dialog if it's still open
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      if (mounted) {
        _showSnackBar('❌ Restore failed: ${e.toString()}');
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: BackupConstants.notificationDisplayDuration,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Show backup bottom sheet
void showBackupBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const BackupBottomSheet(),
  );
}
