import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/scheduled_backup_service.dart';

class ScheduledBackupSettings extends StatefulWidget {
  const ScheduledBackupSettings({super.key});

  @override
  State<ScheduledBackupSettings> createState() => _ScheduledBackupSettingsState();
}

class _ScheduledBackupSettingsState extends State<ScheduledBackupSettings> {
  final ScheduledBackupService _scheduledService = ScheduledBackupService();
  
  bool _isEnabled = false;
  String _frequency = 'daily';
  DateTime? _nextBackup;
  DateTime? _lastBackup;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadScheduleInfo();
  }

  Future<void> _loadScheduleInfo() async {
    try {
      await _scheduledService.initialize();
      final info = await _scheduledService.getScheduleInfo();
      
      if (mounted) {
        setState(() {
          _isEnabled = info['enabled'] ?? false;
          _frequency = info['frequency'] ?? 'daily';
          _nextBackup = info['nextBackup'];
          _lastBackup = info['lastBackup'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load schedule info: $e')),
        );
      }
    }
  }

  Future<void> _toggleScheduledBackups(bool enabled) async {
    try {
      if (enabled) {
        await _scheduledService.enableScheduledBackups(_frequency);
      } else {
        await _scheduledService.disableScheduledBackups();
      }
      
      await _loadScheduleInfo(); // Refresh the info
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(enabled 
              ? 'Scheduled backups enabled' 
              : 'Scheduled backups disabled'
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _updateFrequency(String newFrequency) async {
    try {
      setState(() {
        _frequency = newFrequency;
      });
      
      if (_isEnabled) {
        await _scheduledService.enableScheduledBackups(newFrequency);
        await _loadScheduleInfo();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Backup frequency updated to $newFrequency')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating frequency: $e')),
        );
      }
    }
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Never';
    
    final now = DateTime.now();
    final difference = dateTime.difference(now);
    
    if (difference.inDays > 7) {
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    } else if (difference.inDays > 0) {
      return 'in ${difference.inDays} day${difference.inDays == 1 ? '' : 's'}';
    } else if (difference.inHours > 0) {
      return 'in ${difference.inHours} hour${difference.inHours == 1 ? '' : 's'}';
    } else if (difference.inMinutes > 0) {
      return 'in ${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'}';
    } else if (difference.inDays < 0) {
      final daysPast = difference.inDays.abs();
      if (daysPast > 7) {
        return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
      } else {
        return '$daysPast day${daysPast == 1 ? '' : 's'} ago';
      }
    } else {
      return 'Soon';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  color: _isEnabled ? Colors.green : Colors.grey,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Scheduled Backups',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Automatically backup your data',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isEnabled,
                  onChanged: _toggleScheduledBackups,
                ),
              ],
            ),

            if (_isEnabled) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),

              // Frequency Selection
              Text(
                'Backup Frequency',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              DropdownButtonFormField<String>(
                initialValue: _frequency,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: const [
                  DropdownMenuItem(value: 'daily', child: Text('Daily')),
                  DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                  DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    _updateFrequency(value);
                  }
                },
              ),

              const SizedBox(height: 16),

              // Schedule Information
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Next Backup:'),
                        Text(
                          _formatDateTime(_nextBackup),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Last Backup:'),
                        Text(
                          _formatDateTime(_lastBackup),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _lastBackup != null ? Colors.green : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Important Notes
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Important Notes',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Scheduled backups require network connection\n'
                      '• Backups will pause when battery is low\n'
                      '• You\'ll receive notifications for backup status\n'
                      '• Manual backups are always available',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}