# Smart Restore System - PRD (Product Requirements Document)
## Al Khazna - WhatsApp-Style Intelligent Backup Restore

---

## 📋 Document Information

| Property | Value |
|----------|-------|
| **Version** | 1.1.0 |
| **Date** | 2025-01-18 |
| **Author** | Development Team |
| **Status** | Draft |
| **Target Release** | v2.0 |
| **Enhancements** | Safety Backup, Extended Stats, UUID Prefixes, Structured Logging |

---

## 🎯 1. Overview & Objectives

### 1.1 Executive Summary
Implement a WhatsApp-style intelligent restore system that **merges backup data with local data** instead of replacing it entirely. The system will use smart conflict resolution, maintain data integrity, and provide seamless user experience.

**v1.1 Enhancements:**
- 🧱 **Safety Backup**: Automatic pre-restore backup for rollback capability
- 📊 **Extended Statistics**: Detailed merge reports with conflict details
- 🏷️ **UUID Prefixes**: Type-safe identifiers (`inc_*`, `out_*`) for better debugging
- 📝 **Structured Logging**: Professional logging with `logger` package for production debugging

### 1.2 Problem Statement
**Current Issue:**
- Restore operation uses **"Replace All"** strategy (`box.clear()`)
- All local data is **permanently deleted** before restore
- Users lose any data created after the backup
- No way to merge backup with current data
- Risk of data loss if backup is outdated

**User Pain Points:**
- ❌ Fear of losing recent transactions
- ❌ Cannot combine backup with new data
- ❌ No rollback if restore goes wrong
- ❌ Must manually re-enter data added after backup

### 1.3 Objectives
1. **Implement Smart Merge** - Combine backup data with local data intelligently
2. **Prevent Duplicates** - Use unique identifiers to avoid data duplication
3. **Conflict Resolution** - Keep most recent version of conflicting entries
4. **Preserve Local Data** - Never delete user's current data
5. **Auto-refresh UI** - Update all screens immediately after restore
6. **Safety First** - Create automatic backup before restore

### 1.4 Success Criteria
- ✅ Zero data loss during restore operations
- ✅ No duplicate entries after merge
- ✅ Automatic conflict resolution (no user intervention needed)
- ✅ Immediate UI refresh showing merged data
- ✅ Backup creation before every restore (safety net)
- ✅ 100% backward compatible with existing backups

---

## 🔍 2. Current State Analysis

### 2.1 Current Restore Flow
```
User clicks Restore
    ↓
Download backup from Firebase
    ↓
incomeBox.clear() ⚠️ DELETE ALL LOCAL DATA
    ↓
outcomeBox.clear() ⚠️ DELETE ALL LOCAL DATA
    ↓
Load backup data
    ↓
Show success message
```

### 2.2 Current Code Behavior
**File:** `lib/backup/services/backup_service.dart`

```dart
// Line 611 - Income Restore
final incomeBox = await Hive.openBox<List<dynamic>>('income_entries');
await incomeBox.clear(); // ⚠️ DELETES EVERYTHING

// Line 658 - Outcome Restore
final outcomeBox = await Hive.openBox<List<dynamic>>('outcome_entries');
await outcomeBox.clear(); // ⚠️ DELETES EVERYTHING
```

### 2.3 Problems with Current Approach
| Problem | Impact | Severity |
|---------|--------|----------|
| Data Loss | All local changes lost | 🔴 Critical |
| No Merge | Can't combine old + new | 🔴 Critical |
| No Rollback | Can't undo restore | 🟠 High |
| Manual Refresh | UI doesn't update | 🟡 Medium |

---

## 👥 3. User Stories

### 3.1 Primary User Stories

**Story 1: Merge Without Loss**
```gherkin
As a user
I want to restore my backup without losing recent transactions
So that I can recover old data while keeping new entries

Acceptance Criteria:
- Backup data is merged with local data
- No local entries are deleted
- All data visible after restore
```

**Story 2: No Duplicates**
```gherkin
As a user
I want the system to automatically detect and prevent duplicate entries
So that I don't see the same transaction twice

Acceptance Criteria:
- Each entry has a unique identifier
- Duplicate detection by ID
- Only one version of each entry exists
```

**Story 3: Keep Latest Version**
```gherkin
As a user
When the same entry exists in both backup and local storage
I want to keep the most recent version
So that my latest changes are preserved

Acceptance Criteria:
- Conflict resolution by timestamp
- Newest version wins automatically
- No manual intervention needed
```

**Story 4: Immediate Refresh**
```gherkin
As a user
After restore completes
I want to see all merged data immediately in the UI
So that I can verify the restore was successful

Acceptance Criteria:
- Total Balance updates automatically
- All screens refresh with merged data
- No manual pull-to-refresh needed
```

**Story 5: Safety Backup**
```gherkin
As a user
Before restore begins
I want an automatic backup of my current data
So that I can recover if something goes wrong

Acceptance Criteria:
- Auto-backup created before restore
- Backup stored with timestamp
- Can restore from safety backup if needed
```

---

## 🛠️ 4. Functional Requirements

### 4.1 Core Features

#### F1: Smart Merge Algorithm
**Description:** Intelligently combine backup data with local data
- **Priority:** P0 (Critical)
- **Complexity:** High

**Requirements:**
- Load both backup and local data into memory
- Compare entries by unique identifier
- Merge without duplicates
- Preserve data integrity

#### F2: Unique Entry Identification
**Description:** Generate and maintain unique IDs for all entries
- **Priority:** P0 (Critical)
- **Complexity:** Medium

**Requirements:**
- Add UUID to IncomeEntry model
- Add UUID to OutcomeEntry model
- Generate UUID on entry creation
- Use UUID for duplicate detection

#### F3: Conflict Resolution
**Description:** Automatically resolve conflicts between backup and local data
- **Priority:** P0 (Critical)
- **Complexity:** Medium

**Requirements:**
- Compare by timestamp (createdAt/updatedAt)
- Keep newest version
- Log conflicts for debugging
- Maintain data consistency

#### F4: Auto-Backup Before Restore
**Description:** Create safety backup before starting restore
- **Priority:** P1 (High)
- **Complexity:** Low

**Requirements:**
- Check if backup needed
- Create backup automatically
- Store with "pre_restore_" prefix
- Show progress to user

#### F5: Automatic UI Refresh
**Description:** Update all UI components after restore
- **Priority:** P1 (High)
- **Complexity:** Medium

**Requirements:**
- Trigger HomeScreen refresh
- Update Total Balance immediately
- Refresh Income/Outcome screens
- Show success notification

### 4.2 Non-Functional Requirements

#### NFR1: Performance
- Merge operation < 5 seconds for 1000 entries
- No UI freezing during merge
- Progress indicator for long operations

#### NFR2: Data Integrity
- Zero data loss guarantee
- Atomic operations (all or nothing)
- Transaction rollback on error

#### NFR3: Backward Compatibility
- Support old backups without UUID
- Graceful migration for existing data
- No breaking changes

#### NFR4: User Experience
- Clear progress messages
- Success/failure notifications
- No technical error messages
- Intuitive flow

---

## 🏗️ 5. Technical Architecture

### 5.1 System Components

```
┌─────────────────────────────────────────────────────────────┐
│                        UI Layer                              │
├─────────────────────────────────────────────────────────────┤
│  BackupBottomSheet  │  HomeScreen  │  Settings  │  Progress │
└─────────────┬───────────────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Service Layer                             │
├─────────────────────────────────────────────────────────────┤
│  BackupService      │  SmartMergeService  │  StorageService │
└─────────────┬───────────────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────────────────────────┐
│                     Data Layer                               │
├─────────────────────────────────────────────────────────────┤
│   Hive Boxes        │   Firebase Storage   │   Local Cache  │
└─────────────────────────────────────────────────────────────┘
```

### 5.2 New Service: SmartMergeService

**Responsibility:** Handle intelligent merging of backup and local data

**Key Methods:**
```dart
class SmartMergeService {
  // Main merge function
  Future<MergeResult> mergeData({
    required Map<String, dynamic> backupData,
    required Map<String, dynamic> localData,
  });

  // Merge income entries
  Future<List<IncomeEntry>> mergeIncomeEntries({
    required List<IncomeEntry> backupEntries,
    required List<IncomeEntry> localEntries,
  });

  // Merge outcome entries
  Future<List<OutcomeEntry>> mergeOutcomeEntries({
    required List<OutcomeEntry> backupEntries,
    required List<OutcomeEntry> localEntries,
  });

  // Resolve conflicts
  T resolveConflict<T extends BaseEntry>(T backup, T local);

  // Detect duplicates
  bool isDuplicate(BaseEntry entry, List<BaseEntry> entries);
}
```

