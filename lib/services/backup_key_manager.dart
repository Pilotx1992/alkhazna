import 'dart:convert';
import 'dart:math';
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
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'https://www.googleapis.com/auth/drive.file',
      'https://www.googleapis.com/auth/drive.appdata',  // Required for app data folder access
      'email',  // Required for user identification
      'profile',  // Required for account verification
    ],
  );
  final CryptoService _cryptoService = CryptoService();
  
  static const String _keyFileName = 'alkhazna_backup_keys.encrypted';
  
  /// Store encryption keys securely in Google Drive's app data folder
  Future<bool> saveKeysToCloud(String userEmail, Uint8List encryptionKey) async {
    try {
      if (kDebugMode) {
        print('🔑 Saving encryption keys to Google Drive for user: $userEmail');
        final currentUser = _googleSignIn.currentUser;
        print('🔍 Current Google user during BACKUP: ${currentUser?.email}');
        print('🔍 Requested user email: $userEmail');
        print('🔍 Account match: ${currentUser?.email?.toLowerCase() == userEmail.toLowerCase()}');
      }
      
      // Ensure user is authenticated with expected email
      final account = await _ensureAuthenticated(expectedEmail: userEmail);
      if (account == null) {
        if (kDebugMode) {
          print('❌ User not authenticated or account mismatch, cannot save keys to cloud');
        }
        return false;
      }
      
      // Double-check account email matches what we expect
      if (account.email?.toLowerCase() != userEmail.toLowerCase()) {
        if (kDebugMode) {
          print('❌ Critical: Account email mismatch after authentication');
          print('   Account: ${account.email}');
          print('   Expected: $userEmail');
        }
        return false;
      }
      
      // Derive master key from user's email
      final masterKey = await _deriveMasterKey(userEmail);
      
      // Create key data structure with enhanced account binding
      final keyData = {
        'version': '1.1', // Updated version for enhanced binding
        'user_email': userEmail,
        'user_email_normalized': userEmail.toLowerCase().trim(),
        'google_account_id': account.id, // Google account ID for stronger binding
        'created_at': DateTime.now().toIso8601String(),
        'last_accessed': DateTime.now().toIso8601String(),
        'encryption_key': hex.encode(encryptionKey),
        'app_version': '1.0.0', // TODO: Get from package info
        'device_info': {
          'platform': 'android', // Could be dynamic
          'created_by': '${account.displayName} (${account.email})',
        },
        'security_checksum': _generateSecurityChecksum(userEmail, account.id),
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
        final currentUser = _googleSignIn.currentUser;
        print('🔍 Current Google user during RESTORE: ${currentUser?.email}');
        print('🔍 Requested user email: $userEmail');
        print('🔍 Account match: ${currentUser?.email?.toLowerCase() == userEmail.toLowerCase()}');
      }
      
      // Ensure user is authenticated with expected email
      final account = await _ensureAuthenticated(expectedEmail: userEmail);
      if (account == null) {
        if (kDebugMode) {
          print('❌ User not authenticated or account mismatch, cannot retrieve keys from cloud');
        }
        return null;
      }
      
      // Double-check account email matches what we expect
      if (account.email?.toLowerCase() != userEmail.toLowerCase()) {
        if (kDebugMode) {
          print('❌ Critical: Account email mismatch after authentication');
          print('   Account: ${account.email}');
          print('   Expected: $userEmail');
        }
        return null;
      }
      
      // Download encrypted keys from Google Drive
      final encryptedKeyData = await _retrieveFromAppDataFolder();
      if (encryptedKeyData == null) {
        if (kDebugMode) {
          print('⚠️ No backup keys found in cloud');
          print('🔍 DEBUG: Listing all files in app data folder...');
          await _debugListAppDataFolderFiles();
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
      
      // Enhanced validation - check multiple binding points
      final storedEmail = keyData['user_email'] as String;
      final storedNormalizedEmail = keyData['user_email_normalized'] as String?;
      final storedAccountId = keyData['google_account_id'] as String?;
      final storedChecksum = keyData['security_checksum'] as String?;
      
      // Primary validation: email match
      if (storedEmail.toLowerCase() != userEmail.toLowerCase()) {
        if (kDebugMode) {
          print('❌ Key data belongs to different user: $storedEmail vs $userEmail');
        }
        return null;
      }
      
      // Enhanced validation for v1.1+ keys
      if (keyData['version'] == '1.1') {
        // Validate Google account ID if available
        if (storedAccountId != null && account.id != storedAccountId) {
          if (kDebugMode) {
            print('❌ Google account ID mismatch: ${account.id} vs $storedAccountId');
            print('   This could indicate account transfer or security issue');
          }
          return null;
        }
        
        // Validate security checksum
        final expectedChecksum = _generateSecurityChecksum(userEmail, account.id);
        if (storedChecksum != null && storedChecksum != expectedChecksum) {
          if (kDebugMode) {
            print('❌ Security checksum validation failed');
          }
          return null;
        }
        
        // Update last accessed timestamp
        await _updateLastAccessedTime(encryptedKeyData);
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
  
  /// Get or create persistent master key (WhatsApp-style)
  /// This ensures we always use the same key for a user account
  Future<Uint8List?> getOrCreatePersistentMasterKey(String userEmail) async {
    try {
      if (kDebugMode) {
        print('🔑 Getting or creating persistent master key for: $userEmail');
      }
      
      // Step 1: Try to retrieve existing key from cloud
      final existingKey = await retrieveKeysFromCloud(userEmail);
      if (existingKey != null) {
        if (kDebugMode) {
          print('✅ Found existing master key in cloud');
        }
        return existingKey;
      }
      
      if (kDebugMode) {
        print('🆕 No existing key found, creating new persistent master key');
      }
      
      // Step 2: Generate new master key
      final newKey = await _generateSecureMasterKey();
      
      // Step 3: Save to cloud immediately
      final saved = await saveKeysToCloud(userEmail, newKey);
      if (!saved) {
        if (kDebugMode) {
          print('❌ Failed to save new master key to cloud');
        }
        return null;
      }
      
      if (kDebugMode) {
        print('✅ New persistent master key created and saved to cloud');
      }
      
      return newKey;
      
    } catch (e) {
      if (kDebugMode) {
        print('💥 Error getting/creating persistent master key: $e');
      }
      return null;
    }
  }
  
  /// Generate a cryptographically secure master key
  Future<Uint8List> _generateSecureMasterKey() async {
    // Generate 32 bytes (256 bits) for AES-256
    final random = Random.secure();
    final key = Uint8List(32);
    for (int i = 0; i < 32; i++) {
      key[i] = random.nextInt(256);
    }
    return key;
  }
  
  /// Delete backup keys from the cloud
  Future<bool> deleteCloudKeys() async {
    try {
      final account = await _ensureAuthenticated();
      if (account == null) {
        if (kDebugMode) {
          print('❌ User not authenticated, cannot delete cloud keys');
        }
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
      if (kDebugMode) {
        print('🔍 Searching for key file in app data folder...');
      }
      
      // Multiple search strategies to ensure we find the file
      final searchQueries = [
        "name='$_keyFileName' and parents in 'appDataFolder' and trashed=false",
        "'appDataFolder' in parents and name='$_keyFileName' and trashed=false",
        "parents in 'appDataFolder' and name contains 'alkhazna_backup_keys'",
        "name='$_keyFileName'"  // Fallback - search everywhere
      ];
      
      Map<String, dynamic>? foundFile;
      for (final query in searchQueries) {
        if (kDebugMode) {
          print('🔍 Trying query: $query');
        }
        
        final files = await _driveProvider.queryFiles(query);
        if (files.isNotEmpty) {
          foundFile = files.first;
          if (kDebugMode) {
            print('✅ Found key file with query: $query');
            print('   File ID: ${foundFile['id']}');
            print('   File Name: ${foundFile['name']}');
            print('   Parents: ${foundFile['parents']}');
          }
          break;
        }
      }
      
      if (foundFile == null) {
        if (kDebugMode) {
          print('❌ No key file found with any search query');
        }
        return null;
      }
      
      // Download the file content
      final fileId = foundFile['id'] as String;
      if (kDebugMode) {
        print('📥 Downloading key file: $fileId');
      }
      
      final fileBytes = await _driveProvider.downloadFileBytes(fileId);
      
      // Parse the JSON data
      final dataJson = utf8.decode(fileBytes);
      final encryptedData = json.decode(dataJson) as Map<String, dynamic>;
      
      if (kDebugMode) {
        print('✅ Successfully retrieved and parsed key file');
        print('   Data keys: ${encryptedData.keys.toList()}');
      }
      
      // Convert to Map<String, String>
      return encryptedData.map((key, value) => MapEntry(key, value.toString()));
      
    } catch (e) {
      if (kDebugMode) {
        print('💥 Error retrieving from app data folder: $e');
        print('   Stack trace: ${StackTrace.current}');
      }
      return null;
    }
  }
  
  /// Ensure Google authentication with forced account verification
  Future<GoogleSignInAccount?> _ensureAuthenticated({String? expectedEmail}) async {
    try {
      if (kDebugMode) {
        print('🔐 Starting Google authentication process...');
      }
      
      // First try silent sign-in to get existing account
      GoogleSignInAccount? account = await _googleSignIn.signInSilently();
      
      if (account == null) {
        if (kDebugMode) {
          print('🔑 Silent sign-in failed, requesting interactive sign-in...');
        }
        
        // Force interactive sign-in if silent fails
        account = await _googleSignIn.signIn();
      }
      
      if (account != null) {
        if (kDebugMode) {
          print('📧 Active Google Account: ${account.email}');
          print('🔍 Expected email: $expectedEmail');
          print('✅ Account verification: ${expectedEmail == null ? "Not required" : account.email?.toLowerCase() == expectedEmail.toLowerCase() ? "✅ Match" : "❌ Mismatch"}');
        }
        
        // If we have an expected email, verify it matches
        if (expectedEmail != null && account.email?.toLowerCase() != expectedEmail.toLowerCase()) {
          if (kDebugMode) {
            print('❌ Account mismatch! Current: ${account.email}, Expected: $expectedEmail');
            print('🔄 Attempting to sign out and re-authenticate with correct account...');
          }
          
          // Sign out and try again
          await _googleSignIn.signOut();
          account = await _googleSignIn.signIn();
          
          // Final verification
          if (account?.email?.toLowerCase() != expectedEmail.toLowerCase()) {
            if (kDebugMode) {
              print('💥 Final verification failed: ${account?.email} != $expectedEmail');
            }
            return null;
          }
        }
        
        if (kDebugMode) {
          print('✅ Google authentication successful: ${account?.email}');
        }
        return account;
      } else {
        if (kDebugMode) {
          print('❌ Google authentication failed: No account returned');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('💥 Authentication error: $e');
      }
      return null;
    }
  }
  
  /// Debug method to list all files in app data folder
  Future<void> _debugListAppDataFolderFiles() async {
    try {
      // First, list ALL files in appDataFolder
      final files = await _driveProvider.queryFiles("parents in 'appDataFolder'");
      if (kDebugMode) {
        print('📂 DEBUG: Complete app data folder listing:');
        print('🔍 Found ${files.length} files in app data folder:');
        for (final file in files) {
          print('   📄 Name: ${file['name']}, ID: ${file['id']}, Size: ${file['size']}, Modified: ${file['modifiedTime']}');
        }
        
        // Search for any file containing "alkhazna" or "backup"
        print('\n🔍 Searching for ANY files containing "alkhazna" or "backup":');
        final allFiles = await _driveProvider.queryFiles("parents in 'appDataFolder' and (name contains 'alkhazna' or name contains 'backup')");
        print('🔍 Found ${allFiles.length} files matching search terms');
        for (final file in allFiles) {
          print('   📄 Match: ${file['name']}, ID: ${file['id']}, Size: ${file['size']}');
        }
        
        // Also specifically search for our key file
        print('\n🔍 Searching specifically for "$_keyFileName"...');
        final keyFiles = await _driveProvider.queryFiles(
          "name='$_keyFileName' and parents in 'appDataFolder'"
        );
        print('🔍 Found ${keyFiles.length} key files with exact name match');
        for (final file in keyFiles) {
          print('   🔑 Key file: ${file['name']}, ID: ${file['id']}, Size: ${file['size']}');
        }
        
        // Try different query formats
        print('\n🔍 Trying alternative queries...');
        try {
          final altQuery1 = await _driveProvider.queryFiles("parents in 'appDataFolder' and name = '$_keyFileName'");
          print('🔍 Alt query 1 (=): Found ${altQuery1.length} files');
          
          final altQuery2 = await _driveProvider.queryFiles("'appDataFolder' in parents and name = '$_keyFileName'");
          print('🔍 Alt query 2 (reversed): Found ${altQuery2.length} files');
        } catch (queryError) {
          print('❌ Alternative query failed: $queryError');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error listing app data folder files: $e');
      }
    }
  }
  
  /// Generate security checksum for account binding validation
  String _generateSecurityChecksum(String userEmail, String googleAccountId) {
    final input = '${userEmail.toLowerCase().trim()}|$googleAccountId|alkhazna_security_v1';
    final bytes = utf8.encode(input);
    
    // Simple hash for checksum - could be enhanced with crypto hash
    int hash = 0;
    for (int byte in bytes) {
      hash = ((hash << 5) - hash + byte) & 0xffffffff;
    }
    return hash.toRadixString(16);
  }
  
  /// Update the last accessed timestamp for the key file (stub for now)
  Future<void> _updateLastAccessedTime(Map<String, String> keyData) async {
    // TODO: Implement if we want to track access patterns
    // For now, this is just a placeholder for future enhancement
    if (kDebugMode) {
      print('📝 Key access logged at ${DateTime.now().toIso8601String()}');
    }
  }
}