import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/income_entry.dart';
import '../models/outcome_entry.dart';
import 'storage_service.dart';

class DataSharingService {
  static const String _fileExtension = '.NOG';

  static Future<void> exportMonthData({
    required String month,
    required int year,
  }) async {
    try {
      final storageService = StorageService();

      // Get month data
      final incomeEntries = await storageService.getIncomeEntries(month, year);
      final outcomeEntries = await storageService.getOutcomeEntries(month, year);

      // Create export data structure
      final exportData = {
        'appVersion': '1.0',
        'exportType': 'month',
        'exportDate': DateTime.now().toIso8601String(),
        'month': month,
        'year': year,
        'incomeEntries': incomeEntries.map((e) => {
          'id': e.id,
          'name': e.name,
          'amount': e.amount,
          'date': e.date.toIso8601String(),
        }).toList(),
        'outcomeEntries': outcomeEntries.map((e) => {
          'id': e.id,
          'name': e.name,
          'amount': e.amount,
          'date': e.date.toIso8601String(),
        }).toList(),
      };

      // Create and share file with current date
      final now = DateTime.now();
      final dateString = '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';
      await _createAndShareFile(
        data: exportData,
        filename: dateString,
      );
    } catch (e) {
      throw Exception('Failed to export month data: $e');
    }
  }

  static Future<void> exportAllData() async {
    try {
      final storageService = StorageService();

      // Get all data
      final allIncomeData = await storageService.getAllIncomeData();
      final allOutcomeData = await storageService.getAllOutcomeData();

      // Create export data structure
      final exportData = {
        'appVersion': '1.0',
        'exportType': 'all',
        'exportDate': DateTime.now().toIso8601String(),
        'allData': {
          'income': allIncomeData,
          'outcome': allOutcomeData,
        }
      };

      // Create and share file with current date
      final now = DateTime.now();
      final dateString = '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';
      await _createAndShareFile(
        data: exportData,
        filename: dateString,
      );
    } catch (e) {
      throw Exception('Failed to export all data: $e');
    }
  }

  static Future<void> _createAndShareFile({
    required Map<String, dynamic> data,
    required String filename,
  }) async {
    try {
      // Get app directory
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$filename$_fileExtension';

      // Create file
      final file = File(filePath);
      final jsonString = json.encode(data);
      await file.writeAsString(jsonString);

      // Try to share file
      try {
        await Share.shareXFiles(
          [XFile(filePath)],
          text: 'AlKhazna Data - $filename',
          subject: 'AlKhazna Data Export',
        );
      } catch (shareError) {
        // If sharing fails (e.g., on desktop platforms), inform user about file location
        if (kDebugMode) {
          print('Share failed, file saved to: $filePath');
        }
        // Rethrow with more helpful message
        throw Exception(
          'File saved successfully to:\n$filePath\n\n'
          'Note: Direct sharing is not available on this platform. '
          'Please locate the file in your documents folder and share it manually.'
        );
      }
    } catch (e) {
      if (e is Exception && e.toString().contains('File saved successfully')) {
        // This is our custom file location message, pass it through
        rethrow;
      } else {
        throw Exception('Failed to create and share file: $e');
      }
    }
  }

