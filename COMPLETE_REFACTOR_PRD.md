# 📋 Complete Refactor & Polish PRD
## Al Khazna - Production-Ready Enhancement Plan

---

## 📊 Document Information

| Property | Value |
|----------|-------|
| **Version** | 1.1.0 |
| **Date** | 2025-01-19 |
| **Author** | Development Team |
| **Status** | In Progress - Phase 1 Complete |
| **Target Release** | v3.1.0 |
| **Estimated Duration** | 3-4 Weeks Remaining |

---

## 🎯 Executive Summary

This PRD outlines a comprehensive refactoring and polish plan to transform Al Khazna from a **functional app** to a **production-ready, polished application**. The plan includes:

1. **Safety Enhancements** - Zero data loss guarantee
2. **Performance Optimization** - Smooth experience for large datasets
3. **UI/UX Polish** - Delightful animations and micro-interactions
4. **Code Quality** - Clean architecture and maintainability
5. **Testing & Documentation** - Production-grade reliability

---

## ⚡ **Quick Summary**

### **What's Already Done (40% Complete):**
✅ Smart Merge System with conflict resolution  
✅ Backup Version Detection (v0.9 to v2.0)  
✅ Legacy Decryption Support  
✅ Extended Merge Statistics  
✅ UUID Prefixes (inc_/out_)  
✅ Structured Logging  
✅ Basic UI Components  

### **What's Still Needed (60% Remaining):**
🔲 **Safety Backup System** (P0 - Critical)  
🔲 **Isolate-Based Merge** (P1 - High)  
🔲 **Enhanced UI with Lottie** (P1 - High)  
🔲 **Comprehensive Tests** (P2 - Medium)  
🔲 **Clean Architecture** (P2 - Optional)  

### **Timeline:**
- **Critical Features:** 1-2 weeks
- **Optional Features:** +2-3 weeks
- **Total:** 3-5 weeks

### **Next Steps:**
1. **Start with Safety Backup** (2 days) - Prevents data loss
2. **Then Enhanced UI** (2 days) - Better UX
3. **Then Isolate Merge** (3 days) - Better performance
4. **Finally Tests** (3 days) - Production reliability

---

## 📈 Current State Analysis

### ✅ **What's Already Implemented:**

| Component | Status | Rating | Files |
|-----------|--------|--------|-------|
| **Data Models** | ✅ Complete | ⭐⭐⭐⭐⭐ | `income_entry.dart`, `outcome_entry.dart` |
| **Smart Merge** | ✅ Implemented | ⭐⭐⭐⭐⭐ | `smart_merge_service.dart` |
| **Version Detection** | ✅ Implemented | ⭐⭐⭐⭐⭐ | `backup_version_detector.dart` |
| **Legacy Support** | ✅ Complete | ⭐⭐⭐⭐⭐ | `legacy_decryption_service.dart` |
| **Security System** | ✅ Robust | ⭐⭐⭐⭐⭐ | `security_service.dart` |
| **Backup/Restore** | ✅ Functional | ⭐⭐⭐⭐☆ | `backup_service.dart` |
| **Merge Statistics** | ✅ Complete | ⭐⭐⭐⭐⭐ | `merge_statistics.dart`, `merge_result.dart` |
| **UI Components** | ✅ Basic | ⭐⭐⭐⭐☆ | `backup_bottom_sheet.dart`, `backup_screen.dart` |
| **Logger Integration** | ✅ Complete | ⭐⭐⭐⭐⭐ | `app_logger.dart` |

### ⚠️ **What Still Needs Implementation:**

| Component | Issue | Priority | Status |
|-----------|-------|----------|--------|
| **Safety Backup** | ❌ Missing pre-restore backup | **P0** | 🔲 Not Started |
| **Performance** | ⚠️ UI freezes with 1000+ entries | **P1** | 🔲 Not Started |
| **UI Polish** | ⚠️ Basic progress indicators | **P1** | 🔲 Not Started |
| **Error Handling** | ⚠️ Generic error messages | **P2** | 🔲 Not Started |
| **Testing** | ❌ No automated tests | **P2** | 🔲 Not Started |
| **Clean Architecture** | ⚠️ Needs refactoring | **P2** | 🔲 Not Started |

---

## 🎉 **Recent Implementation (Completed)**

### **What Was Implemented in Latest Updates:**

#### ✅ **1. Smart Merge System (100% Complete)**
- **File:** `lib/backup/services/smart_merge_service.dart`
- **Features:**
  - WhatsApp-style intelligent merge algorithm
  - Conflict resolution by timestamp & version
  - MergeTracker for detailed statistics
  - ConflictDetail tracking
  - Per-month merge processing
  - Zero duplicate entries

#### ✅ **2. Backup Version Detection (100% Complete)**
- **File:** `lib/backup/services/backup_version_detector.dart`
- **Features:**
  - Automatic version detection (v0.9, v1.0, v1.1, v2.0)
  - Compatibility checking
  - Migration path detection
  - Backup structure validation
  - User-friendly version descriptions

#### ✅ **3. Legacy Decryption Support (100% Complete)**
- **File:** `lib/backup/services/legacy_decryption_service.dart`
- **Features:**
  - Multi-version decryption with fallback
  - Automatic version detection
  - Alternative decryption methods
  - Comprehensive error handling
  - Decryption info for debugging

#### ✅ **4. Merge Statistics & Results (100% Complete)**
- **Files:** 
  - `lib/backup/models/merge_statistics.dart`
  - `lib/backup/models/merge_result.dart`
- **Features:**
  - Detailed merge statistics
  - Conflict resolution tracking
  - Performance metrics
  - JSON serialization
  - Human-readable reports

#### ✅ **5. Enhanced Data Models (100% Complete)**
- **Files:**
  - `lib/models/income_entry.dart`
  - `lib/models/outcome_entry.dart`
- **Features:**
  - UUID with prefixes (`inc_`, `out_`)
  - Timestamp tracking (createdAt, updatedAt)
  - Version tracking for conflict resolution
  - Auto-UUID generation in fromJson
  - Full backward compatibility

#### ✅ **6. Logger Integration (100% Complete)**
- **File:** `lib/utils/app_logger.dart`
- **Features:**
  - Structured logging with logger package
  - PrettyPrinter for readable output
  - Log levels (Debug, Info, Warning, Error)
  - Color-coded output with emojis
  - Automatic timestamps

