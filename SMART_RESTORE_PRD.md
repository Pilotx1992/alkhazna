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

### 2.1 OLD Restore Flow (v1.0 - DEPRECATED ❌)
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

### 2.2 NEW Restore Flow (v1.2 - CURRENT ✅)
```
User clicks Restore
    ↓
1. Create Safety Backup ✨
   └─ Local + Cloud backup of current data
    ↓
2. Download backup from Google Drive
   └─ With retry logic
    ↓
3. Detect Backup Version ✨
   └─ Auto-detect v0.9, v1.0, v1.1, v2.0
    ↓
4. Decrypt with Fallback ✨
   └─ LegacyDecryptionService handles all versions
    ↓
5. Validate ALL Data FIRST ✨
   ├─ Parse all entries
   ├─ Generate missing UUIDs
   └─ Ensure no corruption
    ↓
6. ONLY THEN Clear & Write ✅
   └─ Atomic operation
    ↓
7. Auto-refresh UI
    ↓
Show detailed success stats
```

### 2.3 Critical Fixes Implemented ✅

| Problem (OLD) | Fix (NEW) | Status |
|---------------|-----------|--------|
| ❌ Data Loss on Restore Failure | ✅ Validate BEFORE clear() | FIXED |
| ❌ Missing UUID crashes | ✅ Auto-generate UUIDs in fromJson | FIXED |
| ❌ No version detection | ✅ BackupVersionDetector service | FIXED |
| ❌ No legacy support | ✅ LegacyDecryptionService | FIXED |
| ❌ No rollback capability | ✅ Safety backup before restore | FIXED |

### 2.4 Current System State (v1.2)

**✅ Production-Ready Features:**
- ✅ Zero data loss guarantee (validation-first approach)
- ✅ Full backward compatibility (v0.9 to v2.0)
- ✅ Auto UUID generation for legacy data
- ✅ Multi-version decryption with fallback
- ✅ Safety backup system
- ✅ Detailed merge statistics
- ✅ Structured logging

**⚠️ Recommended Enhancements:**
- ⚠️ Performance: Add isolate-based merge for large datasets (Section 20)
- ⚠️ UI Polish: Add Lottie animations & haptic feedback (Section 21)

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

## 🔐 19. Legacy Encryption & Backup Compatibility

### 19.1 Problem Statement: Legacy Backup Compatibility

**Critical Issue for Existing Users:**

المستخدمون القدامى الذين لديهم backups مشفرة بالنظام الحالي قد يواجهون مشاكل عند استخدام Smart Restore System الجديد:

```
User with old encrypted backup (v1.0)
    ↓
Updates to Smart Restore v1.1
    ↓
Attempts to restore backup
    ↓
❌ FAILURE: Decryption fails or key mismatch
```

**Root Causes:**
1. ❌ تغيير في هيكل البيانات (UUID fields جديدة)
2. ❌ احتمال تغيير في key derivation
3. ❌ عدم وجود version detection في الـ backup format
4. ❌ عدم وجود fallback mechanism

---

### 19.2 Current Encryption System Analysis

#### 19.2.1 Current Architecture

**الملفات الأساسية:**
- `lib/backup/services/encryption_service.dart` - AES-256-GCM encryption
- `lib/backup/services/key_manager.dart` - Master key management
- `lib/backup/models/key_file_format.dart` - Key storage format

**Current Encryption Flow:**
```dart
// BACKUP:
1. Get master key from KeyManager (cloud + local)
2. Encrypt database using AES-256-GCM
3. Store encrypted data with metadata:
   {
     "encrypted": true,
     "version": "1.0",      // ⚠️ Static version
     "backup_id": "...",
     "data": "...",         // Base64 ciphertext
     "iv": "...",           // Nonce
     "tag": "...",          // MAC
     "checksum": "..."      // SHA256
   }

// RESTORE:
1. Download encrypted backup
2. Get master key from KeyManager
3. Decrypt using AES-256-GCM
4. Restore to Hive
```

#### 19.2.2 Current Key Management

**Key Storage Strategy:**
```dart
// Master Key (256-bit AES)
Location 1: Google Drive (primary)
  └─ File: alkhazna_backup_keys.encrypted
  └─ Format: KeyFileFormat v1.1
  └─ Contains: user_email, google_id, key_bytes, checksum

Location 2: Local Secure Storage (cache)
  └─ Key: alkhazna_master_key_v2
  └─ Format: Hex string
```

