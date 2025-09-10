# Product Requirements Document (PRD) - FINAL VERSION
## WhatsApp-Style Backup & Restore System for AlKhazna (Flutter/Android)

### 1. Executive Summary

Implement a WhatsApp-inspired backup and restore system for AlKhazna Flutter Android app that automatically manages encryption keys via Google accounts, stores encrypted backups in Google Drive's hidden AppDataFolder, and provides seamless recovery across devices with clear user feedback.

### 2. Problem Statement

**Critical Issues:**
- Encryption keys stored locally are lost during app uninstalls
- Manual key management confuses non-technical users  
- Restore failures due to missing/invalid keys
- Auto-backup unreliability on Chinese OEMs (Huawei, Xiaomi, Oppo, Vivo)
- Lack of clear progress indicators and error messages

### 3. Solution Overview

- **Automatic key management** linked to Google account (email + Google ID)
- **Secure backup storage** in Google Drive AppDataFolder
- **WhatsApp-style UI** with clear progress and notifications
- **Reliable auto-backup** with fallback reminders for killed background tasks
- **User-friendly error messages** instead of technical logs

### 4. Technical Architecture

#### 4.1 Dependencies
```yaml
dependencies:
  # Google Sign-In & Drive
  google_sign_in: ^6.2.1
  googleapis: ^13.1.0
  googleapis_auth: ^1.6.0
  
  # Encryption
  cryptography: ^2.7.0
  flutter_secure_storage: ^9.2.2
  
  # Local Database
  sqflite: ^2.3.3
  path_provider: ^2.1.3
  
  # Background Tasks
  workmanager: ^0.5.2
  
  # Utilities
  connectivity_plus: ^6.0.3
  device_info_plus: ^10.1.0
  permission_handler: ^11.3.1
  
  # UI Components
  percent_indicator: ^4.2.3
  flutter_local_notifications: ^17.1.2
```

#### 4.2 Project Structure
```
lib/
├── backup/
│   ├── models/
│   │   ├── backup_metadata.dart
│   │   ├── backup_status.dart
│   │   ├── key_file_format.dart
│   │   └── restore_result.dart
│   ├── services/
│   │   ├── backup_service.dart
│   │   ├── encryption_service.dart
│   │   ├── google_drive_service.dart
│   │   └── key_manager.dart
│   ├── ui/
│   │   ├── backup_settings_page.dart
│   │   ├── backup_progress_sheet.dart
│   │   └── restore_dialog.dart
│   └── utils/
│       ├── backup_scheduler.dart
│       ├── notification_helper.dart
│       └── backup_constants.dart
```

### 5. Core Implementation Details

#### 5.1 Enhanced Key Manager

**Key File Format** (`alkhazna_backup_keys.encrypted`):
```json
{
  "version": 1.1,
  "user_email": "user@gmail.com",
  "normalized_email": "user",
  "google_id": "123456789",
  "device_id": "OnePlus-8T",
  "created_at": "2024-01-10T10:30:00Z",
  "checksum": "sha256-hash-of-key",
  "key_bytes": "base64-encoded-256bit-key"
}
```

**Key Management Strategy:**
- Generate 256-bit master key on first backup
- Bind to: email + normalized email + Google ID
- Store in both Google Drive AppDataFolder AND flutter_secure_storage
- Validate checksum on retrieval

#### 5.2 Backup File Naming Convention

- Database: `alkhazna_backup.db.crypt14` (clear naming)
- Key file: `alkhazna_backup_keys.encrypted`
- Media folder: `AlKhazna_Media/`

#### 5.3 Enhanced Restore Reliability

```dart
Future<BackupInfo?> findBackup() async {
  // 1. Always list AppDataFolder first
  final files = await driveApi.files.list(
    spaces: 'appDataFolder',
    q: "name='alkhazna_backup.db.crypt14'",
    orderBy: 'modifiedTime desc',
  );
  
  if (files.isEmpty) {
    // 2. Show clear message if no backup found
    showDialog(
      title: 'No Backup Found',
      message: 'No backup available for ${account.email}',
      actions: ['OK'],
    );
    return null;
  }
  
  // 3. Return most recent backup
  return files.first;
}
```

#### 5.4 Auto-Backup with OEM Workarounds

```dart
class BackupScheduler {
  // Primary: WorkManager
  static Future<void> scheduleAutoBackup(BackupFrequency frequency) async {
    await Workmanager().registerPeriodicTask(
      'auto_backup',
      'auto_backup',
      frequency: _getFrequency(frequency),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
      ),
    );
    
    // Fallback: Schedule reminder notification
    await _scheduleFallbackReminder(frequency);
  }
  
  // Fallback for aggressive OEMs
  static Future<void> _scheduleFallbackReminder(BackupFrequency frequency) async {
    final lastBackup = await getLastBackupTime();
    final daysSince = DateTime.now().difference(lastBackup).inDays;
    
    if (daysSince >= _getReminderDays(frequency)) {
      await NotificationHelper.showReminder(
        title: 'Backup Reminder',
        body: 'You haven\'t backed up in $daysSince days. Tap to back up now.',
        action: 'BACKUP_NOW',
      );
    }
  }
}
```

