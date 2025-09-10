import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../models/key_file_format.dart';
import 'google_drive_service.dart';

/// Enhanced key manager for WhatsApp-style backup system
class KeyManager extends ChangeNotifier {
  static final KeyManager _instance = KeyManager._internal();
  factory KeyManager() => _instance;
  KeyManager._internal();

  final GoogleDriveService _driveService = GoogleDriveService();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'https://www.googleapis.com/auth/drive.appdata',
      'email',
      'profile',
    ],
  );

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  static const String _keyFileName = 'alkhazna_backup_keys.encrypted';
  static const String _localKeyName = 'alkhazna_master_key_v2';

  /// Get or create persistent master key (WhatsApp-style)
  /// This ensures we always use the same key for a user account
  Future<Uint8List?> getOrCreatePersistentMasterKey() async {
    try {
      if (kDebugMode) {
        print('🔑 Getting or creating persistent master key...');
      }

      // Step 1: Get current Google account with forced authentication
      final account = await _ensureGoogleAccount();
      if (account == null) {
        if (kDebugMode) {
          print('❌ No Google account available');
        }
        return null;
      }

      final userEmail = account.email!;
      final googleId = account.id;
      
      if (kDebugMode) {
        print('👤 User: $userEmail (ID: $googleId)');
      }

      // Step 2: Try to retrieve existing key from cloud
      final existingKey = await _retrieveKeyFromCloud(userEmail, googleId);
      if (existingKey != null) {
        if (kDebugMode) {
          print('✅ Retrieved existing master key from cloud');
        }
        
        // Store locally for quick access
        await _storeKeyLocally(existingKey);
        return existingKey;
      }

      // Step 3: Try local storage (fallback)
      final localKey = await _getLocalKey();
      if (localKey != null) {
        if (kDebugMode) {
          print('📱 Found local key, uploading to cloud...');
        }
        
        // Upload local key to cloud for future use
        final uploaded = await _uploadKeyToCloud(userEmail, googleId, localKey);
        if (uploaded) {
          return localKey;
        }
      }

      // Step 4: Generate new master key
      if (kDebugMode) {
        print('🔧 Generating new master key...');
      }
      
      final newKey = await _generateSecureMasterKey();
      
      // Step 5: Save to both cloud and local storage
      final uploaded = await _uploadKeyToCloud(userEmail, googleId, newKey);
      if (!uploaded) {
        if (kDebugMode) {
          print('❌ Failed to upload key to cloud');
        }
        return null;
      }
      
      await _storeKeyLocally(newKey);
      
      if (kDebugMode) {
        print('✅ Created and stored new master key');
      }
      
      return newKey;
      
    } catch (e) {
      if (kDebugMode) {
        print('💥 Error in getOrCreatePersistentMasterKey: $e');
      }
      return null;
    }
  }

  /// Check if persistent master key exists in cloud
  Future<bool> hasPersistentMasterKey() async {
    try {
      final account = _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();
      if (account?.email == null) return false;
      
      return await _driveService.fileExists(_keyFileName);
    } catch (e) {
      if (kDebugMode) {
        print('Error checking persistent master key: $e');
      }
      return false;
    }
  }

  /// Ensure we have a valid Google account with forced authentication
  Future<GoogleSignInAccount?> _ensureGoogleAccount() async {
    try {
      // Try current user first
      var account = _googleSignIn.currentUser;
      
      // Try silent sign-in
      if (account == null) {
        account = await _googleSignIn.signInSilently();
      }
      
      // Force interactive sign-in if still null
      if (account == null) {
        account = await _googleSignIn.signIn();
      }
      
      // Validate account has required information
      if (account?.email == null || account?.id == null) {
        if (kDebugMode) {
          print('⚠️ Google account missing required information');
        }
        return null;
      }
      
      return account;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error ensuring Google account: $e');
      }
      return null;
    }
  }

  /// Retrieve master key from cloud storage
  Future<Uint8List?> _retrieveKeyFromCloud(String userEmail, String googleId) async {
    try {
      if (kDebugMode) {
        print('☁️ Retrieving key from cloud for: $userEmail');
      }

      // Search for key file in AppDataFolder
      final files = await _driveService.listFiles(query: "name='$_keyFileName'");
      
      if (files.isEmpty) {
        if (kDebugMode) {
          print('📂 No backup keys found in cloud');
        }
        return null;
      }

      // Download and parse the key file
      final keyFileContent = await _driveService.downloadFile(files.first.id!);
      if (keyFileContent == null) {
        if (kDebugMode) {
          print('❌ Failed to download key file');
        }
        return null;
      }

      final keyFileJson = json.decode(utf8.decode(keyFileContent));
      final keyFile = KeyFileFormat.fromJson(keyFileJson);

      // Validate the key belongs to this user
      if (!keyFile.belongsToUser(userEmail, googleId)) {
        if (kDebugMode) {
          print('⚠️ Key file does not belong to current user');
        }
        return null;
      }

      // Validate checksum
      if (!keyFile.validateChecksum()) {
        if (kDebugMode) {
          print('⚠️ Key file checksum validation failed');
        }
        return null;
      }

      if (kDebugMode) {
        print('✅ Successfully retrieved and validated key from cloud');
      }

      return keyFile.getMasterKey();
      
    } catch (e) {
      if (kDebugMode) {
        print('💥 Error retrieving key from cloud: $e');
      }
      return null;
    }
  }

  /// Upload master key to cloud storage
  Future<bool> _uploadKeyToCloud(String userEmail, String googleId, Uint8List masterKey) async {
    try {
      if (kDebugMode) {
        print('☁️ Uploading key to cloud for: $userEmail');
      }

      // Get device info
      final deviceInfo = DeviceInfoPlugin();
      String deviceId = 'Unknown';
      
      try {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = '${androidInfo.brand}-${androidInfo.model}';
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Could not get device info: $e');
        }
      }

      // Create key file format
      final keyFile = KeyFileFormat.fromKey(
        userEmail: userEmail,
        googleId: googleId,
        deviceId: deviceId,
        masterKey: masterKey,
      );

      // Convert to JSON and upload
      final keyFileContent = json.encode(keyFile.toJson());
      final keyFileBytes = utf8.encode(keyFileContent);

      final uploaded = await _driveService.uploadFile(
        fileName: _keyFileName,
        content: Uint8List.fromList(keyFileBytes),
        mimeType: 'application/json',
      );

      if (uploaded != null) {
        if (kDebugMode) {
          print('✅ Successfully uploaded key to cloud (ID: $uploaded)');
        }
        return true;
      } else {
        if (kDebugMode) {
          print('❌ Failed to upload key to cloud');
        }
        return false;
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('💥 Error uploading key to cloud: $e');
      }
      return false;
    }
  }

  /// Generate a secure 256-bit master key
  Future<Uint8List> _generateSecureMasterKey() async {
    final algorithm = AesGcm.with256bits();
    final secretKey = await algorithm.newSecretKey();
    final keyBytes = await secretKey.extractBytes();
    return Uint8List.fromList(keyBytes);
  }

  /// Store key in local secure storage
  Future<void> _storeKeyLocally(Uint8List masterKey) async {
    try {
      final hex = StringBuffer();
      for (final byte in masterKey) {
        hex.write(byte.toRadixString(16).padLeft(2, '0'));
      }
      
      await _secureStorage.write(
        key: _localKeyName,
        value: hex.toString(),
      );
      
      if (kDebugMode) {
        print('📱 Master key stored locally');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error storing key locally: $e');
      }
    }
  }

  /// Get key from local secure storage
  Future<Uint8List?> _getLocalKey() async {
    try {
      final hexKey = await _secureStorage.read(key: _localKeyName);
      if (hexKey == null) return null;
      
      final bytes = <int>[];
      for (int i = 0; i < hexKey.length; i += 2) {
        bytes.add(int.parse(hexKey.substring(i, i + 2), radix: 16));
      }
      
      return Uint8List.fromList(bytes);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting local key: $e');
      }
      return null;
    }
  }

  /// Clear all keys (for testing/reset)
  Future<void> clearAllKeys() async {
    try {
      await _secureStorage.delete(key: _localKeyName);
      // Note: We don't delete from cloud as user might want to keep it
      if (kDebugMode) {
        print('🗑️ Local keys cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error clearing keys: $e');
      }
    }
  }
}