import 'package:flutter/material.dart';
import '../services/enhanced_backup_service.dart';

class BackupStatusWidget extends StatelessWidget {
  final bool showFullStatus;
  final VoidCallback? onTap;

  const BackupStatusWidget({
    super.key,
    this.showFullStatus = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: EnhancedBackupService(),
      builder: (context, child) {
        final service = EnhancedBackupService();
        
        if (showFullStatus) {
          return _buildFullStatusCard(context, service);
        } else {
          return _buildCompactStatus(context, service);
        }
      },
    );
  }

  Widget _buildCompactStatus(BuildContext context, EnhancedBackupService service) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: service.statusColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: service.statusColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (service.status == BackupStatus.syncing) ...[
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(service.statusColor),
                  value: service.syncProgress > 0 ? service.syncProgress : null,
                ),
              ),
            ] else ...[
              Icon(
                service.statusIcon,
                size: 16,
                color: service.statusColor,
              ),
            ],
            const SizedBox(width: 6),
            Text(
              _getCompactStatusText(service),
              style: TextStyle(
                color: service.statusColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullStatusCard(BuildContext context, EnhancedBackupService service) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: service.statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    service.statusIcon,
                    color: service.statusColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cloud Backup Status',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        service.statusMessage.isNotEmpty 
                            ? service.statusMessage 
                            : _getDefaultStatusMessage(service.status),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: service.statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (service.status == BackupStatus.syncing)
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(service.statusColor),
                      value: service.syncProgress > 0 ? service.syncProgress : null,
                    ),
                  ),
              ],
            ),
            
            if (service.hasAutoBackup) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              _buildAutoBackupInfo(context, service),
            ],
            
            if (service.status == BackupStatus.syncing) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: service.syncProgress > 0 ? service.syncProgress : null,
                backgroundColor: service.statusColor.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(service.statusColor),
              ),
              const SizedBox(height: 8),
              Text(
                '${(service.syncProgress * 100).round()}%',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAutoBackupInfo(BuildContext context, EnhancedBackupService service) {
    return Column(
      children: [
        Row(
          children: [
            Icon(
              Icons.schedule,
              size: 20,
              color: Colors.blue,
            ),
            const SizedBox(width: 8),
            Text(
              'Automatic Backup',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.blue,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Text(
                'Enabled',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildInfoTile(
                context,
                'Last Backup',
                service.getLastBackupTime(),
                Icons.backup,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInfoTile(
                context,
                'Next Backup',
                service.getTimeUntilNextBackup(),
                Icons.schedule,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoTile(BuildContext context, String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getCompactStatusText(EnhancedBackupService service) {
    switch (service.status) {
      case BackupStatus.idle:
        return 'Idle';
      case BackupStatus.syncing:
        return 'Syncing';
      case BackupStatus.success:
        return 'Synced';
      case BackupStatus.error:
        return 'Error';
      case BackupStatus.scheduled:
        return 'Scheduled';
    }
  }

  String _getDefaultStatusMessage(BackupStatus status) {
    switch (status) {
      case BackupStatus.idle:
        return 'Ready for backup';
      case BackupStatus.syncing:
        return 'Synchronizing data...';
      case BackupStatus.success:
        return 'All data synchronized';
      case BackupStatus.error:
        return 'Synchronization failed';
      case BackupStatus.scheduled:
        return 'Auto backup scheduled';
    }
  }
}

class BackupSettingsDialog extends StatefulWidget {
  const BackupSettingsDialog({super.key});

  @override
  State<BackupSettingsDialog> createState() => _BackupSettingsDialogState();
}

class _BackupSettingsDialogState extends State<BackupSettingsDialog> {
  bool _autoBackupEnabled = false;
  int _intervalHours = 24;

  @override
  void initState() {
    super.initState();
    final service = EnhancedBackupService();
    _autoBackupEnabled = service.hasAutoBackup;
    _intervalHours = service.currentSchedule?.interval.inHours ?? 24;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Backup Settings'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            title: const Text('Auto Backup'),
            subtitle: const Text('Automatically backup your data to the cloud'),
            value: _autoBackupEnabled,
            onChanged: (value) {
              setState(() {
                _autoBackupEnabled = value;
              });
            },
          ),
          if (_autoBackupEnabled) ...[
            const SizedBox(height: 16),
            const Text('Backup Frequency:'),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              initialValue: _intervalHours,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(value: 1, child: Text('Every hour')),
                DropdownMenuItem(value: 6, child: Text('Every 6 hours')),
                DropdownMenuItem(value: 12, child: Text('Every 12 hours')),
                DropdownMenuItem(value: 24, child: Text('Daily')),
                DropdownMenuItem(value: 168, child: Text('Weekly')),
              ],
              onChanged: (value) {
                setState(() {
                  _intervalHours = value ?? 24;
                });
              },
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final service = EnhancedBackupService();
            await service.enableAutoBackup(
              interval: Duration(hours: _intervalHours),
              enabled: _autoBackupEnabled,
            );
            if (mounted) Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}