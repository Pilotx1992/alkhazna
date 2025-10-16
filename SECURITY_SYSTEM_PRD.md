# 📋 Al Khazna Security System - Complete PRD

## 🎯 Project Overview

### Primary Objective
Implement a comprehensive local security system for Al Khazna app using PIN Code (4 digits) + Biometric Authentication (Fingerprint/Face ID) to protect users' financial data without any external dependencies.

### Core Requirements
1. **PIN Code (4 digits)**: Primary authentication mechanism
2. **Biometric Authentication**: Fingerprint/Face ID as fast alternative
3. **Lock Screen**: Display on app launch and background return
4. **Auto-lock**: Automatic lock when app goes to background
5. **Secure Local Storage**: Encrypted PIN storage using device keystore

### Non-Functional Requirements
- Response time: < 500ms for PIN verification
- No network dependency (100% offline)
- Support Android 6.0+ and iOS 12.0+
- Zero tolerance for security breaches
- Minimal impact on app performance

---

## 🏗️ System Architecture

### 1. File Structure

```
lib/
├── services/
│   └── security_service.dart                    # Core security logic
│
├── screens/
│   └── security/
│       ├── setup_pin_screen.dart                # Initial PIN setup
│       ├── unlock_screen.dart                   # Main unlock interface
│       ├── verify_pin_screen.dart               # PIN verification for sensitive ops
│       └── change_pin_screen.dart               # PIN change workflow
│
├── models/
│   ├── security_settings.dart                   # Security configuration model
│   └── security_settings.g.dart                 # Hive adapter (generated)
│
└── widgets/
    ├── pin_input_widget.dart                    # PIN input UI (4 circles + keypad)
    └── security_shimmer_widget.dart             # Loading state widget
```

### 2. Dependencies (All Already Installed ✅)
```yaml
dependencies:
  local_auth: ^2.1.6                    # Biometric authentication
  flutter_secure_storage: ^9.2.2       # Secure PIN storage
  crypto: ^3.0.3                        # SHA-256 hashing
  hive: ^2.2.3                          # Local database
  hive_flutter: ^1.1.0                  # Hive Flutter integration
  provider: ^6.1.2                      # State management
```

**No new dependencies needed!**

---

## 📱 Screen Specifications

### 1. Setup PIN Screen

**Trigger Conditions:**
- First app launch when PIN not configured
- User enables PIN from Settings
- After app reinstall (PIN reset)

**UI Layout:**
```
┌─────────────────────────────┐
│         [Back Arrow]        │
│                             │
│     [Shield Icon + Lock]    │  ← 120x120px
│                             │
│   Secure your Al Khazna     │  ← 24px bold
│                             │
│ Create a 4-digit PIN to     │  ← 16px regular
│ protect your financial data │
│                             │
│      ○  ○  ○  ○            │  ← PIN dots (60px each)
│                             │
│    [Numeric Keypad]         │  ← 3x4 grid
│                             │
│ You can enable fingerprint  │  ← 14px grey
│    unlock later             │
│                             │
│    [SET UP NOW Button]      │  ← Full width, 50px height
└─────────────────────────────┘
```

**User Flow:**
1. User enters 4 digits → dots fill with animation
2. Screen transitions to "Confirm your PIN"
3. User re-enters PIN
4. **If match**:
   - Save encrypted PIN
   - Show success message
   - Optional: Dialog "Enable Biometric?"
   - Navigate to Home
5. **If mismatch**:
   - Show error "PINs don't match"
   - Return to step 1 (keep first PIN in memory)

**Validation Rules:**
- Must be exactly 4 digits
- Cannot be sequential (1234, 4321)
- Cannot be all same (1111, 2222)
- Show warning for weak PINs but allow them

---

### 2. Unlock Screen

**Trigger Conditions:**
- App launched when PIN is set and app was locked
- App returns from background (after 5 seconds)
- User manually locks app

**UI Layout:**
```
┌─────────────────────────────┐
│                             │
│    [App Logo/Icon]          │  ← 80x80px
│                             │
│      Al Khazna              │  ← 28px bold
│                             │
│    Enter your PIN           │  ← 18px regular
│                             │
│      ○  ○  ○  ○            │  ← PIN dots
│                             │
│   [Error message area]      │  ← Red text if wrong PIN
│                             │
│    [Numeric Keypad]         │
│    1    2    3              │
│    4    5    6              │
│    7    8    9              │
│         0                   │
│                             │
│   [Fingerprint Icon]        │  ← Only if biometric enabled
│   Touch to unlock           │
│                             │
│                             │
└─────────────────────────────┘
```

**User Flow:**
1. Screen displays immediately when app needs unlock
2. If biometric enabled: Auto-prompt on appear
3. User enters PIN or uses biometric
4. **On success**:
   - Smooth fade transition to Home
   - Reset failed attempts counter
5. **On failure**:
   - Shake animation on PIN dots
   - Show error: "Incorrect PIN. X attempts remaining"
   - Clear entered digits
   - Increment failed attempts
6. **Lockout logic**:
   - After 5 failures: 30-second cooldown
   - After 10 failures: 5-minute cooldown
   - Display countdown timer during lockout

**Special Features:**
- Haptic feedback on each key press
- Vibration on wrong PIN
- Auto-submit when 4th digit entered
- No "Forgot PIN" option (security by design)

---

### 3. Verify PIN Screen

**Trigger Conditions:**
- Changing PIN
- Disabling PIN protection
- Exporting sensitive data
- Deleting all data
- Modifying security settings

**UI:** Identical to Unlock Screen with title "Verify your PIN to continue"

**Behavior:**
- Single verification attempt context
- If wrong: Shows error, allows retry
- No lockout mechanism (different from Unlock)
- Can cancel operation

---

### 4. Change PIN Screen

**Multi-step Flow:**

**Step 1: Verify Current PIN**
```
Screen title: "Enter current PIN"
[PIN Input Widget]
```

