import 'package:flutter/material.dart';
import '../models/drive_manifest_model.dart';
import '../services/drive/drive_restore_service.dart';
import 'restore_progress_screen.dart';

class RestoreOptionsScreen extends StatefulWidget {
  const RestoreOptionsScreen({super.key});

  @override
  State<RestoreOptionsScreen> createState() => _RestoreOptionsScreenState();
}

class _RestoreOptionsScreenState extends State<RestoreOptionsScreen> {
  final DriveRestoreService _restoreService = DriveRestoreService();
  List<Map<String, dynamic>> _backupsWithIds = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }

  Future<void> _loadBackups() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final backupsWithIds = await _restoreService.listAvailableBackupsWithIds();
      
      setState(() {
        _backupsWithIds = backupsWithIds;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load backups: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _showRestoreConfirmation(Map<String, dynamic> backupWithId) async {
    final manifestFileId = backupWithId['manifestFileId'] as String;
    final backup = backupWithId['manifest'] as DriveManifest;
    final preview = await _restoreService.getRestorePreview(manifestFileId);
    
    if (!mounted) return;

    final restoreOption = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.restore, size: 48, color: Colors.orange),
        title: const Text('Restore Backup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose how to restore data from ${backup.createdAt.toString().split(' ')[0]}:',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            
            if (preview != null) ...[
              const Text(
                'This backup contains:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('• ${preview['file_count'] ?? 0} files'),
              Text('• Total size: ${_formatBytes(preview['total_size'] ?? 0)}'),
              const SizedBox(height: 8),
              Text(
                'Platform: ${preview['platform'] ?? 'Unknown'}',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              const Text(
                '⚠️ Preview unavailable. The backup may be corrupted or inaccessible.',
                style: TextStyle(color: Colors.orange),
              ),
              const SizedBox(height: 16),
            ],

            // Merge option (recommended)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.merge, color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Merge: Add backup data to your existing data (Recommended)',
                      style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 8),

            // Replace option (warning)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Replace: Delete all current data and replace with backup',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'merge'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Merge'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'replace'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Replace'),
          ),
        ],
      ),
    );

    if (restoreOption != null) {
      final replaceExisting = restoreOption == 'replace';
      _startRestore(manifestFileId, replaceExisting: replaceExisting);
    }
  }

  void _startRestore(String manifestFileId, {bool replaceExisting = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RestoreProgressScreen(
          manifestFileId: manifestFileId, 
          replaceExisting: replaceExisting,
        ),
      ),
    );
  }

  Future<void> _deleteBackup(Map<String, dynamic> backupWithId) async {
    final backup = backupWithId['manifest'] as DriveManifest;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete, size: 48, color: Colors.red),
        title: const Text('Delete Backup'),
        content: Text('Are You Sure ${backup.createdAt.toString().split(' ')[0]}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Show loading indicator
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  ),
                  SizedBox(width: 12),
                  Text('Deleting backup...'),
                ],
              ),
            ),
          );
        }

        // Delete the backup using the restore service
        final manifestFileId = backupWithId['manifestFileId'] as String;
        await _restoreService.deleteBackup(manifestFileId);
        
        // Show success message and refresh the list
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Backup deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadBackups(); // Refresh the backup list
        }
      } catch (e) {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete backup: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Restore Options'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBackups,
          ),
        ],
      ),
      body: _buildBody(colorScheme),
    );
  }

  Widget _buildBody(ColorScheme colorScheme) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading your backups...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load backups',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadBackups,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_backupsWithIds.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No Backups Found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You haven\'t created any backups yet.\nCreate a backup first to be able to restore your data.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBackups,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _backupsWithIds.length,
        itemBuilder: (context, index) {
          final backupWithId = _backupsWithIds[index];
          return _buildBackupCard(backupWithId, colorScheme);
        },
      ),
    );
  }

  Widget _buildBackupCard(Map<String, dynamic> backupWithId, ColorScheme colorScheme) {
    final backup = backupWithId['manifest'] as DriveManifest;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showRestoreConfirmation(backupWithId),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.backup,
                      color: colorScheme.onPrimaryContainer,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          backup.createdAt.toString().split(' ')[0],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          '${_formatBytes(ManifestUtils.calculateTotalSize(backup))} • ${backup.platform}',
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _deleteBackup(backupWithId),
                    icon: const Icon(Icons.delete),
                    color: Colors.red,
                    tooltip: 'Delete backup',
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Content Summary
              Row(
                children: [
                  _buildDataChip(
                    '${backup.files.length} Files',
                    Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  _buildDataChip(
                    '${ManifestUtils.calculateTotalChunks(backup)} Chunks',
                    Colors.green,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Status and Action
              Row(
                children: [
                  Icon(
                    backup.status == 'complete'
                        ? Icons.check_circle
                        : Icons.warning,
                    size: 16,
                    color: backup.status == 'complete'
                        ? Colors.green
                        : Colors.orange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    backup.status == 'complete'
                        ? 'Ready to restore'
                        : 'May have issues',
                    style: TextStyle(
                      fontSize: 12,
                      color: backup.status == 'complete'
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.restore,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Tap to restore',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }
}