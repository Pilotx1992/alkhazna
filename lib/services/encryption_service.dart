import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';

/// Encryption service for WhatsApp-style backup system
/// Uses AES-256-GCM for authenticated encryption
class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  final AesGcm _algorithm = AesGcm.with256bits();

  /// Encrypt data using master key
  Future<Map<String, String>?> encryptData({
    required Uint8List data,
    required Uint8List masterKey,
    String? associatedData,
  }) async {
    try {
      if (kDebugMode) {
        print('🔐 Encrypting ${data.length} bytes of data...');
      }

      // Create secret key from master key
      final secretKey = SecretKey(masterKey);

      // Generate random nonce
      final nonce = _algorithm.newNonce();

      // Prepare associated data if provided
      List<int>? aad;
      if (associatedData != null) {
        aad = utf8.encode(associatedData);
      }

      // Encrypt the data
      final secretBox = await _algorithm.encrypt(
        data,
        secretKey: secretKey,
        nonce: nonce,
        aad: aad != null ? aad! : [],
      );

      // Convert to base64 strings for storage
      final result = {
        'data': base64Encode(secretBox.cipherText),
        'iv': base64Encode(secretBox.nonce),
        'tag': base64Encode(secretBox.mac.bytes),
      };

      if (kDebugMode) {
        print('✅ Data encrypted successfully');
        print('   Cipher length: ${secretBox.cipherText.length}');
        print('   IV length: ${secretBox.nonce.length}');
        print('   Tag length: ${secretBox.mac.bytes.length}');
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('💥 Encryption failed: $e');
      }
      return null;
    }
  }

  /// Decrypt data using master key
  Future<Uint8List?> decryptData({
    required Map<String, String> encryptedData,
    required Uint8List masterKey,
    String? associatedData,
  }) async {
    try {
      if (kDebugMode) {
        print('🔓 Decrypting data...');
      }

      // Validate required fields
      if (!encryptedData.containsKey('data') ||
          !encryptedData.containsKey('iv') ||
          !encryptedData.containsKey('tag')) {
        if (kDebugMode) {
          print('❌ Missing required encryption fields');
        }
        return null;
      }

      // Create secret key from master key
      final secretKey = SecretKey(masterKey);

      // Decode base64 data
      final cipherText = base64Decode(encryptedData['data']!);
      final nonce = base64Decode(encryptedData['iv']!);
      final macBytes = base64Decode(encryptedData['tag']!);

      // Prepare associated data if provided
      List<int>? aad;
      if (associatedData != null) {
        aad = utf8.encode(associatedData);
      }

      // Create SecretBox for decryption
      final secretBox = SecretBox(
        cipherText,
        nonce: nonce,
        mac: Mac(macBytes),
      );

      // Decrypt the data
      final decryptedData = await _algorithm.decrypt(
        secretBox,
        secretKey: secretKey,
        aad: aad != null ? aad! : [],
      );

      final result = Uint8List.fromList(decryptedData);

      if (kDebugMode) {
        print('✅ Data decrypted successfully');
        print('   Decrypted length: ${result.length}');
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('💥 Decryption failed: $e');
      }
      return null;
    }
  }

  /// Encrypt database file for backup
  Future<Map<String, dynamic>?> encryptDatabase({
    required Uint8List databaseBytes,
    required Uint8List masterKey,
    required String backupId,
  }) async {
    try {
      if (kDebugMode) {
        print('💾 Encrypting database for backup...');
        print('   Database size: ${databaseBytes.length} bytes');
      }

      // Use backup ID as associated data for additional security
      final associatedData = 'alkhazna_backup_$backupId';

      // Encrypt the database
      final encryptedData = await encryptData(
        data: databaseBytes,
        masterKey: masterKey,
        associatedData: associatedData,
      );

      if (encryptedData == null) {
        return null;
      }

      // Add metadata
      final result = {
        'encrypted': true,
        'version': '1.0',
        'backup_id': backupId,
        'original_size': databaseBytes.length,
        'timestamp': DateTime.now().toIso8601String(),
        ...encryptedData,
      };

      if (kDebugMode) {
        print('✅ Database encrypted for backup');
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('💥 Database encryption failed: $e');
      }
      return null;
    }
  }

  /// Decrypt database file from backup
  Future<Uint8List?> decryptDatabase({
    required Map<String, dynamic> encryptedBackup,
    required Uint8List masterKey,
  }) async {
    try {
      if (kDebugMode) {
        print('💾 Decrypting database from backup...');
      }

      // Validate backup format
      if (encryptedBackup['encrypted'] != true) {
        if (kDebugMode) {
          print('❌ Backup is not encrypted');
        }
        return null;
      }

      final backupId = encryptedBackup['backup_id'] as String?;
      if (backupId == null) {
        if (kDebugMode) {
          print('❌ Missing backup ID');
        }
        return null;
      }

      // Extract encryption data
      final encryptedData = {
        'data': encryptedBackup['data'] as String,
        'iv': encryptedBackup['iv'] as String,
        'tag': encryptedBackup['tag'] as String,
      };

      // Use backup ID as associated data
      final associatedData = 'alkhazna_backup_$backupId';

      // Decrypt the database
      final decryptedData = await decryptData(
        encryptedData: encryptedData,
        masterKey: masterKey,
        associatedData: associatedData,
      );

      if (decryptedData != null) {
        if (kDebugMode) {
          print('✅ Database decrypted from backup');
          print('   Decrypted size: ${decryptedData.length} bytes');
        }
      }

      return decryptedData;
    } catch (e) {
      if (kDebugMode) {
        print('💥 Database decryption failed: $e');
      }
      return null;
    }
  }

  /// Generate secure random bytes
  Future<Uint8List> generateRandomBytes(int length) async {
    final random = SecureRandom.fast;
    final bytes = List<int>.filled(length, 0);
    for (int i = 0; i < length; i++) {
      bytes[i] = random.nextInt(256);
    }
    return Uint8List.fromList(bytes);
  }

  /// Secure wipe of sensitive data from memory
  void secureWipe(Uint8List data) {
    try {
      // Overwrite with random data
      for (int i = 0; i < data.length; i++) {
        data[i] = 0;
      }
      
      if (kDebugMode) {
        print('🧹 Secure wipe completed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Secure wipe failed: $e');
      }
    }
  }

  /// Validate encryption format
  bool isValidEncryptedFormat(Map<String, dynamic> data) {
    return data.containsKey('encrypted') &&
           data.containsKey('data') &&
           data.containsKey('iv') &&
           data.containsKey('tag') &&
           data['encrypted'] == true;
  }

  /// Get encryption info for debugging
  Map<String, dynamic> getEncryptionInfo(Map<String, dynamic> encryptedData) {
    if (!isValidEncryptedFormat(encryptedData)) {
      return {'valid': false, 'error': 'Invalid format'};
    }

    try {
      final dataLength = base64Decode(encryptedData['data'] as String).length;
      final ivLength = base64Decode(encryptedData['iv'] as String).length;
      final tagLength = base64Decode(encryptedData['tag'] as String).length;

      return {
        'valid': true,
        'algorithm': 'AES-256-GCM',
        'data_length': dataLength,
        'iv_length': ivLength,
        'tag_length': tagLength,
        'version': encryptedData['version'] ?? 'unknown',
        'timestamp': encryptedData['timestamp'] ?? 'unknown',
      };
    } catch (e) {
      return {'valid': false, 'error': e.toString()};
    }
  }
}