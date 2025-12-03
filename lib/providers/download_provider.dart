// lib/providers/download_provider.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/downloaded_session.dart';
import '../services/download/download_service.dart';
import '../services/download/download_database.dart';
import '../services/download/connectivity_service.dart';

/// Provider for managing download state across the app
class DownloadProvider extends ChangeNotifier {
  final DownloadService _downloadService = DownloadService();
  final ConnectivityService _connectivityService = ConnectivityService();

  // State
  List<DownloadedSession> _downloads = [];
  Map<String, DownloadProgress> _activeDownloads = {};
  DownloadStats? _stats;
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _error;

  // Connectivity state
  ConnectivityStatus _connectivityStatus = ConnectivityStatus.unknown;

  // Subscriptions
  StreamSubscription<List<DownloadedSession>>? _downloadsSubscription;
  StreamSubscription<DownloadProgress>? _progressSubscription;
  StreamSubscription<ConnectivityStatus>? _connectivitySubscription;

  // Getters
  List<DownloadedSession> get downloads => _downloads;
  Map<String, DownloadProgress> get activeDownloads => _activeDownloads;
  DownloadStats? get stats => _stats;
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasDownloads => _downloads.isNotEmpty;
  int get downloadCount => _downloads.length;
  Stream<DownloadProgress> get progressStream =>
      _downloadService.progressStream;

  // Connectivity getters
  ConnectivityStatus get connectivityStatus => _connectivityStatus;
  bool get isOnline => _connectivityStatus == ConnectivityStatus.online;
  bool get isOffline => _connectivityStatus == ConnectivityStatus.offline;

