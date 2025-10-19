import 'package:hive/hive.dart';

part 'security_settings.g.dart';

/// Security configuration model for PIN and biometric authentication
/// Stores non-sensitive settings in Hive local database
@HiveType(typeId: 5) // typeId 5 (0-4 already used)
class SecuritySettings extends HiveObject {
  /// Whether PIN protection is enabled
  @HiveField(0)
  bool isPinEnabled;

  /// Whether biometric unlock is enabled (requires PIN to be enabled)
  @HiveField(1)
  bool isBiometricEnabled;

  /// Number of consecutive failed PIN attempts
  @HiveField(2)
  int failedAttempts;

  /// Timestamp when lockout period ends (null if not locked out)
  @HiveField(3)
  DateTime? lockoutUntil;

  /// Timestamp of last successful unlock
  @HiveField(4)
  DateTime? lastUnlockedAt;

  /// Salt for PIN hashing (stored in Hive, not secure storage)
  /// Used with SHA-256 to create unique hash even for common PINs
  @HiveField(5)
  String? pinSalt;

  /// Auto-lock timeout in seconds (0 = immediate, null = disabled)
  @HiveField(6)
  int? autoLockTimeout;

  /// Session start timestamp (when user last unlocked)
  @HiveField(7)
  DateTime? sessionStartTime;

  /// Last user interaction timestamp (tap, scroll, etc.)
  @HiveField(8)
  DateTime? lastInteractionTime;

  /// Session duration in minutes (default: 15)
  /// How long to keep session active without interaction
  @HiveField(9)
  int? sessionDuration;

  SecuritySettings({
    required this.isPinEnabled,
    required this.isBiometricEnabled,
    this.failedAttempts = 0,
    this.lockoutUntil,
    this.lastUnlockedAt,
    this.pinSalt,
    this.autoLockTimeout, // Nullable for backward compatibility
    this.sessionStartTime,
    this.lastInteractionTime,
    this.sessionDuration, // Nullable for backward compatibility
  });

  /// Factory constructor for initial settings
  factory SecuritySettings.initial() {
    return SecuritySettings(
      isPinEnabled: false,
      isBiometricEnabled: false,
      failedAttempts: 0,
      autoLockTimeout: 30, // 30 seconds default
      sessionDuration: 15, // 15 minutes default
    );
  }

  /// Create a copy with updated fields
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
      lockoutUntil: lockoutUntil,
      lastUnlockedAt: lastUnlockedAt,
      pinSalt: pinSalt,
      autoLockTimeout: autoLockTimeout ?? this.autoLockTimeout,
      sessionStartTime: sessionStartTime,
      lastInteractionTime: lastInteractionTime,
      sessionDuration: sessionDuration ?? this.sessionDuration,
    );
  }

  @override
  String toString() {
    return 'SecuritySettings('
        'isPinEnabled: $isPinEnabled, '
        'isBiometricEnabled: $isBiometricEnabled, '
        'failedAttempts: $failedAttempts, '
        'lockoutUntil: $lockoutUntil, '
        'lastUnlockedAt: $lastUnlockedAt, '
        'hasSalt: ${pinSalt != null}, '
        'autoLockTimeout: $autoLockTimeout, '
        'sessionStartTime: $sessionStartTime, '
        'lastInteractionTime: $lastInteractionTime, '
        'sessionDuration: $sessionDuration)';
  }
}
