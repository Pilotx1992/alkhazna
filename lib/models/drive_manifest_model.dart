import 'dart:convert';

/// Drive Manifest Model - Following blueprint section 3 schema
/// Schema: "alkhazna.drive.e2ee.backup"
class DriveManifest {
  final String schema;
  final int version;
  final String sessionId;
  final DateTime createdAt;
  final String appVersion;
  final String platform;
  final String compression;
  final int chunkSize;
  final List<ManifestFile> files;
  final WrappedMasterKey? wmk; // Optional - only if recovery key used
  final ManifestOwner owner;
  final String status; // "in_progress" | "complete" | "failed"

  DriveManifest({
    this.schema = "alkhazna.drive.e2ee.backup",
    this.version = 1,
    required this.sessionId,
    required this.createdAt,
    required this.appVersion,
    required this.platform,
    this.compression = "gzip",
    this.chunkSize = 8388608, // 8 MiB default
    required this.files,
    this.wmk,
    required this.owner,
    this.status = "in_progress",
  });

  Map<String, dynamic> toJson() => {
    'schema': schema,
    'version': version,
    'sessionId': sessionId,
    'createdAt': createdAt.toIso8601String(),
    'appVersion': appVersion,
    'platform': platform,
    'compression': compression,
    'chunkSize': chunkSize,
    'files': files.map((f) => f.toJson()).toList(),
    if (wmk != null) 'wmk': wmk!.toJson(),
    'owner': owner.toJson(),
    'status': status,
  };

  factory DriveManifest.fromJson(Map<String, dynamic> json) => DriveManifest(
    schema: json['schema'] ?? "alkhazna.drive.e2ee.backup",
    version: json['version'] ?? 1,
    sessionId: json['sessionId'],
    createdAt: DateTime.parse(json['createdAt']),
    appVersion: json['appVersion'],
    platform: json['platform'],
    compression: json['compression'] ?? "gzip",
    chunkSize: json['chunkSize'] ?? 8388608,
    files: (json['files'] as List)
        .map((f) => ManifestFile.fromJson(f))
        .toList(),
    wmk: json['wmk'] != null ? WrappedMasterKey.fromJson(json['wmk']) : null,
    owner: ManifestOwner.fromJson(json['owner']),
    status: json['status'] ?? "in_progress",
  );

  String toJsonString() => json.encode(toJson());
  
  factory DriveManifest.fromJsonString(String jsonString) =>
      DriveManifest.fromJson(json.decode(jsonString));

  /// Create a copy with updated status
  DriveManifest copyWith({
    String? status,
    List<ManifestFile>? files,
    WrappedMasterKey? wmk,
  }) => DriveManifest(
    schema: schema,
    version: version,
    sessionId: sessionId,
    createdAt: createdAt,
    appVersion: appVersion,
    platform: platform,
    compression: compression,
    chunkSize: chunkSize,
    files: files ?? this.files,
    wmk: wmk ?? this.wmk,
    owner: owner,
    status: status ?? this.status,
  );
}

/// File entry in the manifest
class ManifestFile {
  final String id;
  final String path;
  final int originalSize;
  final List<ManifestChunk> chunks;

  ManifestFile({
    required this.id,
    required this.path,
    required this.originalSize,
    required this.chunks,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'path': path,
    'originalSize': originalSize,
    'chunks': chunks.map((c) => c.toJson()).toList(),
  };

  factory ManifestFile.fromJson(Map<String, dynamic> json) => ManifestFile(
    id: json['id'],
    path: json['path'],
    originalSize: json['originalSize'],
    chunks: (json['chunks'] as List)
        .map((c) => ManifestChunk.fromJson(c))
        .toList(),
  );

  /// Add a chunk to this file
  ManifestFile addChunk(ManifestChunk chunk) => ManifestFile(
    id: id,
    path: path,
    originalSize: originalSize,
    chunks: [...chunks, chunk],
  );
}

/// Individual chunk metadata
class ManifestChunk {
  final int seq;
  final String driveFileId;
  final String sha256;
  final int size;
  final String iv; // Base64 encoded
  final String tag; // Base64 encoded

  ManifestChunk({
    required this.seq,
    required this.driveFileId,
    required this.sha256,
    required this.size,
    required this.iv,
    required this.tag,
  });

  Map<String, dynamic> toJson() => {
    'seq': seq,
    'driveFileId': driveFileId,
    'sha256': sha256,
    'size': size,
    'iv': iv,
    'tag': tag,
  };

  factory ManifestChunk.fromJson(Map<String, dynamic> json) => ManifestChunk(
    seq: json['seq'],
    driveFileId: json['driveFileId'],
    sha256: json['sha256'],
    size: json['size'],
    iv: json['iv'],
    tag: json['tag'],
  );
}

/// Wrapped master key (optional - only when recovery key is used)
class WrappedMasterKey {
  final String iv; // Base64 encoded
  final String tag; // Base64 encoded  
  final String ct; // Base64 encoded ciphertext
  final String? salt; // Base64 encoded salt for PBKDF2
  final int? iterations; // PBKDF2 iterations

  WrappedMasterKey({
    required this.iv,
    required this.tag,
    required this.ct,
    this.salt,
    this.iterations = 210000,
  });

  Map<String, dynamic> toJson() => {
    'iv': iv,
    'tag': tag,
    'ct': ct,
    if (salt != null) 'salt': salt,
    if (iterations != null) 'iterations': iterations,
  };

  factory WrappedMasterKey.fromJson(Map<String, dynamic> json) => WrappedMasterKey(
    iv: json['iv'],
    tag: json['tag'],
    ct: json['ct'],
    salt: json['salt'],
    iterations: json['iterations'] ?? 210000,
  );
}

/// Manifest owner information  
class ManifestOwner {
  final String googleId;
  final String email;

  ManifestOwner({
    required this.googleId,
    required this.email,
  });

  Map<String, dynamic> toJson() => {
    'googleId': googleId,
    'email': email,
  };

  factory ManifestOwner.fromJson(Map<String, dynamic> json) => ManifestOwner(
    googleId: json['googleId'],
    email: json['email'],
  );
}

/// Utilities for manifest management
class ManifestUtils {
  /// Generate chunk file name following blueprint convention
  static String chunkFileName(String fileId, int seq) => "$fileId.part$seq.enc";
  
  /// Generate manifest file name
  static String manifestFileName(String sessionId) => "manifest.json";
  
  /// Validate manifest schema
  static bool validateManifest(DriveManifest manifest) {
    if (manifest.schema != "alkhazna.drive.e2ee.backup") return false;
    if (manifest.version != 1) return false;
    if (manifest.sessionId.isEmpty) return false;
    if (manifest.files.isEmpty) return false;
    
    // Validate each file has at least one chunk
    for (final file in manifest.files) {
      if (file.chunks.isEmpty) return false;
      
      // Validate chunk sequence numbers are consecutive
      for (int i = 0; i < file.chunks.length; i++) {
        if (file.chunks[i].seq != i) return false;
      }
    }
    
    return true;
  }
  
  /// Calculate total backup size from manifest
  static int calculateTotalSize(DriveManifest manifest) {
    return manifest.files.fold(0, (sum, file) => sum + file.originalSize);
  }
  
  /// Calculate total chunks count
  static int calculateTotalChunks(DriveManifest manifest) {
    return manifest.files.fold(0, (sum, file) => sum + file.chunks.length);
  }
}