### 5.3 Data Flow Diagram

```
┌─────────────┐
│   User      │
│ Clicks      │
│ Restore     │
└──────┬──────┘
       │
       ▼
┌─────────────────────────────────────┐
│  1. Pre-Restore Safety Backup       │
│     - Create backup of current data │
│     - Store with timestamp          │
└──────┬──────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────┐
│  2. Download Backup from Firebase   │
│     - Fetch backup data             │
│     - Validate JSON structure       │
└──────┬──────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────┐
│  3. Load Local Data from Hive       │
│     - Read all income entries       │
│     - Read all outcome entries      │
└──────┬──────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────┐
│  4. Smart Merge Algorithm           │
│     - Compare by UUID               │
│     - Resolve conflicts by timestamp│
│     - Create merged dataset         │
└──────┬──────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────┐
│  5. Write Merged Data to Hive       │
│     - Clear boxes                   │
│     - Write merged entries          │
│     - Atomic transaction            │
└──────┬──────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────┐
│  6. Refresh UI                      │
│     - Update HomeScreen             │
│     - Reload Total Balance          │
│     - Show success message          │
└─────────────────────────────────────┘
```

---

## 💾 6. Data Models

### 6.1 Enhanced IncomeEntry Model

**Current Model:**
```dart
class IncomeEntry {
  double amount;
  String name;
  String date;
  DateTime? createdAt;
}
```

**Enhanced Model:**
```dart
@HiveType(typeId: 1)
class IncomeEntry extends HiveObject {
  @HiveField(0)
  double amount;

  @HiveField(1)
  String name;

  @HiveField(2)
  String date;

  @HiveField(3)
  DateTime? createdAt;

  @HiveField(4) // ✨ NEW
  String id; // UUID with prefix: inc_<uuid>

  @HiveField(5) // ✨ NEW
  DateTime? updatedAt; // Track last modification

  @HiveField(6) // ✨ NEW
  int version; // Version number for conflict resolution
}
```

### 6.2 Enhanced OutcomeEntry Model

**Current Model:**
```dart
class OutcomeEntry {
  String description;
  double amount;
  String date;
}
```

**Enhanced Model:**
```dart
@HiveType(typeId: 2)
class OutcomeEntry extends HiveObject {
  @HiveField(0)
  String description;

  @HiveField(1)
  double amount;

  @HiveField(2)
  String date;

  @HiveField(3) // ✨ NEW
  String id; // UUID with prefix: out_<uuid>

  @HiveField(4) // ✨ NEW
  DateTime createdAt; // Creation timestamp

  @HiveField(5) // ✨ NEW
  DateTime? updatedAt; // Last modification timestamp

  @HiveField(6) // ✨ NEW
  int version; // Version number
}
```

### 6.3 New Models

#### MergeResult (v1.1 Enhanced)
```dart
class MergeResult {
  final bool success;
  final int totalEntries;
  final int mergedEntries;
  final int newEntries;
  final int conflictsResolved;
  final int duplicatesSkipped;
  final String? errorMessage;
  final Duration duration;

  // ✨ v1.1: Extended statistics
  final MergeStatistics statistics;
  final List<ConflictDetail> conflicts; // Details of each conflict
  final Map<String, int> sourceBreakdown; // Entries by month
}
```

#### ConflictDetail (v1.1 New)
```dart
class ConflictDetail {
  final String entryId;
  final String entryName; // Income name or Outcome description
  final String entryType; // 'income' or 'outcome'
  final DateTime backupTimestamp;
  final DateTime localTimestamp;
  final String resolution; // 'kept_backup' or 'kept_local'
  final String reason; // 'newer_timestamp', 'higher_version', etc.
}
```

#### MergeConflict
```dart
class MergeConflict<T> {
  final T backupEntry;
  final T localEntry;
  final ConflictResolutionStrategy strategy;
  final T resolvedEntry;
  final String reason;
}
```

#### ConflictResolutionStrategy
```dart
enum ConflictResolutionStrategy {
  keepNewest,    // Keep entry with latest timestamp
  keepBackup,    // Always prefer backup version
  keepLocal,     // Always prefer local version
  merge,         // Merge both entries
}
```

---

## 🧠 7. Smart Merge Algorithm

### 7.1 Algorithm Overview

```
INPUT: backupData, localData
OUTPUT: mergedData

STEP 1: Initialize
  - Create empty mergedMap (keyed by UUID)
  - Create conflictsList

STEP 2: Add Local Entries First
  FOR EACH localEntry IN localData:
    mergedMap[localEntry.id] = localEntry

STEP 3: Process Backup Entries
  FOR EACH backupEntry IN backupData:
    IF backupEntry.id NOT IN mergedMap:
      // New entry from backup
      mergedMap[backupEntry.id] = backupEntry
    ELSE:
      // Conflict detected
      localEntry = mergedMap[backupEntry.id]
      resolvedEntry = resolveConflict(backupEntry, localEntry)
      mergedMap[backupEntry.id] = resolvedEntry

STEP 4: Return Merged Data
  RETURN mergedMap.values
```

### 7.2 Conflict Resolution Logic

```
FUNCTION resolveConflict(backupEntry, localEntry):

  // Compare timestamps
  backupTime = backupEntry.updatedAt ?? backupEntry.createdAt
  localTime = localEntry.updatedAt ?? localEntry.createdAt

  IF backupTime > localTime:
    RETURN backupEntry  // Backup is newer
  ELSE IF localTime > backupTime:
    RETURN localEntry   // Local is newer
  ELSE:
    // Same timestamp - compare versions
    IF backupEntry.version > localEntry.version:
      RETURN backupEntry
    ELSE:
      RETURN localEntry
```

### 7.3 UUID Generation Strategy

```dart
// For new entries
String generateUUID() {
  return Uuid().v4(); // Random UUID
}

// For existing entries without UUID (migration)
String generateLegacyUUID(Entry entry) {
  // Create deterministic UUID from entry data
  final data = '${entry.date}_${entry.amount}_${entry.name}';
  return Uuid().v5(Uuid.NAMESPACE_OID, data);
}
```

### 7.4 Duplicate Detection

```dart
bool isDuplicate(Entry entry, List<Entry> entries) {
  // Primary: Check by UUID
  if (entries.any((e) => e.id == entry.id)) {
    return true;
  }

  // Secondary: Check by content (for legacy entries)
  return entries.any((e) =>
    e.date == entry.date &&
    e.amount == entry.amount &&
    e.description == entry.description &&
    (e.createdAt?.difference(entry.createdAt ?? DateTime.now()).inMinutes.abs() ?? 0) < 5
  );
}
```

---

## 🎨 8. UI/UX Flow

### 8.1 Restore Dialog Flow

```
┌─────────────────────────────────────┐
│  ⚠️  Restore Backup?                │
│                                      │
│  This will merge your backup data   │
│  with current data.                 │
│                                      │
│  Your local data will be preserved. │
│                                      │
│  [ Cancel ]  [ Restore & Merge ]   │
└─────────────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────┐
│  🔄 Preparing Restore...            │
│                                      │
│  Creating safety backup...          │
│  ████████████░░░░░░░  60%          │
└─────────────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────┐
│  📥 Downloading Backup...           │
│                                      │
│  Fetching from cloud...             │
│  ███████████████████░  90%         │
└─────────────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────┐
│  🧠 Merging Data...                 │
│                                      │
│  • 45 entries from backup           │
│  • 23 local entries                 │
│  • 3 conflicts resolved             │
│  • 0 duplicates skipped             │
│                                      │
│  ████████████████████  100%        │
└─────────────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────┐
│  ✅ Restore Complete!               │
│                                      │
│  📊 Merge Summary:                  │
│  • Total: 65 entries                │
│  • Added: 42 from backup            │
│  • Kept: 23 local entries           │
│  • Updated: 3 conflicts             │
│                                      │
│  [     View Details     ]           │
│  [         Done         ]           │
└─────────────────────────────────────┘
```

### 8.2 Progress Messages

| Phase | Message | Duration |
|-------|---------|----------|
| Pre-backup | "Creating safety backup..." | 2-3s |
| Download | "Downloading backup from cloud..." | 3-5s |
| Load Local | "Loading local data..." | 1-2s |
| Merge | "Merging data intelligently..." | 2-4s |
| Write | "Saving merged data..." | 1-2s |
| Refresh | "Refreshing UI..." | 1s |

