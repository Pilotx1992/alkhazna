import 'package:flutter/foundation.dart';

/// Backup version information
class BackupVersion {
  final String formatVersion;      // Overall backup format (1.0, 2.0)
  final String encryptionVersion;  // Encryption algorithm version (1.0, 1.1)
  final String dataSchemaVersion;  // Data model version (1.0, 1.1)
  final bool isLegacy;             // True for v1.0 format without explicit versioning

  const BackupVersion({
    required this.formatVersion,
    required this.encryptionVersion,
    required this.dataSchemaVersion,
    required this.isLegacy,
  });

  factory BackupVersion.unknown() {
    return const BackupVersion(
      formatVersion: 'unknown',
      encryptionVersion: 'unknown',
      dataSchemaVersion: 'unknown',
      isLegacy: true,
    );
  }

  @override
  String toString() {
    return 'BackupVersion(format: $formatVersion, encryption: $encryptionVersion, schema: $dataSchemaVersion, legacy: $isLegacy)';
  }
}

/// Service for detecting backup format versions
class BackupVersionDetector {
  /// Detect the version of a backup file
  static BackupVersion detectVersion(Map<String, dynamic> backupData) {
    try {
      // Check for v1.1+ format with explicit versioning
      if (backupData.containsKey('format_version')) {
        final formatVersion = backupData['format_version'];
        final encryptionVersion = backupData['encryption_version'] ?? '1.0';
        final schemaVersion = backupData['data_schema_version'] ?? '1.0';

        if (kDebugMode) {
          print('[BackupVersionDetector] Detected v1.1+ backup:');
          print('  Format: $formatVersion');
          print('  Encryption: $encryptionVersion');
          print('  Schema: $schemaVersion');
        }

        return BackupVersion(
          formatVersion: formatVersion.toString(),
          encryptionVersion: encryptionVersion.toString(),
          dataSchemaVersion: schemaVersion.toString(),
          isLegacy: false,
        );
      }

      // Legacy format (v1.0) - only has 'version' field
      if (backupData.containsKey('version')) {
        final version = backupData['version'].toString();

        if (kDebugMode) {
          print('[BackupVersionDetector] Detected legacy v1.0 backup');
          print('  Version: $version');
        }

        return BackupVersion(
          formatVersion: version,
          encryptionVersion: version,
          dataSchemaVersion: version,
          isLegacy: true,
        );
      }

      // Even older format (v0.9) - no version field at all
      if (kDebugMode) {
        print('[BackupVersionDetector] Detected very old backup (v0.9 or earlier)');
      }

      return BackupVersion(
        formatVersion: '0.9',
        encryptionVersion: '0.9',
        dataSchemaVersion: '0.9',
        isLegacy: true,
      );
    } catch (e) {
      if (kDebugMode) {
        print('[BackupVersionDetector] Error detecting version: $e');
      }
      return BackupVersion.unknown();
    }
  }

  /// Check if a backup version is compatible with current app
  static bool isCompatible(BackupVersion version) {
    if (version.formatVersion == 'unknown') {
      if (kDebugMode) {
        print('[BackupVersionDetector] ❌ Unknown version - not compatible');
      }
      return false;
    }

    // We support all versions from 0.9 to 2.0
    final supportedVersions = ['0.9', '1.0', '1.1', '2.0'];
    final isSupported = supportedVersions.contains(version.formatVersion);

    if (kDebugMode) {
      if (isSupported) {
        print('[BackupVersionDetector] ✅ Version ${version.formatVersion} is compatible');
      } else {
        print('[BackupVersionDetector] ❌ Version ${version.formatVersion} is not supported');
      }
    }

    return isSupported;
  }

  /// Check if backup requires migration
  static bool requiresMigration(BackupVersion version) {
    // Legacy formats need migration to add UUIDs
    return version.isLegacy;
  }

  /// Get migration path for a version
  static String getMigrationPath(BackupVersion version) {
    if (version.formatVersion == '0.9') {
      return '0.9 → 1.0 → 1.1 (Add version field, add UUIDs)';
    } else if (version.formatVersion == '1.0') {
      return '1.0 → 1.1 (Add UUIDs to entries)';
    } else {
      return 'No migration needed';
    }
  }

  /// Get user-friendly version description
  static String getVersionDescription(BackupVersion version) {
    switch (version.formatVersion) {
      case '0.9':
        return 'Very old backup (before versioning system)';
      case '1.0':
        return 'Legacy backup (before UUID system)';
      case '1.1':
        return 'Current backup with UUID support';
      case '2.0':
        return 'Enhanced backup with full versioning';
      default:
        return 'Unknown backup format';
    }
  }

  /// Check if backup has encryption metadata
  static bool hasEncryptionMetadata(Map<String, dynamic> backupData) {
    return backupData.containsKey('encrypted') &&
           backupData.containsKey('data') &&
           backupData.containsKey('iv') &&
           backupData.containsKey('tag');
  }

  /// Validate backup structure
  static bool validateBackupStructure(Map<String, dynamic> backupData) {
    try {
      // Check for required encryption fields
      if (!hasEncryptionMetadata(backupData)) {
        if (kDebugMode) {
          print('[BackupVersionDetector] ❌ Missing encryption metadata');
        }
        return false;
      }

      // Check if encrypted field is valid
      final encrypted = backupData['encrypted'];
      if (encrypted != true && encrypted != 'true') {
        if (kDebugMode) {
          print('[BackupVersionDetector] ❌ Backup is not encrypted');
        }
        return false;
      }

      // Check for backup ID (required for decryption)
      if (!backupData.containsKey('backup_id')) {
        if (kDebugMode) {
          print('[BackupVersionDetector] ❌ Missing backup_id');
        }
        return false;
      }

      if (kDebugMode) {
        print('[BackupVersionDetector] ✅ Backup structure is valid');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('[BackupVersionDetector] ❌ Error validating structure: $e');
      }
      return false;
    }
  }
}
