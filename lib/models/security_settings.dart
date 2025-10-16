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

  SecuritySettings({
    required this.isPinEnabled,
    required this.isBiometricEnabled,
    this.failedAttempts = 0,
    this.lockoutUntil,
    this.lastUnlockedAt,
    this.pinSalt,
    this.autoLockTimeout = 0, // Default: immediate lock on background
  });

  /// Factory constructor for initial settings
  factory SecuritySettings.initial() {
    return SecuritySettings(
      isPinEnabled: false,
      isBiometricEnabled: false,
      failedAttempts: 0,
      autoLockTimeout: 0, // Immediate lock by default
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
  }) {
    return SecuritySettings(
      isPinEnabled: isPinEnabled ?? this.isPinEnabled,
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      lockoutUntil: lockoutUntil ?? this.lockoutUntil,
      lastUnlockedAt: lastUnlockedAt ?? this.lastUnlockedAt,
      pinSalt: pinSalt ?? this.pinSalt,
      autoLockTimeout: autoLockTimeout ?? this.autoLockTimeout,
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
        'autoLockTimeout: $autoLockTimeout)';
  }
}
