import 'dart:convert';
import 'dart:typed_data';
import 'package:convert/convert.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'crypto_service.dart';
import 'drive/drive_provider_resumable.dart';

/// Manages backup encryption keys by storing them securely in Google Drive
/// This ensures keys persist across app installations when using the same Google account
class BackupKeyManager {
  static final BackupKeyManager _instance = BackupKeyManager._internal();
  factory BackupKeyManager() => _instance;
  BackupKeyManager._internal();

  final DriveProviderResumable _driveProvider = DriveProviderResumable();
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final CryptoService _cryptoService = CryptoService();
  
  static const String _keyFileName = 'alkhazna_backup_keys.encrypted';
  
  /// Store encryption keys securely in Google Drive's app data folder
  Future<bool> saveKeysToCloud(String userEmail, Uint8List encryptionKey) async {
    try {
      if (kDebugMode) {
        print('🔑 Saving encryption keys to Google Drive for user: $userEmail');
      }
      
      // Ensure user is authenticated
      if (!await _ensureAuthenticated()) {
        if (kDebugMode) {
          print('❌ User not authenticated, cannot save keys to cloud');
        }
        return false;
      }
      
      // Derive master key from user's email
      final masterKey = await _deriveMasterKey(userEmail);
      
      // Create key data structure
      final keyData = {
        'version': '1.0',
        'user_email': userEmail,
        'created_at': DateTime.now().toIso8601String(),
        'encryption_key': hex.encode(encryptionKey),
        'app_version': '1.0.0', // TODO: Get from package info
      };
      
      // Encrypt the key data
      final keyDataJson = json.encode(keyData);
      final keyDataBytes = utf8.encode(keyDataJson);
      
      final encryptedKeyData = await _encryptWithMasterKey(
        keyDataBytes, 
        masterKey, 
        'backup_keys|$userEmail'
      );
      
      // Save to Google Drive app data folder
      final success = await _saveToAppDataFolder(encryptedKeyData);
      
      if (kDebugMode) {
        print(success ? '✅ Keys saved to cloud successfully' : '❌ Failed to save keys to cloud');
      }
      
      return success;
      
    } catch (e) {
      if (kDebugMode) {
        print('💥 Error saving keys to cloud: $e');
      }
      return false;
    }
  }
  
  /// Retrieve encryption keys from Google Drive
  Future<Uint8List?> retrieveKeysFromCloud(String userEmail) async {
    try {
      if (kDebugMode) {
        print('🔍 Retrieving encryption keys from Google Drive for user: $userEmail');
      }
      
      // Ensure user is authenticated
      if (!await _ensureAuthenticated()) {
        if (kDebugMode) {
          print('❌ User not authenticated, cannot retrieve keys from cloud');
        }
        return null;
      }
      
      // Download encrypted keys from Google Drive
      final encryptedKeyData = await _retrieveFromAppDataFolder();
      if (encryptedKeyData == null) {
        if (kDebugMode) {
          print('⚠️ No backup keys found in cloud');
        }
        return null;
      }
      
      // Derive master key and decrypt
      final masterKey = await _deriveMasterKey(userEmail);
      
      final decryptedKeyData = await _decryptWithMasterKey(
        encryptedKeyData,
        masterKey,
        'backup_keys|$userEmail'
      );
      
      // Parse key data
      final keyDataJson = utf8.decode(decryptedKeyData);
      final keyData = json.decode(keyDataJson) as Map<String, dynamic>;
      
      // Validate the key data belongs to this user
      final storedEmail = keyData['user_email'] as String;
      if (storedEmail.toLowerCase() != userEmail.toLowerCase()) {
        if (kDebugMode) {
          print('❌ Key data belongs to different user: $storedEmail vs $userEmail');
        }
        return null;
      }
      
      // Extract and return the encryption key
      final encryptionKeyHex = keyData['encryption_key'] as String;
      final encryptionKey = Uint8List.fromList(hex.decode(encryptionKeyHex));
      
      if (kDebugMode) {
        print('✅ Successfully retrieved encryption keys from cloud');
        print('   Created: ${keyData['created_at']}');
        print('   Version: ${keyData['version']}');
      }
      
      return encryptionKey;
      
    } catch (e) {
      if (kDebugMode) {
        print('💥 Error retrieving keys from cloud: $e');
      }
      return null;
    }
  }
  
