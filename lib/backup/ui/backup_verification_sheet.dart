import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/google_drive_service.dart';
import '../services/backup_service.dart';

/// WhatsApp-style backup verification sheet
class BackupVerificationSheet extends StatefulWidget {
  const BackupVerificationSheet({super.key});

  @override
  State<BackupVerificationSheet> createState() => _BackupVerificationSheetState();
}

class _BackupVerificationSheetState extends State<BackupVerificationSheet> {
  final GoogleDriveService _driveService = GoogleDriveService();
  
  bool _isLoading = true;
  bool _isVerifying = false;
  final List<BackupVerificationReport> _verificationReports = [];
  String? _errorMessage;
  GoogleSignInAccount? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadBackupInfo();
  }

  Future<void> _loadBackupInfo() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Initialize Drive service
      final isInitialized = await _driveService.initialize();
      if (!isInitialized) {
        setState(() {
          _errorMessage = 'Failed to initialize Google Drive service';
          _isLoading = false;
        });
        return;
      }

      _currentUser = _driveService.currentUser;
      
      // Get backup files
      final backupFiles = await _driveService.listFiles(
        query: "name contains 'alkhazna_backup_'"
      );

      if (backupFiles.isEmpty) {
        setState(() {
          _errorMessage = 'No backup files found';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load backup information: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyBackups() async {
    setState(() {
      _isVerifying = true;
      _verificationReports.clear();
    });

    try {
      // Get backup files
      final backupFiles = await _driveService.listFiles(
        query: "name contains 'alkhazna_backup_'"
      );

      for (final file in backupFiles) {
        if (file.id == null) continue;

        try {
          // Get file details
          final fileInfo = await _driveService.getFileInfo(file.id!);
          final fileSize = int.tryParse(fileInfo?.size ?? file.size ?? '0') ?? 0;
          
          // For now, we'll do basic validation
          // In a real implementation, you might want to:
          // 1. Download and decrypt a small portion
          // 2. Verify the file structure
          // 3. Check metadata integrity
          
          final report = BackupVerificationReport(
            fileName: file.name ?? 'Unknown',
            fileId: file.id!,
            isValid: fileSize > 0, // Basic size check
            expectedChecksum: null, // Would need to be stored in metadata
            actualChecksum: null, // Would need to be calculated
            sizeBytes: fileSize,
            modifiedTime: file.modifiedTime,
            error: fileSize == 0 ? 'File appears to be empty' : null,
          );

          _verificationReports.add(report);
        } catch (e) {
          _verificationReports.add(BackupVerificationReport(
            fileName: file.name ?? 'Unknown',
            fileId: file.id!,
            isValid: false,
            expectedChecksum: null,
            actualChecksum: null,
            sizeBytes: 0,
            modifiedTime: file.modifiedTime,
            error: 'Failed to verify: $e',
          ));
        }
      }

    } catch (e) {
      setState(() {
        _errorMessage = 'Verification failed: $e';
      });
    } finally {
      setState(() {
        _isVerifying = false;
      });
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Unknown';
    
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return 'Today at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return '${weekdays[dateTime.weekday - 1]} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
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
                Icon(
                  Icons.verified,
                  color: Colors.green[600],
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Backup Verification',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // User info
          if (_currentUser != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundImage: _currentUser!.photoUrl != null 
                          ? NetworkImage(_currentUser!.photoUrl!)
                          : null,
                      child: _currentUser!.photoUrl == null 
                          ? Text(_currentUser!.email[0].toUpperCase())
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentUser!.displayName ?? 'Google User',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            _currentUser!.email,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          const SizedBox(height: 24),
          
          // Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading backup information...'),
                      ],
                    ),
                  )
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Colors.red[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _errorMessage!,
                                style: theme.textTheme.bodyLarge,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: _loadBackupInfo,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          // Verify button
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _isVerifying ? null : _verifyBackups,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green[600],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                icon: _isVerifying
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Icon(Icons.verified),
                                label: Text(_isVerifying ? 'Verifying...' : 'Verify Backups'),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Results
                          Expanded(
                            child: _verificationReports.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.backup_outlined,
                                          size: 64,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No verification results yet',
                                          style: theme.textTheme.bodyLarge?.copyWith(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Tap "Verify Backups" to check your backup files',
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.symmetric(horizontal: 24),
                                    itemCount: _verificationReports.length,
                                    itemBuilder: (context, index) {
                                      final report = _verificationReports[index];
                                      return Card(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(
                                                    report.isValid 
                                                        ? Icons.check_circle 
                                                        : Icons.error,
                                                    color: report.isValid 
                                                        ? Colors.green[600] 
                                                        : Colors.red[600],
                                                    size: 20,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      report.fileName,
                                                      style: theme.textTheme.bodyMedium?.copyWith(
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              
                                              const SizedBox(height: 8),
                                              
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.storage,
                                                    size: 16,
                                                    color: Colors.grey[600],
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    _formatFileSize(report.sizeBytes),
                                                    style: theme.textTheme.bodySmall?.copyWith(
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 16),
                                                  Icon(
                                                    Icons.schedule,
                                                    size: 16,
                                                    color: Colors.grey[600],
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    _formatDateTime(report.modifiedTime),
                                                    style: theme.textTheme.bodySmall?.copyWith(
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              
                                              if (report.error != null) ...[
                                                const SizedBox(height: 8),
                                                Container(
                                                  padding: const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: Colors.red[50],
                                                    borderRadius: BorderRadius.circular(4),
                                                    border: Border.all(color: Colors.red[200]!),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        Icons.warning,
                                                        size: 16,
                                                        color: Colors.red[600],
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Expanded(
                                                        child: Text(
                                                          report.error!,
                                                          style: theme.textTheme.bodySmall?.copyWith(
                                                            color: Colors.red[700],
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
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
          ),
          
          // Bottom actions
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[600],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(
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
}
