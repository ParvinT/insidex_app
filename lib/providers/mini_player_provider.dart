// lib/providers/mini_player_provider.dart

import 'package:flutter/material.dart';
import 'dart:async';
import '../services/language_helper_service.dart';

/// Global state provider for mini player
/// Manages session data, playback state, and UI state
class MiniPlayerProvider extends ChangeNotifier {
  // =================== SESSION DATA ===================
  Map<String, dynamic>? _currentSession;
  Map<String, dynamic>? get currentSession => _currentSession;

  // =================== PLAYBACK STATE ===================
  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  bool _isAtTop = false;
  bool get isAtTop => _isAtTop;

  Duration _position = Duration.zero;
  Duration get position => _position;

  Duration _duration = Duration.zero;
  Duration get duration => _duration;

  String _currentTrack = 'intro'; // 'intro' or 'subliminal'
  String get currentTrack => _currentTrack;

  // =================== UI STATE ===================
  bool _isVisible = false;
  bool get isVisible => _isVisible;

  bool _isExpanded = false;
  bool get isExpanded => _isExpanded;

  bool _isDragging = false;
  bool get isDragging => _isDragging;

  double _dragOffset = 0.0; // 0.0 = collapsed at bottom, 1.0 = full screen
  double get dragOffset => _dragOffset;

  // =================== STREAM SUBSCRIPTIONS ===================
  StreamSubscription? _playingSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _durationSubscription;

  // =================== INIT & DISPOSE ===================
  MiniPlayerProvider() {
    debugPrint('[MiniPlayerProvider] Initialized');
  }

  @override
  void dispose() {
    _playingSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    debugPrint('[MiniPlayerProvider] Disposed');
    super.dispose();
  }

  // =================== SESSION MANAGEMENT ===================

  /// Start playing a new session and show mini player
  void playSession(Map<String, dynamic> sessionData) {
    _currentSession = sessionData;
    _isVisible = true;
    _isExpanded = false;
    _position = Duration.zero;
    _currentTrack = 'subliminal';

    debugPrint('[MiniPlayer] Session started: ${sessionData['title']}');
    notifyListeners();
  }

  /// Update current session data (e.g., when switching tracks)
  void updateSession(Map<String, dynamic> sessionData) {
    _currentSession = sessionData;
    notifyListeners();
  }

  /// Set current track (intro or subliminal)
  void setCurrentTrack(String track) {
    if (track == 'intro' || track == 'subliminal') {
      _currentTrack = track;
      notifyListeners();
    }
  }

  // =================== PLAYBACK CONTROL ===================

  /// Update playing state
  void setPlayingState(bool playing) {
    _isPlaying = playing;
    notifyListeners();
  }

  /// Update playback position
  void updatePosition(Duration pos) {
    _position = pos;
    notifyListeners();
  }

  /// Update total duration
  void updateDuration(Duration dur) {
    _duration = dur;
    notifyListeners();
  }

  /// Get progress as percentage (0.0 to 1.0)
  double get progress {
    if (_duration.inMilliseconds == 0) return 0.0;
    final prog =
        (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0);
    // debugPrint('📊 Progress: ${(prog * 100).toStringAsFixed(1)}% (${_position.inSeconds}s / ${_duration.inSeconds}s)');
    return prog;
  }

  // =================== UI CONTROL ===================

  /// Show mini player
  void show() {
    _isVisible = true;
    notifyListeners();
  }

  /// Hide mini player
  void hide() {
    _isVisible = false;
    _isExpanded = false;
    notifyListeners();
  }

  /// Dismiss mini player and stop session
  void dismiss() {
    _currentSession = null;
    _isVisible = false;
    _isExpanded = false;
    _isAtTop = false;
    _position = Duration.zero;
    _duration = Duration.zero;
    _isPlaying = false;

    debugPrint('[MiniPlayer] Dismissed');
    notifyListeners();
  }

  /// Toggle expanded state
  void toggleExpanded() {
    _isExpanded = !_isExpanded;
    notifyListeners();
  }