#### ✅ **7. Backup UI Components (95% Complete)**
- **Files:**
  - `lib/backup/ui/backup_bottom_sheet.dart`
  - `lib/backup/ui/backup_screen.dart`
- **Features:**
  - One-tap backup functionality
  - Progress indicators
  - Connectivity status
  - Restore confirmation dialogs
  - Error handling

---

## 🏗️ Refactoring Strategy

### **Phase 1: Safety First (Week 1)** 🔒
**Goal:** Zero data loss guarantee  
**Status:** 🔲 Not Started (0%)

**Tasks:**
1. ❌ Implement Safety Backup System
2. ❌ Add Rollback Capability
3. ❌ Enhanced Error Handling
4. ✅ Data Validation Pipeline (Already done in SmartMergeService)

### **Phase 2: Performance (Week 2)** ⚡
**Goal:** Smooth experience for any dataset size  
**Status:** 🔲 Not Started (0%)

**Tasks:**
1. ❌ Isolate-Based Merge
2. ❌ Progress Streaming
3. ✅ Memory Optimization (Basic - SmartMergeService uses maps)
4. ❌ Lazy Loading

### **Phase 3: UI Polish (Week 3)** 🎨
**Goal:** Delightful user experience  
**Status:** 🔲 Not Started (0%)

**Tasks:**
1. ❌ Lottie Animations
2. ❌ Haptic Feedback
3. ❌ Micro-interactions
4. ✅ Enhanced Dialogs (Basic - backup_bottom_sheet.dart)

### **Phase 4: Code Quality (Week 4)** 🏛️
**Goal:** Maintainable and scalable codebase  
**Status:** 🔲 Not Started (0%)

**Tasks:**
1. ❌ Clean Architecture
2. ❌ Dependency Injection
3. ✅ State Management (Provider already used)
4. ⚠️ Code Documentation (Partial)

### **Phase 5: Testing & Documentation (Week 5-6)** 🧪
**Goal:** Production-grade reliability  
**Status:** 🔲 Not Started (0%)

**Tasks:**
1. ❌ Unit Tests
2. ❌ Integration Tests
3. ❌ E2E Tests
4. ✅ API Documentation (PRD documents)

---

## 🎯 **Recommended Next Steps**

### **Priority 1: Safety Backup (Critical - 2 days)**
**Why:** Prevents data loss during restore operations  
**Impact:** High - Zero data loss guarantee  
**Effort:** Medium

**Steps:**
1. Create `lib/backup/services/safety_backup_service.dart`
2. Implement `createPreRestoreBackup()` method
3. Implement `restoreFromSafetyBackup()` method
4. Integrate into `BackupService.startRestore()`
5. Add rollback UI dialogs
6. Test with real data

### **Priority 2: Enhanced Progress Dialog (High - 2 days)**
**Why:** Better user experience during long operations  
**Impact:** Medium - Improved user satisfaction  
**Effort:** Low

**Steps:**
1. Download Lottie animations from LottieFiles
2. Create `lib/backup/ui/enhanced_restore_progress_dialog.dart`
3. Replace basic progress dialog
4. Add haptic feedback
5. Test animations

### **Priority 3: Isolate-Based Merge (High - 3 days)**
**Why:** Prevents UI freezing with large datasets  
**Impact:** High - Better performance  
**Effort:** High

**Steps:**
1. Create `lib/backup/services/isolate_merge_service.dart`
2. Implement background merge worker
3. Add progress streaming
4. Integrate into BackupService
5. Benchmark performance
6. Test with 10,000+ entries

---

## 🔗 **Compatibility with SMART_RESTORE_PRD.md**

This PRD is **100% compatible** with the existing SMART_RESTORE_PRD.md. Here's the alignment:

| SMART_RESTORE_PRD Feature | COMPLETE_REFACTOR_PRD | Status |
|---------------------------|----------------------|--------|
| **Smart Merge Algorithm** | Phase 2 (Performance) | ✅ Already Implemented |
| **UUID Prefixes** | Phase 1 (Data Models) | ✅ Already Implemented |
| **Version Detection** | Phase 1 (Legacy Support) | ✅ Already Implemented |
| **Legacy Decryption** | Phase 1 (Legacy Support) | ✅ Already Implemented |
| **Safety Backup** | Phase 1 (Safety First) | ❌ Not Implemented Yet |
| **Extended Statistics** | Phase 1 (Data Models) | ✅ Already Implemented |
| **Structured Logging** | Phase 1 (Code Quality) | ✅ Already Implemented |
| **Isolate-Based Merge** | Phase 2 (Performance) | ❌ Not Implemented Yet |
| **UI Polish (Lottie)** | Phase 3 (UI Polish) | ❌ Not Implemented Yet |

**Key Insight:** Most of the SMART_RESTORE_PRD has been implemented! This refactor PRD focuses on:
1. Adding the **missing Safety Backup** feature
2. Optimizing **performance** with isolates
3. Polishing the **UI/UX**
4. Improving **code quality**
5. Adding **comprehensive tests**

---

## 📁 **Current Project Structure**

### **Backup System Files (Already Implemented):**

```
lib/backup/
├── models/
│   ├── backup_metadata.dart           ✅ Complete
│   ├── backup_status.dart             ✅ Complete
│   ├── key_file_format.dart           ✅ Complete
│   ├── merge_result.dart              ✅ Complete (v1.1)
│   ├── merge_statistics.dart          ✅ Complete (v1.1)
│   └── restore_result.dart            ✅ Complete
│
├── services/
│   ├── backup_service.dart            ✅ Complete (needs Safety Backup integration)
│   ├── backup_version_detector.dart   ✅ Complete (v1.1)
│   ├── encryption_service.dart        ✅ Complete
│   ├── google_drive_service.dart      ✅ Complete
│   ├── headers_client.dart            ✅ Complete
│   ├── key_manager.dart               ✅ Complete
│   ├── legacy_decryption_service.dart ✅ Complete (v1.1)
│   └── smart_merge_service.dart       ✅ Complete (v1.1)
│
└── ui/
    ├── backup_bottom_sheet.dart       ✅ Complete (Basic)
    ├── backup_progress_sheet.dart     ✅ Complete
    ├── backup_screen.dart             ✅ Complete
    ├── backup_settings_page.dart      ✅ Complete
    ├── backup_verification_sheet.dart ✅ Complete
    └── restore_dialog.dart            ✅ Complete
```

