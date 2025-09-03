import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:archive/archive_io.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'storage_service.dart';

enum BackupComponent {
  income('Income Data', 'Income entries and totals'),
  outcome('Outcome Data', 'Outcome entries and totals'),
  preferences('User Preferences', 'App settings and preferences'),
  metadata('App Metadata', 'Application metadata and configuration');

  const BackupComponent(this.displayName, this.description);
  
  final String displayName;
  final String description;
}

class SelectiveBackupOptions {
  final Set<BackupComponent> selectedComponents;
  final bool includeAppData;
  final bool compressData;
  final String compressionLevel;
  final DateTime? dateRangeStart;
  final DateTime? dateRangeEnd;

  SelectiveBackupOptions({
    required this.selectedComponents,
    this.includeAppData = true,
    this.compressData = true,
    this.compressionLevel = 'balanced',
    this.dateRangeStart,
    this.dateRangeEnd,
  });

  Map<String, dynamic> toMap() {
    return {
      'selectedComponents': selectedComponents.map((c) => c.name).toList(),
      'includeAppData': includeAppData,
      'compressData': compressData,
      'compressionLevel': compressionLevel,
      'dateRangeStart': dateRangeStart?.toIso8601String(),
      'dateRangeEnd': dateRangeEnd?.toIso8601String(),
    };
  }

  factory SelectiveBackupOptions.fromMap(Map<String, dynamic> map) {
    return SelectiveBackupOptions(
      selectedComponents: (map['selectedComponents'] as List<dynamic>?)
          ?.map((name) => BackupComponent.values.firstWhere((c) => c.name == name))
          .toSet() ?? BackupComponent.values.toSet(),
      includeAppData: map['includeAppData'] ?? true,
      compressData: map['compressData'] ?? true,
      compressionLevel: map['compressionLevel'] ?? 'balanced',
      dateRangeStart: map['dateRangeStart'] != null 
          ? DateTime.parse(map['dateRangeStart']) 
          : null,
      dateRangeEnd: map['dateRangeEnd'] != null 
          ? DateTime.parse(map['dateRangeEnd']) 
          : null,
    );
  }
}

class SelectiveBackupResult {
  final Archive archive;
  final Map<BackupComponent, int> componentSizes;
  final int totalSize;
  final Duration processingTime;
  final SelectiveBackupOptions options;

  SelectiveBackupResult({
    required this.archive,
    required this.componentSizes,
    required this.totalSize,
    required this.processingTime,
    required this.options,
  });
}

class SelectiveBackupService {
  static const String _optionsKey = 'selective_backup_options';
  
  /// Gets the user's saved selective backup preferences
  static Future<SelectiveBackupOptions> getSavedOptions() async {
    final prefs = await SharedPreferences.getInstance();
    final optionsJson = prefs.getString(_optionsKey);
    
    if (optionsJson != null) {
      try {
        final optionsMap = Map<String, dynamic>.from(
          Uri.splitQueryString(optionsJson).map((k, v) => MapEntry(k, Uri.decodeComponent(v)))
        );
        return SelectiveBackupOptions.fromMap(optionsMap);
      } catch (e) {
        debugPrint('Error loading saved backup options: $e');
      }
    }
    
    // Return default options
    return SelectiveBackupOptions(
      selectedComponents: BackupComponent.values.toSet(),
    );
  }

  /// Saves the user's selective backup preferences
  static Future<void> saveOptions(SelectiveBackupOptions options) async {
    final prefs = await SharedPreferences.getInstance();
    final optionsMap = options.toMap();
    final optionsJson = Uri(queryParameters: optionsMap.map((k, v) => MapEntry(k, v.toString()))).query;
    await prefs.setString(_optionsKey, optionsJson);
  }

  /// Analyzes what data will be included in the backup based on options
  static Future<Map<BackupComponent, Map<String, dynamic>>> analyzeBackupContent(
    SelectiveBackupOptions options
  ) async {
    final analysis = <BackupComponent, Map<String, dynamic>>{};
    
    for (final component in options.selectedComponents) {
      switch (component) {
        case BackupComponent.income:
          final incomeData = await _analyzeIncomeData(options);
          analysis[component] = incomeData;
          break;
          
        case BackupComponent.outcome:
          final outcomeData = await _analyzeOutcomeData(options);
          analysis[component] = outcomeData;
          break;
          
        case BackupComponent.preferences:
          final prefsData = await _analyzePreferencesData();
          analysis[component] = prefsData;
          break;
          
        case BackupComponent.metadata:
          final metaData = await _analyzeMetadata();
          analysis[component] = metaData;
          break;
      }
    }
    
    return analysis;
  }