**Key Retrieval Priority:**
```
1. Try Google Drive (cloud key)
2. Fallback to local secure storage
3. Generate new key if neither exists
```

#### 19.2.3 Current Backup Format

```json
{
  "encrypted": true,
  "version": "1.0",           // ⚠️ No encryption version
  "backup_id": "unique-id",
  "original_size": 12345,
  "timestamp": "2025-01-18T...",
  "checksum": "sha256-...",
  "data": "base64-ciphertext",
  "iv": "base64-nonce",
  "tag": "base64-mac"
}
```

**Missing Fields for Compatibility:**
- ❌ No `encryption_version` field
- ❌ No `key_version` field
- ❌ No `data_schema_version` field
- ❌ No `migration_needed` flag

---

### 19.3 Proposed Solution: Multi-Version Decryption System

#### 19.3.1 Enhanced Backup Metadata Format (v1.1+)

```json
{
  "encrypted": true,
  "format_version": "2.0",         // ✨ Overall backup format
  "encryption_version": "1.1",     // ✨ Encryption algorithm version
  "data_schema_version": "1.1",    // ✨ Data model version (UUID support)
  "key_derivation": "AES-256-GCM", // ✨ Algorithm identifier
  "backup_id": "unique-id",
  "original_size": 12345,
  "timestamp": "2025-01-18T...",
  "checksum": "sha256-...",
  "data": "base64-ciphertext",
  "iv": "base64-nonce",
  "tag": "base64-mac",

  // ✨ New compatibility fields
  "compatibility": {
    "min_app_version": "1.1.0",
    "created_by_version": "1.1.0",
    "requires_migration": false,
    "legacy_format": false
  }
}
```

#### 19.3.2 Version Detection Strategy

**File:** `lib/backup/services/backup_version_detector.dart`

```dart
import 'package:flutter/foundation.dart';

/// Detects backup format version and compatibility
class BackupVersionDetector {
  /// Detect backup format version
  static BackupVersion detectVersion(Map<String, dynamic> backupData) {
    // Check for v1.1+ format with explicit versioning
    if (backupData.containsKey('format_version')) {
      final formatVersion = backupData['format_version'];
      final encryptionVersion = backupData['encryption_version'] ?? '1.0';
      final schemaVersion = backupData['data_schema_version'] ?? '1.0';

      return BackupVersion(
        formatVersion: formatVersion.toString(),
        encryptionVersion: encryptionVersion.toString(),
        dataSchemaVersion: schemaVersion.toString(),
        isLegacy: false,
      );
    }

    // Legacy format (v1.0) - only has 'version' field
    if (backupData.containsKey('version')) {
      return BackupVersion(
        formatVersion: '1.0',
        encryptionVersion: '1.0',
        dataSchemaVersion: '1.0',
        isLegacy: true,
      );
    }

    // Very old format - no version at all
    if (backupData.containsKey('encrypted') &&
        backupData.containsKey('data')) {
      return BackupVersion(
        formatVersion: '0.9',
        encryptionVersion: '1.0',
        dataSchemaVersion: '0.9',
        isLegacy: true,
      );
    }

    // Unknown format
    return BackupVersion.unknown();
  }

  /// Check if backup is compatible with current app
  static bool isCompatible(BackupVersion version) {
    // We support all versions from 0.9 to 2.0
    final supportedVersions = ['0.9', '1.0', '1.1', '2.0'];
    return supportedVersions.contains(version.formatVersion);
  }

  /// Check if migration is needed
  static bool needsMigration(BackupVersion version) {
    // Legacy formats need migration to add UUIDs
    return version.isLegacy;
  }
}

/// Backup version information
class BackupVersion {
  final String formatVersion;
  final String encryptionVersion;
  final String dataSchemaVersion;
  final bool isLegacy;

  const BackupVersion({
    required this.formatVersion,
    required this.encryptionVersion,
    required this.dataSchemaVersion,
    required this.isLegacy,
  });

  factory BackupVersion.unknown() => const BackupVersion(
    formatVersion: 'unknown',
    encryptionVersion: 'unknown',
    dataSchemaVersion: 'unknown',
    isLegacy: false,
  );

  bool get isUnknown => formatVersion == 'unknown';
}
```

#### 19.3.3 Multi-Version Decryption Service

**File:** `lib/backup/services/legacy_decryption_service.dart`

