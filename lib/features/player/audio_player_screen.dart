import 'dart:async';
import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart' show PlayerState, ProcessingState;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'widgets/player_modals.dart';
import 'widgets/session_info_modal.dart';
import 'widgets/player_widgets.dart';
import 'widgets/player_album_art.dart';
import 'widgets/up_next_card.dart';
import '../../models/play_context.dart';
import '../../services/listening_tracker_service.dart';
import '../../services/audio/audio_player_service.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/mini_player_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../../providers/auto_play_provider.dart';
import '../../services/language_helper_service.dart';
import '../../services/session_localization_service.dart';
import '../../services/download/download_service.dart';
import '../../services/download/decryption_preloader.dart';
import '../../services/audio/audio_handler.dart';
import '../../services/cache_manager_service.dart';
import '../downloads/widgets/download_button.dart';
import '../../shared/widgets/upgrade_prompt.dart';
import '../../core/themes/app_theme_extension.dart';

class AudioPlayerScreen extends StatefulWidget {
  final Map<String, dynamic>? sessionData;
  final PlayContext? playContext;
  const AudioPlayerScreen({super.key, this.sessionData, this.playContext});

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // Equalizer animation (replaces old rotating note)
  late final AnimationController _eqController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  // Service
  final AudioPlayerService _audioService = AudioPlayerService();

  MiniPlayerProvider? _miniPlayerProvider;

  // UI State
  bool _isPlaying = false;
  bool _isFavorite = false;
  bool _isInPlaylist = false;
  bool _isLooping = false;
  bool _isTracking = false;
  bool _isDecrypting = false;
  bool _isLoadingAudio = false;
  bool _isPlayingTrack = false;

  //Audio State
  String _currentLanguage = 'en';
  String? _audioUrl;
  String? _backgroundImageUrl;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _hasAddedToRecent = false;
  bool _accessGranted = false;

  // Session
  late Map<String, dynamic> _session;

  // Subscriptions
  StreamSubscription<bool>? _playingSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<PlayerState>? _playerStateSub;

  int? _sleepTimerMinutes;
  StreamSubscription<int?>? _sleepTimerSub;
  bool get _isOfflineSession => _session['_isOffline'] == true;

