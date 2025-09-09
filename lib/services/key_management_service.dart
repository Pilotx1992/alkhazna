import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'crypto_service.dart';

class KeyManagementService extends ChangeNotifier {
  static final KeyManagementService _instance = KeyManagementService._internal();
  factory KeyManagementService() => _instance;
  KeyManagementService._internal();

  final CryptoService _cryptoService = CryptoService();
  
  static const String _encryptionEnabledKey = 'encryption_enabled';
  static const String _recoveryKeyGeneratedKey = 'recovery_key_generated';

  // Check if encryption is enabled
  Future<bool> isEncryptionEnabled() async {
    final box = await Hive.openBox('key_management');
    return box.get(_encryptionEnabledKey, defaultValue: true); // Default enabled for hybrid approach
  }

  // Enable/disable encryption
  Future<void> setEncryptionEnabled(bool enabled) async {
    final box = await Hive.openBox('key_management');
    await box.put(_encryptionEnabledKey, enabled);
    
    if (enabled && !await _cryptoService.hasMasterKey()) {
      // Generate master key when encryption is first enabled
      await _cryptoService.getMasterKey();
    }
    
    notifyListeners();
  }

  // Check if recovery key has been generated
  Future<bool> hasRecoveryKey() async {
    final box = await Hive.openBox('key_management');
    return box.get(_recoveryKeyGeneratedKey, defaultValue: false);
  }

  // Generate recovery key and return it for user to save
  Future<String> generateRecoveryKey(String sessionId) async {
    final recoveryKey = _cryptoService.generateRecoveryKey();
    
    // Wrap master key with recovery key
    final wmk = await _cryptoService.wrapMasterKeyWithRecovery(recoveryKey, sessionId);
    
    // Store that recovery key has been generated and store wmk
    final box = await Hive.openBox('key_management');
    await box.put(_recoveryKeyGeneratedKey, true);
    await box.put('wmk_data', wmk);
    
    notifyListeners();
    return recoveryKey;
  }

  // Get wrapped master key data for backup manifest
  Future<Map<String, String>?> getWrappedMasterKeyData() async {
    final box = await Hive.openBox('key_management');
    final wmkData = box.get('wmk_data');
    if (wmkData is Map) {
      return Map<String, String>.from(wmkData);
    }
    return null;
  }

  // Restore master key from recovery key (for restore on new device)
  Future<bool> restoreMasterKeyFromRecovery(String recoveryKey, Map<String, String> wmk, String sessionId) async {
    try {
      final masterKey = await _cryptoService.unwrapMasterKeyWithRecovery(recoveryKey, wmk, sessionId);
      
      // Store the recovered master key securely
      await _storeRecoveredMasterKey(masterKey);
      
      // Mark that we have a recovery key
      final box = await Hive.openBox('key_management');
      await box.put(_recoveryKeyGeneratedKey, true);
      await box.put('wmk_data', wmk);
      
      // Secure wipe the recovered key from memory
      _cryptoService.secureWipe(masterKey);
      
      notifyListeners();
      return true;
    } catch (e) {
      print('Failed to restore master key from recovery: $e');
      return false;
    }
  }

  // Store recovered master key (internal method)
  Future<void> _storeRecoveredMasterKey(Uint8List masterKey) async {
    const secureStorage = FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
      ),
    );
    
    final hex = StringBuffer();
    for (final byte in masterKey) {
      hex.write(byte.toRadixString(16).padLeft(2, '0'));
    }
    
    await secureStorage.write(
      key: 'alkhazna_master_key',
      value: hex.toString(),
    );
  }

  // Reset all encryption data (use with extreme caution)
  Future<void> resetEncryption() async {
    await _cryptoService.resetEncryption();
    
    final box = await Hive.openBox('key_management');
    await box.delete(_encryptionEnabledKey);
    await box.delete(_recoveryKeyGeneratedKey);
    await box.delete('wmk_data');
    
    notifyListeners();
  }

  // Get encryption status for UI
  Future<Map<String, dynamic>> getEncryptionStatus() async {
    return {
      'enabled': await isEncryptionEnabled(),
      'hasMasterKey': await _cryptoService.hasMasterKey(),
      'hasRecoveryKey': await hasRecoveryKey(),
    };
  }

  // Initialize encryption system (called on app start)
  Future<void> initializeEncryption() async {
    final enabled = await isEncryptionEnabled();
    if (enabled && !await _cryptoService.hasMasterKey()) {
      // Auto-generate master key for hybrid approach
      await _cryptoService.getMasterKey();
    }
  }
}