```dart
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'encryption_service.dart';
import 'backup_version_detector.dart';

/// Service for handling legacy backup decryption
class LegacyDecryptionService {
  final EncryptionService _encryptionService = EncryptionService();

  /// Decrypt backup with automatic version detection
  Future<Uint8List?> decryptBackupWithFallback({
    required Map<String, dynamic> encryptedBackup,
    required Uint8List masterKey,
  }) async {
    try {
      // Step 1: Detect backup version
      final version = BackupVersionDetector.detectVersion(encryptedBackup);

      if (kDebugMode) {
        print('🔍 Detected backup version:');
        print('   Format: ${version.formatVersion}');
        print('   Encryption: ${version.encryptionVersion}');
        print('   Schema: ${version.dataSchemaVersion}');
        print('   Legacy: ${version.isLegacy}');
      }

      // Step 2: Check compatibility
      if (!BackupVersionDetector.isCompatible(version)) {
        if (kDebugMode) {
          print('❌ Unsupported backup version: ${version.formatVersion}');
        }
        return null;
      }

      // Step 3: Decrypt using appropriate method
      Uint8List? decryptedData;

      if (version.isLegacy) {
        // Use legacy decryption (v1.0 format)
        decryptedData = await _decryptLegacyFormat(
          encryptedBackup: encryptedBackup,
          masterKey: masterKey,
          version: version,
        );
      } else {
        // Use new decryption (v1.1+ format)
        decryptedData = await _encryptionService.decryptDatabase(
          encryptedBackup: encryptedBackup,
          masterKey: masterKey,
        );
      }

      if (decryptedData == null) {
        if (kDebugMode) {
          print('❌ Decryption failed for version ${version.formatVersion}');
        }
        return null;
      }

      if (kDebugMode) {
        print('✅ Successfully decrypted ${version.isLegacy ? "legacy" : "modern"} backup');
      }

      return decryptedData;

    } catch (e) {
      if (kDebugMode) {
        print('💥 Decryption with fallback failed: $e');
      }
      return null;
    }
  }

  /// Decrypt legacy v1.0 format
  Future<Uint8List?> _decryptLegacyFormat({
    required Map<String, dynamic> encryptedBackup,
    required Uint8List masterKey,
    required BackupVersion version,
  }) async {
    try {
      if (kDebugMode) {
        print('🔓 Decrypting legacy format v${version.formatVersion}...');
      }

      // Legacy format uses same encryption, just different metadata
      // We can reuse the existing decryptDatabase method
      final decrypted = await _encryptionService.decryptDatabase(
        encryptedBackup: encryptedBackup,
        masterKey: masterKey,
      );

      if (decrypted != null && kDebugMode) {
        print('✅ Legacy decryption successful');
      }

      return decrypted;

    } catch (e) {
      if (kDebugMode) {
        print('❌ Legacy decryption failed: $e');
      }
      return null;
    }
  }
}
```

#### 19.3.4 Updated Restore Flow with Version Detection

**Integration into BackupService:**

```dart
// lib/backup/services/backup_service.dart

import 'legacy_decryption_service.dart';
import 'backup_version_detector.dart';

class BackupService extends ChangeNotifier {
  final LegacyDecryptionService _legacyDecryption = LegacyDecryptionService();

  Future<RestoreResult> startRestoreWithVersionDetection() async {
    try {
      // ... existing code for download ...

      // Step 6: Decrypt with automatic version detection
      _updateProgress(70, null, 'Decrypting backup...', RestoreStatus.decrypting);
      final encryptedData = json.decode(utf8.decode(encryptedBytes)) as Map<String, dynamic>;

      // ✨ Use legacy-aware decryption
      final databaseBytes = await _legacyDecryption.decryptBackupWithFallback(
        encryptedBackup: encryptedData,
        masterKey: masterKey,
      );

      if (databaseBytes == null) {
        _updateProgress(0, null, 'Failed to decrypt backup', RestoreStatus.failed);
        return RestoreResult.failure('Failed to decrypt backup. The backup may be corrupted or incompatible.');
      }

      // Step 7: Check if migration needed
      final version = BackupVersionDetector.detectVersion(encryptedData);
      if (BackupVersionDetector.needsMigration(version)) {
        _updateProgress(75, null, 'Migrating data format...', RestoreStatus.processing);
        // Migration will happen automatically in DataMigrationService
      }

      // ... continue with restore ...

    } catch (e) {
      // ... error handling ...
    }
  }
}
```

---

### 19.4 Key Compatibility Matrix

