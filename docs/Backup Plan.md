# Product Requirements Document (PRD) - FINAL VERSION
## Backup & Restore System for AlKhazna (Flutter/Android)

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

#### 6.4 Data Sharing Interface
- **Share Options Menu**: Export menu with multiple sharing formats
- **Time Range Selector**: Current Month / All Data / Custom Range
- **Format Selection**: PDF Report / Excel Sheet / JSON Data
- **Sharing Method**: WhatsApp, Bluetooth, Quick Share, Email, File Manager
- **Preview Option**: Data preview before sharing
- **Security Options**: Password protect shared files (optional)

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

### 14. Professional Data Sharing System

#### 14.1 Overview
Implement a comprehensive data sharing system that allows users to export and share their financial data through multiple channels with professional formatting and security options.

#### 14.2 Sharing Capabilities

**Time Range Options:**
- **Current Month**: Selected month data only
- **All Historical Data**: Complete financial history
- **Custom Range**: User-defined date range picker
- **Year Summary**: Annual financial reports

**Export Formats:**
```dart
enum ExportFormat {
  pdfReport,    // Professional formatted PDF
  excelSheet,   // Excel workbook with formulas
  csvData,      // Comma-separated values
  jsonData,     // Structured JSON format
}
```

**Sharing Methods:**
- **WhatsApp**: Direct share with message template
- **Bluetooth**: Nearby device sharing
- **Quick Share**: Android's native sharing
- **Email**: Automated email with attachments
- **File Manager**: Save to device storage
- **Cloud Storage**: Google Drive, Dropbox integration

#### 14.3 Technical Implementation

**Data Export Service:**
```dart
class DataExportService {
  // Generate comprehensive financial report
  static Future<ExportResult> generateReport({
    required DateRange dateRange,
    required ExportFormat format,
    required List<DataCategory> categories,
    ExportOptions? options,
  }) async {

    final data = await _collectData(dateRange, categories);

    switch (format) {
      case ExportFormat.pdfReport:
        return await _generatePDFReport(data, options);
      case ExportFormat.excelSheet:
        return await _generateExcelReport(data, options);
      case ExportFormat.csvData:
        return await _generateCSVReport(data, options);
      case ExportFormat.jsonData:
        return await _generateJSONReport(data, options);
    }
  }

  // Multi-platform sharing integration
  static Future<void> shareData({
    required ExportResult result,
    required SharingMethod method,
    String? customMessage,
  }) async {

    switch (method) {
      case SharingMethod.whatsapp:
        await _shareViaWhatsApp(result, customMessage);
        break;
      case SharingMethod.bluetooth:
        await _shareViaBluetooth(result);
        break;
      case SharingMethod.quickShare:
        await _shareViaQuickShare(result);
        break;
      case SharingMethod.email:
        await _shareViaEmail(result, customMessage);
        break;
      case SharingMethod.fileManager:
        await _saveToFileSystem(result);
        break;
    }
  }
}
```

**Professional PDF Generation:**
```dart
class ProfessionalPDFGenerator {
  static Future<Uint8List> generateFinancialReport({
    required FinancialData data,
    required ReportOptions options,
  }) async {

    final pdf = pw.Document();

    // Cover Page
    pdf.addPage(_buildCoverPage(data.dateRange, options));

    // Executive Summary
    pdf.addPage(_buildSummaryPage(data.summary));

    // Income Analysis
    if (data.hasIncomeData) {
      pdf.addPage(_buildIncomeAnalysis(data.income));
    }

    // Expense Analysis
    if (data.hasExpenseData) {
      pdf.addPage(_buildExpenseAnalysis(data.expenses));
    }

    // Charts and Visualizations
    pdf.addPage(_buildChartsPage(data.analytics));

    // Detailed Tables
    pdf.addPage(_buildDetailedTables(data));

    // Appendix
    pdf.addPage(_buildAppendix(data.metadata));

    return await pdf.save();
  }
}
```

**Excel Export with Formulas:**
```dart
class ExcelExportService {
  static Future<Uint8List> generateWorkbook({
    required FinancialData data,
    required ExcelOptions options,
  }) async {

    final excel = Excel.createExcel();

    // Summary Sheet
    final summarySheet = excel['Summary'];
    _buildSummarySheet(summarySheet, data.summary);

    // Income Sheet
    final incomeSheet = excel['Income'];
    _buildIncomeSheet(incomeSheet, data.income);

    // Expenses Sheet
    final expenseSheet = excel['Expenses'];
    _buildExpenseSheet(expenseSheet, data.expenses);

    // Charts Sheet
    final chartsSheet = excel['Analytics'];
    _buildChartsSheet(chartsSheet, data.analytics);

    // Add formulas and formatting
    _addFormulasAndFormatting(excel);

    return excel.save();
  }

  static void _addFormulasAndFormatting(Excel excel) {
    // Auto-sum formulas
    // Conditional formatting
    // Professional styling
    // Data validation
  }
}
```

#### 14.4 Sharing Integration

**WhatsApp Integration:**
```dart
class WhatsAppSharingService {
  static Future<void> shareFinancialReport({
    required ExportResult report,
    String? customMessage,
  }) async {

    final message = customMessage ?? _generateDefaultMessage(report);

    // Share via WhatsApp with custom message
    await Share.shareFiles(
      [report.filePath],
      text: message,
      sharePositionOrigin: Rect.zero,
      mimeTypes: [report.mimeType],
      subject: 'AlKhazna Financial Report - ${report.dateRange}',
    );
  }

  static String _generateDefaultMessage(ExportResult report) {
    return '''
💰 AlKhazna Financial Report
📅 Period: ${report.dateRange}
📊 Total Income: ${report.summary.totalIncome}
💸 Total Expenses: ${report.summary.totalExpenses}
💎 Net Balance: ${report.summary.netBalance}

Generated with AlKhazna App 📱
    ''';
  }
}
```

