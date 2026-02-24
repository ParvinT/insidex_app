// lib/models/play_context.dart

/// Defines the source context for audio playback queue.
///
/// When a user starts playing a session, the PlayContext tells the player
/// where the session came from and what other sessions are in the queue.
/// This enables auto-play of the next session when the current one finishes.
enum PlayContextType {
  /// Playing from a category's session list
  category,

  /// Playing from a user's playlist
  playlist,

  /// Playing from the "All Sessions" list
  allSessions,

  /// Playing from search results
  search,

  /// Single session with no queue (quiz result, direct link, etc.)
  single,
}

class PlayContext {
  /// The type of context this session was started from
  final PlayContextType type;

  /// Source identifier (categoryId, playlistId, etc.)
  final String? sourceId;

  /// Source display name (category title, playlist name, etc.)
  final String? sourceTitle;

  /// Ordered list of sessions in the queue
  final List<Map<String, dynamic>> sessionList;

  /// Current index in the session list
  final int currentIndex;

  const PlayContext({
    required this.type,
    this.sourceId,
    this.sourceTitle,
    required this.sessionList,
    required this.currentIndex,
  });

  /// Whether there is a next session in the queue
  bool get hasNext => currentIndex < sessionList.length - 1;

  /// Whether there is a previous session in the queue
  bool get hasPrevious => currentIndex > 0;

  /// Get the next session data, or null if at end of queue
  Map<String, dynamic>? get nextSession {
    if (!hasNext) return null;
    return sessionList[currentIndex + 1];
  }

  /// Get the previous session data, or null if at start of queue
  Map<String, dynamic>? get previousSession {
    if (!hasPrevious) return null;
    return sessionList[currentIndex - 1];
  }

  /// Get the current session data
  Map<String, dynamic>? get currentSession {
    if (currentIndex < 0 || currentIndex >= sessionList.length) return null;
    return sessionList[currentIndex];
  }

  /// Total number of sessions in the queue
  int get totalSessions => sessionList.length;

  /// Human-readable position (e.g., "3 / 12")
  String get positionLabel => '${currentIndex + 1} / $totalSessions';

  /// Whether this context supports auto-play
  bool get supportsAutoPlay => type != PlayContextType.single;

  /// Create a new PlayContext with updated index (for next/previous)
  PlayContext copyWithIndex(int newIndex) {
    return PlayContext(
      type: type,
      sourceId: sourceId,
      sourceTitle: sourceTitle,
      sessionList: sessionList,
      currentIndex: newIndex,
    );
  }

  /// Create a single-session context (no queue)
  factory PlayContext.single() {
    return const PlayContext(
      type: PlayContextType.single,
      sessionList: [],
      currentIndex: 0,
    );
  }

  @override
  String toString() {
    return 'PlayContext(type: ${type.name}, source: $sourceId, '
        'index: $currentIndex/$totalSessions, hasNext: $hasNext)';
  }
}