#### 5.5 Enhanced Notification System

```dart
class NotificationHelper {
  static const String CHANNEL_ID = 'alkhazna_backup_channel';
  
  static Future<void> showBackupProgress({
    required String stage,
    required int percentage,
    required String message,
  }) async {
    final icon = _getIconForStage(stage);
    
    await flutterLocalNotificationsPlugin.show(
      0,
      '$icon Backup in progress',
      '$message ($percentage%)',
      NotificationDetails(
        android: AndroidNotificationDetails(
          CHANNEL_ID,
          'Backup Notifications',
          ongoing: true,
          showProgress: true,
          maxProgress: 100,
          progress: percentage,
          autoCancel: false,
        ),
      ),
    );
  }
  
  static String _getIconForStage(String stage) {
    switch (stage) {
      case 'preparing': return '🔄';
      case 'encrypting': return '🔐';
      case 'uploading': return '☁️';
      case 'completed': return '✅';
      case 'failed': return '❌';
      default: return '📱';
    }
  }
}
```

### 6. User Interface Specifications

#### 6.1 Backup Settings Page
- **Google Account Section**: Show email, photo, change button
- **Last Backup Info**: Date, size, device name
- **Backup Now Button**: Green prominent button
- **Auto-backup Options**: Off/Daily/Weekly/Monthly radio buttons
- **Network Preference**: Wi-Fi only toggle

#### 6.2 Progress Indicators
- **Backup Progress**: Live percentage, stage icon, cancel button
- **Restore Progress**: Similar to backup with skip option
- **Notifications**: Mirror progress in notification shade

#### 6.3 Restore Dialog
- **Backup Found**: Show date, size, source device
- **Actions**: RESTORE (primary) / SKIP (secondary)
- **No Backup**: Clear message with OK button

### 7. Error Handling Matrix

| Error Type | User Message | Action |
|------------|--------------|--------|
| No Internet | "No connection. Please connect to Wi-Fi and try again." | Retry button |
| Sign-in Failed | "Google sign-in failed. Please try again." | Sign-in button |
| No Backup Found | "No backup available for this Google account." | OK button |
| Decryption Failed | "Could not decrypt backup. The backup may be corrupted." | Contact support |
| Drive Quota Exceeded | "Google Drive storage is full. Free up space and try again." | Manage storage |
| Upload Failed | "Upload failed. Check your connection and try again." | Retry button |

### 8. Android-Specific Configuration

#### 8.1 Permissions (AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
```

#### 8.2 OEM-Specific Handling
```dart
class OEMHelper {
  static bool requiresSpecialHandling() {
    final manufacturer = deviceInfo.manufacturer.toLowerCase();
    return ['xiaomi', 'oppo', 'vivo', 'huawei', 'realme']
        .contains(manufacturer);
  }
  
  static void requestAutoStartPermission() {
    if (requiresSpecialHandling()) {
      // Show dialog explaining battery optimization
      // Direct to settings if needed
    }
  }
}
```

### 9. Testing Strategy

#### 9.1 Test Scenarios
- Fresh install → Restore prompt appears
- Backup → Uninstall → Reinstall → Restore works
- Change device → Sign in → Restore works
- No internet → Clear error message
- WorkManager killed → Fallback notification appears

#### 9.2 Device Testing Matrix
- Samsung (standard Android)
- Xiaomi (MIUI aggressive killing)
- Oppo/Vivo (ColorOS restrictions)
- OnePlus (OxygenOS)
- Pixel (stock Android)

### 10. Performance Requirements

- **Backup Speed**: ≥500 KB/s (4G), ≥2 MB/s (WiFi)
- **Encryption Overhead**: <5% of total time
- **Memory Usage**: <50MB during operation
- **Battery Impact**: <2% per backup
- **Success Rate**: >98% backup, >99% restore

### 11. Success Metrics

- **Backup Success Rate**: >98%
- **Restore Success Rate**: >99%
- **Auto-backup Adoption**: >60% of users
- **Support Tickets**: <2% backup-related
- **User Satisfaction**: >4.5/5 rating for backup feature

### 12. Implementation Timeline

**Week 1-2**: Core infrastructure (encryption, Drive API)
**Week 3**: UI implementation
**Week 4**: Auto-backup and notifications
**Week 5**: OEM-specific fixes and fallbacks
**Week 6**: Testing and refinement

### 13. Key Improvements (vs Original PRD)

✅ **Enhanced key file format** with metadata validation
✅ **Clear file naming** (alkhazna_backup.db.crypt14)
✅ **Mandatory AppDataFolder listing** before restore
✅ **Fallback notifications** for OEM WorkManager issues
✅ **Progress notifications** for both backup and restore
✅ **User-friendly error messages** replacing technical logs
✅ **OEM-specific handling** for Chinese manufacturers
✅ **Checksum validation** for key integrity

This PRD ensures a robust, user-friendly backup system that handles real-world Android fragmentation and provides a seamless experience similar to WhatsApp.