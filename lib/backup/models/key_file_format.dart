import 'dart:convert';
import 'dart:typed_data';

/// Enhanced key file format for WhatsApp-style backup system
class KeyFileFormat {
  final double version;
  final String userEmail;
  final String normalizedEmail;
  final String googleId;
  final String deviceId;
  final DateTime createdAt;
  final String checksum;
  final String keyBytes; // base64-encoded 256-bit key

  const KeyFileFormat({
    required this.version,
    required this.userEmail,
    required this.normalizedEmail,
    required this.googleId,
    required this.deviceId,
    required this.createdAt,
    required this.checksum,
    required this.keyBytes,
  });

  /// Create key file from raw key bytes
  factory KeyFileFormat.fromKey({
    required String userEmail,
    required String googleId,
    required String deviceId,
    required Uint8List masterKey,
  }) {
    final normalizedEmail = _normalizeEmail(userEmail);
    final createdAt = DateTime.now();
    final keyBytes = base64Encode(masterKey);
    final checksum = _generateChecksum(masterKey);

    return KeyFileFormat(
      version: 1.1,
      userEmail: userEmail,
      normalizedEmail: normalizedEmail,
      googleId: googleId,
      deviceId: deviceId,
      createdAt: createdAt,
      checksum: checksum,
      keyBytes: keyBytes,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() => {
    'version': version,
    'user_email': userEmail,
    'normalized_email': normalizedEmail,
    'google_id': googleId,
    'device_id': deviceId,
    'created_at': createdAt.toIso8601String(),
    'checksum': checksum,
    'key_bytes': keyBytes,
  };

  /// Create from JSON
  factory KeyFileFormat.fromJson(Map<String, dynamic> json) => KeyFileFormat(
    version: json['version']?.toDouble() ?? 1.0,
    userEmail: json['user_email'],
    normalizedEmail: json['normalized_email'],
    googleId: json['google_id'],
    deviceId: json['device_id'],
    createdAt: DateTime.parse(json['created_at']),
    checksum: json['checksum'],
    keyBytes: json['key_bytes'],
  );

  /// Get master key as bytes
  Uint8List getMasterKey() => Uint8List.fromList(base64Decode(keyBytes));

  /// Validate checksum
  bool validateChecksum() {
    try {
      final key = getMasterKey();
      final expectedChecksum = _generateChecksum(key);
      return checksum == expectedChecksum;
    } catch (e) {
      return false;
    }
  }

  /// Check if key belongs to this user
  bool belongsToUser(String email, String gId) {
    return userEmail.toLowerCase() == email.toLowerCase() && googleId == gId;
  }

  /// Generate checksum for key integrity
  static String _generateChecksum(Uint8List key) {
    // Simple checksum using first 8 bytes XOR with last 8 bytes
    if (key.length < 16) return 'invalid';
    
    int checksum = 0;
    for (int i = 0; i < 8; i++) {
      checksum ^= key[i] ^ key[key.length - 8 + i];
    }
    return 'sha256-${checksum.toRadixString(16).padLeft(8, '0')}';
  }

  /// Normalize email (remove dots, plus signs, etc.)
  static String _normalizeEmail(String email) {
    final parts = email.toLowerCase().split('@');
    if (parts.length != 2) return email.toLowerCase();
    
    String localPart = parts[0];
    
    // For Gmail, remove dots and everything after +
    if (parts[1] == 'gmail.com') {
      localPart = localPart.replaceAll('.', '');
      final plusIndex = localPart.indexOf('+');
      if (plusIndex != -1) {
        localPart = localPart.substring(0, plusIndex);
      }
    }
    
    return localPart;
  }
}