### **Files Still Needed:**

```
lib/backup/
├── services/
│   ├── safety_backup_service.dart     ❌ NOT CREATED YET (P0)
│   └── isolate_merge_service.dart     ❌ NOT CREATED YET (P1)
│
└── ui/
    ├── enhanced_restore_progress_dialog.dart ❌ NOT CREATED YET (P1)
    └── animated_success_dialog.dart          ❌ NOT CREATED YET (P1)
```

---

## 📝 Detailed Implementation Plan

---

## **Phase 1: Safety First** 🔒

### **Task 1.1: Safety Backup System**

**Priority:** P0 (Critical)  
**Complexity:** Medium  
**Estimated Time:** 2 days

**File:** `lib/backup/services/safety_backup_service.dart`

```dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import '../../models/income_entry.dart';
import '../../models/outcome_entry.dart';
import '../../utils/app_logger.dart';

/// Service for creating safety backups before critical operations
/// Provides rollback capability in case of failures
class SafetyBackupService {
  static final SafetyBackupService _instance = SafetyBackupService._internal();
  factory SafetyBackupService() => _instance;
  SafetyBackupService._internal();

  final Logger _logger = AppLogger.instance;

  /// Create a safety backup before restore operation
  /// Returns backup ID for rollback reference
  Future<String> createPreRestoreBackup() async {
    final stopwatch = Stopwatch()..start();
    final backupId = DateTime.now().toIso8601String().replaceAll(':', '-');
    final backupName = 'pre_restore_$backupId.json';

    _logger.i('🛡️ Creating safety backup: $backupName');

    try {
      // Step 1: Load current data from Hive
      final incomeBox = await Hive.openBox<List<dynamic>>('income_entries');
      final outcomeBox = await Hive.openBox<List<dynamic>>('outcome_entries');

      // Step 2: Serialize to JSON
      final backupData = {
        'backup_id': backupId,
        'timestamp': DateTime.now().toIso8601String(),
        'type': 'safety_backup',
        'version': '2.0',
        'income_entries': {},
        'outcome_entries': {},
        'metadata': {
          'total_income_entries': 0,
          'total_outcome_entries': 0,
          'month_count': 0,
        },
      };

      int totalIncome = 0;
      int totalOutcome = 0;

      // Convert income entries
      for (final key in incomeBox.keys) {
        final entries = incomeBox.get(key);
        if (entries != null && entries is List) {
          final jsonList = entries
              .whereType<IncomeEntry>()
              .map((e) => e.toJson())
              .toList();
          
          backupData['income_entries'][key.toString()] = jsonList;
          totalIncome += jsonList.length;
        }
      }

      // Convert outcome entries
      for (final key in outcomeBox.keys) {
        final entries = outcomeBox.get(key);
        if (entries != null && entries is List) {
          final jsonList = entries
              .whereType<OutcomeEntry>()
              .map((e) => e.toJson())
              .toList();
          
          backupData['outcome_entries'][key.toString()] = jsonList;
          totalOutcome += jsonList.length;
        }
      }

      // Update metadata
      backupData['metadata']['total_income_entries'] = totalIncome;
      backupData['metadata']['total_outcome_entries'] = totalOutcome;
      backupData['metadata']['month_count'] = incomeBox.keys.length;

      // Step 3: Save to local file
      final directory = await getApplicationDocumentsDirectory();
      final safetyBackupDir = Directory('${directory.path}/safety_backups');
      if (!safetyBackupDir.existsSync()) {
        safetyBackupDir.createSync(recursive: true);
      }

      final file = File('${safetyBackupDir.path}/$backupName');
      await file.writeAsString(jsonEncode(backupData));

      _logger.i('✅ Safety backup created locally: ${file.path}');
      _logger.d('   Income entries: $totalIncome');
      _logger.d('   Outcome entries: $totalOutcome');
      _logger.d('   Months: ${incomeBox.keys.length}');

      // Step 4: Upload to Firebase Storage (optional, for cloud safety)
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('users/${user.uid}/safety_backups/$backupName');

          await storageRef.putString(
            jsonEncode(backupData),
            metadata: SettableMetadata(contentType: 'application/json'),
          );

          _logger.i('✅ Safety backup uploaded to cloud');
        }
      } catch (cloudError) {
        _logger.w('⚠️ Failed to upload safety backup to cloud: $cloudError');
        // Continue - local backup is sufficient
      }

      // Step 5: Clean up old safety backups (keep last 5)
      await _cleanupOldSafetyBackups(safetyBackupDir);

      stopwatch.stop();
      _logger.i('✅ Safety backup complete in ${stopwatch.elapsedMilliseconds}ms');

      return backupId;
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to create safety backup', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Restore from safety backup
  /// Used for rollback in case of restore failure
  Future<bool> restoreFromSafetyBackup(String backupId) async {
    _logger.i('🔄 Restoring from safety backup: $backupId');

    try {
      // Step 1: Find backup file
      final directory = await getApplicationDocumentsDirectory();
      final safetyBackupDir = Directory('${directory.path}/safety_backups');
      
      if (!safetyBackupDir.existsSync()) {
        _logger.e('❌ Safety backup directory not found');
        return false;
      }

      final backupFile = File('${safetyBackupDir.path}/pre_restore_$backupId.json');
      if (!backupFile.existsSync()) {
        _logger.e('❌ Safety backup file not found: ${backupFile.path}');
        return false;
      }

      // Step 2: Load backup data
      final jsonString = await backupFile.readAsString();
      final backupData = json.decode(jsonString) as Map<String, dynamic>;

      // Step 3: Validate data
      if (!_validateBackupData(backupData)) {
        _logger.e('❌ Invalid safety backup data');
        return false;
      }

      // Step 4: Restore to Hive
      final incomeBox = await Hive.openBox<List<dynamic>>('income_entries');
      final outcomeBox = await Hive.openBox<List<dynamic>>('outcome_entries');

      // Clear existing data
      await incomeBox.clear();
      await outcomeBox.clear();

      // Restore income entries
      final incomeData = backupData['income_entries'] as Map<String, dynamic>;
      for (final entry in incomeData.entries) {
        final entries = (entry.value as List)
            .map((e) => IncomeEntry.fromJson(e as Map<String, dynamic>))
            .toList();
        await incomeBox.put(entry.key, entries);
      }

      // Restore outcome entries
      final outcomeData = backupData['outcome_entries'] as Map<String, dynamic>;
      for (final entry in outcomeData.entries) {
        final entries = (entry.value as List)
            .map((e) => OutcomeEntry.fromJson(e as Map<String, dynamic>))
            .toList();
        await outcomeBox.put(entry.key, entries);
      }

      _logger.i('✅ Safety backup restored successfully');
      return true;
    } catch (e, stackTrace) {
      _logger.e('❌ Failed to restore safety backup', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Clean up old safety backups, keeping only the last 5
  Future<void> _cleanupOldSafetyBackups(Directory safetyBackupDir) async {
    try {
      final files = safetyBackupDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList();

      // Sort by modified time (oldest first)
      files.sort((a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));

      // Keep only last 5, delete the rest
      if (files.length > 5) {
        for (var i = 0; i < files.length - 5; i++) {
          await files[i].delete();
          _logger.d('🗑️ Deleted old safety backup: ${files[i].path}');
        }
      }
    } catch (e) {
      _logger.w('⚠️ Failed to cleanup old safety backups: $e');
    }
  }

  /// Validate backup data structure
  bool _validateBackupData(Map<String, dynamic> data) {
    try {
      // Check required fields
      if (!data.containsKey('backup_id')) return false;
      if (!data.containsKey('timestamp')) return false;
      if (!data.containsKey('income_entries')) return false;
      if (!data.containsKey('outcome_entries')) return false;

      // Check data types
      if (data['income_entries'] is! Map) return false;
      if (data['outcome_entries'] is! Map) return false;

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get list of available safety backups
  Future<List<SafetyBackupInfo>> getAvailableSafetyBackups() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final safetyBackupDir = Directory('${directory.path}/safety_backups');
      
      if (!safetyBackupDir.existsSync()) {
        return [];
      }

      final files = safetyBackupDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList();

      return files.map((file) {
        final stat = file.statSync();
        return SafetyBackupInfo(
          backupId: file.path.split('/').last.replaceAll('.json', ''),
          filePath: file.path,
          createdAt: stat.modified,
          fileSize: stat.size,
        );
      }).toList();
    } catch (e) {
      _logger.e('❌ Failed to get safety backups list', error: e);
      return [];
    }
  }
}

/// Information about a safety backup
class SafetyBackupInfo {
  final String backupId;
  final String filePath;
  final DateTime createdAt;
  final int fileSize;

  SafetyBackupInfo({
    required this.backupId,
    required this.filePath,
    required this.createdAt,
    required this.fileSize,
  });
}
```