**Step 2: Enter New PIN**
```
Screen title: "Enter new PIN"
[PIN Input Widget]
Warning: "Avoid using simple patterns"
```

**Step 3: Confirm New PIN**
```
Screen title: "Confirm new PIN"
[PIN Input Widget]
```

**Step 4: Success**
```
Success dialog with checkmark
"Your PIN has been changed successfully"
[OK button] → Navigate back
```

**Implementation Details:**
- Use PageView for smooth transitions
- Validate new PIN is different from old PIN
- Apply same weak PIN warnings as Setup
- Update encrypted PIN in secure storage
- Log security event (timestamp only, no PIN data)

---

### 5. Settings Screen Integration

**Add new section after existing Security section:**

```dart
// Security & Privacy Section
Card(
  child: Column(
    children: [
      // Existing: Biometric Authentication

      // NEW: App Lock
      ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.indigo.shade50,
          child: Icon(Icons.lock, color: Colors.indigo),
        ),
        title: Text('App Lock (PIN)'),
        subtitle: Text(
          isPinEnabled ? 'Enabled' : 'Disabled',
          style: TextStyle(
            color: isPinEnabled ? Colors.green : Colors.grey[600],
          ),
        ),
        trailing: Switch(
          value: isPinEnabled,
          onChanged: (value) {
            if (value) {
              // Navigate to Setup PIN Screen
            } else {
              // Show Verify PIN Screen → Disable
            }
          },
        ),
      ),

      Divider(height: 1),

      // NEW: Biometric Unlock (depends on PIN)
      ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.teal.shade50,
          child: Icon(Icons.fingerprint, color: Colors.teal),
        ),
        title: Text('Biometric Unlock'),
        subtitle: Text(
          !isPinEnabled
            ? 'Requires PIN to be enabled first'
            : isBiometricEnabled
              ? 'Enabled'
              : 'Disabled',
        ),
        trailing: Switch(
          value: isBiometricEnabled,
          onChanged: isPinEnabled ? (value) {
            // Enable/disable biometric
          } : null,
        ),
      ),

      Divider(height: 1),

      // NEW: Change PIN (only visible if PIN enabled)
      if (isPinEnabled)
        ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.orange.shade50,
            child: Icon(Icons.pin, color: Colors.orange),
          ),
          title: Text('Change PIN'),
          subtitle: Text('Update your security PIN'),
          trailing: Icon(Icons.chevron_right),
          onTap: () {
            // Navigate to Change PIN Screen
          },
        ),
    ],
  ),
),
```

---

## 🔐 Security Service - Technical Deep Dive

### Service Architecture

```dart
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:local_auth/local_auth.dart';

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

  // Constructor
  SecurityService({
    FlutterSecureStorage? secureStorage,
    LocalAuthentication? localAuth,
  })  : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _localAuth = localAuth ?? LocalAuthentication();

  // Initialization
  Future<void> initialize() async {
    _settingsBox = await Hive.openBox<SecuritySettings>(_settingsBoxName);
    _settings = _settingsBox.get('current') ?? SecuritySettings.initial();

    // Lock app on start if PIN is enabled
    if (_settings!.isPinEnabled) {
      _isLocked = true;
    } else {
      _isLocked = false;
    }

    notifyListeners();
  }

  // Getters
  bool get isLocked => _isLocked;
  bool get isPinEnabled => _settings?.isPinEnabled ?? false;
  bool get isBiometricEnabled => _settings?.isBiometricEnabled ?? false;
  int get failedAttempts => _settings?.failedAttempts ?? 0;
  DateTime? get lockoutUntil => _settings?.lockoutUntil;

  // Check if currently in lockout period
  bool get isLockedOut {
    if (lockoutUntil == null) return false;
    return DateTime.now().isBefore(lockoutUntil!);
  }

  // Get remaining lockout time in seconds
  int get lockoutRemainingSeconds {
    if (!isLockedOut) return 0;
    return lockoutUntil!.difference(DateTime.now()).inSeconds;
  }

  // PIN Management Methods

  /// Setup new PIN (first time)
  Future<void> setupPin(String pin) async {
    if (pin.length != 4 || !_isNumeric(pin)) {
      throw ArgumentError('PIN must be exactly 4 digits');
    }

    final hash = _hashPin(pin);
    await _secureStorage.write(key: _pinHashKey, value: hash);

    _settings!.isPinEnabled = true;
    _settings!.failedAttempts = 0;
    _settings!.lockoutUntil = null;
    await _saveSettings();

    _isLocked = false; // Unlock after setup
    notifyListeners();
  }

  /// Verify PIN against stored hash
  Future<bool> verifyPin(String pin) async {
    if (!isPinEnabled) return false;

    // Check lockout
    if (isLockedOut) {
      throw LockoutException('Too many failed attempts. Try again later.');
    }

    final storedHash = await _secureStorage.read(key: _pinHashKey);
    if (storedHash == null) return false;

    final inputHash = _hashPin(pin);
    final isCorrect = storedHash == inputHash;

    if (isCorrect) {
      await _resetFailedAttempts();
      _isLocked = false;
      _settings!.lastUnlockedAt = DateTime.now();
      await _saveSettings();
      notifyListeners();
      return true;
    } else {
      await _incrementFailedAttempts();
      notifyListeners();
      return false;
    }
  }

  /// Change PIN (requires old PIN verification)
  Future<void> changePin(String oldPin, String newPin) async {
    if (!await verifyPin(oldPin)) {
      throw UnauthorizedException('Current PIN is incorrect');
    }

    if (newPin.length != 4 || !_isNumeric(newPin)) {
      throw ArgumentError('New PIN must be exactly 4 digits');
    }

    if (oldPin == newPin) {
      throw ArgumentError('New PIN must be different from current PIN');
    }

    final hash = _hashPin(newPin);
    await _secureStorage.write(key: _pinHashKey, value: hash);

    // Don't lock after changing PIN
    notifyListeners();
  }

  /// Delete PIN and disable protection
  Future<void> deletePin() async {
    await _secureStorage.delete(key: _pinHashKey);

    _settings!.isPinEnabled = false;
    _settings!.isBiometricEnabled = false;
    _settings!.failedAttempts = 0;
    _settings!.lockoutUntil = null;
    await _saveSettings();

    _isLocked = false;
    notifyListeners();
  }

  /// Check if PIN is set
  Future<bool> isPinSet() async {
    final hash = await _secureStorage.read(key: _pinHashKey);
    return hash != null && hash.isNotEmpty;
  }

  // Biometric Management Methods

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
  }

  /// Disable biometric authentication
  Future<void> disableBiometric() async {
    _settings!.isBiometricEnabled = false;
    await _saveSettings();
    notifyListeners();
  }

  /// Authenticate using biometric
  Future<bool> authenticateWithBiometric() async {
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
        await _saveSettings();
        notifyListeners();
      }

      return authenticated;
    } catch (e) {
      debugPrint('Biometric authentication error: $e');
      return false;
    }
  }

  // Lock State Management

  /// Lock the app
  Future<void> lockApp() async {
    if (!isPinEnabled) return;

    _isLocked = true;
    notifyListeners();
  }

  /// Unlock the app (only after successful authentication)
  Future<void> unlockApp() async {
    _isLocked = false;
    notifyListeners();
  }

  // Failed Attempts Management

  Future<void> _incrementFailedAttempts() async {
    _settings!.failedAttempts++;

    // Lockout logic
    if (_settings!.failedAttempts >= 10) {
      // 10+ attempts: 5-minute lockout
      _settings!.lockoutUntil = DateTime.now().add(const Duration(minutes: 5));
    } else if (_settings!.failedAttempts >= 5) {
      // 5-9 attempts: 30-second lockout
      _settings!.lockoutUntil = DateTime.now().add(const Duration(seconds: 30));
    }

    await _saveSettings();
  }

  Future<void> _resetFailedAttempts() async {
    _settings!.failedAttempts = 0;
    _settings!.lockoutUntil = null;
    await _saveSettings();
  }

  // Helper Methods

  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  bool _isNumeric(String str) {
    return RegExp(r'^[0-9]+$').hasMatch(str);
  }

  Future<void> _saveSettings() async {
    await _settingsBox.put('current', _settings!);
  }

  // Weak PIN detection (optional warnings)
  bool isPinWeak(String pin) {
    if (pin.length != 4) return true;

    // Check for sequential (1234, 4321, etc.)
    if (_isSequential(pin)) return true;

    // Check for repeated (1111, 2222, etc.)
    if (_isRepeating(pin)) return true;

    return false;
  }

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

  bool _isRepeating(String pin) {
    return pin.split('').toSet().length == 1;
  }
}

// Custom Exceptions
class LockoutException implements Exception {
  final String message;
  LockoutException(this.message);
  @override
  String toString() => message;
}

class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException(this.message);
  @override
  String toString() => message;
}
```

