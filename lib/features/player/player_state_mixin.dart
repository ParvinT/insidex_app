import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart' show PlayerState;
import '../../providers/mini_player_provider.dart';
import '../../services/audio/audio_player_service.dart';

/// Common interface for player mixins to access shared state.
/// Implemented by _AudioPlayerScreenState.
abstract class PlayerStateAccessor {
  // State getters
  Map<String, dynamic> get session;
  set session(Map<String, dynamic> value);
  String get currentLanguage;
  set currentLanguage(String value);
  String? get audioUrl;
  set audioUrl(String? value);
  String? get backgroundImageUrl;
  set backgroundImageUrl(String? value);
  Duration get currentPosition;
  set currentPosition(Duration value);
  Duration get totalDuration;
  set totalDuration(Duration value);
  bool get isPlaying;
  set isPlaying(bool value);
  bool get isFavorite;
  set isFavorite(bool value);
  bool get isInPlaylist;
  set isInPlaylist(bool value);
  bool get isLooping;
  set isLooping(bool value);
  bool get isTracking;
  set isTracking(bool value);
  bool get isDecrypting;
  set isDecrypting(bool value);
  bool get isLoadingAudio;
  set isLoadingAudio(bool value);
  bool get isPlayingTrack;
  set isPlayingTrack(bool value);
  bool get hasAddedToRecent;
  set hasAddedToRecent(bool value);
  bool get accessGranted;
  set accessGranted(bool value);
  int? get sleepTimerMinutes;
  set sleepTimerMinutes(int? value);
  bool get isOfflineSession;

  // Services & providers
  AudioPlayerService get audioService;
  MiniPlayerProvider? get miniPlayerProvider;
  AnimationController get eqController;

  // Stream subscriptions
  StreamSubscription<bool>? get playingSub;
  set playingSub(StreamSubscription<bool>? value);
  StreamSubscription<Duration>? get positionSub;
  set positionSub(StreamSubscription<Duration>? value);
  StreamSubscription<Duration?>? get durationSub;
  set durationSub(StreamSubscription<Duration?>? value);
  StreamSubscription<PlayerState>? get playerStateSub;
  set playerStateSub(StreamSubscription<PlayerState>? value);
  StreamSubscription<int?>? get sleepTimerSub;
  set sleepTimerSub(StreamSubscription<int?>? value);

  // Flutter State methods
  bool get mounted;
  void setState(VoidCallback fn);
  BuildContext get context;
}