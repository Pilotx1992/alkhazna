import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../services/auth_service.dart';
import '../services/backup_service.dart';
import '../models/backup_status.dart';
import '../utils/backup_scheduler.dart';
import '../utils/oem_helper.dart';
import 'backup_progress_sheet.dart';
import '../../services/data_sharing_service.dart';
import '../../screens/import_screen.dart';

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
    // Show confirmation dialog
    final confirmed = await _showBackupConfirmationDialog();
    if (!confirmed) return;

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
    // Show confirmation dialog
    final confirmed = await _showRestoreConfirmationDialog();
    if (!confirmed) return;

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

  Future<void> _showExportOptions() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Export Data'),
          content: const Text('Choose what data to export:'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showMonthSelector();
              },
              child: const Text('Export Month'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _exportAllData();
              },
              child: const Text('Export All Data'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showMonthSelector() async {
    final currentDate = DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(currentDate.year - 5),
      lastDate: DateTime(currentDate.year + 1),
      helpText: 'Select Month to Export',
      fieldLabelText: 'Month/Year',
    );

    if (selectedDate != null) {
      final monthNames = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      final monthName = monthNames[selectedDate.month - 1];
      await _exportMonthData(monthName, selectedDate.year);
    }
  }

  Future<void> _exportMonthData(String month, int year) async {
    try {
      await DataSharingService.exportMonthData(month: month, year: year);
      if (mounted) {
        setState(() {
          _successMessage = 'Month data exported successfully! ($month $year)';
        });
        _clearMessageAfterDelay();
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString();
        if (errorMessage.contains('File saved successfully')) {
          // Show success dialog with file location info
          _showFileLocationDialog(errorMessage.replaceFirst('Exception: ', ''));
        } else {
          setState(() {
            _errorMessage = 'Failed to export month data: $e';
          });
          _clearMessageAfterDelay();
        }
      }
    }
  }

  Future<void> _exportAllData() async {
    try {
      await DataSharingService.exportAllData();
      if (mounted) {
        setState(() {
          _successMessage = 'All data exported successfully!';
        });
        _clearMessageAfterDelay();
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString();
        if (errorMessage.contains('File saved successfully')) {
          // Show success dialog with file location info
          _showFileLocationDialog(errorMessage.replaceFirst('Exception: ', ''));
        } else {
          setState(() {
            _errorMessage = 'Failed to export data: $e';
          });
          _clearMessageAfterDelay();
        }
      }
    }
  }

  Future<void> _importData() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ImportScreen(),
      ),
    );
    // Refresh backup screen data if import was successful
    if (result == true && mounted) {
      setState(() {
        _successMessage = 'Data imported successfully!';
      });
      _clearMessageAfterDelay();
      await _loadSettings(); // Refresh the screen
    }
  }

  void _showFileLocationDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 8),
              Text('Export Successful'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(message),
                const SizedBox(height: 16),
                Text(
                  'You can now manually share this file or copy it to your desired location.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _showBackupConfirmationDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.backup, color: Colors.indigo),
              const SizedBox(width: 8),
              Text('Confirm Backup'),
            ],
          ),
          content: Text('Create a backup of your data to Google Drive?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
              child: const Text('Backup'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  Future<bool> _showRestoreConfirmationDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.restore, color: Colors.orange),
              const SizedBox(width: 8),
              Text('Confirm Restore'),
            ],
          ),
          content: Text('This will replace your current data with the backup from Google Drive. Continue?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Restore'),
            ),
          ],
        );
      },
    ) ?? false;
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

                  // Cloud Backup Actions Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cloud Backup',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),

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
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Data Management Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.folder_shared,
                                size: 24,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Data Management',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Export and import your data files for sharing or migration',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Export Data Button (with options)
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: (_backupService.isBackupInProgress || _backupService.isRestoreInProgress)
                                  ? null
                                  : _showExportOptions,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.orange,
                                side: BorderSide(color: Colors.orange),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.file_upload),
                                  const SizedBox(width: 8),
                                  Text('Export Data'),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Import Data Button
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: (_backupService.isBackupInProgress || _backupService.isRestoreInProgress)
                                  ? null
                                  : _importData,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.teal,
                                side: BorderSide(color: Colors.teal),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.file_download),
                                  const SizedBox(width: 8),
                                  Text('Import Data'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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

                ],
              ),
            ),
    );
  }
}