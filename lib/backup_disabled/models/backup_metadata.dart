/// Backup metadata for WhatsApp-style backup system
class BackupMetadata {
  final String version;
  final String userEmail;
  final String normalizedEmail;
  final String googleId;
  final String deviceId;
  final DateTime createdAt;
  final String checksum;
  final int fileSizeBytes;
  final String driveFileId;

  const BackupMetadata({
    required this.version,
    required this.userEmail,
    required this.normalizedEmail,
    required this.googleId,
    required this.deviceId,
    required this.createdAt,
    required this.checksum,
    required this.fileSizeBytes,
    required this.driveFileId,
  });

  Map<String, dynamic> toJson() => {
    'version': version,
    'user_email': userEmail,
    'normalized_email': normalizedEmail,
    'google_id': googleId,
    'device_id': deviceId,
    'created_at': createdAt.toIso8601String(),
    'checksum': checksum,
    'file_size_bytes': fileSizeBytes,
    'drive_file_id': driveFileId,
  };

  factory BackupMetadata.fromJson(Map<String, dynamic> json) => BackupMetadata(
    version: json['version'],
    userEmail: json['user_email'],
    normalizedEmail: json['normalized_email'],
    googleId: json['google_id'],
    deviceId: json['device_id'],
    createdAt: DateTime.parse(json['created_at']),
    checksum: json['checksum'],
    fileSizeBytes: json['file_size_bytes'],
    driveFileId: json['drive_file_id'],
  );
}