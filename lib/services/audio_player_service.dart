// lib/services/audio_player_service.dart

import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:rxdart/rxdart.dart';

class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal();

  late AudioPlayer _audioPlayer;
  late AudioHandler _audioHandler;

  // Track if service is initialized
  bool _isInitialized = false;

  // Track current URL to prevent reloading same audio
  String? _currentUrl;

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

      // Temporarily disable AudioService for testing
      // Just use basic audio player without background service

      /*
      // Initialize audio service for background play
      _audioHandler = await AudioService.init(
        builder: () => AudioPlayerHandler(_audioPlayer),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.insidex.app.audio',
          androidNotificationChannelName: 'INSIDEX Audio',
          androidNotificationOngoing: true,
          androidNotificationIcon: 'mipmap/ic_launcher',
          androidStopForegroundOnPause: true,
        ),
      );
      */

      // Listen to player state changes
      _audioPlayer.playingStream.listen((playing) {
        _isPlaying.add(playing);
      });

      _audioPlayer.positionStream.listen((position) {
        _position.add(position);
      });

      _audioPlayer.durationStream.listen((duration) {
        if (duration != null) {
          _duration.add(duration);
          print('Audio duration detected: ${duration.inSeconds} seconds');
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
        }
      });

      _isInitialized = true;
      print(
          'AudioPlayerService initialized successfully (without background service)');
    } catch (e) {
      print('Error initializing AudioPlayerService: $e');
      _isInitialized = false;
    }
  }

  // Play audio from URL
  Future<void> playFromUrl(
    String url, {
    required String title,
    required String artist,
    String? artUri,
  }) async {
    try {
      print('AudioPlayerService: Playing from URL: $url');

      // Check if initialized
      if (!_isInitialized) {
        print('AudioService not initialized, initializing now...');
        await initialize();
      }

      // Only reload if URL is different
      if (_currentUrl != url) {
        _currentUrl = url;
        _currentTrack.add(title);

        // Reset position
        _position.add(Duration.zero);

        // AudioHandler is disabled for now, skip notification setup
        /*
        // Set media item for notification
        final mediaItem = MediaItem(
          id: url,
          title: title,
          artist: artist,
          artUri: artUri != null ? Uri.parse(artUri) : null,
          duration: null,
        );

        // Cast safely and handle if it's AudioPlayerHandler
        if (_audioHandler is AudioPlayerHandler) {
          await (_audioHandler as AudioPlayerHandler)
              .customAction('setMediaItem', {'mediaItem': mediaItem});
        }
        */

        // Load audio - handle both http and https URLs
        final audioUrl = url.replaceAll(' ', '%20'); // URL encode spaces
        await _audioPlayer.setUrl(audioUrl);
        print('Audio loaded successfully from: $audioUrl');
      }

      // Play
      await _audioPlayer.play();
      print('Playback started');
    } catch (e) {
      print('Error playing audio: $e');
      print('URL was: $url');
      _isPlaying.add(false);
      // Don't throw, just log
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
      _currentUrl = null; // Reset current URL
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

  // Add missing replay_15 method
  Future<void> replay_15() async {
    try {
      final newPosition = _position.value - const Duration(seconds: 15);
      await seek(newPosition.isNegative ? Duration.zero : newPosition);
    } catch (e) {
      print('Error replaying: $e');
    }
  }

  // Add missing forward_15 method
  Future<void> forward_15() async {
    try {
      final newPosition = _position.value + const Duration(seconds: 15);
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

// Audio Handler for background playback
class AudioPlayerHandler extends BaseAudioHandler {
  final AudioPlayer _audioPlayer;

  AudioPlayerHandler(this._audioPlayer);

  @override
  Future<void> play() async {
    await _audioPlayer.play();
  }

  @override
  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  @override
  Future<void> stop() async {
    await _audioPlayer.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  @override
  Future<void> customAction(String name, [Map<String, dynamic>? extras]) async {
    if (name == 'setMediaItem' && extras != null) {
      final mediaItem = extras['mediaItem'] as MediaItem;
      this.mediaItem.add(mediaItem);
    }
  }
}