### 8.3 Success Screen Details

```dart
// Detailed merge statistics
MergeStatistics {
  totalEntriesAfterMerge: 65,
  entriesFromBackup: 42,
  entriesKeptLocal: 23,
  conflictsResolved: 3,
  duplicatesSkipped: 0,

  incomeStats: {
    total: 40,
    fromBackup: 25,
    fromLocal: 15,
  },

  outcomeStats: {
    total: 25,
    fromBackup: 17,
    fromLocal: 8,
  },
}
```

---

## 🔨 9. Implementation Plan

### Phase 1: Data Model Enhancement (Week 1)

#### Task 1.1: Add UUID to IncomeEntry
**File:** `lib/models/income_entry.dart`

```dart
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'income_entry.g.dart';

@HiveType(typeId: 1)
class IncomeEntry extends HiveObject {
  @HiveField(0)
  double amount;

  @HiveField(1)
  String name;

  @HiveField(2)
  String date;

  @HiveField(3)
  DateTime? createdAt;

  // ✨ NEW FIELDS
  @HiveField(4)
  late String id;

  @HiveField(5)
  DateTime? updatedAt;

  @HiveField(6)
  int version;

  IncomeEntry({
    required this.amount,
    required this.name,
    required this.date,
    DateTime? createdAt,
    String? id,
    this.updatedAt,
    this.version = 1,
  }) : this.createdAt = createdAt ?? DateTime.now() {
    // ✨ v1.1: Generate UUID with prefix if not provided
    this.id = id ?? 'inc_${const Uuid().v4()}';
  }

  // Factory for JSON deserialization
  factory IncomeEntry.fromJson(Map<String, dynamic> json) {
    return IncomeEntry(
      amount: (json['amount'] as num).toDouble(),
      name: json['name'] as String,
      date: json['date'] as String,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      id: json['id'] as String?,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      version: json['version'] as int? ?? 1,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'name': name,
      'date': date,
      'createdAt': createdAt?.toIso8601String(),
      'id': id,
      'updatedAt': updatedAt?.toIso8601String(),
      'version': version,
    };
  }

  // Update entry
  void update() {
    updatedAt = DateTime.now();
    version++;
  }

  // Create copy with changes
  IncomeEntry copyWith({
    double? amount,
    String? name,
    String? date,
    DateTime? createdAt,
    String? id,
    DateTime? updatedAt,
    int? version,
  }) {
    return IncomeEntry(
      amount: amount ?? this.amount,
      name: name ?? this.name,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
    );
  }
}
```

#### Task 1.2: Add UUID to OutcomeEntry
**File:** `lib/models/outcome_entry.dart`

```dart
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'outcome_entry.g.dart';

@HiveType(typeId: 2)
class OutcomeEntry extends HiveObject {
  @HiveField(0)
  String description;

  @HiveField(1)
  double amount;

  @HiveField(2)
  String date;

  // ✨ NEW FIELDS
  @HiveField(3)
  late String id;

  @HiveField(4)
  late DateTime createdAt;

  @HiveField(5)
  DateTime? updatedAt;

  @HiveField(6)
  int version;

  OutcomeEntry({
    required this.description,
    required this.amount,
    required this.date,
    String? id,
    DateTime? createdAt,
    this.updatedAt,
    this.version = 1,
  }) {
    // ✨ v1.1: Generate UUID with prefix if not provided
    this.id = id ?? 'out_${const Uuid().v4()}';
    this.createdAt = createdAt ?? DateTime.now();
  }

  factory OutcomeEntry.fromJson(Map<String, dynamic> json) {
    return OutcomeEntry(
      description: json['description'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: json['date'] as String,
      id: json['id'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      version: json['version'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'amount': amount,
      'date': date,
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'version': version,
    };
  }

  void update() {
    updatedAt = DateTime.now();
    version++;
  }

  OutcomeEntry copyWith({
    String? description,
    double? amount,
    String? date,
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? version,
  }) {
    return OutcomeEntry(
      description: description ?? this.description,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
    );
  }
}
```

#### Task 1.3: Create MergeResult Model
**File:** `lib/backup/models/merge_result.dart`

```dart
/// Result of a merge operation
class MergeResult {
  final bool success;
  final int totalEntries;
  final int entriesFromBackup;
  final int entriesFromLocal;
  final int conflictsResolved;
  final int duplicatesSkipped;
  final String? errorMessage;
  final Duration duration;
  final MergeStatistics statistics;

  MergeResult({
    required this.success,
    required this.totalEntries,
    required this.entriesFromBackup,
    required this.entriesFromLocal,
    required this.conflictsResolved,
    required this.duplicatesSkipped,
    this.errorMessage,
    required this.duration,
    required this.statistics,
  });

  factory MergeResult.success({
    required int totalEntries,
    required int entriesFromBackup,
    required int entriesFromLocal,
    required int conflictsResolved,
    required int duplicatesSkipped,
    required Duration duration,
    required MergeStatistics statistics,
  }) {
    return MergeResult(
      success: true,
      totalEntries: totalEntries,
      entriesFromBackup: entriesFromBackup,
      entriesFromLocal: entriesFromLocal,
      conflictsResolved: conflictsResolved,
      duplicatesSkipped: duplicatesSkipped,
      duration: duration,
      statistics: statistics,
    );
  }

  factory MergeResult.failure(String errorMessage) {
    return MergeResult(
      success: false,
      totalEntries: 0,
      entriesFromBackup: 0,
      entriesFromLocal: 0,
      conflictsResolved: 0,
      duplicatesSkipped: 0,
      errorMessage: errorMessage,
      duration: Duration.zero,
      statistics: MergeStatistics.empty(),
    );
  }
}

/// Detailed statistics about the merge operation
class MergeStatistics {
  final IncomeStatistics income;
  final OutcomeStatistics outcome;

  MergeStatistics({
    required this.income,
    required this.outcome,
  });

  factory MergeStatistics.empty() {
    return MergeStatistics(
      income: IncomeStatistics.empty(),
      outcome: OutcomeStatistics.empty(),
    );
  }

  int get totalIncome => income.total;
  int get totalOutcome => outcome.total;
  int get grandTotal => totalIncome + totalOutcome;
}

class IncomeStatistics {
  final int total;
  final int fromBackup;
  final int fromLocal;
  final int conflicts;

  IncomeStatistics({
    required this.total,
    required this.fromBackup,
    required this.fromLocal,
    required this.conflicts,
  });

  factory IncomeStatistics.empty() {
    return IncomeStatistics(
      total: 0,
      fromBackup: 0,
      fromLocal: 0,
      conflicts: 0,
    );
  }
}

class OutcomeStatistics {
  final int total;
  final int fromBackup;
  final int fromLocal;
  final int conflicts;

  OutcomeStatistics({
    required this.total,
    required this.fromBackup,
    required this.fromLocal,
    required this.conflicts,
  });

  factory OutcomeStatistics.empty() {
    return OutcomeStatistics(
      total: 0,
      fromBackup: 0,
      fromLocal: 0,
      conflicts: 0,
    );
  }
}
```

### Phase 2: Smart Merge Service (Week 2)

#### Task 2.1: Create SmartMergeService
**File:** `lib/backup/services/smart_merge_service.dart`

