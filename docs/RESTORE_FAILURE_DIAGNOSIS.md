# Restore Failure Diagnosis Guide
## How to Identify and Debug Restore Issues

---

## SYMPTOM: "Failed to decrypt backup. The backup may be corrupted."

This error can mean multiple different things. This guide shows how to diagnose which issue you're hitting.

### Issue A: Missing ID Field (Most Likely)

Error Message: 
```
E/flutter: NoSuchMethodError: The method '[]' was called on null.
E/flutter: Error converting income entry: NoSuchMethodError
```

Debug Path:
1. Check if backup contains 'id' field
2. If missing, it's pre-UUID backup
3. Will crash on line: income_entry.dart:42
   ```dart
   id: json['id'],  // This line crashes
   ```

Confirmation: Old backup JSON missing 'id' field
```json
{
  "name": "Salary",
  "amount": 5000,
  "date": "2024-10-01T00:00:00Z"
  // NO "id" FIELD - triggers Issue A
}
```

### Issue B: Data Already Cleared

Error Message:
```
E/flutter: Error restoring database
E/flutter: Failed to restore database: No such method
```

What Actually Happened:
1. box.clear() executed at line 611
2. Local data deleted
3. fromJson failed (missing id)
4. Error returned to user
5. DATA PERMANENTLY LOST (but user only sees error message)

Confirmation: Check Hive box is empty after failed restore

### Issue C: Type Mismatch

Error Message:
```
E/flutter: TypeError: Cannot cast "1500" to num
E/flutter: String is not a subtype of num
```

Debug Path:
1. Check backup data types
2. Look for amount as string: "1500"
3. Should be number: 1500

Code that fails:
```dart
amount: (json['amount'] as num).toDouble()  // Crashes here
```

### Issue D: Binary Format Mismatch

Error Message:
```
E/flutter: NoSuchMethodError: Cannot read property '0'
E/flutter: Attempting to access fields[0]
```

What Happened:
1. Old Hive data has 4 fields (no id)
2. New adapter tries to read 5 fields
3. Accesses fields[0] as String
4. Gets name field instead (wrong type)

---

## DETAILED ERROR FLOW

Complete path when restoring old backup:

```
Step 1: User clicks "Restore"
  ├─ Check connectivity: ✅
  ├─ Initialize Drive: ✅
  └─ User signed in: ✅

Step 2: Find and download backup
  ├─ List Drive files: ✅
  ├─ Filter .crypt14 files: ✅
  ├─ Select most recent: ✅
  └─ Download: ✅ (200KB backup)

Step 3: Decrypt backup
  ├─ Get master key: ✅
  ├─ Verify checksum: ✅
  ├─ Decrypt data: ✅
  └─ Parse JSON: ✅

Step 4: Open Hive boxes
  ├─ Open income_entries box: ✅
  └─ Open outcome_entries box: ✅

Step 5: CLEAR INCOME BOX
  ├─ incomeBox.clear(): ✅ EXECUTED
  ├─ All entries deleted: ✅ DONE
  └─ Point of no return: ⚠️

Step 6: Convert entries to objects
  ├─ For each month in backup:
  │  ├─ For each entry:
  │  │  ├─ Call IncomeEntry.fromJson(item)
  │  │  ├─ Try: id = json['id']
  │  │  ├─ CRASH: 'id' field missing
  │  │  ├─ Exception thrown
  │  │  └─ Catch block catches error
  │  │
  │  └─ rethrow propagates error

Step 7: Error handling
  ├─ Parent catch block: catches exception
  ├─ Return RestoreResult.failure()
  └─ Display error to user

Result: ❌ RESTORE FAILED, DATA LOST
  └─ User cannot undo (no transactions)
```

---

## RECOVERY CHECKLIST

After failed restore:

- [ ] Check if any data is in Hive
  ```dart
  final box = await Hive.openBox<List<dynamic>>('income_entries');
  print('Box length: ${box.length}');  // Will be 0 if cleared
  ```

- [ ] Check if backup still in Google Drive
  ```dart
  // Should still be there
  // But you can't decrypt it again (same error)
  ```

- [ ] Check local app cache
  ```dart
  // No automatic backup exists
  // Data gone
  ```

- [ ] Recovery options:
  1. Restore from another backup (if available)
  2. Contact support with backup file
  3. Re-enter data manually

---

## LOG ANALYSIS

Key log patterns to look for:

### Pattern A: Missing ID Field
```
I/flutter: ⚠️ Error converting income entry: 
  NoSuchMethodError: The method '[]' was called on null.
  Attempted to access member 'id' on a null object
I/flutter: item: {name: Salary, amount: 5000, date: ...}
```
→ Backup missing 'id' field

### Pattern B: Type Error
```
I/flutter: ⚠️ Error converting income entry: 
  TypeError: Cannot cast "1500" to num
```
→ Old backup has string amounts

### Pattern C: Hive Read Error
```
I/flutter: ⚠️ Error converting income entry:
  NoSuchMethodError: Cannot read property '0' of undefined
```
→ Binary format mismatch

### Pattern D: Corruption
```
I/flutter: [EncryptionService] ❌ Checksum mismatch
I/flutter:    Expected: abc123def456
I/flutter:    Actual:   xyz789uvw012
```
→ Backup corrupted

---

## PREVENTION CHECKLIST

Before release:

- [ ] Test restore with backup from 3 months ago
- [ ] Test restore with backup without 'id' fields
- [ ] Test restore with manually created old data
- [ ] Verify local data exists after failed restore
- [ ] Test with intentionally corrupted backup
- [ ] Verify error messages are helpful
- [ ] Test fallback to older backups

---

## WHAT'S BROKEN

Current implementation cannot handle:
- ❌ Backups without 'id' field
- ❌ Backups with string amounts instead of numbers
- ❌ Backups with missing optional fields
- ❌ Corrupted most-recent backup (no fallback)
- ❌ Version mismatch (no migration)
- ❌ Data loss recovery (no rollback)

---

## WHAT SHOULD BE DONE

Before restore:
1. Download backup
2. Decrypt backup
3. VALIDATE all data structure
4. Generate missing IDs
5. Convert types correctly
6. ONLY THEN clear boxes
7. Restore validated data

After restore:
1. Verify counts match
2. Verify no duplicates
3. Refresh UI
4. Show summary to user

---

## TIMELINE OF DISASTER

When user tries to restore old backup:

T+0s:   User taps "Restore" button
T+2s:   Files downloaded from Drive
T+4s:   Data decrypted successfully
T+5s:   JSON parsed successfully
T+6s:   incomeBox.clear() executes
T+7s:   Trying to convert first entry
T+8s:   CRASH on missing 'id' field
T+9s:   Error message shown: "Failed to restore"
T+10s:  User realizes all data gone
T+∞:    User crying, must re-enter 6 months of data

---

## CONCLUSION

The restore system is not production-ready for users with old backups.

Recommended action: Hold release, implement P0 fixes, test thoroughly.

