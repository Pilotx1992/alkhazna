import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/cloud_backup_service.dart';
import '../services/background_backup_service.dart';
import '../widgets/modern_progress_widget.dart';
import '../widgets/scheduled_backup_settings.dart';
import '../widgets/beautiful_backup_card.dart';

class CloudBackupScreen extends StatefulWidget {
  const CloudBackupScreen({super.key});

  @override
  State<CloudBackupScreen> createState() => _CloudBackupScreenState();
}

class _CloudBackupScreenState extends State<CloudBackupScreen> {
  final CloudBackupService _cloudBackupService = CloudBackupService();
  final BackgroundBackupService _backgroundService = BackgroundBackupService();
  bool _isLoading = false;
  String _currentOperation = '';
  List<CloudBackupMetadata> _cloudBackups = [];
  double _operationProgress = 0.0;
  bool _operationComplete = false;
  String? _operationError;

  @override
  void initState() {
    super.initState();
    _loadCloudBackups();
  }

  void _loadCloudBackups() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _currentOperation = 'Loading cloud backups...';
    });

    try {
      final backups = await _cloudBackupService.getCloudBackups(context);
      if (mounted) {
        setState(() {
          _cloudBackups = backups;
          _isLoading = false;
          _currentOperation = '';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _currentOperation = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load backups: $e')),
        );
      }
    }
  }

  void _createCloudBackup() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _operationProgress = 0.0;
      _operationComplete = false;
      _operationError = null;
      _currentOperation = 'Initializing backup...';
    });

    try {
      await _backgroundService.createBackgroundBackup(
        (status) {
          if (mounted) {
            setState(() {
              _currentOperation = status;
              // Extract progress from status if it contains percentage
              final match = RegExp(r'(\d+)%').firstMatch(status);
              if (match != null) {
                _operationProgress = double.parse(match.group(1)!);
              }
            });
          }
        },
        (success, error) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _operationComplete = success;
              _operationError = error;
              if (success) {
                _currentOperation = 'Backup completed successfully!';
                _operationProgress = 100.0;
              }
            });
            
            if (success) {
              _loadCloudBackups(); // Refresh the list
              // Auto-hide success message after 3 seconds
              Future.delayed(const Duration(seconds: 3), () {
                if (mounted) {
                  setState(() {
                    _operationComplete = false;
                    _operationProgress = 0.0;
                    _currentOperation = '';
                  });
                }
              });
            }
          }
        },
        context: context,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _operationError = e.toString();
          _currentOperation = 'Backup failed';
        });
      }
    }
  }

  void _restoreCloudBackup(CloudBackupMetadata backup) async {
    final confirm = await _showConfirmDialog(
      title: 'Restore Cloud Backup',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.restore_rounded,
            size: 48,
            color: Colors.orange[600],
          ),
          const SizedBox(height: 16),
          Text(
            'Restore from "${backup.name}"?',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Created: ${DateFormat('MMM dd, yyyy at HH:mm').format(backup.createdAt)}',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Text(
            'Size: ${_cloudBackupService.formatFileSize(backup.size)}',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_rounded, color: Colors.orange[600], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This will replace all your current data with the backup data.',
                    style: TextStyle(
                      color: Colors.orange[800],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      confirmText: 'Restore',
      confirmColor: Colors.orange[600]!,
      isDestructive: true,
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
        _operationProgress = 0.0;
        _operationComplete = false;
        _operationError = null;
        _currentOperation = 'Starting cloud restore...';
      });

      try {
        await _backgroundService.restoreBackgroundBackup(
          backup,
          (status) {
            if (mounted) {
              setState(() {
                _currentOperation = status;
                final match = RegExp(r'(\d+)%').firstMatch(status);
                if (match != null) {
                  _operationProgress = double.parse(match.group(1)!) / 100;
                }
              });
            }
          },
          (success, error) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _operationComplete = success;
                _operationError = error;
                _operationProgress = success ? 1.0 : 0.0;
              });
              
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Backup restored successfully!'),
                    backgroundColor: Colors.green[600],
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.all(16),
                  ),
                );
                _showRestartDialog();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(error ?? 'Restore failed'),
                    backgroundColor: Colors.red[600],
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.all(16),
                  ),
                );
              }
            }
          },
          context: context,
        );
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _operationError = e.toString();
            _currentOperation = 'Restore failed';
          });
        }
      }
    }
  }

  void _deleteCloudBackup(CloudBackupMetadata backup) async {
    final confirm = await _showConfirmDialog(
      title: 'Delete Cloud Backup',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.delete_forever_rounded,
            size: 48,
            color: Colors.red[600],
          ),
          const SizedBox(height: 16),
          Text(
            'Delete "${backup.name}"?',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'This backup will be permanently deleted from the cloud.',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_rounded, color: Colors.red[600], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This action cannot be undone.',
                    style: TextStyle(
                      color: Colors.red[800],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      confirmText: 'Delete',
      confirmColor: Colors.red[600]!,
      isDestructive: true,
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
        _operationProgress = 0.0;
        _operationComplete = false;
        _operationError = null;
        _currentOperation = 'Deleting backup...';
      });

      try {
        await _backgroundService.deleteBackgroundBackup(
          backup,
          (status) {
            if (mounted) {
              setState(() {
                _currentOperation = status;
              });
            }
          },
          (success, error) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _operationComplete = success;
                _operationError = error;
                _operationProgress = success ? 1.0 : 0.0;
              });
              
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Backup deleted successfully!'),
                    backgroundColor: Colors.green[600],
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.all(16),
                  ),
                );
                _loadCloudBackups(); // Refresh the list
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(error ?? 'Delete failed'),
                    backgroundColor: Colors.red[600],
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.all(16),
                  ),
                );
              }
            }
          },
          context: context,
        );
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _operationError = e.toString();
            _currentOperation = 'Delete failed';
          });
        }
      }
    }
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required Widget content,
    required String confirmText,
    required Color confirmColor,
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: content,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  void _showRestartDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_rounded,
              size: 64,
              color: Colors.green[600],
            ),
            const SizedBox(height: 16),
            const Text(
              'Restore Complete!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Your data has been restored successfully. Please restart the app for changes to take effect.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloud Backups'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadCloudBackups,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _isLoading
              ? ModernProgressWidget(
                  progress: _operationProgress,
                  status: _currentOperation,
                  isComplete: _operationComplete,
                  error: _operationError,
                  onCancel: () {
                    setState(() {
                      _isLoading = false;
                      _operationProgress = 0.0;
                      _operationComplete = false;
                      _operationError = null;
                      _currentOperation = '';
                    });
                  },
                )
              : Column(
                  children: [
                    // Scheduled Backup Settings
                    const ScheduledBackupSettings(),
                    
                    const SizedBox(height: 16),
                    
                    // Create Cloud Backup Button
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.cloud_upload,
                              size: 48,
                              color: Colors.blue,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Cloud Storage',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Your data is encrypted before upload. Keep your password safe!',
                              style: Theme.of(context).textTheme.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _createCloudBackup,
                                icon: const Icon(Icons.cloud_upload),
                                label: const Text('Create Cloud Backup'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.all(16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Cloud Backups List
                    Expanded(
                      child: Card(
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  const Icon(Icons.cloud, color: Colors.blue),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Your Cloud Backups',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${_cloudBackups.length} backup${_cloudBackups.length == 1 ? '' : 's'}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1),
                            Expanded(
                              child: _cloudBackups.isEmpty
                                  ? const Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.cloud_off,
                                            size: 64,
                                            color: Colors.grey,
                                          ),
                                          SizedBox(height: 16),
                                          Text(
                                            'No cloud backups found',
                                            style: TextStyle(
                                              fontSize: 18,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            'Create your first backup',
                                            style: TextStyle(color: Colors.grey),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    )
                                  : ListView.builder(
                                      itemCount: _cloudBackups.length,
                                      padding: const EdgeInsets.only(left: 8, right: 8, top: 8, bottom: 80),
                                      itemBuilder: (context, index) {
                                        final backup = _cloudBackups[index];
                                        
                                        return BeautifulBackupCard(
                                          backup: backup,
                                          index: index,
                                          onRestore: () => _restoreCloudBackup(backup),
                                          onDelete: () => _deleteCloudBackup(backup),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}