// lib/providers/mini_player_provider.dart

import 'package:flutter/material.dart';
import 'dart:async';
import '../services/language_helper_service.dart';
import '../models/play_context.dart';

/// Global state provider for mini player
/// Manages session data, playback state, and UI state
class MiniPlayerProvider extends ChangeNotifier {
  // =================== SESSION DATA ===================
  Map<String, dynamic>? _currentSession;
  Map<String, dynamic>? get currentSession => _currentSession;

  // =================== QUEUE / PLAY CONTEXT ===================
  PlayContext? _playContext;
  PlayContext? get playContext => _playContext;

  // =================== PLAYBACK STATE ===================
  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  bool _isAtTop = false;
  bool get isAtTop => _isAtTop;

  Duration _position = Duration.zero;
  Duration get position => _position;

  Duration _duration = Duration.zero;
  Duration get duration => _duration;

  String _currentTrack = 'intro';
  String get currentTrack => _currentTrack;

  // =================== UI STATE ===================
  bool _isVisible = false;
  bool get isVisible => _isVisible;

  bool _isExpanded = false;
  bool get isExpanded => _isExpanded;

  bool _isDragging = false;
  bool get isDragging => _isDragging;

  double _dragOffset = 0.0;
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
    _cachedImageUrl = null;
    _cachedImageSessionId = null;

    debugPrint('[MiniPlayer] Session started: ${sessionData['title']}');
    notifyListeners();
  }

  /// Update current session data (e.g., when switching tracks)
  void updateSession(Map<String, dynamic> sessionData) {
    _currentSession = sessionData;
    _cachedImageUrl = null;
    _cachedImageSessionId = null;
    notifyListeners();
  }

  /// Set current track (intro or subliminal)
  void setCurrentTrack(String track) {
    if (track == 'intro' || track == 'subliminal') {
      _currentTrack = track;
      notifyListeners();
    }
  }

  // =================== QUEUE MANAGEMENT ===================

  /// Set the play context (queue) for auto-play
  void setPlayContext(PlayContext? context) {
    _playContext = context;
    debugPrint('[MiniPlayer] PlayContext set: $context');
    notifyListeners();
  }

  // =================== AUTO-PLAY TRANSITION ===================

  bool _isAutoPlayTransitioning = false;
  bool get isAutoPlayTransitioning => _isAutoPlayTransitioning;

  void setAutoPlayTransitioning(bool value) {
    _isAutoPlayTransitioning = value;
    debugPrint('[MiniPlayer] Auto-play transitioning: $value');
  }

  /// Whether there is a next session in the queue
  bool get hasNext => _playContext?.hasNext ?? false;

  /// Whether there is a previous session in the queue
  bool get hasPrevious => _playContext?.hasPrevious ?? false;

  /// Whether auto-play is supported in current context
  bool get supportsAutoPlay => _playContext?.supportsAutoPlay ?? false;

  /// Get next session info for "Up Next" display
  Map<String, dynamic>? get nextSession => _playContext?.nextSession;

  /// Queue position label (e.g., "3 / 12")
  String? get queuePositionLabel => _playContext?.positionLabel;

  /// Advance to the next session in the queue
  /// Returns the next session data, or null if at end
  Map<String, dynamic>? playNext() {
    if (_playContext == null || !_playContext!.hasNext) {
      debugPrint('[MiniPlayer] No next session in queue');
      return null;
    }

    final nextIndex = _playContext!.currentIndex + 1;
    _playContext = _playContext!.copyWithIndex(nextIndex);
    final nextSession = _playContext!.currentSession;

    if (nextSession != null) {
      _currentSession = nextSession;
      _position = Duration.zero;
      _duration = Duration.zero;
      _cachedImageUrl = null;
      _cachedImageSessionId = null;

      debugPrint(
        '[MiniPlayer] Playing next: ${nextSession['title']} '
        '(${_playContext!.positionLabel})',
      );
      notifyListeners();
    }

    return nextSession;
  }

  /// Go back to the previous session in the queue
  /// Returns the previous session data, or null if at start
  Map<String, dynamic>? playPrevious() {
    if (_playContext == null || !_playContext!.hasPrevious) {
      debugPrint('[MiniPlayer] No previous session in queue');
      return null;
    }

    final prevIndex = _playContext!.currentIndex - 1;
    _playContext = _playContext!.copyWithIndex(prevIndex);
    final prevSession = _playContext!.currentSession;

    if (prevSession != null) {
      _currentSession = prevSession;
      _position = Duration.zero;
      _duration = Duration.zero;
      _cachedImageUrl = null;
      _cachedImageSessionId = null;

      debugPrint(
        '[MiniPlayer] Playing previous: ${prevSession['title']} '
        '(${_playContext!.positionLabel})',
      );
      notifyListeners();
    }

    return prevSession;
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
    _playContext = null;
    _isVisible = false;
    _isExpanded = false;
    _isAtTop = false;
    _position = Duration.zero;
    _duration = Duration.zero;
    _isPlaying = false;
    _isAutoPlayTransitioning = false;

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

    final preComputedUrl = _currentSession!['_backgroundImageUrl'];
    if (preComputedUrl != null && preComputedUrl.toString().isNotEmpty) {
      return preComputedUrl.toString();
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
      final currentLanguage = _currentSession!['_currentLanguage'] as String?;

      if (currentLanguage != null &&
          backgroundImages[currentLanguage] != null) {
        imageUrl = backgroundImages[currentLanguage];
      } else {
        // Fallback: default priority
        imageUrl = backgroundImages['en'] ??
            backgroundImages['tr'] ??
            backgroundImages['ru'] ??
            backgroundImages['hi'] ??
            backgroundImages.values.first;
      }
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
