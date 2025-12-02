// lib/services/audio/audio_handler.dart

import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

import 'audio_cache_service.dart';

/// Professional Audio Handler for INSIDEX
///
/// This handler integrates with the OS-level media controls:
/// - Android: MediaSession API + MediaStyle Notification
/// - iOS: MPNowPlayingInfoCenter + Control Center
///
/// Features:
/// - Lock screen controls with album art
/// - Notification player (Android)
/// - Control Center integration (iOS)
/// - Bluetooth/Headphone/CarPlay controls
/// - Background playback
/// - Audio caching support
class InsideXAudioHandler extends BaseAudioHandler with SeekHandler {
  // =================== CORE PLAYER ===================
  final AudioPlayer _player = AudioPlayer();

  // Race guard for async loads (prevents overlapping plays)
  int _loadToken = 0;

  // Skip duration for forward/rewind
  static const Duration _skipDuration = Duration(seconds: 10);

  // =================== CONSTRUCTOR ===================

  InsideXAudioHandler() {
    _init();
  }

  Future<void> _init() async {
    // Set default volume
    await _player.setVolume(0.7);

    // Listen to player state changes and broadcast to OS
    _listenToPlayerState();
    _listenToPlaybackEvents();
    _listenToDuration();
    _listenToCurrentIndex();

    debugPrint('🎵 [InsideXAudioHandler] Initialized');
  }

  // =================== STATE LISTENERS ===================

  /// Listen to player state and update playbackState
  void _listenToPlayerState() {
    // Combine all relevant streams into playbackState
    Rx.combineLatest4<bool, ProcessingState, Duration, Duration?,
        PlaybackState>(
      _player.playingStream,
      _player.processingStateStream,
      _player.positionStream,
      _player.durationStream,
      (playing, processingState, position, duration) {
        return PlaybackState(
          // Available controls shown on lock screen / notification
          controls: [
            MediaControl.rewind, // -10 seconds
            playing ? MediaControl.pause : MediaControl.play,
            MediaControl.stop,
            MediaControl.fastForward,
          ],
          // Which system actions are enabled
          systemActions: const {
            MediaAction.seek,
            MediaAction.seekForward,
            MediaAction.seekBackward,
            MediaAction.play,
            MediaAction.pause,
            MediaAction.stop,
            MediaAction.fastForward,
            MediaAction.rewind,
          },
          // Android notification compact view buttons (indices of controls array)
          androidCompactActionIndices: const [0, 1, 3],
          // Current processing state
          processingState: _mapProcessingState(processingState),
          // Is currently playing
          playing: playing,
          // Current position (for progress bar)
          updatePosition: position,
          // Buffered position
          bufferedPosition: _player.bufferedPosition,
          // Playback speed
          speed: _player.speed,
          // Queue index (if using queue)
          queueIndex: 0,
        );
      },
    ).listen((state) {
      playbackState.add(state);
    });
  }

  /// Map just_audio ProcessingState to audio_service AudioProcessingState
  AudioProcessingState _mapProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  /// Listen to playback events for error handling
  void _listenToPlaybackEvents() {
    _player.playbackEventStream.listen(
      (event) {
        // Successfully received event
      },
      onError: (Object e, StackTrace st) {
        debugPrint('⚠️ [InsideXAudioHandler] Playback error: $e');
      },
    );
  }

  /// Listen to duration changes and update mediaItem
  void _listenToDuration() {
    _player.durationStream.listen((duration) {
      final currentItem = mediaItem.value;
      if (currentItem != null && duration != null) {
        // Update mediaItem with actual duration
        mediaItem.add(currentItem.copyWith(duration: duration));
      }
    });
  }

  /// Listen to current index (for queue support in future)
  void _listenToCurrentIndex() {
    _player.currentIndexStream.listen((index) {
      // For future queue support
    });
  }

  // =================== EXPOSED STREAMS (for UI) ===================

  /// Stream of playing state
  Stream<bool> get isPlayingStream => _player.playingStream;

  /// Stream of current position
  Stream<Duration> get positionStream => _player.positionStream;

  /// Stream of total duration
  Stream<Duration?> get durationStream => _player.durationStream;

  /// Stream of player state
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  /// Current position (sync)
  Duration get currentPosition => _player.position;

  /// Current duration (sync)
  Duration? get currentDuration => _player.duration;

  /// Is currently playing (sync)
  bool get isPlaying => _player.playing;