  /// Creates a selective backup based on the provided options
  static Future<SelectiveBackupResult> createSelectiveBackup(
    SelectiveBackupOptions options, {
    Function(String)? onProgress,
  }) async {
    final stopwatch = Stopwatch()..start();
    onProgress?.call('Initializing selective backup...');
    
    final archive = Archive();
    final componentSizes = <BackupComponent, int>{};
    
    // Process each selected component
    for (final component in options.selectedComponents) {
      onProgress?.call('Processing ${component.displayName}...');
      
      int componentSize = 0;
      
      switch (component) {
        case BackupComponent.income:
          componentSize = await _addIncomeData(archive, options, onProgress);
          break;
          
        case BackupComponent.outcome:
          componentSize = await _addOutcomeData(archive, options, onProgress);
          break;
          
        case BackupComponent.preferences:
          componentSize = await _addPreferencesData(archive, onProgress);
          break;
          
        case BackupComponent.metadata:
          componentSize = await _addMetadataData(archive, onProgress);
          break;
      }
      
      componentSizes[component] = componentSize;
      onProgress?.call('${component.displayName} added (${_formatBytes(componentSize)})');
    }
    
    // Add backup manifest
    await _addBackupManifest(archive, options);
    
    stopwatch.stop();
    
    final totalSize = componentSizes.values.fold(0, (sum, size) => sum + size);
    
    onProgress?.call('Selective backup created successfully!');
    
    return SelectiveBackupResult(
      archive: archive,
      componentSizes: componentSizes,
      totalSize: totalSize,
      processingTime: stopwatch.elapsed,
      options: options,
    );
  }

