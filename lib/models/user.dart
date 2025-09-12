import 'package:hive/hive.dart';

part 'user.g.dart';

@HiveType(typeId: 4)
class User extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String username;

  @HiveField(2)
  String email;

  @HiveField(3)
  String passwordHash;

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  DateTime lastLoginAt;

  @HiveField(6)
  bool biometricEnabled;

  @HiveField(7)
  String? googleAccountId;

  @HiveField(8)
  String? backupGoogleAccountEmail;

  @HiveField(9)
  String? profileImageUrl;

  @HiveField(10)
  bool isFirstTime;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.passwordHash,
    required this.createdAt,
    required this.lastLoginAt,
    this.biometricEnabled = false,
    this.googleAccountId,
    this.backupGoogleAccountEmail,
    this.profileImageUrl,
    this.isFirstTime = true,
  });

  /// Create a new user with generated ID
  factory User.create({
    required String username,
    required String email,
    required String passwordHash,
    String? googleAccountId,
    String? backupGoogleAccountEmail,
  }) {
    final now = DateTime.now();
    return User(
      id: _generateUserId(),
      username: username,
      email: email,
      passwordHash: passwordHash,
      createdAt: now,
      lastLoginAt: now,
      googleAccountId: googleAccountId,
      backupGoogleAccountEmail: backupGoogleAccountEmail,
    );
  }

  /// Generate unique user ID
  static String _generateUserId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// Update last login timestamp
  void updateLastLogin() {
    lastLoginAt = DateTime.now();
    save(); // Save to Hive
  }

  /// Enable/disable biometric authentication
  void setBiometricEnabled(bool enabled) {
    biometricEnabled = enabled;
    save();
  }

  /// Link Google account for backups
  void linkGoogleAccount(String googleId, String email) {
    googleAccountId = googleId;
    backupGoogleAccountEmail = email;
    save();
  }

  /// Check if user has linked Google account
  bool get hasLinkedGoogleAccount => googleAccountId != null && backupGoogleAccountEmail != null;

  /// Mark as not first time user
  void completeOnboarding() {
    isFirstTime = false;
    save();
  }

  /// Convert to JSON for backup serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'passwordHash': passwordHash, // Include password hash for backup
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt.toIso8601String(),
      'biometricEnabled': biometricEnabled,
      'googleAccountId': googleAccountId,
      'backupGoogleAccountEmail': backupGoogleAccountEmail,
      'profileImageUrl': profileImageUrl,
      'isFirstTime': isFirstTime,
    };
  }

  /// Create User from JSON for backup restoration
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      passwordHash: json['passwordHash'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastLoginAt: DateTime.parse(json['lastLoginAt'] as String),
      biometricEnabled: json['biometricEnabled'] as bool? ?? false,
      googleAccountId: json['googleAccountId'] as String?,
      backupGoogleAccountEmail: json['backupGoogleAccountEmail'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
      isFirstTime: json['isFirstTime'] as bool? ?? true,
    );
  }

  /// Convert to map for debugging
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt.toIso8601String(),
      'biometricEnabled': biometricEnabled,
      'googleAccountId': googleAccountId,
      'backupGoogleAccountEmail': backupGoogleAccountEmail,
      'profileImageUrl': profileImageUrl,
      'isFirstTime': isFirstTime,
    };
  }

  @override
  String toString() {
    return 'User{id: $id, username: $username, email: $email, biometric: $biometricEnabled, google: $hasLinkedGoogleAccount}';
  }
}