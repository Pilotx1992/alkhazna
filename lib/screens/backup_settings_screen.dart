import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/backup_models.dart';
import '../services/key_management_service.dart';
import 'backup_progress_screen.dart';

class BackupSettingsScreen extends StatefulWidget {
  const BackupSettingsScreen({super.key});

  @override
  State<BackupSettingsScreen> createState() => _BackupSettingsScreenState();
}

class _BackupSettingsScreenState extends State<BackupSettingsScreen> {
  final KeyManagementService _keyManagementService = KeyManagementService();
  BackupSettings? _settings;
  bool _isLoading = true;
  GoogleSignInAccount? _currentUser;
  Map<String, dynamic> _encryptionStatus = {};

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _getCurrentUser();
    _loadEncryptionStatus();
  }

  Future<void> _loadSettings() async {
    try {
      // Create default settings for now - DriveBackupService doesn't have getBackupSettings yet
      setState(() {
        _settings = BackupSettings();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _settings = BackupSettings();
      });
    }
  }

  Future<void> _getCurrentUser() async {
    final googleSignIn = GoogleSignIn();
    final user = await googleSignIn.signInSilently();
    setState(() {
      _currentUser = user;
    });
  }

  Future<void> _saveSettings() async {
    // TODO: Implement settings persistence for DriveBackupService
    if (_settings != null) {
      // For now, just store in memory - can implement Hive storage later
      print('Settings updated: ${_settings!.toJson()}');
    }
  }

  Future<void> _loadEncryptionStatus() async {
    try {
      final status = await _keyManagementService.getEncryptionStatus();
      setState(() {
        _encryptionStatus = status;
      });
    } catch (e) {
      print('Failed to load encryption status: $e');
    }
  }

  Future<void> _toggleEncryption(bool enabled) async {
    try {
      await _keyManagementService.setEncryptionEnabled(enabled);
      await _loadEncryptionStatus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update encryption: $e')),
        );
      }
    }
  }

  Future<void> _generateRecoveryKey() async {
    try {
      final recoveryKey = await _keyManagementService.generateRecoveryKey('temp_session');
      if (mounted) {
        _showRecoveryKeyDialog(recoveryKey);
        await _loadEncryptionStatus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate recovery key: $e')),
        );
      }
    }
  }

  void _showRecoveryKeyDialog(String recoveryKey) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Recovery Key Generated'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'IMPORTANT: Save this recovery key safely. You\'ll need it to restore your backups on a new device.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: SelectableText(
                recoveryKey,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '• Write it down and store it safely\n• Don\'t share it with anyone\n• You cannot recover it later',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Copy to clipboard
              // Add clipboard functionality if needed
              Navigator.of(context).pop();
            },
            child: const Text('I\'ve Saved It'),
          ),
        ],
      ),
    );
  }

  Future<void> _startManualBackup() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BackupProgressScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup Settings'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _settings == null
              ? const Center(child: Text('Failed to load settings'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Account Info Section
                      _buildAccountSection(colorScheme),
                      const SizedBox(height: 24),
                      
                      // Auto Backup Section
                      _buildAutoBackupSection(colorScheme),
                      const SizedBox(height: 24),
                      
                      // Encryption Section
                      _buildEncryptionSection(colorScheme),
                      const SizedBox(height: 24),
                      
                      // Manual Backup Section
                      _buildManualBackupSection(colorScheme),
                      const SizedBox(height: 24),
                      
                      // Backup History
                      _buildBackupHistorySection(colorScheme),
                      const SizedBox(height: 24),
                      
                      // Storage Info
                      _buildStorageInfoSection(colorScheme),
                    ],
                  ),
                ),
    );
  }

  Widget _buildAccountSection(ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_circle, color: colorScheme.primary, size: 32),
                const SizedBox(width: 12),
                Text(
                  'Google Account',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentUser?.email ?? 'Not signed in',
                        style: TextStyle(
                          fontSize: 16,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      if (_currentUser?.displayName != null)
                        Text(
                          _currentUser!.displayName!,
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.cloud_done,
                  color: Colors.green,
                  size: 24,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoBackupSection(ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Auto Backup',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            
            // Auto backup toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enable Auto Backup',
                      style: TextStyle(
                        fontSize: 16,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Automatically backup your data',
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                Switch(
                  value: _settings!.autoBackupEnabled,
                  onChanged: (value) {
                    setState(() {
                      _settings!.autoBackupEnabled = value;
                    });
                    _saveSettings();
                  },
                ),
              ],
            ),
            
            if (_settings!.autoBackupEnabled) ...[
              const SizedBox(height: 16),
              
              // Frequency selection
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.schedule, color: colorScheme.primary),
                title: const Text('Backup Frequency'),
                subtitle: Text(_settings!.frequencyDisplayText),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showFrequencyDialog(),
              ),
              
              // WiFi only option
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Backup on WiFi only',
                        style: TextStyle(
                          fontSize: 16,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Avoid mobile data usage',
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  Switch(
                    value: _settings!.backupOnWifiOnly,
                    onChanged: (value) {
                      setState(() {
                        _settings!.backupOnWifiOnly = value;
                      });
                      _saveSettings();
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildManualBackupSection(ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Manual Backup',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Backup Now',
                        style: TextStyle(
                          fontSize: 16,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Create a backup immediately',
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _startManualBackup,
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text('Start Backup'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupHistorySection(ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Backup History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.history, color: colorScheme.primary),
              title: const Text('Last Backup'),
              subtitle: Text(_settings!.lastBackupDisplayText),
              trailing: Icon(
                _settings!.lastBackupTime != null 
                    ? Icons.check_circle 
                    : Icons.info_outline,
                color: _settings!.lastBackupTime != null 
                    ? Colors.green 
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageInfoSection(ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Storage Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Icon(Icons.cloud_queue, color: colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Google Drive Storage',
                        style: TextStyle(
                          fontSize: 16,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Backups are stored securely in your Google Drive',
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showFrequencyDialog() async {
    final result = await showDialog<BackupFrequency>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Backup Frequency'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: BackupFrequency.values.map((frequency) {
            final isSelected = _settings!.frequency == frequency;
            return ListTile(
              title: Text(_getFrequencyText(frequency)),
              leading: Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: isSelected ? Theme.of(context).colorScheme.primary : null,
              ),
              onTap: () => Navigator.pop(context, frequency),
            );
          }).toList(),
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _settings!.frequency = result;
      });
      _saveSettings();
    }
  }

  Widget _buildEncryptionSection(ColorScheme colorScheme) {
    final isEncrypted = _encryptionStatus['enabled'] ?? false;
    final hasRecoveryKey = _encryptionStatus['hasRecoveryKey'] ?? false;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              colorScheme.surfaceContainer,
              colorScheme.surfaceContainer.withAlpha((255 * 0.8).round()),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.security,
                  color: colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Encryption & Security',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Encryption Toggle
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withAlpha((255 * 0.7).round()),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colorScheme.outline.withAlpha((255 * 0.3).round()),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isEncrypted ? Icons.lock : Icons.lock_open,
                    color: isEncrypted ? Colors.green : Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'End-to-End Encryption',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          isEncrypted 
                            ? 'Your backups are encrypted with AES-256'
                            : 'Enable encryption to secure your backups',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurface.withAlpha((255 * 0.7).round()),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: isEncrypted,
                    onChanged: _toggleEncryption,
                    activeTrackColor: Colors.green.shade300,
                    activeThumbColor: Colors.green,
                  ),
                ],
              ),
            ),

            if (isEncrypted) ...[
              const SizedBox(height: 12),
              
              // Recovery Key Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withAlpha((255 * 0.7).round()),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colorScheme.outline.withAlpha((255 * 0.3).round()),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          hasRecoveryKey ? Icons.key : Icons.key_off,
                          color: hasRecoveryKey ? Colors.green : Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Recovery Key',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                hasRecoveryKey 
                                  ? 'Recovery key generated - you can restore backups on new devices'
                                  : 'Generate a recovery key to restore backups on new devices',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurface.withAlpha((255 * 0.7).round()),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (!hasRecoveryKey) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _generateRecoveryKey,
                          icon: const Icon(Icons.key, size: 16),
                          label: const Text('Generate Recovery Key'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getFrequencyText(BackupFrequency frequency) {
    switch (frequency) {
      case BackupFrequency.daily:
        return 'Daily';
      case BackupFrequency.weekly:
        return 'Weekly';
      case BackupFrequency.monthly:
        return 'Monthly';
      case BackupFrequency.manual:
        return 'Manual only';
    }
  }
}