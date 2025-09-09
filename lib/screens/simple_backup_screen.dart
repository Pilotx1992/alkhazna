import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/drive/drive_backup_service.dart';
import '../services/drive/drive_restore_service.dart';
import '../services/drive/drive_provider_resumable.dart';
import 'backup_progress_screen.dart';
import 'backup_settings_screen.dart';
import 'restore_progress_screen.dart';

/// WhatsApp-style backup screen - Simple and intuitive
class SimpleBackupScreen extends StatefulWidget {
  const SimpleBackupScreen({super.key});

  @override
  State<SimpleBackupScreen> createState() => _SimpleBackupScreenState();
}

class _SimpleBackupScreenState extends State<SimpleBackupScreen> {
  // Services for backup system integration
  final DriveBackupService _backupService = DriveBackupService(); // Used for backup operations
  final DriveRestoreService _restoreService = DriveRestoreService(); // Used for restore operations
  final DriveProviderResumable _driveProvider = DriveProviderResumable(); // Used for Drive API calls
  final GoogleSignIn _googleSignIn = GoogleSignIn(); // Used for authentication
  
  bool _isLoading = true;
  bool _isSignedIn = false;
  String? _userEmail;
  String? _lastBackupTime;
  List<Map<String, dynamic>> _availableBackups = [];

  @override
  void initState() {
    super.initState();
    _loadBackupInfo();
  }

  Future<void> _loadBackupInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check Google Sign-in status and get real user info
      final googleSignIn = GoogleSignIn();
      final currentUser = googleSignIn.currentUser ?? await googleSignIn.signInSilently();
      
      if (currentUser != null) {
        _isSignedIn = true;
        _userEmail = currentUser.email;
      } else {
        _isSignedIn = false;
        _userEmail = null;
      }

      // Get available backups with their manifest file IDs
      _availableBackups = await _getBackupsWithManifestIds();

