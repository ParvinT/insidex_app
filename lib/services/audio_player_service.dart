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

      // Duration stream - uzun dosyalar için özel işlem
      _audioPlayer.durationStream.listen((duration) {
        if (duration != null) {
          print('Audio duration detected: ${duration.inSeconds} seconds');

          // Manuel duration varsa onu kullan
          if (_manualDuration != null && _manualDuration!.inSeconds > 0) {
            _duration.add(_manualDuration!);
          }
          // Duration çok kısa veya çok uzunsa güvenmeyelim
          else if (duration.inSeconds > 10 && duration.inSeconds < 14400) {
            // Max 4 saat
            _duration.add(duration);
          }
          // Hatalı duration
          else if (_manualDuration != null) {
            _duration.add(_manualDuration!);
          }
        } else if (_manualDuration != null) {
          // Duration null ise manuel değeri kullan
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
      print('AudioPlayerService initialized successfully');
    } catch (e) {
      print('Error initializing AudioPlayerService: $e');
      _isInitialized = false;
    }
  }

  // Manuel duration ayarlama
  void setManualDuration(int seconds) {
    _manualDuration = Duration(seconds: seconds);
    _duration.add(_manualDuration!);
    print('Manual duration set: $seconds seconds');
  }

  // Play audio from URL with duration
  Future<void> playFromUrl(
    String url, {
    required String title,
    required String artist,
    String? artUri,
    int? durationInSeconds, // Duration parametresi eklendi
  }) async {
    try {
      print('AudioPlayerService: Playing from URL: $url');
      print('Manual duration provided: $durationInSeconds seconds');

      // Check if initialized
      if (!_isInitialized) {
        print('AudioService not initialized, initializing now...');
        await initialize();
      }

      // Duration varsa ÖNCE ayarla
      if (durationInSeconds != null && durationInSeconds > 0) {
        setManualDuration(durationInSeconds);
      }

      // Only reload if URL is different
      if (_currentUrl != url) {
        _currentUrl = url;
        _currentTrack.add(title);

        // Reset position
        _position.add(Duration.zero);

        // Büyük dosyalar için özel yükleme
        try {
          // LockCachingAudioSource kullanarak büyük dosyaları handle et
          final audioSource = LockCachingAudioSource(
            Uri.parse(url),
            tag: {
              'title': title,
              'artist': artist,
            },
          );

          await _audioPlayer.setAudioSource(audioSource);

          print('Audio loaded successfully');

          // Duration kontrolü - her zaman manuel değeri tercih et
          await Future.delayed(
              Duration(milliseconds: 500)); // Duration yüklenmesi için bekle

          final detectedDuration = _audioPlayer.duration;
          print('Detected duration: ${detectedDuration?.inSeconds} seconds');

          // Eğer algılanan duration yanlışsa (1 saat gibi) manuel değeri kullan
          if (durationInSeconds != null && durationInSeconds > 0) {
            if (detectedDuration == null ||
                detectedDuration.inSeconds < durationInSeconds * 0.9) {
              // %90'ından azsa
              print('Using manual duration instead of detected');
              setManualDuration(durationInSeconds);
            }
          }
        } catch (e) {
          print('Error with LockCachingAudioSource, trying direct URL: $e');
          // Fallback to direct URL
          await _audioPlayer.setUrl(url);

          // Yine manuel duration'ı zorla
          if (durationInSeconds != null && durationInSeconds > 0) {
            setManualDuration(durationInSeconds);
          }
        }
      }

      // Play
      await _audioPlayer.play();
      print(
          'Playback started with duration: ${_duration.value.inSeconds} seconds');
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

      // Manuel duration varsa onu kullan
      final maxDuration = _manualDuration ?? _duration.value;

      if (maxDuration > Duration.zero && newPosition < maxDuration) {
        await seek(newPosition);
      } else if (maxDuration > Duration.zero) {
        await seek(maxDuration - const Duration(seconds: 1));
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

// Audio metadata class
class AudioMetadata {
  final String title;
  final String artist;

  AudioMetadata({
    required this.title,
    required this.artist,
  });
}
