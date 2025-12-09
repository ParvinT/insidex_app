// lib/services/download/decryption_preloader.dart

import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'package:flutter/foundation.dart';

import 'download_service.dart';

/// Smart pre-decryption service for offline audio playback
///
/// Features:
/// - Viewport-based preloading (only visible sessions)
/// - Max 2 parallel decrypt operations
/// - LRU cache with 5 file limit
/// - Memory-efficient cleanup
/// - Priority queue system
class DecryptionPreloader {
  static final DecryptionPreloader _instance = DecryptionPreloader._internal();
  factory DecryptionPreloader() => _instance;
  DecryptionPreloader._internal();

  // =================== CONFIGURATION ===================

  static const int maxParallelDecrypts = 2;
  static const int maxCachedFiles = 5;
  static const int preloadAheadCount =
      2; // Extra items to preload beyond visible

  // =================== STATE ===================

  final DownloadService _downloadService = DownloadService();

  // Queue of session IDs waiting to be decrypted
  final Queue<String> _decryptQueue = Queue();

  // Currently active decrypt operations
  final Set<String> _activeDecrypts = {};

  // LRU Cache: sessionId_language -> decrypted file path
  final LinkedHashMap<String, String> _decryptedCache = LinkedHashMap();

  // Track which sessions are already queued
  final Set<String> _queuedSessions = {};

  // Initialization flag
  bool _isInitialized = false;

  // Current language
  String _currentLanguage = 'en';

  // =================== INITIALIZATION ===================

  /// Initialize the preloader
  Future<void> initialize({String language = 'en'}) async {
    if (_isInitialized) return;

    _currentLanguage = language;
    _isInitialized = true;

    debugPrint('✅ [Preloader] Initialized with language: $language');
  }

  /// Update current language
  void setLanguage(String language) {
    if (_currentLanguage != language) {
      _currentLanguage = language;
      // Clear queue when language changes
      _decryptQueue.clear();
      _queuedSessions.clear();
      debugPrint('🌍 [Preloader] Language changed to: $language');
    }
  }

  // =================== PUBLIC API ===================

  /// Preload visible sessions (call this when scroll position changes)
  /// [sessionIds] should be the IDs of currently visible sessions
  Future<void> preloadVisibleSessions(List<String> sessionIds) async {
    if (!_isInitialized) return;

    for (final sessionId in sessionIds) {
      final cacheKey = _getCacheKey(sessionId);

      // Skip if already cached or queued
      if (_decryptedCache.containsKey(cacheKey)) continue;
      if (_queuedSessions.contains(cacheKey)) continue;
      if (_activeDecrypts.contains(cacheKey)) continue;

      // Add to queue
      _decryptQueue.addLast(cacheKey);
      _queuedSessions.add(cacheKey);

      debugPrint('📥 [Preloader] Queued: $cacheKey');
    }

    // Process queue
    _processQueue();
  }

  /// Get cached decrypted path (returns immediately if cached)
  /// Returns null if not cached - caller should fall back to normal decrypt
  String? getCachedPath(String sessionId) {
    final cacheKey = _getCacheKey(sessionId);
    final cachedPath = _decryptedCache[cacheKey];

    if (cachedPath != null) {
      // Move to end (LRU update)
      _decryptedCache.remove(cacheKey);
      _decryptedCache[cacheKey] = cachedPath;

      debugPrint('⚡ [Preloader] Cache hit: $cacheKey');
      return cachedPath;
    }

    debugPrint('❌ [Preloader] Cache miss: $cacheKey');
    return null;
  }

  /// Check if a session is cached
  bool isCached(String sessionId) {
    final cacheKey = _getCacheKey(sessionId);
    return _decryptedCache.containsKey(cacheKey);
  }

  /// Check if a session is being decrypted
  bool isDecrypting(String sessionId) {
    final cacheKey = _getCacheKey(sessionId);
    return _activeDecrypts.contains(cacheKey);
  }

  /// Prioritize a specific session (move to front of queue)
  void prioritize(String sessionId) {
    final cacheKey = _getCacheKey(sessionId);

    // Already cached, no need to prioritize
    if (_decryptedCache.containsKey(cacheKey)) return;

    // Already being decrypted
    if (_activeDecrypts.contains(cacheKey)) return;

    // Remove from current position and add to front
    final queueList = _decryptQueue.toList();
    if (queueList.remove(cacheKey)) {
      _decryptQueue.clear();
      _decryptQueue.addFirst(cacheKey);
      _decryptQueue.addAll(queueList);
      debugPrint('⬆️ [Preloader] Prioritized: $cacheKey');
    }
  }

  /// Clear all cached files and reset state
  Future<void> clear() async {
    _decryptQueue.clear();
    _queuedSessions.clear();
    _activeDecrypts.clear();

    // Delete cached files
    for (final cachedPath in _decryptedCache.values) {
      try {
        final file = File(cachedPath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('⚠️ [Preloader] Delete error: $e');
      }
    }

    _decryptedCache.clear();
    debugPrint('🧹 [Preloader] Cleared all cache');
  }

  /// Get cache statistics
  Map<String, dynamic> getStats() {
    return {
      'cachedCount': _decryptedCache.length,
      'queueLength': _decryptQueue.length,
      'activeDecrypts': _activeDecrypts.length,
      'maxCached': maxCachedFiles,
    };
  }

  // =================== PRIVATE METHODS ===================

  String _getCacheKey(String sessionId) {
    return '${sessionId}_$_currentLanguage';
  }

  /// Process the decrypt queue
  void _processQueue() {
    // Start new decrypts if under limit
    while (_activeDecrypts.length < maxParallelDecrypts &&
        _decryptQueue.isNotEmpty) {
      final cacheKey = _decryptQueue.removeFirst();
      _queuedSessions.remove(cacheKey);

      // Start decrypt in background
      _decryptSession(cacheKey);
    }
  }

  /// Decrypt a single session
  Future<void> _decryptSession(String cacheKey) async {
    // Parse session ID and language from cache key
    final parts = cacheKey.split('_');
    if (parts.length < 2) return;

    final sessionId = parts.sublist(0, parts.length - 1).join('_');
    final language = parts.last;

    _activeDecrypts.add(cacheKey);
    debugPrint('🔓 [Preloader] Decrypting: $cacheKey');

    try {
      // Get decrypted path using existing service
      final decryptedPath = await _downloadService.getDecryptedAudioPath(
        sessionId,
        language,
      );

      if (decryptedPath != null) {
        // Add to cache
        _addToCache(cacheKey, decryptedPath);
        debugPrint('✅ [Preloader] Decrypted: $cacheKey');
      } else {
        debugPrint('⚠️ [Preloader] Decrypt failed: $cacheKey');
      }
    } catch (e) {
      debugPrint('❌ [Preloader] Decrypt error: $cacheKey - $e');
    } finally {
      _activeDecrypts.remove(cacheKey);

      // Process next in queue
      _processQueue();
    }
  }

  /// Add to LRU cache with eviction
  void _addToCache(String cacheKey, String path) {
    // Evict oldest if at capacity
    while (_decryptedCache.length >= maxCachedFiles) {
      final oldestKey = _decryptedCache.keys.first;
      _decryptedCache.remove(oldestKey);

      debugPrint('🗑️ [Preloader] Evicting LRU: $oldestKey');

      // Note: We don't delete the temp file because DownloadService
      // manages temp file cleanup. The file might still be in use.
    }

    _decryptedCache[cacheKey] = path;
  }
}