```dart
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart'; // ✨ v1.1: Structured logging
import '../../models/income_entry.dart';
import '../../models/outcome_entry.dart';
import '../models/merge_result.dart';

/// Service for intelligently merging backup data with local data
/// Uses WhatsApp-style smart merge algorithm
///
/// v1.1 Enhancements:
/// - Structured logging with logger package
/// - Extended statistics with conflict details
/// - UUID prefix validation
class SmartMergeService {
  // ✨ v1.1: Structured logger
  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: true,
    ),
  );
  /// Merge income entries
  ///
  /// Algorithm:
  /// 1. Create map keyed by UUID
  /// 2. Add all local entries
  /// 3. Process backup entries
  /// 4. Resolve conflicts by timestamp
  Future<List<IncomeEntry>> mergeIncomeEntries({
    required List<IncomeEntry> backupEntries,
    required List<IncomeEntry> localEntries,
  }) async {
    final stopwatch = Stopwatch()..start();

    // Step 1: Create merge map (keyed by UUID)
    final Map<String, IncomeEntry> mergeMap = {};
    int conflictsResolved = 0;
    final List<ConflictDetail> conflicts = []; // ✨ v1.1: Track conflict details

    // Step 2: Add all local entries first
    for (final localEntry in localEntries) {
      mergeMap[localEntry.id] = localEntry;
    }

    // ✨ v1.1: Structured logging
    _logger.d('SmartMerge: Added ${localEntries.length} local income entries');

    // Step 3: Process backup entries
    for (final backupEntry in backupEntries) {
      if (!mergeMap.containsKey(backupEntry.id)) {
        // New entry from backup - add it
        mergeMap[backupEntry.id] = backupEntry;
        _logger.i('New entry from backup: ${backupEntry.name} (${backupEntry.id})');
      } else {
        // Conflict detected - resolve it
        final localEntry = mergeMap[backupEntry.id]!;
        final resolved = _resolveIncomeConflict(backupEntry, localEntry);
        mergeMap[backupEntry.id] = resolved;
        conflictsResolved++;

        // ✨ v1.1: Record conflict details
        final backupTime = backupEntry.updatedAt ?? backupEntry.createdAt!;
        final localTime = localEntry.updatedAt ?? localEntry.createdAt!;

        conflicts.add(ConflictDetail(
          entryId: backupEntry.id,
          entryName: backupEntry.name,
          entryType: 'income',
          backupTimestamp: backupTime,
          localTimestamp: localTime,
          resolution: resolved == backupEntry ? 'kept_backup' : 'kept_local',
          reason: _getConflictReason(backupEntry, localEntry, resolved),
        ));

        _logger.w('Conflict resolved for: ${backupEntry.name}');
        _logger.d('  Backup: v${backupEntry.version} @ $backupTime');
        _logger.d('  Local:  v${localEntry.version} @ $localTime');
        _logger.d('  Winner: ${resolved == backupEntry ? "Backup" : "Local"}');
      }
    }

    stopwatch.stop();
    // ✨ v1.1: Structured logging with statistics
    _logger.i('Income merge complete in ${stopwatch.elapsedMilliseconds}ms');
    _logger.d('  Total: ${mergeMap.length} entries');
    _logger.d('  From backup: ${backupEntries.length}');
    _logger.d('  From local: ${localEntries.length}');
    _logger.d('  Conflicts resolved: $conflictsResolved');

    // Step 4: Return merged entries sorted by date
    final merged = mergeMap.values.toList();
    merged.sort((a, b) => b.createdAt!.compareTo(a.createdAt!));
    return merged;
  }

  /// Merge outcome entries
  Future<List<OutcomeEntry>> mergeOutcomeEntries({
    required List<OutcomeEntry> backupEntries,
    required List<OutcomeEntry> localEntries,
  }) async {
    final stopwatch = Stopwatch()..start();

    // Step 1: Create merge map (keyed by UUID)
    final Map<String, OutcomeEntry> mergeMap = {};
    int conflictsResolved = 0;

    // Step 2: Add all local entries first
    for (final localEntry in localEntries) {
      mergeMap[localEntry.id] = localEntry;
    }

    if (kDebugMode) {
      print('🔄 SmartMerge: Added ${localEntries.length} local outcome entries');
    }

    // Step 3: Process backup entries
    for (final backupEntry in backupEntries) {
      if (!mergeMap.containsKey(backupEntry.id)) {
        // New entry from backup - add it
        mergeMap[backupEntry.id] = backupEntry;
        if (kDebugMode) {
          print('✅ New entry from backup: ${backupEntry.description} (${backupEntry.id})');
        }
      } else {
        // Conflict detected - resolve it
        final localEntry = mergeMap[backupEntry.id]!;
        final resolved = _resolveOutcomeConflict(backupEntry, localEntry);
        mergeMap[backupEntry.id] = resolved;
        conflictsResolved++;

        if (kDebugMode) {
          print('⚔️ Conflict resolved for: ${backupEntry.description}');
          print('   Backup: v${backupEntry.version} @ ${backupEntry.updatedAt ?? backupEntry.createdAt}');
          print('   Local:  v${localEntry.version} @ ${localEntry.updatedAt ?? localEntry.createdAt}');
          print('   Winner: ${resolved == backupEntry ? "Backup" : "Local"}');
        }
      }
    }

    stopwatch.stop();
    if (kDebugMode) {
      print('✅ Outcome merge complete in ${stopwatch.elapsedMilliseconds}ms');
      print('   Total: ${mergeMap.length} entries');
      print('   From backup: ${backupEntries.length}');
      print('   From local: ${localEntries.length}');
      print('   Conflicts resolved: $conflictsResolved');
    }

    // Step 4: Return merged entries sorted by date
    final merged = mergeMap.values.toList();
    merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return merged;
  }

  /// Resolve conflict between two income entries
  /// Strategy: Keep the entry with the latest timestamp
  IncomeEntry _resolveIncomeConflict(
    IncomeEntry backup,
    IncomeEntry local,
  ) {
    // Get timestamps for comparison
    final backupTime = backup.updatedAt ?? backup.createdAt ?? DateTime(1970);
    final localTime = local.updatedAt ?? local.createdAt ?? DateTime(1970);

    // Compare timestamps
    if (backupTime.isAfter(localTime)) {
      return backup; // Backup is newer
    } else if (localTime.isAfter(backupTime)) {
      return local; // Local is newer
    } else {
      // Same timestamp - compare versions
      if (backup.version > local.version) {
        return backup;
      } else {
        return local;
      }
    }
  }

  /// Resolve conflict between two outcome entries
  OutcomeEntry _resolveOutcomeConflict(
    OutcomeEntry backup,
    OutcomeEntry local,
  ) {
    // Get timestamps for comparison
    final backupTime = backup.updatedAt ?? backup.createdAt;
    final localTime = local.updatedAt ?? local.createdAt;

    // Compare timestamps
    if (backupTime.isAfter(localTime)) {
      return backup; // Backup is newer
    } else if (localTime.isAfter(backupTime)) {
      return local; // Local is newer
    } else {
      // Same timestamp - compare versions
      if (backup.version > local.version) {
        return backup;
      } else {
        return local;
      }
    }
  }

  /// Check if entry is duplicate (for legacy entries without UUID)
  bool isDuplicateIncome(IncomeEntry entry, List<IncomeEntry> entries) {
    return entries.any((e) =>
        e.id == entry.id ||
        (e.date == entry.date &&
            e.amount == entry.amount &&
            e.name == entry.name &&
            _isWithinTimeWindow(
              e.createdAt ?? DateTime.now(),
              entry.createdAt ?? DateTime.now(),
            )));
  }

  /// Check if entry is duplicate (for legacy entries without UUID)
  bool isDuplicateOutcome(OutcomeEntry entry, List<OutcomeEntry> entries) {
    return entries.any((e) =>
        e.id == entry.id ||
        (e.date == entry.date &&
            e.amount == entry.amount &&
            e.description == entry.description &&
            _isWithinTimeWindow(e.createdAt, entry.createdAt)));
  }

  /// Check if two timestamps are within 5 minutes of each other
  bool _isWithinTimeWindow(DateTime t1, DateTime t2) {
    return t1.difference(t2).inMinutes.abs() < 5;
  }

  // ✨ v1.1: Helper to get conflict resolution reason
  String _getConflictReason(dynamic backup, dynamic local, dynamic resolved) {
    final backupTime = backup.updatedAt ?? backup.createdAt;
    final localTime = local.updatedAt ?? local.createdAt;

    if (backupTime.isAfter(localTime)) {
      return 'newer_timestamp';
    } else if (localTime.isAfter(backupTime)) {
      return 'newer_timestamp';
    } else {
      return 'higher_version';
    }
  }
}
```

### Phase 3: Update BackupService (Week 2)

#### Task 3.1: Integrate SmartMerge into BackupService
**File:** `lib/backup/services/backup_service.dart`

**Changes to make:**

