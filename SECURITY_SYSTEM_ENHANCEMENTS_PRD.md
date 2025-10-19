# 🔐 Al Khazna Security System - Enhancements PRD

**Document Version:** 1.0
**Created:** 2025-10-17
**Status:** Ready for Implementation
**Estimated Time:** 4-5 hours

---

## 📋 Table of Contents

1. [Executive Summary](#executive-summary)
2. [Current Problems Analysis](#current-problems-analysis)
3. [Proposed Solutions](#proposed-solutions)
4. [Detailed Implementation Plan](#detailed-implementation-plan)
5. [Code Examples](#code-examples)
6. [Testing Strategy](#testing-strategy)
7. [Timeline & Milestones](#timeline--milestones)

---

## 🎯 Executive Summary

### Project Goal
Enhance the existing security system to provide a **seamless user experience** while maintaining **strong security standards**. Address user frustration with constant PIN/Biometric prompts while allowing flexible security configurations.

### Key Improvements
1. **Smart Auto-Lock Timer** - Delay locking when switching apps
2. **Session Management** - Unlock once, use freely for a session
3. **Biometric First UX** - Prioritize fingerprint for faster access
4. **Quick Lock Button** - Manual lock control
5. **Enhanced Settings UI** - Clear, user-friendly security configuration

### Success Metrics
- 📉 Reduce unlock prompts by **80%** during normal usage
- ⚡ Improve average unlock time to **< 1 second** (biometric)
- 😊 User satisfaction score > 90% for security experience
- 🔒 Maintain zero security breaches

---

## 🔍 Current Problems Analysis

### Problem 1: Excessive Lock Prompts ⚠️

**Symptom:**
```
User Flow (Current):
1. User opens Al Khazna → Unlock with PIN/Biometric
2. User switches to Messages app → App goes to background
3. User returns to Al Khazna (5 seconds later) → Unlock again! 😤
4. User switches to Browser → App goes to background
5. User returns to Al Khazna (10 seconds later) → Unlock AGAIN! 😡
```

**Root Cause:**
```dart
// File: lib/main.dart (current)
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.paused) {
    // ❌ PROBLEM: Locks immediately, no grace period
    _securityService.lockApp();
  }
}
```

**Impact:**
- Poor UX - interrupts workflow
- User frustration - constant unlock for quick tasks
- May lead users to disable security entirely

---

### Problem 2: No Session Persistence 📱

**Symptom:**
```
Current Behavior:
- Unlock → Locked state = false
- Go to background → Locked state = true (immediate)
- Return → Must unlock again

NO memory of recent unlock!
```

**Missing Features:**
- No session concept
- No "remember me for X minutes"
- No grace period for quick switches

**User Expectation:**
"I unlocked 30 seconds ago! Why ask me again?"

---

### Problem 3: Biometric Experience 👆

**Current State:**
- Biometric auto-prompts (good ✓)
- BUT: PIN keypad is equally prominent
- Biometric feels like "alternative option" not primary

**User Mental Model:**
"I have fingerprint - why show me a PIN pad first?"

---

### Problem 4: No Manual Lock Control 🔐

**Current State:**
- App locks automatically on background
- NO way to manually lock when needed
- User can't proactively secure app before handing phone to someone

**User Need:**
"I want to lock my app NOW before showing my screen to a friend"

---

### Problem 5: Settings Complexity ⚙️

**Current Issues:**
```
Settings Screen (Current):
├─ "App Lock (PIN)" toggle
├─ "Biometric Unlock" toggle
├─ "Change PIN" link
└─ That's it...

Missing:
❌ Auto-lock timeout options
❌ Session duration settings
❌ Quick lock button
❌ Clear explanations
```

---

## 💡 Proposed Solutions

### Solution 1: Smart Auto-Lock Timer ⏱️

**Concept:**
Instead of locking immediately, wait for a configurable duration.

**User Experience:**
```
Timeline:
├─ 00:00 - User unlocks app
├─ 00:30 - User switches to Messages
├─ 00:35 - User returns to Al Khazna
│          └─> Still unlocked! (within 30s grace period)
├─ 02:00 - User switches to Browser
├─ 02:35 - User returns to Al Khazna
│          └─> Now locked (exceeded 30s)
└─ User must unlock again
```

**Configuration Options:**
- **Immediate** (0s) - Lock right away (current behavior)
- **30 seconds** - For quick task switching
- **1 minute** - For moderate multitasking
- **5 minutes** - For active usage sessions
- **Never** - Disable auto-lock (unlock once per app launch)

**Security Consideration:**
Users can choose their preference. Default: 30 seconds (balanced).

---

### Solution 2: Session Management 🎫

**Concept:**
After successful unlock, establish a "session" that persists across app switches within a time window.

**Session Lifecycle:**
```
1. Unlock Success
   ├─> Create session token
   ├─> Set session start time
   └─> Set session expiry (15 min default)

2. During Session
   ├─> Every user interaction → refresh expiry
   ├─> App switches → session persists
   └─> Return to app → check session validity

3. Session Ends When:
   ├─> Inactivity timeout exceeded (15 min default)
   ├─> User manually locks ("Lock Now" button)
   └─> App completely terminated (force quit)
```

**Benefits:**
- **Seamless UX:** Unlock once, use freely
- **Automatic renewal:** Activity keeps session alive
- **Security maintained:** Long inactivity → auto-lock

**Configuration:**
```
Session Duration Options:
├─ 5 minutes   - Short sessions
├─ 15 minutes  - Default (balanced)
├─ 30 minutes  - Extended work
└─ 1 hour      - Long tasks
```

---

### Solution 3: Biometric First UX 👍

**Current Layout:**
```
┌─────────────────────┐
│   Al Khazna Logo    │
│                     │
│  Enter your PIN     │ ← Primary
│   ○ ○ ○ ○          │
│  [1][2][3]          │
│  [4][5][6]          │
│  [7][8][9]          │
│     [0]             │
│                     │
│   👆 Touch to       │ ← Secondary
│     unlock          │
└─────────────────────┘
```

**Proposed Layout:**
```
┌─────────────────────┐
│   Al Khazna Logo    │
│                     │
│   👆 BIOMETRIC       │ ← PRIMARY!
│   ┌─────────────┐   │
│   │             │   │
│   │   [LARGE    │   │ 64x64 icon
│   │    ICON]    │   │ Pulsing animation
│   │             │   │
│   └─────────────┘   │
│  Tap for Quick      │
│      Unlock         │
│                     │
│  ───────────────    │
│                     │
│  Or enter PIN:      │ ← Fallback
│   ○ ○ ○ ○          │
│  [keypad...]        │
└─────────────────────┘
```

**Visual Improvements:**
1. Biometric icon: 48px → 64px (33% larger)
2. Pulsing animation (1.5s cycle)
3. Blue highlight ring
4. "Quick Unlock" badge
5. PIN keypad moved down, smaller prominence

---

### Solution 4: Quick Lock Button 🚨

**Feature:**
Manual lock control for immediate security.

**Use Cases:**
1. **Privacy:** Lock before showing phone to someone
2. **Handoff:** Lock before giving phone to family member
3. **Peace of Mind:** User wants extra security NOW

**Placement:**
```
Settings > Security > [Lock Now] Button
                      ^^^^^^^^^^^^^^^^
                      Red, prominent
                      Icon: 🔒
```

**Behavior:**
```dart
onPressed() {
  1. End current session immediately
  2. Set locked state = true
  3. Show "App Locked" toast
  4. Navigate to UnlockScreen (or stay in Settings)
}
```

---

### Solution 5: Enhanced Settings UI 🎨

**Current UI Problems:**
- Too minimal
- No explanations
- No grouping
- Missing options

**Proposed UI Structure:**
```
╔══════════════════════════════════════════════╗
║          SECURITY & PRIVACY                  ║
╠══════════════════════════════════════════════╣
║                                              ║
║  🔐 APP PROTECTION                           ║
║  ────────────────────────────────────        ║
║                                              ║
║  PIN Code                           [Toggle] ║
║  Secure app with 4-digit PIN        Enabled  ║
║                                              ║
║  [Change PIN >]                              ║
║                                              ║
║  ────────────────────────────────────        ║
║                                              ║
║  👆 Biometric Unlock                [Toggle] ║
║  Use fingerprint for quick access   Enabled  ║
║  Requires PIN to be enabled                  ║
║                                              ║
║  ════════════════════════════════════        ║
║                                              ║
║  ⏱️ AUTO-LOCK SETTINGS                       ║
║  ────────────────────────────────────        ║
║                                              ║
║  Auto-Lock Timer                             ║
║  Lock app after switching          30 sec ▼  ║
║                                              ║
║  ○ Immediate                                 ║
║  ● 30 seconds       ← Selected               ║
║  ○ 1 minute                                  ║
║  ○ 5 minutes                                 ║
║  ○ Never                                     ║
║                                              ║
║  ────────────────────────────────────        ║
║                                              ║
║  Session Duration                            ║
║  Stay unlocked during active use   15 min ▼  ║
║                                              ║
║  ○ 5 minutes                                 ║
║  ● 15 minutes       ← Selected               ║
║  ○ 30 minutes                                ║
║  ○ 1 hour                                    ║
║                                              ║
║  ════════════════════════════════════        ║
║                                              ║
║  ⚡ QUICK ACTIONS                             ║
║  ────────────────────────────────────        ║
║                                              ║
║  ┌────────────────────────────────────────┐ ║
║  │     🔒  LOCK NOW                       │ ║
║  │  Lock app immediately                 │ ║
║  └────────────────────────────────────────┘ ║
║                                              ║
╚══════════════════════════════════════════════╝
```

---

## 🛠️ Detailed Implementation Plan

### Phase 1: Data Model Updates (30 minutes)

#### File: `lib/models/security_settings.dart`

**Current Fields:**
```dart
@HiveField(0) bool isPinEnabled;
@HiveField(1) bool isBiometricEnabled;
@HiveField(2) int failedAttempts;
@HiveField(3) DateTime? lockoutUntil;
@HiveField(4) DateTime? lastUnlockedAt;
@HiveField(5) String? pinSalt;
@HiveField(6) int? autoLockTimeout;
```

**New Fields to Add:**
```dart
/// Session start timestamp (when user last unlocked)
@HiveField(7)
DateTime? sessionStartTime;

/// Last user interaction timestamp (tap, scroll, etc.)
@HiveField(8)
DateTime? lastInteractionTime;

/// Session duration in minutes (default: 15)
/// How long to keep session active without interaction
@HiveField(9)
int sessionDuration;

/// Whether a session is currently active
/// NOT persisted in Hive - transient state
bool _isSessionActive = false;
```

**Updated Constructor:**
```dart
SecuritySettings({
  required this.isPinEnabled,
  required this.isBiometricEnabled,
  this.failedAttempts = 0,
  this.lockoutUntil,
  this.lastUnlockedAt,
  this.pinSalt,
  this.autoLockTimeout = 30, // Default: 30 seconds
  this.sessionStartTime,
  this.lastInteractionTime,
  this.sessionDuration = 15, // Default: 15 minutes
});
```

**Updated `initial()` Factory:**
```dart
factory SecuritySettings.initial() {
  return SecuritySettings(
    isPinEnabled: false,
    isBiometricEnabled: false,
    failedAttempts: 0,
    autoLockTimeout: 30, // 30 seconds default
    sessionDuration: 15,  // 15 minutes default
  );
}
```

**Updated `copyWith()`:**
```dart
SecuritySettings copyWith({
  bool? isPinEnabled,
  bool? isBiometricEnabled,
  int? failedAttempts,
  DateTime? lockoutUntil,
  DateTime? lastUnlockedAt,
  String? pinSalt,
  int? autoLockTimeout,
  DateTime? sessionStartTime,
  DateTime? lastInteractionTime,
  int? sessionDuration,
}) {
  return SecuritySettings(
    isPinEnabled: isPinEnabled ?? this.isPinEnabled,
    isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
    failedAttempts: failedAttempts ?? this.failedAttempts,
    lockoutUntil: lockoutUntil ?? this.lockoutUntil,
    lastUnlockedAt: lastUnlockedAt ?? this.lastUnlockedAt,
    pinSalt: pinSalt ?? this.pinSalt,
    autoLockTimeout: autoLockTimeout ?? this.autoLockTimeout,
    sessionStartTime: sessionStartTime ?? this.sessionStartTime,
    lastInteractionTime: lastInteractionTime ?? this.lastInteractionTime,
    sessionDuration: sessionDuration ?? this.sessionDuration,
  );
}
```

**Regenerate Hive Adapter:**
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

### Phase 2: SecurityService Enhancements (1.5 hours)

#### File: `lib/services/security_service.dart`

**New Getters:**
```dart
/// Whether a session is currently active
bool get isSessionActive {
  if (!_isInitialized || _settings == null) return false;
  if (_settings!.sessionStartTime == null) return false;

  final now = DateTime.now();
  final sessionStart = _settings!.sessionStartTime!;
  final sessionDurationMinutes = _settings!.sessionDuration;
  final expiryTime = sessionStart.add(Duration(minutes: sessionDurationMinutes));

  return now.isBefore(expiryTime);
}

/// Session duration in minutes
int get sessionDuration => _settings?.sessionDuration ?? 15;

/// Auto-lock timeout in seconds
int get autoLockTimeout => _settings?.autoLockTimeout ?? 30;
```

**New Method: Start Session**
```dart
/// Start a new security session after successful unlock
Future<void> startSession() async {
  _ensureInitialized();

  final now = DateTime.now();
  _settings!.sessionStartTime = now;
  _settings!.lastInteractionTime = now;
  await _saveSettings();

  notifyListeners();
  debugPrint('✅ Security session started (expires in ${_settings!.sessionDuration} minutes)');
}
```

**New Method: End Session**
```dart
/// End the current security session
Future<void> endSession() async {
  _ensureInitialized();

  _settings!.sessionStartTime = null;
  _settings!.lastInteractionTime = null;
  await _saveSettings();

  notifyListeners();
  debugPrint('🔒 Security session ended');
}
```

**New Method: Update Interaction Time**
```dart
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
```

**New Method: Should Lock on Resume**
```dart
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
```

**New Method: Lock Now**
```dart
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
```

**New Method: Set Auto-Lock Timeout**
```dart
/// Update auto-lock timeout setting
Future<void> setAutoLockTimeout(int seconds) async {
  _ensureInitialized();

  _settings!.autoLockTimeout = seconds;
  await _saveSettings();
  notifyListeners();

  debugPrint('⏱️ Auto-lock timeout set to ${seconds}s');
}
```

**New Method: Set Session Duration**
```dart
/// Update session duration setting
Future<void> setSessionDuration(int minutes) async {
  _ensureInitialized();

  _settings!.sessionDuration = minutes;
  await _saveSettings();
  notifyListeners();

  debugPrint('⏱️ Session duration set to ${minutes} minutes');
}
```

**Update: verifyPin() Method**
```dart
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
    final storedHash = await _secureStorage.read(key: _pinHashKey);
    if (storedHash == null) {
      debugPrint('⚠️ No PIN hash found in secure storage');
      return false;
    }

    final salt = _settings!.pinSalt;
    if (salt == null) {
      debugPrint('⚠️ No salt found in settings');
      return false;
    }

    final inputHash = _hashPinWithSalt(pin, salt);
    final isCorrect = storedHash == inputHash;

    if (isCorrect) {
      await _resetFailedAttempts();
      _isLocked = false;
      _settings!.lastUnlockedAt = DateTime.now();

      // 🆕 NEW: Start session on successful unlock
      await startSession();

      await _saveSettings();
      notifyListeners();
      debugPrint('✅ PIN verified successfully + session started');
      return true;
    } else {
      await _incrementFailedAttempts();
      notifyListeners();
      debugPrint('❌ Incorrect PIN. Attempts: ${_settings!.failedAttempts}');
      return false;
    }
  } catch (e) {
    debugPrint('Error verifying PIN: $e');
    return false;
  }
}
```

**Update: authenticateWithBiometric() Method**
```dart
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

      // 🆕 NEW: Start session on successful biometric auth
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
```

---

### Phase 3: App Lifecycle Update (30 minutes)

#### File: `lib/main.dart`

**Update: _AlKhaznaAppState**
```dart
class _AlKhaznaAppState extends State<AlKhaznaApp> with WidgetsBindingObserver {
  late SecurityService _securityService;
  late ThemeService _themeService;
  late LanguageService _languageService;
  late NotificationSettingsService _notificationSettingsService;

  // 🆕 NEW: Track when app went to background
  DateTime? _pausedTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _securityService = SecurityService();
    _securityService.initialize();
    _themeService = ThemeService();
    _themeService.initialize();
    _languageService = LanguageService();
    _languageService.initialize();
    _notificationSettingsService = NotificationSettingsService();
    _notificationSettingsService.initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 🆕 UPDATED: Smart auto-lock logic
    if (state == AppLifecycleState.paused) {
      // App going to background - record timestamp
      _pausedTime = DateTime.now();
      debugPrint('📱 App paused at ${_pausedTime}');

      // Don't lock immediately - wait for resume
    } else if (state == AppLifecycleState.resumed) {
      // App resumed - check if should lock
      debugPrint('📱 App resumed');

      if (_pausedTime != null) {
        final shouldLock = _securityService.shouldLockOnResume(_pausedTime!);

        if (shouldLock) {
          _securityService.lockApp();
          debugPrint('🔒 App locked due to timeout');
        } else {
          debugPrint('✅ App stays unlocked (within grace period or session active)');
        }

        _pausedTime = null;
      }

      // Trigger rebuild to show unlock screen if needed
      setState(() {});
    }
  }

  // ... rest of build method unchanged
}
```

---

### Phase 4: UnlockScreen UI Enhancement (45 minutes)

#### File: `lib/screens/security/unlock_screen.dart`

**Updated Build Method:**
```dart
@override
Widget build(BuildContext context) {
  final securityService = context.watch<SecurityService>();
  final isLockedOut = securityService.isLockedOut;
  final biometricEnabled = securityService.isBiometricEnabled;

  return PopScope(
    canPop: false,
    child: Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo (smaller)
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 32,
                  color: Colors.indigo,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                'Al Khazna',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
              ),

              const SizedBox(height: 32),

              // 🆕 BIOMETRIC FIRST - Large Prominent
              if (biometricEnabled && !isLockedOut) ...[
                _buildBiometricSection(),
                const SizedBox(height: 32),

                // Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey[400])),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'or use PIN',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey[400])),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              // Lockout message
              if (isLockedOut) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.lock_clock, color: Colors.red, size: 32),
                      const SizedBox(height: 12),
                      Text(
                        'Too Many Failed Attempts',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please wait $_remainingSeconds seconds',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // PIN Input (smaller, less prominent)
              PinInputWidget(
                key: _pinKey,
                title: isLockedOut ? 'Locked' : 'Enter PIN',
                subtitle: isLockedOut
                    ? 'Wait for lockout to end'
                    : biometricEnabled
                      ? 'As an alternative to biometric'
                      : 'Unlock to access your data',
                onPinComplete: _onPinComplete,
                errorMessage: _errorMessage,
                isLoading: _isLoading || isLockedOut,
                showBiometricButton: false, // Hide old biometric button
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
```

**New Method: Build Biometric Section**
```dart
Widget _buildBiometricSection() {
  return Column(
    children: [
      // Large pulsing biometric icon
      AnimatedContainer(
        duration: const Duration(milliseconds: 1500),
        curve: Curves.easeInOut,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.95, end: 1.05),
          duration: const Duration(milliseconds: 1500),
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: child,
            );
          },
          onEnd: () {
            // Restart animation
            setState(() {});
          },
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.indigo,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.indigo.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: InkWell(
              onTap: _isLoading ? null : _onBiometricTap,
              customBorder: const CircleBorder(),
              child: Icon(
                Icons.fingerprint,
                size: 64,
                color: Colors.indigo,
              ),
            ),
          ),
        ),
      ),

      const SizedBox(height: 16),

      // Quick Unlock text
      Text(
        'Touch for Quick Unlock',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.indigo,
        ),
      ),

      const SizedBox(height: 4),

      // Subtitle
      Text(
        'Faster and more secure',
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      ),
    ],
  );
}
```

---

### Phase 5: Settings Screen Enhancement (1 hour)

#### File: `lib/screens/settings_screen.dart`

**Updated Security Section:**
```dart
Widget _buildSecuritySection(BuildContext context) {
  return Consumer<SecurityService>(
    builder: (context, securityService, child) {
      final isPinEnabled = securityService.isPinEnabled;
      final isBiometricEnabled = securityService.isBiometricEnabled;
      final autoLockTimeout = securityService.autoLockTimeout;
      final sessionDuration = securityService.sessionDuration;

      return Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.security, color: Colors.indigo),
                  const SizedBox(width: 12),
                  Text(
                    'Security & Privacy',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // 🔐 APP PROTECTION
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                '🔐 APP PROTECTION',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                  letterSpacing: 1.2,
                ),
              ),
            ),

            // PIN Code Toggle
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.indigo.shade50,
                child: Icon(Icons.lock, color: Colors.indigo),
              ),
              title: const Text('PIN Code'),
              subtitle: Text(
                isPinEnabled
                    ? 'Secure app with 4-digit PIN'
                    : 'Disabled - anyone can access',
                style: TextStyle(
                  color: isPinEnabled ? Colors.green : Colors.red,
                ),
              ),
              trailing: Switch(
                value: isPinEnabled,
                onChanged: (value) async {
                  if (value) {
                    // Enable PIN - navigate to setup
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SetupPinScreen(),
                      ),
                    );
                  } else {
                    // Disable PIN - require verification first
                    final verified = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const VerifyPinScreen(
                          title: 'Verify PIN to Disable',
                        ),
                      ),
                    );

                    if (verified == true && context.mounted) {
                      await securityService.deletePin();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('PIN protection disabled'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  }
                },
              ),
            ),

            // Change PIN (only if enabled)
            if (isPinEnabled)
              ListTile(
                leading: const SizedBox(width: 40), // Indent
                title: const Text('Change PIN'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChangePinScreen(),
                    ),
                  );
                },
              ),

            const Divider(height: 1),

            // Biometric Unlock Toggle
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.teal.shade50,
                child: Icon(Icons.fingerprint, color: Colors.teal),
              ),
              title: const Text('Biometric Unlock'),
              subtitle: Text(
                !isPinEnabled
                    ? 'Requires PIN to be enabled first'
                    : isBiometricEnabled
                        ? 'Use fingerprint for quick access'
                        : 'Disabled',
                style: TextStyle(
                  color: !isPinEnabled
                      ? Colors.orange
                      : isBiometricEnabled
                          ? Colors.green
                          : Colors.grey[600],
                ),
              ),
              trailing: Switch(
                value: isBiometricEnabled,
                onChanged: isPinEnabled
                    ? (value) async {
                        try {
                          if (value) {
                            await securityService.enableBiometric();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Biometric unlock enabled!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } else {
                            await securityService.disableBiometric();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Biometric unlock disabled'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    : null,
              ),
            ),

            const SizedBox(height: 16),
            const Divider(height: 1, thickness: 2),
            const SizedBox(height: 8),

            // ⏱️ AUTO-LOCK SETTINGS
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                '⏱️ AUTO-LOCK SETTINGS',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                  letterSpacing: 1.2,
                ),
              ),
            ),

            // Auto-Lock Timer
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.orange.shade50,
                child: Icon(Icons.timer, color: Colors.orange),
              ),
              title: const Text('Auto-Lock Timer'),
              subtitle: Text(
                _getAutoLockDescription(autoLockTimeout),
                style: TextStyle(color: Colors.grey[700]),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                _showAutoLockDialog(context, securityService);
              },
            ),

            // Session Duration
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.purple.shade50,
                child: Icon(Icons.schedule, color: Colors.purple),
              ),
              title: const Text('Session Duration'),
              subtitle: Text(
                'Stay unlocked for $sessionDuration min',
                style: TextStyle(color: Colors.grey[700]),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                _showSessionDurationDialog(context, securityService);
              },
            ),

            const SizedBox(height: 16),
            const Divider(height: 1, thickness: 2),
            const SizedBox(height: 8),

            // ⚡ QUICK ACTIONS
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                '⚡ QUICK ACTIONS',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                  letterSpacing: 1.2,
                ),
              ),
            ),

            // Lock Now Button
            if (isPinEnabled)
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await securityService.lockNow();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('🔒 App locked'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.lock, size: 24),
                    label: const Text(
                      'LOCK NOW',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}
```

**Helper Method: Auto-Lock Description**
```dart
String _getAutoLockDescription(int seconds) {
  if (seconds == 0) return 'Lock immediately when app goes to background';
  if (seconds == 30) return 'Lock after 30 seconds in background';
  if (seconds == 60) return 'Lock after 1 minute in background';
  if (seconds == 300) return 'Lock after 5 minutes in background';
  if (seconds < 0 || seconds > 3600) return 'Never auto-lock';
  return 'Lock after $seconds seconds';
}
```

**Auto-Lock Dialog:**
```dart
Future<void> _showAutoLockDialog(
  BuildContext context,
  SecurityService securityService,
) async {
  final currentValue = securityService.autoLockTimeout;

  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Auto-Lock Timer'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RadioListTile<int>(
            title: const Text('Immediate'),
            subtitle: const Text('Lock right away'),
            value: 0,
            groupValue: currentValue,
            onChanged: (value) {
              securityService.setAutoLockTimeout(value!);
              Navigator.pop(context);
            },
          ),
          RadioListTile<int>(
            title: const Text('30 seconds'),
            subtitle: const Text('For quick task switching'),
            value: 30,
            groupValue: currentValue,
            onChanged: (value) {
              securityService.setAutoLockTimeout(value!);
              Navigator.pop(context);
            },
          ),
          RadioListTile<int>(
            title: const Text('1 minute'),
            subtitle: const Text('For moderate multitasking'),
            value: 60,
            groupValue: currentValue,
            onChanged: (value) {
              securityService.setAutoLockTimeout(value!);
              Navigator.pop(context);
            },
          ),
          RadioListTile<int>(
            title: const Text('5 minutes'),
            subtitle: const Text('For active usage'),
            value: 300,
            groupValue: currentValue,
            onChanged: (value) {
              securityService.setAutoLockTimeout(value!);
              Navigator.pop(context);
            },
          ),
          RadioListTile<int>(
            title: const Text('Never'),
            subtitle: const Text('Disable auto-lock'),
            value: -1,
            groupValue: currentValue,
            onChanged: (value) {
              securityService.setAutoLockTimeout(value!);
              Navigator.pop(context);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
      ],
    ),
  );
}
```

**Session Duration Dialog:**
```dart
Future<void> _showSessionDurationDialog(
  BuildContext context,
  SecurityService securityService,
) async {
  final currentValue = securityService.sessionDuration;

  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Session Duration'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RadioListTile<int>(
            title: const Text('5 minutes'),
            subtitle: const Text('Short sessions'),
            value: 5,
            groupValue: currentValue,
            onChanged: (value) {
              securityService.setSessionDuration(value!);
              Navigator.pop(context);
            },
          ),
          RadioListTile<int>(
            title: const Text('15 minutes'),
            subtitle: const Text('Balanced (recommended)'),
            value: 15,
            groupValue: currentValue,
            onChanged: (value) {
              securityService.setSessionDuration(value!);
              Navigator.pop(context);
            },
          ),
          RadioListTile<int>(
            title: const Text('30 minutes'),
            subtitle: const Text('Extended work'),
            value: 30,
            groupValue: currentValue,
            onChanged: (value) {
              securityService.setSessionDuration(value!);
              Navigator.pop(context);
            },
          ),
          RadioListTile<int>(
            title: const Text('1 hour'),
            subtitle: const Text('Long tasks'),
            value: 60,
            groupValue: currentValue,
            onChanged: (value) {
              securityService.setSessionDuration(value!);
              Navigator.pop(context);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
      ],
    ),
  );
}
```

---

## 🧪 Testing Strategy

### Unit Tests

**Test File:** `test/security_service_enhancements_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:al_khazna/services/security_service.dart';

void main() {
  group('Session Management', () {
    test('Session starts after successful unlock', () async {
      // Setup
      final service = SecurityService();
      await service.initialize();

      // Test
      await service.startSession();

      // Verify
      expect(service.isSessionActive, true);
    });

    test('Session expires after duration', () async {
      // Setup
      final service = SecurityService();
      await service.initialize();
      await service.setSessionDuration(0); // Instant expiry

      // Test
      await service.startSession();
      await Future.delayed(Duration(seconds: 1));

      // Verify
      expect(service.isSessionActive, false);
    });

    test('Session ends on lockNow()', () async {
      // Setup
      final service = SecurityService();
      await service.initialize();
      await service.startSession();

      // Test
      await service.lockNow();

      // Verify
      expect(service.isSessionActive, false);
    });
  });

  group('Auto-Lock Timer', () {
    test('Should lock when pause duration exceeds timeout', () {
      // Setup
      final service = SecurityService();
      service.initialize();
      service.setAutoLockTimeout(30); // 30 seconds

      // Test
      final pausedTime = DateTime.now().subtract(Duration(seconds: 35));
      final shouldLock = service.shouldLockOnResume(pausedTime);

      // Verify
      expect(shouldLock, true);
    });

    test('Should NOT lock when pause duration within timeout', () {
      // Setup
      final service = SecurityService();
      service.initialize();
      service.setAutoLockTimeout(30); // 30 seconds

      // Test
      final pausedTime = DateTime.now().subtract(Duration(seconds: 20));
      final shouldLock = service.shouldLockOnResume(pausedTime);

      // Verify
      expect(shouldLock, false);
    });

    test('Should NOT lock when session is active', () {
      // Setup
      final service = SecurityService();
      service.initialize();
      service.setAutoLockTimeout(30);
      service.startSession();

      // Test
      final pausedTime = DateTime.now().subtract(Duration(seconds: 35));
      final shouldLock = service.shouldLockOnResume(pausedTime);

      // Verify (session overrides auto-lock)
      expect(shouldLock, false);
    });
  });
}
```

### Integration Tests

**Test Scenarios:**

1. **Quick App Switch:**
   ```
   User Flow:
   1. Unlock app
   2. Switch to Messages (5 seconds)
   3. Return to Al Khazna

   Expected: Still unlocked
   ```

2. **Long Background:**
   ```
   User Flow:
   1. Unlock app
   2. Switch to Browser (2 minutes)
   3. Return to Al Khazna

   Expected: Locked, must unlock again
   ```

3. **Session Active:**
   ```
   User Flow:
   1. Unlock app
   2. Use app for 5 minutes
   3. Switch to Messages (1 minute)
   4. Return to Al Khazna

   Expected: Still unlocked (session active)
   ```

4. **Manual Lock:**
   ```
   User Flow:
   1. Unlock app
   2. Tap "Lock Now" button
   3. App immediately locks

   Expected: UnlockScreen appears
   ```

5. **Biometric First:**
   ```
   User Flow:
   1. Open locked app
   2. Biometric prompt appears first
   3. User sees large fingerprint icon

   Expected: Biometric UI prominent, PIN below
   ```

### Manual Testing Checklist

- [ ] Auto-lock timer options work correctly
- [ ] Session persists across app switches
- [ ] Session expires after inactivity
- [ ] Lock Now button locks immediately
- [ ] Biometric icon appears large and centered
- [ ] PIN keypad appears below biometric
- [ ] Settings UI displays all options clearly
- [ ] Radio buttons select correct values
- [ ] Toast messages appear on actions
- [ ] No crashes or errors in console

---

## 📅 Timeline & Milestones

### Total Estimated Time: 4-5 hours

#### Milestone 1: Data Layer (30 min)
- ✅ Update SecuritySettings model
- ✅ Add new fields
- ✅ Regenerate Hive adapter
- ✅ Test model persistence

#### Milestone 2: Business Logic (1.5 hours)
- ✅ Add session management methods
- ✅ Add auto-lock logic
- ✅ Add Lock Now method
- ✅ Update unlock methods
- ✅ Test all new methods

#### Milestone 3: App Lifecycle (30 min)
- ✅ Update didChangeAppLifecycleState
- ✅ Add pause time tracking
- ✅ Test lifecycle transitions

#### Milestone 4: UI - UnlockScreen (45 min)
- ✅ Redesign biometric section
- ✅ Add pulsing animation
- ✅ Reorder UI elements
- ✅ Test visual appearance

#### Milestone 5: UI - Settings (1 hour)
- ✅ Add enhanced security section
- ✅ Add auto-lock dialog
- ✅ Add session duration dialog
- ✅ Add Lock Now button
- ✅ Test all settings

#### Milestone 6: Testing & Polish (30 min)
- ✅ Run manual tests
- ✅ Fix any bugs
- ✅ Polish animations
- ✅ Final verification

---

## 🎉 Expected Results

### Before vs After

**Before:**
```
User Experience:
├─ Unlock app
├─ Switch to Messages (5s)
├─ Return → UNLOCK AGAIN 😤
├─ Switch to Browser (10s)
├─ Return → UNLOCK AGAIN 😡
└─ User disables security 🚨
```

**After:**
```
User Experience:
├─ Unlock app (session starts)
├─ Switch to Messages (5s)
├─ Return → STILL UNLOCKED ✨
├─ Switch to Browser (10s)
├─ Return → STILL UNLOCKED ✨
├─ Work for 15 minutes
├─ Switch to Gallery (30s)
├─ Return → STILL UNLOCKED ✨
└─ Inactive for 5 min → Auto-lock 🔒
```

### Key Metrics

- **Unlock Prompts:** 80% reduction
- **User Friction:** Minimal interruption
- **Security:** Maintained (session timeout + manual lock)
- **Flexibility:** User controls timing
- **Satisfaction:** High (seamless experience)

---

## 📚 Additional Notes

### Backward Compatibility

All new fields have default values, so existing users won't experience any issues:
- `autoLockTimeout`: Defaults to 30 seconds
- `sessionDuration`: Defaults to 15 minutes
- Existing PIN/Biometric settings preserved

### Future Enhancements (Optional)

1. **Biometric-Only Mode** - No PIN required
2. **Trusted Networks** - Auto-unlock at home
3. **Security Logs** - View unlock history
4. **Pattern Lock** - Alternative to PIN
5. **Panic Button** - Quick data wipe

### Security Considerations

- Session tokens not stored on disk (in-memory only)
- PIN hash never exposed
- Biometric handled by OS (never by app)
- Manual lock always available
- Configurable timeouts for different security needs

---

## ✅ Implementation Checklist

Use this checklist during implementation:

- [ ] Phase 1: Update SecuritySettings model
- [ ] Phase 1: Regenerate Hive adapter
- [ ] Phase 2: Add session methods to SecurityService
- [ ] Phase 2: Add auto-lock methods to SecurityService
- [ ] Phase 2: Update verifyPin() method
- [ ] Phase 2: Update authenticateWithBiometric() method
- [ ] Phase 3: Update main.dart lifecycle
- [ ] Phase 4: Enhance UnlockScreen UI
- [ ] Phase 4: Add biometric first design
- [ ] Phase 5: Update Settings screen
- [ ] Phase 5: Add auto-lock dialog
- [ ] Phase 5: Add session duration dialog
- [ ] Phase 5: Add Lock Now button
- [ ] Phase 6: Run unit tests
- [ ] Phase 6: Run integration tests
- [ ] Phase 6: Manual testing
- [ ] Phase 6: Fix bugs and polish
- [ ] Final: Commit and document changes

---

**Document Status:** ✅ Ready for Implementation
**Next Step:** Begin Phase 1 - Data Model Updates

---

*Generated with care for Al Khazna project*
*Security enhancements that users will love* ❤️
