import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart' show PlayerState, ProcessingState;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'widgets/player_modals.dart';
import 'widgets/session_info_modal.dart';
import 'widgets/player_widgets.dart';
import 'widgets/player_album_art.dart';
import '../../services/listening_tracker_service.dart';
import '../../services/audio/audio_player_service.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/mini_player_provider.dart';
import '../../services/language_helper_service.dart';
import '../../services/session_localization_service.dart';
import '../../services/download/download_service.dart';
import '../downloads/widgets/download_button.dart';

class AudioPlayerScreen extends StatefulWidget {
  final Map<String, dynamic>? sessionData;
  const AudioPlayerScreen({super.key, this.sessionData});

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen>
    with TickerProviderStateMixin {
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

  //Audio State
  String _currentLanguage = 'en';
  String? _audioUrl;
  String? _backgroundImageUrl;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _hasAddedToRecent = false;

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_miniPlayerProvider == null) {
      _miniPlayerProvider = context.read<MiniPlayerProvider>();

      // ✅ SMOOTH TRANSITION: Sadece AYNI session için state yükle
      final miniPlayer = _miniPlayerProvider!;
      final isSameSession = miniPlayer.hasActiveSession &&
          miniPlayer.currentSession?['id'] == widget.sessionData?['id'];

      if (isSameSession && miniPlayer.position > Duration.zero) {
        _currentPosition = miniPlayer.position;
        _totalDuration = miniPlayer.duration;
        _isPlaying = miniPlayer.isPlaying;

        debugPrint(
            '✨ Pre-loaded state for same session: ${_currentPosition.inSeconds}s');
      } else {
        debugPrint('🆕 New session or no mini player state');
      }
    }
  }

  @override
  void initState() {
    super.initState();

    _session = widget.sessionData ??
        {
          'title': 'Session',
          'introduction': {
            'title': AppLocalizations.of(context).aboutThisSession,
            'content': ''
          },
          'subliminal': {
            'audioUrls': {},
            'durations': {},
          },
          'backgroundImages': {},
        };
    _loadLanguageAndUrls();
    _setupStreamListeners();
    _addToRecentSessions();
    _checkFavoriteStatus();
    _checkPlaylistStatus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MiniPlayerProvider>().hide();

      _restoreStateFromMiniPlayer();
    });
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

      // 🆕 Store localized content in session
      final sessionNumber = _session['sessionNumber'];
      final title = localizedContent.title;

      if (sessionNumber != null) {
        _session['_localizedTitle'] =
            '$sessionNumber • $title'; // ← Mini player için
        _session['_displayTitle'] = '$sessionNumber • $title'; // ← Player için
      } else {
        _session['_localizedTitle'] = title;
        _session['_displayTitle'] = title;
      }
      _session['_localizedDescription'] = localizedContent.description;
      _session['_localizedIntroTitle'] = localizedContent.introduction.title;
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

    if (_isOfflineSession) {
      debugPrint('📥 [AudioPlayer] Offline session - starting fresh');
      await _initializeAudio();
      return;
    }

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
      if (state.processingState == ProcessingState.completed) {
        if (_isLooping) {
          _audioService.seek(Duration.zero);
          _audioService.play();
        }
      }
    });

    _sleepTimerSub = _audioService.sleepTimer.listen((m) {
      if (!mounted) return;
      final hadTimer = _sleepTimerMinutes != null;
      setState(() => _sleepTimerMinutes = m);
      if (m == null && hadTimer) {
        setState(() => _isLooping = false);
        debugPrint('🔁 [Timer] Timer ended - loop disabled');
      }
      if (m == null && _isTracking) {
        ListeningTrackerService.endSession();
        _isTracking = false;
      }
    });
  }

  Future<void> _initializeAudio() async {
    await _audioService.stop();
    await _audioService.initialize();
    await _setupStreamListeners();
    await _playCurrentTrack();
  }

  Future<void> _togglePlayPause() async {
    if (_isPlaying) {
      await _audioService.pause();

      if (_isTracking) {
        await ListeningTrackerService.pauseSession();
      }
    } else {
      // İLK PLAY'DE RECENT'E EKLE
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
          sessionTitle:
              _session['title'] ?? AppLocalizations.of(context).unknownSession,
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

      final decryptedPath =
          await downloadService.getDecryptedAudioPath(sessionId, language);

      if (decryptedPath != null) {
        if (!mounted) return;
        try {
          setState(() {
            _currentPosition = Duration.zero;
          });

          final localImagePath = _session['_localImagePath'] as String?;

          final resolved = await _audioService.playFromUrl(
            'file://$decryptedPath',
            title: _session['_displayTitle'] ??
                _session['title'] ??
                AppLocalizations.of(context).subliminalSession,
            artist: 'InsideX',
            artworkUrl: null,
            localArtworkPath: localImagePath,
            sessionId: sessionId,
          );

          if (!mounted) return;

          if (resolved != null) {
            setState(() => _totalDuration = resolved);
          }

          debugPrint('🎵 Playing offline: ${_session['title']}');
          return; // ← ÖNEMLİ: Online flow'u atla
        } catch (e) {
          debugPrint('❌ [AudioPlayer] Offline playback error: $e');
          // Fall through to show error
        }
      } else {
        debugPrint('❌ [AudioPlayer] Could not decrypt offline file');
      }

      // Show error for offline playback failure
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).audioFileNotFound),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
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

    try {
      setState(() {
        _currentPosition = Duration.zero;
        // _totalDuration already set in _loadLanguageAndUrls
      });

      final resolved = await _audioService.playFromUrl(
        _audioUrl!,
        title: _session['_displayTitle'] ??
            _session['_localizedTitle'] ??
            _session['title'] ??
            AppLocalizations.of(context).subliminalSession,
        artist: 'InsideX',
        artworkUrl: _backgroundImageUrl,
        sessionId: _session['id'],
      );

      if (mounted && resolved != null) {
        setState(() => _totalDuration = resolved);
      }

      debugPrint('🎵 Playing: ${_session['title']}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('${AppLocalizations.of(context).failedToPlayAudio} ($e)'),
          backgroundColor: Colors.red,
        ),
      );
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

  @override
  void dispose() {
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) return;

        debugPrint('🔙 [AudioPlayer] PopScope triggered');

        if (_isTracking) {
          await ListeningTrackerService.endSession();
          debugPrint('Session tracking ended on back press');
        }

        if (_miniPlayerProvider != null) {
          debugPrint(
              '🎵 [AudioPlayer] Showing mini player with session: ${_session['title']}');
          _miniPlayerProvider!.playSession(_session);
          _miniPlayerProvider!.show();
          debugPrint(
              '✅ [AudioPlayer] Mini player visible: ${_miniPlayerProvider!.isVisible}');
        } else {
          debugPrint('❌ Mini player provider is null');
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            Container(
              color: Colors.white,
              child: SafeArea(
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
                    Expanded(child: LayoutBuilder(
                      builder: (context, constraints) {
                        final Widget _inner = Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            PlayerAlbumArt(
                              imageUrl: _backgroundImageUrl,
                              localImagePath: _session['_localImagePath'],
                              equalizerController: _eqController,
                              isPlaying: _isPlaying,
                            ),
                            SizedBox(height: 40.h),
                            PlayerSessionInfo(
                              title: _session['_displayTitle'] ??
                                  _session['_localizedTitle'] ??
                                  _session['title'] ??
                                  AppLocalizations.of(context).untitledSession,
                              subtitle: AppLocalizations.of(context)
                                  .subliminalSession,
                            ),
                            SizedBox(height: 30.h),
                            IntroductionButton(
                              onTap: _showIntroductionModal,
                            ),
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
                              onPlayPause: _togglePlayPause,
                              onReplay10: _replay10,
                              onForward10: _forward10,
                            ),
                            SizedBox(height: 25.h),
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
                        final bool _isSmallPhone =
                            constraints.maxWidth <= 400 ||
                                constraints.maxHeight <= 700;
                        return SingleChildScrollView(
                          padding: EdgeInsets.only(
                              bottom:
                                  MediaQuery.of(context).padding.bottom + 12),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                                minHeight: constraints.maxHeight),
                            child: Align(
                              alignment: _isSmallPhone
                                  ? Alignment.topCenter
                                  : Alignment.center,
                              child: _inner,
                            ),
                          ),
                        );
                      },
                    )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleLoop() {
    setState(() => _isLooping = !_isLooping);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isLooping
            ? AppLocalizations.of(context).loopEnabled
            : AppLocalizations.of(context).loopDisabled),
        backgroundColor: Colors.black,
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
              backgroundColor: Colors.green,
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
              backgroundColor: Colors.orange,
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
              backgroundColor: Colors.red,
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
              backgroundColor: Colors.grey,
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
    PlayerModals.showSleepTimer(
      context,
      _sleepTimerMinutes,
      _audioService,
      (minutes) {
        if (mounted) {
          setState(() {
            _sleepTimerMinutes = minutes;

            if (minutes != null && _totalDuration.inSeconds > 0) {
              final timerSeconds = minutes * 60;
              final audioSeconds = _totalDuration.inSeconds;

              if (timerSeconds > audioSeconds && !_isLooping) {
                _isLooping = true;
                debugPrint(
                    '🔁 [Timer] Auto-loop enabled (timer: ${minutes}min > audio: ${audioSeconds ~/ 60}min)');
              }
            }
          });
        }
      },
    );
  }

  void _showIntroductionModal() {
    final title = _session['_localizedIntroTitle'] ??
        _session['introduction']?['title'] ??
        AppLocalizations.of(context).introduction;

    final content = _session['_localizedIntroContent'] ??
        _session['introduction']?['content'] ??
        '';

    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).noIntroductionAvailable),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
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
          color: Colors.white,
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
                color: Colors.grey[300],
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
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: Colors.grey[300]),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20.w),
                child: Text(
                  content,
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    height: 1.6,
                    color: Colors.black87,
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
