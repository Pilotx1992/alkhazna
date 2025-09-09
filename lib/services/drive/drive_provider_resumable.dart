import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';

/// DriveProviderResumable - Implements resumable Google Drive operations
/// Following blueprint section 7 and 16 specifications
class DriveProviderResumable {
  static final DriveProviderResumable _instance = DriveProviderResumable._internal();
  factory DriveProviderResumable() => _instance;
  DriveProviderResumable._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'https://www.googleapis.com/auth/drive.file',
      'https://www.googleapis.com/auth/drive.appdata',
      'email',
      'profile'
    ],
  );

  String? _accessToken;
  
  // Retry configuration
  static const int maxRetries = 5;
  static const int baseDelayMs = 500;
  static const double backoffFactor = 2.0;
  static const int jitterMs = 100;

  /// Get current access token, refresh if needed
  Future<String> getAccessToken() async {
    if (_accessToken == null) {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        throw Exception('Google Sign-In failed');
      }
      final authHeaders = await account.authHeaders;
      _accessToken = authHeaders['Authorization']!.split(' ').last;
    }
    return _accessToken!;
  }

  /// Find or create folder by name
  /// Returns folderId
  Future<String> findOrCreateFolder(String folderName) async {
    final token = await getAccessToken();
    
    // First, try to find existing folder
    final query = "name='$folderName' and mimeType='application/vnd.google-apps.folder'";
    final searchUri = Uri.parse('https://www.googleapis.com/drive/v3/files')
        .replace(queryParameters: {'q': query});
    
    final searchResp = await http.get(searchUri, headers: {
      'Authorization': 'Bearer $token',
    });

    if (searchResp.statusCode == 200) {
      final data = json.decode(searchResp.body);
      final files = data['files'] as List;
      if (files.isNotEmpty) {
        return files[0]['id'];
      }
    }

    // Create new folder
    final createUri = Uri.parse('https://www.googleapis.com/drive/v3/files');
    final folderMetadata = {
      'name': folderName,
      'mimeType': 'application/vnd.google-apps.folder',
    };

    final createResp = await http.post(
      createUri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: json.encode(folderMetadata),
    );

    if (createResp.statusCode == 200) {
      final data = json.decode(createResp.body);
      return data['id'];
    } else {
      throw Exception('Failed to create folder: ${createResp.body}');
    }
  }

  /// Create subfolder under parent
  /// Returns folderId
  Future<String> createSubfolder(String parentId, String name) async {
    final token = await getAccessToken();
    
    final uri = Uri.parse('https://www.googleapis.com/drive/v3/files');
    final metadata = {
      'name': name,
      'mimeType': 'application/vnd.google-apps.folder',
      'parents': [parentId],
    };

    final resp = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: json.encode(metadata),
    );

    if (resp.statusCode == 200) {
      final data = json.decode(resp.body);
      return data['id'];
    } else {
      throw Exception('Failed to create subfolder: ${resp.body}');
    }
  }

  /// Create resumable upload session
  /// Returns upload URL for the session
  Future<Uri> createResumableSession({
    required String parentId,
    required String fileName,
    required int totalSize,
  }) async {
    final token = await getAccessToken();
    
    final uri = Uri.parse('https://www.googleapis.com/upload/drive/v3/files?uploadType=resumable');
    final metadata = {
      "name": fileName,
      "parents": [parentId],
      "mimeType": "application/octet-stream"
    };

    final resp = await _executeWithRetry(() async {
      return await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
          'X-Upload-Content-Type': 'application/octet-stream',
          'X-Upload-Content-Length': totalSize.toString(),
        },
        body: json.encode(metadata),
      );
    });

    if (resp.statusCode == 200) {
      final uploadUrl = resp.headers['location'];
      if (uploadUrl == null) {
        throw Exception('No upload URL returned in Location header');
      }
      return Uri.parse(uploadUrl);
    } else {
      throw Exception('Failed to create resumable session: ${resp.body}');
    }
  }

  /// Upload bytes with resume capability
  /// Returns file metadata Map on completion
  Future<Map<String, dynamic>> uploadBytesWithResume({
    required Uri uploadUrl,
    required Uint8List bytes,
    required int totalSize,
  }) async {
    return await _executeWithRetry(() async {
      return await _attemptUpload(uploadUrl, bytes, totalSize);
    });
  }

  /// Internal method to attempt upload with 308 handling
  Future<Map<String, dynamic>> _attemptUpload(Uri uploadUrl, Uint8List bytes, int totalSize) async {
    final resp = await http.put(
      uploadUrl,
      headers: {
        'Content-Length': bytes.length.toString(),
        'Content-Range': 'bytes 0-${bytes.length - 1}/$totalSize',
      },
      body: bytes,
    );

    if (resp.statusCode == 200 || resp.statusCode == 201) {
      // Upload completed successfully
      return json.decode(resp.body);
    } else if (resp.statusCode == 308) {
      // Resumable upload in progress
      final rangeHeader = resp.headers['range'];
      if (rangeHeader == null) {
        throw Exception('308 response without Range header');
      }
      
      // Parse range header: "bytes=0-1234"
      final match = RegExp(r'bytes=(\d+)-(\d+)').firstMatch(rangeHeader);
      if (match == null) {
        throw Exception('Invalid Range header format: $rangeHeader');
      }
      
      final lastByte = int.parse(match.group(2)!);
      final nextStartByte = lastByte + 1;
      
      if (nextStartByte >= bytes.length) {
        throw Exception('Server reports more bytes received than sent');
      }
      
      // Resume from next byte
      final remainingBytes = bytes.sublist(nextStartByte);
      final resumeResp = await http.put(
        uploadUrl,
        headers: {
          'Content-Length': remainingBytes.length.toString(),
          'Content-Range': 'bytes $nextStartByte-${bytes.length - 1}/$totalSize',
        },
        body: remainingBytes,
      );
      
      if (resumeResp.statusCode == 200 || resumeResp.statusCode == 201) {
        return json.decode(resumeResp.body);
      } else {
        throw Exception('Resume upload failed: ${resumeResp.statusCode} ${resumeResp.body}');
      }
    } else {
      throw Exception('Upload failed: ${resp.statusCode} ${resp.body}');
    }
  }

  /// Query upload status for existing session
  Future<int> queryUploadStatus(Uri uploadUrl) async {
    final resp = await http.put(
      uploadUrl,
      headers: {
        'Content-Range': 'bytes */*',
      },
    );

    if (resp.statusCode == 308) {
      final rangeHeader = resp.headers['range'];
      if (rangeHeader != null) {
        final match = RegExp(r'bytes=(\d+)-(\d+)').firstMatch(rangeHeader);
        if (match != null) {
          return int.parse(match.group(2)!) + 1; // Next byte to send
        }
      }
      return 0; // Start from beginning
    } else {
      throw Exception('Query upload status failed: ${resp.statusCode}');
    }
  }

  /// Download file as bytes (for small files)
  Future<Uint8List> downloadFileBytes(String driveFileId) async {
    final token = await getAccessToken();
    
    final uri = Uri.parse('https://www.googleapis.com/drive/v3/files/$driveFileId')
        .replace(queryParameters: {'alt': 'media'});

    final resp = await _executeWithRetry(() async {
      return await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
      });
    });

    if (resp.statusCode == 200) {
      return resp.bodyBytes;
    } else {
      throw Exception('Download failed: ${resp.statusCode} ${resp.body}');
    }
  }

  /// Download file as stream (for streaming decoding)
  Stream<List<int>> downloadFileStream(String driveFileId) async* {
    final bytes = await downloadFileBytes(driveFileId);
    
    // Chunk the bytes for streaming
    const chunkSize = 8192;
    for (int i = 0; i < bytes.length; i += chunkSize) {
      final end = (i + chunkSize < bytes.length) ? i + chunkSize : bytes.length;
      yield bytes.sublist(i, end);
    }
  }

  /// Query files with Drive query syntax
  Future<List<Map<String, dynamic>>> queryFiles(String query) async {
    final token = await getAccessToken();
    
    final uri = Uri.parse('https://www.googleapis.com/drive/v3/files')
        .replace(queryParameters: {'q': query});

    final resp = await _executeWithRetry(() async {
      return await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
      });
    });

    if (resp.statusCode == 200) {
      final data = json.decode(resp.body);
      return List<Map<String, dynamic>>.from(data['files'] ?? []);
    } else {
      throw Exception('Query files failed: ${resp.statusCode} ${resp.body}');
    }
  }

  /// Execute with retry and exponential backoff
  Future<T> _executeWithRetry<T>(Future<T> Function() operation) async {
    int attempt = 0;
    
    while (attempt < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempt++;
        if (attempt >= maxRetries) {
          rethrow;
        }
        
        // Calculate delay with exponential backoff and jitter
        final delay = (baseDelayMs * pow(backoffFactor, attempt - 1)).round();
        final jitter = Random().nextInt(jitterMs * 2) - jitterMs;
        final totalDelay = delay + jitter;
        
        if (kDebugMode) {
          print('DriveProvider retry $attempt/$maxRetries after ${totalDelay}ms: $e');
        }
        
        await Future.delayed(Duration(milliseconds: totalDelay));
      }
    }
    
    throw Exception('Max retries exceeded');
  }

  /// Update existing file content
  Future<Map<String, dynamic>> updateFileContent({
    required String fileId,
    required Uint8List newContent,
  }) async {
    final token = await getAccessToken();
    
    final uri = Uri.parse('https://www.googleapis.com/upload/drive/v3/files/$fileId?uploadType=media');
    
    final resp = await _executeWithRetry(() async {
      return await http.patch(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Content-Length': newContent.length.toString(),
        },
        body: newContent,
      );
    });

    if (resp.statusCode == 200) {
      return json.decode(resp.body);
    } else {
      throw Exception('File update failed: ${resp.statusCode} ${resp.body}');
    }
  }

  /// Delete file or folder from Google Drive
  Future<void> deleteFile(String fileId) async {
    final token = await getAccessToken();
    
    final uri = Uri.parse('https://www.googleapis.com/drive/v3/files/$fileId');
    
    final resp = await _executeWithRetry(() async {
      return await http.delete(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
    });

    if (resp.statusCode == 200 || resp.statusCode == 204) {
      if (kDebugMode) {
        print('Successfully deleted file: $fileId');
      }
    } else {
      throw Exception('File deletion failed: ${resp.statusCode} ${resp.body}');
    }
  }

  /// Reset authentication (for testing/logout)
  void resetAuth() {
    _accessToken = null;
  }
}