  /// Initialize the provider
  Future<void> initialize(String userId) async {
    if (_isInitialized) return;

    debugPrint('📥 [DownloadProvider] Initializing...');

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Initialize download service
      await _downloadService.initialize(userId);

      // Subscribe to downloads stream
      _downloadsSubscription = _downloadService.downloadsStream.listen(
        _onDownloadsChanged,
        onError: (e) =>
            debugPrint('❌ [DownloadProvider] Downloads stream error: $e'),
      );

      // Subscribe to progress stream
      _progressSubscription = _downloadService.progressStream.listen(
        _onProgressChanged,
        onError: (e) =>
            debugPrint('❌ [DownloadProvider] Progress stream error: $e'),
      );

      // Subscribe to connectivity stream
      _connectivitySubscription = _connectivityService.statusStream.listen(
        _onConnectivityChanged,
        onError: (e) =>
            debugPrint('❌ [DownloadProvider] Connectivity stream error: $e'),
      );

      // Get initial connectivity status
      _connectivityStatus = _connectivityService.currentStatus;

      // Load initial data
      await _loadDownloads();
      await _loadStats();

      _isInitialized = true;
      _isLoading = false;
      notifyListeners();

      debugPrint(
          '✅ [DownloadProvider] Initialized with ${_downloads.length} downloads');
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('❌ [DownloadProvider] Initialization error: $e');
    }
  }

  /// Handle downloads list changes
  void _onDownloadsChanged(List<DownloadedSession> downloads) {
    _downloads = downloads;
    _loadStats();
    notifyListeners();
  }

  /// Handle download progress changes
  void _onProgressChanged(DownloadProgress progress) {
    if (progress.status == DownloadStatus.completed ||
        progress.status == DownloadStatus.failed) {
      _activeDownloads.remove(progress.key);
    } else {
      _activeDownloads[progress.key] = progress;
    }
    notifyListeners();
  }

  /// Handle connectivity changes
  void _onConnectivityChanged(ConnectivityStatus status) {
    _connectivityStatus = status;
    notifyListeners();
    debugPrint('🌐 [DownloadProvider] Connectivity: $status');
  }

  /// Load downloads from database
  Future<void> _loadDownloads() async {
    _downloads = await _downloadService.getAllDownloads();
  }

  /// Load download statistics
  Future<void> _loadStats() async {
    _stats = await _downloadService.getStats();
  }

  /// Refresh downloads
  Future<void> refresh() async {
    await _loadDownloads();
    await _loadStats();
    notifyListeners();
  }

  // =================== DOWNLOAD OPERATIONS ===================

  /// Start downloading a session
  Future<bool> downloadSession({
    required Map<String, dynamic> sessionData,
    required String language,
  }) async {
    if (!_isInitialized) {
      debugPrint('❌ [DownloadProvider] Not initialized');
      return false;
    }

    if (isOffline) {
      debugPrint('❌ [DownloadProvider] Offline, cannot download');
      return false;
    }

    return await _downloadService.downloadSession(
      sessionData: sessionData,
      language: language,
    );
  }

  /// Cancel a download
  Future<bool> cancelDownload(String sessionId, String language) async {
    final result = await _downloadService.cancelDownload(sessionId, language);
    if (result) {
      _activeDownloads.remove('${sessionId}_$language');
      notifyListeners();
    }
    return result;
  }

  /// Delete a download
  Future<bool> deleteDownload(String sessionId, String language) async {
    final result = await _downloadService.deleteDownload(sessionId, language);
    if (result) {
      await refresh();
    }
    return result;
  }

  /// Delete all downloads
  Future<int> deleteAllDownloads() async {
    final count = await _downloadService.deleteAllDownloads();
    await refresh();
    return count;
  }

  // =================== QUERY OPERATIONS ===================

  /// Check if a session is downloaded
  Future<bool> isDownloaded(String sessionId, String language) async {
    return await _downloadService.isDownloaded(sessionId, language);
  }

  /// Check if a session is downloaded in any language
  Future<bool> isDownloadedAnyLanguage(String sessionId) async {
    return await _downloadService.isDownloadedAnyLanguage(sessionId);
  }

  /// Get download by session ID and language
  Future<DownloadedSession?> getDownload(
      String sessionId, String language) async {
    return await _downloadService.getDownload(sessionId, language);
  }

  /// Get downloads for a specific language
  Future<List<DownloadedSession>> getDownloadsForLanguage(
      String language) async {
    return await _downloadService.getDownloadsForLanguage(language);
  }

  /// Check if download is in progress
  bool isDownloading(String sessionId, String language) {
    final key = '${sessionId}_$language';
    return _activeDownloads.containsKey(key);
  }

  /// Get download progress for a session
  DownloadProgress? getProgress(String sessionId, String language) {
    final key = '${sessionId}_$language';
    return _activeDownloads[key];
  }

  /// Get download status for a session
  Future<DownloadButtonState> getDownloadState(
    String sessionId,
    String language,
  ) async {
    // Check if downloading
    if (isDownloading(sessionId, language)) {
      final progress = getProgress(sessionId, language);
      return DownloadButtonState.downloading(progress?.progress ?? 0);
    }

    // Check if downloaded
    final isDownloaded = await this.isDownloaded(sessionId, language);
    if (isDownloaded) {
      return DownloadButtonState.downloaded();
    }

    // Not downloaded
    return DownloadButtonState.notDownloaded();
  }

  // =================== PLAYBACK ===================

  /// Get decrypted audio path for playback
  Future<String?> getDecryptedAudioPath(
      String sessionId, String language) async {
    return await _downloadService.getDecryptedAudioPath(sessionId, language);
  }

  /// Clean up temp playback files
  Future<void> cleanupTempFiles() async {
    await _downloadService.cleanupTempFiles();
  }

  // =================== LIFECYCLE ===================

  /// Clear user data (on logout)
  Future<void> clearUserData() async {
    await _downloadService.clearUserData();
    _downloads = [];
    _activeDownloads = {};
    _stats = null;
    _isInitialized = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _downloadsSubscription?.cancel();
    _progressSubscription?.cancel();
    _connectivitySubscription?.cancel();
    _downloadService.dispose();
    super.dispose();
  }
}

/// Download button state
class DownloadButtonState {
  final DownloadStateType type;
  final double progress;

  const DownloadButtonState._({
    required this.type,
    this.progress = 0,
  });

  factory DownloadButtonState.notDownloaded() {
    return const DownloadButtonState._(type: DownloadStateType.notDownloaded);
  }

  factory DownloadButtonState.downloading(double progress) {
    return DownloadButtonState._(
      type: DownloadStateType.downloading,
      progress: progress,
    );
  }

  factory DownloadButtonState.downloaded() {
    return const DownloadButtonState._(type: DownloadStateType.downloaded);
  }

  bool get isNotDownloaded => type == DownloadStateType.notDownloaded;
  bool get isDownloading => type == DownloadStateType.downloading;
  bool get isDownloaded => type == DownloadStateType.downloaded;
}

/// Download state type
enum DownloadStateType {
  notDownloaded,
  downloading,
  downloaded,
}
