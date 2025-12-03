import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';

import 'audio_handler.dart';
import '../download/download_service.dart';
import '../language_helper_service.dart';

/// Single-responsibility audio service.
/// - Single AudioPlayer instance (prevents overlapping sounds)
/// - Safe loading with a race-guard token
/// - Always stop -> load -> play
/// - Built-in sleep timer (set/cancel + stream)
/// - Transient network errors are retried once (e.g., "Connection aborted")
class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal();

  // Sleep timer
  Timer? _sleepTimer;
  int? _sleepTimerMinutes;
  final _sleepTimerCtrl = StreamController<int?>.broadcast();

  // Exposed streams
  Stream<bool> get isPlaying => audioHandler.isPlayingStream;
  Stream<Duration> get position => audioHandler.positionStream;
  Stream<Duration?> get duration => audioHandler.durationStream;
  Stream<PlayerState> get playerState => audioHandler.playerStateStream;
  Stream<int?> get sleepTimer => _sleepTimerCtrl.stream; // minutes or null

  Future<void> initialize() async {
    // audioHandler is initialized in main.dart via initAudioService()
    debugPrint('🎵 [AudioPlayerService] Ready (using audioHandler)');
  }

  Future<void> setVolume(double value) async =>
      audioHandler.setVolume(value.clamp(0.0, 1.0));

  Future<void> play() async => audioHandler.play();
  Future<void> pause() async => audioHandler.pause();
  Future<void> stop() async => audioHandler.stop();
  Future<void> seek(Duration position) async => audioHandler.seek(position);

  /// Safely loads & plays a URL with a small retry for transient errors.
  /// Returns the resolved media duration (if known) so UI can show it immediately.
  Future<Duration?> playFromUrl(
    String url, {
    String? title,
    String? artist,
    String? artworkUrl,
    String? sessionId,
    Duration? duration,
  }) async {
    return await audioHandler.playFromUrl(
      url: url,
      title: title ?? 'INSIDEX Session',
      artist: artist ?? 'INSIDEX',
      artworkUrl: artworkUrl,
      sessionId: sessionId,
      duration: duration,
    );
  }

  /// Play session with download priority
  /// Priority: Downloaded → Cached → Stream
  Future<Duration?> playSession({
    required Map<String, dynamic> sessionData,
    required String language,
    String? artworkUrl,
  }) async {
    final sessionId = sessionData['id'] as String?;
    if (sessionId == null) {
      debugPrint('❌ [AudioPlayerService] Session ID is null');
      return null;
    }

    final downloadService = DownloadService();

    // Get session metadata
    final title = sessionData['_displayTitle'] ??
        sessionData['title'] ??
        'INSIDEX Session';
    final duration = LanguageHelperService.getDuration(
      sessionData['subliminal']?['durations'],
      language,
    );

    // 1️⃣ Check if downloaded (HIGHEST PRIORITY)
    if (downloadService.isInitialized) {
      final isDownloaded =
          await downloadService.isDownloaded(sessionId, language);

      if (isDownloaded) {
        debugPrint('📥 [AudioPlayerService] Playing from download');

        final decryptedPath = await downloadService.getDecryptedAudioPath(
          sessionId,
          language,
        );

        if (decryptedPath != null) {
          // Play from decrypted file
          return await audioHandler.playFromUrl(
            url: 'file://$decryptedPath',
            title: title,
            artist: 'INSIDEX',
            artworkUrl: artworkUrl,
            sessionId: sessionId,
            duration: duration > 0 ? Duration(seconds: duration) : null,
          );
        }
      }
    }

    // 2️⃣ Get audio URL and use cache/stream flow
    final audioUrl = LanguageHelperService.getAudioUrl(
      sessionData['subliminal']?['audioUrls'],
      language,
    );

    if (audioUrl.isEmpty) {
      debugPrint('❌ [AudioPlayerService] Audio URL not found');
      return null;
    }

    debugPrint('🎵 [AudioPlayerService] Playing from cache/stream');

    return await playFromUrl(
      audioUrl,
      title: title,
      artist: 'INSIDEX',
      artworkUrl: artworkUrl,
      sessionId: sessionId,
      duration: duration > 0 ? Duration(seconds: duration) : null,
    );
  }

  /// ---- Sleep timer API (used by PlayerModals) ----
  Future<void> setSleepTimer(int minutes) async {
    _sleepTimer?.cancel();
    _sleepTimerMinutes = minutes;
    _sleepTimerCtrl.add(_sleepTimerMinutes);

    _sleepTimer = Timer(Duration(minutes: minutes), () async {
      _sleepTimerMinutes = null;
      _sleepTimerCtrl.add(null);
      try {
        await audioHandler.pause();
      } catch (_) {}
    });
  }

  Future<void> cancelSleepTimer() async {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _sleepTimerMinutes = null;
    _sleepTimerCtrl.add(null);
  }

  Future<void> dispose() async {
    _sleepTimer?.cancel();
    await _sleepTimerCtrl.close();
    debugPrint('🗑️ [AudioPlayerService] Disposed');
  }
}