  // =================== MEDIA CONTROLS (OS-level) ===================

  @override
  Future<void> play() async {
    await _player.play();
    debugPrint('▶️ [InsideXAudioHandler] Play');
  }

  @override
  Future<void> pause() async {
    await _player.pause();
    debugPrint('⏸️ [InsideXAudioHandler] Pause');
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    mediaItem.add(null);
    debugPrint('⏹️ [InsideXAudioHandler] Stopped & notification closed');
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
    debugPrint('⏩ [InsideXAudioHandler] Seek to ${position.inSeconds}s');
  }

  /// Fast forward 10 seconds (for notification button)
  @override
  Future<void> fastForward() async {
    final newPosition = _player.position + _skipDuration;
    final duration = _player.duration ?? Duration.zero;
    final targetPosition = newPosition < duration ? newPosition : duration;
    await _player.seek(targetPosition);
    debugPrint(
        '⏭️ [InsideXAudioHandler] Fast forward 10s → ${targetPosition.inSeconds}s');
  }

  /// Rewind 10 seconds (for notification button)
  @override
  Future<void> rewind() async {
    final newPosition = _player.position - _skipDuration;
    final targetPosition =
        newPosition > Duration.zero ? newPosition : Duration.zero;
    await _player.seek(targetPosition);
    debugPrint(
        '⏮️ [InsideXAudioHandler] Rewind 10s → ${targetPosition.inSeconds}s');
  }