---

### **Task 1.2: Integrate Safety Backup into Restore Flow**

**Priority:** P0 (Critical)  
**Complexity:** Low  
**Estimated Time:** 1 day

**Implementation Steps:**

1. **Update BackupService imports:**
```dart
// Add to lib/backup/services/backup_service.dart
import 'safety_backup_service.dart';
```

2. **Add SafetyBackupService instance:**
```dart
final SafetyBackupService _safetyBackupService = SafetyBackupService();
```

3. **Update startRestore method:**
```dart
Future<RestoreResult> startRestore() async {
  if (_isRestoreInProgress) {
    return RestoreResult.failure('Restore already in progress');
  }

  _isRestoreInProgress = true;
  String? safetyBackupId;

  try {
    // ✨ NEW: Create safety backup BEFORE restore
    _updateProgress(5, null, 'Creating safety backup...', RestoreStatus.downloading);
    try {
      safetyBackupId = await _safetyBackupService.createPreRestoreBackup();
      _logger.i('✅ Safety backup created: $safetyBackupId');
    } catch (e) {
      _logger.e('⚠️ Safety backup failed: $e');
      // Ask user if they want to continue without safety backup
      final shouldContinue = await _showSafetyBackupWarningDialog();
      if (!shouldContinue) {
        _updateProgress(0, null, 'Restore cancelled', RestoreStatus.failed);
        return RestoreResult.failure('User cancelled due to safety backup failure');
      }
    }

    // ... existing restore code ...

    // If restore succeeds, delete safety backup
    if (safetyBackupId != null) {
      await _deleteSafetyBackup(safetyBackupId);
    }

    return RestoreResult.success(/* ... */);
  } catch (e) {
    _logger.e('❌ Restore failed: $e');
    
    // ✨ NEW: Offer rollback if safety backup exists
    if (safetyBackupId != null) {
      final shouldRollback = await _showRollbackDialog();
      if (shouldRollback) {
        _updateProgress(0, null, 'Rolling back...', RestoreStatus.applying);
        final rollbackSuccess = await _safetyBackupService.restoreFromSafetyBackup(safetyBackupId);
        
        if (rollbackSuccess) {
          _updateProgress(100, null, 'Rollback successful', RestoreStatus.completed);
          return RestoreResult.failure('Restore failed but rollback successful');
        }
      }
    }
    
    _updateProgress(0, null, 'Restore failed', RestoreStatus.failed);
    return RestoreResult.failure(e.toString());
  } finally {
    _isRestoreInProgress = false;
  }
}
```

---

## **Phase 2: Performance Optimization** ⚡

### **Task 2.1: Isolate-Based Merge Service**

**Priority:** P1 (High)  
**Complexity:** High  
**Estimated Time:** 3 days

**File:** `lib/backup/services/isolate_merge_service.dart`

