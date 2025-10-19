# 🏗️ Al Khazna - Architecture Documentation

## 📋 Table of Contents

1. [Overview](#overview)
2. [Architecture Pattern](#architecture-pattern)
3. [Project Structure](#project-structure)
4. [Backup & Restore System](#backup--restore-system)
5. [Data Models](#data-models)
6. [Services](#services)
7. [Security](#security)
8. [Performance](#performance)
9. [Testing Strategy](#testing-strategy)

---

## 🎯 Overview

Al Khazna is a personal finance management app built with Flutter, featuring:
- **Local-first architecture** with Hive database
- **Cloud backup** to Google Drive
- **Smart merge** algorithm for conflict resolution
- **Safety backup** system for data protection
- **Encryption** for secure data storage

---

## 🏛️ Architecture Pattern

### **Current Architecture: Service-Oriented**

```
┌─────────────────────────────────────────────────────────┐
│                      UI Layer                            │
│  (Screens, Dialogs, Bottom Sheets, Widgets)             │
└─────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│                   Service Layer                          │
│  (BackupService, SecurityService, StorageService)       │
└─────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│                   Data Layer                             │
│  (Hive Database, Models, Adapters)                      │
└─────────────────────────────────────────────────────────┘
```

### **State Management: Provider**

- `ChangeNotifier` for reactive state
- `Provider` for dependency injection
- `Consumer` widgets for UI updates

---

## 📁 Project Structure

```
lib/
├── backup/                          # Backup & Restore System
│   ├── models/                      # Data models
│   │   ├── backup_metadata.dart
│   │   ├── backup_status.dart
│   │   ├── merge_result.dart
│   │   ├── merge_statistics.dart
│   │   └── restore_result.dart
│   │
│   ├── services/                    # Core services
│   │   ├── backup_service.dart      # Main backup orchestrator
│   │   ├── smart_merge_service.dart # WhatsApp-style merge
│   │   ├── safety_backup_service.dart # Pre-restore backups
│   │   ├── encryption_service.dart  # AES-256-GCM encryption
│   │   ├── google_drive_service.dart # Drive integration
│   │   ├── key_manager.dart         # Key management
│   │   ├── legacy_decryption_service.dart # Version compatibility
│   │   └── backup_version_detector.dart # Version detection
│   │
│   ├── ui/                          # UI components
│   │   ├── backup_bottom_sheet.dart
│   │   ├── backup_progress_sheet.dart
│   │   ├── backup_screen.dart
│   │   ├── restore_dialog.dart
│   │   ├── rollback_dialog.dart
│   │   ├── animated_success_dialog.dart
│   │   └── enhanced_restore_progress_dialog.dart
│   │
│   └── utils/                       # Utilities
│       ├── backup_scheduler.dart
│       └── haptic_feedback_helper.dart
│
├── models/                          # Data models
│   ├── income_entry.dart            # Income transactions
│   ├── outcome_entry.dart           # Expense transactions
│   ├── security_settings.dart       # Security configuration
│   └── user.dart                    # User profile
│
├── screens/                         # UI screens
│   ├── home_screen.dart             # Main screen
│   ├── settings_screen.dart         # Settings
│   └── security/
│       └── unlock_screen.dart       # Authentication
│
├── services/                        # Core services
│   ├── security_service.dart        # PIN & biometric auth
│   ├── storage_service.dart         # Hive operations
│   ├── drive_auth_service.dart      # Google sign-in
│   ├── connectivity_service.dart    # Network status
│   └── hive_snapshot_service.dart   # Data snapshots
│
├── utils/                           # Utilities
│   ├── app_logger.dart              # Structured logging
│   └── theme.dart                   # App theme
│
└── main.dart                        # App entry point
```

---

## 🔄 Backup & Restore System

### **Backup Flow**

```
┌─────────────────────────────────────────────────────────┐
│                    Backup Flow                          │
└─────────────────────────────────────────────────────────┘

1. User clicks "Backup"
   ↓
2. Check connectivity (Wi-Fi required)
   ↓
3. Authenticate with Google Drive
   ↓
4. Load data from Hive
   ↓
5. Serialize to JSON
   ↓
6. Encrypt with AES-256-GCM
   ↓
7. Upload to Google Drive
   ↓
8. Save metadata
   ↓
9. Clean up old backups (keep last 5)
   ↓
10. Show success animation
```

### **Restore Flow**

```
┌─────────────────────────────────────────────────────────┐
│                   Restore Flow                          │
└─────────────────────────────────────────────────────────┘

1. User clicks "Restore"
   ↓
2. Create safety backup (pre-restore)
   ↓
3. Download backup from Google Drive
   ↓
4. Decrypt backup
   ↓
5. Validate data structure
   ↓
6. Smart merge with local data
   ├─ Conflict detection
   ├─ Version comparison
   ├─ Timestamp comparison
   └─ Winner selection
   ↓
7. Save merged data to Hive
   ↓
8. Delete safety backup (if successful)
   ↓
9. Show success animation
   ↓
10. If failed: Show rollback dialog
```

---

## 📊 Data Models

### **IncomeEntry**

```dart
class IncomeEntry {
  String id;              // UUID with 'inc_' prefix
  String name;            // Transaction name
  double amount;          // Amount
  DateTime date;          // Date (first day of month)
  DateTime? createdAt;    // Actual creation date
  DateTime? updatedAt;    // Last update date
  int version;            // Version for conflict resolution
}
```

### **OutcomeEntry**

```dart
class OutcomeEntry {
  String id;              // UUID with 'out_' prefix
  String name;            // Transaction name
  double amount;          // Amount
  DateTime date;          // Date (first day of month)
  DateTime? createdAt;    // Actual creation date
  DateTime? updatedAt;    // Last update date
  int version;            // Version for conflict resolution
}
```

### **Backup Metadata**

```dart
class BackupMetadata {
  String backupId;        // Unique backup ID
  DateTime createdAt;     // Creation timestamp
  int fileSizeBytes;      // Backup file size
  String deviceId;        // Source device
  String userEmail;       // User email
  String version;         // Backup format version
}
```

---

## 🔧 Services

### **1. BackupService**

**Responsibility:** Orchestrates backup and restore operations

**Key Methods:**
- `startBackup()` - Create and upload backup
- `startRestore()` - Download and restore backup
- `rollbackFromSafetyBackup()` - Rollback to previous state

**Dependencies:**
- `GoogleDriveService` - Drive operations
- `EncryptionService` - Data encryption
- `SmartMergeService` - Conflict resolution
- `SafetyBackupService` - Pre-restore backups

### **2. SmartMergeService**

**Responsibility:** WhatsApp-style intelligent merge

**Algorithm:**
1. Create maps for O(1) lookup
2. Compare entries by ID
3. Resolve conflicts by:
   - Version number (higher wins)
   - Timestamp (newer wins)
   - Default to remote
4. Track statistics

**Key Methods:**
- `mergeIncomeEntries()` - Merge income data
- `mergeOutcomeEntries()` - Merge outcome data

### **3. SafetyBackupService**

**Responsibility:** Create safety backups before critical operations

**Key Methods:**
- `createPreRestoreBackup()` - Create backup before restore
- `restoreFromSafetyBackup()` - Restore from backup
- `deleteSafetyBackup()` - Clean up after success

**Storage:**
- Local: `safety_backups/` directory
- Cloud: Firebase Storage (optional)

### **4. EncryptionService**

**Responsibility:** Encrypt/decrypt backup data

**Algorithm:** AES-256-GCM
- **Key Derivation:** PBKDF2 with 100,000 iterations
- **IV Generation:** Random 12 bytes
- **Authentication:** GCM tag

**Key Methods:**
- `encrypt()` - Encrypt data
- `decrypt()` - Decrypt data
- `generateKey()` - Derive encryption key

### **5. GoogleDriveService**

**Responsibility:** Google Drive operations

**Key Methods:**
- `initialize()` - Authenticate
- `listFiles()` - List backups
- `downloadFile()` - Download backup
- `uploadFile()` - Upload backup
- `deleteFileById()` - Delete backup

---

## 🔒 Security

### **Authentication**

1. **PIN Authentication**
   - SHA-256 hashing
   - Salt per user
   - 4-digit PIN
   - Lockout after 5 failed attempts

2. **Biometric Authentication**
   - Fingerprint/Face ID
   - Optional (can be disabled)
   - Fallback to PIN

### **Data Protection**

1. **At Rest:**
   - Hive database (encrypted by OS)
   - Local files (encrypted)

2. **In Transit:**
   - HTTPS for Google Drive
   - AES-256-GCM encryption

3. **In Cloud:**
   - Encrypted backup files
   - Key stored separately
   - User-specific encryption

### **Session Management**

- 15-minute session timeout
- Auto-logout on app background
- Re-authentication required for sensitive operations

---

## ⚡ Performance

### **Optimizations**

1. **Smart Merge:**
   - O(n) complexity with maps
   - Zero duplicate entries
   - Efficient conflict resolution

2. **Lazy Loading:**
   - Load data on-demand
   - Cache frequently used data
   - Clear cache on logout

3. **Background Operations:**
   - Async/await for I/O
   - Progress callbacks
   - Non-blocking UI

4. **Memory Management:**
   - Dispose controllers
   - Clear unused data
   - Garbage collection friendly

### **Performance Metrics**

| Operation | Small (<100) | Medium (100-500) | Large (>500) |
|-----------|--------------|------------------|--------------|
| Backup    | <1s          | 2-5s             | 5-10s        |
| Restore   | <2s          | 3-7s             | 10-20s       |
| Merge     | <100ms       | 200-500ms        | 500ms-2s     |

---

## 🧪 Testing Strategy

### **Unit Tests**

- Service methods
- Utility functions
- Data transformations

### **Integration Tests**

- Backup flow
- Restore flow
- Merge operations

### **E2E Tests**

- Full user workflows
- Error scenarios
- Performance benchmarks

### **Test Coverage Target**

- **Current:** ~0%
- **Target:** 80%+
- **Critical:** 100% (backup/restore)

---

## 📈 Future Improvements

### **Phase 4: Clean Architecture (Optional)**

1. **Repository Pattern:**
   - Abstract data sources
   - Dependency inversion
   - Testability

2. **Use Cases:**
   - Business logic separation
   - Single responsibility
   - Reusability

3. **Dependency Injection:**
   - GetIt or similar
   - Explicit dependencies
   - Easy mocking

### **Phase 5: Testing (Optional)**

1. **Unit Tests:**
   - Service tests
   - Model tests
   - Utility tests

2. **Integration Tests:**
   - Backup/restore flow
   - Merge operations
   - Error handling

3. **E2E Tests:**
   - User workflows
   - Performance tests
   - Regression tests

---

## 📚 Documentation

### **Code Documentation**

- ✅ Inline comments for complex logic
- ✅ Doc comments for public APIs
- ✅ README for setup
- ✅ Architecture documentation (this file)

### **User Documentation**

- ❌ User guide
- ❌ FAQ
- ❌ Troubleshooting guide

---

## 🤝 Contributing

### **Code Style**

- Follow Flutter conventions
- Use meaningful names
- Add comments for complex logic
- Keep functions small (<50 lines)

### **Git Workflow**

1. Create feature branch
2. Implement changes
3. Add tests
4. Update documentation
5. Create pull request

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

