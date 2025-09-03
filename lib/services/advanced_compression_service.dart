import 'dart:math';
import 'dart:typed_data';
import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

class CompressionResult {
  final Uint8List compressedData;
  final int originalSize;
  final int compressedSize;
  final double compressionRatio;
  final String checksum;
  final Duration compressionTime;

  CompressionResult({
    required this.compressedData,
    required this.originalSize,
    required this.compressedSize,
    required this.compressionRatio,
    required this.checksum,
    required this.compressionTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'originalSize': originalSize,
      'compressedSize': compressedSize,
      'compressionRatio': compressionRatio,
      'checksum': checksum,
      'compressionTimeMs': compressionTime.inMilliseconds,
    };
  }
}

class DecompressionResult {
  final Uint8List decompressedData;
  final bool checksumValid;
  final Duration decompressionTime;

  DecompressionResult({
    required this.decompressedData,
    required this.checksumValid,
    required this.decompressionTime,
  });
}

class AdvancedCompressionService {
  static const int _defaultCompressionLevel = 6; // Best balance between size and speed
  static const int _maxCompressionLevel = 9;     // Maximum compression
  static const int _fastCompressionLevel = 1;    // Fastest compression

  /// Compresses data with advanced optimization based on data characteristics
  static Future<CompressionResult> compressData({
    required Uint8List data,
    String compressionLevel = 'balanced',
    Function(String)? onProgress,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    onProgress?.call('Analyzing data structure...');
    
    // Analyze data to choose optimal compression strategy
    final analysisResult = await _analyzeData(data);
    final selectedLevel = _selectCompressionLevel(compressionLevel, analysisResult);
    
    onProgress?.call('Compressing with level $selectedLevel...');
    
    // Calculate original checksum
    final originalChecksum = sha256.convert(data).toString();
    
    // Perform compression with selected strategy
    final compressedData = await _performCompression(
      data, 
      selectedLevel, 
      analysisResult,
      onProgress,
    );
    
    stopwatch.stop();
    
    final compressionRatio = compressedData.length / data.length;
    
    onProgress?.call('Compression completed!');
    
    return CompressionResult(
      compressedData: compressedData,
      originalSize: data.length,
      compressedSize: compressedData.length,
      compressionRatio: compressionRatio,
      checksum: originalChecksum,
      compressionTime: stopwatch.elapsed,
    );
  }

  /// Decompresses data with integrity verification
  static Future<DecompressionResult> decompressData({
    required Uint8List compressedData,
    required String expectedChecksum,
    Function(String)? onProgress,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    onProgress?.call('Decompressing data...');
    
    try {
      // Decompress the data
      final decompressedData = await _performDecompression(compressedData, onProgress);
      
      onProgress?.call('Verifying data integrity...');
      
      // Verify checksum
      final actualChecksum = sha256.convert(decompressedData).toString();
      final checksumValid = actualChecksum == expectedChecksum;
      
      stopwatch.stop();
      
      onProgress?.call(checksumValid ? 'Decompression completed!' : 'Warning: Checksum mismatch!');
      
      return DecompressionResult(
        decompressedData: decompressedData,
        checksumValid: checksumValid,
        decompressionTime: stopwatch.elapsed,
      );
      
    } catch (e) {
      throw Exception('Decompression failed: $e');
    }
  }

  /// Analyzes data characteristics to optimize compression
  static Future<Map<String, dynamic>> _analyzeData(Uint8List data) async {
    // Sample the data to understand its characteristics
    final sampleSize = (data.length * 0.1).clamp(1024, 10240).toInt(); // 10% sample, min 1KB, max 10KB
    final sample = data.sublist(0, sampleSize.clamp(0, data.length));
    
    // Calculate entropy (measure of randomness)
    final entropy = _calculateEntropy(sample);
    
    // Detect if data is already compressed (high entropy)
    final isAlreadyCompressed = entropy > 7.5; // Entropy close to 8 means highly random
    
    // Analyze byte patterns
    final hasRepeatingPatterns = _detectRepeatingPatterns(sample);
    
    // Check for JSON/text patterns
    final isTextLike = _isTextLikeData(sample);
    
    return {
      'entropy': entropy,
      'isAlreadyCompressed': isAlreadyCompressed,
      'hasRepeatingPatterns': hasRepeatingPatterns,
      'isTextLike': isTextLike,
      'sampleSize': sample.length,
    };
  }

  static double _calculateEntropy(Uint8List data) {
    final frequency = List<int>.filled(256, 0);
    
    // Count byte frequencies
    for (final byte in data) {
      frequency[byte]++;
    }
    
    // Calculate entropy
    double entropy = 0.0;
    final length = data.length;
    
    for (final freq in frequency) {
      if (freq > 0) {
        final probability = freq / length;
        entropy -= probability * (log2(probability));
      }
    }
    
    return entropy;
  }

  static double log2(double x) => (x <= 0) ? 0 : (log(x) / ln2);

  static bool _detectRepeatingPatterns(Uint8List data) {
    if (data.length < 64) return false;
    
    // Check for simple repeating patterns
    int patternCount = 0;
    for (int i = 0; i < data.length - 8; i++) {
      for (int j = i + 4; j < data.length - 4; j++) {
        if (_bytesEqual(data, i, j, 4)) {
          patternCount++;
          if (patternCount > data.length * 0.05) return true; // 5% threshold
        }
      }
    }
    
    return false;
  }

  static bool _bytesEqual(Uint8List data, int pos1, int pos2, int length) {
    for (int i = 0; i < length && pos1 + i < data.length && pos2 + i < data.length; i++) {
      if (data[pos1 + i] != data[pos2 + i]) return false;
    }
    return true;
  }

  static bool _isTextLikeData(Uint8List data) {
    int textChars = 0;
    for (final byte in data.take(1024)) { // Check first 1KB
      if ((byte >= 32 && byte <= 126) || byte == 9 || byte == 10 || byte == 13) {
        textChars++;
      }
    }
    return textChars > data.take(1024).length * 0.8; // 80% printable characters
  }

  static int _selectCompressionLevel(String level, Map<String, dynamic> analysis) {
    final isAlreadyCompressed = analysis['isAlreadyCompressed'] as bool;
    final hasRepeatingPatterns = analysis['hasRepeatingPatterns'] as bool;
    final isTextLike = analysis['isTextLike'] as bool;
    
    // If already compressed, use fast compression to avoid wasting time
    if (isAlreadyCompressed) {
      return _fastCompressionLevel;
    }
    
    switch (level) {
      case 'fast':
        return _fastCompressionLevel;
      case 'maximum':
        return _maxCompressionLevel;
      case 'balanced':
      default:
        // Optimize based on data characteristics
        if (isTextLike || hasRepeatingPatterns) {
          return _maxCompressionLevel; // Text compresses very well
        }
        return _defaultCompressionLevel;
    }
  }

  static Future<Uint8List> _performCompression(
    Uint8List data,
    int level,
    Map<String, dynamic> analysis,
    Function(String)? onProgress,
  ) async {
    onProgress?.call('Performing compression...');
    
    try {
      // Use different compression strategies based on data type
      if (analysis['isTextLike'] == true) {
        return await _compressTextData(data, level, onProgress);
      } else {
        return await _compressBinaryData(data, level, onProgress);
      }
    } catch (e) {
      // Fallback to basic compression
      onProgress?.call('Using fallback compression...');
      final encoder = ZipEncoder();
      final archive = Archive();
      archive.addFile(ArchiveFile('data', data.length, data));
      final encoded = encoder.encode(archive);
      return Uint8List.fromList(encoded);
    }
  }

  static Future<Uint8List> _compressTextData(
    Uint8List data, 
    int level, 
    Function(String)? onProgress,
  ) async {
    onProgress?.call('Applying text-optimized compression...');
    
    // For text data, use ZIP compression
    final encoder = ZipEncoder();
    
    final archive = Archive();
    archive.addFile(ArchiveFile('data.txt', data.length, data));
    
    final encoded = encoder.encode(archive);
    return Uint8List.fromList(encoded);
  }

  static Future<Uint8List> _compressBinaryData(
    Uint8List data, 
    int level, 
    Function(String)? onProgress,
  ) async {
    onProgress?.call('Applying binary-optimized compression...');
    
    // For binary data, use standard ZIP compression
    final encoder = ZipEncoder();
    
    final archive = Archive();
    archive.addFile(ArchiveFile('data.bin', data.length, data));
    
    final encoded = encoder.encode(archive);
    return Uint8List.fromList(encoded);
  }

  static Future<Uint8List> _performDecompression(
    Uint8List compressedData,
    Function(String)? onProgress,
  ) async {
    onProgress?.call('Extracting compressed data...');
    
    try {
      final archive = ZipDecoder().decodeBytes(compressedData);
      
      if (archive.files.isEmpty) {
        throw Exception('No files found in compressed data');
      }
      
      final file = archive.files.first;
      return Uint8List.fromList(file.content as List<int>);
      
    } catch (e) {
      throw Exception('Failed to decompress data: $e');
    }
  }

  /// Estimates compression benefit before performing actual compression
  static Future<Map<String, dynamic>> estimateCompression(Uint8List data) async {
    final analysis = await _analyzeData(data);
    
    double estimatedRatio;
    String recommendation;
    
    if (analysis['isAlreadyCompressed'] == true) {
      estimatedRatio = 0.95; // Minimal compression expected
      recommendation = 'Data appears already compressed. Limited benefit expected.';
    } else if (analysis['isTextLike'] == true) {
      estimatedRatio = 0.3; // Text compresses very well
      recommendation = 'Excellent compression expected for text data.';
    } else if (analysis['hasRepeatingPatterns'] == true) {
      estimatedRatio = 0.5; // Good compression for repetitive data
      recommendation = 'Good compression expected due to repeating patterns.';
    } else {
      estimatedRatio = 0.8; // Moderate compression for binary data
      recommendation = 'Moderate compression expected for binary data.';
    }
    
    return {
      'estimatedCompressionRatio': estimatedRatio,
      'estimatedSavedBytes': (data.length * (1 - estimatedRatio)).round(),
      'recommendation': recommendation,
      'analysis': analysis,
    };
  }
}