  /// Check if backup keys exist in the cloud
  Future<bool> hasCloudKeys(String userEmail) async {
    try {
      final keys = await retrieveKeysFromCloud(userEmail);
      return keys != null;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking for cloud keys: $e');
      }
      return false;
    }
  }
  
  /// Delete backup keys from the cloud
  Future<bool> deleteCloudKeys() async {
    try {
      if (!await _ensureAuthenticated()) {
        return false;
      }
      
      // Find and delete the key file
      final files = await _driveProvider.queryFiles(
        "name='$_keyFileName' and parents in 'appDataFolder'"
      );
      
      if (files.isNotEmpty) {
        final fileId = files.first['id'] as String;
        await _driveProvider.deleteFile(fileId);
        
        if (kDebugMode) {
          print('✅ Cloud backup keys deleted successfully');
        }
        return true;
      }
      
      if (kDebugMode) {
        print('⚠️ No cloud backup keys found to delete');
      }
      return true; // Not an error if no keys exist
      
    } catch (e) {
      if (kDebugMode) {
        print('💥 Error deleting cloud keys: $e');
      }
      return false;
    }
  }
  
  /// Derive a master key from user's email using PBKDF2
  Future<Uint8List> _deriveMasterKey(String userEmail) async {
    // Use a fixed salt based on app identifier to ensure consistency
    final salt = utf8.encode('alkhazna_backup_key_v1_${userEmail.toLowerCase()}');
    
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: 100000, // 100k iterations for good security vs performance balance
      bits: 256, // 32 bytes output for AES-256
    );
    
    final secret = SecretKey(utf8.encode(userEmail.toLowerCase()));
    final derivedKey = await pbkdf2.deriveKey(
      secretKey: secret,
      nonce: Uint8List.fromList(salt.take(16).toList()), // Use first 16 bytes as nonce
    );
    
    return Uint8List.fromList(await derivedKey.extractBytes());
  }
  
  /// Encrypt data with master key using AES-GCM
  Future<Map<String, String>> _encryptWithMasterKey(
    Uint8List data, 
    Uint8List masterKey, 
    String context
  ) async {
    final aesGcm = AesGcm.with256bits();
    final nonce = aesGcm.newNonce();
    final aad = utf8.encode('alkhazna_key_storage|$context');
    
    final secretBox = await aesGcm.encrypt(
      data,
      secretKey: SecretKey(masterKey),
      nonce: nonce,
      aad: aad,
    );
    
    return {
      'iv': base64.encode(nonce),
      'tag': base64.encode(secretBox.mac.bytes),
      'data': base64.encode(secretBox.cipherText),
    };
  }
  
  /// Decrypt data with master key using AES-GCM
  Future<Uint8List> _decryptWithMasterKey(
    Map<String, String> encryptedData,
    Uint8List masterKey,
    String context
  ) async {
    final aesGcm = AesGcm.with256bits();
    final nonce = base64.decode(encryptedData['iv']!);
    final tag = Mac(base64.decode(encryptedData['tag']!));
    final cipherText = base64.decode(encryptedData['data']!);
    final aad = utf8.encode('alkhazna_key_storage|$context');
    
    final secretBox = SecretBox(cipherText, nonce: nonce, mac: tag);
    
    final decrypted = await aesGcm.decrypt(
      secretBox,
      secretKey: SecretKey(masterKey),
      aad: aad,
    );
    
    return Uint8List.fromList(decrypted);
  }
  
  /// Save encrypted key data to Google Drive app data folder
  Future<bool> _saveToAppDataFolder(Map<String, String> encryptedData) async {
    try {
      // Convert to JSON for storage
      final dataJson = json.encode(encryptedData);
      final dataBytes = utf8.encode(dataJson);
      
      // Check if file already exists and delete it
      final existingFiles = await _driveProvider.queryFiles(
        "name='$_keyFileName' and parents in 'appDataFolder'"
      );
      
      for (final file in existingFiles) {
        await _driveProvider.deleteFile(file['id'] as String);
        if (kDebugMode) {
          print('🗑️ Deleted existing key file: ${file['id']}');
        }
      }
      
      // Upload new key file to app data folder
      final fileId = await _driveProvider.uploadToAppDataFolder(
        fileName: _keyFileName,
        content: dataBytes,
        mimeType: 'application/json',
      );
      
      return fileId != null;
      
    } catch (e) {
      if (kDebugMode) {
        print('Error saving to app data folder: $e');
      }
      return false;
    }
  }
  
  /// Retrieve encrypted key data from Google Drive app data folder
  Future<Map<String, String>?> _retrieveFromAppDataFolder() async {
    try {
      // Find the key file in app data folder
      final files = await _driveProvider.queryFiles(
        "name='$_keyFileName' and parents in 'appDataFolder'"
      );
      
      if (files.isEmpty) {
        return null; // No key file found
      }
      
      // Download the file content
      final fileId = files.first['id'] as String;
      final fileBytes = await _driveProvider.downloadFileBytes(fileId);
      
      // Parse the JSON data
      final dataJson = utf8.decode(fileBytes);
      final encryptedData = json.decode(dataJson) as Map<String, dynamic>;
      
      // Convert to Map<String, String>
      return encryptedData.map((key, value) => MapEntry(key, value.toString()));
      
    } catch (e) {
      if (kDebugMode) {
        print('Error retrieving from app data folder: $e');
      }
      return null;
    }
  }
  
  /// Ensure Google authentication
  Future<bool> _ensureAuthenticated() async {
    try {
      final account = await _googleSignIn.signIn();
      return account != null;
    } catch (e) {
      if (kDebugMode) {
        print('Authentication failed: $e');
      }
      return false;
    }
  }
}