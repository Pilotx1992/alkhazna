import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/backup_status.dart';
import '../services/backup_service.dart';
import '../utils/backup_scheduler.dart';
import '../utils/notification_helper.dart';
import 'backup_progress_sheet.dart';

/// WhatsApp-style backup settings page
class BackupSettingsPage extends StatefulWidget {
  const BackupSettingsPage({super.key});

  @override
  State<BackupSettingsPage> createState() => _BackupSettingsPageState();
}

class _BackupSettingsPageState extends State<BackupSettingsPage> {
  final BackupService _backupService = BackupService();
  final NotificationHelper _notificationHelper = NotificationHelper();
  
  bool _isLoading = true;
  BackupFrequency _backupFrequency = BackupFrequency.weekly;
  NetworkPreference _networkPreference = NetworkPreference.wifiOnly;
  DateTime? _lastBackupTime;
  GoogleSignInAccount? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _notificationHelper.initialize();
  }

  Future<void> _loadSettings() async {
    try {
      await BackupScheduler.isAutoBackupEnabled();
      final frequency = await BackupScheduler.getBackupFrequency();
      final networkPref = await BackupScheduler.getNetworkPreference();
      final lastBackup = await BackupScheduler.getLastBackupTime();
      final user = _backupService.currentUser;

      setState(() {
        _backupFrequency = frequency;
        _networkPreference = networkPref;
        _lastBackupTime = lastBackup.millisecondsSinceEpoch > 0 ? lastBackup : null;
        _currentUser = user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Backup Settings'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildGoogleAccountSection(),
                const SizedBox(height: 16),
                _buildLastBackupInfo(),
                const SizedBox(height: 16),
                _buildBackupNowButton(),
                const SizedBox(height: 24),
                _buildAutoBackupSection(),
                const SizedBox(height: 16),
                _buildNetworkPreference(),
                const SizedBox(height: 24),
                _buildInfoSection(),
              ],
            ),
    );
  }

  Widget _buildGoogleAccountSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Google Account',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            if (_currentUser != null) ...[
              Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundImage: _currentUser!.photoUrl != null
                        ? NetworkImage(_currentUser!.photoUrl!)
                        : null,
                    backgroundColor: Colors.blue[100],
                    child: _currentUser!.photoUrl == null
                        ? const Icon(Icons.person, color: Colors.blue)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentUser!.displayName ?? 'Google User',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          _currentUser!.email!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _showChangeAccountDialog,
                    child: const Text('Change'),
                  ),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  const Icon(Icons.account_circle, size: 50, color: Colors.grey),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Not signed in',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _signInToGoogle,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(80, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: const Text('Sign In'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLastBackupInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Last Backup',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            if (_lastBackupTime != null) ...[
              Text(
                _formatBackupTime(_lastBackupTime!),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ] else ...[
              Text(
                'Never backed up',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBackupNowButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _currentUser != null ? _startBackupNow : null,
        icon: const Icon(Icons.backup, color: Colors.white),
        label: const Text(
          'Backup Now',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green[600],
          disabledBackgroundColor: Colors.grey[300],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildAutoBackupSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Auto Backup',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            RadioListTile<BackupFrequency>(
              title: const Text('Off'),
              value: BackupFrequency.off,
              groupValue: _backupFrequency,
              onChanged: _onBackupFrequencyChanged,
              contentPadding: EdgeInsets.zero,
            ),
            RadioListTile<BackupFrequency>(
              title: const Text('Daily'),
              value: BackupFrequency.daily,
              groupValue: _backupFrequency,
              onChanged: _onBackupFrequencyChanged,
              contentPadding: EdgeInsets.zero,
            ),
            RadioListTile<BackupFrequency>(
              title: const Text('Weekly'),
              value: BackupFrequency.weekly,
              groupValue: _backupFrequency,
              onChanged: _onBackupFrequencyChanged,
              contentPadding: EdgeInsets.zero,
            ),
            RadioListTile<BackupFrequency>(
              title: const Text('Monthly'),
              value: BackupFrequency.monthly,
              groupValue: _backupFrequency,
              onChanged: _onBackupFrequencyChanged,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkPreference() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Network Preference',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Wi-Fi only'),
              subtitle: const Text('Use Wi-Fi for backups to save mobile data'),
              value: _networkPreference == NetworkPreference.wifiOnly,
              onChanged: _onNetworkPreferenceChanged,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.security, color: Colors.blue[600], size: 20),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Secure & Private',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Your data is encrypted and stored securely in your Google Drive. Only you can access it.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.3,
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

  String _formatBackupTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }

  void _onBackupFrequencyChanged(BackupFrequency? frequency) async {
    if (frequency == null) return;

    setState(() {
      _backupFrequency = frequency;
    });

    await BackupScheduler.scheduleAutoBackup(frequency);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            frequency == BackupFrequency.off
                ? 'Auto backup disabled'
                : 'Auto backup set to ${frequency.displayName.toLowerCase()}',
          ),
          backgroundColor: Colors.green[600],
        ),
      );
    }
  }

  void _onNetworkPreferenceChanged(bool wifiOnly) async {
    final preference = wifiOnly ? NetworkPreference.wifiOnly : NetworkPreference.wifiAndMobile;
    
    setState(() {
      _networkPreference = preference;
    });

    await BackupScheduler.setNetworkPreference(preference);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wifiOnly 
                ? 'Backups will use Wi-Fi only'
                : 'Backups will use Wi-Fi and mobile data',
          ),
          backgroundColor: Colors.blue[600],
        ),
      );
    }
  }

  void _startBackupNow() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const BackupProgressSheet(),
    ).then((_) {
      // Refresh settings after backup
      _loadSettings();
    });
  }

  void _signInToGoogle() async {
    try {
      // The BackupService will handle Google Sign-In
      final success = await _backupService.isSignedIn;
      if (success) {
        _loadSettings();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to sign in to Google'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign-in error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showChangeAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Account'),
        content: const Text('Do you want to sign out and use a different Google account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _backupService.signOut();
              _loadSettings();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}