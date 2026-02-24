import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'player_state_mixin.dart';
import '../../providers/mini_player_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../services/listening_tracker_service.dart';
import '../../services/language_helper_service.dart';
import '../../services/session_localization_service.dart';
import '../../services/audio/audio_handler.dart';
import '../../shared/widgets/upgrade_prompt.dart';
import '../../l10n/app_localizations.dart';
import '../../core/themes/app_theme_extension.dart';

/// Session management, navigation, and Firestore operations.
mixin PlayerSessionMixin<T extends StatefulWidget> on State<T>
    implements PlayerStateAccessor {
  // Callback for initializeAudio - set by host
  Future<void> Function()? onInitializeAudio;
  Future<void> Function()? onSetupStreamListeners;

  // Cooldown to prevent rapid swipe/tap transitions
  DateTime? _lastTransitionTime;
  static const Duration _transitionCooldown = Duration(milliseconds: 1000);

  bool get _isInCooldown {
    if (_lastTransitionTime == null) return false;
    return DateTime.now().difference(_lastTransitionTime!) <
        _transitionCooldown;
  }

  Future<void> checkAccessAndInitialize() async {
    final miniPlayerProvider = context.read<MiniPlayerProvider>();
    final subscriptionProvider = context.read<SubscriptionProvider>();
    final l10n = AppLocalizations.of(context);
    final navigator = Navigator.of(context);

    await loadLanguageAndUrls();

    if (!mounted) return;

    // OFFLINE SESSION = SKIP SUBSCRIPTION CHECK
    if (isOfflineSession) {
      debugPrint(
          '📥 [AudioPlayer] Offline session - skipping subscription check');
      accessGranted = true;

      audioHandler.setShowMediaNotification(true);
      debugPrint('🎧 [AudioPlayer] Background playback: ENABLED (offline)');

      await onSetupStreamListeners?.call();
      miniPlayerProvider.hide();
      await restoreStateFromMiniPlayer();
      return;
    }

    // ========== ONLINE SESSION - NORMAL FLOW ==========
    await subscriptionProvider.waitForInitialization();

    if (!mounted) return;

    final isDemo = session['isDemo'] as bool? ?? false;
    final canPlay = isDemo || subscriptionProvider.canPlayAudio;

    debugPrint('🔍 [AccessCheck] isDemo: $isDemo');
    debugPrint('🔍 [AccessCheck] tier: ${subscriptionProvider.tier}');
    debugPrint('🔍 [AccessCheck] isActive: ${subscriptionProvider.isActive}');
    debugPrint(
        '🔍 [AccessCheck] canPlayAudio: ${subscriptionProvider.canPlayAudio}');
    debugPrint('🔍 [AccessCheck] canPlay result: $canPlay');

    if (!canPlay) {
      final purchased = await showUpgradeBottomSheet(
        context,
        feature: 'play_session',
        title: l10n.premiumSessionTitle,
        subtitle: l10n.premiumSessionSubtitle,
      );

      if (purchased != true && mounted) {
        navigator.pop();
        return;
      }
    }

    if (!mounted) return;

    accessGranted = true;

    final canUseBackground = subscriptionProvider.canUseBackgroundPlayback;
    audioHandler.setShowMediaNotification(canUseBackground);
    debugPrint(
        '🎧 [AudioPlayer] Background playback: ${canUseBackground ? "ENABLED" : "DISABLED"}');

    await onSetupStreamListeners?.call();
    addToRecentSessions();
    checkFavoriteStatus();
    checkPlaylistStatus();

    miniPlayerProvider.hide();
    await restoreStateFromMiniPlayer();
  }

  Future<void> loadLanguageAndUrls() async {
    // OFFLINE SESSION
    if (session['_skipUrlLoading'] == true) {
      debugPrint('📥 [AudioPlayer] Offline session - using cached data');

      final language = session['_downloadedLanguage'] as String? ??
          await LanguageHelperService.getCurrentLanguage();

      setState(() {
        currentLanguage = language;
        backgroundImageUrl = null;

        final offlineDuration = session['_offlineDurationSeconds'] as int?;
        if (offlineDuration != null && offlineDuration > 0) {
          totalDuration = Duration(seconds: offlineDuration);
        }
      });
      return;
    }

    final language = await LanguageHelperService.getCurrentLanguage();

    final localizedContent = SessionLocalizationService.getLocalizedContent(
      session,
      language,
    );

    setState(() {
      currentLanguage = language;

      audioUrl = LanguageHelperService.getAudioUrl(
        session['subliminal']?['audioUrls'],
        language,
      );

      backgroundImageUrl = LanguageHelperService.getImageUrl(
        session['backgroundImages'],
        language,
      );

      final duration = LanguageHelperService.getDuration(
        session['subliminal']?['durations'],
        language,
      );

      if (duration > 0) {
        totalDuration = Duration(seconds: duration);
      }

      final title = localizedContent.title;

      session['_localizedTitle'] = title;
      session['_displayTitle'] = title;
      session['_localizedIntroContent'] = localizedContent.introduction.content;
    });
  }

  Future<void> restoreStateFromMiniPlayer() async {
    final miniPlayer = miniPlayerProvider;

    if (miniPlayer == null || !miniPlayer.hasActiveSession) {
      await onInitializeAudio?.call();
      return;
    }

    final isSameSession = miniPlayer.currentSession?['id'] == session['id'];

    if (!isSameSession) {
      debugPrint('🆕 Different session, starting fresh');
      await onInitializeAudio?.call();
      return;
    }

    final miniPlayerPosition = miniPlayer.position;
    final miniPlayerDuration = miniPlayer.duration;
    final miniPlayerTrack = miniPlayer.currentTrack;
    final wasPlaying = miniPlayer.isPlaying;

    debugPrint('🔄 Restoring from mini player (SMOOTH):');
    debugPrint('   Position: ${miniPlayerPosition.inSeconds}s');
    debugPrint('   Track: $miniPlayerTrack');
    debugPrint('   Was playing: $wasPlaying');

    setState(() {
      currentPosition = miniPlayerPosition;
      totalDuration = miniPlayerDuration;
      isPlaying = wasPlaying;
    });

    if (wasPlaying) {
      eqController.repeat();
    }

    debugPrint('✅ Smooth transition completed - NO audio interruption');
  }

  Future<void> playNextSession() async {
    debugPrint('🔵 [NEXT-DEBUG] playNextSession CALLED');

    if (miniPlayerProvider == null ||
        miniPlayerProvider!.isAutoPlayTransitioning ||
        _isInCooldown) {
      debugPrint('🔴 [NEXT-DEBUG] BLOCKED! Returning early.');
      return;
    }

    _lastTransitionTime = DateTime.now();

    miniPlayerProvider!.setAutoPlayTransitioning(true);

    try {
      final nextSession = miniPlayerProvider!.playNext();
      if (nextSession == null) {
        debugPrint('🔴 [NEXT-DEBUG] playNext() returned NULL - queue ended');
        return;
      }

      debugPrint(
          '🔵 [NEXT-DEBUG] Got next session: ${nextSession['id']} - ${nextSession['title']}');

      if (isTracking) {
        await ListeningTrackerService.endSession();
        isTracking = false;
        debugPrint('🔵 [NEXT-DEBUG] Tracking ended');
      }

      final newSession = Map<String, dynamic>.from(nextSession);

      session = newSession;
      await loadLanguageAndUrls();
      debugPrint(
          '🔵 [NEXT-DEBUG] loadLanguageAndUrls done. audioUrl: $audioUrl');

      setState(() {
        currentPosition = Duration.zero;
        totalDuration = Duration.zero;
        isPlaying = false;
        hasAddedToRecent = false;
        isPlayingTrack = false;
        isFavorite = false;
        isInPlaylist = false;
      });
      debugPrint(
          '🔵 [NEXT-DEBUG] setState done - state reset with title ready');

      miniPlayerProvider!.updateSession(session);
      debugPrint('🔵 [NEXT-DEBUG] Provider session updated');

      checkFavoriteStatus();
      checkPlaylistStatus();
      addToRecentSessions();
      debugPrint('🔵 [NEXT-DEBUG] Favorite/Playlist/Recent checks dispatched');

      debugPrint('🔵 [NEXT-DEBUG] Calling initializeAudio...');
      await onInitializeAudio?.call();
      debugPrint('🔵 [NEXT-DEBUG] initializeAudio COMPLETED');
    } catch (e, st) {
      debugPrint('❌ [NEXT-DEBUG] EXCEPTION: $e');
      debugPrint('❌ [NEXT-DEBUG] STACKTRACE: $st');
    } finally {
      miniPlayerProvider!.setAutoPlayTransitioning(false);
      debugPrint('🔵 [NEXT-DEBUG] Transitioning set to FALSE (finally)');
    }
  }

  Future<void> playPreviousSession() async {
    debugPrint('🔵 [PREV-DEBUG] playPreviousSession CALLED');

    if (miniPlayerProvider == null ||
        miniPlayerProvider!.isAutoPlayTransitioning ||
        _isInCooldown) {
      debugPrint(
          '🔴 [PREV-DEBUG] BLOCKED - transitioning, cooldown, or null provider');
      return;
    }

    _lastTransitionTime = DateTime.now();

    miniPlayerProvider!.setAutoPlayTransitioning(true);

    try {
      final prevSession = miniPlayerProvider!.playPrevious();
      if (prevSession == null) {
        debugPrint('⏹️ [PREV-DEBUG] No previous session - at start');
        return;
      }

      debugPrint(
          '⏮️ [AudioPlayer] Switching to previous: ${prevSession['title']}');

      if (isTracking) {
        await ListeningTrackerService.endSession();
        isTracking = false;
      }

      final newSession = Map<String, dynamic>.from(prevSession);

      session = newSession;
      await loadLanguageAndUrls();

      setState(() {
        currentPosition = Duration.zero;
        totalDuration = Duration.zero;
        isPlaying = false;
        hasAddedToRecent = false;
        isPlayingTrack = false;
        isFavorite = false;
        isInPlaylist = false;
      });

      miniPlayerProvider!.updateSession(session);
      checkFavoriteStatus();
      checkPlaylistStatus();
      addToRecentSessions();
      await onInitializeAudio?.call();
    } catch (e) {
      debugPrint('❌ [AudioPlayer] Play previous session error: $e');
    } finally {
      miniPlayerProvider!.setAutoPlayTransitioning(false);
    }
  }

  void checkFavoriteStatus() async {
    if (isOfflineSession) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && session['id'] != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final favoriteIds = List<String>.from(
            userDoc.data()?['favoriteSessionIds'] ?? [],
          );

          setState(() {
            isFavorite = favoriteIds.contains(session['id']);
          });
        }
      } catch (e) {
        debugPrint('Error checking favorite status: $e');
      }
    }
  }

  void checkPlaylistStatus() async {
    if (isOfflineSession) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && session['id'] != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final playlistIds = List<String>.from(
            userDoc.data()?['playlistSessionIds'] ?? [],
          );

          setState(() {
            isInPlaylist = playlistIds.contains(session['id']);
          });
        }
      } catch (e) {
        debugPrint('Error checking playlist status: $e');
      }
    }
  }

  void addToRecentSessions() async {
    if (isOfflineSession) {
      debugPrint('📥 [AudioPlayer] Skipping recent - offline mode');
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && session['id'] != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'recentSessionIds': FieldValue.arrayUnion([session['id']]),
          'lastActiveAt': FieldValue.serverTimestamp(),
        });
        debugPrint('Added to recent sessions: ${session['id']}');
      } catch (e) {
        debugPrint('Error adding to recent sessions: $e');
      }
    }
  }

  Future<void> toggleFavorite() async {
    if (isOfflineSession) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user != null && session['id'] != null) {
      setState(() => isFavorite = !isFavorite);

      try {
        if (isFavorite) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({
            'favoriteSessionIds': FieldValue.arrayUnion([session['id']]),
          });

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).addedToFavorites),
              backgroundColor: Colors.red.shade700,
              duration: const Duration(seconds: 1),
            ),
          );
        } else {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({
            'favoriteSessionIds': FieldValue.arrayRemove([session['id']]),
          });

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).removedFromFavorites),
              backgroundColor: context.colors.textSecondary,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      } catch (e) {
        debugPrint('Error updating favorites: $e');
      }
    }
  }

  Future<void> togglePlaylist() async {
    if (isOfflineSession) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && session['id'] != null) {
      setState(() => isInPlaylist = !isInPlaylist);

      try {
        if (isInPlaylist) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({
            'playlistSessionIds': FieldValue.arrayUnion([session['id']]),
          });

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).addedToPlaylist),
              backgroundColor: Colors.green.shade700,
              duration: const Duration(seconds: 1),
            ),
          );
        } else {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({
            'playlistSessionIds': FieldValue.arrayRemove([session['id']]),
          });

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).removedFromPlaylist),
              backgroundColor: Colors.orange.shade700,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      } catch (e) {
        debugPrint('Error updating playlist: $e');
      }
    }
  }
}
