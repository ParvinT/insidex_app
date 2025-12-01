// lib/services/audio_cache_service.dart

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

/// Audio-specific cache manager
/// Optimized for large audio files with longer retention
class AudioCacheService {
  static const key = 'insidexAudioCache';

  static CacheManager? _instance;

  static final Map<String, Future<File>> _downloadLocks = {};

  /// Get singleton cache manager instance
  static CacheManager get instance {
    _instance ??= CacheManager(
      Config(
        key,
        stalePeriod: const Duration(days: 30), // 30 days retention
        maxNrOfCacheObjects: 200, // Max 200 audio files
        repo: JsonCacheInfoRepository(databaseName: key),
        fileService: HttpFileService(),
      ),
    );
    return _instance!;
  }

  /// Get cached audio file or download if not cached
  /// Returns file path for audio player
  static Future<File> getCachedAudio(String audioUrl) async {
    try {
      debugPrint('🎵 [AudioCache] Fetching: $audioUrl');

      // Check cache first
      final fileInfo = await instance.getFileFromCache(audioUrl);

      if (fileInfo != null && fileInfo.file.existsSync()) {
        debugPrint(
            '✅ [AudioCache] Using cached file (${_formatBytes(fileInfo.file.lengthSync())})');
        return fileInfo.file;
      }

      // 🆕 Check if already downloading this URL
      if (_downloadLocks.containsKey(audioUrl)) {
        debugPrint('⏳ [AudioCache] Already downloading, waiting...');
        return await _downloadLocks[audioUrl]!;
      }

      // 🆕 Create download future and store in lock
      debugPrint('📥 [AudioCache] Downloading...');
      final downloadFuture = instance.getSingleFile(audioUrl).then((file) {
        debugPrint(
            '✅ [AudioCache] Downloaded and cached (${_formatBytes(file.lengthSync())})');
        _downloadLocks.remove(audioUrl); // Remove lock after download
        return file;
      }).catchError((error) {
        debugPrint('❌ [AudioCache] Download error: $error');
        _downloadLocks.remove(audioUrl); // Remove lock on error
        throw error;
      });

      _downloadLocks[audioUrl] = downloadFuture;

      return await downloadFuture;
    } catch (e) {
      debugPrint('❌ [AudioCache] Error: $e');
      rethrow;
    }
  }

  /// Pre-cache audio file in background (for future playback)
  static Future<void> precacheAudio(String audioUrl) async {
    try {
      final fileInfo = await instance.getFileFromCache(audioUrl);
      if (fileInfo != null) {
        debugPrint('✅ [AudioCache] Already cached: $audioUrl');
        return;
      }

      debugPrint('📥 [AudioCache] Pre-caching: $audioUrl');
      await instance.downloadFile(audioUrl);
      debugPrint('✅ [AudioCache] Pre-cached successfully');
    } catch (e) {
      debugPrint('⚠️ [AudioCache] Pre-cache error: $e');
    }
  }

  /// Check if audio is cached
  static Future<bool> isCached(String audioUrl) async {
    try {
      final fileInfo = await instance.getFileFromCache(audioUrl);
      return fileInfo != null && fileInfo.file.existsSync();
    } catch (e) {
      return false;
    }
  }

  /// Clear all audio cache
  static Future<void> clearCache() async {
    try {
      await instance.emptyCache();
      debugPrint('✅ [AudioCache] Cache cleared');
    } catch (e) {
      debugPrint('❌ [AudioCache] Clear error: $e');
    }
  }

  /// Get cache statistics
  static Future<Map<String, dynamic>> getCacheStats() async {
    try {
      // flutter_cache_manager doesn't expose file list easily
      // So we'll return basic info
      debugPrint('📊 [AudioCache] Getting cache stats...');

      return {
        'fileCount': 0, // Not easily accessible
        'totalSize': 0,
        'formattedSize': '0 MB',
        'info': 'Cache stats limited by flutter_cache_manager API',
      };
    } catch (e) {
      debugPrint('❌ [AudioCache] Stats error: $e');
      return {
        'fileCount': 0,
        'totalSize': 0,
        'formattedSize': '0 MB',
      };
    }
  }

  /// Format bytes to human readable
  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
