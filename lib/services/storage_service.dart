import 'package:hive_flutter/hive_flutter.dart';
import '../models/income_entry.dart';
import '../models/outcome_entry.dart';

class StorageService {
  static const String incomeBoxName = 'income_entries';
  static const String outcomeBoxName = 'outcome_entries';

  static Future<void> closeHive() async {
    await Hive.close();
  }

  Future<List<IncomeEntry>> getIncomeEntries(String month, int year) async {
    final box = await Hive.openBox<List<dynamic>>(incomeBoxName);
    final key = '${month}_$year';
    final List<dynamic>? rawList = box.get(key);
    List<IncomeEntry> entries = [];

    if (rawList != null) {
      entries = rawList.map((item) => item as IncomeEntry).toList();
    }

    return entries;
  }

  Future<void> saveIncomeEntries(
      String month, int year, List<IncomeEntry> entries) async {
    final box = await Hive.openBox<List<dynamic>>(incomeBoxName);
    final key = '${month}_$year';
    await box.put(key, entries);
  }

  Future<List<OutcomeEntry>> getOutcomeEntries(String month, int year) async {
    final box = await Hive.openBox<List<dynamic>>(outcomeBoxName);
    final key = '${month}_$year';
    final List<dynamic>? rawList = box.get(key);
    List<OutcomeEntry> entries = [];

    if (rawList != null) {
      entries = rawList.map((item) => item as OutcomeEntry).toList();
    }

    return entries;
  }

  Future<void> saveOutcomeEntries(
      String month, int year, List<OutcomeEntry> entries) async {
    final box = await Hive.openBox<List<dynamic>>(outcomeBoxName);
    final key = '${month}_$year';
    await box.put(key, entries);
  }

  Future<void> clearAllData() async {
    final incomeBox = await Hive.openBox<List<dynamic>>(incomeBoxName);
    final outcomeBox = await Hive.openBox<List<dynamic>>(outcomeBoxName);

    await incomeBox.clear();
    await outcomeBox.clear();
  }

  Future<void> deleteMonthData(String month, int year) async {
    final incomeBox = await Hive.openBox<List<dynamic>>(incomeBoxName);
    final outcomeBox = await Hive.openBox<List<dynamic>>(outcomeBoxName);

    final key = '${month}_$year';
    await incomeBox.delete(key);
    await outcomeBox.delete(key);
  }

  // Returns all income entries across all months/years
  Future<List<IncomeEntry>> getAllIncomeEntries() async {
    final box = await Hive.openBox<List<dynamic>>(incomeBoxName);
    List<IncomeEntry> allEntries = [];
    for (var value in box.values) {
      allEntries.addAll(value.map((item) => item as IncomeEntry));
    }
    return allEntries;
  }

  // Returns all outcome entries across all months/years
  Future<List<OutcomeEntry>> getAllOutcomeEntries() async {
    final box = await Hive.openBox<List<dynamic>>(outcomeBoxName);
    List<OutcomeEntry> allEntries = [];
    for (var value in box.values) {
      allEntries.addAll(value.map((item) => item as OutcomeEntry));
    }
    return allEntries;
  }

  // Returns all income data organized by month/year keys
  Future<Map<String, List<IncomeEntry>>> getAllIncomeData() async {
    final box = await Hive.openBox<List<dynamic>>(incomeBoxName);
    Map<String, List<IncomeEntry>> allData = {};

    for (var key in box.keys) {
      final rawList = box.get(key);
      if (rawList != null) {
        allData[key] = rawList.map((item) => item as IncomeEntry).toList();
      }
    }
    return allData;
  }

  // Returns all outcome data organized by month/year keys
  Future<Map<String, List<OutcomeEntry>>> getAllOutcomeData() async {
    final box = await Hive.openBox<List<dynamic>>(outcomeBoxName);
    Map<String, List<OutcomeEntry>> allData = {};

    for (var key in box.keys) {
      final rawList = box.get(key);
      if (rawList != null) {
        allData[key] = rawList.map((item) => item as OutcomeEntry).toList();
      }
    }
    return allData;
  }
}