---

## 📦 Data Models

### SecuritySettings Model

```dart
import 'package:hive/hive.dart';

part 'security_settings.g.dart';

@HiveType(typeId: 5) // Use typeId 5 (4 is already used for User)
class SecuritySettings extends HiveObject {
  @HiveField(0)
  bool isPinEnabled;

  @HiveField(1)
  bool isBiometricEnabled;

  @HiveField(2)
  int failedAttempts;

  @HiveField(3)
  DateTime? lockoutUntil;

  @HiveField(4)
  DateTime? lastUnlockedAt;

  SecuritySettings({
    required this.isPinEnabled,
    required this.isBiometricEnabled,
    this.failedAttempts = 0,
    this.lockoutUntil,
    this.lastUnlockedAt,
  });

  factory SecuritySettings.initial() {
    return SecuritySettings(
      isPinEnabled: false,
      isBiometricEnabled: false,
      failedAttempts: 0,
    );
  }

  SecuritySettings copyWith({
    bool? isPinEnabled,
    bool? isBiometricEnabled,
    int? failedAttempts,
    DateTime? lockoutUntil,
    DateTime? lastUnlockedAt,
  }) {
    return SecuritySettings(
      isPinEnabled: isPinEnabled ?? this.isPinEnabled,
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      lockoutUntil: lockoutUntil ?? this.lockoutUntil,
      lastUnlockedAt: lastUnlockedAt ?? this.lastUnlockedAt,
    );
  }

  @override
  String toString() {
    return 'SecuritySettings(isPinEnabled: $isPinEnabled, '
        'isBiometricEnabled: $isBiometricEnabled, '
        'failedAttempts: $failedAttempts, '
        'lockoutUntil: $lockoutUntil, '
        'lastUnlockedAt: $lastUnlockedAt)';
  }
}
```

---

## 🎨 UI Components

### PIN Input Widget

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PinInputWidget extends StatefulWidget {
  final Function(String) onPinComplete;
  final Function(String)? onPinChanged;
  final String? errorMessage;
  final bool isLoading;
  final String title;
  final String? subtitle;

  const PinInputWidget({
    Key? key,
    required this.onPinComplete,
    this.onPinChanged,
    this.errorMessage,
    this.isLoading = false,
    this.title = 'Enter PIN',
    this.subtitle,
  }) : super(key: key);

  @override
  State<PinInputWidget> createState() => _PinInputWidgetState();
}

