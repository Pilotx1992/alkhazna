import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/security_service.dart';
import '../services/theme_service.dart';
import '../services/language_service.dart';
import '../backup/ui/backup_screen.dart';
import '../backup/services/backup_service.dart';
import 'security/setup_pin_screen.dart';
import 'security/change_pin_screen.dart';
import 'security/verify_pin_screen.dart';
import 'notification_settings_screen.dart';
import 'login_screen.dart';

/// Comprehensive settings and user profile screen
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final securityService = Provider.of<SecurityService>(context);
    final themeService = Provider.of<ThemeService>(context);
    final languageService = Provider.of<LanguageService>(context);
    final user = authService.authState.currentUser;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    const headerGrad = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF0D2A45), Color(0xFF133A5A)],
    );

    final surfaceCard = isDark ? const Color(0xFF1C2B39) : Colors.white;
    final sectionTitleColor = isDark ? Colors.white.withValues(alpha: 0.92) : cs.onSurface;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0E1C28) : cs.surface,
      body: Stack(
        children: [
          // Header gradient background
          Container(height: 220, decoration: const BoxDecoration(gradient: headerGrad)),

          SafeArea(
            child: Column(
              children: [
                // Fixed Profile Section
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
                              'Settings',
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
                      _buildProfileCard(surfaceCard, sectionTitleColor, user, context, authService),
                    ],
                  ),
                ),
                
                // Scrollable Content
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    children: [
                      const SizedBox(height: 16),
                      _buildSecuritySection(surfaceCard, sectionTitleColor, securityService, context),
                      const SizedBox(height: 16),
                      _buildBackupSection(surfaceCard, sectionTitleColor, user, context),
                      const SizedBox(height: 16),
                      _buildAppSettingsSection(surfaceCard, sectionTitleColor, themeService, languageService, context),
                      const SizedBox(height: 32),
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

  // ---------------- Profile Card ----------------
  Widget _buildProfileCard(Color surfaceCard, Color sectionTitleColor, user, BuildContext context, authService) {
    final cs = Theme.of(context).colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        color: surfaceCard,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile Avatar
              Center(
                child: CircleAvatar(
                  radius: 22,
                  backgroundImage: user?.profileImageUrl != null && user!.profileImageUrl!.isNotEmpty
                      ? NetworkImage(user!.profileImageUrl!)
                      : null,
                  backgroundColor: cs.primary.withValues(alpha: 0.12),
                  child: user?.profileImageUrl == null || user!.profileImageUrl!.isEmpty
                      ? Icon(
                          user?.username.isNotEmpty == true ? Icons.person : Icons.account_circle,
                          color: cs.primary,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          user?.username ?? 'User',
                          style: TextStyle(
                            color: sectionTitleColor,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (user?.hasLinkedGoogleAccount == true)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user?.email ?? 'No email',
                      style: TextStyle(
                        color: sectionTitleColor.withValues(alpha: 0.65),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Sign Out Icon Button (top right)
              InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Sign Out'),
                      content: const Text('Are you sure you want to sign out?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            await authService.signOut();
                            if (context.mounted) {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(builder: (context) => const LoginScreen()),
                                (route) => false,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                          child: const Text('Sign Out'),
                        ),
                      ],
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(24),
                splashColor: Colors.red.withValues(alpha: 0.1),
                highlightColor: Colors.red.withValues(alpha: 0.05),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(Icons.logout, color: Colors.red, size: 24),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------- Security Section ----------------
  Widget _buildSecuritySection(Color surfaceCard, Color sectionTitleColor, SecurityService securityService, BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isPinEnabled = securityService.isPinEnabled;
    final isBiometricEnabled = securityService.isBiometricEnabled;
    final autoLockTimeout = securityService.autoLockTimeout;
    final sessionDuration = securityService.sessionDuration;

    Widget row({
      required IconData icon,
      required String title,
      String? subtitle,
      required Widget trailing,
      bool topDivider = false,
    }) {
      return Column(
        children: [
          if (topDivider) Divider(height: 1, color: sectionTitleColor.withValues(alpha: 0.12)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: sectionTitleColor.withValues(alpha: 0.8)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(color: sectionTitleColor, fontWeight: FontWeight.w600),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: sectionTitleColor.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
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
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 18, offset: const Offset(0, 10))],
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Security & Privacy', style: TextStyle(color: sectionTitleColor, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),

          // PIN Lock Toggle
          row(
            icon: Icons.lock,
            title: 'App Lock (PIN)',
            subtitle: isPinEnabled ? 'Secure app with 4-digit PIN' : 'Disabled',
            trailing: Switch.adaptive(
              value: isPinEnabled,
              onChanged: (value) async {
                if (value) {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SetupPinScreen()),
                  );
                  if (result == true && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('PIN protection enabled!'), backgroundColor: Colors.green),
                    );
                  }
                } else {
                  final verified = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(builder: (context) => const VerifyPinScreen(title: 'Verify PIN to Disable')),
                  );
                  if (verified == true && context.mounted) {
                    await securityService.deletePin();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('PIN protection disabled'), backgroundColor: Colors.orange),
                      );
                    }
                  }
                }
              },
              activeThumbColor: cs.primary,
            ),
          ),

          if (isPinEnabled) ...[
            // Biometric Unlock
            row(
              icon: Icons.fingerprint,
              title: 'Biometric Unlock',
              subtitle: isBiometricEnabled ? 'Use fingerprint for quick access' : 'Disabled',
              topDivider: true,
              trailing: Switch.adaptive(
                value: isBiometricEnabled,
                onChanged: (value) async {
                  try {
                    if (value) {
                      await securityService.enableBiometric();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Biometric unlock enabled!'), backgroundColor: Colors.green),
                        );
                      }
                    } else {
                      await securityService.disableBiometric();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Biometric unlock disabled'), backgroundColor: Colors.orange),
                        );
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
                activeThumbColor: cs.primary,
              ),
            ),

            // Change PIN
            row(
              icon: Icons.pin,
              title: 'Change PIN',
              topDivider: true,
              trailing: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ChangePinScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Update',
                        style: TextStyle(color: sectionTitleColor.withValues(alpha: 0.75)),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.chevron_right, color: sectionTitleColor, size: 16),
                    ],
                  ),
                ),
              ),
            ),

            // Section divider
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Divider(height: 1, thickness: 2, color: sectionTitleColor.withValues(alpha: 0.2)),
            ),

            // Auto-Lock Settings Header
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 6),
              child: Text(
                'AUTO-LOCK SETTINGS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: sectionTitleColor.withValues(alpha: 0.6),
                  letterSpacing: 1.2,
                ),
              ),
            ),

            // Auto-Lock Timer
            row(
              icon: Icons.timer,
              title: 'Auto-Lock Timer',
              subtitle: _getAutoLockDescription(autoLockTimeout),
              trailing: InkWell(
                onTap: () => _showAutoLockDialog(context, securityService, sectionTitleColor, cs),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getAutoLockShort(autoLockTimeout),
                        style: TextStyle(color: sectionTitleColor.withValues(alpha: 0.75)),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.chevron_right, color: sectionTitleColor, size: 16),
                    ],
                  ),
                ),
              ),
            ),

            // Session Duration
            row(
              icon: Icons.schedule,
              title: 'Session Duration',
              subtitle: 'Stay unlocked for $sessionDuration min',
              topDivider: true,
              trailing: InkWell(
                onTap: () => _showSessionDurationDialog(context, securityService, sectionTitleColor, cs),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$sessionDuration min',
                        style: TextStyle(color: sectionTitleColor.withValues(alpha: 0.75)),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.chevron_right, color: sectionTitleColor, size: 16),
                    ],
                  ),
                ),
              ),
            ),

            // Section divider
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Divider(height: 1, thickness: 2, color: sectionTitleColor.withValues(alpha: 0.2)),
            ),

            // Quick Actions Header
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 12),
              child: Text(
                'QUICK ACTIONS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: sectionTitleColor.withValues(alpha: 0.6),
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getAutoLockDescription(int seconds) {
    if (seconds == 0) return 'Lock immediately';
    if (seconds == 30) return 'Lock after 30 seconds';
    if (seconds == 60) return 'Lock after 1 minute';
    if (seconds == 300) return 'Lock after 5 minutes';
    if (seconds < 0 || seconds > 3600) return 'Never auto-lock';
    return 'Lock after $seconds seconds';
  }

  String _getAutoLockShort(int seconds) {
    if (seconds == 0) return 'Immediate';
    if (seconds == 30) return '30 sec';
    if (seconds == 60) return '1 min';
    if (seconds == 300) return '5 min';
    if (seconds < 0 || seconds > 3600) return 'Never';
    return '${seconds}s';
  }

  Future<void> _showAutoLockDialog(
    BuildContext context,
    SecurityService securityService,
    Color sectionTitleColor,
    ColorScheme cs,
  ) async {
    final currentValue = securityService.autoLockTimeout;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Auto-Lock Timer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ignore: deprecated_member_use
            RadioListTile<int>(
              title: const Text('Immediate'),
              subtitle: const Text('Lock right away'),
              value: 0,
              // ignore: deprecated_member_use
              groupValue: currentValue,
              activeColor: cs.primary,
              // ignore: deprecated_member_use
              onChanged: (value) {
                securityService.setAutoLockTimeout(value!);
                Navigator.pop(context);
              },
            ),
            // ignore: deprecated_member_use
            RadioListTile<int>(
              title: const Text('30 seconds'),
              subtitle: const Text('For quick task switching'),
              value: 30,
              // ignore: deprecated_member_use
              groupValue: currentValue,
              activeColor: cs.primary,
              // ignore: deprecated_member_use
              onChanged: (value) {
                securityService.setAutoLockTimeout(value!);
                Navigator.pop(context);
              },
            ),
            // ignore: deprecated_member_use
            RadioListTile<int>(
              title: const Text('1 minute'),
              subtitle: const Text('For moderate multitasking'),
              value: 60,
              // ignore: deprecated_member_use
              groupValue: currentValue,
              activeColor: cs.primary,
              // ignore: deprecated_member_use
              onChanged: (value) {
                securityService.setAutoLockTimeout(value!);
                Navigator.pop(context);
              },
            ),
            // ignore: deprecated_member_use
            RadioListTile<int>(
              title: const Text('5 minutes'),
              subtitle: const Text('For active usage'),
              value: 300,
              // ignore: deprecated_member_use
              groupValue: currentValue,
              activeColor: cs.primary,
              // ignore: deprecated_member_use
              onChanged: (value) {
                securityService.setAutoLockTimeout(value!);
                Navigator.pop(context);
              },
            ),
            // ignore: deprecated_member_use
            RadioListTile<int>(
              title: const Text('Never'),
              subtitle: const Text('Disable auto-lock'),
              value: -1,
              // ignore: deprecated_member_use
              groupValue: currentValue,
              activeColor: cs.primary,
              // ignore: deprecated_member_use
              onChanged: (value) {
                securityService.setAutoLockTimeout(value!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSessionDurationDialog(
    BuildContext context,
    SecurityService securityService,
    Color sectionTitleColor,
    ColorScheme cs,
  ) async {
    final currentValue = securityService.sessionDuration;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Session Duration'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ignore: deprecated_member_use
            RadioListTile<int>(
              title: const Text('5 minutes'),
              subtitle: const Text('Short sessions'),
              value: 5,
              // ignore: deprecated_member_use
              groupValue: currentValue,
              activeColor: cs.primary,
              // ignore: deprecated_member_use
              onChanged: (value) {
                securityService.setSessionDuration(value!);
                Navigator.pop(context);
              },
            ),
            // ignore: deprecated_member_use
            RadioListTile<int>(
              title: const Text('15 minutes'),
              subtitle: const Text('Balanced (recommended)'),
              value: 15,
              // ignore: deprecated_member_use
              groupValue: currentValue,
              activeColor: cs.primary,
              // ignore: deprecated_member_use
              onChanged: (value) {
                securityService.setSessionDuration(value!);
                Navigator.pop(context);
              },
            ),
            // ignore: deprecated_member_use
            RadioListTile<int>(
              title: const Text('30 minutes'),
              subtitle: const Text('Extended work'),
              value: 30,
              // ignore: deprecated_member_use
              groupValue: currentValue,
              activeColor: cs.primary,
              // ignore: deprecated_member_use
              onChanged: (value) {
                securityService.setSessionDuration(value!);
                Navigator.pop(context);
              },
            ),
            // ignore: deprecated_member_use
            RadioListTile<int>(
              title: const Text('1 hour'),
              subtitle: const Text('Long tasks'),
              value: 60,
              // ignore: deprecated_member_use
              groupValue: currentValue,
              activeColor: cs.primary,
              // ignore: deprecated_member_use
              onChanged: (value) {
                securityService.setSessionDuration(value!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
        ],
      ),
    );
  }

  // ---------------- Backup Section ----------------
  Widget _buildBackupSection(Color surfaceCard, Color sectionTitleColor, user, context) {
    Widget row({
      required IconData icon,
      required String title,
      required VoidCallback onTap,
      Color? iconColor,
      bool topDivider = false,
    }) {
      return Column(
        children: [
          if (topDivider) Divider(height: 1, color: sectionTitleColor.withValues(alpha: 0.12)),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
              child: Row(
                children: [
                  Icon(icon, color: iconColor ?? sectionTitleColor.withValues(alpha: 0.8)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(color: sectionTitleColor, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Icon(Icons.chevron_right, color: sectionTitleColor),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: surfaceCard,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 18, offset: const Offset(0, 10))],
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Backup & Storage', style: TextStyle(color: sectionTitleColor, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          row(
            icon: Icons.backup,
            title: 'Backup & Restore',
            onTap: () async {
              // Show loading indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Signing in to Google...'),
                        ],
                      ),
                    ),
                  ),
                ),
              );

              try {
                // Auto sign in silently
                final backupService = BackupService();
                final isSignedIn = await backupService.performAutoSignIn();
                
                // Close loading dialog
                if (context.mounted) Navigator.of(context).pop();
                
                if (isSignedIn) {
                  // Navigate to backup screen
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const BackupScreen()),
                  );
                } else {
                  // Show error message
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to sign in to Google. Please try again.'),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                }
              } catch (e) {
                // Close loading dialog
                if (context.mounted) Navigator.of(context).pop();
                
                // Show error message
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  // ---------------- App Settings Section ----------------
  Widget _buildAppSettingsSection(Color surfaceCard, Color sectionTitleColor, themeService, languageService, context) {
    final cs = Theme.of(context).colorScheme;

    Widget row({
      required IconData icon,
      required String title,
      required Widget trailing,
      bool topDivider = false,
    }) {
      return Column(
        children: [
          if (topDivider) Divider(height: 1, color: sectionTitleColor.withValues(alpha: 0.12)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
                children: [
                Icon(icon, color: sectionTitleColor.withValues(alpha: 0.8)),
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
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 18, offset: const Offset(0, 10))],
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('App Settings', style: TextStyle(color: sectionTitleColor, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          row(
            icon: themeService.isDarkMode ? Icons.dark_mode : Icons.light_mode,
            title: 'Theme',
            trailing: Switch.adaptive(
                      value: themeService.isDarkMode,
                      onChanged: (value) async {
                        await themeService.toggleTheme();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                      content: Text('Switched to ${value ? "dark" : "light"} mode'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        }
                      },
              activeThumbColor: cs.primary,
            ),
          ),
          row(
            icon: Icons.language,
            title: 'Language',
            topDivider: true,
            trailing: Switch.adaptive(
                      value: languageService.isArabic,
                      onChanged: (value) async {
                        await languageService.toggleLanguage();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                      content: Text('Switched to ${value ? "Arabic" : "English"}'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        }
                      },
              activeThumbColor: cs.primary,
            ),
          ),
          row(
            icon: Icons.notifications,
            title: 'Notifications',
            topDivider: true,
            trailing: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NotificationSettingsScreen()),
                );
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Manage',
                      style: TextStyle(color: sectionTitleColor.withValues(alpha: 0.75)),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.chevron_right, color: sectionTitleColor, size: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

}
