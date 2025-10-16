# Security System Testing Guide

## Overview
This guide provides comprehensive instructions for testing the PIN + Biometric security system implemented in Al Khazna app.

## Implementation Summary

### Completed Features
✅ **SecuritySettings Model** ([lib/models/security_settings.dart](lib/models/security_settings.dart))
- Hive model with typeId: 5
- Fields: isPinEnabled, isBiometricEnabled, failedAttempts, lockoutUntil, lastUnlockedAt, pinSalt, autoLockTimeout
- Generated adapter registered in main.dart

✅ **SecurityService** ([lib/services/security_service.dart](lib/services/security_service.dart))
- Complete security logic with SHA-256 + Salt hashing
- 32-character random salt generation using Random.secure()
- PIN stored encrypted in flutter_secure_storage
- Salt stored in Hive (non-sensitive, needed for verification)
- Biometric authentication support
- Auto-lock on app background
- Lockout mechanism (5 attempts → 30s, 10 attempts → 5min)

✅ **PinInputWidget** ([lib/widgets/pin_input_widget.dart](lib/widgets/pin_input_widget.dart))
- Reusable PIN input with 4 dots
- Numeric keypad (0-9)
- Shake animation on error
- Haptic feedback on key press
- Auto-submit when 4 digits entered
- Optional biometric button

✅ **Security Screens**
- **SetupPinScreen** ([lib/screens/security/setup_pin_screen.dart](lib/screens/security/setup_pin_screen.dart:1))
  * 2-step flow: Enter PIN → Confirm PIN
  * Weak PIN warnings (sequential/repeating digits)
  * Optional biometric enable after setup

- **UnlockScreen** ([lib/screens/security/unlock_screen.dart](lib/screens/security/unlock_screen.dart:1))
  * Main unlock interface when app is locked
  * Biometric auto-prompt on screen load
  * Lockout countdown timer
  * Failed attempts tracking (5 max before lockout)
  * PopScope prevents back navigation

- **VerifyPinScreen** ([lib/screens/security/verify_pin_screen.dart](lib/screens/security/verify_pin_screen.dart:1))
  * Used for sensitive operations (disable PIN, etc.)
  * No lockout mechanism (can retry indefinitely)
  * Can cancel operation

- **ChangePinScreen** ([lib/screens/security/change_pin_screen.dart](lib/screens/security/change_pin_screen.dart:1))
  * 3-step flow: Current PIN → New PIN → Confirm
  * Validates new PIN != old PIN
  * Weak PIN warnings
  * Progress indicator with 3 dots

✅ **App Integration** ([lib/main.dart](lib/main.dart))
- SecuritySettingsAdapter registered (typeId: 5)
- AlKhaznaApp converted to StatefulWidget
- WidgetsBindingObserver for app lifecycle management
- SecurityService added to providers
- SecurityWrapper checks lock state before showing app

✅ **Settings Screen** ([lib/screens/settings_screen.dart](lib/screens/settings_screen.dart))
- Security & Privacy section with:
  * App Lock (PIN) toggle switch
  * Biometric Unlock toggle (requires PIN enabled)
  * Change PIN navigation (only shows if PIN enabled)

---

## Testing Checklist

### 1. Initial Setup Test
**Test PIN Setup Flow**

1. Launch the app
2. Navigate to Settings → Security & Privacy
3. Toggle "App Lock (PIN)" switch to ON
4. **Expected**: SetupPinScreen appears
5. Enter a 4-digit PIN (e.g., 1234)
6. **Expected**: Screen advances to confirmation step
7. Re-enter the same PIN
8. **Expected**:
   - Success dialog appears
   - Option to enable biometric (if available)
   - Navigate back to Settings
   - PIN toggle shows "Enabled" in green

**Test Weak PIN Warning**

1. Toggle PIN ON again (after disabling)
2. Enter a weak PIN: 1111 or 1234
3. **Expected**: Warning dialog appears
4. Choose "Continue Anyway" or "Choose Different"
5. Verify behavior matches choice

### 2. App Lock Test
**Test Background Lock**

1. Enable PIN (if not already)
2. Navigate to any screen (Home/Income/Outcome)
3. Minimize the app (send to background)
4. Wait 2-3 seconds
5. Bring app back to foreground
6. **Expected**: UnlockScreen appears immediately
7. Enter correct PIN
8. **Expected**: App unlocks, returns to previous screen

**Test Cold Start Lock**