```dart
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import '../../models/income_entry.dart';
import '../../models/outcome_entry.dart';
import '../models/merge_result.dart';
import '../models/merge_statistics.dart';
import '../../utils/app_logger.dart';

/// Service for performing merge operations in background isolate
/// Prevents UI freezing for large datasets (>500 entries)
class IsolateMergeService {
  static final IsolateMergeService _instance = IsolateMergeService._internal();
  factory IsolateMergeService() => _instance;
  IsolateMergeService._internal();

  final Logger _logger = AppLogger.instance;

  /// Merge entries in background isolate with real-time progress
  Stream<MergeProgress> mergeInBackground({
    required Map<String, dynamic> backupData,
    required Map<String, dynamic> localData,
  }) async* {
    final receivePort = ReceivePort();
    final errorPort = ReceivePort();

    try {
      // Spawn isolate
      await Isolate.spawn(
        _isolateMergeWorker,
        _IsolateConfig(
          sendPort: receivePort.sendPort,
          backupData: backupData,
          localData: localData,
        ),
        onError: errorPort.sendPort,
        debugName: 'SmartMergeIsolate',
      );

      _logger.i('📊 Background isolate spawned for merge');

      // Listen for progress updates
      await for (final message in receivePort) {
        if (message is MergeProgress) {
          yield message;
        } else if (message is Map<String, dynamic>) {
          // Final result
          yield MergeProgress.completed(
            incomeData: message['income'] as Map<String, List<IncomeEntry>>,
            outcomeData: message['outcome'] as Map<String, List<OutcomeEntry>>,
            statistics: message['statistics'] as MergeStatistics,
          );
          break;
        } else if (message is String && message.startsWith('ERROR:')) {
          yield MergeProgress.error(message: message.substring(6));
          break;
        }
      }
    } catch (e) {
      _logger.e('❌ Isolate merge error', error: e);
      yield MergeProgress.error(message: e.toString());
    } finally {
      receivePort.close();
      errorPort.close();
    }
  }

  /// Isolate worker function (runs in background)
  static void _isolateMergeWorker(_IsolateConfig config) async {
    final sendPort = config.sendPort;
    final backupData = config.backupData;
    final localData = config.localData;

    try {
      // Phase 1: Validate data (5%)
      sendPort.send(MergeProgress(
        phase: MergePhase.validating,
        percentage: 5,
        message: 'Validating backup data...',
      ));

      // Phase 2: Parse and merge income (10-40%)
      sendPort.send(MergeProgress(
        phase: MergePhase.parsingIncome,
        percentage: 10,
        message: 'Loading income entries...',
      ));

      final incomeResults = await _parseAndMergeIncome(
        backupData: backupData,
        localData: localData,
        progressCallback: (progress) {
          sendPort.send(MergeProgress(
            phase: MergePhase.mergingIncome,
            percentage: 10 + (progress * 30).toInt(),
            message: 'Merging income entries... ${(progress * 100).toInt()}%',
          ));
        },
      );

      // Phase 3: Parse and merge outcome (40-70%)
      sendPort.send(MergeProgress(
        phase: MergePhase.parsingOutcome,
        percentage: 40,
        message: 'Loading expense entries...',
      ));

      final outcomeResults = await _parseAndMergeOutcome(
        backupData: backupData,
        localData: localData,
        progressCallback: (progress) {
          sendPort.send(MergeProgress(
            phase: MergePhase.mergingOutcome,
            percentage: 40 + (progress * 30).toInt(),
            message: 'Merging expense entries... ${(progress * 100).toInt()}%',
          ));
        },
      );

      // Phase 4: Finalize (70-100%)
      sendPort.send(MergeProgress(
        phase: MergePhase.finalizing,
        percentage: 90,
        message: 'Finalizing merge...',
      ));

      // Send final result
      sendPort.send({
        'income': incomeResults.mergedData,
        'outcome': outcomeResults.mergedData,
        'statistics': incomeResults.statistics,
      });

    } catch (e, stackTrace) {
      sendPort.send('ERROR:$e');
    }
  }

  /// Decide whether to use isolate based on data size
  static bool shouldUseIsolate(Map<String, dynamic> backupData) {
    int totalEntries = 0;

    // Count income entries
    if (backupData.containsKey('income_entries')) {
      final incomeData = backupData['income_entries'] as Map<String, dynamic>;
      for (final entries in incomeData.values) {
        if (entries is List) {
          totalEntries += entries.length;
        }
      }
    }

    // Count outcome entries
    if (backupData.containsKey('outcome_entries')) {
      final outcomeData = backupData['outcome_entries'] as Map<String, dynamic>;
      for (final entries in outcomeData.values) {
        if (entries is List) {
          totalEntries += entries.length;
        }
      }
    }

    // Use isolate for 500+ entries
    return totalEntries >= 500;
  }
}

/// Progress update from isolate
class MergeProgress {
  final MergePhase phase;
  final int percentage;
  final String message;
  final Map<String, List<IncomeEntry>>? incomeData;
  final Map<String, List<OutcomeEntry>>? outcomeData;
  final MergeStatistics? statistics;
  final String? error;

  MergeProgress({
    required this.phase,
    required this.percentage,
    required this.message,
    this.incomeData,
    this.outcomeData,
    this.statistics,
    this.error,
  });

  factory MergeProgress.completed({
    required Map<String, List<IncomeEntry>> incomeData,
    required Map<String, List<OutcomeEntry>> outcomeData,
    required MergeStatistics statistics,
  }) {
    return MergeProgress(
      phase: MergePhase.completed,
      percentage: 100,
      message: 'Merge completed!',
      incomeData: incomeData,
      outcomeData: outcomeData,
      statistics: statistics,
    );
  }

  factory MergeProgress.error({required String message}) {
    return MergeProgress(
      phase: MergePhase.error,
      percentage: 0,
      message: message,
      error: message,
    );
  }

  bool get isCompleted => phase == MergePhase.completed;
  bool get hasError => phase == MergePhase.error;
}

/// Merge phases for progress tracking
enum MergePhase {
  validating,
  parsingIncome,
  mergingIncome,
  parsingOutcome,
  mergingOutcome,
  finalizing,
  completed,
  error,
}

/// Configuration for isolate worker
class _IsolateConfig {
  final SendPort sendPort;
  final Map<String, dynamic> backupData;
  final Map<String, dynamic> localData;

  _IsolateConfig({
    required this.sendPort,
    required this.backupData,
    required this.localData,
  });
}
```

---

## **Phase 3: UI Polish** 🎨

### **Task 3.1: Enhanced Progress Dialog with Lottie**

**Priority:** P1 (High)  
**Complexity:** Medium  
**Estimated Time:** 2 days

