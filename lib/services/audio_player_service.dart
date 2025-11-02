import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';

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
    await _player.setVolume(0.7);
    await _setupAudioSession();
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

    for (int attempt = 0; attempt < 2; attempt++) {
      if (token != _loadToken) return lastResolvedDuration;
      try {
        // setUrl resolves with the media duration (may be null for live/unknown)
        lastResolvedDuration = await _player.setUrl(url);

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
        if (attempt == 0 && transient) {
          await Future.delayed(const Duration(milliseconds: 350));
          continue; // retry once
        }
        rethrow;
      } catch (_) {
        if (attempt == 0) {
          await Future.delayed(const Duration(milliseconds: 350));
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

  // ---- Audio Session & Interruption Handling ----
  Future<void> _setupAudioSession() async {
    final session = await AudioSession.instance;

    // Configure audio session for music playback
    await session.configure(const AudioSessionConfiguration.music());

    // Handle phone calls, alarms, other apps
    session.interruptionEventStream.listen((event) {
      if (event.begin) {
        // Interruption started (phone call, alarm, etc.)
        switch (event.type) {
          case AudioInterruptionType.duck:
            _player.setVolume(0.3);
            break;
          case AudioInterruptionType.pause:
          case AudioInterruptionType.unknown:
            // Pause playback
            _player.pause();
            break;
        }
      } else {
        // Interruption ended
        switch (event.type) {
          case AudioInterruptionType.duck:
            _player.setVolume(0.7);
            break;
          case AudioInterruptionType.pause:
            break;
          case AudioInterruptionType.unknown:
            break;
        }
      }
    });

    // Handle headphone disconnection
    session.becomingNoisyEventStream.listen((_) {
      _player.pause();
    });
  }

  Future<void> dispose() async {
    _sleepTimer?.cancel();
    _sleepTimerCtrl.close();

    final session = await AudioSession.instance;
    await session.setActive(false);

    await _player.dispose();
  }
}