1. Enable PIN
2. Completely close the app (terminate process)
3. Reopen the app
4. **Expected**: UnlockScreen appears after splash screen
5. Enter correct PIN
6. **Expected**: App proceeds to normal flow

### 3. PIN Verification Test
**Test Correct PIN**

1. On UnlockScreen, enter correct PIN
2. **Expected**:
   - Success haptic feedback
   - App unlocks smoothly
   - No error message

**Test Incorrect PIN**

1. On UnlockScreen, enter wrong PIN
2. **Expected**:
   - Shake animation
   - Error message: "Incorrect PIN. X attempts left"
   - Haptic error feedback
   - PIN input clears
   - Can try again

**Test Lockout Mechanism**

1. On UnlockScreen, enter wrong PIN 5 times
2. **Expected**:
   - Lockout message appears
   - Countdown timer shows: "Please wait 30 seconds"
   - PIN input disabled
   - Timer counts down
3. Wait for timer to reach 0
4. **Expected**:
   - Error message clears
   - PIN input enabled again
   - Can enter PIN

### 4. Biometric Authentication Test
**Test Biometric Enable**

1. Ensure PIN is enabled
2. Navigate to Settings → Security & Privacy
3. Toggle "Biometric Unlock" switch to ON
4. **Expected**:
   - Biometric prompt appears (fingerprint/Face ID)
   - After successful auth: "Biometric unlock enabled!" message
   - Toggle shows "Enabled" in green

**Test Biometric Disable**

1. Toggle "Biometric Unlock" switch to OFF
2. **Expected**:
   - Immediately disables
   - "Biometric unlock disabled" message
   - Toggle shows "Disabled"

**Test Biometric Unlock**

1. Enable biometric
2. Lock the app (send to background)
3. Return to app
4. **Expected**:
   - UnlockScreen appears
   - Biometric prompt automatically shows
5. Complete biometric authentication
6. **Expected**: App unlocks without entering PIN

**Test Biometric Fallback**

1. On UnlockScreen with biometric enabled
2. Cancel or fail biometric authentication
3. **Expected**:
   - Error message: "Biometric failed. Use PIN instead"
   - Can manually enter PIN
4. Enter correct PIN
5. **Expected**: App unlocks normally

### 5. Change PIN Test
**Test Change PIN Flow**

1. Navigate to Settings → Change PIN
2. **Expected**: ChangePinScreen appears with 3-step indicator
3. **Step 1**: Enter current PIN
4. **Expected**: Advances to step 2
5. **Step 2**: Enter new PIN (different from current)
6. **Expected**: Advances to step 3
7. **Step 3**: Confirm new PIN
8. **Expected**:
   - Success dialog: "Your PIN has been changed successfully!"
   - Navigate back to Settings

**Test Same PIN Error**

1. In Change PIN flow, step 2
2. Enter the same PIN as current
3. **Expected**:
   - Shake animation
   - Error: "New PIN must be different"
   - Can try again

**Test Confirmation Mismatch**

1. In Change PIN flow, step 3
2. Enter different PIN than step 2
3. **Expected**:
   - Shake animation
   - Error: "PINs don't match"
   - Can re-enter

### 6. Disable PIN Test
**Test PIN Disable**

1. Navigate to Settings
2. Toggle "App Lock (PIN)" switch to OFF
3. **Expected**: VerifyPinScreen appears
4. Enter correct PIN
5. **Expected**:
   - PIN deleted
   - "PIN protection disabled" message
   - Toggle shows "Disabled"
   - Biometric toggle becomes disabled (grayed out)

**Test Cancel Disable**

1. Toggle PIN switch to OFF
2. On VerifyPinScreen, tap back button
3. **Expected**:
   - Returns to Settings
   - PIN remains enabled
   - Toggle returns to ON state

### 7. Edge Cases Test
**Test Multiple Rapid Locks**

1. Enable PIN
2. Rapidly switch app to background and foreground 5 times
3. **Expected**: UnlockScreen appears each time
4. Enter correct PIN each time
5. **Expected**: App unlocks consistently

**Test PIN During Migration**

1. Install fresh app (clear data)
2. Enable PIN
3. Add some income/outcome entries
4. Lock app, unlock app
5. **Expected**: Data persists correctly
6. **Expected**: PIN works after data changes

**Test Biometric Without PIN**

1. Disable PIN completely
2. **Expected**: Biometric toggle is disabled (grayed out)
3. Try to enable biometric
4. **Expected**: Cannot enable (button disabled)
5. Subtitle shows: "Requires PIN to be enabled first"

---

## Expected Security Behavior

