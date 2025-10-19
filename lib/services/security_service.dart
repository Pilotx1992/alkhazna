import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:local_auth/local_auth.dart';

import '../models/security_settings.dart';

/// Security service for PIN and biometric authentication
/// Manages all security-related operations with SHA-256 + Salt hashing
class SecurityService extends ChangeNotifier {
  // Storage keys
  static const String _pinHashKey = 'app_pin_hash';
  static const String _settingsBoxName = 'security_settings';

  // Dependencies
  final FlutterSecureStorage _secureStorage;
  final LocalAuthentication _localAuth;
  late Box<SecuritySettings> _settingsBox;

  // State
  bool _isLocked = true;
  SecuritySettings? _settings;
  bool _isInitialized = false;

  /// Constructor with dependency injection
  SecurityService({
    FlutterSecureStorage? secureStorage,
    LocalAuthentication? localAuth,
  })  : _secureStorage = secureStorage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
              ),
            ),
        _localAuth = localAuth ?? LocalAuthentication();

  /// Initialize the security service
  /// Must be called before using any other methods
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _settingsBox = await Hive.openBox<SecuritySettings>(_settingsBoxName);
      _settings = _settingsBox.get('current') ?? SecuritySettings.initial();

      // Lock app on start if PIN is enabled
      if (_settings!.isPinEnabled) {
        _isLocked = true;
      } else {
        _isLocked = false;
      }

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('SecurityService initialization error: $e');
      // Fallback to default settings if initialization fails
      _settings = SecuritySettings.initial();
      _isLocked = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  // ==================== Getters ====================

  /// Whether the app is currently locked
  bool get isLocked => _isLocked;

  /// Whether PIN protection is enabled
  bool get isPinEnabled => _settings?.isPinEnabled ?? false;

  /// Whether biometric unlock is enabled
  bool get isBiometricEnabled => _settings?.isBiometricEnabled ?? false;

  /// Number of consecutive failed attempts
  int get failedAttempts => _settings?.failedAttempts ?? 0;

  /// Timestamp when lockout period ends
  DateTime? get lockoutUntil => _settings?.lockoutUntil;

  /// Auto-lock timeout in seconds (0 = immediate)
  int get autoLockTimeout => _settings?.autoLockTimeout ?? 30;

  /// Session duration in minutes
  int get sessionDuration => _settings?.sessionDuration ?? 15;

  /// Check if currently in lockout period
  bool get isLockedOut {
    if (lockoutUntil == null) return false;
    return DateTime.now().isBefore(lockoutUntil!);
  }

  /// Get remaining lockout time in seconds
  int get lockoutRemainingSeconds {
    if (!isLockedOut) return 0;
    final remaining = lockoutUntil!.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  /// Whether a session is currently active
  bool get isSessionActive {
    if (!_isInitialized || _settings == null) return false;
    if (_settings!.sessionStartTime == null) return false;

    final now = DateTime.now();
    final sessionStart = _settings!.sessionStartTime!;
    final sessionDurationMinutes = _settings!.sessionDuration ?? 15; // Default 15 minutes
    final expiryTime = sessionStart.add(Duration(minutes: sessionDurationMinutes));

    return now.isBefore(expiryTime);
  }

  // ==================== PIN Management ====================

  /// Setup new PIN (first time)
  /// Generates random salt and stores hashed PIN
  Future<void> setupPin(String pin) async {
    _ensureInitialized();

    if (pin.length != 4 || !_isNumeric(pin)) {
      throw ArgumentError('PIN must be exactly 4 digits');
    }

    // Generate random salt (32 characters)
    final salt = _generateSalt();

    // Hash PIN with salt
    final hash = _hashPinWithSalt(pin, salt);

    // Store hash in secure storage
    await _secureStorage.write(key: _pinHashKey, value: hash);

    // Store salt and enable PIN in settings
    _settings!.isPinEnabled = true;
    _settings!.pinSalt = salt;
    _settings!.failedAttempts = 0;
    _settings!.lockoutUntil = null;
    await _saveSettings();

    _isLocked = false; // Unlock after setup
    notifyListeners();

    debugPrint('✅ PIN setup completed with salt');
  }

  /// Verify PIN against stored hash
  Future<bool> verifyPin(String pin) async {
    _ensureInitialized();

    if (!isPinEnabled) return false;

    // Check lockout
    if (isLockedOut) {
      throw LockoutException(
          'Too many failed attempts. Try again in ${lockoutRemainingSeconds}s');
    }

    try {
      // Get stored hash
      final storedHash = await _secureStorage.read(key: _pinHashKey);
      if (storedHash == null) {
        debugPrint('⚠️ No PIN hash found in secure storage');
        return false;
      }

      // Get salt from settings
      final salt = _settings!.pinSalt;
      if (salt == null) {
        debugPrint('⚠️ No salt found in settings');
        return false;
      }

      // Hash input PIN with salt
      final inputHash = _hashPinWithSalt(pin, salt);
      final isCorrect = storedHash == inputHash;

      if (isCorrect) {
        await _resetFailedAttempts();
        _isLocked = false;
        _settings!.lastUnlockedAt = DateTime.now();

        // Start session on successful unlock
        await startSession();

        await _saveSettings();
        notifyListeners();
        debugPrint('✅ PIN verified successfully + session started');
        return true;
      } else {
        await _incrementFailedAttempts();
        notifyListeners();
        debugPrint(
            '❌ Incorrect PIN. Attempts: ${_settings!.failedAttempts}');
        return false;
      }
    } catch (e) {
      debugPrint('Error verifying PIN: $e');
      return false;
    }
  }

  /// Change PIN (requires old PIN verification)
  Future<void> changePin(String oldPin, String newPin) async {
    _ensureInitialized();

    // Verify old PIN first
    final isOldPinCorrect = await verifyPin(oldPin);
    if (!isOldPinCorrect) {
      throw UnauthorizedException('Current PIN is incorrect');
    }

    if (newPin.length != 4 || !_isNumeric(newPin)) {
      throw ArgumentError('New PIN must be exactly 4 digits');
    }

    if (oldPin == newPin) {
      throw ArgumentError('New PIN must be different from current PIN');
    }

    // Generate new salt for new PIN
    final newSalt = _generateSalt();

    // Hash new PIN with new salt
    final newHash = _hashPinWithSalt(newPin, newSalt);

    // Store new hash
    await _secureStorage.write(key: _pinHashKey, value: newHash);

    // Update salt in settings
    _settings!.pinSalt = newSalt;
    await _saveSettings();

    notifyListeners();
    debugPrint('✅ PIN changed successfully');
  }

  /// Delete PIN and disable protection
  Future<void> deletePin() async {
    _ensureInitialized();

    try {
      await _secureStorage.delete(key: _pinHashKey);

      _settings!.isPinEnabled = false;
      _settings!.isBiometricEnabled = false;
      _settings!.pinSalt = null;
      _settings!.failedAttempts = 0;
      _settings!.lockoutUntil = null;
      await _saveSettings();

      _isLocked = false;
      notifyListeners();
      debugPrint('✅ PIN deleted and security disabled');
    } catch (e) {
      debugPrint('Error deleting PIN: $e');
      rethrow;
    }
  }

  /// Check if PIN is set
  Future<bool> isPinSet() async {
    _ensureInitialized();

    try {
      final hash = await _secureStorage.read(key: _pinHashKey);
      return hash != null && hash.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking PIN: $e');
      return false;
    }
  }

  // ==================== Biometric Management ====================

  /// Check if device supports biometric authentication
  Future<bool> isBiometricAvailable() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return canCheck && isDeviceSupported;
    } catch (e) {
      debugPrint('Error checking biometric availability: $e');
      return false;
    }
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      debugPrint('Error getting available biometrics: $e');
      return [];
    }
  }

  /// Enable biometric authentication
  Future<void> enableBiometric() async {
    _ensureInitialized();

    if (!isPinEnabled) {
      throw StateError('PIN must be enabled before enabling biometric');
    }

    if (!await isBiometricAvailable()) {
      throw UnsupportedError('Biometric authentication not available');
    }

    // Test biometric authentication before enabling
    final authenticated = await _localAuth.authenticate(
      localizedReason: 'Authenticate to enable biometric unlock',
      options: const AuthenticationOptions(
        stickyAuth: true,
        biometricOnly: true,
      ),
    );

    if (!authenticated) {
      throw UnauthorizedException('Biometric authentication failed');
    }

    _settings!.isBiometricEnabled = true;
    await _saveSettings();
    notifyListeners();
    debugPrint('✅ Biometric authentication enabled');
  }

  /// Disable biometric authentication
  Future<void> disableBiometric() async {
    _ensureInitialized();

    _settings!.isBiometricEnabled = false;
    await _saveSettings();
    notifyListeners();
    debugPrint('✅ Biometric authentication disabled');
  }

  /// Authenticate using biometric
  Future<bool> authenticateWithBiometric() async {
    _ensureInitialized();

    if (!isBiometricEnabled) return false;

    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Unlock Al Khazna',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (authenticated) {
        await _resetFailedAttempts();
        _isLocked = false;
        _settings!.lastUnlockedAt = DateTime.now();

        // Start session on successful biometric auth
        await startSession();

        await _saveSettings();
        notifyListeners();
        debugPrint('✅ Biometric authentication successful + session started');
      }

      return authenticated;
    } catch (e) {
      debugPrint('Biometric authentication error: $e');
      return false;
    }
  }

  // ==================== Lock State Management ====================

  /// Lock the app
  Future<void> lockApp() async {
    _ensureInitialized();

    if (!isPinEnabled) return;

    _isLocked = true;
    notifyListeners();
    debugPrint('🔒 App locked');
  }

  /// Unlock the app (only after successful authentication)
  Future<void> unlockApp() async {
    _ensureInitialized();

    _isLocked = false;
    notifyListeners();
    debugPrint('🔓 App unlocked');
  }

  // ==================== Session Management ====================

  /// Start a new security session after successful unlock
  Future<void> startSession() async {
    _ensureInitialized();

    final now = DateTime.now();
    _settings!.sessionStartTime = now;
    _settings!.lastInteractionTime = now;
    await _saveSettings();

    notifyListeners();
    final duration = _settings!.sessionDuration ?? 15;
    debugPrint('✅ Security session started (expires in $duration minutes)');
  }

  /// End the current security session
  Future<void> endSession() async {
    _ensureInitialized();

    _settings!.sessionStartTime = null;
    _settings!.lastInteractionTime = null;
    await _saveSettings();

    notifyListeners();
    debugPrint('🔒 Security session ended');
  }

  /// Update last interaction timestamp to keep session alive
  Future<void> updateLastInteraction() async {
    _ensureInitialized();

    // Only update if session is active
    if (isSessionActive) {
      _settings!.lastInteractionTime = DateTime.now();
      // Don't save on every interaction - too frequent
      // Session expiry is based on sessionStartTime anyway
      debugPrint('🔄 Interaction recorded - session refreshed');
    }
  }

  /// Determine if app should lock based on auto-lock timeout
  ///
  /// Returns true if app should lock, false if still within grace period
  bool shouldLockOnResume(DateTime pausedTime) {
    _ensureInitialized();

    // If no PIN, never lock
    if (!isPinEnabled) return false;

    // Check if session is active - if so, don't lock
    if (isSessionActive) {
      debugPrint('✅ Session active - no lock needed');
      return false;
    }

    // Session expired - check auto-lock timeout
    final autoLockSeconds = autoLockTimeout;

    // Never lock (timeout = -1 or very large)
    if (autoLockSeconds < 0 || autoLockSeconds > 3600) {
      debugPrint('✅ Auto-lock disabled - no lock');
      return false;
    }

    // Immediate lock (timeout = 0)
    if (autoLockSeconds == 0) {
      debugPrint('🔒 Immediate lock enabled - locking');
      return true;
    }

    // Check if pause duration exceeded timeout
    final now = DateTime.now();
    final pauseDuration = now.difference(pausedTime);
    final shouldLock = pauseDuration.inSeconds >= autoLockSeconds;

    if (shouldLock) {
      debugPrint('🔒 Auto-lock timeout exceeded (${pauseDuration.inSeconds}s > ${autoLockSeconds}s)');
    } else {
      debugPrint('✅ Within grace period (${pauseDuration.inSeconds}s < ${autoLockSeconds}s)');
    }

    return shouldLock;
  }

  /// Immediately lock the app and end session
  /// Used for manual "Lock Now" button
  Future<void> lockNow() async {
    _ensureInitialized();

    if (!isPinEnabled) return;

    // End session
    await endSession();

    // Lock app
    _isLocked = true;
    notifyListeners();

    debugPrint('🔒 App locked manually (Lock Now)');
  }

  /// Update auto-lock timeout setting
  Future<void> setAutoLockTimeout(int seconds) async {
    _ensureInitialized();

    _settings!.autoLockTimeout = seconds;
    await _saveSettings();
    notifyListeners();

    debugPrint('⏱️ Auto-lock timeout set to ${seconds}s');
  }

  /// Update session duration setting
  Future<void> setSessionDuration(int minutes) async {
    _ensureInitialized();

    _settings!.sessionDuration = minutes;
    await _saveSettings();
    notifyListeners();

    debugPrint('⏱️ Session duration set to $minutes minutes');
  }

  // ==================== Failed Attempts Management ====================

  Future<void> _incrementFailedAttempts() async {
    _settings!.failedAttempts++;

    // Lockout logic
    if (_settings!.failedAttempts >= 10) {
      // 10+ attempts: 5-minute lockout
      _settings!.lockoutUntil = DateTime.now().add(const Duration(minutes: 5));
      debugPrint('🚫 Lockout triggered: 5 minutes (${_settings!.failedAttempts} attempts)');
    } else if (_settings!.failedAttempts >= 5) {
      // 5-9 attempts: 30-second lockout
      _settings!.lockoutUntil =
          DateTime.now().add(const Duration(seconds: 30));
      debugPrint(
          '⚠️ Lockout triggered: 30 seconds (${_settings!.failedAttempts} attempts)');
    }

    await _saveSettings();
  }

  Future<void> _resetFailedAttempts() async {
    if (_settings!.failedAttempts > 0) {
      debugPrint('✅ Failed attempts reset (was: ${_settings!.failedAttempts})');
    }
    _settings!.failedAttempts = 0;
    _settings!.lockoutUntil = null;
    await _saveSettings();
  }

  // ==================== Helper Methods ====================

  /// Hash PIN with salt using SHA-256
  String _hashPinWithSalt(String pin, String salt) {
    final saltedPin = pin + salt;
    final bytes = utf8.encode(saltedPin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Generate random salt (32 characters)
  String _generateSalt() {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    return List.generate(32, (index) => chars[random.nextInt(chars.length)])
        .join();
  }

  /// Check if string contains only numeric digits
  bool _isNumeric(String str) {
    return RegExp(r'^[0-9]+$').hasMatch(str);
  }

  /// Save settings to Hive
  Future<void> _saveSettings() async {
    try {
      await _settingsBox.put('current', _settings!);
    } catch (e) {
      debugPrint('Error saving settings: $e');
    }
  }

  /// Ensure service is initialized
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError(
          'SecurityService not initialized. Call initialize() first.');
    }
  }

  // ==================== PIN Validation ====================

  /// Check if PIN is weak (sequential or repeating)
  bool isPinWeak(String pin) {
    if (pin.length != 4) return true;

    // Check for sequential (1234, 4321, etc.)
    if (_isSequential(pin)) return true;

    // Check for repeated (1111, 2222, etc.)
    if (_isRepeating(pin)) return true;

    return false;
  }

  /// Check if PIN is sequential (ascending or descending)
  bool _isSequential(String pin) {
    final nums = pin.split('').map(int.parse).toList();

    // Ascending: 1234, 2345, etc.
    bool isAscending = true;
    for (int i = 0; i < nums.length - 1; i++) {
      if (nums[i + 1] != nums[i] + 1) {
        isAscending = false;
        break;
      }
    }

    // Descending: 4321, 5432, etc.
    bool isDescending = true;
    for (int i = 0; i < nums.length - 1; i++) {
      if (nums[i + 1] != nums[i] - 1) {
        isDescending = false;
        break;
      }
    }

    return isAscending || isDescending;
  }

  /// Check if PIN has all same digits (1111, 2222, etc.)
  bool _isRepeating(String pin) {
    return pin.split('').toSet().length == 1;
  }

  /// Get PIN strength description
  String getPinStrengthDescription(String pin) {
    if (pin.length != 4) return 'Invalid';
    if (_isRepeating(pin)) return 'Very Weak (Repeating)';
    if (_isSequential(pin)) return 'Weak (Sequential)';
    return 'Good';
  }
}

// ==================== Custom Exceptions ====================

/// Exception thrown when too many failed attempts trigger lockout
class LockoutException implements Exception {
  final String message;
  LockoutException(this.message);

  @override
  String toString() => message;
}

/// Exception thrown when authentication fails
class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException(this.message);

  @override
  String toString() => message;
}