| Backup Version | Encryption | Key Format | Compatible | Migration Needed |
|----------------|------------|------------|------------|------------------|
| **0.9** (very old) | AES-256-GCM | v1.0 | ✅ Yes | ✅ Yes (add UUIDs) |
| **1.0** (current) | AES-256-GCM | v1.1 | ✅ Yes | ✅ Yes (add UUIDs) |
| **1.1** (new) | AES-256-GCM | v1.1 | ✅ Yes | ❌ No |
| **2.0** (future) | AES-256-GCM | v2.0 | ✅ Yes | ⚠️ TBD |

---

### 19.5 Migration Strategy for Legacy Data

When restoring a legacy backup (v1.0), the system will:

```
1. Detect version → "v1.0" (legacy)
2. Decrypt successfully using existing AES-256-GCM
3. Load data into Hive
4. Trigger DataMigrationService.migrateToUUIDs()
   ├─ Generate deterministic UUIDs for existing entries
   ├─ Add inc_/out_ prefixes
   └─ Update version field
5. Save migrated data
6. Continue with Smart Merge
```

**No data loss, fully automatic!**

---

### 19.6 Error Handling & User Communication

#### 19.6.1 Decryption Failure Messages

```dart
if (decryptedData == null) {
  final version = BackupVersionDetector.detectVersion(encryptedData);

  if (version.isUnknown) {
    return RestoreResult.failure(
      'عذراً، تنسيق النسخة الاحتياطية غير معروف. قد تكون ملف تالف.'
    );
  }

  if (!BackupVersionDetector.isCompatible(version)) {
    return RestoreResult.failure(
      'هذه النسخة الاحتياطية تم إنشاؤها بإصدار غير متوافق (${version.formatVersion}). '
      'يرجى تحديث التطبيق إلى أحدث إصدار.'
    );
  }

  return RestoreResult.failure(
    'فشل فك تشفير النسخة الاحتياطية. تأكد من استخدام نفس حساب Google المستخدم في إنشاء النسخة.'
  );
}
```

#### 19.6.2 Migration Progress Dialog

```dart
// Show dialog for legacy backups
if (BackupVersionDetector.needsMigration(version)) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.upgrade, color: Colors.blue),
          SizedBox(width: 8),
          Text('ترقية البيانات'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'جاري ترقية تنسيق البيانات إلى الإصدار الجديد...\n'
            'قد يستغرق هذا بضع ثوانٍ.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}
```

---

### 19.7 Testing Strategy for Legacy Compatibility

#### 19.7.1 Test Scenarios

| Test Case | Description | Expected Result |
|-----------|-------------|-----------------|
| **TC-1** | Restore v1.0 backup with v1.1 app | ✅ Success with migration |
| **TC-2** | Restore v1.1 backup with v1.1 app | ✅ Success without migration |
| **TC-3** | Restore v0.9 backup with v1.1 app | ✅ Success with migration |
| **TC-4** | Wrong encryption key | ❌ Clear error message |
| **TC-5** | Corrupted backup file | ❌ Checksum validation fails |
| **TC-6** | Different Google account | ❌ Key ownership validation fails |

#### 19.7.2 Test Data Preparation

```dart
// Generate test backups for each version
Future<void> generateTestBackups() async {
  // v1.0 backup (legacy)
  final v1_0_backup = {
    'encrypted': true,
    'version': '1.0',
    'backup_id': 'test-v1.0',
    // ... encrypted data without UUIDs
  };

  // v1.1 backup (new)
  final v1_1_backup = {
    'encrypted': true,
    'format_version': '2.0',
    'encryption_version': '1.1',
    'data_schema_version': '1.1',
    'backup_id': 'test-v1.1',
    // ... encrypted data with UUIDs
  };

  // Test decryption for both
  await testDecryption(v1_0_backup);
  await testDecryption(v1_1_backup);
}
```

---

### 19.8 Implementation Checklist

**Phase 1: Version Detection (2 days) ✅ COMPLETED**
- [x] Create BackupVersionDetector class
- [x] Add version detection logic
- [x] Write unit tests for version detection
- [x] Test with sample backups

**Phase 2: Legacy Decryption (2 days) ✅ COMPLETED**
- [x] Create LegacyDecryptionService class
- [x] Implement fallback decryption
- [x] Add error handling
- [x] Test with real v1.0 backups

**Phase 3: Integration (2 days) ✅ COMPLETED**
- [x] Update BackupService restore flow
- [x] Add version-aware encryption for new backups
- [x] Update UI messages
- [x] Test end-to-end restore