**Bluetooth & Quick Share:**
```dart
class NearbyShareService {
  static Future<void> shareViaBluetooth(ExportResult report) async {
    // Use Android's Bluetooth sharing
    await Share.shareFiles([report.filePath]);
  }

  static Future<void> shareViaQuickShare(ExportResult report) async {
    // Use Android's Quick Share (Nearby Share)
    await Share.shareFiles(
      [report.filePath],
      mimeTypes: [report.mimeType],
    );
  }
}
```

**Email Integration:**
```dart
class EmailSharingService {
  static Future<void> shareViaEmail({
    required ExportResult report,
    String? customMessage,
    List<String>? recipients,
  }) async {

    final Email email = Email(
      body: customMessage ?? _generateEmailBody(report),
      subject: 'Financial Report - ${report.dateRange}',
      recipients: recipients ?? [],
      attachmentPaths: [report.filePath],
      isHTML: true,
    );

    await FlutterEmailSender.send(email);
  }

  static String _generateEmailBody(ExportResult report) {
    return '''
    <h2>AlKhazna Financial Report</h2>
    <p><strong>Period:</strong> ${report.dateRange}</p>
    <p><strong>Generated:</strong> ${DateTime.now().toString()}</p>

    <h3>Summary:</h3>
    <ul>
      <li>Total Income: ${report.summary.totalIncome}</li>
      <li>Total Expenses: ${report.summary.totalExpenses}</li>
      <li>Net Balance: ${report.summary.netBalance}</li>
    </ul>

    <p>Please find the detailed report attached.</p>
    <p><em>Generated with AlKhazna Financial Tracker</em></p>
    ''';
  }
}
```

#### 14.5 Security & Privacy

**File Security:**
```dart
class SecureExportService {
  static Future<ExportResult> generateSecureReport({
    required FinancialData data,
    required ExportOptions options,
    String? password,
  }) async {

    final report = await _generateReport(data, options);

    if (password != null) {
      // Encrypt the file with password
      final encryptedData = await _encryptFile(report.data, password);
      return ExportResult(
        data: encryptedData,
        filename: '${report.filename}.encrypted',
        mimeType: 'application/octet-stream',
        isEncrypted: true,
      );
    }

    return report;
  }

  static Future<Uint8List> _encryptFile(Uint8List data, String password) async {
    // AES-256 encryption with password-derived key
    final key = await _deriveKey(password);
    final cipher = AESGCMCipher();
    return await cipher.encrypt(data, key);
  }
}
```

#### 14.6 User Experience Features

**Smart Sharing Suggestions:**
```dart
class SmartSharingService {
  static List<SharingMethod> getSuggestedMethods({
    required ExportFormat format,
    required int fileSize,
  }) {

    final suggestions = <SharingMethod>[];

    // Size-based recommendations
    if (fileSize < 25 * 1024 * 1024) { // 25MB
      suggestions.addAll([
        SharingMethod.whatsapp,
        SharingMethod.email,
      ]);
    }

    // Format-based recommendations
    if (format == ExportFormat.pdfReport) {
      suggestions.add(SharingMethod.whatsapp);
    }

    // Always available
    suggestions.addAll([
      SharingMethod.quickShare,
      SharingMethod.bluetooth,
      SharingMethod.fileManager,
    ]);

    return suggestions;
  }
}
```

**Sharing Analytics:**
```dart
class SharingAnalytics {
  static void trackShare({
    required SharingMethod method,
    required ExportFormat format,
    required DateRange dateRange,
  }) {
    // Track sharing patterns for UX improvements
    FirebaseAnalytics.instance.logEvent(
      name: 'data_shared',
      parameters: {
        'method': method.name,
        'format': format.name,
        'date_range': dateRange.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }
}
```

#### 14.7 Implementation Requirements

**Dependencies:**
```yaml
dependencies:
  # File sharing
  share_plus: ^7.2.1
  flutter_email_sender: ^6.0.2

  # File generation
  excel: ^2.1.0
  csv: ^5.0.2

  # Security
  encrypt: ^5.0.1
  crypto: ^3.0.3

  # UI Components
  file_picker: ^6.1.1
  path_provider: ^2.1.1
```

**Performance Requirements:**
- **Generation Speed**: <5 seconds for monthly reports, <15 seconds for annual reports
- **File Size**: PDF <5MB, Excel <10MB, CSV <2MB
- **Memory Usage**: <100MB during export process
- **Sharing Success Rate**: >99% for standard sharing methods

#### 14.8 Quality Assurance

**Testing Matrix:**
- **Format Testing**: All export formats with various data sizes
- **Sharing Testing**: All sharing methods across different Android versions
- **Security Testing**: Password protection and encryption validation
- **Performance Testing**: Large datasets (5+ years of data)
- **Compatibility Testing**: Different devices and OEM customizations

**Error Handling:**
- **File Generation Failures**: Clear error messages with retry options
- **Sharing Failures**: Alternative sharing method suggestions
- **Storage Issues**: Insufficient space warnings with cleanup options
- **Network Issues**: Offline queuing for cloud-based sharing

This comprehensive data sharing system ensures professional-grade export capabilities while maintaining user-friendly operation and robust security measures.