class _PinInputWidgetState extends State<PinInputWidget>
    with SingleTickerProviderStateMixin {
  String _pin = '';
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 10)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController);
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onKeyPress(String digit) {
    if (_pin.length < 4 && !widget.isLoading) {
      HapticFeedback.selectionClick();
      setState(() {
        _pin += digit;
      });
      widget.onPinChanged?.call(_pin);

      if (_pin.length == 4) {
        widget.onPinComplete(_pin);
      }
    }
  }

  void _onDelete() {
    if (_pin.isNotEmpty && !widget.isLoading) {
      HapticFeedback.selectionClick();
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
      widget.onPinChanged?.call(_pin);
    }
  }

  void clearPin() {
    setState(() {
      _pin = '';
    });
  }

  void shake() {
    HapticFeedback.heavyImpact();
    _shakeController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Title
        Text(
          widget.title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),

        if (widget.subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            widget.subtitle!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
        ],

        const SizedBox(height: 40),

        // PIN Dots
        AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_shakeAnimation.value, 0),
              child: child,
            );
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) {
              final isFilled = index < _pin.length;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isFilled ? Colors.indigo : Colors.grey[300],
                  border: Border.all(
                    color: widget.errorMessage != null
                        ? Colors.red
                        : Colors.indigo,
                    width: 2,
                  ),
                ),
                child: isFilled
                    ? const Center(
                        child: Icon(
                          Icons.circle,
                          color: Colors.white,
                          size: 20,
                        ),
                      )
                    : null,
              );
            }),
          ),
        ),

        // Error Message
        const SizedBox(height: 16),
        SizedBox(
          height: 24,
          child: widget.errorMessage != null
              ? Text(
                  widget.errorMessage!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                )
              : null,
        ),

        const SizedBox(height: 40),

        // Numeric Keypad
        _buildKeypad(),
      ],
    );
  }

  Widget _buildKeypad() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          // Row 1: 1 2 3
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKey('1'),
              _buildKey('2'),
              _buildKey('3'),
            ],
          ),
          const SizedBox(height: 16),
          // Row 2: 4 5 6
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKey('4'),
              _buildKey('5'),
              _buildKey('6'),
            ],
          ),
          const SizedBox(height: 16),
          // Row 3: 7 8 9
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKey('7'),
              _buildKey('8'),
              _buildKey('9'),
            ],
          ),
          const SizedBox(height: 16),
          // Row 4: [empty] 0 [delete]
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(width: 70, height: 70), // Empty space
              _buildKey('0'),
              _buildDeleteKey(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKey(String digit) {
    return Material(
      color: Colors.white,
      elevation: 2,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: widget.isLoading ? null : () => _onKeyPress(digit),
        customBorder: const CircleBorder(),
        child: Container(
          width: 70,
          height: 70,
          alignment: Alignment.center,
          child: Text(
            digit,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w500,
              color: Colors.indigo,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteKey() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.isLoading ? null : _onDelete,
        customBorder: const CircleBorder(),
        child: Container(
          width: 70,
          height: 70,
          alignment: Alignment.center,
          child: Icon(
            Icons.backspace_outlined,
            size: 28,
            color: _pin.isEmpty ? Colors.grey[400] : Colors.indigo,
          ),
        ),
      ),
    );
  }
}
```

---

## 🔄 App Lifecycle Integration

### Update main.dart

```dart
// Add SecurityService to providers
class AlKhaznaApp extends StatefulWidget {
  const AlKhaznaApp({super.key});

  @override
  State<AlKhaznaApp> createState() => _AlKhaznaAppState();
}

class _AlKhaznaAppState extends State<AlKhaznaApp>
    with WidgetsBindingObserver {
  late SecurityService _securityService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _securityService = SecurityService();
    _securityService.initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // Lock app when going to background
      _securityService.lockApp();
    } else if (state == AppLifecycleState.resumed) {
      // App will check lock state and show unlock screen if needed
      setState(() {}); // Trigger rebuild to show unlock screen
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthService()..initialize()),
        ChangeNotifierProvider(create: (context) => BackupService()),
        ChangeNotifierProvider.value(value: _securityService), // NEW
      ],
      child: MaterialApp(
        title: 'Al Khazna',
        theme: AppTheme.lightTheme,
        home: const SecurityWrapper(), // NEW: Wrap with SecurityWrapper
        locale: const Locale('en', ''),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('ar', ''),
          Locale('en', ''),
        ],
      ),
    );
  }
}

