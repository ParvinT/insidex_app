// lib/services/audio_player_service.dart

import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal();

  late AudioPlayer _audioPlayer;

  bool _isInitialized = false;
  String? _currentUrl;
  Duration? _manualDuration; // Manuel duration için

  // Audio state streams
  final BehaviorSubject<bool> _isPlaying = BehaviorSubject.seeded(false);
  final BehaviorSubject<Duration> _position =
      BehaviorSubject.seeded(Duration.zero);
  final BehaviorSubject<Duration> _duration =
      BehaviorSubject.seeded(Duration.zero);
  final BehaviorSubject<double> _volume = BehaviorSubject.seeded(0.7);
  final BehaviorSubject<String> _currentTrack = BehaviorSubject.seeded('');

  // Sleep timer
  Timer? _sleepTimer;
  final BehaviorSubject<int?> _sleepTimerMinutes = BehaviorSubject.seeded(null);

  // Getters
  Stream<bool> get isPlaying => _isPlaying.stream;
  Stream<Duration> get position => _position.stream;
  Stream<Duration> get duration => _duration.stream;
  Stream<double> get volume => _volume.stream;
  Stream<String> get currentTrack => _currentTrack.stream;
  Stream<int?> get sleepTimer => _sleepTimerMinutes.stream;

  // Current values
  bool get isPlayingNow => _isPlaying.value;
  Duration get currentPosition => _position.value;
  Duration get totalDuration => _duration.value;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _audioPlayer = AudioPlayer();

      // Listen to player state changes
      _audioPlayer.playingStream.listen((playing) {
        _isPlaying.add(playing);
      });

      _audioPlayer.positionStream.listen((position) {
        _position.add(position);
      });

      _audioPlayer.durationStream.listen((duration) {
        if (duration != null) {
          print('Audio duration detected: ${duration.inSeconds} seconds');

          // Duration kontrolü - çok kısa veya çok uzunsa ignore et
          if (duration.inSeconds > 10 && duration.inSeconds < 14400) {
            // 10 saniye - 4 saat arası
            _duration.add(duration);
          } else if (_manualDuration != null) {
            // Manuel duration varsa onu kullan
            _duration.add(_manualDuration!);
            print(
                'Using manual duration: ${_manualDuration!.inSeconds} seconds');
          }
        } else if (_manualDuration != null) {
          // Duration null ise manuel olanı kullan
          _duration.add(_manualDuration!);
        }
      });

      _audioPlayer.volumeStream.listen((volume) {
        _volume.add(volume);
      });

      // Handle completion
      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          _isPlaying.add(false);
          _position.add(Duration.zero);
          print('Audio completed');
        }
      });

      _isInitialized = true;
      print('AudioPlayerService initialized successfully (simple version)');
    } catch (e) {
      print('Error initializing AudioPlayerService: $e');
      _isInitialized = false;
    }
  }

  // Manuel duration ayarla
  void setManualDuration(int seconds) {
    _manualDuration = Duration(seconds: seconds);
    _duration.add(_manualDuration!);
    print('Manual duration set: $seconds seconds');
  }

  // Play audio from URL with optional duration
  Future<void> playFromUrl(
    String url, {
    required String title,
    required String artist,
    String? artUri,
    int? durationInSeconds, // Opsiyonel duration parametresi
  }) async {
    try {
      print('AudioPlayerService: Playing from URL: $url');

      // Check if initialized
      if (!_isInitialized) {
        print('AudioService not initialized, initializing now...');
        await initialize();
      }

      // Manuel duration ayarla
      if (durationInSeconds != null && durationInSeconds > 0) {
        setManualDuration(durationInSeconds);
      }

      // Only reload if URL is different
      if (_currentUrl != url) {
        _currentUrl = url;
        _currentTrack.add(title);

        // Reset position
        _position.add(Duration.zero);

        // Set audio source with custom loading config for long files
        try {
          final audioSource = AudioSource.uri(
            Uri.parse(url),
            tag: MediaItem(
              id: url,
              title: title,
              artist: artist,
              duration: _manualDuration,
            ),
          );

          // Load with custom configuration for long files
          await _audioPlayer.setAudioSource(
            audioSource,
            preload: false, // Büyük dosyalar için preload kapalı
            initialPosition: Duration.zero,
          );

          print('Audio loaded successfully');

          // Duration'ı tekrar kontrol et
          final detectedDuration = _audioPlayer.duration;
          if (detectedDuration == null || detectedDuration.inSeconds < 10) {
            // Duration algılanamadıysa manuel olanı zorla
            if (_manualDuration != null) {
              _duration.add(_manualDuration!);
              print(
                  'Forced manual duration: ${_manualDuration!.inSeconds} seconds');
            }
          }
        } catch (e) {
          print('Error loading audio source: $e');
          // Try alternative method
          await _audioPlayer.setUrl(url);
        }
      }

      // Play
      await _audioPlayer.play();
      print('Playback started');
    } catch (e) {
      print('Error playing audio: $e');
      print('URL was: $url');
      _isPlaying.add(false);
    }
  }

  // Playback controls
  Future<void> play() async {
    try {
      await _audioPlayer.play();
    } catch (e) {
      print('Error resuming playback: $e');
    }
  }

  Future<void> pause() async {
    try {
      await _audioPlayer.pause();
    } catch (e) {
      print('Error pausing playback: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
      _position.add(Duration.zero);
      _isPlaying.add(false);
      _currentUrl = null;
      _manualDuration = null; // Reset manual duration
    } catch (e) {
      print('Error stopping playback: $e');
    }
  }

  Future<void> seek(Duration position) async {
    try {
      await _audioPlayer.seek(position);
    } catch (e) {
      print('Error seeking: $e');
    }
  }

  Future<void> setVolume(double volume) async {
    try {
      await _audioPlayer.setVolume(volume);
      _volume.add(volume);
    } catch (e) {
      print('Error setting volume: $e');
    }
  }

  // 10 seconds backward
  Future<void> replay_10() async {
    try {
      final newPosition = _position.value - const Duration(seconds: 10);
      await seek(newPosition.isNegative ? Duration.zero : newPosition);
    } catch (e) {
      print('Error replaying: $e');
    }
  }

  // 10 seconds forward
  Future<void> forward_10() async {
    try {
      final newPosition = _position.value + const Duration(seconds: 10);
      if (_duration.value > Duration.zero && newPosition < _duration.value) {
        await seek(newPosition);
      } else if (_duration.value > Duration.zero) {
        await seek(_duration.value - const Duration(seconds: 1));
      }
    } catch (e) {
      print('Error forwarding: $e');
    }
  }

  // Sleep timer
  void setSleepTimer(int minutes) {
    _sleepTimer?.cancel();
    _sleepTimerMinutes.add(minutes);

    _sleepTimer = Timer(Duration(minutes: minutes), () {
      stop();
      _sleepTimerMinutes.add(null);
      print('Sleep timer completed');
    });
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimerMinutes.add(null);
  }

  // Cleanup
  void dispose() {
    _sleepTimer?.cancel();
    _audioPlayer.dispose();
    _isPlaying.close();
    _position.close();
    _duration.close();
    _volume.close();
    _currentTrack.close();
    _sleepTimerMinutes.close();
  }
}

// MediaItem class for tag
class MediaItem {
  final String id;
  final String title;
  final String artist;
  final Duration? duration;

  MediaItem({
    required this.id,
    required this.title,
    required this.artist,
    this.duration,
  });
}
