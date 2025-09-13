import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../services/auth_service.dart';
import '../services/backup_service.dart';
import '../models/backup_status.dart';
import '../utils/backup_scheduler.dart';
import '../utils/oem_helper.dart';
import 'backup_progress_sheet.dart';

/// Enhanced WhatsApp-style backup screen with modern interface
class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final BackupService _backupService = BackupService();
  bool _isLoading = true;
  bool _isAutoBackupEnabled = false;
  BackupFrequency _backupFrequency = BackupFrequency.weekly;
  NetworkPreference _networkPreference = NetworkPreference.wifiOnly;
  DateTime? _lastBackupTime;
  GoogleSignInAccount? _currentUser;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _backupService.addListener(_onBackupProgressUpdate);
  }

  @override
  void dispose() {
    _backupService.removeListener(_onBackupProgressUpdate);
    super.dispose();
  }

  void _onBackupProgressUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final isEnabled = await BackupScheduler.isAutoBackupEnabled();
      final frequency = await BackupScheduler.getBackupFrequency();
      final networkPref = await BackupScheduler.getNetworkPreference();
      final lastBackup = await BackupScheduler.getLastBackupTime();
      final user = _backupService.currentUser;

      setState(() {
        _isAutoBackupEnabled = isEnabled;
        _backupFrequency = frequency;
        _networkPreference = networkPref;
        _lastBackupTime = lastBackup.millisecondsSinceEpoch > 0 ? lastBackup : null;
        _currentUser = user;
        _isLoading = false;
      });

      // Show OnePlus/OEM guidance if needed
      if (mounted) {
        await OEMHelper.showBackupGuidance(context);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load backup settings: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _createBackup() async {
    try {
      // Show progress sheet
      showModalBottomSheet(
        context: context,
        isDismissible: false,
        enableDrag: false,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => BackupProgressSheet(
          onBackupComplete: () async {
            // Immediately refresh the last backup time after successful backup
            await _loadSettings();
            if (mounted) {
              setState(() {
                _successMessage = 'Backup created successfully!';
              });
              _clearMessageAfterDelay();
            }
          },
        ),
      );

      // Start backup
      await _backupService.startBackup();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to start backup: $e';
      });
    }
  }

  Future<void> _restoreBackup() async {
    // Show progress sheet
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BackupProgressSheet(
        isRestore: true,
        onRestoreComplete: () {
          setState(() {
            _successMessage = 'Backup restored successfully!';
          });
          _loadSettings();
          _clearMessageAfterDelay();
        },
      ),
    );
  }

  void _clearMessageAfterDelay() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _successMessage = null;
          _errorMessage = null;
        });
      }
    });
  }

  String _formatDateTime(DateTime dateTime) {
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

  String _getFrequencyText(BackupFrequency frequency) {
    switch (frequency) {
      case BackupFrequency.daily:
        return 'Daily';
      case BackupFrequency.weekly:
        return 'Weekly';
      case BackupFrequency.monthly:
        return 'Monthly';
      case BackupFrequency.off:
        return 'Off';
    }
  }

  String _getNetworkText(NetworkPreference preference) {
    switch (preference) {
      case NetworkPreference.wifiOnly:
        return 'Wi-Fi only';
      case NetworkPreference.wifiAndMobile:
        return 'Wi-Fi + Mobile';
    }
  }

  Future<String> _getOnePlusGuidance() async {
    if (await OEMHelper.requiresSpecialHandling()) {
      final oemType = await OEMHelper.getOEMType();
      if (oemType == OEMType.colorOS) {
        return '• OnePlus devices: Enable "Auto-launch" in Settings → Battery → Battery Optimization\n'
               '• Allow background activity to ensure reliable auto-backup\n';
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.authState.currentUser;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Restore'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.indigo,
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading backup settings...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.cloud_outlined,
                                size: 28,
                                color: Colors.indigo,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Google Drive Backup',
                                      style: theme.textTheme.titleLarge,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _currentUser?.email ?? user?.backupGoogleAccountEmail ?? 'Not signed in',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    if (_lastBackupTime != null) ...[
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.schedule,
                                            size: 14,
                                            color: Colors.green,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Last backup: ${_formatDateTime(_lastBackupTime!)}',
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: Colors.green,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),

                  // Auto Backup Settings
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Auto Backup Settings',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Auto Backup Toggle
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Auto Backup',
                                      style: theme.textTheme.bodyLarge,
                                    ),
                                    Text(
                                      'Automatically backup your data',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _isAutoBackupEnabled,
                                onChanged: (value) async {
                                  if (value) {
                                    // Check if OnePlus/OEM needs special handling
                                    if (await OEMHelper.requiresSpecialHandling()) {
                                      await OEMHelper.requestAutoStartPermission(context);
                                    }
                                    await BackupScheduler.scheduleAutoBackup(_backupFrequency);
                                  } else {
                                    await BackupScheduler.cancelAutoBackup();
                                  }
                                  setState(() {
                                    _isAutoBackupEnabled = value;
                                  });
                                },
                                activeThumbColor: Colors.indigo,
                              ),
                            ],
                          ),

                          if (_isAutoBackupEnabled) ...[
                            const Divider(),
                            
                            // Backup Frequency
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Backup Frequency'),
                              subtitle: Text(_getFrequencyText(_backupFrequency)),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Backup Frequency'),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: BackupFrequency.values.map((frequency) {
                                        return RadioListTile<BackupFrequency>(
                                          title: Text(_getFrequencyText(frequency)),
                                          value: frequency,
                                          groupValue: _backupFrequency,
                                          onChanged: (value) async {
                                            if (value != null) {
                                              await BackupScheduler.scheduleAutoBackup(value);
                                              setState(() {
                                                _backupFrequency = value;
                                                _isAutoBackupEnabled = value != BackupFrequency.off;
                                              });
                                              Navigator.pop(context);
                                            }
                                          },
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                );
                              },
                            ),

                            // Network Preference
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Network'),
                              subtitle: Text(_getNetworkText(_networkPreference)),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Network Preference'),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: NetworkPreference.values.map((preference) {
                                        return RadioListTile<NetworkPreference>(
                                          title: Text(_getNetworkText(preference)),
                                          value: preference,
                                          groupValue: _networkPreference,
                                          onChanged: (value) async {
                                            if (value != null) {
                                              await BackupScheduler.setNetworkPreference(value);
                                              setState(() {
                                                _networkPreference = value;
                                              });
                                              Navigator.pop(context);
                                            }
                                          },
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Manual Backup Actions
                  Column(
                    children: [
                      // Create Backup Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _backupService.isBackupInProgress ? null : _createBackup,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_backupService.isBackupInProgress) ...[
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text('Creating Backup...'),
                              ] else ...[
                                Icon(Icons.backup),
                                const SizedBox(width: 8),
                                Text('Backup Now'),
                              ],
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Restore Backup Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: (_backupService.isBackupInProgress || _backupService.isRestoreInProgress) 
                              ? null 
                              : _restoreBackup,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.indigo,
                            side: BorderSide(color: Colors.indigo),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_backupService.isRestoreInProgress) ...[
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text('Restoring...'),
                              ] else ...[
                                Icon(Icons.restore),
                                const SizedBox(width: 8),
                                Text('Restore'),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Messages
                  if (_errorMessage != null) ...[
                    Card(
                      color: Colors.red[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Icon(Icons.error, color: Colors.red),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(color: Colors.red[700]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (_successMessage != null) ...[
                    Card(
                      color: Colors.green[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _successMessage!,
                                style: TextStyle(color: Colors.green[700]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Information Card
                  Card(
                    color: Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info, color: Colors.blue),
                              const SizedBox(width: 8),
                              Text(
                                'About Backup',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          FutureBuilder<String>(
                            future: _getOnePlusGuidance(),
                            builder: (context, snapshot) {
                              final onePlusGuidance = snapshot.data ?? '';
                              return Text(
                                '• Your data is encrypted with WhatsApp-style security\n'
                                '• Backups include all income/expense entries and settings\n'
                                '• Files are stored securely in your Google Drive app data\n'
                                '• Automatic backups run in the background\n'
                                '• You can restore your data on any device\n'
                                '$onePlusGuidance',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.blue[700],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}