// NEW: SecurityWrapper to check lock state
class SecurityWrapper extends StatelessWidget {
  const SecurityWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SecurityService>(
      builder: (context, securityService, child) {
        // If locked, show unlock screen
        if (securityService.isLocked && securityService.isPinEnabled) {
          return const UnlockScreen();
        }

        // Otherwise, show normal auth flow
        return const AuthWrapper();
      },
    );
  }
}
```

---

## ⚙️ Detailed Implementation Plan

### Phase 1: Foundation Setup (2-3 hours)

#### Step 1.1: Create SecuritySettings Model
**File:** `lib/models/security_settings.dart`

**Actions:**
1. Create the model file with Hive annotations
2. Define all fields with proper types
3. Add factory constructors and copyWith method
4. Generate adapter: `flutter pub run build_runner build`
5. Register adapter in main.dart (typeId: 5)

**Testing:**
- Verify model can be saved to Hive
- Test initial() factory constructor
- Test copyWith method

---

#### Step 1.2: Create SecurityService Core
**File:** `lib/services/security_service.dart`

**Actions:**
1. Create service class extending ChangeNotifier
2. Add dependencies injection (FlutterSecureStorage, LocalAuthentication)
3. Implement initialize() method
4. Implement PIN hashing with SHA-256
5. Add isPinSet() check method
6. Implement basic getters (isLocked, isPinEnabled, etc.)

**Testing:**
- Test service initialization
- Test PIN hashing produces consistent results
- Test isPinSet() returns correct value

---

#### Step 1.3: Implement PIN Management
**File:** `lib/services/security_service.dart` (continued)

**Actions:**
1. Implement setupPin() method
   - Validate PIN format (4 digits, numeric only)
   - Hash PIN with SHA-256
   - Store hash in secure storage
   - Update settings in Hive
   - Set isLocked = false
2. Implement verifyPin() method
   - Check lockout state first
   - Hash input PIN
   - Compare with stored hash
   - Handle success: reset failed attempts, unlock
   - Handle failure: increment failed attempts
3. Implement changePin() method
   - Verify old PIN first
   - Validate new PIN
   - Ensure new PIN != old PIN
   - Update hash in secure storage
4. Implement deletePin() method
   - Remove hash from secure storage
   - Reset all security settings
   - Set isLocked = false

**Testing:**
- Test PIN setup with valid 4-digit PIN
- Test PIN setup rejects invalid formats
- Test PIN verification with correct PIN
- Test PIN verification with wrong PIN
- Test change PIN workflow
- Test delete PIN clears all data

---

#### Step 1.4: Implement Failed Attempts Logic
**File:** `lib/services/security_service.dart` (continued)

**Actions:**
1. Add incrementFailedAttempts() method
   - Increment counter
   - Apply lockout rules:
     - 5 failures → 30-second lockout
     - 10 failures → 5-minute lockout
   - Save settings
2. Add resetFailedAttempts() method
3. Add isLockedOut getter
4. Add lockoutRemainingSeconds getter

**Testing:**
- Test 4 wrong PINs don't trigger lockout
- Test 5th wrong PIN triggers 30-second lockout
- Test 10th wrong PIN triggers 5-minute lockout
- Test successful PIN resets failed attempts
- Test lockout countdown works correctly

---

### Phase 2: UI Components (2-3 hours)

#### Step 2.1: Create PIN Input Widget
**File:** `lib/widgets/pin_input_widget.dart`

**Actions:**
1. Create stateful widget with parameters:
   - onPinComplete callback
   - onPinChanged callback (optional)
   - errorMessage (optional)
   - isLoading flag
   - title and subtitle
2. Implement UI layout:
   - Title and subtitle text
   - 4 PIN dots (circles)
   - Numeric keypad (3x4 grid)
   - Delete button
3. Implement pin state management
4. Add animations:
   - Shake animation for errors
   - Scale animation on dot fill
5. Add haptic feedback on key press
6. Add auto-submit when 4 digits entered
7. Expose clearPin() and shake() methods

**Testing:**
- Test all 10 digits work
- Test delete button works
- Test auto-submit at 4 digits
- Test animations play correctly
- Test haptic feedback works

---

#### Step 2.2: Create Setup PIN Screen
**File:** `lib/screens/security/setup_pin_screen.dart`

**Actions:**
1. Create StatefulWidget with two-step flow
2. Implement Step 1: Enter PIN
   - Use PinInputWidget
   - Title: "Create your PIN"
   - Store PIN in local variable
   - On complete: Navigate to Step 2
3. Implement Step 2: Confirm PIN
   - Use PinInputWidget
   - Title: "Confirm your PIN"
   - On complete: Compare with Step 1
   - If match: Call securityService.setupPin()
   - If mismatch: Show error, go back to Step 1
4. Add weak PIN warning (optional)
   - Check if PIN is sequential or repeating
   - Show warning banner but allow proceed
5. After success:
   - Show success dialog
   - Optional: "Enable Biometric?" dialog
   - Navigate to Home

**Testing:**
- Test two-step flow works
- Test matching PINs succeed
- Test mismatched PINs show error
- Test weak PIN warning appears
- Test navigation after success

---

#### Step 2.3: Create Unlock Screen
**File:** `lib/screens/security/unlock_screen.dart`

**Actions:**
1. Create StatefulWidget
2. Add UI elements:
   - App logo at top
   - "Enter your PIN" title
   - PinInputWidget
   - Biometric button (if enabled)
   - Error message area
   - Lockout timer (if locked out)
3. Implement PIN verification:
   - On complete: Call securityService.verifyPin()
   - On success: Pop screen or navigate to Home
   - On failure: Show error, shake animation, clear PIN
4. Implement biometric unlock:
   - Auto-prompt on screen appear (if enabled)
   - Manual button to retry
   - On success: Same as PIN success
   - On failure: Stay on screen, allow PIN entry
5. Implement lockout display:
   - Check isLockedOut on build
   - Show countdown timer
   - Disable PIN input during lockout
   - Use periodic timer to update UI
6. Add WillPopScope to prevent back navigation

**Testing:**
- Test correct PIN unlocks app
- Test wrong PIN shows error
- Test shake animation on wrong PIN
- Test biometric auto-prompt works
- Test manual biometric button works
- Test lockout after 5 failures
- Test lockout timer countdown
- Test cannot go back when locked

---

#### Step 2.4: Create Verify PIN Screen
**File:** `lib/screens/security/verify_pin_screen.dart`

**Actions:**
1. Create StatefulWidget accepting:
   - title parameter (default: "Verify your PIN")
   - Optional: reason parameter for display
2. Reuse PinInputWidget
3. Implement verification:
   - On complete: Call securityService.verifyPin()
   - On success: Pop with result = true
   - On failure: Show error, allow retry
4. Add cancel button
5. No lockout mechanism (different from Unlock)

**Testing:**
- Test correct PIN returns true
- Test wrong PIN allows retry
- Test cancel button works
- Test doesn't trigger lockout

---

#### Step 2.5: Create Change PIN Screen
**File:** `lib/screens/security/change_pin_screen.dart`

**Actions:**
1. Create StatefulWidget with PageView
2. Implement 3-page flow:
   - Page 1: "Enter current PIN"
   - Page 2: "Enter new PIN"
   - Page 3: "Confirm new PIN"
3. Page transitions:
   - Use PageView with physics disabled
   - Animate between pages
4. Logic:
   - Page 1: Verify current PIN
   - Page 2: Store new PIN (with weak PIN warning)
   - Page 3: Compare with Page 2
   - If match: Call securityService.changePin()
   - Show success dialog
   - Navigate back to Settings
5. Validation:
   - New PIN must be different from old PIN
   - Show error if same

**Testing:**
- Test 3-step flow completes
- Test current PIN verification
- Test new PIN != old PIN validation
- Test confirm PIN matching
- Test success saves new PIN
- Test can verify with new PIN afterward

---

### Phase 3: Biometric Integration (1-2 hours)

#### Step 3.1: Implement Biometric Methods in SecurityService
**File:** `lib/services/security_service.dart` (continued)

**Actions:**
1. Implement isBiometricAvailable()
   - Check canCheckBiometrics
   - Check isDeviceSupported
   - Handle exceptions
2. Implement getAvailableBiometrics()
   - Return list of BiometricType
3. Implement enableBiometric()
   - Check PIN is enabled first
   - Check biometric is available
   - Test authentication before enabling
   - Update settings if successful
4. Implement disableBiometric()
   - Simple flag update
5. Implement authenticateWithBiometric()
   - Call localAuth.authenticate()
   - Use proper options (stickyAuth, biometricOnly)
   - On success: unlock app, reset failed attempts
   - On failure: return false
   - Handle exceptions gracefully

**Testing:**
- Test isBiometricAvailable() on devices with/without biometric
- Test enableBiometric() requires PIN first
- Test enableBiometric() tests auth before enabling
- Test authenticateWithBiometric() unlocks app
- Test biometric failure doesn't crash

---

#### Step 3.2: Add Biometric to Unlock Screen
**File:** `lib/screens/security/unlock_screen.dart` (update)

**Actions:**
1. Add biometric auto-prompt in initState()
   - Only if isBiometricEnabled
   - Delay 300ms for smooth UX
   - Call securityService.authenticateWithBiometric()
2. Add biometric button below keypad
   - Show fingerprint icon
   - "Touch to unlock" text
   - Only visible if biometricEnabled
3. Handle biometric failure gracefully
   - Don't show error
   - Allow user to continue with PIN
4. Add biometric icon animation (pulse effect)

**Testing:**
- Test biometric auto-prompt on screen open
- Test manual biometric button works
- Test biometric success unlocks
- Test biometric failure allows PIN entry
- Test biometric doesn't show if not enabled

---

#### Step 3.3: Update Biometric Settings Screen
**File:** `lib/screens/biometric_settings_screen.dart` (update)

**Actions:**
1. Update toggle logic to use SecurityService
2. Add dependency on SecurityService (was using AuthService)
3. Update UI to show:
   - "Biometric unlock for app lock"
   - Note: "PIN must be enabled first"
4. Disable toggle if PIN not enabled
5. Test biometric on toggle enable

**Testing:**
- Test toggle disabled when no PIN
- Test toggle enables biometric
- Test toggle disables biometric
- Test setting persists

---

### Phase 4: App Integration (2 hours)

#### Step 4.1: Add SecurityService to Provider
**File:** `lib/main.dart` (update)

**Actions:**
1. Create SecurityService instance in AlKhaznaApp state
2. Initialize in initState()
3. Add to MultiProvider
4. Add WidgetsBindingObserver
5. Implement didChangeAppLifecycleState()
   - On paused: Call securityService.lockApp()
   - On resumed: Trigger rebuild

**Testing:**
- Test service is available in all screens
- Test app locks when minimized
- Test app shows unlock screen on return

---

#### Step 4.2: Create SecurityWrapper
**File:** `lib/main.dart` (add new widget)

**Actions:**
1. Create SecurityWrapper as consumer of SecurityService
2. Check if app is locked
3. If locked: Show UnlockScreen
4. If not locked: Show AuthWrapper (existing flow)
5. Update MaterialApp home to SecurityWrapper

**Testing:**
- Test normal app flow when no PIN
- Test unlock screen appears when locked
- Test successful unlock shows home
- Test works with existing auth flow

---

#### Step 4.3: Update Settings Screen
**File:** `lib/screens/settings_screen.dart` (update)

**Actions:**
1. Add SecurityService consumer
2. Add "Security & Privacy" section (or update existing)
3. Add three items:
   - App Lock (PIN) toggle
   - Biometric Unlock toggle (depends on PIN)
   - Change PIN option (only if PIN enabled)
4. Implement toggle logic:
   - Enable PIN: Navigate to SetupPinScreen
   - Disable PIN: Show VerifyPinScreen → call deletePin()
   - Enable Biometric: Call enableBiometric()
   - Disable Biometric: Call disableBiometric()
   - Change PIN: Navigate to ChangePinScreen
5. Update UI to show current state

**Testing:**
- Test PIN toggle navigation
- Test enable PIN workflow
- Test disable PIN requires verification
- Test biometric toggle only works with PIN
- Test change PIN navigation

---

#### Step 4.4: Add PIN Verification to Sensitive Operations
**Files:** Various screens that handle sensitive data

**Actions:**
1. Identify sensitive operations:
   - Export data
   - Delete all data
   - Backup/Restore operations
2. For each operation:
   - Before action: Check if PIN is enabled
   - If enabled: Show VerifyPinScreen
   - Wait for verification result
   - Only proceed if verified

**Example for Export:**
```dart
Future<void> _exportData() async {
  final securityService = context.read<SecurityService>();

  if (securityService.isPinEnabled) {
    final verified = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const VerifyPinScreen(
          title: 'Verify PIN to Export Data',
        ),
      ),
    );

    if (verified != true) return; // User cancelled or failed
  }

  // Proceed with export
  _performExport();
}
```

**Testing:**
- Test sensitive operations require PIN when enabled
- Test can cancel verification
- Test wrong PIN doesn't proceed
- Test correct PIN allows operation
- Test operations work normally when no PIN

---

### Phase 5: Security Hardening (1-2 hours)

#### Step 5.1: Add Security Logging
**File:** `lib/services/security_service.dart` (update)

**Actions:**
1. Add logging for security events:
   - PIN setup
   - PIN change
   - Successful unlock
   - Failed unlock attempts
   - Biometric enable/disable
2. Log only timestamps and event types (NO PIN data)
3. Store logs in Hive (optional, for user review)
4. Add method to clear logs

**Testing:**
- Test events are logged
- Test logs don't contain sensitive data
- Test logs can be cleared

---

#### Step 5.2: Implement Screenshot Protection (Optional)
**File:** Platform-specific implementation

**Android:** Update `AndroidManifest.xml`
```xml
<activity
    android:name=".MainActivity"
    android:windowSoftInputMode="adjustResize"
    android:screenOrientation="portrait">

    <!-- Add this for security screens -->
    <meta-data
        android:name="io.flutter.embedding.android.SplashScreenDrawable"
        android:resource="@drawable/launch_background" />