**File:** `lib/backup/ui/enhanced_restore_progress_dialog.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import '../models/backup_status.dart';

/// Enhanced restore progress dialog with Lottie animations
class EnhancedRestoreProgressDialog extends StatefulWidget {
  final int percentage;
  final String message;
  final RestoreStatus status;

  const EnhancedRestoreProgressDialog({
    super.key,
    required this.percentage,
    required this.message,
    required this.status,
  });

  @override
  State<EnhancedRestoreProgressDialog> createState() =>
      _EnhancedRestoreProgressDialogState();
}

class _EnhancedRestoreProgressDialogState
    extends State<EnhancedRestoreProgressDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Haptic feedback on milestones
    _triggerHapticFeedback();
  }

  void _triggerHapticFeedback() {
    if (widget.percentage == 25 || widget.percentage == 50 || widget.percentage == 75) {
      HapticFeedback.selectionClick();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated Lottie
            SizedBox(
              width: 150,
              height: 150,
              child: _buildAnimation(),
            ),

            const SizedBox(height: 16),

            // Status title
            Text(
              _getStatusTitle(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Progress message
            Text(
              widget.message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // Enhanced progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                height: 8,
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutCubic,
                  tween: Tween<double>(begin: 0, end: widget.percentage / 100),
                  builder: (context, value, _) {
                    return LinearProgressIndicator(
                      value: value,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getProgressColor(),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Percentage text
            TweenAnimationBuilder<int>(
              duration: const Duration(milliseconds: 500),
              tween: IntTween(begin: 0, end: widget.percentage),
              builder: (context, value, _) {
                return Text(
                  '$value%',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _getProgressColor(),
                      ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimation() {
    switch (widget.status) {
      case RestoreStatus.downloading:
        return Lottie.asset(
          'assets/animations/cloud_download.json',
          repeat: true,
        );
      case RestoreStatus.decrypting:
        return Lottie.asset(
          'assets/animations/lock_unlock.json',
          repeat: true,
        );
      case RestoreStatus.processing:
        return Lottie.asset(
          'assets/animations/data_merge.json',
          repeat: true,
        );
      case RestoreStatus.completed:
        return Lottie.asset(
          'assets/animations/success_checkmark.json',
          repeat: false,
        );
      case RestoreStatus.failed:
        return Lottie.asset(
          'assets/animations/error_cross.json',
          repeat: false,
        );
      default:
        return const CircularProgressIndicator();
    }
  }

  String _getStatusTitle() {
    switch (widget.status) {
      case RestoreStatus.downloading:
        return 'Downloading Backup';
      case RestoreStatus.decrypting:
        return 'Decrypting Data';
      case RestoreStatus.processing:
        return 'Merging Data';
      case RestoreStatus.completed:
        return 'Restore Complete!';
      case RestoreStatus.failed:
        return 'Restore Failed';
      default:
        return 'Processing...';
    }
  }

  Color _getProgressColor() {
    switch (widget.status) {
      case RestoreStatus.downloading:
        return Colors.blue;
      case RestoreStatus.decrypting:
        return Colors.orange;
      case RestoreStatus.processing:
        return Colors.purple;
      case RestoreStatus.completed:
        return Colors.green;
      case RestoreStatus.failed:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
```

---

### **Task 3.2: Animated Success Dialog with Confetti**

**Priority:** P1 (High)  
**Complexity:** Medium  
**Estimated Time:** 2 days

**File:** `lib/backup/ui/animated_success_dialog.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:confetti/confetti.dart';
import '../models/merge_result.dart';

/// Celebratory success dialog with confetti
class AnimatedSuccessDialog extends StatefulWidget {
  final MergeResult result;

  const AnimatedSuccessDialog({
    super.key,
    required this.result,
  });

  @override
  State<AnimatedSuccessDialog> createState() => _AnimatedSuccessDialogState();
}

class _AnimatedSuccessDialogState extends State<AnimatedSuccessDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );

    // Trigger haptic feedback
    HapticFeedback.mediumImpact();

    // Start animations
    _controller.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      _confettiController.play();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main dialog
        Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: ScaleTransition(
            scale: CurvedAnimation(
              parent: _controller,
              curve: Curves.elasticOut,
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Success animation
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: Lottie.asset(
                      'assets/animations/success_checkmark.json',
                      repeat: false,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Title
                  Text(
                    '🎉 Restore Complete!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),

                  const SizedBox(height: 8),

                  // Subtitle
                  Text(
                    'Your data has been successfully merged',
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 24),

                  // Animated statistics cards
                  _buildStatCard(
                    icon: Icons.check_circle,
                    color: Colors.green,
                    label: 'Total Entries',
                    value: widget.result.totalEntries.toString(),
                    delay: 200,
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.cloud_download,
                          color: Colors.blue,
                          label: 'From Backup',
                          value: widget.result.entriesFromBackup.toString(),
                          delay: 400,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.phone_android,
                          color: Colors.purple,
                          label: 'Local',
                          value: widget.result.entriesFromLocal.toString(),
                          delay: 600,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Action button
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Confetti overlay
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            particleDrag: 0.05,
            emissionFrequency: 0.05,
            numberOfParticles: 50,
            gravity: 0.2,
            shouldLoop: false,
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange,
              Colors.purple,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
    required int delay,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: delay),
      tween: Tween<double>(begin: 0, end: 1),
      curve: Curves.easeOutBack,
      builder: (context, opacity, child) {
        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - opacity)),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## **Phase 4: Code Quality** 🏛️

### **Task 4.1: Clean Architecture Implementation**

**Priority:** P2 (Medium)  
**Complexity:** High  
**Estimated Time:** 4 days

**File:** `lib/core/usecases/base_usecase.dart`

```dart
import 'package:dartz/dartz.dart';
import '../errors/failures.dart';

/// Base use case for clean architecture
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

/// No parameters use case
class NoParams {
  const NoParams();
}
```

**File:** `lib/core/errors/failures.dart`

```dart
/// Base class for failures
abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => message;
}

/// Server failure
class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

/// Cache failure
class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

/// Network failure
class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

/// Validation failure
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}
```

**File:** `lib/domain/usecases/finance/get_income_entries.dart`

```dart
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../entities/income_entry.dart';
import '../../repositories/finance_repository.dart';
import '../../../../core/usecases/base_usecase.dart';

class GetIncomeEntries implements UseCase<List<IncomeEntry>, String> {
  final FinanceRepository repository;

  GetIncomeEntries(this.repository);