      // Get last backup time
      if (_availableBackups.isNotEmpty) {
        _availableBackups.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
        _lastBackupTime = _formatBackupTime(_availableBackups.first['date'] as DateTime);
      }

    } catch (e) {
      // Handle Google Drive API not enabled gracefully
      if (e.toString().contains('accessNotConfigured') || e.toString().contains('Google Drive API has not been used')) {
        // Show a more user-friendly message for API configuration issues
        if (mounted) {
          _showDriveApiNotConfiguredDialog();
        }
      } else {
        // Handle other errors gracefully
        if (mounted) {
          _showError('Failed to load backup information: ${e.toString()}');
        }
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatBackupTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }


  void _showBackupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.backup, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Back up'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Back up your chats and media to Google Drive so you can restore them if you reinstall Alkhazna.'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.green.shade600, size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Your backup will be encrypted and stored securely',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startBackup();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('BACK UP'),
          ),
        ],
      ),
    );
  }

  void _showRestoreDialog() {
    if (_availableBackups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No backups available to restore')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.restore, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Restore'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Restore your data from your Google Drive backup.'),
            const SizedBox(height: 12),
            Text(
              'Latest backup: $_lastBackupTime',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            Text(
              'Choose restore option:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.add_circle_outline, color: Colors.blue.shade600, size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'MERGE: Add backup data to existing data',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange.shade600, size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'REPLACE: This will delete current data',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startRestoreWithOption(false); // Merge
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('MERGE'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startRestoreWithOption(true); // Replace
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('REPLACE'),
          ),
        ],
      ),
    );
  }

  void _startBackup() {
    // Check if user is authenticated first
    if (!_isSignedIn) {
      _showError('Please sign in to your Google account first');
      return;
    }
    
    // Navigate to backup progress screen
    // The BackupProgressScreen will handle Drive API configuration errors
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BackupProgressScreen(),
      ),
    ).then((_) => _loadBackupInfo());
  }

  /// Get available backups with actual manifest file IDs
  Future<List<Map<String, dynamic>>> _getBackupsWithManifestIds() async {
    try {
      // Use the new method that returns actual Drive file IDs
      return await _restoreService.listAvailableBackupsWithIds();
    } catch (e) {
      if (mounted) {
        print('Failed to get backups with manifest IDs: $e');
      }
      return [];
    }
  }


  void _startRestoreWithOption(bool replaceExisting) {
    if (_availableBackups.isNotEmpty) {
      // Get the latest backup's manifest file ID
      final latestBackup = _availableBackups.first;
      final manifestFileId = latestBackup['manifestFileId'] as String;
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RestoreProgressScreen(
            manifestFileId: manifestFileId,
            replaceExisting: replaceExisting,
          ),
        ),
      ).then((_) => _loadBackupInfo());
    } else {
      _showError('No backups available to restore');
    }
  }


  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  void _showDriveApiNotConfiguredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.cloud_off, size: 64, color: Colors.orange),
        title: const Text('Google Drive API Setup Required'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'To enable backup functionality, the Google Drive API needs to be configured in Google Cloud Console.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              '1. Go to Google Cloud Console\n'
              '2. Enable Google Drive API\n'
              '3. Configure OAuth consent screen\n'
              '4. Add required scopes',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Could add a link to documentation or setup guide
            },
            child: const Text('Learn More'),
          ),
        ],
      ),
    );
  }

  void _showManageBackupsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.folder_outlined, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Manage backups'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'You have ${_availableBackups.length} backup${_availableBackups.length == 1 ? '' : 's'} stored in Google Drive.',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: _availableBackups.length > 3 ? 200 : null,
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _availableBackups.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final backup = _availableBackups[index];
                    final date = backup['date'] as DateTime;
                    final size = backup['size'] as int;
                    final status = backup['status'] as String;
                    
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: status == 'complete' 
                              ? Colors.green.shade100 
                              : Colors.orange.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          status == 'complete' ? Icons.backup : Icons.warning,
                          color: status == 'complete' 
                              ? Colors.green.shade700 
                              : Colors.orange.shade700,
                          size: 18,
                        ),
                      ),
                      title: Text(
                        _formatBackupDate(date),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        '${_formatFileSize(size)} • $status',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.restore, size: 20),
                            onPressed: status == 'complete' 
                                ? () => _restoreSpecificBackup(backup)
                                : null,
                            tooltip: 'Restore this backup',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                            onPressed: () => _deleteSpecificBackup(backup, index),
                            tooltip: 'Delete this backup',
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (_availableBackups.length > 1)
            TextButton(
              onPressed: _showDeleteAllBackupsDialog,
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('DELETE ALL'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  String _formatBackupDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return 'Today, ${difference.inMinutes}m ago';
      }
      return 'Today, ${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes == 0) return '0 B';
    if (bytes < 1024) return '${bytes} B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  void _restoreSpecificBackup(Map<String, dynamic> backup) {
    Navigator.pop(context); // Close manage dialog
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.restore, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Restore backup'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Restore from backup created on ${_formatBackupDate(backup['date'] as DateTime)}?'),
            const SizedBox(height: 16),
            Text(
              'Choose restore option:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.add_circle_outline, color: Colors.blue.shade600, size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'MERGE: Add backup data to existing data',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange.shade600, size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'REPLACE: This will delete current data',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              final manifestFileId = backup['manifestFileId'] as String;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RestoreProgressScreen(
                    manifestFileId: manifestFileId,
                    replaceExisting: false, // Merge with existing data
                  ),
                ),
              ).then((_) => _loadBackupInfo());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('MERGE'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              final manifestFileId = backup['manifestFileId'] as String;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RestoreProgressScreen(
                    manifestFileId: manifestFileId,
                    replaceExisting: true, // Replace existing data
                  ),
                ),
              ).then((_) => _loadBackupInfo());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('REPLACE'),
          ),
        ],
      ),
    );
  }

  void _deleteSpecificBackup(Map<String, dynamic> backup, int index) {
    Navigator.pop(context); // Close manage dialog
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.delete, color: Colors.red),
            const SizedBox(width: 8),
            const Text('Delete backup'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Delete backup from ${_formatBackupDate(backup['date'] as DateTime)}?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.red.shade600, size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'This action cannot be undone',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performBackupDeletion(backup, index);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAllBackupsDialog() {
    Navigator.pop(context); // Close manage dialog
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.delete_forever, color: Colors.red),
            const SizedBox(width: 8),
            const Text('Delete all backups'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Delete all ${_availableBackups.length} backups from Google Drive?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.red.shade600, size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'This action cannot be undone. All your backup data will be permanently removed.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performAllBackupsDeletion();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('DELETE ALL'),
          ),
        ],
      ),
    );
  }

  Future<void> _performBackupDeletion(Map<String, dynamic> backup, int index) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Deleting backup...'),
          ],
        ),
      ),
    );

    try {
      // Delete the session folder and all its contents
      final sessionId = backup['id'] as String;
      await _deleteBackupSession(sessionId);
      
      // Update local state
      setState(() {
        _availableBackups.removeAt(index);
        if (_availableBackups.isEmpty) {
          _lastBackupTime = null;
        } else {
          _availableBackups.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
          _lastBackupTime = _formatBackupTime(_availableBackups.first['date'] as DateTime);
        }
      });

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        _showError('Failed to delete backup: ${e.toString()}');
      }
    }
  }

  Future<void> _performAllBackupsDeletion() async {
    // Show loading indicator with progress
    int deletedCount = 0;
    final totalCount = _availableBackups.length;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('Deleting backups... ($deletedCount/$totalCount)'),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: deletedCount / totalCount,
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final backupsToDelete = List<Map<String, dynamic>>.from(_availableBackups);
      
      for (final backup in backupsToDelete) {
        try {
          final sessionId = backup['id'] as String;
          await _deleteBackupSession(sessionId);
          deletedCount++;
          
          // Update progress dialog
          if (mounted) {
            // This is a bit hacky but works for updating the dialog
            Navigator.pop(context);
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text('Deleting backups... ($deletedCount/$totalCount)'),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: deletedCount / totalCount,
                    ),
                  ],
                ),
              ),
            );
          }
        } catch (e) {
          print('Failed to delete backup ${backup['id']}: $e');
          // Continue with other deletions
        }
      }
      
      // Update local state
      setState(() {
        _availableBackups.clear();
        _lastBackupTime = null;
      });

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$deletedCount backup${deletedCount == 1 ? '' : 's'} deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        _showError('Failed to delete all backups: ${e.toString()}');
      }
    }
  }

  Future<void> _deleteBackupSession(String sessionId) async {
    try {
      final account = _googleSignIn.currentUser;
      final googleId = account?.id ?? 'unknown';

      // Find user's backup folder
      final appFolderId = await _driveProvider.findOrCreateFolder('Alkhazna Backups');
      final userQuery = "name='$googleId' and parents='$appFolderId' and mimeType='application/vnd.google-apps.folder'";
      final userFolders = await _driveProvider.queryFiles(userQuery);
      
      if (userFolders.isEmpty) {
        throw Exception('User backup folder not found');
      }
      final userFolderId = userFolders[0]['id'];

      // Find session folder
      final sessionQuery = "name='session-$sessionId' and parents='$userFolderId' and mimeType='application/vnd.google-apps.folder'";
      final sessionFolders = await _driveProvider.queryFiles(sessionQuery);
      
      if (sessionFolders.isEmpty) {
        throw Exception('Session folder not found');
      }
      final sessionFolderId = sessionFolders[0]['id'];

      // Delete all files in the session folder
      final filesQuery = "parents='$sessionFolderId'";
      final sessionFiles = await _driveProvider.queryFiles(filesQuery);
      
      for (final file in sessionFiles) {
        await _driveProvider.deleteFile(file['id']);
      }

      // Delete the session folder itself
      await _driveProvider.deleteFile(sessionFolderId);
      
    } catch (e) {
      print('Error deleting backup session $sessionId: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backups'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Google Drive Card
                  _buildGoogleDriveCard(colorScheme),
                  const SizedBox(height: 24),
                  
                  // Backup Options
                  _buildBackupSection(colorScheme),
                  const SizedBox(height: 24),
                  
                  // Settings
                  _buildSettingsSection(colorScheme),
                ],
              ),
            ),
    );
  }

  Widget _buildGoogleDriveCard(ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade600,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.cloud, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Google Drive',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      if (_isSignedIn) ...[
                        Text(
                          _userEmail ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ] else ...[
                        const Text(
                          'Not connected',
                          style: TextStyle(fontSize: 14, color: Colors.red),
                        ),
                      ],
                    ],
                  ),
                ),
                if (_isSignedIn)
                  Icon(Icons.check_circle, color: Colors.green, size: 20),
              ],
            ),
            if (_lastBackupTime != null) ...[
              const SizedBox(height: 12),
              Text(
                'Last backup: $_lastBackupTime',
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBackupSection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Backup',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        
        // Back up button
        Card(
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.backup, color: Colors.green.shade700),
            ),
            title: const Text('Back up to Google Drive'),
            subtitle: const Text('Back up messages and media'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showBackupDialog,
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Restore button
        Card(
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.restore, color: Colors.blue.shade700),
            ),
            title: const Text('Restore from backup'),
            subtitle: Text(
              _availableBackups.isEmpty 
                  ? 'No backups available'
                  : 'Restore your data from Google Drive'
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: _availableBackups.isEmpty ? null : _showRestoreDialog,
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Manage backups button
        Card(
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.folder_outlined, color: Colors.orange.shade700),
            ),
            title: const Text('Manage backups'),
            subtitle: Text(
              _availableBackups.isEmpty 
                  ? 'No backups to manage'
                  : '${_availableBackups.length} backup${_availableBackups.length == 1 ? '' : 's'} available'
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: _availableBackups.isEmpty ? null : _showManageBackupsDialog,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Settings',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        
        Card(
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.settings, color: colorScheme.primary),
                title: const Text('Backup Settings'),
                subtitle: const Text('Configure backup options and encryption'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BackupSettingsScreen(),
                    ),
                  ).then((_) => _loadBackupInfo());
                },
              ),
              
              const Divider(height: 1),
              
              ListTile(
                leading: Icon(Icons.wifi, color: colorScheme.primary),
                title: const Text('Back up over'),
                subtitle: const Text('Wi-Fi only'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BackupSettingsScreen(),
                    ),
                  );
                },
              ),
              
              const Divider(height: 1),
              
              ListTile(
                leading: Icon(Icons.security, color: colorScheme.primary),
                title: const Text('End-to-end encrypted backup'),
                subtitle: const Text('Protect your backup with encryption'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BackupSettingsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Info text
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Backups are encrypted and stored securely in your Google Drive. Media and messages are included in backups.',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}