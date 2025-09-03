import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:collection';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:crypto/crypto.dart';
import 'cloud_backup_service.dart';

class ParallelUploadService {
  static const int _maxConcurrentUploads = 3;
  static const int _maxRetries = 3;
  static const int _chunkSize = 512 * 1024; // 512KB chunks for faster processing
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> uploadBackupInParallel({
    required Uint8List data,
    required String deviceId,
    required String backupName,
    required Function(double) onProgress,
    required Function(String) onStatusUpdate,
  }) async {
    onStatusUpdate('Preparing upload...');
    
    // Split data into chunks
    final chunks = _splitIntoChunks(data);
    final backupId = _generateBackupId();
    final chunkCount = chunks.length;
    
    onStatusUpdate('Uploading $chunkCount chunks...');
    
    // Calculate MD5 hash for integrity
    final hash = md5.convert(data).toString();
    
    try {
      // Create backup metadata first
      await _createBackupMetadata(
        deviceId: deviceId,
        backupId: backupId,
        backupName: backupName,
        chunkCount: chunkCount,
        totalSize: data.length,
        hash: hash,
      );
      
      // Upload chunks in parallel batches
      await _uploadChunksInParallel(
        chunks: chunks,
        deviceId: deviceId,
        backupId: backupId,
        onProgress: onProgress,
        onStatusUpdate: onStatusUpdate,
      );
      
      onStatusUpdate('Upload completed successfully!');
      return backupId;
      
    } catch (e) {
      // Cleanup on failure
      await _cleanupFailedUpload(deviceId, backupId);
      rethrow;
    }
  }

  Future<Uint8List> downloadBackupInParallel({
    required String deviceId,
    required String backupId,
    required Function(double) onProgress,
    required Function(String) onStatusUpdate,
  }) async {
    onStatusUpdate('Retrieving backup metadata...');
    
    // Get backup metadata
    final metadata = await _getBackupMetadata(deviceId, backupId);
    final chunkCount = metadata['chunkCount'] as int;
    final expectedHash = metadata['hash'] as String;
    
    onStatusUpdate('Downloading $chunkCount chunks...');
    
    // Download chunks in parallel
    final chunks = await _downloadChunksInParallel(
      deviceId: deviceId,
      backupId: backupId,
      chunkCount: chunkCount,
      onProgress: onProgress,
      onStatusUpdate: onStatusUpdate,
    );
    
    onStatusUpdate('Reassembling data...');
    
    // Combine chunks
    final combinedData = _combineChunks(chunks);
    
    // Verify integrity
    final actualHash = md5.convert(combinedData).toString();
    if (actualHash != expectedHash) {
      throw Exception('Data integrity check failed. File may be corrupted.');
    }
    
    onStatusUpdate('Download completed successfully!');
    return combinedData;
  }

  List<Uint8List> _splitIntoChunks(Uint8List data) {
    final chunks = <Uint8List>[];
    for (int i = 0; i < data.length; i += _chunkSize) {
      final end = math.min(i + _chunkSize, data.length);
      chunks.add(data.sublist(i, end));
    }
    return chunks;
  }

