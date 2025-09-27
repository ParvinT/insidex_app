import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:audio_session/audio_session.dart';

/// Single-responsibility audio service.
/// - Single AudioPlayer instance (prevents overlapping sounds)
/// - Safe loading with a race-guard token
/// - Always stop -> load -> play
/// - Built-in sleep timer (set/cancel + stream)
/// - Transient network errors are retried once (e.g., "Connection aborted")
class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();

  // Race guard for async loads: only the latest load may win.
  int _loadToken = 0;

  // Sleep timer
  Timer? _sleepTimer;
  int? _sleepTimerMinutes;
  final _sleepTimerCtrl = StreamController<int?>.broadcast();

  // Exposed streams
  Stream<bool> get isPlaying => _player.playingStream;
  Stream<Duration> get position => _player.positionStream;
  Stream<Duration?> get duration => _player.durationStream;
  Stream<PlayerState> get playerState => _player.playerStateStream;
  Stream<int?> get sleepTimer => _sleepTimerCtrl.stream; // minutes or null

  Future<void> initialize() async {
    await _player.setVolume(0.9);
    await _player.setAndroidAudioAttributes(
      const AndroidAudioAttributes(
        contentType: AndroidAudioContentType.music,
        usage: AndroidAudioUsage.media,
      ),
    );
  }

  Future<void> setVolume(double value) async =>
      _player.setVolume(value.clamp(0.0, 1.0));

  Future<void> play() async => _player.play();
  Future<void> pause() async => _player.pause();
  Future<void> stop() async => _player.stop();
  Future<void> seek(Duration position) async => _player.seek(position);

  /// Safely loads & plays a URL with a small retry for transient errors.
  /// Returns the resolved media duration (if known) so UI can show it immediately.
  Future<Duration?> playFromUrl(String url,
      {String? title, String? artist}) async {
    final int token = ++_loadToken;
    await _player.stop();

    Duration? lastResolvedDuration;

    for (int attempt = 0; attempt < 3; attempt++) {
      if (token != _loadToken) return lastResolvedDuration;
      try {
        // ÖNEMLİ: setUrl yerine LockCachingAudioSource kullan
        final audioSource = LockCachingAudioSource(
          Uri.parse(url),
          tag: {
            'title': title ?? 'Unknown',
            'artist': artist ?? 'INSIDEX',
          },
        );

        // AudioSource ile yükle (daha güvenli)
        lastResolvedDuration = await _player.setAudioSource(
          audioSource,
          preload: true, // Ön yükleme yap
          initialPosition: Duration.zero,
        );

        if (token != _loadToken) return lastResolvedDuration;
        await _player.play();
        return lastResolvedDuration; // success
      } on PlayerException catch (e) {
        final code = (e.code).toString().toLowerCase();
        final msg = (e.message ?? '').toString().toLowerCase();
        final transient = code.contains('aborted') ||
            msg.contains('aborted') ||
            msg.contains('connection') ||
            msg.contains('reset') ||
            msg.contains('timed');
        if (attempt < 2) {
          await Future.delayed(const Duration(seconds: 1));
          continue; // retry once
        }
        rethrow;
      } catch (e) {
        print('General error attempt ${attempt + 1}: $e');
        if (attempt < 2) {
          await Future.delayed(const Duration(seconds: 1));
          continue;
        }
        rethrow;
      }
    }
    return lastResolvedDuration;
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
        await _player.pause();
      } catch (_) {}
    });
  }

  Future<void> cancelSleepTimer() async {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _sleepTimerMinutes = null;
    _sleepTimerCtrl.add(null);
  }

  void dispose() {
    _sleepTimer?.cancel();
    _sleepTimerCtrl.close();
    _player.dispose();
  }
}
