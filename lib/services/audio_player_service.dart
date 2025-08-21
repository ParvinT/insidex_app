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
    _audioPlayer = AudioPlayer();

    // Initialize audio service for background play
    _audioHandler = await AudioService.init(
      builder: () => AudioPlayerHandler(_audioPlayer),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.example.insidex_app.audio',
        androidNotificationChannelName: 'INSIDEX Audio',
        androidNotificationOngoing: true,
        androidNotificationIcon: 'mipmap/ic_launcher',
      ),
    );

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
      }
    });

    _audioPlayer.volumeStream.listen((volume) {
      _volume.add(volume);
    });
  }

  // Play audio from URL
  Future<void> playFromUrl(
    String url, {
    required String title,
    required String artist,
    String? artUri,
  }) async {
    try {
      _currentTrack.add(title);

      // Set media item for notification
      final mediaItem = MediaItem(
        id: url,
        title: title,
        artist: artist,
        artUri: artUri != null ? Uri.parse(artUri) : null,
        duration: null,
      );

      await _audioHandler
          .customAction('setMediaItem', {'mediaItem': mediaItem});

      // Load and play audio
      await _audioPlayer.setUrl(url);
      await _audioPlayer.play();
    } catch (e) {
      print('Error playing audio: $e');
      _isPlaying.add(false);
    }
  }

  // Play local asset
  Future<void> playFromAsset(
    String assetPath, {
    required String title,
    required String artist,
  }) async {
    try {
      _currentTrack.add(title);
      await _audioPlayer.setAsset(assetPath);
      await _audioPlayer.play();
    } catch (e) {
      print('Error playing asset: $e');
      _isPlaying.add(false);
    }
  }

  // Playback controls
  Future<void> play() async {
    await _audioPlayer.play();
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
    _position.add(Duration.zero);
    _isPlaying.add(false);
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  Future<void> setVolume(double volume) async {
    await _audioPlayer.setVolume(volume);
    _volume.add(volume);
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

  // Auto-play next track
  Future<void> playNext(
    String nextUrl, {
    required String title,
    required String artist,
    String? artUri,
  }) async {
    await stop();
    await playFromUrl(nextUrl, title: title, artist: artist, artUri: artUri);
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
