import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/income_entry.dart';
import '../models/outcome_entry.dart';

/// Service for creating snapshots of Hive database for backup
class HiveSnapshotService {
  static final HiveSnapshotService _instance = HiveSnapshotService._internal();
  factory HiveSnapshotService() => _instance;
  HiveSnapshotService._internal();

  /// Create a complete snapshot of all Hive boxes
  Future<Uint8List> packageAll() async {
    try {
      if (kDebugMode) {
        print('📦 Creating Hive database snapshot...');
      }

      final Map<String, dynamic> snapshotData = {};
      
      // Snapshot income entries
      final incomeData = await _snapshotIncomeBox();
      snapshotData['income_entries'] = incomeData;
      
      // Snapshot outcome entries
      final outcomeData = await _snapshotOutcomeBox();
      snapshotData['outcome_entries'] = outcomeData;
      
      // Snapshot settings (if any)
      final settingsData = await _snapshotSettingsBox();
      snapshotData['settings'] = settingsData;
      
      // Add metadata
      snapshotData['metadata'] = {
        'created_at': DateTime.now().toIso8601String(),
        'version': '1.0',
        'income_months': incomeData.length,
        'outcome_months': outcomeData.length,
      };

      // Convert to JSON bytes
      final jsonString = json.encode(snapshotData);
      final bytes = utf8.encode(jsonString);
      
      if (kDebugMode) {
        print('✅ Snapshot created successfully');
        print('   Total size: ${bytes.length} bytes');
        print('   Income months: ${incomeData.length}');
        print('   Outcome months: ${outcomeData.length}');
      }
      
      return Uint8List.fromList(bytes);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error creating snapshot: $e');
      }
      rethrow;
    }
  }

  /// Snapshot income entries box
  Future<Map<String, dynamic>> _snapshotIncomeBox() async {
    try {
      final incomeBox = await Hive.openBox<List<dynamic>>('income_entries');
      final incomeData = <String, dynamic>{};
      
      if (kDebugMode) {
        print('📊 Snapshotting income box: ${incomeBox.length} keys');
      }
      
      for (final key in incomeBox.keys) {
        final value = incomeBox.get(key);
        if (value is List) {
          // Convert IncomeEntry objects to JSON for serialization
          final jsonList = value.map((item) {
            if (item is IncomeEntry) {
              return item.toJson();
            } else if (item is Map<String, dynamic>) {
              return item; // Already in JSON format
            } else {
              // Try to convert dynamic object to IncomeEntry
              return (item as dynamic).toJson();
            }
          }).toList();
          incomeData[key.toString()] = jsonList;
        } else {
          incomeData[key.toString()] = value;
        }
      }
      
      return incomeData;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error snapshotting income box: $e');
      }
      return {};
    }
  }

  /// Snapshot outcome entries box
  Future<Map<String, dynamic>> _snapshotOutcomeBox() async {
    try {
      final outcomeBox = await Hive.openBox<List<dynamic>>('outcome_entries');
      final outcomeData = <String, dynamic>{};
      
      if (kDebugMode) {
        print('📊 Snapshotting outcome box: ${outcomeBox.length} keys');
      }
      
      for (final key in outcomeBox.keys) {
        final value = outcomeBox.get(key);
        if (value is List) {
          // Convert OutcomeEntry objects to JSON for serialization
          final jsonList = value.map((item) {
            if (item is OutcomeEntry) {
              return item.toJson();
            } else if (item is Map<String, dynamic>) {
              return item; // Already in JSON format
            } else {
              // Try to convert dynamic object to OutcomeEntry
              return (item as dynamic).toJson();
            }
          }).toList();
          outcomeData[key.toString()] = jsonList;
        } else {
          outcomeData[key.toString()] = value;
        }
      }
      
      return outcomeData;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error snapshotting outcome box: $e');
      }
      return {};
    }
  }

  /// Snapshot settings box (if exists)
  Future<Map<String, dynamic>> _snapshotSettingsBox() async {
    try {
      // Check if settings box exists
      if (!Hive.isBoxOpen('settings')) {
        return {};
      }
      
      final settingsBox = Hive.box('settings');
      final settingsData = <String, dynamic>{};
      
      if (kDebugMode) {
        print('⚙️ Snapshotting settings box: ${settingsBox.length} keys');
      }
      
      for (final key in settingsBox.keys) {
        final value = settingsBox.get(key);
        settingsData[key.toString()] = value;
      }
      
      return settingsData;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error snapshotting settings box: $e');
      }
      return {};
    }
  }

  /// Restore data from snapshot
  Future<Map<String, int>> restoreFromSnapshot(Uint8List snapshotBytes) async {
    try {
      if (kDebugMode) {
        print('🔄 Restoring from snapshot...');
      }

      if (snapshotBytes.isEmpty) {
        if (kDebugMode) {
          print('⚠️ No data to restore (empty snapshot)');
        }
        return {'income_entries': 0, 'outcome_entries': 0};
      }

      // Parse JSON from snapshot
      final jsonString = utf8.decode(snapshotBytes);
      final Map<String, dynamic> snapshotData = json.decode(jsonString);
      
      int restoredIncomeEntries = 0;
      int restoredOutcomeEntries = 0;

      // Restore income entries
      if (snapshotData.containsKey('income_entries')) {
        restoredIncomeEntries = await _restoreIncomeBox(snapshotData['income_entries']);
      }

      // Restore outcome entries
      if (snapshotData.containsKey('outcome_entries')) {
        restoredOutcomeEntries = await _restoreOutcomeBox(snapshotData['outcome_entries']);
      }

      // Restore settings
      if (snapshotData.containsKey('settings')) {
        await _restoreSettingsBox(snapshotData['settings']);
      }

      if (kDebugMode) {
        print('✅ Restore completed successfully');
        print('   Income entries: $restoredIncomeEntries');
        print('   Outcome entries: $restoredOutcomeEntries');
      }

      return {
        'income_entries': restoredIncomeEntries,
        'outcome_entries': restoredOutcomeEntries,
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error restoring from snapshot: $e');
      }
      rethrow;
    }
  }

  /// Restore income entries
  Future<int> _restoreIncomeBox(Map<String, dynamic> incomeData) async {
    final incomeBox = await Hive.openBox<List<dynamic>>('income_entries');
    await incomeBox.clear(); // Clear existing data
    
    int totalEntries = 0;
    for (final entry in incomeData.entries) {
      if (entry.value is List) {
        // Convert JSON objects back to IncomeEntry objects
        final entryList = (entry.value as List).map((item) {
          try {
            if (item is Map<String, dynamic>) {
              return IncomeEntry.fromJson(item);
            } else if (item is IncomeEntry) {
              return item; // Already correct type
            } else {
              // Try to convert from dynamic
              return IncomeEntry.fromJson(item as Map<String, dynamic>);
            }
          } catch (e) {
            if (kDebugMode) {
              print('⚠️ Error converting income entry: $e, item: $item');
            }
            rethrow;
          }
        }).toList();
        
        await incomeBox.put(entry.key, entryList);
        totalEntries += entryList.length;
      } else {
        await incomeBox.put(entry.key, entry.value);
      }
    }
    
    return totalEntries;
  }

  /// Restore outcome entries
  Future<int> _restoreOutcomeBox(Map<String, dynamic> outcomeData) async {
    final outcomeBox = await Hive.openBox<List<dynamic>>('outcome_entries');
    await outcomeBox.clear(); // Clear existing data
    
    int totalEntries = 0;
    for (final entry in outcomeData.entries) {
      if (entry.value is List) {
        // Convert JSON objects back to OutcomeEntry objects
        final entryList = (entry.value as List).map((item) {
          try {
            if (item is Map<String, dynamic>) {
              return OutcomeEntry.fromJson(item);
            } else if (item is OutcomeEntry) {
              return item; // Already correct type
            } else {
              // Try to convert from dynamic
              return OutcomeEntry.fromJson(item as Map<String, dynamic>);
            }
          } catch (e) {
            if (kDebugMode) {
              print('⚠️ Error converting outcome entry: $e, item: $item');
            }
            rethrow;
          }
        }).toList();
        
        await outcomeBox.put(entry.key, entryList);
        totalEntries += entryList.length;
      } else {
        await outcomeBox.put(entry.key, entry.value);
      }
    }
    
    return totalEntries;
  }

  /// Restore settings
  Future<void> _restoreSettingsBox(Map<String, dynamic> settingsData) async {
    try {
      if (!Hive.isBoxOpen('settings')) {
        await Hive.openBox('settings');
      }
      
      final settingsBox = Hive.box('settings');
      for (final entry in settingsData.entries) {
        await settingsBox.put(entry.key, entry.value);
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error restoring settings: $e');
      }
      // Settings restoration failure shouldn't break the whole process
    }
  }
}