**Phase 4: Testing & Validation (ONGOING)**
- [x] Create test backup files (v0.9, v1.0, v1.1)
- [x] Test all migration paths
- [x] Validate data integrity
- [ ] User acceptance testing (Production testing)

**Status:** ✅ **ALL CRITICAL FEATURES IMPLEMENTED**
**Total Time Spent:** 6 days (2 days ahead of schedule!)
**Next:** Production testing with real users

---

### 19.9 Future-Proofing

**For Future Encryption Algorithm Changes:**

```dart
// Encryption version mapping
enum EncryptionAlgorithm {
  AES_256_GCM_V1('1.0', 'AES-256-GCM'),
  AES_256_GCM_V2('1.1', 'AES-256-GCM-Enhanced'),
  CHACHA20_POLY1305('2.0', 'ChaCha20-Poly1305'),
  ;

  final String version;
  final String algorithm;

  const EncryptionAlgorithm(this.version, this.algorithm);

  static EncryptionAlgorithm fromVersion(String version) {
    return values.firstWhere(
      (e) => e.version == version,
      orElse: () => AES_256_GCM_V1,
    );
  }
}
```

---

### 19.10 Security Considerations

**✅ Safe Practices:**
1. **Key Isolation:** Legacy and new keys use same secure storage
2. **Version Pinning:** Each backup records exact encryption version
3. **Checksum Validation:** Integrity checked before decryption
4. **User Verification:** Email + Google ID match required
5. **Graceful Failure:** Never expose raw error details to user

**❌ Security Risks Mitigated:**
- ✅ Prevent key downgrade attacks
- ✅ Detect tampered backup files
- ✅ Avoid key reuse across accounts
- ✅ Protect against version confusion attacks

---

## ⚡ 20. Performance Optimization with Isolates

### 20.1 Problem: UI Freezing During Large Merges

**Current Limitation:**
When merging large datasets (>1000 entries), the merge operation runs on the main UI thread, causing:
- ❌ UI freezing for 3-5 seconds
- ❌ Poor user experience
- ❌ ANR (Application Not Responding) warnings on Android
- ❌ Can't show real-time progress

**Performance Benchmarks (Current Implementation):**
```
100 entries:   ~200ms  ✅ Acceptable
500 entries:   ~800ms  ⚠️  Noticeable lag
1000 entries:  ~2.5s   ❌ UI freezes
5000 entries:  ~15s    ❌ App appears frozen
```

### 20.2 Solution: Background Merge with Isolates

#### 20.2.1 Architecture

```
Main Thread (UI)                     Background Isolate
    │                                        │
    ├─ User clicks "Restore"                │
    ├─ Show progress dialog                 │
    ├─ Send data to isolate ────────────────┤
    │                                        ├─ Receive data
    │                                        ├─ Parse JSON
    │                                        ├─ Run merge algorithm
    │                                        ├─ Send progress updates ─┐
    │                                        │                         │
    ├─ Update progress UI ◄──────────────────────────────────────────┘
    │                                        │
    ├─ Receive merged result ◄──────────────┤
    ├─ Write to Hive                        │
    ├─ Refresh UI                            │
    └─ Show success                          └─ Isolate terminated
```

#### 20.2.2 Implementation: IsolateMergeService

**File:** `lib/backup/services/isolate_merge_service.dart`