  String _generateBackupId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + 
           '_' + 
           math.Random().nextInt(10000).toString();
  }

  Future<void> _createBackupMetadata({
    required String deviceId,
    required String backupId,
    required String backupName,
    required int chunkCount,
    required int totalSize,
    required String hash,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final metadata = CloudBackupMetadata(
      id: backupId,
      name: backupName,
      createdAt: DateTime.now(),
      size: totalSize,
      userId: user.uid,
      deviceInfo: Platform.operatingSystem,
      appVersion: '1.0.0',
    );

    await _firestore
        .collection('backups')
        .doc(deviceId)
        .collection('user_backups')
        .doc(backupId)
        .set({
      ...metadata.toMap(),
      'chunkCount': chunkCount,
      'hash': hash,
      'status': 'uploading',
    });
  }

  Future<Map<String, dynamic>> _getBackupMetadata(String deviceId, String backupId) async {
    final doc = await _firestore
        .collection('backups')
        .doc(deviceId)
        .collection('user_backups')
        .doc(backupId)
        .get();
    
    if (!doc.exists) {
      throw Exception('Backup not found');
    }
    
    return doc.data()!;
  }

  Future<void> _uploadChunksInParallel({
    required List<Uint8List> chunks,
    required String deviceId,
    required String backupId,
    required Function(double) onProgress,
    required Function(String) onStatusUpdate,
  }) async {
    int completedChunks = 0;
    final totalChunks = chunks.length;
    
    // Create semaphore to limit concurrent uploads
    final semaphore = Semaphore(_maxConcurrentUploads);
    
    // Upload chunks with controlled concurrency
    final futures = chunks.asMap().entries.map((entry) async {
      await semaphore.acquire();
      
      try {
        final chunkIndex = entry.key;
        final chunkData = entry.value;
        
        await _uploadSingleChunk(
          deviceId: deviceId,
          backupId: backupId,
          chunkIndex: chunkIndex,
          chunkData: chunkData,
        );
        
        completedChunks++;
        final progress = (completedChunks / totalChunks) * 100;
        onProgress(progress);
        onStatusUpdate('Uploaded $completedChunks/$totalChunks chunks (${progress.round()}%)');
        
      } finally {
        semaphore.release();
      }
    }).toList();
    
    await Future.wait(futures);
    
    // Mark upload as complete
    await _firestore
        .collection('backups')
        .doc(deviceId)
        .collection('user_backups')
        .doc(backupId)
        .update({'status': 'completed'});
  }

  Future<void> _uploadSingleChunk({
    required String deviceId,
    required String backupId,
    required int chunkIndex,
    required Uint8List chunkData,
  }) async {
    int retries = 0;
    
    while (retries < _maxRetries) {
      try {
        await _firestore
            .collection('backups')
            .doc(deviceId)
            .collection('user_backups')
            .doc(backupId)
            .collection('chunks')
            .doc('chunk_$chunkIndex')
            .set({
          'index': chunkIndex,
          'data': base64Encode(chunkData),
          'size': chunkData.length,
          'uploadedAt': FieldValue.serverTimestamp(),
        });
        
        return; // Success
      } catch (e) {
        retries++;
        if (retries >= _maxRetries) {
          throw Exception('Failed to upload chunk $chunkIndex after $retries attempts: $e');
        }
        
        // Exponential backoff
        await Future.delayed(Duration(milliseconds: 1000 * math.pow(2, retries).round()));
      }
    }
  }

  Future<List<Uint8List>> _downloadChunksInParallel({
    required String deviceId,
    required String backupId,
    required int chunkCount,
    required Function(double) onProgress,
    required Function(String) onStatusUpdate,
  }) async {
    int completedChunks = 0;
    final chunks = List<Uint8List?>.filled(chunkCount, null);
    
    // Create semaphore to limit concurrent downloads
    final semaphore = Semaphore(_maxConcurrentUploads);
    
    // Download chunks with controlled concurrency
    final futures = List.generate(chunkCount, (chunkIndex) async {
      await semaphore.acquire();
      
      try {
        final chunkData = await _downloadSingleChunk(
          deviceId: deviceId,
          backupId: backupId,
          chunkIndex: chunkIndex,
        );
        
        chunks[chunkIndex] = chunkData;
        completedChunks++;
        
        final progress = (completedChunks / chunkCount) * 100;
        onProgress(progress);
        onStatusUpdate('Downloaded $completedChunks/$chunkCount chunks (${progress.round()}%)');
        
      } finally {
        semaphore.release();
      }
    });
    
    await Future.wait(futures);
    
    // Ensure all chunks were downloaded
    for (int i = 0; i < chunkCount; i++) {
      if (chunks[i] == null) {
        throw Exception('Failed to download chunk $i');
      }
    }
    
    return chunks.cast<Uint8List>();
  }

  Future<Uint8List> _downloadSingleChunk({
    required String deviceId,
    required String backupId,
    required int chunkIndex,
  }) async {
    int retries = 0;
    
    while (retries < _maxRetries) {
      try {
        final doc = await _firestore
            .collection('backups')
            .doc(deviceId)
            .collection('user_backups')
            .doc(backupId)
            .collection('chunks')
            .doc('chunk_$chunkIndex')
            .get();
        
        if (!doc.exists) {
          throw Exception('Chunk $chunkIndex not found');
        }
        
        final data = doc.data()!;
        final encodedData = data['data'] as String;
        return base64Decode(encodedData);
        
      } catch (e) {
        retries++;
        if (retries >= _maxRetries) {
          throw Exception('Failed to download chunk $chunkIndex after $retries attempts: $e');
        }
        
        // Exponential backoff
        await Future.delayed(Duration(milliseconds: 1000 * math.pow(2, retries).round()));
      }
    }
    
    throw Exception('Unreachable code');
  }

  Uint8List _combineChunks(List<Uint8List> chunks) {
    final totalLength = chunks.fold<int>(0, (sum, chunk) => sum + chunk.length);
    final combined = Uint8List(totalLength);
    
    int offset = 0;
    for (final chunk in chunks) {
      combined.setAll(offset, chunk);
      offset += chunk.length;
    }
    
    return combined;
  }

  Future<void> _cleanupFailedUpload(String deviceId, String backupId) async {
    try {
      // Delete backup document and all its subcollections
      final backupRef = _firestore
          .collection('backups')
          .doc(deviceId)
          .collection('user_backups')
          .doc(backupId);
      
      // Delete all chunks first
      final chunksSnapshot = await backupRef.collection('chunks').get();
      final batch = _firestore.batch();
      
      for (final doc in chunksSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // Delete backup metadata
      batch.delete(backupRef);
      
      await batch.commit();
    } catch (e) {
      // Log cleanup failure but don't throw
      print('Failed to cleanup failed upload: $e');
    }
  }

  Future<bool> deleteBackupInParallel({
    required String deviceId,
    required String backupId,
    required Function(double) onProgress,
    required Function(String) onStatusUpdate,
  }) async {
    try {
      onStatusUpdate('Retrieving backup metadata...');
      
      // Get backup metadata to know chunk count
      final metadata = await _getBackupMetadata(deviceId, backupId);
      final chunkCount = metadata['chunkCount'] as int;
      
      onStatusUpdate('Deleting backup chunks...');
      
      // Delete chunks in parallel batches
      await _deleteChunksInParallel(
        deviceId: deviceId,
        backupId: backupId,
        chunkCount: chunkCount,
        onProgress: onProgress,
        onStatusUpdate: onStatusUpdate,
      );
      
      onStatusUpdate('Deleting backup metadata...');
      
      // Finally delete the backup metadata
      await _firestore
          .collection('backups')
          .doc(deviceId)
          .collection('user_backups')
          .doc(backupId)
          .delete();
      
      onStatusUpdate('Backup deleted successfully!');
      return true;
      
    } catch (e) {
      throw Exception('Failed to delete backup: $e');
    }
  }

  Future<void> _deleteChunksInParallel({
    required String deviceId,
    required String backupId,
    required int chunkCount,
    required Function(double) onProgress,
    required Function(String) onStatusUpdate,
  }) async {
    const batchSize = 10; // Delete 10 chunks at a time
    int completedBatches = 0;
    final totalBatches = (chunkCount / batchSize).ceil();
    
    for (int batchStart = 0; batchStart < chunkCount; batchStart += batchSize) {
      final batchEnd = math.min(batchStart + batchSize, chunkCount);
      
      // Create batch delete operation
      final batch = _firestore.batch();
      
      for (int i = batchStart; i < batchEnd; i++) {
        final chunkRef = _firestore
            .collection('backups')
            .doc(deviceId)
            .collection('user_backups')
            .doc(backupId)
            .collection('chunks')
            .doc('chunk_$i');
        
        batch.delete(chunkRef);
      }
      
      await batch.commit();
      
      completedBatches++;
      final progress = (completedBatches / totalBatches) * 100;
      onProgress(progress);
      onStatusUpdate('Deleted ${math.min(batchEnd, chunkCount)}/$chunkCount chunks (${progress.round()}%)');
    }
  }
}

class Semaphore {
  final int maxCount;
  int _currentCount;
  final Queue<Completer<void>> _waitQueue = Queue<Completer<void>>();

  Semaphore(this.maxCount) : _currentCount = maxCount;

  Future<void> acquire() async {
    if (_currentCount > 0) {
      _currentCount--;
      return;
    }

    final completer = Completer<void>();
    _waitQueue.add(completer);
    return completer.future;
  }

  void release() {
    if (_waitQueue.isNotEmpty) {
      final completer = _waitQueue.removeFirst();
      completer.complete();
    } else {
      _currentCount++;
    }
  }
}

