import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart' show ProcessingState;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'player_state_mixin.dart';
import '../../core/themes/app_theme_extension.dart';
import '../../providers/mini_player_provider.dart';
import '../../providers/auto_play_provider.dart';
import '../../services/listening_tracker_service.dart';
import '../../services/audio/audio_handler.dart';
import '../../services/download/download_service.dart';
import '../../services/download/decryption_preloader.dart';
import '../../l10n/app_localizations.dart';

/// Audio playback control methods.
/// Requires the host class to implement [PlayerStateAccessor].
mixin PlayerAudioMixin<T extends StatefulWidget> on State<T>
    implements PlayerStateAccessor {
  // Callback for next/previous session - set by the host
  VoidCallback? onPlayNextSession;
  VoidCallback? onPlayPreviousSession;

  Future<void> setupStreamListeners() async {
    // Bind notification skip controls
    audioHandler.onSkipToNext = () => onPlayNextSession?.call();
    audioHandler.onSkipToPrevious = () => onPlayPreviousSession?.call();

    // Cancel existing subscriptions first
    await playingSub?.cancel();
    await positionSub?.cancel();
    await durationSub?.cancel();
    await playerStateSub?.cancel();
    await sleepTimerSub?.cancel();

    playingSub = audioService.isPlaying.listen((playing) {
      if (!mounted) return;
      context.read<MiniPlayerProvider>().setPlayingState(playing);
      setState(() => isPlaying = playing);
      if (playing) {
        eqController.repeat();
      } else {
        eqController.stop();
      }
    });

    positionSub = audioService.position.listen((pos) {
      if (!mounted) return;
      context.read<MiniPlayerProvider>().updatePosition(pos);
      setState(() {
        currentPosition = pos;
      });
    });

    durationSub = audioService.duration.listen((d) {
      if (!mounted) return;
      if (d != null) {
        context.read<MiniPlayerProvider>().updateDuration(d);
        setState(() => totalDuration = d);
      }
    });

    playerStateSub = audioService.playerState.listen((state) {
      if (!mounted) return;
      debugPrint(
          '🔔 [AudioPlayer] PlayerState: processing=${state.processingState}, playing=${state.playing}');
      if (state.processingState == ProcessingState.completed) {
        _handlePlaybackCompleted();
      }
    });

    sleepTimerSub = audioService.sleepTimer.listen((m) {
      if (!mounted) return;
      final hadTimer = sleepTimerMinutes != null;
      setState(() => sleepTimerMinutes = m);
      if (m == null && hadTimer) {
        setState(() => isLooping = false);
        miniPlayerProvider?.setPlayContext(null);
        debugPrint('🔁 [Timer] Timer ended - loop & auto-play disabled');

        if (isTracking) {
          ListeningTrackerService.endSession();
          isTracking = false;
        }
      }
    });
  }

  void _handlePlaybackCompleted() {
    debugPrint('✅ [AudioPlayer] COMPLETED detected!');
    debugPrint('✅ [STREAM-DEBUG] hasNext: ${miniPlayerProvider?.hasNext}');
    debugPrint(
        '✅ [STREAM-DEBUG] isAutoPlayTransitioning: ${miniPlayerProvider?.isAutoPlayTransitioning}');
    debugPrint('✅ [STREAM-DEBUG] isLooping: $isLooping');

    if (isLooping) {
      audioService.seek(Duration.zero);
      audioService.play();
    } else if (miniPlayerProvider?.hasNext == true &&
        !(miniPlayerProvider?.isAutoPlayTransitioning ?? false)) {
      final autoPlay = context.read<AutoPlayProvider>();
      if (autoPlay.isEnabled) {
        debugPrint('⏭️ [AudioPlayer] Auto-playing next session...');
        onPlayNextSession?.call();
      } else {
        debugPrint('⏹️ [AudioPlayer] Auto-play disabled - stopping');
      }
    }
  }

  Future<void> initializeAudio() async {
    if (isLoadingAudio) {
      debugPrint('⏳ [INIT-DEBUG] Already loading audio, SKIPPING');
      return;
    }

    isLoadingAudio = true;
    debugPrint('🟡 [INIT-DEBUG] Starting initializeAudio...');

    try {
      await audioService.pause();
      await audioService.seek(Duration.zero);
      debugPrint('🟡 [INIT-DEBUG] audioService paused + seeked to zero');
      await Future.delayed(const Duration(milliseconds: 50));
      await audioService.initialize();
      debugPrint('🟡 [INIT-DEBUG] audioService.initialize() done');
    } catch (e) {
      debugPrint('❌ [INIT-DEBUG] Initialize error: $e');
    } finally {
      isLoadingAudio = false;
      debugPrint('🟡 [INIT-DEBUG] isLoadingAudio set to FALSE');
    }
    await setupStreamListeners();
    debugPrint('🟡 [INIT-DEBUG] Stream listeners setup done');
    await playCurrentTrack();
    debugPrint('🟡 [INIT-DEBUG] playCurrentTrack() returned');
  }

  Future<void> togglePlayPause() async {
    final unknownSessionText = AppLocalizations.of(context).unknownSession;
    if (isPlaying) {
      await audioService.pause();

      if (isTracking) {
        await ListeningTrackerService.pauseSession();
      }
    } else {
      if (!hasAddedToRecent && session['id'] != null) {
        hasAddedToRecent = true;
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          try {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .update({
              'recentSessionIds': FieldValue.arrayUnion([session['id']]),
              'lastActiveAt': FieldValue.serverTimestamp(),
            });
            debugPrint('Added to recent: ${session['id']}');
          } catch (e) {
            debugPrint('Error adding to recent: $e');
          }
        }
      }

      // START TRACKING
      if (!isTracking && session['id'] != null) {
        isTracking = true;

        await ListeningTrackerService.startSession(
          sessionId: session['id'],
          sessionTitle: session['_displayTitle'] ??
              session['_localizedTitle'] ??
              session['title'] ??
              unknownSessionText,
          categoryId: session['categoryId'],
        );
      } else if (isTracking) {
        await ListeningTrackerService.resumeSession();
      }

      if (currentPosition > Duration.zero) {
        await audioService.play();
      } else {
        await playCurrentTrack();
      }
    }
  }

  Future<void> playCurrentTrack() async {
    if (isPlayingTrack) {
      debugPrint('⏳ [AudioPlayer] Already playing track, skipping...');
      return;
    }

    if (isLoadingAudio) {
      debugPrint(
          '⏳ [AudioPlayer] Audio loading in progress, skipping playCurrentTrack...');
      return;
    }

    isPlayingTrack = true;
    debugPrint('▶️ [AudioPlayer] Starting playCurrentTrack...');

    try {
      final l10n = AppLocalizations.of(context);
      final unknownSessionText = l10n.unknownSession;
      final subliminalSessionText = l10n.subliminalSession;
      final audioNotFoundText = l10n.audioFileNotFound;

      if (session['_isOffline'] == true) {
        await _playOfflineTrack(
          unknownSessionText: unknownSessionText,
          subliminalSessionText: subliminalSessionText,
          audioNotFoundText: audioNotFoundText,
        );
        return;
      }

      // ========== ONLINE PLAYBACK ==========
      if (audioUrl == null || audioUrl!.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).audioFileNotFound),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        currentPosition = Duration.zero;
      });

      if (!isOfflineSession && !isTracking && session['id'] != null) {
        isTracking = true;
        await ListeningTrackerService.startSession(
          sessionId: session['id'],
          sessionTitle: session['_displayTitle'] ??
              session['_localizedTitle'] ??
              session['title'] ??
              AppLocalizations.of(context).unknownSession,
          categoryId: session['categoryId'],
        );
      }

      final resolved = await audioService.playFromUrl(
        audioUrl!,
        title: session['_displayTitle'] ??
            session['_localizedTitle'] ??
            session['title'] ??
            subliminalSessionText,
        artist: 'InsideX',
        artworkUrl: backgroundImageUrl,
        sessionId: session['id'],
      );

      if (mounted && resolved != null) {
        setState(() => totalDuration = resolved);
      }

      debugPrint('🎵 Playing: ${session['_displayTitle'] ?? session['title']}');
    } catch (e) {
      if (!mounted) return;
      debugPrint('❌ [AudioPlayer] Playback error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppLocalizations.of(context).failedToPlayAudio} ($e)',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      isPlayingTrack = false;
      debugPrint('✅ [AudioPlayer] playCurrentTrack completed');
    }
  }

  Future<void> _playOfflineTrack({
    required String unknownSessionText,
    required String subliminalSessionText,
    required String audioNotFoundText,
  }) async {
    debugPrint('📥 [AudioPlayer] Playing from offline download');

    final downloadService = DownloadService();
    final language =
        session['_downloadedLanguage'] as String? ?? currentLanguage;
    final sessionId = session['id'] as String?;

    if (sessionId == null) {
      debugPrint('❌ [AudioPlayer] Session ID is null for offline playback');
      return;
    }

    final preloader = DecryptionPreloader();
    String? decryptedPath = preloader.getCachedPath(sessionId);

    if (decryptedPath == null) {
      debugPrint('⏳ [AudioPlayer] Cache miss - decrypting now...');

      if (mounted) {
        setState(() => isDecrypting = true);
      }

      decryptedPath = await downloadService.getDecryptedAudioPath(
        sessionId,
        language,
      );

      if (mounted) {
        setState(() => isDecrypting = false);
      }
    } else {
      debugPrint('⚡ [AudioPlayer] Cache hit - instant playback!');
    }

    if (decryptedPath != null) {
      if (!mounted) return;

      setState(() {
        currentPosition = Duration.zero;
      });
      await audioService.seek(Duration.zero);

      if (!isOfflineSession && !isTracking && session['id'] != null) {
        isTracking = true;
        await ListeningTrackerService.startSession(
          sessionId: session['id'],
          sessionTitle: session['_displayTitle'] ??
              session['_localizedTitle'] ??
              session['title'] ??
              unknownSessionText,
          categoryId: session['categoryId'],
        );
      }

      final localImagePath = session['_localImagePath'] as String?;

      final resolved = await audioService.playFromUrl(
        'file://$decryptedPath',
        title: session['_displayTitle'] ??
            session['title'] ??
            subliminalSessionText,
        artist: 'InsideX',
        artworkUrl: null,
        localArtworkPath: localImagePath,
        sessionId: sessionId,
        duration: totalDuration,
      );

      if (!mounted) return;

      if (resolved != null) {
        setState(() => totalDuration = resolved);
      }

      debugPrint(
          '🎵 Playing offline: ${session['_displayTitle'] ?? session['title']}');
      return;
    } else {
      debugPrint('❌ [AudioPlayer] Could not decrypt offline file');
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(audioNotFoundText),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> replay10() async {
    final newPos = currentPosition - const Duration(seconds: 10);
    await audioService.seek(newPos.isNegative ? Duration.zero : newPos);
  }

  Future<void> forward10() async {
    final total = totalDuration.inMilliseconds > 0
        ? totalDuration
        : const Duration(minutes: 10);
    final newPos = currentPosition + const Duration(seconds: 10);
    await audioService.seek(
      newPos < total ? newPos : total - const Duration(milliseconds: 500),
    );
  }

  void toggleLoop() {
    setState(() => isLooping = !isLooping);
    if (!mounted) return;
    final colors = Theme.of(context).extension<AppThemeExtension>();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isLooping
              ? AppLocalizations.of(context).loopEnabled
              : AppLocalizations.of(context).loopDisabled,
        ),
        backgroundColor: colors?.textSecondary ?? Colors.grey,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void cancelStreamSubscriptions() {
    playingSub?.cancel();
    positionSub?.cancel();
    durationSub?.cancel();
    playerStateSub?.cancel();
    sleepTimerSub?.cancel();
  }
}
