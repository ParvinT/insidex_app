// lib/services/download/download_service.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;

import '../../models/downloaded_session.dart';
import 'download_database.dart';
import 'download_encryption.dart';
import 'download_helpers.dart';
import 'connectivity_service.dart';
import '../language_helper_service.dart';
import '../session_localization_service.dart';

/// Main download service for managing offline audio downloads
///
/// Features:
/// - Download queue management
/// - Background downloads
/// - Progress tracking
/// - Encrypted storage
/// - Offline playback support
class DownloadService {
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;
  DownloadService._internal();

  // Dependencies
  final DownloadDatabase _database = DownloadDatabase();
  final DownloadEncryption _encryption = DownloadEncryption();
  final ConnectivityService _connectivity = ConnectivityService();

  // Download directory
  Directory? _downloadDir;

  // Download queue
  final Map<String, DownloadQueueItem> _queue = {};

  // Active download
  String? _activeDownloadKey;

  // Progress streams
  final StreamController<DownloadProgress> _progressController =
      StreamController<DownloadProgress>.broadcast();

  // Downloads list stream
  final StreamController<List<DownloadedSession>> _downloadsController =
      StreamController<List<DownloadedSession>>.broadcast();

  // Initialization flag
  bool _isInitialized = false;

  // Current user ID (for encryption)
  String? _currentUserId;

  // Progress throttle
  DateTime? _lastProgressEmit;
  static const Duration _progressThrottleDuration = Duration(milliseconds: 100);