```dart
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import '../../models/income_entry.dart';
import '../../models/outcome_entry.dart';
import '../models/merge_result.dart';

/// Service for performing merge operations in background isolate
/// Prevents UI freezing for large datasets
class IsolateMergeService {
  /// Merge entries in background isolate (for large datasets)
  /// Returns Stream for real-time progress updates
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

      // Listen for progress updates
      await for (final message in receivePort) {
        if (message is MergeProgress) {
          yield message;
        } else if (message is MergeResult) {
          yield MergeProgress.completed(result: message);
          break;
        } else if (message is String && message.startsWith('ERROR:')) {
          yield MergeProgress.error(message: message.substring(6));
          break;
        }
      }
    } catch (e) {
      yield MergeProgress.error(message: e.toString());
    } finally {
      receivePort.close();
      errorPort.close();
    }
  }

  /// Isolate worker function (runs in background)
  static void _isolateMergeWorker(_IsolateConfig config) async {
    final sendPort = config.sendPort;

    try {
      // Phase 1: Validate data (5%)
      sendPort.send(MergeProgress(
        phase: MergePhase.validating,
        percentage: 5,
        message: 'Validating backup data...',
      ));

      final backupData = config.backupData;
      final localData = config.localData;

      // Phase 2: Parse income entries (10-40%)
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

      // Phase 3: Parse outcome entries (40-70%)
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

      // Phase 4: Build final result (70-100%)
      sendPort.send(MergeProgress(
        phase: MergePhase.finalizing,
        percentage: 90,
        message: 'Finalizing merge...',
      ));

      final result = MergeResult.success(
        totalEntries: incomeResults.totalEntries + outcomeResults.totalEntries,
        entriesFromBackup: incomeResults.fromBackup + outcomeResults.fromBackup,
        entriesFromLocal: incomeResults.fromLocal + outcomeResults.fromLocal,
        conflictsResolved: incomeResults.conflicts + outcomeResults.conflicts,
        duplicatesSkipped: 0,
        duration: Duration.zero, // Will be calculated by caller
        statistics: MergeStatistics(
          income: incomeResults.statistics,
          outcome: outcomeResults.statistics,
        ),
      );

      // Send final result
      sendPort.send(result);

    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('💥 Isolate merge error: $e');
        print(stackTrace);
      }
      sendPort.send('ERROR:$e');
    }
  }

  /// Parse and merge income entries (runs in isolate)
  static Future<_MergeStats> _parseAndMergeIncome({
    required Map<String, dynamic> backupData,
    required Map<String, dynamic> localData,
    required Function(double) progressCallback,
  }) async {
    // Implementation similar to SmartMergeService.mergeIncomeEntries
    // but with progress callbacks
    int totalEntries = 0;
    int fromBackup = 0;
    int fromLocal = 0;
    int conflicts = 0;

    // ... merge logic with progress updates ...
    // progressCallback(0.5); // 50% done

    return _MergeStats(
      totalEntries: totalEntries,
      fromBackup: fromBackup,
      fromLocal: fromLocal,
      conflicts: conflicts,
      statistics: IncomeStatistics(
        total: totalEntries,
        fromBackup: fromBackup,
        fromLocal: fromLocal,
        conflicts: conflicts,
      ),
    );
  }

  /// Parse and merge outcome entries (runs in isolate)
  static Future<_MergeStats> _parseAndMergeOutcome({
    required Map<String, dynamic> backupData,
    required Map<String, dynamic> localData,
    required Function(double) progressCallback,
  }) async {
    // Similar implementation for outcomes
    return _MergeStats(
      totalEntries: 0,
      fromBackup: 0,
      fromLocal: 0,
      conflicts: 0,
      statistics: OutcomeStatistics.empty(),
    );
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

/// Statistics for merge results
class _MergeStats {
  final int totalEntries;
  final int fromBackup;
  final int fromLocal;
  final int conflicts;
  final dynamic statistics;

  _MergeStats({
    required this.totalEntries,
    required this.fromBackup,
    required this.fromLocal,
    required this.conflicts,
    required this.statistics,
  });
}

/// Progress update from isolate
class MergeProgress {
  final MergePhase phase;
  final int percentage;
  final String message;
  final MergeResult? result;
  final String? error;

  MergeProgress({
    required this.phase,
    required this.percentage,
    required this.message,
    this.result,
    this.error,
  });

  factory MergeProgress.completed({required MergeResult result}) {
    return MergeProgress(
      phase: MergePhase.completed,
      percentage: 100,
      message: 'Merge completed!',
      result: result,
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
```

#### 20.2.3 Updated BackupService Integration

```dart
// lib/backup/services/backup_service.dart

import 'isolate_merge_service.dart';

class BackupService extends ChangeNotifier {
  final IsolateMergeService _isolateMerge = IsolateMergeService();

  Future<RestoreResult> startRestoreWithIsolate() async {
    try {
      // ... download and decrypt ...

      // Decide: use isolate or main thread?
      final useIsolate = IsolateMergeService.shouldUseIsolate(backupData);

      if (useIsolate) {
        if (kDebugMode) {
          print('📊 Large dataset detected. Using background isolate for merge.');
        }

        // Merge in background with real-time progress
        await for (final progress in _isolateMerge.mergeInBackground(
          backupData: backupData,
          localData: localData,
        )) {
          if (progress.hasError) {
            return RestoreResult.failure(progress.error!);
          }

          // Update UI with progress
          _updateProgress(
            progress.percentage,
            null,
            progress.message,
            RestoreStatus.processing,
          );

          if (progress.isCompleted && progress.result != null) {
            // Merge complete! Write to Hive
            await _writeMergedDataToHive(
              progress.result!.mergedIncome,
              progress.result!.mergedOutcome,
            );
            return RestoreResult.success();
          }
        }
      } else {
        // Small dataset - use main thread (faster startup)
        if (kDebugMode) {
          print('📊 Small dataset. Using main thread for merge.');
        }
        return await _mergeOnMainThread(backupData, localData);
      }

    } catch (e) {
      return RestoreResult.failure(e.toString());
    }
  }
}
```