```dart
import 'smart_merge_service.dart';
import '../models/merge_result.dart';

class BackupService extends ChangeNotifier {
  // ... existing code ...

  // Add SmartMergeService
  final SmartMergeService _mergeService = SmartMergeService();

  /// Start restore with smart merge
  Future<RestoreResult> startRestore() async {
    if (_isRestoreInProgress) {
      return RestoreResult.failure('Restore already in progress');
    }

    _isRestoreInProgress = true;
    final overallStopwatch = Stopwatch()..start();

    try {
      // Step 1: Create safety backup
      _updateProgress(5, null, 'Creating safety backup...', RestoreStatus.downloading);
      await _createSafetyBackup();

      // Step 2: Check connectivity
      _updateProgress(10, null, 'Checking connection...', RestoreStatus.downloading);
      final isConnected = await _checkConnectivity();
      if (!isConnected) {
        _updateProgress(0, null, 'No internet connection', RestoreStatus.failed);
        return RestoreResult.failure('No internet connection');
      }

      // Step 3: Download backup from Firebase
      _updateProgress(20, null, 'Downloading backup...', RestoreStatus.downloading);
      final backupData = await _downloadBackupFromFirebase();
      if (backupData == null) {
        _updateProgress(0, null, 'No backup found', RestoreStatus.failed);
        return RestoreResult.failure('No backup found in cloud');
      }

      // Step 4: Load local data
      _updateProgress(40, null, 'Loading local data...', RestoreStatus.processing);
      final localIncomeData = await _loadLocalIncomeData();
      final localOutcomeData = await _loadLocalOutcomeData();

      // Step 5: Smart merge income entries
      _updateProgress(50, null, 'Merging income data...', RestoreStatus.processing);
      final mergedIncome = await _mergeIncomeData(
        backupData: backupData,
        localData: localIncomeData,
      );

      // Step 6: Smart merge outcome entries
      _updateProgress(70, null, 'Merging outcome data...', RestoreStatus.processing);
      final mergedOutcome = await _mergeOutcomeData(
        backupData: backupData,
        localData: localOutcomeData,
      );

      // Step 7: Write merged data to Hive
      _updateProgress(85, null, 'Saving merged data...', RestoreStatus.processing);
      await _writeMergedDataToHive(mergedIncome, mergedOutcome);

      // Step 8: Success
      overallStopwatch.stop();
      _updateProgress(
        100,
        null,
        'Restore complete!',
        RestoreStatus.completed,
      );

      if (kDebugMode) {
        print('✅ Restore completed in ${overallStopwatch.elapsedMilliseconds}ms');
      }

      return RestoreResult.success();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Restore failed: $e');
      }
      _updateProgress(0, null, 'Restore failed', RestoreStatus.failed);
      return RestoreResult.failure(e.toString());
    } finally {
      _isRestoreInProgress = false;
      notifyListeners();
    }
  }

  /// ✨ v1.1: Create safety backup before restore (ACTUAL IMPLEMENTATION)
  Future<void> _createSafetyBackup() async {
    try {
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final safetyBackupName = 'pre_restore_$timestamp.json';

      _logger.i('Creating safety backup: $safetyBackupName');

      // Step 1: Load current data from Hive
      final incomeBox = await Hive.openBox<List<dynamic>>('income_entries');
      final outcomeBox = await Hive.openBox<List<dynamic>>('outcome_entries');

      // Step 2: Serialize to JSON
      final backupData = {
        'timestamp': timestamp,
        'type': 'safety_backup',
        'income_entries': {},
        'outcome_entries': {},
      };

      // Convert income entries
      for (final key in incomeBox.keys) {
        final entries = incomeBox.get(key);
        if (entries != null && entries is List) {
          backupData['income_entries'][key.toString()] =
            entries.whereType<IncomeEntry>().map((e) => e.toJson()).toList();
        }
      }

      // Convert outcome entries
      for (final key in outcomeBox.keys) {
        final entries = outcomeBox.get(key);
        if (entries != null && entries is List) {
          backupData['outcome_entries'][key.toString()] =
            entries.whereType<OutcomeEntry>().map((e) => e.toJson()).toList();
        }
      }

      // Step 3: Save to local file
      final directory = await getApplicationDocumentsDirectory();
      final safetyBackupDir = Directory('${directory.path}/safety_backups');
      if (!safetyBackupDir.existsSync()) {
        safetyBackupDir.createSync(recursive: true);
      }

      final file = File('${safetyBackupDir.path}/$safetyBackupName');
      await file.writeAsString(jsonEncode(backupData));

      _logger.i('Safety backup created successfully: ${file.path}');

      // Step 4: Upload to Firebase Storage (optional, for cloud safety)
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('users/${user.uid}/safety_backups/$safetyBackupName');

          await storageRef.putString(
            jsonEncode(backupData),
            metadata: SettableMetadata(contentType: 'application/json'),
          );

          _logger.i('Safety backup uploaded to cloud');
        }
      } catch (cloudError) {
        _logger.w('Failed to upload safety backup to cloud: $cloudError');
        // Continue - local backup is sufficient
      }

      // Step 5: Clean up old safety backups (keep last 5)
      await _cleanupOldSafetyBackups(safetyBackupDir);

    } catch (e, stackTrace) {
      _logger.e('Failed to create safety backup', error: e, stackTrace: stackTrace);
      // Don't fail restore if safety backup fails, but warn user
      throw SafetyBackupException('Could not create safety backup: ${e.toString()}');
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
          _logger.d('Deleted old safety backup: ${files[i].path}');
        }
      }
    } catch (e) {
      _logger.w('Failed to cleanup old safety backups: $e');
    }
  }

  /// Load local income data
  Future<Map<String, List<IncomeEntry>>> _loadLocalIncomeData() async {
    final incomeBox = await Hive.openBox<List<dynamic>>('income_entries');
    final Map<String, List<IncomeEntry>> localData = {};

    for (final key in incomeBox.keys) {
      final entries = incomeBox.get(key);
      if (entries != null && entries is List) {
        final incomeEntries = entries
            .whereType<IncomeEntry>()
            .toList();
        localData[key.toString()] = incomeEntries;
      }
    }

    if (kDebugMode) {
      print('📱 Loaded ${localData.length} months of local income data');
    }

    return localData;
  }

  /// Load local outcome data
  Future<Map<String, List<OutcomeEntry>>> _loadLocalOutcomeData() async {
    final outcomeBox = await Hive.openBox<List<dynamic>>('outcome_entries');
    final Map<String, List<OutcomeEntry>> localData = {};

    for (final key in outcomeBox.keys) {
      final entries = outcomeBox.get(key);
      if (entries != null && entries is List) {
        final outcomeEntries = entries
            .whereType<OutcomeEntry>()
            .toList();
        localData[key.toString()] = outcomeEntries;
      }
    }

    if (kDebugMode) {
      print('📱 Loaded ${localData.length} months of local outcome data');
    }

    return localData;
  }

  /// Merge income data using SmartMergeService
  Future<Map<String, List<IncomeEntry>>> _mergeIncomeData({
    required Map<String, dynamic> backupData,
    required Map<String, List<IncomeEntry>> localData,
  }) async {
    final Map<String, List<IncomeEntry>> mergedData = {};

    if (!backupData.containsKey('income_entries')) {
      return localData; // No backup data, return local
    }

    final backupIncomeData = backupData['income_entries'] as Map<String, dynamic>;

    // Get all unique keys (months) from both backup and local
    final allKeys = <String>{
      ...backupIncomeData.keys,
      ...localData.keys,
    };

    for (final key in allKeys) {
      // Get entries from backup
      final backupEntries = <IncomeEntry>[];
      if (backupIncomeData.containsKey(key)) {
        final backupList = backupIncomeData[key];
        if (backupList is List) {
          for (final item in backupList) {
            try {
              if (item is Map<String, dynamic>) {
                backupEntries.add(IncomeEntry.fromJson(item));
              } else if (item is IncomeEntry) {
                backupEntries.add(item);
              }
            } catch (e) {
              if (kDebugMode) {
                print('⚠️ Error parsing backup income entry: $e');
              }
            }
          }
        }
      }

      // Get entries from local
      final localEntries = localData[key] ?? [];

      // Merge using SmartMergeService
      final merged = await _mergeService.mergeIncomeEntries(
        backupEntries: backupEntries,
        localEntries: localEntries,
      );

      mergedData[key] = merged;

      if (kDebugMode) {
        print('📊 Merged $key: ${backupEntries.length} backup + ${localEntries.length} local = ${merged.length} total');
      }
    }

    return mergedData;
  }

  /// Merge outcome data using SmartMergeService
  Future<Map<String, List<OutcomeEntry>>> _mergeOutcomeData({
    required Map<String, dynamic> backupData,
    required Map<String, List<OutcomeEntry>> localData,
  }) async {
    final Map<String, List<OutcomeEntry>> mergedData = {};

    if (!backupData.containsKey('outcome_entries')) {
      return localData; // No backup data, return local
    }

    final backupOutcomeData = backupData['outcome_entries'] as Map<String, dynamic>;

    // Get all unique keys (months) from both backup and local
    final allKeys = <String>{
      ...backupOutcomeData.keys,
      ...localData.keys,
    };

    for (final key in allKeys) {
      // Get entries from backup
      final backupEntries = <OutcomeEntry>[];
      if (backupOutcomeData.containsKey(key)) {
        final backupList = backupOutcomeData[key];
        if (backupList is List) {
          for (final item in backupList) {
            try {
              if (item is Map<String, dynamic>) {
                backupEntries.add(OutcomeEntry.fromJson(item));
              } else if (item is OutcomeEntry) {
                backupEntries.add(item);
              }
            } catch (e) {
              if (kDebugMode) {
                print('⚠️ Error parsing backup outcome entry: $e');
              }
            }
          }
        }
      }

      // Get entries from local
      final localEntries = localData[key] ?? [];

      // Merge using SmartMergeService
      final merged = await _mergeService.mergeOutcomeEntries(
        backupEntries: backupEntries,
        localEntries: localEntries,
      );

      mergedData[key] = merged;

      if (kDebugMode) {
        print('📊 Merged $key: ${backupEntries.length} backup + ${localEntries.length} local = ${merged.length} total');
      }
    }

    return mergedData;
  }

  /// Write merged data to Hive
  Future<void> _writeMergedDataToHive(
    Map<String, List<IncomeEntry>> mergedIncome,
    Map<String, List<OutcomeEntry>> mergedOutcome,
  ) async {
    // Write income data
    final incomeBox = await Hive.openBox<List<dynamic>>('income_entries');
    await incomeBox.clear(); // Clear old data
    for (final entry in mergedIncome.entries) {
      await incomeBox.put(entry.key, entry.value);
    }

    if (kDebugMode) {
      print('✅ Wrote ${mergedIncome.length} months of income data');
    }

    // Write outcome data
    final outcomeBox = await Hive.openBox<List<dynamic>>('outcome_entries');
    await outcomeBox.clear(); // Clear old data
    for (final entry in mergedOutcome.entries) {
      await outcomeBox.put(entry.key, entry.value);
    }

    if (kDebugMode) {
      print('✅ Wrote ${mergedOutcome.length} months of outcome data');
    }
  }
}
```