  static Future<Map<String, dynamic>> _analyzeIncomeData(SelectiveBackupOptions options) async {
    try {
      final storageService = StorageService();
      final allEntries = await storageService.getAllIncomeEntries();
      
      // Apply date filtering if specified
      final filteredEntries = _filterEntriesByDate(allEntries, options);
      
      return {
        'totalEntries': allEntries.length,
        'selectedEntries': filteredEntries.length,
        'estimatedSize': filteredEntries.length * 100, // rough estimate
        'hasData': filteredEntries.isNotEmpty,
      };
    } catch (e) {
      return {
        'totalEntries': 0,
        'selectedEntries': 0,
        'estimatedSize': 0,
        'hasData': false,
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> _analyzeOutcomeData(SelectiveBackupOptions options) async {
    try {
      final storageService = StorageService();
      final allEntries = await storageService.getAllOutcomeEntries();
      
      // Apply date filtering if specified
      final filteredEntries = _filterEntriesByDate(allEntries, options);
      
      return {
        'totalEntries': allEntries.length,
        'selectedEntries': filteredEntries.length,
        'estimatedSize': filteredEntries.length * 120, // rough estimate
        'hasData': filteredEntries.isNotEmpty,
      };
    } catch (e) {
      return {
        'totalEntries': 0,
        'selectedEntries': 0,
        'estimatedSize': 0,
        'hasData': false,
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> _analyzePreferencesData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      return {
        'totalPreferences': keys.length,
        'estimatedSize': keys.length * 50, // rough estimate
        'hasData': keys.isNotEmpty,
      };
    } catch (e) {
      return {
        'totalPreferences': 0,
        'estimatedSize': 0,
        'hasData': false,
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> _analyzeMetadata() async {
    return {
      'estimatedSize': 500, // metadata is typically small
      'hasData': true,
      'includes': ['app_version', 'backup_date', 'device_info'],
    };
  }

  static List<dynamic> _filterEntriesByDate(List<dynamic> entries, SelectiveBackupOptions options) {
    if (options.dateRangeStart == null && options.dateRangeEnd == null) {
      return entries;
    }
    
    return entries.where((entry) {
      // Assuming entries have a date field - adapt based on your data structure
      final entryDate = entry.createdAt as DateTime?;
      if (entryDate == null) return true; // Include entries without dates
      
      if (options.dateRangeStart != null && entryDate.isBefore(options.dateRangeStart!)) {
        return false;
      }
      
      if (options.dateRangeEnd != null && entryDate.isAfter(options.dateRangeEnd!)) {
        return false;
      }
      
      return true;
    }).toList();
  }

  static Future<int> _addIncomeData(
    Archive archive, 
    SelectiveBackupOptions options,
    Function(String)? onProgress
  ) async {
    try {
      final storageService = StorageService();
      final allEntries = await storageService.getAllIncomeEntries();
      final filteredEntries = _filterEntriesByDate(allEntries, options);
      
      final jsonData = {
        'entries': filteredEntries.map((e) => e.toMap()).toList(),
        'metadata': {
          'component': 'income',
          'total_entries': filteredEntries.length,
          'export_date': DateTime.now().toIso8601String(),
          'date_range': {
            'start': options.dateRangeStart?.toIso8601String(),
            'end': options.dateRangeEnd?.toIso8601String(),
          }
        }
      };
      
      final jsonString = jsonEncode(jsonData);
      final bytes = Uint8List.fromList(utf8.encode(jsonString));
      
      archive.addFile(ArchiveFile('income_data.json', bytes.length, bytes));
      return bytes.length;
      
    } catch (e) {
      debugPrint('Error adding income data: $e');
      return 0;
    }
  }

  static Future<int> _addOutcomeData(
    Archive archive, 
    SelectiveBackupOptions options,
    Function(String)? onProgress
  ) async {
    try {
      final storageService = StorageService();
      final allEntries = await storageService.getAllOutcomeEntries();
      final filteredEntries = _filterEntriesByDate(allEntries, options);
      
      final jsonData = {
        'entries': filteredEntries.map((e) => e.toMap()).toList(),
        'metadata': {
          'component': 'outcome',
          'total_entries': filteredEntries.length,
          'export_date': DateTime.now().toIso8601String(),
          'date_range': {
            'start': options.dateRangeStart?.toIso8601String(),
            'end': options.dateRangeEnd?.toIso8601String(),
          }
        }
      };
      
      final jsonString = jsonEncode(jsonData);
      final bytes = Uint8List.fromList(utf8.encode(jsonString));
      
      archive.addFile(ArchiveFile('outcome_data.json', bytes.length, bytes));
      return bytes.length;
      
    } catch (e) {
      debugPrint('Error adding outcome data: $e');
      return 0;
    }
  }

  static Future<int> _addPreferencesData(Archive archive, Function(String)? onProgress) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      final prefsData = <String, dynamic>{};
      for (final key in keys) {
        try {
          final value = prefs.get(key);
          prefsData[key] = value;
        } catch (e) {
          debugPrint('Error reading preference $key: $e');
        }
      }
      
      final jsonData = {
        'preferences': prefsData,
        'metadata': {
          'component': 'preferences',
          'total_keys': keys.length,
          'export_date': DateTime.now().toIso8601String(),
        }
      };
      
      final jsonString = jsonEncode(jsonData);
      final bytes = Uint8List.fromList(utf8.encode(jsonString));
      
      archive.addFile(ArchiveFile('preferences.json', bytes.length, bytes));
      return bytes.length;
      
    } catch (e) {
      debugPrint('Error adding preferences data: $e');
      return 0;
    }
  }

  static Future<int> _addMetadataData(Archive archive, Function(String)? onProgress) async {
    final metaData = {
      'app_version': '1.0.0',
      'backup_date': DateTime.now().toIso8601String(),
      'device_info': Platform.operatingSystem,
      'backup_type': 'selective',
      'flutter_version': 'unknown', // Could be populated from build info
    };
    
    final jsonString = jsonEncode(metaData);
    final bytes = Uint8List.fromList(utf8.encode(jsonString));
    
    archive.addFile(ArchiveFile('metadata.json', bytes.length, bytes));
    return bytes.length;
  }

  static Future<void> _addBackupManifest(Archive archive, SelectiveBackupOptions options) async {
    final manifest = {
      'backup_format_version': '1.0',
      'created_at': DateTime.now().toIso8601String(),
      'options': options.toMap(),
      'components': options.selectedComponents.map((c) => {
        'name': c.name,
        'display_name': c.displayName,
        'description': c.description,
      }).toList(),
    };
    
    final jsonString = jsonEncode(manifest);
    final bytes = Uint8List.fromList(utf8.encode(jsonString));
    
    archive.addFile(ArchiveFile('backup_manifest.json', bytes.length, bytes));
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Validates if a selective restore is possible with the given backup
  static Future<Map<String, dynamic>> validateBackupForRestore(Archive archive) async {
    try {
      // Look for backup manifest
      final manifestFile = archive.files.firstWhere(
        (file) => file.name == 'backup_manifest.json',
        orElse: () => throw Exception('Backup manifest not found'),
      );
      
      final manifestJson = utf8.decode(manifestFile.content as List<int>);
      final manifest = jsonDecode(manifestJson);
      
      // Analyze available components
      final availableComponents = <String>[];
      for (final file in archive.files) {
        if (file.name.endsWith('_data.json')) {
          availableComponents.add(file.name.replaceAll('_data.json', ''));
        }
      }
      
      return {
        'valid': true,
        'manifest': manifest,
        'available_components': availableComponents,
        'backup_date': manifest['created_at'],
        'format_version': manifest['backup_format_version'],
      };
      
    } catch (e) {
      return {
        'valid': false,
        'error': e.toString(),
      };
    }
  }
}