  @override
  Future<Either<Failure, List<IncomeEntry>>> call(String monthKey) async {
    return await repository.getIncomeEntries(monthKey);
  }
}
```

---

## **Phase 5: Testing** 🧪

### **Task 5.1: Unit Tests**

**Priority:** P2 (Medium)  
**Complexity:** Medium  
**Estimated Time:** 3 days

**File:** `test/backup/services/smart_merge_service_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:alkhazna/backup/services/smart_merge_service.dart';
import 'package:alkhazna/models/income_entry.dart';

void main() {
  group('SmartMergeService', () {
    late SmartMergeService mergeService;

    setUp(() {
      mergeService = SmartMergeService();
    });

    test('Merge with no conflicts', () async {
      // Arrange
      final backup = [
        IncomeEntry(
          id: 'inc_uuid-1',
          name: 'Salary',
          amount: 1000,
          date: DateTime(2025, 1, 1),
          createdAt: DateTime(2025, 1, 1),
          version: 1,
        ),
      ];

      final local = [
        IncomeEntry(
          id: 'inc_uuid-2',
          name: 'Bonus',
          amount: 500,
          date: DateTime(2025, 1, 15),
          createdAt: DateTime(2025, 1, 15),
          version: 1,
        ),
      ];

      // Act
      final tracker = MergeTracker();
      tracker.start();
      final merged = await mergeService.mergeIncomeEntries(
        backupData: {'2025-01': backup},
        localData: {'2025-01': local},
        tracker: tracker,
      );
      tracker.finish();

      // Assert
      expect(merged['2025-01']?.length, 2);
      expect(merged['2025-01']?.any((e) => e.id == 'inc_uuid-1'), true);
      expect(merged['2025-01']?.any((e) => e.id == 'inc_uuid-2'), true);
    });

    test('Resolve conflict - backup newer', () async {
      // Arrange
      final oldTime = DateTime(2025, 1, 1);
      final newTime = DateTime(2025, 1, 15);

      final backup = [
        IncomeEntry(
          id: 'inc_uuid-1',
          name: 'Updated Salary',
          amount: 2000,
          date: oldTime,
          createdAt: oldTime,
          updatedAt: newTime,
          version: 2,
        ),
      ];

      final local = [
        IncomeEntry(
          id: 'inc_uuid-1',
          name: 'Salary',
          amount: 1000,
          date: oldTime,
          createdAt: oldTime,
          version: 1,
        ),
      ];

      // Act
      final tracker = MergeTracker();
      tracker.start();
      final merged = await mergeService.mergeIncomeEntries(
        backupData: {'2025-01': backup},
        localData: {'2025-01': local},
        tracker: tracker,
      );
      tracker.finish();

      // Assert
      expect(merged['2025-01']?.length, 1);
      expect(merged['2025-01']?.first.amount, 2000);
      expect(merged['2025-01']?.first.name, 'Updated Salary');
      expect(tracker.incomeConflicts, 1);
    });
  });
}
```

---

## 📊 **Implementation Checklist**

### **Week 1: Safety First** 🔒 (2-3 days)
- [ ] Create SafetyBackupService
- [ ] Integrate into BackupService
- [ ] Add rollback UI dialogs
- [ ] Test safety backup creation
- [ ] Test rollback functionality
- [ ] Update documentation

### **Week 2: Performance** ⚡ (3-4 days)
- [ ] Create IsolateMergeService
- [ ] Implement background merge
- [ ] Add progress streaming
- [ ] Benchmark performance improvements
- [ ] Test with 10,000+ entries
- [ ] Optimize memory usage

### **Week 3: UI Polish** 🎨 (2-3 days)
- [ ] Download Lottie animations from LottieFiles
- [ ] Create EnhancedRestoreProgressDialog
- [ ] Create AnimatedSuccessDialog
- [ ] Add haptic feedback throughout app
- [ ] Test animations on low-end devices
- [ ] Optimize animation file sizes

### **Week 4: Code Quality** 🏛️ (Optional - 3-4 days)
- [ ] Implement Clean Architecture structure
- [ ] Add Dependency Injection (GetIt)
- [ ] Refactor state management
- [ ] Add comprehensive code documentation
- [ ] Code review and refactoring
- [ ] Performance profiling

### **Week 5-6: Testing** 🧪 (Optional - 3-4 days)
- [ ] Write unit tests (target 80%+ coverage)
- [ ] Write integration tests
- [ ] Write E2E tests with Flutter Driver
- [ ] Performance testing and optimization
- [ ] User acceptance testing
- [ ] Bug fixes and polish

---

## 🎯 **Success Metrics**

| Metric | Target | Measurement |
|--------|--------|-------------|
| **Data Loss Rate** | 0% | User reports & analytics |
| **UI Freeze Rate** | 0% | Performance monitoring |
| **Test Coverage** | 80%+ | Automated test reports |
| **User Satisfaction** | 4.5/5 | App store reviews |
| **Performance** | <5s for 1000 entries | Benchmark tests |
| **Crash Rate** | <0.1% | Firebase Crashlytics |
| **App Size** | <50MB | APK/IPA analysis |

---

## 📦 **Dependencies to Add**

### **Required Dependencies (Already in pubspec.yaml):**
```yaml
dependencies:
  uuid: ^4.4.0          ✅ Already added
  logger: ^2.5.0        ✅ Already added (via app_logger.dart)
  lottie: ^2.6.0        ✅ Already added
  confetti: ^0.7.0      ✅ Already added
```

### **Optional Dependencies (For Phase 4 & 5):**

Update `pubspec.yaml`:

```yaml
dependencies:
  # ... existing dependencies ...
  
  # For Clean Architecture (Optional)
  dartz: ^0.10.1
  
  # For Dependency Injection (Optional)
  get_it: ^7.6.4
  
dev_dependencies:
  # For Testing (Optional)
  mockito: ^5.4.4
  flutter_test:
    sdk: flutter
  flutter_driver:
    sdk: flutter
  test: ^1.24.0
```

### **Installation Commands:**

```bash
# Install required dependencies (if not already installed)
flutter pub get

# For Clean Architecture (optional)
flutter pub add dartz

# For Dependency Injection (optional)
flutter pub add get_it

