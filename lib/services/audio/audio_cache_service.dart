// lib/services/audio/audio_cache_service.dart

import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Professional Audio Cache Service for INSIDEX
///
/// Features:
/// - Uses Application Support Directory (persistent on iOS)
/// - SHA256 hashed filenames (no URL encoding issues)
/// - File validation on access (iOS sandbox check)
/// - Automatic cleanup of corrupted/stale files
/// - Metadata tracking via SharedPreferences
/// - LRU-style cache eviction
class AudioCacheService {
  static const String _cacheFolder = 'insidex_audio_cache';
  static const String _metadataKey = 'insidex_audio_cache_metadata';
  static const int _maxCacheSize = 500 * 1024 * 1024; // 500 MB
  static const int _maxCacheAgeDays = 30;

  static Directory? _cacheDir;
  static Map<String, CacheMetadata>? _metadata;
  static bool _isInitialized = false;

  // Download locks to prevent duplicate downloads
  static final Map<String, Future<File>> _downloadLocks = {};

  // =================== INITIALIZATION ===================

  /// Initialize cache service
  /// Call this in main.dart before using cache
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _ensureCacheDirectory();
      await _loadMetadata();
      await _cleanupInvalidFiles();
      _isInitialized = true;
      debugPrint(
          '✅ [AudioCache] Initialized with ${_metadata!.length} cached files');
    } catch (e) {
      debugPrint('⚠️ [AudioCache] Initialization error: $e');
      _metadata = {};
      _isInitialized = true;
    }
  }

  /// Ensure initialized before any operation
  static Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  // =================== DIRECTORY MANAGEMENT ===================

  /// Get cache directory (Application Support - persists on iOS)
  static Future<Directory> _ensureCacheDirectory() async {
    if (_cacheDir != null && await _cacheDir!.exists()) {
      return _cacheDir!;
    }

    // Use Application Support Directory - persists across app restarts
    // This is different from Temporary Directory which iOS can clear
    final appDir = await getApplicationSupportDirectory();
    _cacheDir = Directory('${appDir.path}/$_cacheFolder');

    if (!await _cacheDir!.exists()) {
      await _cacheDir!.create(recursive: true);
      debugPrint('📁 [AudioCache] Created cache directory: ${_cacheDir!.path}');
    }

    return _cacheDir!;
  }

  // =================== FILENAME GENERATION ===================

  /// Generate safe filename from URL using SHA256
  /// This eliminates URL encoding issues (Cyrillic, special chars, etc.)
  static String _generateFileName(String url) {
    final bytes = utf8.encode(url);
    final hash = sha256.convert(bytes);
    return '${hash.toString()}.mp3';
  }

  /// Get full file path for URL
  static Future<String> _getFilePath(String url) async {
    final dir = await _ensureCacheDirectory();
    final fileName = _generateFileName(url);
    return '${dir.path}/$fileName';
  }

  // =================== METADATA MANAGEMENT ===================

  /// Load metadata from SharedPreferences
  static Future<void> _loadMetadata() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_metadataKey);

      if (jsonStr != null && jsonStr.isNotEmpty) {
        final Map<String, dynamic> json = jsonDecode(jsonStr);
        _metadata = {};

        for (final entry in json.entries) {
          try {
            _metadata![entry.key] = CacheMetadata.fromJson(entry.value);
          } catch (e) {
            debugPrint('⚠️ [AudioCache] Invalid metadata entry, skipping');
          }
        }
      } else {
        _metadata = {};
      }
    } catch (e) {
      debugPrint('⚠️ [AudioCache] Metadata load error: $e');
      _metadata = {};
    }
  }

  /// Save metadata to SharedPreferences
  static Future<void> _saveMetadata() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json =
          _metadata!.map((key, value) => MapEntry(key, value.toJson()));
      await prefs.setString(_metadataKey, jsonEncode(json));
    } catch (e) {
      debugPrint('⚠️ [AudioCache] Metadata save error: $e');
    }
  }

  // =================== CACHE VALIDATION ===================

  /// Cleanup invalid, stale, and corrupted files
  static Future<void> _cleanupInvalidFiles() async {
    if (_metadata == null || _metadata!.isEmpty) return;

    try {
      final now = DateTime.now();
      final urlsToRemove = <String>[];
      int totalSize = 0;

      for (final entry in _metadata!.entries) {
        final url = entry.key;
        final meta = entry.value;
        final filePath = await _getFilePath(url);
        final file = File(filePath);

        // Check 1: File exists?
        if (!await file.exists()) {
          urlsToRemove.add(url);
          debugPrint('🗑️ [AudioCache] Removing missing file entry');
          continue;
        }

        // Check 2: File too old?
        final ageDays = now.difference(meta.cachedAt).inDays;
        if (ageDays > _maxCacheAgeDays) {
          urlsToRemove.add(url);
          await _safeDelete(file);
          debugPrint(
              '🗑️ [AudioCache] Removing stale file ($ageDays days old)');
          continue;
        }

        // Check 3: File readable? (iOS sandbox validation)
        if (!await _isFileReadable(file)) {
          urlsToRemove.add(url);
          await _safeDelete(file);
          debugPrint('🗑️ [AudioCache] Removing unreadable file (iOS sandbox)');
          continue;
        }

        // File is valid, add to total size
        try {
          totalSize += await file.length();
        } catch (_) {
          urlsToRemove.add(url);
          await _safeDelete(file);
        }
      }

      // Remove invalid entries from metadata
      for (final url in urlsToRemove) {
        _metadata!.remove(url);
      }

      // Check cache size limit
      if (totalSize > _maxCacheSize) {
        await _evictOldestFiles(totalSize);
      }

      if (urlsToRemove.isNotEmpty) {
        await _saveMetadata();
        debugPrint(
            '🧹 [AudioCache] Cleaned up ${urlsToRemove.length} invalid files');
      }
    } catch (e) {
      debugPrint('⚠️ [AudioCache] Cleanup error: $e');
    }
  }

  /// Check if file is readable (critical for iOS sandbox)
  static Future<bool> _isFileReadable(File file) async {
    try {
      final randomAccess = await file.open(mode: FileMode.read);
      // Try to read first byte
      await randomAccess.read(1);
      await randomAccess.close();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Safely delete a file
  static Future<void> _safeDelete(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  /// Evict oldest files to meet size limit (LRU-style)
  static Future<void> _evictOldestFiles(int currentSize) async {
    // Sort by last accessed time (oldest first)
    final sortedEntries = _metadata!.entries.toList()
      ..sort(
          (a, b) => a.value.lastAccessedAt.compareTo(b.value.lastAccessedAt));

    int freedSpace = 0;
    final targetSize = (_maxCacheSize * 0.7).toInt(); // Clean to 70%

    for (final entry in sortedEntries) {
      if (currentSize - freedSpace <= targetSize) break;

      final filePath = await _getFilePath(entry.key);
      final file = File(filePath);

      if (await file.exists()) {
        try {
          freedSpace += await file.length();
          await file.delete();
        } catch (_) {}
      }

      _metadata!.remove(entry.key);
    }

    await _saveMetadata();
    debugPrint('🧹 [AudioCache] Evicted ${_formatBytes(freedSpace)} (LRU)');
  }

  // =================== PUBLIC API ===================

  /// Check if audio is cached and valid
  static Future<bool> isCached(String url) async {
    await _ensureInitialized();

    try {
      // Check metadata
      if (!_metadata!.containsKey(url)) {
        return false;
      }

      // Check file exists
      final filePath = await _getFilePath(url);
      final file = File(filePath);

      if (!await file.exists()) {
        _metadata!.remove(url);
        await _saveMetadata();
        return false;
      }

      // Validate file is readable (iOS sandbox check)
      if (!await _isFileReadable(file)) {
        _metadata!.remove(url);
        await _safeDelete(file);
        await _saveMetadata();
        debugPrint('⚠️ [AudioCache] File not readable, removed from cache');
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get cached audio file or download if not cached
  static Future<File> getCachedAudio(String url) async {
    await _ensureInitialized();

    final shortUrl = url.length > 80 ? '${url.substring(0, 80)}...' : url;
    debugPrint('🎵 [AudioCache] Fetching: $shortUrl');

    // Check if already downloading
    if (_downloadLocks.containsKey(url)) {
      debugPrint('⏳ [AudioCache] Already downloading, waiting...');
      return await _downloadLocks[url]!;
    }

    final filePath = await _getFilePath(url);
    final file = File(filePath);

    // Check if cached and valid
    if (await isCached(url)) {
      // Update last accessed time
      _metadata![url] = _metadata![url]!.copyWith(
        lastAccessedAt: DateTime.now(),
      );
      await _saveMetadata();

      final size = await file.length();
      debugPrint('✅ [AudioCache] Using cached file (${_formatBytes(size)})');
      return file;
    }

    // Download file
    debugPrint('📥 [AudioCache] Downloading...');

    final downloadFuture = _downloadFile(url, filePath);
    _downloadLocks[url] = downloadFuture;

    try {
      return await downloadFuture;
    } finally {
      _downloadLocks.remove(url);
    }
  }

  /// Download file from URL
  static Future<File> _downloadFile(String url, String filePath) async {
    try {
      final httpClient = HttpClient();
      httpClient.connectionTimeout = const Duration(seconds: 30);

      final request = await httpClient.getUrl(Uri.parse(url));
      final response = await request.close();

      if (response.statusCode != 200) {
        httpClient.close();
        throw Exception('HTTP ${response.statusCode}');
      }

      // Ensure directory exists
      final file = File(filePath);
      final parentDir = file.parent;
      if (!await parentDir.exists()) {
        await parentDir.create(recursive: true);
      }

      // Download to file
      final sink = file.openWrite();
      await response.pipe(sink);
      await sink.close();
      httpClient.close();

      // Verify download
      if (!await file.exists()) {
        throw Exception('File not created');
      }

      final size = await file.length();
      if (size == 0) {
        await _safeDelete(file);
        throw Exception('Empty file downloaded');
      }

      // Save metadata
      _metadata![url] = CacheMetadata(
        url: url,
        fileName: _generateFileName(url),
        size: size,
        cachedAt: DateTime.now(),
        lastAccessedAt: DateTime.now(),
      );
      await _saveMetadata();

      debugPrint('✅ [AudioCache] Downloaded (${_formatBytes(size)})');
      return file;
    } catch (e) {
      debugPrint('❌ [AudioCache] Download error: $e');
      rethrow;
    }
  }

  /// Pre-cache audio in background
  static Future<void> precacheAudio(String url) async {
    try {
      if (await isCached(url)) {
        final shortUrl = url.length > 50 ? '${url.substring(0, 50)}...' : url;
        debugPrint('✅ [AudioCache] Already cached: $shortUrl');
        return;
      }

      debugPrint('📥 [AudioCache] Pre-caching...');
      await getCachedAudio(url);
      debugPrint('✅ [AudioCache] Pre-cached successfully');
    } catch (e) {
      debugPrint('⚠️ [AudioCache] Pre-cache error: $e');
    }
  }

  /// Clear all cache
  static Future<void> clearCache() async {
    await _ensureInitialized();

    try {
      final dir = await _ensureCacheDirectory();

      if (await dir.exists()) {
        await dir.delete(recursive: true);
        await dir.create();
      }

      _metadata = {};
      await _saveMetadata();

      debugPrint('✅ [AudioCache] Cache cleared');
    } catch (e) {
      debugPrint('❌ [AudioCache] Clear error: $e');
    }
  }

  /// Get cache statistics
  static Future<Map<String, dynamic>> getCacheStats() async {
    await _ensureInitialized();

    try {
      int totalSize = 0;
      int fileCount = _metadata!.length;

      for (final entry in _metadata!.values) {
        totalSize += entry.size;
      }

      return {
        'fileCount': fileCount,
        'totalSize': totalSize,
        'formattedSize': _formatBytes(totalSize),
        'maxSize': _formatBytes(_maxCacheSize),
        'usagePercent':
            '${(totalSize / _maxCacheSize * 100).toStringAsFixed(1)}%',
      };
    } catch (e) {
      return {
        'fileCount': 0,
        'totalSize': 0,
        'formattedSize': '0 MB',
        'maxSize': _formatBytes(_maxCacheSize),
        'usagePercent': '0%',
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

// =================== CACHE METADATA ===================

/// Metadata for each cached file
class CacheMetadata {
  final String url;
  final String fileName;
  final int size;
  final DateTime cachedAt;
  final DateTime lastAccessedAt;

  CacheMetadata({
    required this.url,
    required this.fileName,
    required this.size,
    required this.cachedAt,
    required this.lastAccessedAt,
  });

  CacheMetadata copyWith({DateTime? lastAccessedAt}) {
    return CacheMetadata(
      url: url,
      fileName: fileName,
      size: size,
      cachedAt: cachedAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'url': url,
        'fileName': fileName,
        'size': size,
        'cachedAt': cachedAt.toIso8601String(),
        'lastAccessedAt': lastAccessedAt.toIso8601String(),
      };

  factory CacheMetadata.fromJson(Map<String, dynamic> json) => CacheMetadata(
        url: json['url'] ?? '',
        fileName: json['fileName'] ?? '',
        size: json['size'] ?? 0,
        cachedAt: DateTime.tryParse(json['cachedAt'] ?? '') ?? DateTime.now(),
        lastAccessedAt:
            DateTime.tryParse(json['lastAccessedAt'] ?? '') ?? DateTime.now(),
      );
}
