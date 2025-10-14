import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import '../services/backup_service.dart';
import '../models/backup_status.dart';
import '../utils/backup_scheduler.dart';
import '../utils/oem_helper.dart';
import 'backup_progress_sheet.dart';
import 'backup_verification_sheet.dart';
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
    });

    try {
      final isEnabled = await BackupScheduler.isAutoBackupEnabled();
      final frequency = await BackupScheduler.getBackupFrequency();
      final networkPref = await BackupScheduler.getNetworkPreference();
      final lastBackupLocal = await BackupScheduler.getLastBackupTime();
      final user = _backupService.currentUser;

      // If signed in, try to get last backup time from Google Drive
      DateTime? lastBackupDrive;
      if (_backupService.isSignedIn) {
        try {
          final meta = await _backupService.findExistingBackup();
          if (meta != null && meta.createdAt != null) {
            lastBackupDrive = meta.createdAt!.toLocal();
            if (kDebugMode) {
              print('✅ Drive backup time: $lastBackupDrive');
            }
          } else {
            if (kDebugMode) {
              print('⚠️ No backup metadata found on Drive');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('💥 Error fetching Drive backup time: $e');
          }
          // في حالة الخطأ، نحاول الاعتماد على الوقت المحلي
        }
      }

      // Prefer Drive timestamp (actual cloud backup time). Fallback to local if Drive not available.
      DateTime? effectiveLastBackup;
      if (lastBackupDrive != null && lastBackupDrive.millisecondsSinceEpoch > 0) {
        effectiveLastBackup = lastBackupDrive;
        if (kDebugMode) {
          print('📱 Using Drive timestamp: $lastBackupDrive');
        }
      } else if (lastBackupLocal.millisecondsSinceEpoch > 0) {
        effectiveLastBackup = lastBackupLocal;
        if (kDebugMode) {
          print('📱 Using Local timestamp: $lastBackupLocal');
        }
      } else {
        if (kDebugMode) {
          print('⚠️ No backup timestamp available (local or Drive)');
        }
      }

      // Keep local storage in sync with Drive timestamp when available
      if (lastBackupDrive != null) {
        await BackupScheduler.setLastBackupTime(lastBackupDrive);
        if (kDebugMode) {
          print('🔄 Synced local storage with Drive timestamp');
        }
      }

      setState(() {
        _isAutoBackupEnabled = isEnabled;
        _backupFrequency = frequency;
        _networkPreference = networkPref;
        _lastBackupTime = effectiveLastBackup;
        _currentUser = user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
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
          },
        ),
      );

      // Start backup
      await _backupService.startBackup();
    } catch (e) {
      // Handle error silently or show snackbar
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
          _loadSettings();
        },
      ),
    );
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
        // Show success message
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString();
        if (errorMessage.contains('File saved successfully')) {
          // Show success dialog with file location info
          _showFileLocationDialog(errorMessage.replaceFirst('Exception: ', ''));
        } else {
          // Handle error
        }
      }
    }
  }

  Future<void> _exportAllData() async {
    try {
      await DataSharingService.exportAllData();
      if (mounted) {
        // Show success message
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString();
        if (errorMessage.contains('File saved successfully')) {
          // Show success dialog with file location info
          _showFileLocationDialog(errorMessage.replaceFirst('Exception: ', ''));
        } else {
          // Handle error
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

  Future<void> _showFrequencySheet() async {
    final value = await showModalBottomSheet<BackupFrequency>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: BackupFrequency.values.map((frequency) {
              return ListTile(
                leading: Icon(_getFrequencyIcon(frequency)),
                title: Text(_getFrequencyText(frequency)),
                trailing: _backupFrequency == frequency
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () => Navigator.of(ctx).pop(frequency),
              );
            }).toList(),
          ),
        );
      },
    );

    if (value != null) {
      await BackupScheduler.scheduleAutoBackup(value);
      setState(() {
        _backupFrequency = value;
        _isAutoBackupEnabled = value != BackupFrequency.off;
      });
    }
  }

  Future<void> _showNetworkPreferenceSheet() async {
    final value = await showModalBottomSheet<NetworkPreference>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: NetworkPreference.values.map((preference) {
              return ListTile(
                leading: Icon(_getNetworkIcon(preference)),
                title: Text(_getNetworkText(preference)),
                trailing: _networkPreference == preference
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () => Navigator.of(ctx).pop(preference),
              );
            }).toList(),
          ),
        );
      },
    );

    if (value != null) {
      await BackupScheduler.setNetworkPreference(value);
      setState(() {
        _networkPreference = value;
      });
    }
  }

  IconData _getFrequencyIcon(BackupFrequency frequency) {
    switch (frequency) {
      case BackupFrequency.daily:
        return Icons.calendar_today_outlined;
      case BackupFrequency.weekly:
        return Icons.view_week_outlined;
      case BackupFrequency.monthly:
        return Icons.calendar_month_outlined;
      case BackupFrequency.off:
        return Icons.block_outlined;
    }
  }

  IconData _getNetworkIcon(NetworkPreference preference) {
    switch (preference) {
      case NetworkPreference.wifiOnly:
        return Icons.wifi;
      case NetworkPreference.wifiAndMobile:
        return Icons.network_cell;
    }
  }

  Future<void> _signInToGoogle() async {
    try {
      // Call the sign-in method
      final success = await _backupService.signIn();
      if (success) {
        _loadSettings();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to sign in to Google'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
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
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Open Google account chooser (without leaving the user signed out).
  Future<void> _chooseAccount() async {
    try {
      // Sign out first to force account chooser
      await _backupService.signOut();

      // Update UI to show signed out state (red dot)
      setState(() {
        _currentUser = null;
      });

      // Re-authenticate to show account picker
      await _signInToGoogle();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not switch account: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    const headerGrad = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF0D2A45), Color(0xFF133A5A)],
    );

    final surfaceCard = isDark ? const Color(0xFF1C2B39) : Colors.white;
    final sectionTitleColor = isDark ? Colors.white.withOpacity(0.92) : cs.onSurface;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0E1C28) : cs.surface,
      body: Stack(
        children: [
          // Header gradient background
          Container(height: 220, decoration: const BoxDecoration(gradient: headerGrad)),

          SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : Column(
                    children: [
                      // Fixed Google Account Section
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                                  color: Colors.white,
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Backup & Restore',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 48), // Placeholder for symmetry
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildAccountCard(surfaceCard, sectionTitleColor),
                          ],
                        ),
                      ),
                      
                      // Scrollable Content
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                children: [
                            _buildAutoBackupCard(surfaceCard, sectionTitleColor),
                            const SizedBox(height: 16),
                            _buildBackupActions(surfaceCard, sectionTitleColor),
                            const SizedBox(height: 16),
                            _buildDataManagement(surfaceCard, sectionTitleColor),

                            const SizedBox(height: 22),
                            Center(
                              child: Text(
                                'All Backups Are end-to-end Encrypted (AES-256-GCM)',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white.withOpacity(0.55) : cs.onSurfaceVariant,
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ---------------- Google Account Card ----------------
  Widget _buildAccountCard(Color surfaceCard, Color sectionTitleColor) {
    final cs = Theme.of(context).colorScheme;
    final user = _currentUser;
    final isConnected = user != null;
    final hasBackup = _lastBackupTime != null;

    return Container(
      decoration: BoxDecoration(
        color: surfaceCard,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 10)),
        ],
      ),
      padding: const EdgeInsets.all(16),
              child: Column(
                        children: [
                          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
              // الصورة في المنتصف
              Center(
                child: CircleAvatar(
                  radius: 22,
                  backgroundImage: user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null,
                  backgroundColor: cs.primary.withOpacity(0.12),
                  child: user?.photoUrl == null
                      ? Icon(isConnected ? Icons.person : Icons.cloud_off, color: cs.primary)
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              // النصوص تلف حول الصورة
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                                  children: [
                                    Text(
                          isConnected
                              ? (user.displayName?.isNotEmpty == true ? user.displayName! : 'Google User')
                              : 'Not connected',
                          style: TextStyle(color: sectionTitleColor, fontSize: 15.5, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isConnected ? const Color(0xFF10B981) : Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                                          Text(
                      isConnected ? user.email : 'Sign in to enable backup',
                      style: TextStyle(color: sectionTitleColor.withOpacity(0.65), fontSize: 13),
                    ),
                    if (isConnected) ...[
                      const SizedBox(height: 4),
                      Text(
                        hasBackup
                          ? 'Last backup: ${_formatBackupTime(_lastBackupTime!)}'
                          : 'Last backup: Never',
                        style: TextStyle(color: sectionTitleColor.withOpacity(0.72), fontSize: 13, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
              // زر Choose account في المنتصف العمودي
              Align(
                alignment: Alignment.center,
                child: IconButton(
                  tooltip: 'Choose account',
                  icon: Icon(Icons.settings, color: cs.primary),
                  onPressed: _chooseAccount,
                ),
                          ),
                        ],
                      ),
          if (!isConnected) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _signInToGoogle,
                icon: const Icon(Icons.login, size: 18),
                label: const Text('Sign in'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------- Auto Backup Card ----------------
  Widget _buildAutoBackupCard(Color surfaceCard, Color sectionTitleColor) {
    final cs = Theme.of(context).colorScheme;

    Widget row({
      required IconData icon,
      required String title,
      required Widget trailing,
      bool topDivider = false,
    }) {
      return Column(
                            children: [
          if (topDivider) Divider(height: 1, color: sectionTitleColor.withOpacity(0.12)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
                                  children: [
                Icon(icon, color: sectionTitleColor.withOpacity(0.8)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(color: sectionTitleColor, fontWeight: FontWeight.w600),
                  ),
                ),
                trailing,
                                  ],
                                ),
                              ),
        ],
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: surfaceCard,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 10))],
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Auto Backup', style: TextStyle(color: sectionTitleColor, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          row(
            icon: Icons.autorenew_rounded,
            title: 'Auto Backup',
            trailing: Switch.adaptive(
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
              activeColor: cs.primary,
                              ),
                          ),
                          if (_isAutoBackupEnabled) ...[
            row(
              icon: Icons.calendar_today_outlined,
              title: 'Backup Frequency',
              topDivider: true,
              trailing: GestureDetector(
                onTap: _showFrequencySheet,
                child: Row(
                  children: [
                    Text(
                      _getFrequencyText(_backupFrequency),
                      style: TextStyle(color: sectionTitleColor.withOpacity(0.75)),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.chevron_right, color: sectionTitleColor),
                  ],
                ),
              ),
            ),
            row(
              icon: Icons.wifi,
              title: 'Network',
              topDivider: true,
              trailing: GestureDetector(
                onTap: () => _showNetworkPreferenceSheet(),
                child: Row(
                  children: [
                    Text(
                      _getNetworkText(_networkPreference),
                      style: TextStyle(color: sectionTitleColor.withOpacity(0.75)),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.chevron_right, color: sectionTitleColor),
                        ],
                      ),
                    ),
                  ),
          ],
        ],
      ),
    );
  }

  // ---------------- Cloud Backup Actions ----------------
  Widget _buildBackupActions(Color surfaceCard, Color sectionTitleColor) {
    final cs = Theme.of(context).colorScheme;
    final enabled = _currentUser != null;

    return Container(
      decoration: BoxDecoration(
        color: surfaceCard,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 10))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cloud Backup Actions', style: TextStyle(color: sectionTitleColor, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),

          Opacity(
            opacity: enabled ? 1 : .55,
            child: GestureDetector(
              onTap: enabled ? _createBackup : null,
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF40BEFF), Color(0xFF12C9B6)]),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF12C9B6).withOpacity(0.35),
                      blurRadius: 24,
                      spreadRadius: 1,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_backupService.isBackupInProgress) ...[
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('Creating Backup...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15.5)),
                      ] else ...[
                        const Icon(Icons.cloud_upload_outlined, color: Colors.white, size: 22),
                        const SizedBox(width: 8),
                        const Text('Backup Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15.5)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          Opacity(
            opacity: enabled ? 1 : .55,
            child: OutlinedButton.icon(
              onPressed: enabled ? _restoreBackup : null,
              icon: Icon(Icons.restore, color: cs.primary),
              label: Text('Restore', style: TextStyle(color: cs.primary, fontWeight: FontWeight.w700, fontSize: 15)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                side: BorderSide(color: cs.primary, width: 1.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Data Management ----------------
  Widget _buildDataManagement(Color surfaceCard, Color sectionTitleColor) {
    const folderIconColor = Color(0xFF9C27B0); // Purple color for folder icon
    return Container(
      decoration: BoxDecoration(
        color: surfaceCard,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 10))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.folder_open, color: folderIconColor),
              const SizedBox(width: 8),
              Text('Data Management', style: TextStyle(color: sectionTitleColor, fontSize: 16, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _showExportOptions,
            icon: const Icon(Icons.upload, color: Color(0xFF2196F3)),
            label: const Text('Export Data', style: TextStyle(color: Color(0xFF2196F3), fontWeight: FontWeight.w700, fontSize: 15)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
             side: const BorderSide(color: Color(0xFF2196F3), width: 1.3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(45)),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _importData,
            icon: const Icon(Icons.file_download, color: Color(0xFF00C853)),
            label: const Text('Import Data', style: TextStyle(color: Color(0xFF00C853), fontWeight: FontWeight.w700, fontSize: 15)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              side: const BorderSide(color: Color(0xFF00C853), width: 1.3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(45)),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Helpers & actions ----------------
  String _formatBackupTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('dd MMM yyyy, HH:mm').format(time);
  }

}