  @override
  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed);
    debugPrint('🏃 [InsideXAudioHandler] Speed set to ${speed}x');
  }

  // =================== CUSTOM SKIP METHODS (for UI buttons) ===================

  /// Skip forward by custom duration (for UI)
  Future<void> skipForward([Duration? duration]) async {
    final skipAmount = duration ?? _skipDuration;
    final newPosition = _player.position + skipAmount;
    final totalDuration = _player.duration ?? Duration.zero;
    final targetPosition =
        newPosition < totalDuration ? newPosition : totalDuration;
    await _player.seek(targetPosition);
    debugPrint(
        '⏭️ [InsideXAudioHandler] Skip forward ${skipAmount.inSeconds}s');
  }

  /// Skip backward by custom duration (for UI)
  Future<void> skipBackward([Duration? duration]) async {
    final skipAmount = duration ?? _skipDuration;
    final newPosition = _player.position - skipAmount;
    final targetPosition =
        newPosition > Duration.zero ? newPosition : Duration.zero;
    await _player.seek(targetPosition);
    debugPrint(
        '⏮️ [InsideXAudioHandler] Skip backward ${skipAmount.inSeconds}s');
  }

  // =================== VOLUME CONTROL ===================

  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume.clamp(0.0, 1.0));
    debugPrint(
        '🔊 [InsideXAudioHandler] Volume set to ${(volume * 100).toInt()}%');
  }

  // =================== AUDIO PLAYBACK ===================

  /// Play audio from URL with metadata for lock screen
  ///
  /// [url] - Audio URL (will check cache first)
  /// [title] - Session title (shown on lock screen)
  /// [artist] - Artist name (default: "INSIDEX")
  /// [artworkUrl] - Album art URL (shown on lock screen)
  /// [sessionId] - Unique session ID
  /// [duration] - Pre-known duration (optional, will be updated from stream)
  Future<Duration?> playFromUrl({
    required String url,
    required String title,
    String artist = 'INSIDEX',
    String? artworkUrl,
    String? sessionId,
    Duration? duration,
  }) async {
    final int token = ++_loadToken;

    // Stop any current playback
    await _player.stop();

    Duration? resolvedDuration;

    for (int attempt = 0; attempt < 2; attempt++) {
      if (token != _loadToken) {
        debugPrint('⚠️ [InsideXAudioHandler] Load cancelled (new request)');
        return resolvedDuration;
      }

      try {
        // Check cache first
        final isCached = await AudioCacheService.isCached(url);

        if (isCached) {
          // Play from cache (instant!)
          debugPrint('✅ [InsideXAudioHandler] Playing from cache');
          final cachedFile = await AudioCacheService.getCachedAudio(url);
          resolvedDuration = await _player.setFilePath(cachedFile.path);
        } else {
          // Stream from URL and cache in background
          debugPrint(
              '⚡ [InsideXAudioHandler] Streaming + caching in background');
          resolvedDuration = await _player.setUrl(url);

          // Cache in background (fire and forget)
          AudioCacheService.precacheAudio(url).catchError((e) {
            debugPrint('⚠️ Background cache failed: $e');
          });
        }

        if (token != _loadToken) return resolvedDuration;

        // Update media item for lock screen / notification
        _updateMediaItem(
          title: title,
          artist: artist,
          artworkUrl: artworkUrl,
          sessionId: sessionId,
          duration: resolvedDuration ?? duration,
        );

        // Start playback
        await _player.play();

        debugPrint('🎵 [InsideXAudioHandler] Now playing: $title');
        return resolvedDuration;
      } on PlayerException catch (e) {
        final code = (e.code).toString().toLowerCase();
        final msg = (e.message ?? '').toString().toLowerCase();
        final isTransient = code.contains('aborted') ||
            msg.contains('aborted') ||
            msg.contains('connection') ||
            msg.contains('reset') ||
            msg.contains('timed');

        if (attempt == 0 && isTransient) {
          debugPrint('⚠️ [InsideXAudioHandler] Transient error, retrying...');
          await Future.delayed(const Duration(milliseconds: 350));
          continue;
        }
        rethrow;
      } catch (e) {
        if (attempt == 0) {
          debugPrint('⚠️ [InsideXAudioHandler] Error, retrying: $e');
          await Future.delayed(const Duration(milliseconds: 350));
          continue;
        }
        rethrow;
      }
    }

    return resolvedDuration;
  }

  /// Update the media item shown on lock screen / notification
  void _updateMediaItem({
    required String title,
    required String artist,
    String? artworkUrl,
    String? sessionId,
    Duration? duration,
  }) {
    final item = MediaItem(
      id: sessionId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      artist: artist,
      duration: duration,
      artUri: artworkUrl != null && artworkUrl.isNotEmpty
          ? Uri.parse(artworkUrl)
          : null,
      // Additional metadata
      extras: {
        'sessionId': sessionId,
      },
    );

    mediaItem.add(item);

    debugPrint('📱 [InsideXAudioHandler] MediaItem updated:');
    debugPrint('   Title: $title');
    debugPrint('   Artist: $artist');
    debugPrint('   Artwork: ${artworkUrl != null ? "✅" : "❌"}');
    debugPrint('   Duration: ${duration?.inSeconds ?? "unknown"}s');
  }

  /// Update only the artwork (useful when image loads async)
  void updateArtwork(String artworkUrl) {
    final currentItem = mediaItem.value;
    if (currentItem != null && artworkUrl.isNotEmpty) {
      mediaItem.add(currentItem.copyWith(artUri: Uri.parse(artworkUrl)));
      debugPrint('🖼️ [InsideXAudioHandler] Artwork updated');
    }
  }

  /// Update only the duration (when actual duration is known)
  void updateDuration(Duration duration) {
    final currentItem = mediaItem.value;
    if (currentItem != null) {
      mediaItem.add(currentItem.copyWith(duration: duration));
      debugPrint(
          '⏱️ [InsideXAudioHandler] Duration updated: ${duration.inSeconds}s');
    }
  }

  // =================== CLEANUP ===================

  /// Dispose the handler and release resources
  Future<void> disposeHandler() async {
    await _player.dispose();
    debugPrint('🗑️ [InsideXAudioHandler] Disposed');
  }
}

// =================== GLOBAL HANDLER INSTANCE ===================

/// Global audio handler instance
/// Initialized in main.dart via AudioService.init()
late InsideXAudioHandler audioHandler;

/// Initialize the audio service
/// Must be called in main() before runApp()
Future<void> initAudioService() async {
  audioHandler = await AudioService.init(
    builder: () => InsideXAudioHandler(),
    config: const AudioServiceConfig(
      // Android notification configuration
      androidNotificationChannelId: 'com.insidexapp.mobile.audio',
      androidNotificationChannelName: 'INSIDEX Audio',
      androidNotificationChannelDescription: 'Audio playback controls',
      androidNotificationIcon: 'drawable/ic_notification',
      androidShowNotificationBadge: true,
      androidNotificationOngoing: true,
      // Stop when swiped away (Android 13+)
      androidStopForegroundOnPause: true,
      // Preload artwork for smoother transitions
      preloadArtwork: true,
      // Fast forward / rewind intervals
      fastForwardInterval: Duration(seconds: 10),
      rewindInterval: Duration(seconds: 10),
    ),
  );

  debugPrint('✅ [AudioService] Initialized successfully');
}