  /// Expand mini player controls
  void expand() {
    _isExpanded = true;
    notifyListeners();
  }

  /// Collapse mini player controls
  void collapse() {
    _isExpanded = false;
    notifyListeners();
  }

  // =================== POSITION CONTROL ===================  // ✅ YENİ BÖLÜM

  /// Set mini player at top
  void setAtTop(bool value) {
    _isAtTop = value;
    debugPrint('[MiniPlayer] Position: ${value ? "TOP" : "BOTTOM"}');
    notifyListeners();
  }

  /// Toggle position (top/bottom)
  void togglePosition() {
    _isAtTop = !_isAtTop;
    notifyListeners();
  }

  // =================== DRAG CONTROL ===================

  /// Start dragging
  void startDrag() {
    _isDragging = true;
    notifyListeners();
  }

  /// Update drag offset (0.0 to 1.0)
  void updateDragOffset(double offset) {
    _dragOffset = offset.clamp(0.0, 1.0);
    notifyListeners();
  }

  /// End dragging with snap decision
  void endDrag() {
    _isDragging = false;

    // Snap logic: if dragged more than 50%, expand; otherwise collapse
    if (_dragOffset > 0.5) {
      _dragOffset = 1.0;
      _isExpanded = true;
    } else {
      _dragOffset = 0.0;
      _isExpanded = false;
    }

    notifyListeners();
  }

  // =================== HELPER METHODS ===================

  /// Get formatted time string
  String formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  /// Get session title safely
  String get sessionTitle {
    if (_currentSession == null) return 'Unknown Session';

    // Try localized title first (WITHOUT number - clean for mini player)
    if (_currentSession!.containsKey('_localizedTitle')) {
      final localizedTitle = _currentSession!['_localizedTitle'];
      if (localizedTitle != null && localizedTitle.toString().isNotEmpty) {
        return localizedTitle.toString();
      }
    }

    // Fallback: old structure
    return _currentSession!['title'] ?? 'Unknown Session';
  }

  /// Get session image URL safely
  String? _cachedImageUrl;
  String? _cachedImageSessionId;
  bool get isOfflineSession => _currentSession?['_isOffline'] == true;

  /// Get local image path for offline sessions
  String? get localImagePath => _currentSession?['_localImagePath'] as String?;

  String? get sessionImageUrl {
    if (_currentSession == null) return null;

    if (isOfflineSession) {
      return null;
    }

    final sessionId = _currentSession!['id'];

    // Return cached if same session
    if (_cachedImageUrl != null && _cachedImageSessionId == sessionId) {
      return _cachedImageUrl;
    }

    // Calculate image URL
    final backgroundImages = _currentSession!['backgroundImages'];
    String? imageUrl;

    if (backgroundImages is Map) {
      // Try to get from current language (sync - may not be accurate but fast)
      // We'll use a default priority: en > tr > ru > hi
      imageUrl = backgroundImages['en'] ??
          backgroundImages['tr'] ??
          backgroundImages['ru'] ??
          backgroundImages['hi'] ??
          backgroundImages.values.first;
    } else {
      // Fallback to old structure
      imageUrl = _currentSession!['backgroundImage'];
    }

    // Cache it
    _cachedImageUrl = imageUrl;
    _cachedImageSessionId = sessionId;

    return imageUrl;
  }

  /// Call this when session changes to load correct language image
  Future<void> updateImageUrlForLanguage() async {
    if (_currentSession == null) return;

    final backgroundImages = _currentSession!['backgroundImages'];
    if (backgroundImages is Map) {
      final userLanguage = await LanguageHelperService.getCurrentLanguage();
      final imageUrl = backgroundImages[userLanguage] ??
          backgroundImages['en'] ??
          backgroundImages.values.first;

      if (_cachedImageUrl != imageUrl) {
        _cachedImageUrl = imageUrl;
        notifyListeners();
      }
    }
  }

  /// Check if session is active
  bool get hasActiveSession => _currentSession != null;
}
