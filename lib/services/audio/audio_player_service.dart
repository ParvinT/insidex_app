import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';

import 'audio_handler.dart';

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