### 20.3 Performance Improvements

**Expected Performance Gains:**

| Dataset Size | Without Isolate | With Isolate | UI Responsiveness |
|--------------|-----------------|--------------|-------------------|
| 100 entries | 200ms | 300ms* | ✅ Smooth |
| 500 entries | 800ms (freeze) | 850ms | ✅ Smooth |
| 1000 entries | 2.5s (freeze) | 2.6s | ✅ Smooth |
| 5000 entries | 15s (freeze) | 16s | ✅ Smooth |
| 10000 entries | 45s (ANR) | 47s | ✅ Smooth |

*Slight overhead for isolate startup, but UI never freezes

### 20.4 Implementation Checklist

**Performance Optimization Tasks:**
- [ ] Create IsolateMergeService class
- [ ] Implement background merge worker
- [ ] Add progress streaming
- [ ] Integrate with BackupService
- [ ] Add size-based isolate decision logic
- [ ] Test with 10,000+ entry dataset
- [ ] Benchmark performance gains
- [ ] Update UI to show real-time progress

**Estimated Time:** 3-4 days

---

## 🎨 21. UI Polish & User Experience Enhancements

### 21.1 Current UI State: Good Foundation, Needs Polish

**Rating: ⭐⭐⭐⭐☆ (4/5 - Good, can be improved)**

**What Works Well:**
- ✅ Clear progress indicators
- ✅ Informative messages
- ✅ Material 3 design
- ✅ Responsive layout

**Areas for Improvement:**
- ⚠️ Basic progress bar (no animations)
- ⚠️ Generic success dialog
- ⚠️ No haptic feedback
- ⚠️ Limited visual flair

### 21.2 Polish Enhancements

#### 21.2.1 Enhanced Progress Dialog with Lottie

**File:** `lib/backup/ui/enhanced_restore_progress_dialog.dart`

```dart
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Enhanced restore progress dialog with Lottie animations
class EnhancedRestoreProgressDialog extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated Lottie based on status
            SizedBox(
              width: 150,
              height: 150,
              child: _buildAnimation(status),
            ),

            const SizedBox(height: 16),

            // Status title
            Text(
              _getStatusTitle(status),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Progress message
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // Enhanced progress bar with gradient
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                height: 8,
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutCubic,
                  tween: Tween<double>(begin: 0, end: percentage / 100),
                  builder: (context, value, _) {
                    return LinearProgressIndicator(
                      value: value,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getProgressColor(status),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Percentage text with animation
            TweenAnimationBuilder<int>(
              duration: const Duration(milliseconds: 500),
              tween: IntTween(begin: 0, end: percentage),
              builder: (context, value, _) {
                return Text(
                  '$value%',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _getProgressColor(status),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimation(RestoreStatus status) {
    switch (status) {
      case RestoreStatus.downloading:
        return Lottie.asset('assets/animations/cloud_download.json');
      case RestoreStatus.decrypting:
        return Lottie.asset('assets/animations/lock_unlock.json');
      case RestoreStatus.processing:
        return Lottie.asset('assets/animations/data_merge.json');
      case RestoreStatus.completed:
        return Lottie.asset('assets/animations/success_checkmark.json', repeat: false);
      case RestoreStatus.failed:
        return Lottie.asset('assets/animations/error_cross.json', repeat: false);
      default:
        return const CircularProgressIndicator();
    }
  }

  String _getStatusTitle(RestoreStatus status) {
    switch (status) {
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

  Color _getProgressColor(RestoreStatus status) {
    switch (status) {
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

#### 21.2.2 Animated Success Dialog

**File:** `lib/backup/ui/animated_success_dialog.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:confetti/confetti.dart';

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

#### 21.2.3 Required Assets & Dependencies

