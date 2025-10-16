import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notification_settings_service.dart';

/// Screen for managing notification preferences
class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notificationService = Provider.of<NotificationSettingsService>(context);
    final cs = Theme.of(context).colorScheme;
    final sectionTitleColor = cs.onSurface.withValues(alpha: 0.85);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    cs.primary,
                    cs.primary.withValues(alpha: 0.8),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      // Back Button
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Title
                      Expanded(
                        child: Text(
                          'Notifications',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Master Notifications Section
                  _buildMasterNotificationsSection(
                    context,
                    notificationService,
                    cs,
                    sectionTitleColor,
                  ),

                  const SizedBox(height: 24),

                  // Notification Types Section
                  _buildNotificationTypesSection(
                    context,
                    notificationService,
                    cs,
                    sectionTitleColor,
                  ),

                  const SizedBox(height: 24),

                  // Info Banner
                  _buildInfoBanner(context, cs),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Master Notifications Section
  Widget _buildMasterNotificationsSection(
    BuildContext context,
    NotificationSettingsService service,
    ColorScheme cs,
    Color sectionTitleColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Text(
            'Master Settings',
            style: TextStyle(
              color: sectionTitleColor,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),

          // Master Toggle
          Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: service.notificationsEnabled
                      ? cs.primary.withValues(alpha: 0.12)
                      : Colors.grey.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  service.notificationsEnabled
                      ? Icons.notifications_active
                      : Icons.notifications_off,
                  color: service.notificationsEnabled
                      ? cs.primary
                      : Colors.grey,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enable Notifications',
                      style: TextStyle(
                        color: sectionTitleColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      service.notificationsEnabled
                          ? 'Notifications are enabled'
                          : 'Notifications are disabled',
                      style: TextStyle(
                        color: service.notificationsEnabled
                            ? Colors.green
                            : Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              // Switch
              Switch.adaptive(
                value: service.notificationsEnabled,
                activeColor: cs.primary,
                onChanged: (value) async {
                  await service.toggleNotifications();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          value
                              ? 'Notifications enabled'
                              : 'Notifications disabled',
                        ),
                        duration: const Duration(seconds: 1),
                        backgroundColor: cs.primary,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Notification Types Section
  Widget _buildNotificationTypesSection(
    BuildContext context,
    NotificationSettingsService service,
    ColorScheme cs,
    Color sectionTitleColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Text(
            'Notification Types',
            style: TextStyle(
              color: sectionTitleColor,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),

          // Backup Notifications
          _buildNotificationRow(
            icon: Icons.backup,
            iconColor: Colors.blue,
            title: 'Backup Notifications',
            subtitle: 'Get notified about backup status',
            value: service.backupNotifications,
            enabled: service.notificationsEnabled,
            onChanged: service.notificationsEnabled
                ? (value) async {
                    await service.toggleBackupNotifications();
                  }
                : null,
            sectionTitleColor: sectionTitleColor,
          ),

          const SizedBox(height: 16),
          Divider(height: 1, color: sectionTitleColor.withValues(alpha: 0.12)),
          const SizedBox(height: 16),

          // Reminder Notifications
          _buildNotificationRow(
            icon: Icons.alarm,
            iconColor: Colors.orange,
            title: 'Reminder Notifications',
            subtitle: 'Get reminders for data entry',
            value: service.reminderNotifications,
            enabled: service.notificationsEnabled,
            onChanged: service.notificationsEnabled
                ? (value) async {
                    await service.toggleReminderNotifications();
                  }
                : null,
            sectionTitleColor: sectionTitleColor,
          ),
        ],
      ),
    );
  }

  // Notification Row Widget
  Widget _buildNotificationRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required bool enabled,
    required void Function(bool)? onChanged,
    required Color sectionTitleColor,
  }) {
    return Row(
      children: [
        // Icon
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: enabled ? iconColor : Colors.grey,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),

        // Text
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: enabled
                      ? sectionTitleColor
                      : sectionTitleColor.withValues(alpha: 0.5),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: enabled
                      ? sectionTitleColor.withValues(alpha: 0.65)
                      : sectionTitleColor.withValues(alpha: 0.4),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),

        // Switch
        Switch.adaptive(
          value: value,
          activeColor: iconColor,
          onChanged: onChanged,
        ),
      ],
    );
  }

  // Info Banner
  Widget _buildInfoBanner(BuildContext context, ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.primary.withValues(alpha: 0.08),
            cs.primary.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cs.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: cs.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Notifications help you stay updated with important events in the app.',
              style: TextStyle(
                color: cs.primary.withValues(alpha: 0.9),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