### Phase 4: UI Updates (Week 3)

#### Task 4.1: Update Restore Confirmation Dialog
**File:** `lib/backup/ui/backup_bottom_sheet.dart`

```dart
// Update the confirmation dialog text
final confirmed = await showDialog<bool>(
  context: context,
  builder: (context) => AlertDialog(
    title: const Row(
      children: [
        Icon(Icons.merge_type, color: Colors.blue),
        SizedBox(width: 8),
        Text('Smart Restore'),
      ],
    ),
    content: const Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'This will intelligently merge your backup data with current data.',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text('Your local data will be preserved'),
            ),
          ],
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text('Conflicts resolved automatically'),
            ),
          ],
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text('No duplicate entries'),
            ),
          ],
        ),
        SizedBox(height: 16),
        Text(
          'A safety backup will be created first.',
          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: const Text('Cancel'),
      ),
      ElevatedButton.icon(
        onPressed: () => Navigator.pop(context, true),
        icon: const Icon(Icons.merge_type),
        label: const Text('Smart Restore'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
      ),
    ],
  ),
);
```

#### Task 4.2: Create Merge Success Dialog
**File:** `lib/backup/ui/merge_success_dialog.dart`

```dart
import 'package:flutter/material.dart';
import '../models/merge_result.dart';

/// Dialog showing detailed merge statistics
class MergeSuccessDialog extends StatelessWidget {
  final MergeResult result;

  const MergeSuccessDialog({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 32),
          SizedBox(width: 12),
          Text('Restore Complete!'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your data has been successfully merged.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),

            // Overall Statistics
            _buildSectionTitle('📊 Merge Summary'),
            const SizedBox(height: 12),
            _buildStatRow('Total Entries', result.totalEntries.toString()),
            _buildStatRow('From Backup', result.entriesFromBackup.toString()),
            _buildStatRow('From Local', result.entriesFromLocal.toString()),
            _buildStatRow('Conflicts Resolved', result.conflictsResolved.toString()),
            _buildStatRow('Duplicates Skipped', result.duplicatesSkipped.toString()),

            const SizedBox(height: 16),

            // Income Statistics
            _buildSectionTitle('💰 Income'),
            const SizedBox(height: 12),
            _buildStatRow('Total', result.statistics.income.total.toString()),
            _buildStatRow('From Backup', result.statistics.income.fromBackup.toString()),
            _buildStatRow('From Local', result.statistics.income.fromLocal.toString()),

            const SizedBox(height: 16),

            // Outcome Statistics
            _buildSectionTitle('💸 Expenses'),
            const SizedBox(height: 12),
            _buildStatRow('Total', result.statistics.outcome.total.toString()),
            _buildStatRow('From Backup', result.statistics.outcome.fromBackup.toString()),
            _buildStatRow('From Local', result.statistics.outcome.fromLocal.toString()),

            const SizedBox(height: 16),

            // Duration
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer, size: 20, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    'Completed in ${result.duration.inMilliseconds}ms',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
```

### Phase 5: Data Migration (Week 3)

#### Task 5.1: Create Migration Service
**File:** `lib/services/data_migration_service.dart`

```dart
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/income_entry.dart';
import '../models/outcome_entry.dart';

/// Service to migrate existing data to new schema with UUIDs
class DataMigrationService {
  static const String _migrationKey = 'uuid_migration_completed';

  /// Check if migration is needed
  Future<bool> needsMigration() async {
    try {
      final box = await Hive.openBox('app_settings');
      final completed = box.get(_migrationKey, defaultValue: false);
      return !completed;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking migration status: $e');
      }
      return false;
    }
  }

  /// Migrate all existing entries to include UUIDs
  Future<void> migrateToUUIDs() async {
    if (kDebugMode) {
      print('🔄 Starting UUID migration...');
    }

    try {
      // Migrate income entries
      await _migrateIncomeEntries();

      // Migrate outcome entries
      await _migrateOutcomeEntries();

      // Mark migration as complete
      final settingsBox = await Hive.openBox('app_settings');
      await settingsBox.put(_migrationKey, true);

      if (kDebugMode) {
        print('✅ UUID migration completed successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Migration failed: $e');
      }
      rethrow;
    }
  }

  /// Migrate income entries
  Future<void> _migrateIncomeEntries() async {
    final incomeBox = await Hive.openBox<List<dynamic>>('income_entries');
    int migratedCount = 0;

    for (final key in incomeBox.keys) {
      final entries = incomeBox.get(key);
      if (entries == null || entries is! List) continue;

      final migratedEntries = <IncomeEntry>[];

      for (final entry in entries) {
        if (entry is IncomeEntry) {
          // Check if already has UUID
          try {
            if (entry.id.isEmpty) {
              // ✨ v1.1: Generate deterministic UUID with prefix
              final uuid = _generateDeterministicUUID(
                '${entry.date}_${entry.amount}_${entry.name}',
                prefix: 'inc_',
              );

              // Create new entry with UUID
              final migratedEntry = IncomeEntry(
                amount: entry.amount,
                name: entry.name,
                date: entry.date,
                createdAt: entry.createdAt,
                id: uuid,
                version: 1,
              );

              migratedEntries.add(migratedEntry);
              migratedCount++;
            } else {
              // Already has UUID, keep as is
              migratedEntries.add(entry);
            }
          } catch (e) {
            // No UUID field yet, add it with prefix
            final uuid = _generateDeterministicUUID(
              '${entry.date}_${entry.amount}_${entry.name}',
              prefix: 'inc_',
            );

            final migratedEntry = IncomeEntry(
              amount: entry.amount,
              name: entry.name,
              date: entry.date,
              createdAt: entry.createdAt,
              id: uuid,
              version: 1,
            );

            migratedEntries.add(migratedEntry);
            migratedCount++;
          }
        }
      }

      // Save migrated entries
      await incomeBox.put(key, migratedEntries);
    }

    if (kDebugMode) {
      print('✅ Migrated $migratedCount income entries');
    }
  }

  /// Migrate outcome entries
  Future<void> _migrateOutcomeEntries() async {
    final outcomeBox = await Hive.openBox<List<dynamic>>('outcome_entries');
    int migratedCount = 0;

    for (final key in outcomeBox.keys) {
      final entries = outcomeBox.get(key);
      if (entries == null || entries is! List) continue;

      final migratedEntries = <OutcomeEntry>[];

      for (final entry in entries) {
        if (entry is OutcomeEntry) {
          // Check if already has UUID
          try {
            if (entry.id.isEmpty) {
              // ✨ v1.1: Generate deterministic UUID with prefix
              final uuid = _generateDeterministicUUID(
                '${entry.date}_${entry.amount}_${entry.description}',
                prefix: 'out_',
              );

              final migratedEntry = OutcomeEntry(
                description: entry.description,
                amount: entry.amount,
                date: entry.date,
                id: uuid,
                createdAt: DateTime.now(),
                version: 1,
              );

              migratedEntries.add(migratedEntry);
              migratedCount++;
            } else {
              migratedEntries.add(entry);
            }
          } catch (e) {
            // No UUID field yet, add it with prefix
            final uuid = _generateDeterministicUUID(
              '${entry.date}_${entry.amount}_${entry.description}',
              prefix: 'out_',
            );

            final migratedEntry = OutcomeEntry(
              description: entry.description,
              amount: entry.amount,
              date: entry.date,
              id: uuid,
              createdAt: DateTime.now(),
              version: 1,
            );

            migratedEntries.add(migratedEntry);
            migratedCount++;
          }
        }
      }

      await outcomeBox.put(key, migratedEntries);
    }

    if (kDebugMode) {
      print('✅ Migrated $migratedCount outcome entries');
    }
  }

  /// Generate deterministic UUID from entry data
  /// This ensures same entry always gets same UUID
  /// ✨ v1.1: Added prefix parameter for type safety
  String _generateDeterministicUUID(String data, {String prefix = ''}) {
    const uuid = Uuid();
    final baseUuid = uuid.v5(Uuid.NAMESPACE_OID, data);
    return prefix.isEmpty ? baseUuid : '$prefix$baseUuid';
  }
}
```

