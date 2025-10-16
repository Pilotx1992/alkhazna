import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notification_settings_service.dart';

/// Screen for managing notification preferences
class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notificationService = Provider.of<NotificationSettingsService>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Manage your notification preferences',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Master Notifications Toggle
          Card(
            child: SwitchListTile(
              secondary: CircleAvatar(
                backgroundColor: Colors.indigo.shade50,
                child: Icon(
                  notificationService.notificationsEnabled
                      ? Icons.notifications_active
                      : Icons.notifications_off,
                  color: Colors.indigo,
                ),
              ),
              title: const Text('Enable Notifications'),
              subtitle: Text(
                notificationService.notificationsEnabled
                    ? 'Notifications are enabled'
                    : 'Notifications are disabled',
                style: TextStyle(
                  color: notificationService.notificationsEnabled
                      ? Colors.green
                      : Colors.grey[600],
                ),
              ),
              value: notificationService.notificationsEnabled,
              onChanged: (value) async {
                await notificationService.toggleNotifications();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        value
                            ? 'Notifications enabled'
                            : 'Notifications disabled',
                      ),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
              },
            ),
          ),

          const SizedBox(height: 24),

          // Notification Types Section
          Text(
            'Notification Types',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),

          Card(
            child: Column(
              children: [
                // Backup Notifications
                SwitchListTile(
                  secondary: CircleAvatar(
                    backgroundColor: Colors.blue.shade50,
                    child: Icon(Icons.backup, color: Colors.blue),
                  ),
                  title: const Text('Backup Notifications'),
                  subtitle: const Text('Get notified about backup status'),
                  value: notificationService.backupNotifications,
                  onChanged: notificationService.notificationsEnabled
                      ? (value) async {
                          await notificationService.toggleBackupNotifications();
                        }
                      : null,
                ),

                const Divider(height: 1),

                // Reminder Notifications
                SwitchListTile(
                  secondary: CircleAvatar(
                    backgroundColor: Colors.orange.shade50,
                    child: Icon(Icons.alarm, color: Colors.orange),
                  ),
                  title: const Text('Reminder Notifications'),
                  subtitle: const Text('Get reminders for data entry'),
                  value: notificationService.reminderNotifications,
                  onChanged: notificationService.notificationsEnabled
                      ? (value) async {
                          await notificationService.toggleReminderNotifications();
                        }
                      : null,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Info Card
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Notifications help you stay updated with important events in the app.',
                      style: TextStyle(
                        color: Colors.blue[900],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
