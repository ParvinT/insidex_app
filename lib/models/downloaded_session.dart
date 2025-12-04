// lib/models/downloaded_session.dart

/// Model for downloaded/offline sessions
/// Stores all necessary data to play a session without internet
class DownloadedSession {
  final String id;
  final String sessionId;
  final String language;
  final String encryptedAudioPath;
  final String imagePath;
  final String title;
  final String artist;
  final int durationSeconds;
  final int fileSizeBytes;
  final DateTime downloadedAt;
  final DateTime lastPlayedAt;
  final DownloadStatus status;
  final double progress;

  // Original session metadata for UI
  final String? categoryId;
  final String? categoryName;
  final int? sessionNumber;
  final String? description;
  final String? introTitle;
  final String? introContent;

  const DownloadedSession({
    required this.id,
    required this.sessionId,
    required this.language,
    required this.encryptedAudioPath,
    required this.imagePath,
    required this.title,
    required this.artist,
    required this.durationSeconds,
    required this.fileSizeBytes,
    required this.downloadedAt,
    required this.lastPlayedAt,
    this.status = DownloadStatus.completed,
    this.progress = 1.0,
    this.categoryId,
    this.categoryName,
    this.sessionNumber,
    this.description,
    this.introTitle,
    this.introContent,
  });

  /// Create from SQLite row
  factory DownloadedSession.fromMap(Map<String, dynamic> map) {
    return DownloadedSession(
      id: map['id'] as String,
      sessionId: map['session_id'] as String,
      language: map['language'] as String,
      encryptedAudioPath: map['encrypted_audio_path'] as String,
      imagePath: map['image_path'] as String,
      title: map['title'] as String,
      artist: map['artist'] as String? ?? 'INSIDEX',
      durationSeconds: map['duration_seconds'] as int,
      fileSizeBytes: map['file_size_bytes'] as int,
      downloadedAt:
          DateTime.fromMillisecondsSinceEpoch(map['downloaded_at'] as int),
      lastPlayedAt:
          DateTime.fromMillisecondsSinceEpoch(map['last_played_at'] as int),
      status: DownloadStatus.fromString(map['status'] as String),
      progress: (map['progress'] as num?)?.toDouble() ?? 1.0,
      categoryId: map['category_id'] as String?,
      categoryName: map['category_name'] as String?,
      sessionNumber: map['session_number'] as int?,
      description: map['description'] as String?,
      introTitle: map['intro_title'] as String?,
      introContent: map['intro_content'] as String?,
    );
  }