#### Task 5.2: Run Migration on App Start
**File:** `lib/main.dart`

```dart
import 'services/data_migration_service.dart';

// In main() function, after Hive initialization
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ... existing initialization code ...

  // Run data migration if needed
  final migrationService = DataMigrationService();
  if (await migrationService.needsMigration()) {
    print('🔄 Running data migration...');
    await migrationService.migrateToUUIDs();
    print('✅ Migration complete');
  }

  runApp(const AlKhaznaApp());
}
```

---

## 🧪 10. Testing Strategy

### 10.1 Unit Tests

#### Test File: `test/smart_merge_service_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:alkhazna/models/income_entry.dart';
import 'package:alkhazna/backup/services/smart_merge_service.dart';

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
          amount: 1000,
          name: 'Salary',
          date: '2025-01-01',
          id: 'uuid-1',
        ),
      ];

      final local = [
        IncomeEntry(
          amount: 500,
          name: 'Bonus',
          date: '2025-01-15',
          id: 'uuid-2',
        ),
      ];

      // Act
      final merged = await mergeService.mergeIncomeEntries(
        backupEntries: backup,
        localEntries: local,
      );

      // Assert
      expect(merged.length, 2);
      expect(merged.any((e) => e.id == 'uuid-1'), true);
      expect(merged.any((e) => e.id == 'uuid-2'), true);
    });

    test('Resolve conflict - backup newer', () async {
      // Arrange
      final oldTime = DateTime(2025, 1, 1);
      final newTime = DateTime(2025, 1, 15);

      final backup = [
        IncomeEntry(
          amount: 2000,
          name: 'Updated Salary',
          date: '2025-01-01',
          id: 'uuid-1',
          createdAt: oldTime,
          updatedAt: newTime,
          version: 2,
        ),
      ];

      final local = [
        IncomeEntry(
          amount: 1000,
          name: 'Salary',
          date: '2025-01-01',
          id: 'uuid-1',
          createdAt: oldTime,
          version: 1,
        ),
      ];

      // Act
      final merged = await mergeService.mergeIncomeEntries(
        backupEntries: backup,
        localEntries: local,
      );

      // Assert
      expect(merged.length, 1);
      expect(merged.first.amount, 2000);
      expect(merged.first.name, 'Updated Salary');
    });

    test('Resolve conflict - local newer', () async {
      // Arrange
      final oldTime = DateTime(2025, 1, 1);
      final newTime = DateTime(2025, 1, 15);

      final backup = [
        IncomeEntry(
          amount: 1000,
          name: 'Salary',
          date: '2025-01-01',
          id: 'uuid-1',
          createdAt: oldTime,
          version: 1,
        ),
      ];

      final local = [
        IncomeEntry(
          amount: 2000,
          name: 'Updated Salary',
          date: '2025-01-01',
          id: 'uuid-1',
          createdAt: oldTime,
          updatedAt: newTime,
          version: 2,
        ),
      ];

      // Act
      final merged = await mergeService.mergeIncomeEntries(
        backupEntries: backup,
        localEntries: local,
      );

      // Assert
      expect(merged.length, 1);
      expect(merged.first.amount, 2000);
      expect(merged.first.name, 'Updated Salary');
    });
  });
}
```

### 10.2 Integration Tests

#### Test Scenarios

| Scenario | Expected Result |
|----------|----------------|
| Restore with empty local data | All backup data imported |
| Restore with empty backup | All local data preserved |
| Restore with identical data | No duplicates, single copy kept |
| Restore with conflicts | Newest version kept |
| Restore with network failure | Rollback, local data intact |
| Restore with corrupted backup | Error shown, local data intact |

### 10.3 User Acceptance Testing

**Test Cases:**
1. ✅ User restores old backup without losing recent transactions
2. ✅ No duplicate entries appear after restore
3. ✅ Conflicts resolved automatically (newest wins)
4. ✅ UI refreshes immediately showing all merged data
5. ✅ Safety backup created before restore
6. ✅ Can rollback if needed

---

## ⚠️ 11. Edge Cases

### 11.1 Identified Edge Cases

| Edge Case | Handling Strategy |
|-----------|------------------|
| **Backup older than 30 days** | Show warning, allow proceed |
| **Local data > 1000 entries** | Show progress, paginate merge |
| **Corrupted UUID** | Regenerate deterministic UUID |
| **Same timestamp & version** | Keep local (safer) |
| **Network timeout** | Retry 3 times, then fail gracefully |
| **Hive write failure** | Rollback to pre-restore state |
| **Partial merge completion** | Use transaction, all-or-nothing |

### 11.2 Error Handling

```dart
try {
  // Restore operation
} on NetworkException {
  return RestoreResult.failure('Network error. Please check connection.');
} on StorageException {
  return RestoreResult.failure('Storage error. Please free up space.');
} on CorruptedBackupException {
  return RestoreResult.failure('Backup file is corrupted.');
} catch (e) {
  return RestoreResult.failure('Unknown error: ${e.toString()}');
}
```

---

## 📊 12. Success Metrics

### 12.1 Key Performance Indicators (KPIs)

| Metric | Target | Measurement |
|--------|--------|-------------|
| **Data Loss Rate** | 0% | User reports |
| **Merge Accuracy** | 100% | Automated tests |
| **Restore Success Rate** | >95% | Analytics |
| **Average Restore Time** | <10s | Performance monitoring |
| **User Satisfaction** | >4.5/5 | App store reviews |
| **Conflict Resolution Accuracy** | >99% | Manual verification |

### 12.2 Success Criteria

**Must Have (P0):**
- ✅ Zero data loss in restore operations
- ✅ No duplicate entries after merge
- ✅ Automatic conflict resolution
- ✅ Backward compatible with old backups

**Should Have (P1):**
- ✅ Restore completes in <10 seconds
- ✅ Clear progress indicators
- ✅ Detailed merge statistics
- ✅ Safety backup before restore

**Nice to Have (P2):**
- 🔲 Undo restore feature
- 🔲 Preview merge before applying
- 🔲 Export merge report
- 🔲 Advanced conflict resolution options

---

## 📦 13. Dependencies

### 13.1 New Dependencies (v1.1 Updated)

Add to `pubspec.yaml`:

```yaml
dependencies:
  uuid: ^4.5.1  # For generating UUIDs with prefixes
  logger: ^2.5.0  # ✨ v1.1: Structured logging for production debugging

dev_dependencies:
  mockito: ^5.4.4  # For testing
  build_runner: ^2.4.13  # For code generation
```

Run after adding:
```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### 13.2 Import Requirements (v1.1)

The following imports will be needed in your files:

```dart
// For SmartMergeService
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

// For BackupService
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
```

### 13.3 Logger Configuration (v1.1)

Configure logger in your app initialization:

```dart
// lib/utils/app_logger.dart
import 'package:logger/logger.dart';

class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
    level: kReleaseMode ? Level.warning : Level.debug,
  );

  static Logger get instance => _logger;
}
```

---

## 🚀 14. Rollout Plan

