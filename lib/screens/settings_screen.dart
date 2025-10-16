import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/security_service.dart';
import '../services/theme_service.dart';
import '../services/language_service.dart';
import '../backup/ui/backup_screen.dart';
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
                      _buildProfileCard(surfaceCard, sectionTitleColor, user, context),
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
                      const SizedBox(height: 16),
                      _buildAccountSection(surfaceCard, sectionTitleColor, authService, context),
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
  Widget _buildProfileCard(Color surfaceCard, Color sectionTitleColor, user, BuildContext context) {
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
                  backgroundImage: user?.profileImageUrl != null ? NetworkImage(user!.profileImageUrl!) : null,
                  backgroundColor: cs.primary.withValues(alpha: 0.12),
                  child: user?.profileImageUrl == null
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
                              ],
                            ),
                          ],
      ),
    );
  }

  // ---------------- Security Section ----------------
  Widget _buildSecuritySection(Color surfaceCard, Color sectionTitleColor, securityService, context) {
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
          Text('Security & Privacy', style: TextStyle(color: sectionTitleColor, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          row(
            icon: Icons.lock,
            title: 'App Lock (PIN)',
            trailing: Switch.adaptive(
                      value: securityService.isPinEnabled,
                      onChanged: (value) async {
                        if (value) {
                  // Enable PIN
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
                  // Disable PIN
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
          if (securityService.isPinEnabled) ...[
            row(
              icon: Icons.fingerprint,
              title: 'Biometric Unlock',
              topDivider: true,
              trailing: Switch.adaptive(
                      value: securityService.isBiometricEnabled,
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
            row(
              icon: Icons.pin,
              title: 'Change PIN',
              topDivider: true,
              trailing: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                    MaterialPageRoute(builder: (context) => const ChangePinScreen()),
                  );
                },
                child: Row(
                  children: [
                    Text(
                      'Update',
                      style: TextStyle(color: sectionTitleColor.withValues(alpha: 0.75)),
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

  // ---------------- Backup Section ----------------
  Widget _buildBackupSection(Color surfaceCard, Color sectionTitleColor, user, context) {
    final isConnected = user?.hasLinkedGoogleAccount == true;
    
    return Container(
      decoration: BoxDecoration(
        color: surfaceCard,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 18, offset: const Offset(0, 10))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Backup & Storage', style: TextStyle(color: sectionTitleColor, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          
          // Enhanced Backup Button with gradient
          GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                MaterialPageRoute(builder: (context) => const BackupScreen()),
              );
            },
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                gradient: isConnected
                    ? const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      )
                    : const LinearGradient(
                        colors: [Color(0xFF40BEFF), Color(0xFF12C9B6)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: (isConnected ? const Color(0xFF10B981) : const Color(0xFF12C9B6)).withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 1,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Status Icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isConnected ? Icons.cloud_done : Icons.cloud_upload,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Text Content
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isConnected ? 'Backup & Restore' : 'Connect Backup',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isConnected
                              ? 'Connected to ${user!.backupGoogleAccountEmail.split('@').first}'
                              : 'Enable cloud backup now',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  
                  // Arrow Icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Additional Info
          if (isConnected) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF10B981).withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.verified,
                    color: const Color(0xFF10B981),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your data is backed up and encrypted',
                      style: TextStyle(
                        color: sectionTitleColor.withValues(alpha: 0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
            trailing: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                  MaterialPageRoute(builder: (context) => const NotificationSettingsScreen()),
                      );
                    },
              child: Row(
                children: [
                  Text(
                    'Manage',
                    style: TextStyle(color: sectionTitleColor.withValues(alpha: 0.75)),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.chevron_right, color: sectionTitleColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Account Section ----------------
  Widget _buildAccountSection(Color surfaceCard, Color sectionTitleColor, authService, context) {
    final cs = Theme.of(context).colorScheme;

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
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
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
          Text('Account', style: TextStyle(color: sectionTitleColor, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          row(
            icon: Icons.info,
            title: 'About',
            iconColor: cs.primary,
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'Al Khazna',
                        applicationVersion: '1.0.0',
                applicationIcon: Icon(Icons.account_balance_wallet_outlined, size: 48, color: cs.primary),
                        children: [
                  const Text('A simple and elegant app for tracking your monthly income and expenses.'),
                        ],
                      );
                    },
                  ),
          row(
            icon: Icons.logout,
            title: 'Sign Out',
            iconColor: Colors.red,
            topDivider: true,
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
                  ),
                ],
      ),
    );
  }
}