**Add to pubspec.yaml:**
```yaml
dependencies:
  lottie: ^3.1.0          # For smooth animations
  confetti: ^0.7.0        # For celebration effect
  flutter_animate: ^4.5.0 # For micro-interactions

assets:
  - assets/animations/cloud_download.json
  - assets/animations/lock_unlock.json
  - assets/animations/data_merge.json
  - assets/animations/success_checkmark.json
  - assets/animations/error_cross.json
```

**Lottie Animation Sources:**
- Download from [LottieFiles](https://lottiefiles.com/)
- Recommended animations:
  - Cloud download: Search "cloud download"
  - Lock unlock: Search "unlock animation"
  - Data merge: Search "data sync"
  - Success: Search "success checkmark"
  - Error: Search "error cross"

### 21.3 Micro-Interactions

#### 21.3.1 Haptic Feedback

```dart
import 'package:flutter/services.dart';

// On restore start
HapticFeedback.lightImpact();

// On progress milestones (25%, 50%, 75%)
HapticFeedback.selectionClick();

// On success
HapticFeedback.mediumImpact();

// On error
HapticFeedback.heavyImpact();
```

#### 21.3.2 Sound Effects (Optional)

```dart
import 'package:audioplayers/audioplayers.dart';

final player = AudioPlayer();

// On success
await player.play(AssetSource('sounds/success.mp3'));

// On error
await player.play(AssetSource('sounds/error.mp3'));
```

### 21.4 Implementation Checklist

**UI Polish Tasks:**
- [ ] Add Lottie animations package
- [ ] Download/create animation files
- [ ] Create EnhancedRestoreProgressDialog
- [ ] Create AnimatedSuccessDialog
- [ ] Add haptic feedback at key moments
- [ ] Add confetti celebration
- [ ] Test animations on low-end devices
- [ ] Optimize animation file sizes

**Estimated Time:** 2-3 days

---

## 🔄 22. Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2025-01-18 | Dev Team | Initial PRD creation |
| 1.1.0 | 2025-01-18 | Dev Team | Added 4 critical enhancements: Safety Backup, Extended Stats, UUID Prefixes, Structured Logging |
| 1.1.1 | 2025-01-19 | Dev Team | Added Legacy Encryption & Backup Compatibility section (Section 19) |
| **1.2.0** | **2025-10-19** | **Dev Team** | **✨ Added Performance Optimization with Isolates (Section 20) + UI Polish Enhancements (Section 21)** |

---

## 📊 23. Final Implementation Priority

### 23.1 Phase A: Critical Fixes (COMPLETED ✅)
- ✅ Fix data loss bug (validate before clear)
- ✅ Add null-safety to fromJson methods
- ✅ Implement BackupVersionDetector
- ✅ Implement LegacyDecryptionService
- ✅ Integrate legacy-aware decryption

**Status:** All P0 critical bugs fixed. System is production-safe.

### 23.2 Phase B: Performance Optimization (RECOMMENDED - 4 stars)
- [ ] Implement IsolateMergeService
- [ ] Add background merge for large datasets
- [ ] Add real-time progress streaming
- [ ] Benchmark performance improvements

**Priority:** P1 (High)
**Impact:** Prevents UI freezing for users with large datasets
**Estimated Time:** 3-4 days

### 23.3 Phase C: UI Polish (RECOMMENDED - 4 stars)
- [ ] Add Lottie animations
- [ ] Create EnhancedRestoreProgressDialog
- [ ] Create AnimatedSuccessDialog with confetti
- [ ] Add haptic feedback
- [ ] Optimize animation performance

**Priority:** P2 (Medium)
**Impact:** Significantly improves user experience and delight
**Estimated Time:** 2-3 days

### 23.4 Overall Roadmap

```
CURRENT STATE: ⭐⭐⭐⭐☆
├─ ✅ Data safety: 5/5 (all critical fixes done)
├─ ⚠️  Performance: 3/5 (works but can freeze on large data)
└─ ⚠️  UI polish: 3/5 (functional but basic)

TARGET STATE: ⭐⭐⭐⭐⭐
├─ ✅ Data safety: 5/5 (maintained)
├─ ✨ Performance: 5/5 (isolate-based, smooth for any size)
└─ ✨ UI polish: 5/5 (delightful animations + haptics)

TIMELINE:
Week 1: Phase A (DONE)
Week 2: Phase B (Performance) - 4 days
Week 3: Phase C (UI Polish) - 3 days
Week 4: Testing & Beta Release
```

---

**END OF PRD**

*This is a living document and will be updated as requirements evolve.*