</activity>
```

**Flutter:** Add flag to security screens
```dart
// In unlock_screen.dart, setup_pin_screen.dart
@override
Widget build(BuildContext context) {
  // Prevent screenshots on Android
  if (Platform.isAndroid) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
  }

  return Scaffold(
    // ...
  );
}
```

**Testing:**
- Test screenshots blocked on security screens
- Test screenshots work on other screens

---

#### Step 5.3: Add Tamper Detection (Optional)
**File:** `lib/services/security_service.dart` (update)

**Actions:**
1. Add integrity check on PIN hash
2. Detect if secure storage was cleared externally
3. If tampering detected:
   - Reset all security settings
   - Force user to setup PIN again
   - Show warning dialog

**Testing:**
- Test tampering detection works
- Test reset flow after tampering

---

### Phase 6: Testing & Polish (1-2 hours)

#### Step 6.1: Comprehensive Testing
**Create test file:** `test/security_service_test.dart`

**Unit Tests:**
```dart
void main() {
  group('SecurityService', () {
    test('PIN hashing is consistent', () {
      // Test same PIN produces same hash
    });

    test('Setup PIN works', () {
      // Test setupPin() success
    });

    test('Verify correct PIN succeeds', () {
      // Test verifyPin() with correct PIN
    });

    test('Verify wrong PIN fails', () {
      // Test verifyPin() with wrong PIN
    });

    test('Failed attempts trigger lockout', () {
      // Test lockout after 5 attempts
    });

    test('Change PIN works', () {
      // Test changePin() workflow
    });

    // Add more tests...
  });
}
```

**Integration Tests:**
- Test full setup flow
- Test unlock flow
- Test biometric flow
- Test settings integration

**Manual Testing Checklist:**
- [ ] Setup PIN first time
- [ ] Confirm PIN matching works
- [ ] Unlock with correct PIN
- [ ] Unlock with wrong PIN shows error
- [ ] 5 wrong PINs trigger 30s lockout
- [ ] 10 wrong PINs trigger 5min lockout
- [ ] Biometric enables successfully
- [ ] Biometric unlocks app
- [ ] Change PIN workflow
- [ ] Disable PIN workflow
- [ ] App locks on background
- [ ] App unlocks on return
- [ ] Settings UI updates correctly

---

#### Step 6.2: Add Animations & Polish

**Actions:**
1. Add entrance animations to screens
   - Fade in for unlock screen
   - Slide up for PIN input
2. Add success animations
   - Checkmark animation on correct PIN
   - Green flash on dots
3. Add error animations
   - Shake on wrong PIN (already implemented)
   - Red flash on dots
4. Add loading states
   - Spinner during biometric auth
   - Disabled state during verification
5. Improve haptic feedback
   - Success haptic on correct PIN
   - Error haptic on wrong PIN
   - Light haptic on key press

**Testing:**
- Test all animations play smoothly
- Test haptic feedback works
- Test loading states display correctly

---

#### Step 6.3: Error Handling & Edge Cases

**Actions:**
1. Handle secure storage failures
   - Try-catch around all secure storage operations
   - Fallback: Disable PIN if storage fails
   - Show user-friendly error messages
2. Handle biometric failures
   - Device locked out
   - No biometric enrolled
   - Biometric hardware error
3. Handle Hive failures
   - Database corruption
   - Migration issues
4. Handle app reinstall scenario
   - Clear secure storage on first launch
   - Detect orphaned PIN settings
5. Handle device change scenario
   - PIN doesn't transfer to new device (secure storage is device-specific)

**Testing:**
- Test all error scenarios
- Test app doesn't crash on failures
- Test user sees helpful error messages

---

#### Step 6.4: Documentation

**Actions:**
1. Add inline code documentation
2. Create user guide in app
   - "How to use PIN lock"
   - "How to enable biometric"
   - "What if I forget my PIN?"
3. Update README with security features
4. Document security architecture

---

### Phase 7: Optimization & Deployment (1 hour)

#### Step 7.1: Performance Optimization

**Actions:**
1. Optimize PIN verification speed
   - Hash computation should be < 50ms
2. Optimize UI rendering
   - Use const constructors where possible
   - Minimize rebuilds
3. Optimize app launch time
   - Lazy load security service if not needed
4. Test on low-end devices

**Testing:**
- Measure unlock time (target: < 500ms)
- Test on Android devices (low-end)
- Test on iOS devices
- Profile for memory leaks

---

#### Step 7.2: Platform-Specific Testing

**Android:**
- Test on Android 6.0 (API 23)
- Test on Android 13+ (latest)
- Test fingerprint sensor
- Test face unlock (if available)
- Test different screen sizes

**iOS:**
- Test on iOS 12.0
- Test on iOS 17+ (latest)
- Test Touch ID (older devices)
- Test Face ID (newer devices)
- Test different iPhone models

**Testing Checklist:**
- [ ] Android fingerprint works
- [ ] Android face unlock works
- [ ] iOS Touch ID works
- [ ] iOS Face ID works
- [ ] All screen sizes supported
- [ ] Landscape mode works (optional: lock to portrait)

---

#### Step 7.3: Security Audit

**Actions:**
1. Code review for security issues
2. Verify no PIN data in logs
3. Verify secure storage implementation
4. Verify no security bypasses
5. Test with security tools:
   - Frida (test anti-tampering)
   - SSL proxies (verify no network calls)

**Checklist:**
- [ ] No PIN stored in plain text
- [ ] No PIN in logs
- [ ] Secure storage used correctly
- [ ] No security bypasses
- [ ] No hardcoded keys
- [ ] Lockout mechanism works
- [ ] No race conditions

---

#### Step 7.4: Final QA & Release

**Actions:**
1. Run all automated tests
2. Complete manual testing checklist
3. Test on production builds (not debug)
4. Verify ProGuard/R8 rules (Android)
   - Add rules for Hive
   - Add rules for local_auth
5. Test APK/IPA size impact
6. Update version number
7. Generate release notes
8. Submit for release

**Release Checklist:**
- [ ] All tests passing
- [ ] Manual testing complete
- [ ] Production build tested
- [ ] No debug code or logs
- [ ] Version number updated
- [ ] Release notes prepared
- [ ] Screenshots updated (if needed)

---

## 🔒 Security Best Practices

### 1. PIN Storage
- ✅ **Never store PIN in plain text**
- ✅ Use SHA-256 hashing (one-way function)
- ✅ Store hash in Flutter Secure Storage
- ✅ Secure Storage uses:
  - iOS: Keychain (hardware-backed)
  - Android: KeyStore (hardware-backed on modern devices)

### 2. Biometric Authentication
- ✅ Biometric data never leaves device
- ✅ Handled by OS, not by app
- ✅ Always have PIN as fallback
- ✅ Don't store any biometric data

### 3. Anti-Brute Force
- ✅ Limit failed attempts (5 → lockout)
- ✅ Exponential backoff (30s, 5min)
- ✅ No "forgot PIN" recovery (maximum security)

### 4. Data Protection
- ✅ No sensitive data in logs
- ✅ No sensitive data in analytics
- ✅ Clear sensitive data from memory
- ✅ Optional: Screenshot protection

### 5. Code Security
- ✅ No hardcoded keys
- ✅ No security bypasses in debug mode
- ✅ ProGuard/R8 obfuscation enabled
- ✅ Root/Jailbreak detection (optional)

---

## 📊 Testing Strategy

### Unit Tests
- SecurityService methods
- PIN hashing consistency
- Failed attempts logic
- Lockout calculations

### Integration Tests
- Full setup flow
- Full unlock flow
- Settings integration
- Biometric integration

### Manual Tests
- All user flows
- Error scenarios
- Edge cases
- Platform-specific features

### Performance Tests
- Unlock speed < 500ms
- Memory usage
- Battery impact
- App size impact

---

## 🐛 Troubleshooting Guide

### Common Issues

**Issue 1: Biometric not working**
- Check device has biometric enrolled
- Check permissions granted
- Check biometric is enabled in settings
- Fallback to PIN

**Issue 2: PIN not persisting**
- Check secure storage permissions
- Check device security settings
- May need device PIN/password set first

**Issue 3: App won't unlock**
- Check lockout status
- Check secure storage accessible
- Last resort: Clear app data (loses local data)

**Issue 4: App locks immediately**
- Check lifecycle state detection
- Check lock timer settings
- May be aggressive background killing by OS

---

## 📈 Success Metrics

### KPIs
1. **Adoption Rate**: >80% of users enable PIN
2. **Biometric Usage**: >60% of users with PIN use biometric
3. **Security**: Zero security breaches reported
4. **Performance**: Unlock time <500ms on 95% of devices
5. **Satisfaction**: <5% user complaints about security features

### Analytics to Track
- PIN setup completion rate
- Biometric enable rate
- Average unlock time
- Failed attempt frequency
- Lockout frequency
- Feature usage patterns

---

## ✨ Future Enhancements

### Phase 8 (Future)

1. **Auto-lock Timer**
   - Lock after X minutes of inactivity
   - User-configurable (1min, 5min, 10min, 30min)
   - Track last interaction timestamp

2. **PIN Complexity Options**
   - Allow 6-digit PIN
   - Allow alphanumeric PIN
   - Force strong PIN (no sequential, repeating)

3. **Decoy PIN**
   - Secondary PIN that opens empty/fake data
   - Emergency protection feature
   - Shows different data set

4. **Emergency Data Wipe**
   - After X failed attempts (20+)
   - Optional: Triggered by special PIN
   - Permanent data deletion

5. **Screenshot Protection**
   - Block screenshots on all screens
   - Blank screen in app switcher
   - Watermark on screenshots (if allowed)

6. **Intruder Selfie**
   - Take photo on failed attempts
   - Store in secure location
   - User can review in settings

7. **Stealth Mode**
   - Hide app icon
   - Launch via special gesture
   - Disguise as different app

8. **Multi-factor Authentication**
   - PIN + Biometric (both required)
   - PIN + Pattern
   - Time-based OTP

9. **Remote Lock/Wipe**
   - Lock device remotely
   - Wipe data remotely
   - Requires cloud backup integration

10. **Security Audit Log**
    - View all security events
    - Export security logs
    - Suspicious activity alerts

---

## 🎯 Conclusion

This comprehensive security system provides:

✅ **Strong Protection**: 4-digit PIN + Biometric authentication
✅ **User-Friendly**: Fast unlock with biometric, fallback to PIN
✅ **Zero Dependencies**: 100% local, no servers required
✅ **Platform Native**: Uses iOS Keychain and Android KeyStore
✅ **Brute-Force Resistant**: Lockout after failed attempts
✅ **Privacy Focused**: No data collection, no analytics on security
✅ **Production Ready**: Comprehensive testing and error handling

### Implementation Timeline
- **Phase 1-2**: Foundation & UI (4-5 hours)
- **Phase 3-4**: Biometric & Integration (3-4 hours)
- **Phase 5-6**: Security & Testing (2-3 hours)
- **Phase 7**: Optimization & Release (1-2 hours)

**Total: 10-14 hours of focused development**

---

**Document Version:** 2.0
**Created:** 2025-10-16
**Last Updated:** 2025-10-16
**Status:** ✅ Ready for Implementation
**Language:** English (Technical)

---

## 📞 Support & Contact

For questions or clarifications during implementation:
1. Review this PRD document
2. Check code comments and documentation
3. Test on real devices early and often
4. Follow security best practices strictly

**Security is not optional - implement every step carefully!** 🔐
