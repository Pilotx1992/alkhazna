import 'package:flutter/foundation.dart';
import 'encryption_service.dart';
import 'backup_version_detector.dart';

/// Service for decrypting backups with legacy format support
class LegacyDecryptionService {
  static final LegacyDecryptionService _instance = LegacyDecryptionService._internal();
  factory LegacyDecryptionService() => _instance;
  LegacyDecryptionService._internal();

  final EncryptionService _encryptionService = EncryptionService();

  /// Decrypt backup with automatic version detection and fallback
  Future<Uint8List?> decryptBackupWithFallback({
    required Map<String, dynamic> encryptedBackup,
    required Uint8List masterKey,
  }) async {
    try {
      if (kDebugMode) {
        print('[LegacyDecryption] Starting decryption with fallback...');
      }

      // Step 1: Validate backup structure
      if (!BackupVersionDetector.validateBackupStructure(encryptedBackup)) {
        if (kDebugMode) {
          print('[LegacyDecryption] ❌ Invalid backup structure');
        }
        return null;
      }

      // Step 2: Detect backup version
      final version = BackupVersionDetector.detectVersion(encryptedBackup);
      if (kDebugMode) {
        print('[LegacyDecryption] Detected version: $version');
        print('[LegacyDecryption] Description: ${BackupVersionDetector.getVersionDescription(version)}');
      }

      // Step 3: Check compatibility
      if (!BackupVersionDetector.isCompatible(version)) {
        if (kDebugMode) {
          print('[LegacyDecryption] ❌ Incompatible backup version');
        }
        return null;
      }

      // Step 4: Decrypt using appropriate method
      Uint8List? decryptedData;

      if (version.isLegacy) {
        if (kDebugMode) {
          print('[LegacyDecryption] Using legacy decryption method');
          if (BackupVersionDetector.requiresMigration(version)) {
            print('[LegacyDecryption] Migration path: ${BackupVersionDetector.getMigrationPath(version)}');
          }
        }
        decryptedData = await _decryptLegacyFormat(
          encryptedBackup: encryptedBackup,
          masterKey: masterKey,
        );
      } else {
        if (kDebugMode) {
          print('[LegacyDecryption] Using current decryption method');
        }
        decryptedData = await _encryptionService.decryptDatabase(
          encryptedBackup: encryptedBackup,
          masterKey: masterKey,
        );
      }

      if (decryptedData != null) {
        if (kDebugMode) {
          print('[LegacyDecryption] ✅ Decryption successful (${decryptedData.length} bytes)');
        }
      } else {
        if (kDebugMode) {
          print('[LegacyDecryption] ❌ Decryption failed');
        }
      }

      return decryptedData;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('[LegacyDecryption] 💥 Error during decryption: $e');
        print('[LegacyDecryption] Stack trace: $stackTrace');
      }
      return null;
    }
  }

  /// Decrypt legacy backup format (v0.9, v1.0)
  Future<Uint8List?> _decryptLegacyFormat({
    required Map<String, dynamic> encryptedBackup,
    required Uint8List masterKey,
  }) async {
    try {
      if (kDebugMode) {
        print('[LegacyDecryption] Decrypting legacy format...');
      }

      // Legacy format uses same encryption algorithm (AES-256-GCM)
      // but may have different metadata structure

      // Try standard decryption first
      final result = await _encryptionService.decryptDatabase(
        encryptedBackup: encryptedBackup,
        masterKey: masterKey,
      );

      if (result != null) {
        if (kDebugMode) {
          print('[LegacyDecryption] ✅ Legacy decryption successful');
        }
        return result;
      }

      // If standard decryption fails, try alternative approaches
      if (kDebugMode) {
        print('[LegacyDecryption] Standard decryption failed, trying alternatives...');
      }

      // Alternative 1: Try without associated data
      // (Some old backups might not have used associated data)
      final altResult = await _decryptWithoutAssociatedData(
        encryptedBackup: encryptedBackup,
        masterKey: masterKey,
      );

      if (altResult != null) {
        if (kDebugMode) {
          print('[LegacyDecryption] ✅ Alternative decryption successful');
        }
        return altResult;
      }

      if (kDebugMode) {
        print('[LegacyDecryption] ❌ All decryption attempts failed');
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('[LegacyDecryption] ❌ Legacy decryption error: $e');
      }
      return null;
    }
  }

  /// Decrypt without associated data (for very old backups)
  Future<Uint8List?> _decryptWithoutAssociatedData({
    required Map<String, dynamic> encryptedBackup,
    required Uint8List masterKey,
  }) async {
    try {
      if (kDebugMode) {
        print('[LegacyDecryption] Trying decryption without associated data...');
      }

      // Extract encryption data
      final encryptedData = {
        'data': encryptedBackup['data'] as String,
        'iv': encryptedBackup['iv'] as String,
        'tag': encryptedBackup['tag'] as String,
      };

      // Decrypt without associated data
      final result = await _encryptionService.decryptData(
        encryptedData: encryptedData,
        masterKey: masterKey,
        associatedData: null, // No associated data
      );

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('[LegacyDecryption] ❌ Decryption without AAD failed: $e');
      }
      return null;
    }
  }

  /// Get decryption info for debugging
  Map<String, dynamic> getDecryptionInfo(Map<String, dynamic> encryptedBackup) {
    try {
      final version = BackupVersionDetector.detectVersion(encryptedBackup);
      final isValid = BackupVersionDetector.validateBackupStructure(encryptedBackup);
      final isCompatible = BackupVersionDetector.isCompatible(version);
      final requiresMigration = BackupVersionDetector.requiresMigration(version);

      return {
        'valid_structure': isValid,
        'version': version.toString(),
        'compatible': isCompatible,
        'requires_migration': requiresMigration,
        'migration_path': requiresMigration
            ? BackupVersionDetector.getMigrationPath(version)
            : 'No migration needed',
        'description': BackupVersionDetector.getVersionDescription(version),
        'encryption_info': _encryptionService.getEncryptionInfo(encryptedBackup),
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'valid_structure': false,
      };
    }
  }
}