# For Testing (optional)
flutter pub add --dev mockito
flutter pub add --dev test
```

---

## 🚀 **Rollout Plan**

### **Phase 1: Internal Testing (Week 1-2)**
- Deploy to internal testers
- Collect feedback
- Fix critical bugs

### **Phase 2: Beta Release (Week 3-4)**
- Release to 10% of users
- Monitor crash reports
- Gather performance metrics

### **Phase 3: Staged Rollout (Week 5-6)**
- 25% of users
- 50% of users
- 100% of users

### **Phase 4: Full Release**
- Public release
- Marketing campaign
- Monitor user feedback

---

## 📊 **Final Assessment**

### **Overall Project Status:** ⭐⭐⭐⭐☆ (4.2/5)

| Category | Rating | Notes |
|----------|--------|-------|
| **Data Safety** | ⭐⭐⭐⭐☆ | Smart Merge done, Safety Backup pending |
| **Performance** | ⭐⭐⭐☆☆ | Works but needs isolate optimization |
| **UI/UX** | ⭐⭐⭐☆☆ | Functional but needs polish |
| **Code Quality** | ⭐⭐⭐⭐☆ | Good structure, needs tests |
| **Security** | ⭐⭐⭐⭐⭐ | Excellent - PIN + Biometric |
| **Backup/Restore** | ⭐⭐⭐⭐☆ | Smart Merge implemented, needs Safety Backup |

### **Strengths:**
✅ Excellent Smart Merge implementation  
✅ Robust version detection & legacy support  
✅ Strong security system  
✅ Good data models with UUID support  
✅ Structured logging ready  
✅ Basic UI components functional  

### **Weaknesses:**
⚠️ No safety backup (data loss risk)  
⚠️ UI freezes with large datasets  
⚠️ Basic progress indicators  
⚠️ No automated tests  
⚠️ Generic error messages  

### **Recommendations:**
1. **Must Do:** Implement Safety Backup (P0)
2. **Should Do:** Add Isolate Merge for performance (P1)
3. **Nice to Have:** Polish UI with Lottie (P1)
4. **Optional:** Add comprehensive tests (P2)

---

## 📝 **Conclusion**

This PRD provides a comprehensive roadmap for transforming Al Khazna into a production-ready, polished application. By following this plan systematically, we will achieve:

✅ **Zero data loss guarantee**  
✅ **Smooth performance for any dataset**  
✅ **Delightful user experience**  
✅ **Maintainable codebase**  
✅ **Production-grade reliability**

**Estimated Timeline:** 
- **Critical Features (P0-P1):** 1-2 weeks
- **Optional Features (P2):** +2-3 weeks
- **Total:** 3-5 weeks (down from 4-6 weeks due to completed work)

**Team Size:** 1-2 developers (reduced due to completed work)  
**Budget:** Standard development costs  
**Expected ROI:** High user satisfaction, reduced support tickets

**Progress:** ~40% Complete (Smart Merge, Version Detection, Legacy Support already done)

---

## 📚 **Additional Resources**

### **Lottie Animations**
Download from [LottieFiles](https://lottiefiles.com/):
- Cloud Download: https://lottiefiles.com/animations/cloud-download
- Lock Unlock: https://lottiefiles.com/animations/unlock
- Data Merge: https://lottiefiles.com/animations/data-sync
- Success Checkmark: https://lottiefiles.com/animations/success-checkmark
- Error Cross: https://lottiefiles.com/animations/error-cross

### **Testing Resources**
- [Flutter Testing Guide](https://docs.flutter.dev/testing)
- [Mockito Documentation](https://pub.dev/packages/mockito)
- [Clean Architecture in Flutter](https://resocoder.com/flutter-clean-architecture-tdd)

### **Performance Optimization**
- [Flutter Performance Best Practices](https://docs.flutter.dev/perf/best-practices)
- [Isolate Usage Guide](https://dart.dev/guides/language/concurrency)

---

---

## 📝 **Document History**

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2025-01-19 | Dev Team | Initial PRD creation |
| **1.1.0** | **2025-01-19** | **Dev Team** | **✨ Updated after analyzing current project state** |

### **v1.1.0 Changes:**
- ✅ Added "Recent Implementation" section documenting completed work
- ✅ Updated current state analysis with actual implemented features
- ✅ Added compatibility matrix with SMART_RESTORE_PRD.md
- ✅ Added current project structure with file status
- ✅ Updated implementation checklist with realistic timelines
- ✅ Added "Recommended Next Steps" section
- ✅ Reduced estimated timeline from 4-6 weeks to 3-5 weeks
- ✅ Marked completed features (Smart Merge, Version Detection, Legacy Support)
- ✅ Identified missing features (Safety Backup, Isolate Merge, UI Polish)

---

**END OF PRD**

*This is a living document and will be updated as implementation progresses.*

**Document Version:** 1.1.0  
**Last Updated:** 2025-01-19  
**Next Review:** After Phase 1 (Safety Backup) completion  
**Current Progress:** ~40% Complete

---

## 🎯 **Executive Summary (TL;DR)**

### **The Good News:**
🎉 **40% of the work is already done!**
- Smart Merge System ✅
- Version Detection ✅
- Legacy Support ✅
- UUID Prefixes ✅
- Structured Logging ✅

### **The Remaining Work:**
📋 **Only 3 critical features left:**
1. **Safety Backup** (2 days) - Prevents data loss
2. **Enhanced UI** (2 days) - Better UX
3. **Isolate Merge** (3 days) - Better performance

### **Timeline:**
- **Minimum (Critical Only):** 1 week
- **Recommended (Critical + Nice to Have):** 2 weeks
- **Complete (All Features):** 3-5 weeks

### **Bottom Line:**
The project is in **excellent shape**. Most of the complex work (Smart Merge, Version Detection, Legacy Support) is already complete. The remaining work is straightforward and can be done in **1-2 weeks** for critical features.

**Recommendation:** Start with Safety Backup (P0), then Enhanced UI (P1), then Isolate Merge (P1). Skip Clean Architecture and Testing if time is limited - they're nice-to-have but not critical for launch.

---

## 📞 **Questions?**

For any questions about this PRD or implementation details, please refer to:
- `SMART_RESTORE_PRD.md` - Detailed Smart Restore documentation
- `CRITICAL_FIXES_SUMMARY.md` - Recent bug fixes
- `BACKUP_RESTORE_COMPATIBILITY_ANALYSIS.md` - Compatibility analysis

