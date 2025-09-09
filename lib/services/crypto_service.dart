import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:convert/convert.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CryptoService {
  static final CryptoService _instance = CryptoService._internal();
  factory CryptoService() => _instance;
  CryptoService._internal();

  static const String _masterKeyStorageKey = 'alkhazna_master_key';
  static const String _recoveryKeyStorageKey = 'alkhazna_recovery_key_wrapped';
  
  final _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  final _aesGcm = AesGcm.with256bits();
  final _random = Random.secure();

  // Generate device-bound master key (32 bytes for AES-256)
  Future<Uint8List> _generateMasterKey() async {
    final bytes = Uint8List(32);
    for (int i = 0; i < bytes.length; i++) {
      bytes[i] = _random.nextInt(256);
    }
    return bytes;
  }

  // Get or create master key from secure storage
  Future<Uint8List> getMasterKey() async {
    try {
      final storedKey = await _secureStorage.read(key: _masterKeyStorageKey);
      if (storedKey != null) {
        return Uint8List.fromList(hex.decode(storedKey));
      }
    } catch (e) {
      print('Failed to read master key: $e');
    }

    // Generate new master key
    final masterKey = await _generateMasterKey();
    try {
      await _secureStorage.write(
        key: _masterKeyStorageKey,
        value: hex.encode(masterKey),
      );
    } catch (e) {
      print('Failed to store master key: $e');
      throw Exception('Could not secure master key');
    }
    return masterKey;
  }

  // Generate recovery key (Base32 encoded, 32 characters)
  String generateRecoveryKey() {
    const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    final buffer = StringBuffer();
    for (int i = 0; i < 32; i++) {
      buffer.write(alphabet[_random.nextInt(alphabet.length)]);
    }
    return buffer.toString();
  }

  // Derive KEK from recovery key using PBKDF2
  Future<Uint8List> _deriveKekFromRecoveryKey(String recoveryKey, Uint8List salt) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: 210000, // 210k iterations as per plan
      bits: 256, // 32 bytes output
    );
    
    final secretKey = await pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(recoveryKey)),
      nonce: salt,
    );
    
    return Uint8List.fromList(await secretKey.extractBytes());
  }

  // Wrap master key with recovery key
  Future<Map<String, String>> wrapMasterKeyWithRecovery(String recoveryKey, String sessionId) async {
    final masterKey = await getMasterKey();
    final salt = Uint8List(16);
    for (int i = 0; i < salt.length; i++) {
      salt[i] = _random.nextInt(256);
    }
    
    final kek = await _deriveKekFromRecoveryKey(recoveryKey, salt);
    final nonce = _aesGcm.newNonce();
    final aad = utf8.encode('wmk|$sessionId'); // Associated auth data
    
    final secretBox = await _aesGcm.encrypt(
      masterKey,
      secretKey: SecretKey(kek),
      nonce: nonce,
      aad: aad,
    );
    
    return {
      'iv': base64.encode(nonce),
      'tag': base64.encode(secretBox.mac.bytes),
      'ct': base64.encode(secretBox.cipherText),
      'salt': base64.encode(salt),
    };
  }

  // Unwrap master key using recovery key
  Future<Uint8List> unwrapMasterKeyWithRecovery(String recoveryKey, Map<String, String> wmk, String sessionId) async {
    final salt = base64.decode(wmk['salt']!);
    final kek = await _deriveKekFromRecoveryKey(recoveryKey, salt);
    
    final nonce = base64.decode(wmk['iv']!);
    final tag = Mac(base64.decode(wmk['tag']!));
    final cipherText = base64.decode(wmk['ct']!);
    final aad = utf8.encode('wmk|$sessionId');
    
    final secretBox = SecretBox(cipherText, nonce: nonce, mac: tag);
    
    final decrypted = await _aesGcm.decrypt(
      secretBox,
      secretKey: SecretKey(kek),
      aad: aad,
    );
    
    return Uint8List.fromList(decrypted);
  }

  // Encrypt data with master key
  Future<Map<String, String>> encryptData(Uint8List data, String sessionId, String fileId) async {
    final masterKey = await getMasterKey();
    
    // Generate secure 12-byte nonce for AES-GCM
    final nonce = Uint8List(12);
    for (int i = 0; i < 12; i++) {
      nonce[i] = _random.nextInt(256);
    }
    
    final aad = utf8.encode('alkhazna|$sessionId|$fileId'); // Associated auth data per backup plan
    
    final secretBox = await _aesGcm.encrypt(
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

  // Decrypt data with master key
  Future<Uint8List> decryptData(Map<String, String> encryptedData, String sessionId, String fileId) async {
    try {
      final masterKey = await getMasterKey();
      final nonce = base64.decode(encryptedData['iv']!);
      final tag = Mac(base64.decode(encryptedData['tag']!));
      final cipherText = base64.decode(encryptedData['data']!);
      final aad = utf8.encode('alkhazna|$sessionId|$fileId');
      
      final secretBox = SecretBox(cipherText, nonce: nonce, mac: tag);
      
      final decrypted = await _aesGcm.decrypt(
        secretBox,
        secretKey: SecretKey(masterKey),
        aad: aad,
      );
      
      return Uint8List.fromList(decrypted);
    } catch (e) {
      print('ERROR: Decryption failed for sessionId=$sessionId, fileId=$fileId: $e');
      rethrow;
    }
  }

  // Check if master key exists (for UI state)
  Future<bool> hasMasterKey() async {
    try {
      final storedKey = await _secureStorage.read(key: _masterKeyStorageKey);
      return storedKey != null;
    } catch (e) {
      return false;
    }
  }

  // Reset encryption (remove all keys - use with caution)
  Future<void> resetEncryption() async {
    try {
      await _secureStorage.delete(key: _masterKeyStorageKey);
      await _secureStorage.delete(key: _recoveryKeyStorageKey);
    } catch (e) {
      print('Failed to reset encryption: $e');
    }
  }

  // Generate SHA-256 hash for integrity verification
  Future<String> sha256Hash(Uint8List data) async {
    final sha256 = Sha256();
    final hash = await sha256.hash(data);
    return hex.encode(hash.bytes);
  }

  // Secure memory wipe (best effort)
  void secureWipe(Uint8List data) {
    for (int i = 0; i < data.length; i++) {
      data[i] = 0;
    }
  }
}