### Phase 1: Development (Week 1-2)
- Implement data models with UUIDs
- Create SmartMergeService
- Write unit tests

### Phase 2: Integration (Week 2-3)
- Update BackupService
- Integrate merge logic
- Update UI components

### Phase 3: Testing (Week 3)
- Run migration service
- Conduct UAT
- Fix bugs

### Phase 4: Release (Week 4)
- Beta release to 10% users
- Monitor metrics
- Full rollout if stable

---

## 📝 15. Risks & Mitigation

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| **Data corruption** | Low | Critical | Atomic transactions, safety backups |
| **Performance issues** | Medium | Medium | Optimize merge algorithm, paginate |
| **User confusion** | Low | Low | Clear UI messages, help docs |
| **Backward compatibility** | Low | High | Migration service, extensive testing |
| **Network failures** | High | Low | Retry logic, offline support |

---

## ✅ 16. Checklist

### Pre-Development
- [ ] PRD reviewed and approved
- [ ] Technical architecture validated
- [ ] Dependencies identified
- [ ] Test plan created

### Development
- [ ] Data models updated
- [ ] SmartMergeService implemented
- [ ] BackupService integrated
- [ ] UI updated
- [ ] Migration service created

### Testing
- [ ] Unit tests passing
- [ ] Integration tests passing
- [ ] UAT completed
- [ ] Edge cases covered

### Deployment
- [ ] Beta release successful
- [ ] Metrics monitored
- [ ] User feedback collected
- [ ] Full rollout approved

---

## 📚 17. Appendix

### A. Glossary

| Term | Definition |
|------|------------|
| **Smart Merge** | Intelligent combination of backup and local data |
| **Conflict Resolution** | Process of choosing between duplicate entries |
| **UUID** | Universally Unique Identifier for entries |
| **Deterministic UUID** | UUID generated from entry data, always same for same input |
| **Safety Backup** | Automatic backup created before restore |

### B. References

- [WhatsApp Backup System](https://faq.whatsapp.com/android/chats/how-to-restore-your-chat-history/)
- [UUID RFC 4122](https://tools.ietf.org/html/rfc4122)
- [Hive Documentation](https://docs.hivedb.dev/)
- [Flutter Best Practices](https://flutter.dev/docs/development/data-and-backend/state-mgmt/options)

---

## 🎨 18. v1.1 Enhancement Details

### 18.1 What's New in v1.1

This section documents the four critical enhancements added to version 1.1 of the Smart Restore System.

#### Enhancement 1: 🧱 Actual Safety Backup Implementation

**Priority:** P0 (Critical)
**Status:** Implemented
**Impact:** Prevents data loss if restore fails

**What Changed:**
- Replaced placeholder `_createSafetyBackup()` with full implementation
- Creates local backup before every restore operation
- Optionally uploads to Firebase Storage for cloud redundancy
- Automatically cleans up old backups (keeps last 5)
- Stores backups in `safety_backups/` directory
- Uses timestamped filenames: `pre_restore_2025-01-18T10-30-00.json`

**Code Location:**
- `lib/backup/services/backup_service.dart` lines 1389-1491

**Benefits:**
- ✅ Users can rollback if restore fails
- ✅ Zero risk of permanent data loss
- ✅ Both local and cloud backup available
- ✅ Automatic cleanup prevents storage bloat

---

#### Enhancement 2: 📊 Extended Merge Statistics

**Priority:** P0 (Critical)
**Status:** Implemented
**Impact:** Provides transparency and debugging capability

**What Changed:**
- Enhanced `MergeResult` model with conflict tracking
- Added `ConflictDetail` class to record each conflict resolution
- Tracks which entries were kept from backup vs. local
- Records resolution reason (newer_timestamp, higher_version, etc.)
- Provides per-month breakdown of merged entries

**New Data Structures:**
```dart
class ConflictDetail {
  final String entryId;
  final String entryName;
  final String entryType;
  final DateTime backupTimestamp;
  final DateTime localTimestamp;
  final String resolution;
  final String reason;
}
```

**Benefits:**
- ✅ Users see exactly what was merged
- ✅ Developers can debug merge issues
- ✅ Transparent conflict resolution
- ✅ Build user trust in the system

---

#### Enhancement 3: 🏷️ UUID Prefixes for Type Safety

**Priority:** P1 (High)
**Status:** Implemented
**Impact:** Prevents cross-type collisions, easier debugging

**What Changed:**
- Income UUIDs now use `inc_` prefix: `inc_<uuid-v4>`
- Outcome UUIDs now use `out_` prefix: `out_<uuid-v4>`
- Updated constructors in both entry models
- UUID generation: `'inc_${const Uuid().v4()}'`

**Example:**
```dart
// Before: "550e8400-e29b-41d4-a716-446655440000"
// After:  "inc_550e8400-e29b-41d4-a716-446655440000"
```

**Benefits:**
- ✅ Immediately identify entry type from ID
- ✅ Prevent theoretical cross-type UUID collisions
- ✅ Easier debugging in logs and database
- ✅ Professional best practice

---

#### Enhancement 4: 📝 Structured Logging with Logger Package

**Priority:** P1 (High)
**Status:** Implemented
**Impact:** Professional production debugging

**What Changed:**
- Replaced all `print()` and `if (kDebugMode) print()` statements
- Integrated `logger` package (v2.5.0)
- Configured with PrettyPrinter for readable output
- Log levels: Debug, Info, Warning, Error
- Color-coded output with emojis
- Automatic timestamp and method context

**Log Levels:**
- `_logger.d()` - Debug (verbose details)
- `_logger.i()` - Info (important milestones)
- `_logger.w()` - Warning (potential issues)
- `_logger.e()` - Error (failures with stack traces)

**Example Output:**
```
💡 [DEBUG] SmartMerge: Added 23 local income entries
ℹ️  [INFO] Income merge complete in 45ms
⚠️  [WARN] Conflict resolved for: Salary
❌ [ERROR] Failed to create safety backup: StorageException
```

**Benefits:**
- ✅ Filter logs by level (debug/production)
- ✅ Easier troubleshooting in production
- ✅ Structured log parsing for analytics
- ✅ Better developer experience

---

### 18.2 Implementation Checklist (v1.1)

**Data Models:**
- [x] Add `inc_` prefix to IncomeEntry UUID generation
- [x] Add `out_` prefix to OutcomeEntry UUID generation
- [x] Add `ConflictDetail` class to merge_result.dart
- [x] Extend `MergeResult` with conflicts list

**Services:**
- [x] Implement actual `_createSafetyBackup()` method
- [x] Add `_cleanupOldSafetyBackups()` helper
- [x] Replace print() with _logger.d/i/w/e() in SmartMergeService
- [x] Add conflict detail tracking in merge algorithm
- [x] Add `_getConflictReason()` helper method

**Dependencies:**
- [x] Add `logger: ^2.5.0` to pubspec.yaml
- [x] Update `uuid` to `^4.5.1`
- [x] Document import requirements

**Documentation:**
- [x] Update PRD version to 1.1.0
- [x] Document all enhancements
- [x] Add this comprehensive v1.1 section
- [x] Update implementation examples with v1.1 code

---

### 18.3 Migration from v1.0 to v1.1

**Breaking Changes:** None
**Backward Compatible:** Yes

**Steps to Upgrade:**
1. Add new dependencies to `pubspec.yaml`
2. Run `flutter pub get`
3. Update IncomeEntry/OutcomeEntry constructors with prefixes
4. Replace SmartMergeService with v1.1 version (logger support)
5. Replace BackupService._createSafetyBackup() with v1.1 implementation
6. Regenerate Hive adapters: `flutter pub run build_runner build`
7. Test restore flow end-to-end

**Data Migration:** Not required - existing UUIDs work fine, new entries get prefixes

---

### 18.4 Deferred to Future Versions

**Not Included in v1.1 (But Recommended for Future):**

**v1.2 Candidates:**
- ⚙️ Isolate-based merge for datasets > 1000 entries
- 🎨 Lottie animations in merge success dialog
- 📄 JSON merge report export

**v2.0 Candidates:**
- ☁️ Bidirectional sync across multiple devices
- 🔄 Real-time conflict resolution
- 📤 PDF merge report generation

---

## 🔄 19. Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2025-01-18 | Dev Team | Initial PRD creation |
| 1.1.0 | 2025-01-18 | Dev Team | Added 4 critical enhancements: Safety Backup, Extended Stats, UUID Prefixes, Structured Logging |

---

**END OF PRD**

*This is a living document and will be updated as requirements evolve.*