  // Swipe-to-dismiss state
  double _dismissDragOffset = 0.0;
  bool _isDismissDragging = false;
  final ScrollController _dismissScrollController = ScrollController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_miniPlayerProvider == null) {
      _miniPlayerProvider = context.read<MiniPlayerProvider>();

      // ✅ SMOOTH TRANSITION: Sadece AYNI session için state yükle
      // ID + offline status BIRLIKTE kontrol edilmeli
      final miniPlayer = _miniPlayerProvider!;

      final currentSessionId = miniPlayer.currentSession?['id'];
      final newSessionId = widget.sessionData?['id'];
      final currentIsOffline = miniPlayer.currentSession?['_isOffline'] == true;
      final newIsOffline = widget.sessionData?['_isOffline'] == true;

      // Aynı session = aynı ID + aynı offline status
      final isSameSession = miniPlayer.hasActiveSession &&
          currentSessionId == newSessionId &&
          currentIsOffline == newIsOffline;

      if (isSameSession && miniPlayer.position > Duration.zero) {
        _currentPosition = miniPlayer.position;
        _totalDuration = miniPlayer.duration;
        _isPlaying = miniPlayer.isPlaying;

        debugPrint(
          '✨ Pre-loaded state for same session: ${_currentPosition.inSeconds}s',
        );
      } else {
        debugPrint(
          '🆕 New session or different type (online/offline mismatch)',
        );
        debugPrint(
          '   Current: $currentSessionId (offline: $currentIsOffline)',
        );
        debugPrint('   New: $newSessionId (offline: $newIsOffline)');
      }

      // Set play context if provided
      if (widget.playContext != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _miniPlayerProvider?.setPlayContext(widget.playContext);
        });
        debugPrint('🎯 [AudioPlayer] PlayContext set: ${widget.playContext}');
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _session = widget.sessionData ??
        {
          'title': 'Session',
          'introduction': {
            'title': AppLocalizations.of(context).aboutThisSession,
            'content': '',
          },
          'subliminal': {'audioUrls': {}, 'durations': {}},
          'backgroundImages': {},
        };

    // ✅ Premium/Demo check - must be done after frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAccessAndInitialize();
    });
  }

  /// Check if user can access this session, then initialize
  Future<void> _checkAccessAndInitialize() async {
    // ✅ Capture context-dependent values BEFORE any async
    final miniPlayerProvider = context.read<MiniPlayerProvider>();
    final subscriptionProvider = context.read<SubscriptionProvider>();
    final l10n = AppLocalizations.of(context);
    final navigator = Navigator.of(context);

    // ✅ Load display info FIRST (title, image) - before access check
    await _loadLanguageAndUrls();

    if (!mounted) return;

    // ✅ FIX: OFFLINE SESSION = SKIP SUBSCRIPTION CHECK ENTIRELY
    // User already had permission when they downloaded, no need to re-check
    if (_isOfflineSession) {
      debugPrint(
          '📥 [AudioPlayer] Offline session - skipping subscription check');
      _accessGranted = true;

      // Enable background playback for offline sessions
      audioHandler.setShowMediaNotification(true);
      debugPrint('🎧 [AudioPlayer] Background playback: ENABLED (offline)');

      // Continue with audio initialization
      await _setupStreamListeners();
      miniPlayerProvider.hide();
      await _restoreStateFromMiniPlayer();
      return;
    }

    // ========== ONLINE SESSION - NORMAL FLOW ==========
    await subscriptionProvider.waitForInitialization();

    if (!mounted) return;

    // Check if session is demo
    final isDemo = _session['isDemo'] as bool? ?? false;

    // Can play if demo OR has active subscription
    final canPlay = isDemo || subscriptionProvider.canPlayAudio;

    debugPrint('🔍 [AccessCheck] isDemo: $isDemo');
    debugPrint('🔍 [AccessCheck] tier: ${subscriptionProvider.tier}');
    debugPrint('🔍 [AccessCheck] isActive: ${subscriptionProvider.isActive}');
    debugPrint(
        '🔍 [AccessCheck] canPlayAudio: ${subscriptionProvider.canPlayAudio}');
    debugPrint('🔍 [AccessCheck] canPlay result: $canPlay');

    if (!canPlay) {
      // Show upgrade prompt - returns true if purchased
      final purchased = await showUpgradeBottomSheet(
        context,
        feature: 'play_session',
        title: l10n.premiumSessionTitle,
        subtitle: l10n.premiumSessionSubtitle,
      );

      // If not purchased, go back
      if (purchased != true && mounted) {
        navigator.pop();
        return;
      }
    }

    if (!mounted) return;

    _accessGranted = true;

    final canUseBackground = subscriptionProvider.canUseBackgroundPlayback;
    audioHandler.setShowMediaNotification(canUseBackground);
    debugPrint(
        '🎧 [AudioPlayer] Background playback: ${canUseBackground ? "ENABLED" : "DISABLED"}');

    // User has access - continue with audio initialization
    await _setupStreamListeners();
    _addToRecentSessions();
    _checkFavoriteStatus();
    _checkPlaylistStatus();

    miniPlayerProvider.hide();
    await _restoreStateFromMiniPlayer();
  }

  Future<void> _loadLanguageAndUrls() async {
    // ✅ OFFLINE SESSION - Skip URL loading, use pre-set values
    if (_session['_skipUrlLoading'] == true) {
      debugPrint('📥 [AudioPlayer] Offline session - using cached data');

      final language = _session['_downloadedLanguage'] as String? ??
          await LanguageHelperService.getCurrentLanguage();

      setState(() {
        _currentLanguage = language;
        _backgroundImageUrl = null; // Will use _localImagePath instead

        // Duration from offline data
        final offlineDuration = _session['_offlineDurationSeconds'] as int?;
        if (offlineDuration != null && offlineDuration > 0) {
          _totalDuration = Duration(seconds: offlineDuration);
        }
      });
      return; // Skip online flow
    }
    final language = await LanguageHelperService.getCurrentLanguage();

    // 🆕 Load localized content
    final localizedContent = SessionLocalizationService.getLocalizedContent(
      _session,
      language,
    );

    setState(() {
      _currentLanguage = language;

      // Get audio URL for current language
      _audioUrl = LanguageHelperService.getAudioUrl(
        _session['subliminal']?['audioUrls'],
        language,
      );

      // Get background image URL for current language
      _backgroundImageUrl = LanguageHelperService.getImageUrl(
        _session['backgroundImages'],
        language,
      );

      // Get duration for current language
      final duration = LanguageHelperService.getDuration(
        _session['subliminal']?['durations'],
        language,
      );

      if (duration > 0) {
        _totalDuration = Duration(seconds: duration);
      }

      // Store localized content in session
      final title = localizedContent.title;

      _session['_localizedTitle'] = title;
      _session['_displayTitle'] = title;
      _session['_localizedIntroContent'] =
          localizedContent.introduction.content;
    });
  }

  Future<void> _restoreStateFromMiniPlayer() async {
    final miniPlayer = _miniPlayerProvider;

    if (miniPlayer == null || !miniPlayer.hasActiveSession) {
      await _initializeAudio();
      return;
    }

    final isSameSession =
        miniPlayer.currentSession?['id'] == widget.sessionData?['id'];

    if (!isSameSession) {
      debugPrint('🆕 Different session, starting fresh');
      await _initializeAudio();
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
      _currentPosition = miniPlayerPosition;
      _totalDuration = miniPlayerDuration;
      _isPlaying = wasPlaying;
    });

    if (wasPlaying) {
      _eqController.repeat();
    }

    debugPrint('✅ Smooth transition completed - NO audio interruption');
  }

  void _checkFavoriteStatus() async {
    if (_isOfflineSession) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && _session['id'] != null) {
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
            _isFavorite = favoriteIds.contains(_session['id']);
          });
        }
      } catch (e) {
        debugPrint('Error checking favorite status: $e');
      }
    }
  }

  void _checkPlaylistStatus() async {
    if (_isOfflineSession) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && _session['id'] != null) {
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
            _isInPlaylist = playlistIds.contains(_session['id']);
          });
        }
      } catch (e) {
        debugPrint('Error checking playlist status: $e');
      }
    }
  }

  void _addToRecentSessions() async {
    if (_isOfflineSession) {
      debugPrint('📥 [AudioPlayer] Skipping recent - offline mode');
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && _session['id'] != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'recentSessionIds': FieldValue.arrayUnion([_session['id']]),
          'lastActiveAt': FieldValue.serverTimestamp(),
        });
        debugPrint('Added to recent sessions: ${_session['id']}');
      } catch (e) {
        debugPrint('Error adding to recent sessions: $e');
      }
    }
  }

  Future<void> _setupStreamListeners() async {
    // Bind notification skip controls to full player actions
    audioHandler.onSkipToNext = () => _playNextSession();
    audioHandler.onSkipToPrevious = () => _playPreviousSession();
    // Cancel existing subscriptions first
    await _playingSub?.cancel();
    await _positionSub?.cancel();
    await _durationSub?.cancel();
    await _playerStateSub?.cancel();
    await _sleepTimerSub?.cancel();

    _playingSub = _audioService.isPlaying.listen((playing) {
      if (!mounted) return;
      context.read<MiniPlayerProvider>().setPlayingState(playing);
      setState(() => _isPlaying = playing);
      if (playing) {
        _eqController.repeat();
      } else {
        _eqController.stop();
      }
    });

    _positionSub = _audioService.position.listen((pos) {
      if (!mounted) return;
      context.read<MiniPlayerProvider>().updatePosition(pos);
      setState(() {
        _currentPosition = pos;
      });
    });

    _durationSub = _audioService.duration.listen((d) {
      if (!mounted) return;
      if (d != null) {
        context.read<MiniPlayerProvider>().updateDuration(d);
        setState(() => _totalDuration = d);
      }
    });

    _playerStateSub = _audioService.playerState.listen((state) {
      if (!mounted) return;
      debugPrint(
          '🔔 [AudioPlayer] PlayerState: processing=${state.processingState}, playing=${state.playing}');
      if (state.processingState == ProcessingState.completed) {
        debugPrint('✅ [AudioPlayer] COMPLETED detected!');
        debugPrint('✅ [STREAM-DEBUG] hasNext: ${_miniPlayerProvider?.hasNext}');
        debugPrint(
            '✅ [STREAM-DEBUG] isAutoPlayTransitioning: ${_miniPlayerProvider?.isAutoPlayTransitioning}');
        debugPrint('✅ [STREAM-DEBUG] _isLooping: $_isLooping');
        debugPrint('   hasNext: ${_miniPlayerProvider?.hasNext}');
        debugPrint(
            '   isTransitioning: ${_miniPlayerProvider?.isAutoPlayTransitioning}');
        debugPrint(
            '   autoPlayEnabled: ${context.read<AutoPlayProvider>().isEnabled}');
        if (_isLooping) {
          _audioService.seek(Duration.zero);
          _audioService.play();
        } else if (_miniPlayerProvider?.hasNext == true &&
            !(_miniPlayerProvider?.isAutoPlayTransitioning ?? false)) {
          final autoPlay = context.read<AutoPlayProvider>();
          if (autoPlay.isEnabled) {
            debugPrint('⏭️ [AudioPlayer] Auto-playing next session...');
            _playNextSession();
          } else {
            debugPrint('⏹️ [AudioPlayer] Auto-play disabled - stopping');
          }
        }
      }
    });

    _sleepTimerSub = _audioService.sleepTimer.listen((m) {
      if (!mounted) return;
      final hadTimer = _sleepTimerMinutes != null;
      setState(() => _sleepTimerMinutes = m);
      if (m == null && hadTimer) {
        setState(() => _isLooping = false);
        _miniPlayerProvider?.setPlayContext(null);
        debugPrint('🔁 [Timer] Timer ended - loop & auto-play disabled');

        if (_isTracking) {
          ListeningTrackerService.endSession();
          _isTracking = false;
        }
      }
    });
  }

  Future<void> _initializeAudio() async {
    if (_isLoadingAudio) {
      debugPrint('⏳ [INIT-DEBUG] Already loading audio, SKIPPING');
      return;
    }

    _isLoadingAudio = true;
    debugPrint('🟡 [INIT-DEBUG] Starting _initializeAudio...');

    try {
      // Pause instead of stop to keep audio session alive
      await _audioService.pause();
      await _audioService.seek(Duration.zero);
      debugPrint('🟡 [INIT-DEBUG] audioService paused + seeked to zero');
      await Future.delayed(const Duration(milliseconds: 50));
      await _audioService.initialize();
      debugPrint('🟡 [INIT-DEBUG] audioService.initialize() done');
    } catch (e) {
      debugPrint('❌ [INIT-DEBUG] Initialize error: $e');
    } finally {
      _isLoadingAudio = false;
      debugPrint('🟡 [INIT-DEBUG] _isLoadingAudio set to FALSE');
    }
    await _setupStreamListeners();
    debugPrint('🟡 [INIT-DEBUG] Stream listeners setup done');
    await _playCurrentTrack();
    debugPrint('🟡 [INIT-DEBUG] _playCurrentTrack() returned');
  }

  Future<void> _togglePlayPause() async {
    final unknownSessionText = AppLocalizations.of(context).unknownSession;
    if (_isPlaying) {
      await _audioService.pause();

      if (_isTracking) {
        await ListeningTrackerService.pauseSession();
      }
    } else {
      if (!_hasAddedToRecent && _session['id'] != null) {
        _hasAddedToRecent = true;
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          try {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .update({
              'recentSessionIds': FieldValue.arrayUnion([_session['id']]),
              'lastActiveAt': FieldValue.serverTimestamp(),
            });
            debugPrint('Added to recent: ${_session['id']}');
          } catch (e) {
            debugPrint('Error adding to recent: $e');
          }
        }
      }

      // START TRACKING
      if (!_isTracking && _session['id'] != null) {
        _isTracking = true;

        await ListeningTrackerService.startSession(
          sessionId: _session['id'],
          sessionTitle: _session['_displayTitle'] ??
              _session['_localizedTitle'] ??
              _session['title'] ??
              unknownSessionText,
          categoryId: _session['categoryId'],
        );
      } else if (_isTracking) {
        // RESUME TRACKING
        await ListeningTrackerService.resumeSession();
      }

      if (_currentPosition > Duration.zero) {
        await _audioService.play();
      } else {
        await _playCurrentTrack();
      }
    }
  }

  Future<void> _playCurrentTrack() async {
    if (_isPlayingTrack) {
      debugPrint('⏳ [AudioPlayer] Already playing track, skipping...');
      return;
    }

    if (_isLoadingAudio) {
      debugPrint(
          '⏳ [AudioPlayer] Audio loading in progress, skipping playCurrentTrack...');
      return;
    }

    _isPlayingTrack = true;
    debugPrint('▶️ [AudioPlayer] Starting playCurrentTrack...');

    try {
      final l10n = AppLocalizations.of(context);
      final unknownSessionText = l10n.unknownSession;
      final subliminalSessionText = l10n.subliminalSession;
      final audioNotFoundText = l10n.audioFileNotFound;

      if (_session['_isOffline'] == true) {
        debugPrint('📥 [AudioPlayer] Playing from offline download');

        final downloadService = DownloadService();
        final language =
            _session['_downloadedLanguage'] as String? ?? _currentLanguage;
        final sessionId = _session['id'] as String?;

        if (sessionId == null) {
          debugPrint('❌ [AudioPlayer] Session ID is null for offline playback');
          return;
        }

        final preloader = DecryptionPreloader();
        String? decryptedPath = preloader.getCachedPath(sessionId);

        if (decryptedPath == null) {
          debugPrint('⏳ [AudioPlayer] Cache miss - decrypting now...');

          if (mounted) {
            setState(() => _isDecrypting = true);
          }

          decryptedPath = await downloadService.getDecryptedAudioPath(
            sessionId,
            language,
          );

          if (mounted) {
            setState(() => _isDecrypting = false);
          }
        } else {
          debugPrint('⚡ [AudioPlayer] Cache hit - instant playback!');
        }

        if (decryptedPath != null) {
          if (!mounted) return;

          setState(() {
            _currentPosition = Duration.zero;
          });
          await _audioService.seek(Duration.zero);

          if (!_isOfflineSession && !_isTracking && _session['id'] != null) {
            _isTracking = true;
            await ListeningTrackerService.startSession(
              sessionId: _session['id'],
              sessionTitle: _session['_displayTitle'] ??
                  _session['_localizedTitle'] ??
                  _session['title'] ??
                  unknownSessionText,
              categoryId: _session['categoryId'],
            );
          }

          final localImagePath = _session['_localImagePath'] as String?;

          final resolved = await _audioService.playFromUrl(
            'file://$decryptedPath',
            title: _session['_displayTitle'] ??
                _session['title'] ??
                subliminalSessionText,
            artist: 'InsideX',
            artworkUrl: null,
            localArtworkPath: localImagePath,
            sessionId: sessionId,
            duration: _totalDuration,
          );

          if (!mounted) return;

          if (resolved != null) {
            setState(() => _totalDuration = resolved);
          }

          debugPrint(
              '🎵 Playing offline: ${_session['_displayTitle'] ?? _session['title']}');
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
        return;
      }

      // ========== ONLINE PLAYBACK ==========
      if (_audioUrl == null || _audioUrl!.isEmpty) {
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
        _currentPosition = Duration.zero;
      });

      if (!_isOfflineSession && !_isTracking && _session['id'] != null) {
        _isTracking = true;
        await ListeningTrackerService.startSession(
          sessionId: _session['id'],
          sessionTitle: _session['_displayTitle'] ??
              _session['_localizedTitle'] ??
              _session['title'] ??
              AppLocalizations.of(context).unknownSession,
          categoryId: _session['categoryId'],
        );
      }

      final resolved = await _audioService.playFromUrl(
        _audioUrl!,
        title: _session['_displayTitle'] ??
            _session['_localizedTitle'] ??
            _session['title'] ??
            subliminalSessionText,
        artist: 'InsideX',
        artworkUrl: _backgroundImageUrl,
        sessionId: _session['id'],
      );

      if (mounted && resolved != null) {
        setState(() => _totalDuration = resolved);
      }

      debugPrint(
          '🎵 Playing: ${_session['_displayTitle'] ?? _session['title']}');
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
      _isPlayingTrack = false;
      debugPrint('✅ [AudioPlayer] playCurrentTrack completed');
    }
  }

  Future<void> _replay10() async {
    final newPos = _currentPosition - const Duration(seconds: 10);
    await _audioService.seek(newPos.isNegative ? Duration.zero : newPos);
  }

  Future<void> _forward10() async {
    final total = _totalDuration.inMilliseconds > 0
        ? _totalDuration
        : const Duration(minutes: 10);
    final newPos = _currentPosition + const Duration(seconds: 10);
    await _audioService.seek(
      newPos < total ? newPos : total - const Duration(milliseconds: 500),
    );
  }

  // =================== AUTO-PLAY ===================

  Future<void> _playNextSession() async {
    debugPrint('🔵 [NEXT-DEBUG] _playNextSession CALLED');
    debugPrint(
        '🔵 [NEXT-DEBUG] _miniPlayerProvider == null: ${_miniPlayerProvider == null}');
    debugPrint(
        '🔵 [NEXT-DEBUG] isAutoPlayTransitioning: ${_miniPlayerProvider?.isAutoPlayTransitioning}');
    debugPrint('🔵 [NEXT-DEBUG] hasNext: ${_miniPlayerProvider?.hasNext}');
    debugPrint('🔵 [NEXT-DEBUG] _isPlayingTrack: $_isPlayingTrack');
    debugPrint('🔵 [NEXT-DEBUG] _isLoadingAudio: $_isLoadingAudio');
    debugPrint('🔵 [NEXT-DEBUG] mounted: $mounted');

    if (_miniPlayerProvider == null ||
        _miniPlayerProvider!.isAutoPlayTransitioning) {
      debugPrint('🔴 [NEXT-DEBUG] BLOCKED! Returning early.');
      return;
    }

    _miniPlayerProvider!.setAutoPlayTransitioning(true);
    debugPrint('🔵 [NEXT-DEBUG] Transitioning set to TRUE');

    try {
      final nextSession = _miniPlayerProvider!.playNext();
      if (nextSession == null) {
        debugPrint('🔴 [NEXT-DEBUG] playNext() returned NULL - queue ended');
        return;
      }

      debugPrint(
          '🔵 [NEXT-DEBUG] Got next session: ${nextSession['id']} - ${nextSession['title']}');

      // End tracking for current session before switching
      if (_isTracking) {
        await ListeningTrackerService.endSession();
        _isTracking = false;
        debugPrint('🔵 [NEXT-DEBUG] Tracking ended');
      }

      // Prepare new session data with basic info BEFORE setState
      final newSession = Map<String, dynamic>.from(nextSession);

      // Pre-load language and URLs into the new session map
      _session = newSession;
      await _loadLanguageAndUrls();
      debugPrint(
          '🔵 [NEXT-DEBUG] _loadLanguageAndUrls done. audioUrl: $_audioUrl');

      // Now update UI in a single setState with all info ready
      setState(() {
        _currentPosition = Duration.zero;
        _totalDuration = Duration.zero;
        _isPlaying = false;
        _hasAddedToRecent = false;
        _isPlayingTrack = false;
        _isFavorite = false;
        _isInPlaylist = false;
      });
      debugPrint(
          '🔵 [NEXT-DEBUG] setState done - state reset with title ready');

      _miniPlayerProvider!.updateSession(_session);
      debugPrint('🔵 [NEXT-DEBUG] Provider session updated');

      _checkFavoriteStatus();
      _checkPlaylistStatus();
      _addToRecentSessions();
      debugPrint('🔵 [NEXT-DEBUG] Favorite/Playlist/Recent checks dispatched');

      debugPrint('🔵 [NEXT-DEBUG] Calling _initializeAudio...');
      await _initializeAudio();
      debugPrint('🔵 [NEXT-DEBUG] _initializeAudio COMPLETED');
    } catch (e, st) {
      debugPrint('❌ [NEXT-DEBUG] EXCEPTION: $e');
      debugPrint('❌ [NEXT-DEBUG] STACKTRACE: $st');
    } finally {
      _miniPlayerProvider!.setAutoPlayTransitioning(false);
      debugPrint('🔵 [NEXT-DEBUG] Transitioning set to FALSE (finally)');
    }
  }

  Future<void> _playPreviousSession() async {
    debugPrint('🔵 [PREV-DEBUG] _playPreviousSession CALLED');

    if (_miniPlayerProvider == null ||
        _miniPlayerProvider!.isAutoPlayTransitioning) {
      debugPrint('🔴 [PREV-DEBUG] BLOCKED - transitioning or null provider');
      return;
    }

    _miniPlayerProvider!.setAutoPlayTransitioning(true);

    try {
      final prevSession = _miniPlayerProvider!.playPrevious();
      if (prevSession == null) {
        debugPrint('⏹️ [PREV-DEBUG] No previous session - at start');
        return;
      }

      debugPrint(
          '⏮️ [AudioPlayer] Switching to previous: ${prevSession['title']}');

      // End tracking for current session before switching
      if (_isTracking) {
        await ListeningTrackerService.endSession();
        _isTracking = false;
      }

      // Prepare new session data with basic info BEFORE setState
      final newSession = Map<String, dynamic>.from(prevSession);

      // Pre-load language and URLs into the new session map
      _session = newSession;
      await _loadLanguageAndUrls();

      // Now update UI in a single setState with all info ready
      setState(() {
        _currentPosition = Duration.zero;
        _totalDuration = Duration.zero;
        _isPlaying = false;
        _hasAddedToRecent = false;
        _isPlayingTrack = false;
        _isFavorite = false;
        _isInPlaylist = false;
      });

      _miniPlayerProvider!.updateSession(_session);
      _checkFavoriteStatus();
      _checkPlaylistStatus();
      _addToRecentSessions();
      await _initializeAudio();
    } catch (e) {
      debugPrint('❌ [AudioPlayer] Play previous session error: $e');
    } finally {
      _miniPlayerProvider!.setAutoPlayTransitioning(false);
    }
  }

  // =================== LIFECYCLE OBSERVER ===================

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Only handle for free users (non-background playback)
    final subscriptionProvider = context.read<SubscriptionProvider>();
    if (subscriptionProvider.canUseBackgroundPlayback) {
      return; // Premium users - do nothing, let audio continue
    }

    // Free user - pause when app goes to background
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (_isPlaying) {
        debugPrint(
            '⏸️ [AudioPlayer] Free user - pausing audio (app backgrounded)');
        _audioService.pause();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_isTracking) {
      ListeningTrackerService.endSession().then((_) {
        debugPrint('Listening session ended and saved');
      });
    }

    _playingSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _playerStateSub?.cancel();
    _eqController.dispose();
    _sleepTimerSub?.cancel();
    _dismissScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) return;

        debugPrint('🔙 [AudioPlayer] PopScope triggered');

        // Clear transitioning flag so mini player can handle completions
        _miniPlayerProvider?.setAutoPlayTransitioning(false);

        // Show mini player with synced session data
        if (_accessGranted && _miniPlayerProvider != null) {
          debugPrint(
              '🎵 [AudioPlayer] Showing mini player with session: ${_session['title']}');
          _session['_currentLanguage'] = _currentLanguage;
          _session['_backgroundImageUrl'] = _backgroundImageUrl;
          _miniPlayerProvider!.playSession(_session);
          _miniPlayerProvider!.show();
          debugPrint(
              '✅ [AudioPlayer] Mini player visible: ${_miniPlayerProvider!.isVisible}');
          // Force re-bind notification callbacks to mini player
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _miniPlayerProvider?.triggerRefresh();
          });
        } else if (!_accessGranted) {
          debugPrint(
              '🚫 [AudioPlayer] Access not granted - skipping mini player');
        } else {
          debugPrint('❌ Mini player provider is null');
        }

        // End tracking in background (non-blocking)
        if (_isTracking) {
          ListeningTrackerService.endSession().then((_) {
            debugPrint('Session tracking ended on back press');
          });
        }
      },
      child: Container(
        color: Colors.black,
        child: AnimatedContainer(
          duration: _isDismissDragging
              ? Duration.zero
              : const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, _dismissDragOffset, 0),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Stack(
              children: [
                // 1. BLUR BACKGROUND IMAGE (Network or Local)
                _buildBlurBackground(colors),

                // 2. DARK OVERLAY FOR READABILITY
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(
                      alpha: (_backgroundImageUrl != null &&
                                  _backgroundImageUrl!.isNotEmpty) ||
                              (_session['_localImagePath'] != null &&
                                  (_session['_localImagePath'] as String)
                                      .isNotEmpty)
                          ? 0.35
                          : 0.0,
                    ),
                  ),
                ),

                // 3. MAIN CONTENT
                SafeArea(
                  child: Column(
                    children: [
                      PlayerHeader(
                        onBack: () => Navigator.pop(context),
                        onInfo: () {
                          SessionInfoModal.show(
                            context: context,
                            session: _session,
                          );
                        },
                      ),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final Widget inner = Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                PlayerAlbumArt(
                                  imageUrl: _backgroundImageUrl,
                                  localImagePath: _session['_localImagePath'],
                                  equalizerController: _eqController,
                                  isPlaying: _isPlaying,
                                  hasPrevious:
                                      _miniPlayerProvider?.hasPrevious ?? false,
                                  hasNext:
                                      _miniPlayerProvider?.hasNext ?? false,
                                  onSwipePrevious: () => _playPreviousSession(),
                                  onSwipeNext: () => _playNextSession(),
                                  nextImageUrl: _getNextSessionImageUrl(),
                                  nextLocalImagePath:
                                      _getNextSessionLocalImagePath(),
                                  previousImageUrl:
                                      _getPreviousSessionImageUrl(),
                                  previousLocalImagePath:
                                      _getPreviousSessionLocalImagePath(),
                                ),
                                SizedBox(height: 40.h),
                                PlayerSessionInfo(
                                  title: _session['_displayTitle'] ??
                                      _session['_localizedTitle'] ??
                                      _session['title'] ??
                                      AppLocalizations.of(
                                        context,
                                      ).untitledSession,
                                  subtitle: AppLocalizations.of(
                                    context,
                                  ).subliminalSession,
                                ),
                                SizedBox(height: 30.h),
                                IntroductionButton(
                                    onTap: _showIntroductionModal),
                                SizedBox(height: 30.h),
                                PlayerProgressBar(
                                  position: _currentPosition,
                                  duration: _totalDuration,
                                  onSeek: (duration) =>
                                      _audioService.seek(duration),
                                ),
                                SizedBox(height: 30.h),
                                PlayerPlayControls(
                                  isPlaying: _isPlaying,
                                  hasPrevious:
                                      _miniPlayerProvider?.hasPrevious ?? false,
                                  hasNext:
                                      _miniPlayerProvider?.hasNext ?? false,
                                  onPlayPause: _togglePlayPause,
                                  onReplay10: _replay10,
                                  onForward10: _forward10,
                                  onPrevious: () => _playPreviousSession(),
                                  onNext: () => _playNextSession(),
                                ),
                                SizedBox(height: 16.h),
                                UpNextCard(
                                  currentLanguage: _currentLanguage,
                                ),
                                SizedBox(height: 16.h),
                                PlayerBottomActions(
                                  isLooping: _isLooping,
                                  isFavorite: _isFavorite,
                                  isInPlaylist: _isInPlaylist,
                                  isOffline: _isOfflineSession,
                                  isTimerActive: _sleepTimerMinutes != null,
                                  onLoop: _toggleLoop,
                                  onFavorite: _toggleFavorite,
                                  onPlaylist: _togglePlaylist,
                                  onTimer: _showSleepTimerModal,
                                  downloadButton: _isOfflineSession
                                      ? null
                                      : DownloadButton(
                                          session: _session,
                                          size: 24.sp,
                                          showBackground: false,
                                        ),
                                ),
                              ],
                            );
                            final bool isSmallPhone =
                                constraints.maxWidth <= 400 ||
                                    constraints.maxHeight <= 700;
                            return Listener(
                              onPointerMove: (event) {
                                if (!_dismissScrollController.hasClients) {
                                  return;
                                }
                                final isAtTop =
                                    _dismissScrollController.offset <= 0;
                                final isGoingDown = event.delta.dy > 0;

                                if ((isAtTop && isGoingDown) ||
                                    _isDismissDragging) {
                                  setState(() {
                                    _dismissDragOffset =
                                        (_dismissDragOffset + event.delta.dy)
                                            .clamp(0.0, 500.0);
                                    _isDismissDragging = _dismissDragOffset > 0;
                                  });
                                }
                              },
                              onPointerUp: (_) {
                                if (!_isDismissDragging) return;

                                final threshold =
                                    MediaQuery.of(context).size.height * 0.15;

                                if (_dismissDragOffset > threshold) {
                                  Navigator.of(context).pop();
                                } else {
                                  setState(() {
                                    _dismissDragOffset = 0.0;
                                    _isDismissDragging = false;
                                  });
                                }
                              },
                              child: SingleChildScrollView(
                                controller: _dismissScrollController,
                                physics: _isDismissDragging
                                    ? const NeverScrollableScrollPhysics()
                                    : null,
                                padding: EdgeInsets.only(
                                  bottom:
                                      MediaQuery.of(context).padding.bottom +
                                          12,
                                ),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minHeight: constraints.maxHeight,
                                  ),
                                  child: Align(
                                    alignment: isSmallPhone
                                        ? Alignment.topCenter
                                        : Alignment.center,
                                    child: inner,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // 4. DECRYPTING OVERLAY
                if (_isDecrypting)
                  Container(
                    color: colors.textPrimary.withValues(alpha: 0.85),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 48.w,
                            height: 48.w,
                            child: CircularProgressIndicator(
                              color: colors.textOnPrimary,
                              strokeWidth: 3,
                            ),
                          ),
                          SizedBox(height: 20.h),
                          Text(
                            AppLocalizations.of(context).preparing,
                            style: GoogleFonts.inter(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w500,
                              color: colors.textOnPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBlurBackground(AppThemeExtension colors) {
    final localImagePath = _session['_localImagePath'] as String?;
    final hasLocalImage = localImagePath != null && localImagePath.isNotEmpty;
    final hasNetworkImage =
        _backgroundImageUrl != null && _backgroundImageUrl!.isNotEmpty;

    // No image available
    if (!hasLocalImage && !hasNetworkImage) {
      return const SizedBox.shrink();
    }

    Widget imageWidget;

    if (hasLocalImage) {
      // Offline - use local file
      final file = File(localImagePath);
      imageWidget = FutureBuilder<bool>(
        future: file.exists(),
        builder: (context, snapshot) {
          if (snapshot.data == true) {
            return Image.file(
              file,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (_, __, ___) => Container(color: colors.background),
            );
          }
          // Fallback to network if local doesn't exist
          if (hasNetworkImage) {
            return CachedNetworkImage(
              imageUrl: _backgroundImageUrl!,
              cacheManager: AppCacheManager.instance,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: colors.background),
              errorWidget: (_, __, ___) => Container(color: colors.background),
            );
          }
          return Container(color: colors.background);
        },
      );
    } else {
      // Online - use network image
      imageWidget = CachedNetworkImage(
        imageUrl: _backgroundImageUrl!,
        cacheManager: AppCacheManager.instance,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(color: colors.background),
        errorWidget: (_, __, ___) => Container(color: colors.background),
      );
    }

    return Positioned.fill(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: imageWidget,
      ),
    );
  }

  void _toggleLoop() {
    setState(() => _isLooping = !_isLooping);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isLooping
              ? AppLocalizations.of(context).loopEnabled
              : AppLocalizations.of(context).loopDisabled,
        ),
        backgroundColor: context.colors.textSecondary,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _togglePlaylist() async {
    if (_isOfflineSession) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && _session['id'] != null) {
      setState(() => _isInPlaylist = !_isInPlaylist);

      try {
        if (_isInPlaylist) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({
            'playlistSessionIds': FieldValue.arrayUnion([_session['id']]),
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
            'playlistSessionIds': FieldValue.arrayRemove([_session['id']]),
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

  Future<void> _toggleFavorite() async {
    if (_isOfflineSession) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user != null && _session['id'] != null) {
      setState(() => _isFavorite = !_isFavorite);

      try {
        if (_isFavorite) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({
            'favoriteSessionIds': FieldValue.arrayUnion([_session['id']]),
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
            'favoriteSessionIds': FieldValue.arrayRemove([_session['id']]),
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

  void _showSleepTimerModal() {
    PlayerModals.showSleepTimer(context, _sleepTimerMinutes, _audioService, (
      minutes,
    ) {
      if (mounted) {
        setState(() {
          _sleepTimerMinutes = minutes;

          if (minutes != null && _totalDuration.inSeconds > 0) {
            final timerSeconds = minutes * 60;
            final audioSeconds = _totalDuration.inSeconds;

            if (timerSeconds > audioSeconds && !_isLooping) {
              _isLooping = true;
              debugPrint(
                '🔁 [Timer] Auto-loop enabled (timer: ${minutes}min > audio: ${audioSeconds ~/ 60}min)',
              );
            }
          }
        });
      }
    });
  }

  // =================== QUEUE IMAGE HELPERS ===================

  String? _getNextSessionImageUrl() {
    final next = _miniPlayerProvider?.nextSession;
    if (next == null) return null;
    if (next['_isOffline'] == true) return null;

    final bgImages = next['backgroundImages'];
    if (bgImages is Map) {
      return bgImages[_currentLanguage] ??
          bgImages['en'] ??
          (bgImages.isNotEmpty ? bgImages.values.first : null);
    }
    return null;
  }

  String? _getNextSessionLocalImagePath() {
    final next = _miniPlayerProvider?.nextSession;
    if (next == null) return null;
    return next['_localImagePath'] as String?;
  }

  String? _getPreviousSessionImageUrl() {
    final prev = _miniPlayerProvider?.playContext?.previousSession;
    if (prev == null) return null;
    if (prev['_isOffline'] == true) return null;

    final bgImages = prev['backgroundImages'];
    if (bgImages is Map) {
      return bgImages[_currentLanguage] ??
          bgImages['en'] ??
          (bgImages.isNotEmpty ? bgImages.values.first : null);
    }
    return null;
  }

  String? _getPreviousSessionLocalImagePath() {
    final prev = _miniPlayerProvider?.playContext?.previousSession;
    if (prev == null) return null;
    return prev['_localImagePath'] as String?;
  }

  void _showIntroductionModal() {
    final title = AppLocalizations.of(context).introduction;

    final content = _session['_localizedIntroContent'] ??
        _session['introduction']?['content'] ??
        '';

    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).noIntroductionAvailable),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: context.colors.backgroundElevated,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: 12.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: context.colors.greyMedium,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),

            // Header
            Padding(
              padding: EdgeInsets.all(20.w),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w700,
                        color: context.colors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon:
                        Icon(Icons.close, color: context.colors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: context.colors.border),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20.w),
                child: Text(
                  content,
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    height: 1.6,
                    color: context.colors.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