  /// Convert to SQLite row
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'language': language,
      'encrypted_audio_path': encryptedAudioPath,
      'image_path': imagePath,
      'title': title,
      'artist': artist,
      'duration_seconds': durationSeconds,
      'file_size_bytes': fileSizeBytes,
      'downloaded_at': downloadedAt.millisecondsSinceEpoch,
      'last_played_at': lastPlayedAt.millisecondsSinceEpoch,
      'status': status.value,
      'progress': progress,
      'category_id': categoryId,
      'category_name': categoryName,
      'session_number': sessionNumber,
      'description': description,
      'intro_title': introTitle,
      'intro_content': introContent,
    };
  }

  /// Create from Firebase session data (for downloading)
  factory DownloadedSession.fromSessionData({
    required Map<String, dynamic> sessionData,
    required String language,
    required String encryptedAudioPath,
    required String imagePath,
    required int fileSizeBytes,
    required String title,
    required int durationSeconds,
    String? description,
    String? introTitle,
    String? introContent,
  }) {
    final now = DateTime.now();
    final sessionId = sessionData['id'] as String;

    return DownloadedSession(
      id: '${sessionId}_$language',
      sessionId: sessionId,
      language: language,
      encryptedAudioPath: encryptedAudioPath,
      imagePath: imagePath,
      title: title,
      artist: 'INSIDEX',
      durationSeconds: durationSeconds,
      fileSizeBytes: fileSizeBytes,
      downloadedAt: now,
      lastPlayedAt: now,
      status: DownloadStatus.completed,
      progress: 1.0,
      categoryId: sessionData['categoryId'] as String?,
      categoryName: sessionData['categoryName'] as String?,
      sessionNumber: sessionData['sessionNumber'] as int?,
      description: description,
      introTitle: introTitle,
      introContent: introContent,
    );
  }

  /// Copy with updated fields
  DownloadedSession copyWith({
    String? id,
    String? sessionId,
    String? language,
    String? encryptedAudioPath,
    String? imagePath,
    String? title,
    String? artist,
    int? durationSeconds,
    int? fileSizeBytes,
    DateTime? downloadedAt,
    DateTime? lastPlayedAt,
    DownloadStatus? status,
    double? progress,
    String? categoryId,
    String? categoryName,
    int? sessionNumber,
    String? description,
    String? introTitle,
    String? introContent,
  }) {
    return DownloadedSession(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      language: language ?? this.language,
      encryptedAudioPath: encryptedAudioPath ?? this.encryptedAudioPath,
      imagePath: imagePath ?? this.imagePath,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      sessionNumber: sessionNumber ?? this.sessionNumber,
      description: description ?? this.description,
      introTitle: introTitle ?? this.introTitle,
      introContent: introContent ?? this.introContent,
    );
  }

  /// Get formatted duration (e.g., "10:30")
  String get formattedDuration {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Get formatted file size (e.g., "10.5 MB")
  String get formattedFileSize {
    if (fileSizeBytes < 1024) {
      return '$fileSizeBytes B';
    } else if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  /// Get display title with session number
  String get displayTitle {
    if (sessionNumber != null && !title.startsWith('$sessionNumber •')) {
      return '$sessionNumber • $title';
    }
    return title;
  }

  Map<String, dynamic> toPlayerSessionData() {
    return {
      // Core identifiers
      'id': sessionId,
      'sessionNumber': sessionNumber,
      'categoryId': categoryId,
      'categoryName': categoryName,

      // Content
      'title': title,
      'description': description,
      '_localizedIntroTitle': introTitle ?? 'Introduction',
      '_localizedIntroContent': introContent ?? '',

      // Pre-formatted display titles (SKIP formatting in player)
      '_displayTitle': displayTitle,
      '_localizedTitle': displayTitle,

      // Offline playback flags
      '_isOffline': true,
      '_downloadedLanguage': language,
      '_localImagePath': imagePath,

      // Duration info
      '_offlineDurationSeconds': durationSeconds,

      // Skip flags - prevent double processing
      '_skipTitleFormatting': true,
      '_skipUrlLoading': true,
    };
  }

  /// Check if download is complete
  bool get isCompleted => status == DownloadStatus.completed;

  /// Check if download is in progress
  bool get isDownloading => status == DownloadStatus.downloading;

  /// Check if download failed
  bool get isFailed => status == DownloadStatus.failed;

  /// Check if download is paused
  bool get isPaused => status == DownloadStatus.paused;

  @override
  String toString() {
    return 'DownloadedSession(id: $id, title: $title, language: $language, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DownloadedSession && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Download status enum
enum DownloadStatus {
  pending('pending'),
  downloading('downloading'),
  paused('paused'),
  completed('completed'),
  failed('failed');

  final String value;
  const DownloadStatus(this.value);

  static DownloadStatus fromString(String value) {
    return DownloadStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => DownloadStatus.pending,
    );
  }
}

/// Download queue item for managing download queue
class DownloadQueueItem {
  final String sessionId;
  final Map<String, dynamic> sessionData;
  final String language;
  final int priority;
  final DateTime addedAt;
  DownloadStatus status;
  double progress;
  String? errorMessage;

  DownloadQueueItem({
    required this.sessionId,
    required this.sessionData,
    required this.language,
    this.priority = 0,
    DateTime? addedAt,
    this.status = DownloadStatus.pending,
    this.progress = 0.0,
    this.errorMessage,
  }) : addedAt = addedAt ?? DateTime.now();

  /// Create unique key for this download
  String get key => '${sessionId}_$language';

  @override
  String toString() {
    return 'DownloadQueueItem(sessionId: $sessionId, language: $language, status: $status, progress: $progress)';
  }
}
