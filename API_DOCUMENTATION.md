# 📚 Al Khazna - API Documentation

## 📋 Table of Contents

1. [BackupService](#backupservice)
2. [SmartMergeService](#smartmergeservice)
3. [SafetyBackupService](#safetybackupservice)
4. [EncryptionService](#encryptionservice)
5. [GoogleDriveService](#googledriveservice)
6. [SecurityService](#securityservice)

---

## 🔄 BackupService

### **Overview**

Main service for orchestrating backup and restore operations.

### **Singleton Pattern**

```dart
final backupService = BackupService();
```

### **Methods**

#### **`startBackup()`**

Creates a backup and uploads it to Google Drive.

**Returns:** `Future<bool>` - Success status

**Example:**
```dart
final success = await backupService.startBackup();
if (success) {
  print('Backup completed successfully');
}
```

**Flow:**
1. Check connectivity
2. Authenticate with Google Drive
3. Load data from Hive
4. Serialize to JSON
5. Encrypt with AES-256-GCM
6. Upload to Google Drive
7. Save metadata
8. Clean up old backups

---

#### **`startRestore()`**

Downloads and restores backup from Google Drive.

**Returns:** `Future<RestoreResult>`

**Example:**
```dart
final result = await backupService.startRestore();
if (result.success) {
  print('Restore completed: ${result.summary}');
} else {
  print('Restore failed: ${result.errorMessage}');
}
```

**Flow:**
1. Create safety backup
2. Download backup from Google Drive
3. Decrypt backup
4. Validate data structure
5. Smart merge with local data
6. Save merged data to Hive
7. Delete safety backup (if successful)

---

#### **`rollbackFromSafetyBackup(String safetyBackupId)`**

Rollback to previous state using safety backup.

**Parameters:**
- `safetyBackupId`: ID of the safety backup to restore

**Returns:** `Future<bool>` - Success status

**Example:**
```dart
final success = await backupService.rollbackFromSafetyBackup(backupId);
if (success) {
  print('Rollback completed successfully');
}
```

---

#### **`findExistingBackup()`**

Find existing backup for current user.

**Returns:** `Future<BackupMetadata?>` - Backup metadata or null

**Example:**
```dart
final backup = await backupService.findExistingBackup();
if (backup != null) {
  print('Found backup: ${backup.createdAt}');
}
```

---

### **Properties**

#### **`currentProgress`**

Get current operation progress.

**Type:** `OperationProgress`

**Example:**
```dart
backupService.addListener(() {
  final progress = backupService.currentProgress;
  print('Progress: ${progress.percentage}%');
});
```

---

#### **`lastMergeResult`**

Get last merge operation result.

**Type:** `MergeResult?`

**Example:**
```dart
final result = backupService.lastMergeResult;
if (result != null) {
  print('Conflicts resolved: ${result.conflictsResolved}');
}
```

---

## 🔀 SmartMergeService

### **Overview**

WhatsApp-style intelligent merge for conflict resolution.

### **Singleton Pattern**

```dart
final mergeService = SmartMergeService();
```

### **Methods**

#### **`mergeIncomeEntries()`**

Merge income entries from backup with local data.

**Parameters:**
- `backupData`: Map of income entries from backup
- `localData`: Map of local income entries
- `tracker`: MergeTracker for statistics

**Returns:** `Future<Map<String, List<IncomeEntry>>>`

**Example:**
```dart
final tracker = MergeTracker()..start();
final merged = await mergeService.mergeIncomeEntries(
  backupData: backupIncomeData,
  localData: localIncomeData,
  tracker: tracker,
);
tracker.finish();
```

---

#### **`mergeOutcomeEntries()`**

Merge outcome entries from backup with local data.

**Parameters:**
- `backupData`: Map of outcome entries from backup
- `localData`: Map of local outcome entries
- `tracker`: MergeTracker for statistics

**Returns:** `Future<Map<String, List<OutcomeEntry>>>`

**Example:**
```dart
final tracker = MergeTracker()..start();
final merged = await mergeService.mergeOutcomeEntries(
  backupData: backupOutcomeData,
  localData: localOutcomeData,
  tracker: tracker,
);
tracker.finish();
```

---

### **Merge Algorithm**

1. **Create Maps:** O(1) lookup by ID
2. **Compare Entries:** By ID
3. **Resolve Conflicts:**
   - Compare version (higher wins)
   - Compare timestamp (newer wins)
   - Default to remote
4. **Track Statistics:**
   - Added entries
   - Updated entries
   - Conflicts resolved
   - Skipped duplicates

---

## 🛡️ SafetyBackupService

### **Overview**

Creates safety backups before critical operations.

### **Singleton Pattern**

```dart
final safetyService = SafetyBackupService();
```

### **Methods**

#### **`createPreRestoreBackup()`**

Create safety backup before restore operation.

**Returns:** `Future<String>` - Backup ID

**Example:**
```dart
final backupId = await safetyService.createPreRestoreBackup();
print('Safety backup created: $backupId');
```

**Storage:**
- Local: `safety_backups/pre_restore_YYYY-MM-DDTHH-MM-SS.json`
- Cloud: Firebase Storage (optional)

---

#### **`restoreFromSafetyBackup(String backupId)`**

Restore from safety backup.

**Parameters:**
- `backupId`: ID of the safety backup

**Returns:** `Future<bool>` - Success status

**Example:**
```dart
final success = await safetyService.restoreFromSafetyBackup(backupId);
if (success) {
  print('Restore from safety backup completed');
}
```

---

#### **`deleteSafetyBackup(String backupId)`**

Delete safety backup after successful restore.

**Parameters:**
- `backupId`: ID of the safety backup

**Returns:** `Future<bool>` - Success status

**Example:**
```dart
await safetyService.deleteSafetyBackup(backupId);
```

---

#### **`getAvailableSafetyBackups()`**

Get list of available safety backups.

**Returns:** `Future<List<SafetyBackupInfo>>`

**Example:**
```dart
final backups = await safetyService.getAvailableSafetyBackups();
for (final backup in backups) {
  print('Backup: ${backup.formattedDate}, Size: ${backup.formattedSize}');
}
```

---

### **SafetyBackupInfo**

```dart
class SafetyBackupInfo {
  final String backupId;
  final String filePath;
  final DateTime createdAt;
  final int fileSize;
  
  String get formattedSize;  // "1.5 MB"
  String get formattedDate;  // "19/01/2025 14:30"
}
```

---

## 🔐 EncryptionService

### **Overview**

Encrypts/decrypts backup data using AES-256-GCM.

### **Singleton Pattern**

```dart
final encryptionService = EncryptionService();
```

### **Methods**

#### **`encrypt(Uint8List data, String password)`**

Encrypt data with password.

**Parameters:**
- `data`: Data to encrypt
- `password`: Encryption password

**Returns:** `Future<Uint8List>` - Encrypted data

**Example:**
```dart
final encrypted = await encryptionService.encrypt(
  utf8.encode('sensitive data'),
  'my-password',
);
```

---

#### **`decrypt(Uint8List encryptedData, String password)`**

Decrypt data with password.

**Parameters:**
- `encryptedData`: Encrypted data
- `password`: Decryption password

**Returns:** `Future<Uint8List>` - Decrypted data

**Example:**
```dart
final decrypted = await encryptionService.decrypt(
  encryptedData,
  'my-password',
);
```

---

#### **`generateKey(String password, Uint8List salt)`**

Derive encryption key from password.

**Parameters:**
- `password`: Password
- `salt`: Salt for key derivation

**Returns:** `Uint8List` - Encryption key

**Algorithm:** PBKDF2 with 100,000 iterations

---

### **Encryption Details**

- **Algorithm:** AES-256-GCM
- **Key Derivation:** PBKDF2 (100,000 iterations)
- **IV Size:** 12 bytes (random)
- **Tag Size:** 16 bytes
- **Authentication:** GCM tag

---

## ☁️ GoogleDriveService

### **Overview**

Handles Google Drive operations.

### **Singleton Pattern**

```dart
final driveService = GoogleDriveService();
```

### **Methods**

#### **`initialize({Map<String, String>? authHeaders})`**

Initialize Google Drive service.

**Parameters:**
- `authHeaders`: Authentication headers (optional)

**Returns:** `Future<bool>` - Success status

**Example:**
```dart
final success = await driveService.initialize(
  authHeaders: authHeaders,
);
```

---

#### **`listFiles({String? query})`**

List files in Google Drive.

**Parameters:**
- `query`: Search query (optional)

**Returns:** `Future<List<DriveFile>>`

**Example:**
```dart
final files = await driveService.listFiles(
  query: "name contains 'backup'",
);
```

---

#### **`downloadFile(String fileId)`**

Download file from Google Drive.

**Parameters:**
- `fileId`: File ID

**Returns:** `Future<Uint8List?>` - File data

**Example:**
```dart
final data = await driveService.downloadFile(fileId);
```

---

#### **`uploadFile(String name, Uint8List data)`**

Upload file to Google Drive.

**Parameters:**
- `name`: File name
- `data`: File data

**Returns:** `Future<String?>` - File ID

**Example:**
```dart
final fileId = await driveService.uploadFile(
  'backup_2025-01-19.crypt14',
  encryptedData,
);
```

---

#### **`deleteFileById(String fileId)`**

Delete file from Google Drive.

**Parameters:**
- `fileId`: File ID

**Returns:** `Future<bool>` - Success status

**Example:**
```dart
await driveService.deleteFileById(fileId);
```

---

## 🔒 SecurityService

### **Overview**

Handles PIN and biometric authentication.

### **Singleton Pattern**

```dart
final securityService = SecurityService();
```

### **Methods**

#### **`verifyPIN(String pin)`**

Verify PIN.

**Parameters:**
- `pin`: PIN to verify

**Returns:** `Future<bool>` - Success status

**Example:**
```dart
final success = await securityService.verifyPIN('1234');
```

---

#### **`setPIN(String pin)`**

Set new PIN.

**Parameters:**
- `pin`: New PIN

**Returns:** `Future<bool>` - Success status

**Example:**
```dart
await securityService.setPIN('1234');
```

---

#### **`enableBiometric()`**

Enable biometric authentication.

**Returns:** `Future<bool>` - Success status

**Example:**
```dart
await securityService.enableBiometric();
```

---

#### **`disableBiometric()`**

Disable biometric authentication.

**Returns:** `Future<void>`

**Example:**
```dart
await securityService.disableBiometric();
```

---

#### **`isBiometricAvailable()`**

Check if biometric is available.

**Returns:** `Future<bool>`

**Example:**
```dart
final available = await securityService.isBiometricAvailable();
```

---

#### **`authenticateWithBiometric()`**

Authenticate with biometric.

**Returns:** `Future<bool>` - Success status

**Example:**
```dart
final success = await securityService.authenticateWithBiometric();
```

---

#### **`startSession()`**

Start security session.

**Returns:** `Future<void>`

**Session Duration:** 15 minutes

**Example:**
```dart
await securityService.startSession();
```

---

#### **`endSession()`**

End security session.

**Returns:** `Future<void>`

**Example:**
```dart
await securityService.endSession();
```

---

#### **`isSessionValid()`**

Check if session is valid.

**Returns:** `bool`

**Example:**
```dart
if (securityService.isSessionValid()) {
  // Access granted
}
```

---

### **Security Features**

- **PIN Hashing:** SHA-256 with salt
- **Lockout:** 5 failed attempts
- **Session Timeout:** 15 minutes
- **Biometric:** Fingerprint/Face ID
- **Auto-logout:** On app background

---

## 📊 Data Models

### **RestoreResult**

```dart
class RestoreResult {
  final bool success;
  final String? summary;
  final String? errorMessage;
  final int? incomeEntries;
  final int? outcomeEntries;
  final DateTime? backupDate;
  final String? sourceDevice;
}
```

### **MergeResult**

```dart
class MergeResult {
  final bool success;
  final int totalEntries;
  final int entriesFromBackup;
  final int entriesFromLocal;
  final int conflictsResolved;
  final int duplicatesSkipped;
  final Duration duration;
  final MergeStatistics statistics;
}
```

### **MergeStatistics**

```dart
class MergeStatistics {
  final int incomeAdded;
  final int incomeUpdated;
  final int incomeConflicts;
  final int incomeSkipped;
  final int outcomeAdded;
  final int outcomeUpdated;
  final int outcomeConflicts;
  final int outcomeSkipped;
  final List<ConflictDetail> conflicts;
  final DateTime startTime;
  final DateTime endTime;
  final Duration processingTime;
}
```

---

## 🔄 State Management

### **ChangeNotifier**

Services extend `ChangeNotifier` for reactive updates:

```dart
backupService.addListener(() {
  final progress = backupService.currentProgress;
  // Update UI
});
```

### **Provider**

Use `Provider` for dependency injection:

```dart
Provider(
  create: (_) => BackupService(),
  child: MyApp(),
)
```

### **Consumer**

Use `Consumer` for UI updates:

```dart
Consumer<BackupService>(
  builder: (context, service, child) {
    final progress = service.currentProgress;
    return Text('${progress.percentage}%');
  },
)
```

---

## 📝 Best Practices

### **Error Handling**

```dart
try {
  final result = await backupService.startRestore();
  if (result.success) {
    // Handle success
  } else {
    // Handle failure
    showError(result.errorMessage);
  }
} catch (e) {
  // Handle exception
  showError(e.toString());
}
```

### **Progress Updates**

```dart
backupService.addListener(() {
  final progress = backupService.currentProgress;
  updateProgressBar(progress.percentage);
});
```

### **Safety Backup**

```dart
// Before critical operation
final backupId = await safetyService.createPreRestoreBackup();

try {
  // Perform operation
  await riskyOperation();
  
  // Delete safety backup on success
  await safetyService.deleteSafetyBackup(backupId);
} catch (e) {
  // Restore from safety backup on failure
  await safetyService.restoreFromSafetyBackup(backupId);
}
```

---

## 📞 Support

For questions or issues:
- GitHub Issues
- Email: support@alkhazna.com
- Documentation: docs.alkhazna.com

---

**Last Updated:** 2025-01-19  
**Version:** 3.1.0  
**Status:** Production-Ready