  static Future<Map<String, dynamic>> importDataFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        throw Exception('File does not exist');
      }

      final jsonString = await file.readAsString();
      final data = json.decode(jsonString) as Map<String, dynamic>;

      // Validate file format
      if (!data.containsKey('appVersion') || !data.containsKey('exportType')) {
        throw Exception('Invalid AlKhazna data file format');
      }

      return data;
    } catch (e) {
      throw Exception('Failed to import data file: $e');
    }
  }

  static Future<void> processImportedData({
    required Map<String, dynamic> data,
    required ImportMode mode,
  }) async {
    try {
      final storageService = StorageService();
      final exportType = data['exportType'] as String;

      if (exportType == 'month') {
        await _processMonthImport(data, mode, storageService);
      } else if (exportType == 'all') {
        await _processAllDataImport(data, mode, storageService);
      } else {
        throw Exception('Unknown export type: $exportType');
      }
    } catch (e) {
      throw Exception('Failed to process imported data: $e');
    }
  }

  static Future<void> _processMonthImport(
    Map<String, dynamic> data,
    ImportMode mode,
    StorageService storageService,
  ) async {
    final month = data['month'] as String;
    final year = data['year'] as int;

    // Parse income entries
    final incomeData = data['incomeEntries'] as List;
    final incomeEntries = incomeData.map((item) => IncomeEntry(
      id: item['id'],
      name: item['name'],
      amount: item['amount'].toDouble(),
      date: DateTime.parse(item['date']),
    )).toList();

    // Parse outcome entries
    final outcomeData = data['outcomeEntries'] as List;
    final outcomeEntries = outcomeData.map((item) => OutcomeEntry(
      id: item['id'],
      name: item['name'],
      amount: item['amount'].toDouble(),
      date: DateTime.parse(item['date']),
    )).toList();

    if (mode == ImportMode.replace) {
      // Replace existing data
      await storageService.saveIncomeEntries(month, year, incomeEntries);
      await storageService.saveOutcomeEntries(month, year, outcomeEntries);
    } else {
      // Integrate with existing data
      final existingIncome = await storageService.getIncomeEntries(month, year);
      final existingOutcome = await storageService.getOutcomeEntries(month, year);

      // Merge data (avoid duplicates by ID)
      final mergedIncome = [...existingIncome];
      for (final entry in incomeEntries) {
        if (!mergedIncome.any((e) => e.id == entry.id)) {
          mergedIncome.add(entry);
        }
      }

      final mergedOutcome = [...existingOutcome];
      for (final entry in outcomeEntries) {
        if (!mergedOutcome.any((e) => e.id == entry.id)) {
          mergedOutcome.add(entry);
        }
      }

      await storageService.saveIncomeEntries(month, year, mergedIncome);
      await storageService.saveOutcomeEntries(month, year, mergedOutcome);
    }
  }

  static Future<void> _processAllDataImport(
    Map<String, dynamic> data,
    ImportMode mode,
    StorageService storageService,
  ) async {
    final allData = data['allData'] as Map<String, dynamic>;
    final incomeData = allData['income'] as Map<String, dynamic>;
    final outcomeData = allData['outcome'] as Map<String, dynamic>;

    if (mode == ImportMode.replace) {
      // Clear all existing data first
      await storageService.clearAllData();
    }

    // Process income data
    for (final monthYear in incomeData.keys) {
      final parts = monthYear.split('_');
      final month = parts[0];
      final year = int.parse(parts[1]);

      final entries = (incomeData[monthYear] as List).map((item) => IncomeEntry(
        id: item['id'],
        name: item['name'],
        amount: item['amount'].toDouble(),
        date: DateTime.parse(item['date']),
      )).toList();

      if (mode == ImportMode.integrate) {
        final existing = await storageService.getIncomeEntries(month, year);
        final merged = [...existing];
        for (final entry in entries) {
          if (!merged.any((e) => e.id == entry.id)) {
            merged.add(entry);
          }
        }
        await storageService.saveIncomeEntries(month, year, merged);
      } else {
        await storageService.saveIncomeEntries(month, year, entries);
      }
    }

    // Process outcome data
    for (final monthYear in outcomeData.keys) {
      final parts = monthYear.split('_');
      final month = parts[0];
      final year = int.parse(parts[1]);

      final entries = (outcomeData[monthYear] as List).map((item) => OutcomeEntry(
        id: item['id'],
        name: item['name'],
        amount: item['amount'].toDouble(),
        date: DateTime.parse(item['date']),
      )).toList();

      if (mode == ImportMode.integrate) {
        final existing = await storageService.getOutcomeEntries(month, year);
        final merged = [...existing];
        for (final entry in entries) {
          if (!merged.any((e) => e.id == entry.id)) {
            merged.add(entry);
          }
        }
        await storageService.saveOutcomeEntries(month, year, merged);
      } else {
        await storageService.saveOutcomeEntries(month, year, entries);
      }
    }
  }

  static Future<Map<String, dynamic>> getImportPreview(String filePath) async {
    try {
      final data = await importDataFile(filePath);
      final exportType = data['exportType'] as String;

      if (exportType == 'month') {
        final month = data['month'] as String;
        final year = data['year'] as int;
        final incomeCount = (data['incomeEntries'] as List).length;
        final outcomeCount = (data['outcomeEntries'] as List).length;

        return {
          'type': 'month',
          'month': month,
          'year': year,
          'incomeCount': incomeCount,
          'outcomeCount': outcomeCount,
          'exportDate': data['exportDate'],
        };
      } else {
        final allData = data['allData'] as Map<String, dynamic>;
        final incomeData = allData['income'] as Map<String, dynamic>;
        final outcomeData = allData['outcome'] as Map<String, dynamic>;

        int totalIncomeEntries = 0;
        int totalOutcomeEntries = 0;

        for (final entries in incomeData.values) {
          totalIncomeEntries += (entries as List).length;
        }

        for (final entries in outcomeData.values) {
          totalOutcomeEntries += (entries as List).length;
        }

        return {
          'type': 'all',
          'monthsCount': incomeData.keys.length,
          'incomeCount': totalIncomeEntries,
          'outcomeCount': totalOutcomeEntries,
          'exportDate': data['exportDate'],
        };
      }
    } catch (e) {
      throw Exception('Failed to get import preview: $e');
    }
  }
}

enum ImportMode {
  replace,
  integrate,
}