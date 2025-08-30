import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/cloud_backup_service.dart';

class CloudBackupScreen extends StatefulWidget {
  const CloudBackupScreen({super.key});

  @override
  State<CloudBackupScreen> createState() => _CloudBackupScreenState();
}

class _CloudBackupScreenState extends State<CloudBackupScreen> {
  final CloudBackupService _cloudBackupService = CloudBackupService();
  bool _isLoading = false;
  String _currentOperation = '';
  List<CloudBackupMetadata> _cloudBackups = [];

  @override
  void initState() {
    super.initState();
    _loadCloudBackups();
  }

  void _loadCloudBackups() async {
    setState(() {
      _isLoading = true;
      _currentOperation = 'Loading cloud backups...';
    });

    try {
      final backups = await _cloudBackupService.getCloudBackups(context);
      setState(() {
        _cloudBackups = backups;
        _isLoading = false;
        _currentOperation = '';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _currentOperation = '';
      });
    }
  }

  void _createCloudBackup() async {
    setState(() {
      _isLoading = true;
      _currentOperation = 'Starting cloud backup...';
    });

    // ignore: use_build_context_synchronously
    await _cloudBackupService.createCloudBackup(
      context,
      onProgress: (status) {
        if (mounted) {
          setState(() {
            _currentOperation = status;
          });
        }
      },
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        _currentOperation = '';
      });
      _loadCloudBackups(); // Refresh the list
    }
  }

  void _restoreCloudBackup(CloudBackupMetadata backup) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Cloud Backup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to restore from "${backup.name}"?'),
            const SizedBox(height: 8),
            Text(
              'Created: ${DateFormat('dd/MM/yyyy HH:mm').format(backup.createdAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              'Size: ${_cloudBackupService.formatFileSize(backup.size)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'This will replace all your current data with the backup data.',
              style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
        _currentOperation = 'Starting cloud restore...';
      });

      await _cloudBackupService.restoreFromCloud(
        context, // ignore: use_build_context_synchronously
        backup,
        onProgress: (status) {
          if (mounted) {
            setState(() {
              _currentOperation = status;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _currentOperation = '';
        });
      }
    }
  }

  void _deleteCloudBackup(CloudBackupMetadata backup) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Cloud Backup'),
        content: Text('Are you sure you want to permanently delete "${backup.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
        _currentOperation = 'Deleting cloud backup...';
      });

      // ignore: use_build_context_synchronously
      final success = await _cloudBackupService.deleteCloudBackup(context, backup);
      if (success) {
        _loadCloudBackups(); // Refresh the list
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _currentOperation = '';
        });
      }
    }
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
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        _currentOperation,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
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
                                            'Create your first cloud backup to keep your data safe',
                                            style: TextStyle(color: Colors.grey),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    )
                                  : ListView.builder(
                                      itemCount: _cloudBackups.length,
                                      itemBuilder: (context, index) {
                                        final backup = _cloudBackups[index];
                                        return ListTile(
                                          leading: const Icon(
                                            Icons.cloud,
                                            color: Colors.blue,
                                            size: 32,
                                          ),
                                          title: Text(
                                            backup.name,
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Created: ${DateFormat('dd/MM/yyyy HH:mm').format(backup.createdAt)}',
                                              ),
                                              Text(
                                                'Size: ${_cloudBackupService.formatFileSize(backup.size)} • ${backup.deviceInfo}',
                                              ),
                                            ],
                                          ),
                                          trailing: PopupMenuButton<String>(
                                            onSelected: (action) {
                                              switch (action) {
                                                case 'restore':
                                                  _restoreCloudBackup(backup);
                                                  break;
                                                case 'delete':
                                                  _deleteCloudBackup(backup);
                                                  break;
                                              }
                                            },
                                            itemBuilder: (context) => [
                                              const PopupMenuItem(
                                                value: 'restore',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.restore, color: Colors.blue),
                                                    SizedBox(width: 8),
                                                    Text('Restore'),
                                                  ],
                                                ),
                                              ),
                                              const PopupMenuItem(
                                                value: 'delete',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.delete, color: Colors.red),
                                                    SizedBox(width: 8),
                                                    Text('Delete'),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          onTap: () => _restoreCloudBackup(backup),
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