  // Retry settings
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);

  // Cancel flags for active downloads
  final Map<String, bool> _cancelFlags = {};

  /// Stream of download progress updates
  Stream<DownloadProgress> get progressStream => _progressController.stream;

  /// Stream of downloads list updates
  Stream<List<DownloadedSession>> get downloadsStream =>
      _downloadsController.stream;

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Get download directory path
  String? get downloadPath => _downloadDir?.path;

  // =================== INITIALIZATION ===================

  /// Initialize the download service
  Future<void> initialize(String userId) async {
    if (_isInitialized && _currentUserId == userId) {
      debugPrint('📥 [DownloadService] Already initialized for user');
      return;
    }

    debugPrint('📥 [DownloadService] Initializing...');

    try {
      // Store user ID
      _currentUserId = userId;

      // Initialize encryption with user-specific key
      _encryption.initialize(userId);

      // Initialize connectivity service
      await _connectivity.initialize();

      // Setup download directory
      await _setupDownloadDirectory();

      // Mark as initialized
      _isInitialized = true;

      // Auto cleanup temp files and orphaned downloads (#7)
      await DownloadHelpers.autoCleanup(
        downloadDir: _downloadDir,
        getValidKeys: () async {
          final downloads = await getAllDownloads();
          return downloads.map((d) => '${d.sessionId}_${d.language}').toList();
        },
      );

      // Notify listeners of current downloads
      await _notifyDownloadsChanged();

      debugPrint('✅ [DownloadService] Initialized successfully');
      debugPrint('   User: ${userId.substring(0, 8)}...');
      debugPrint('   Directory: ${_downloadDir?.path}');
    } catch (e) {
      debugPrint('❌ [DownloadService] Initialization error: $e');
      rethrow;
    }
  }

  /// Setup download directory
  Future<void> _setupDownloadDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    _downloadDir = Directory(path.join(appDir.path, 'insidex_downloads'));

    if (!await _downloadDir!.exists()) {
      await _downloadDir!.create(recursive: true);
      debugPrint('📁 [DownloadService] Created download directory');
    }
  }

  // =================== DOWNLOAD OPERATIONS ===================

  /// Start downloading a session
  Future<bool> downloadSession({
    required Map<String, dynamic> sessionData,
    required String language,
  }) async {
    if (!_isInitialized) {
      debugPrint('❌ [DownloadService] Not initialized');
      return false;
    }

    final sessionId = sessionData['id'] as String?;
    if (sessionId == null) {
      debugPrint('❌ [DownloadService] Session ID is null');
      return false;
    }

    final key = '${sessionId}_$language';

    // Check if already downloaded
    if (await isDownloaded(sessionId, language)) {
      debugPrint('ℹ️ [DownloadService] Already downloaded: $key');
      return true;
    }

    // Check if already in queue
    if (_queue.containsKey(key)) {
      debugPrint('ℹ️ [DownloadService] Already in queue: $key');
      return true;
    }

    // Check connectivity
    if (_connectivity.isOffline) {
      debugPrint('❌ [DownloadService] No internet connection');
      _emitProgress(key, 0, DownloadStatus.failed,
          error: 'No internet connection');
      return false;
    }

    // Add to queue
    final queueItem = DownloadQueueItem(
      sessionId: sessionId,
      sessionData: sessionData,
      language: language,
      status: DownloadStatus.pending,
    );
    _queue[key] = queueItem;

    debugPrint('📥 [DownloadService] Added to queue: $key');

    // Start processing queue
    _processQueue();

    return true;
  }

  /// Process download queue
  Future<void> _processQueue() async {
    // If already processing, skip
    if (_activeDownloadKey != null) return;

    // Find next pending item
    final pendingEntry = _queue.entries.firstWhere(
      (entry) => entry.value.status == DownloadStatus.pending,
      orElse: () => MapEntry(
          '',
          DownloadQueueItem(
            sessionId: '',
            sessionData: {},
            language: '',
            status: DownloadStatus.completed,
          )),
    );

    if (pendingEntry.key.isEmpty) {
      debugPrint('📥 [DownloadService] Queue empty');
      return;
    }

    _activeDownloadKey = pendingEntry.key;
    final item = pendingEntry.value;

    try {
      await _executeDownload(item);
    } catch (e) {
      debugPrint('❌ [DownloadService] Download failed: $e');
      item.status = DownloadStatus.failed;
      item.errorMessage = e.toString();
      _emitProgress(item.key, 0, DownloadStatus.failed, error: e.toString());
    } finally {
      _activeDownloadKey = null;
      _queue.remove(pendingEntry.key);

      // Process next in queue
      _processQueue();
    }
  }

  /// Execute download for a queue item
  Future<void> _executeDownload(DownloadQueueItem item) async {
    final sessionData = item.sessionData;
    final language = item.language;
    final key = item.key;

    debugPrint('📥 [DownloadService] Starting download: $key');
    _cancelFlags.remove(key);

    item.status = DownloadStatus.downloading;
    _emitProgress(key, 0, DownloadStatus.downloading);

    try {
      // 1. Get audio URL for language
      final audioUrl = LanguageHelperService.getAudioUrl(
        sessionData['subliminal']?['audioUrls'],
        language,
      );

      if (audioUrl.isEmpty) {
        throw DownloadException('Audio URL not found for language: $language');
      }

      final estimatedSize = await DownloadHelpers.getRemoteFileSize(audioUrl);
      if (estimatedSize > 0) {
        final hasSpace =
            await DownloadHelpers.hasEnoughDiskSpace(estimatedSize);
        if (!hasSpace) {
          throw DownloadException('Not enough disk space');
        }
      }

      // 2. Get image URL for language
      final imageUrl = LanguageHelperService.getImageUrl(
        sessionData['backgroundImages'],
        language,
      );

      // 3. Get localized title
      final localizedContent = SessionLocalizationService.getLocalizedContent(
        sessionData,
        language,
      );
      final title = localizedContent.title;
      final description = localizedContent.description;
      final introTitle = localizedContent.introduction.title;
      final introContent = localizedContent.introduction.content;
      final sessionNumber = sessionData['sessionNumber'] as int?;
      final displayTitle =
          sessionNumber != null ? '$sessionNumber • $title' : title;

      // 4. Get duration
      final duration = LanguageHelperService.getDuration(
        sessionData['subliminal']?['durations'],
        language,
      );

      // 5. Create session folder
      final sessionDir = Directory(path.join(_downloadDir!.path, key));
      if (!await sessionDir.exists()) {
        await sessionDir.create(recursive: true);
      }

      // 6. Download and encrypt audio
      _emitProgress(key, 0.1, DownloadStatus.downloading);
      final audioPath = await _downloadAndEncryptAudio(
        audioUrl,
        sessionDir.path,
        key,
        (progress) {
          // Map audio download progress to 10-80% of total
          final totalProgress = 0.1 + (progress * 0.7);
          _emitProgress(key, totalProgress, DownloadStatus.downloading);
        },
      );

      // 7. Download image
      _emitProgress(key, 0.85, DownloadStatus.downloading);
      final imagePath =
          await DownloadHelpers.downloadImage(imageUrl, sessionDir.path);

      // 8. Get file size
      final audioFile = File(audioPath);
      final fileSize = await audioFile.length();

      // 9. Create download record
      final download = DownloadedSession.fromSessionData(
        sessionData: sessionData,
        language: language,
        encryptedAudioPath: audioPath,
        imagePath: imagePath,
        fileSizeBytes: fileSize,
        title: displayTitle,
        durationSeconds: duration,
        description: description,
        introTitle: introTitle,
        introContent: introContent,
      );

      // 10. Save to database
      _emitProgress(key, 0.95, DownloadStatus.downloading);
      await _database.insertDownload(download);

      // 11. Complete
      item.status = DownloadStatus.completed;
      item.progress = 1.0;
      _emitProgress(key, 1.0, DownloadStatus.completed);

      // Notify listeners
      await _notifyDownloadsChanged();

      debugPrint('✅ [DownloadService] Download completed: $key');
      debugPrint('   Title: $displayTitle');
      debugPrint('   Size: ${download.formattedFileSize}');
    } catch (e) {
      debugPrint('❌ [DownloadService] Download error: $e');

      // Cleanup on failure
      final sessionDir = Directory(path.join(_downloadDir!.path, key));
      if (await sessionDir.exists()) {
        await sessionDir.delete(recursive: true);
      }

      rethrow;
    }
  }

  /// Download and encrypt audio file with retry mechanism
  Future<String> _downloadAndEncryptAudio(
    String url,
    String destinationDir,
    String key,
    void Function(double progress) onProgress,
  ) async {
    int attempt = 0;

    while (attempt < _maxRetries) {
      attempt++;

      // Don't retry if cancelled
      if (_cancelFlags[key] == true) {
        debugPrint('🛑 [DownloadService] Retry skipped - download cancelled');
        throw DownloadException('Download cancelled by user');
      }

      try {
        return await _downloadAndEncryptAudioAttempt(
          url,
          destinationDir,
          key,
          onProgress,
        );
      } catch (e) {
        debugPrint(
            '⚠️ [DownloadService] Attempt $attempt/$_maxRetries failed: $e');

        if (attempt >= _maxRetries) {
          debugPrint('❌ [DownloadService] All retry attempts exhausted');
          rethrow;
        }

        // Exponential backoff: 2s, 4s, 8s...
        final delay = _retryDelay * (1 << (attempt - 1));
        debugPrint('🔄 [DownloadService] Retrying in ${delay.inSeconds}s...');
        await Future.delayed(delay);
      }
    }

    throw DownloadException('Download failed after $_maxRetries attempts');
  }

  /// Single download attempt
  Future<String> _downloadAndEncryptAudioAttempt(
    String url,
    String destinationDir,
    String key,
    void Function(double progress) onProgress,
  ) async {
    debugPrint('📥 [DownloadService] Downloading audio: $url');

    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(url));
      final response = await client.send(request).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw DownloadException('Connection timeout');
        },
      );

      if (response.statusCode != 200) {
        throw DownloadException('HTTP error: ${response.statusCode}');
      }

      final contentLength = response.contentLength ?? 0;
      final List<int> bytes = [];
      int received = 0;

      await for (final chunk in response.stream) {
        // Check if download was cancelled
        if (_cancelFlags[key] == true) {
          client.close();
          debugPrint('🛑 [DownloadService] HTTP stream cancelled: $key');
          throw DownloadException('Download cancelled by user');
        }
        bytes.addAll(chunk);
        received += chunk.length;

        if (contentLength > 0) {
          // Throttle progress updates (max every 100ms)
          final now = DateTime.now();
          if (_lastProgressEmit == null ||
              now.difference(_lastProgressEmit!) >= _progressThrottleDuration) {
            _lastProgressEmit = now;
            onProgress(received / contentLength);
          }
        }
      }

      // Always emit final progress
      if (contentLength > 0) {
        onProgress(1.0);
      }

      debugPrint('📥 [DownloadService] Downloaded ${bytes.length} bytes');

      // Encrypt the audio in background isolate (NON-BLOCKING)
      debugPrint('🔐 [DownloadService] Encrypting in background...');
      final encryptedBytes =
          await _encryption.encryptBytesInBackground(Uint8List.fromList(bytes));

      // Save encrypted file
      final encryptedPath = path.join(destinationDir, 'audio.enc');
      final file = File(encryptedPath);
      await file.writeAsBytes(encryptedBytes, flush: true);

      debugPrint('🔐 [DownloadService] Encrypted audio saved: $encryptedPath');

      return encryptedPath;
    } finally {
      client.close();
    }
  }

  // =================== QUERY OPERATIONS ===================

  /// Check if a session is downloaded
  Future<bool> isDownloaded(String sessionId, String language) async {
    return await _database.isDownloaded(sessionId, language);
  }

  /// Check if a session is downloaded in any language
  Future<bool> isDownloadedAnyLanguage(String sessionId) async {
    return await _database.isDownloadedAnyLanguage(sessionId);
  }

  /// Get download by session ID and language
  Future<DownloadedSession?> getDownload(
      String sessionId, String language) async {
    return await _database.getBySessionAndLanguage(sessionId, language);
  }

  /// Get all downloads
  Future<List<DownloadedSession>> getAllDownloads() async {
    return await _database.getAllDownloads();
  }

  /// Get downloads for current language
  Future<List<DownloadedSession>> getDownloadsForLanguage(
      String language) async {
    return await _database.getDownloadsByLanguage(language);
  }

  /// Get download statistics
  Future<DownloadStats> getStats() async {
    return await _database.getStats();
  }

  // =================== PLAYBACK ===================

  /// Get decrypted audio for playback (returns temp file path)
  /// Uses cache to avoid re-decrypting and runs decryption in background isolate
  Future<String?> getDecryptedAudioPath(
      String sessionId, String language) async {
    try {
      final download = await getDownload(sessionId, language);
      if (download == null) {
        debugPrint(
            '❌ [DownloadService] Download not found: ${sessionId}_$language');
        return null;
      }

      final encryptedPath = download.encryptedAudioPath;

      // 1️⃣ CHECK CACHE FIRST - Return immediately if already decrypted
      final cachedPath =
          await _encryption.getCachedDecryptedPath(encryptedPath);
      if (cachedPath != null) {
        debugPrint('⚡ [DownloadService] Using cached decrypted file');
        // Update last played in background (fire and forget)
        _database.updateLastPlayed(download.id).catchError((_) => false);
        return cachedPath;
      }

      // 2️⃣ VERIFY ENCRYPTED FILE EXISTS
      final encryptedFile = File(encryptedPath);
      if (!await encryptedFile.exists()) {
        debugPrint('❌ [DownloadService] Encrypted file not found');
        return null;
      }

      // 3️⃣ PREPARE TEMP PATH
      final tempDir = await getTemporaryDirectory();
      final tempPath =
          path.join(tempDir.path, 'insidex_playback', '${download.id}.mp3');

      final tempFileDir = Directory(path.dirname(tempPath));
      if (!await tempFileDir.exists()) {
        await tempFileDir.create(recursive: true);
      }

      // 4️⃣ CHECK IF TEMP FILE ALREADY EXISTS (from previous session)
      final tempFile = File(tempPath);
      if (await tempFile.exists() && await tempFile.length() > 0) {
        debugPrint('⚡ [DownloadService] Temp file already exists');
        _encryption.cacheDecryptedPath(encryptedPath, tempPath);
        _database.updateLastPlayed(download.id).catchError((_) => false);
        return tempPath;
      }

      // 5️⃣ DECRYPT IN BACKGROUND ISOLATE (NON-BLOCKING)
      debugPrint('🔓 [DownloadService] Decrypting in background...');

      final encryptedBytes = await encryptedFile.readAsBytes();

      // Run decryption in isolate - THIS IS THE KEY CHANGE
      final decryptedBytes =
          await _encryption.decryptBytesInBackground(encryptedBytes);

      // Write to temp file
      await tempFile.writeAsBytes(decryptedBytes, flush: true);

      // 6️⃣ CACHE THE RESULT
      _encryption.cacheDecryptedPath(encryptedPath, tempPath);

      // Update last played in background
      _database.updateLastPlayed(download.id).catchError((_) => false);

      debugPrint('✅ [DownloadService] Decrypted for playback: $tempPath');
      return tempPath;
    } catch (e) {
      debugPrint('❌ [DownloadService] Decryption error: $e');
      return null;
    }
  }

  /// Clean up temp playback files
  Future<void> cleanupTempFiles() async {
    await DownloadHelpers.cleanupTempFiles();
  }

  // =================== DELETE OPERATIONS ===================

  /// Delete a download
  Future<bool> deleteDownload(String sessionId, String language) async {
    final key = '${sessionId}_$language';

    try {
      // Get download info first
      final download = await getDownload(sessionId, language);
      if (download == null) {
        debugPrint('ℹ️ [DownloadService] Download not found: $key');
        return false;
      }

      // Delete from database
      await _database.deleteBySessionAndLanguage(sessionId, language);

      // Delete files
      final sessionDir = Directory(path.join(_downloadDir!.path, key));
      if (await sessionDir.exists()) {
        await sessionDir.delete(recursive: true);
        debugPrint('🗑️ [DownloadService] Deleted files: $key');
      }

      // Notify listeners
      await _notifyDownloadsChanged();

      debugPrint('✅ [DownloadService] Download deleted: $key');
      return true;
    } catch (e) {
      debugPrint('❌ [DownloadService] Delete error: $e');
      return false;
    }
  }

  /// Delete all downloads
  Future<int> deleteAllDownloads() async {
    try {
      // Delete from database
      final count = await _database.deleteAllDownloads();

      // Delete all files
      if (_downloadDir != null && await _downloadDir!.exists()) {
        await _downloadDir!.delete(recursive: true);
        await _downloadDir!.create(recursive: true);
      }

      // Notify listeners
      await _notifyDownloadsChanged();

      debugPrint('🗑️ [DownloadService] Deleted all downloads: $count');
      return count;
    } catch (e) {
      debugPrint('❌ [DownloadService] Delete all error: $e');
      return 0;
    }
  }

  // =================== QUEUE MANAGEMENT ===================

  /// Cancel a download in progress
  Future<bool> cancelDownload(String sessionId, String language) async {
    final key = '${sessionId}_$language';

    _cancelFlags[key] = true;

    // Check if in queue
    if (!_queue.containsKey(key)) {
      debugPrint('ℹ️ [DownloadService] Download not in queue: $key');
      return false;
    }

    debugPrint('🛑 [DownloadService] Cancelling download: $key');

    // Remove from queue
    _queue.remove(key);

    // Clear active download if this is the one
    if (_activeDownloadKey == key) {
      _activeDownloadKey = null;
    }

    // Clean up partial files
    try {
      final sessionDir = Directory(path.join(_downloadDir!.path, key));
      if (await sessionDir.exists()) {
        await sessionDir.delete(recursive: true);
        debugPrint('🧹 [DownloadService] Cleaned up partial files: $key');
      }
    } catch (e) {
      debugPrint('⚠️ [DownloadService] Cleanup error: $e');
    }

    // Emit cancelled status
    _emitProgress(key, 0, DownloadStatus.failed, error: 'Cancelled');
    debugPrint('✅ [DownloadService] Download cancelled: $key');
    return true;
  }

  /// Get current queue
  List<DownloadQueueItem> getQueue() {
    return _queue.values.toList();
  }

  /// Check if a download is in progress
  bool isDownloading(String sessionId, String language) {
    final key = '${sessionId}_$language';
    return _queue.containsKey(key) &&
        _queue[key]!.status == DownloadStatus.downloading;
  }

  /// Check if a download is pending
  bool isPending(String sessionId, String language) {
    final key = '${sessionId}_$language';
    return _queue.containsKey(key);
  }

  /// Emit progress update
  void _emitProgress(
    String key,
    double progress,
    DownloadStatus status, {
    String? error,
  }) {
    if (!_progressController.isClosed) {
      _progressController.add(DownloadProgress(
        key: key,
        progress: progress,
        status: status,
        error: error,
      ));
    }
  }

  /// Notify downloads list changed
  Future<void> _notifyDownloadsChanged() async {
    if (!_downloadsController.isClosed) {
      final downloads = await getAllDownloads();
      _downloadsController.add(downloads);
    }
  }

  /// Dispose the service
  void dispose() {
    _progressController.close();
    _downloadsController.close();
    _connectivity.dispose();
    _encryption.clear();
    _isInitialized = false;
    debugPrint('📥 [DownloadService] Disposed');
  }

  /// Clear user data (on logout)
  Future<void> clearUserData() async {
    _encryption.clear();
    _currentUserId = null;
    _isInitialized = false;
    debugPrint('📥 [DownloadService] User data cleared');
  }
}

/// Download progress model
class DownloadProgress {
  final String key;
  final double progress;
  final DownloadStatus status;
  final String? error;

  const DownloadProgress({
    required this.key,
    required this.progress,
    required this.status,
    this.error,
  });

  /// Get progress percentage (0-100)
  int get percentage => (progress * 100).round();

  @override
  String toString() {
    return 'DownloadProgress(key: $key, progress: $percentage%, status: $status)';
  }
}

/// Download exception
class DownloadException implements Exception {
  final String message;

  DownloadException(this.message);

  @override
  String toString() => 'DownloadException: $message';
}