### PIN Storage
- **Hashed PIN**: Stored in flutter_secure_storage (encrypted by OS)
- **Salt**: Stored in Hive (non-sensitive)
- **Algorithm**: SHA-256(PIN + Salt)
- **Salt Length**: 32 characters (Random.secure())

### Lockout Policy
| Attempt | Action |
|---------|--------|
| 1-4 | Show "Incorrect PIN. X attempts left" |
| 5 | Trigger 30-second lockout |
| 6-9 | Show attempts left (after lockout ends) |
| 10 | Trigger 5-minute lockout |

### Auto-Lock Behavior
- **Trigger**: App enters `AppLifecycleState.paused`
- **Unlock Required**: App enters `AppLifecycleState.resumed`
- **No Timeout**: Locks immediately (no configurable timeout yet)

### Biometric Requirements
- **Android**: Fingerprint, Face, Iris (device dependent)
- **iOS**: Touch ID, Face ID (device dependent)
- **Fallback**: PIN entry always available
- **Dependency**: Requires PIN to be enabled first

---

## Known Limitations

1. **No Configurable Timeout**: App locks immediately on background (future enhancement)
2. **No PBKDF2**: Using SHA-256 + Salt (PBKDF2 planned for Phase 8)
3. **No PIN Recovery**: If user forgets PIN, must reinstall app (by design)
4. **Windows Biometric**: May not work on Windows (limited support)

---

## Troubleshooting

### App Won't Launch After Enabling PIN
- **Cause**: Possible Hive corruption
- **Fix**:
  1. Uninstall app
  2. Reinstall app
  3. Try again with different PIN

### Biometric Not Working
- **Check**:
  1. Device has biometric hardware
  2. Biometric is enrolled in device settings
  3. App has biometric permission (check OS settings)
- **Workaround**: Use PIN entry

### Lockout Timer Not Counting Down
- **Cause**: App needs to rebuild UI
- **Fix**:
  1. Try locking/unlocking screen
  2. Wait for timer to expire naturally
  3. If stuck, force close app and reopen

### PIN Input Not Responding
- **Cause**: App in lockout state
- **Check**: Look for lockout message at top
- **Fix**: Wait for lockout timer to expire

---

## Testing on Different Platforms

### Android
```bash
flutter run -d <android-device-id>
```
- Test with fingerprint sensor
- Test with face unlock (if available)
- Test with PIN fallback

### iOS
```bash
flutter run -d <ios-device-id>
```
- Test with Touch ID (older devices)
- Test with Face ID (newer devices)
- Test with PIN fallback

### Windows
```bash
flutter run -d windows
```
- Biometric may not work (limited support)
- Test PIN flow thoroughly
- Test app lifecycle (minimize/restore)

---

## Performance Expectations

- **PIN Verification**: < 100ms
- **Biometric Prompt**: < 500ms
- **Unlock Animation**: 200ms
- **Lockout Timer**: Updates every 1 second
- **Screen Transitions**: 300ms (PageView animations)

---

## Security Audit Checklist

- [x] PIN hashed with SHA-256 + Salt
- [x] Salt randomly generated (32 chars)
- [x] PIN stored encrypted (flutter_secure_storage)
- [x] Lockout mechanism prevents brute force
- [x] Biometric authentication uses official local_auth
- [x] No PIN transmitted over network
- [x] No PIN logged in console
- [x] Back navigation disabled on unlock screen
- [x] App locks on background
- [x] Failed attempts tracked

---

## Next Steps (Optional Enhancements)

### Phase 8: Advanced Security
1. **PBKDF2 Implementation**
   - Replace SHA-256 with PBKDF2
   - Configure 100,000+ iterations
   - Maintain backward compatibility

2. **Configurable Auto-Lock**
   - Add timeout setting (immediate, 30s, 1min, 5min)
   - Store in SecuritySettings
   - Update UI in Settings

3. **Global Animation Controller**
   - Create utilities/animations.dart
   - Centralize shake, fade, slide animations
   - Reduce code duplication

4. **Enhanced Success Feedback**
   - Add confetti animation on successful unlock
   - Add smooth fade transitions
   - Improve haptic patterns

---

## Contact

For issues or questions about the security system implementation:
- Review the PRD: [SECURITY_SYSTEM_PRD.md](SECURITY_SYSTEM_PRD.md)
- Check code comments in individual files
- Test thoroughly before production release

---

**Generated**: 2025-10-16
**Version**: 1.0.0
**Status**: Implementation Complete
