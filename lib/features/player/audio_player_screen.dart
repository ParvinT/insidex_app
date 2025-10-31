import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart' show PlayerState, ProcessingState;
import '../../services/audio_player_service.dart';
import 'widgets/player_modals.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:marquee/marquee.dart';
import 'package:provider/provider.dart';
import 'widgets/session_info_modal.dart';
import '../../services/listening_tracker_service.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/mini_player_provider.dart';

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
  bool _autoPlayEnabled = true;
  bool _isTracking = false;

  // Track state
  String _currentTrack = 'intro'; // 'intro' | 'subliminal'
  double _currentProgress = 0.0;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _hasAddedToRecent = false;
  String? _currentTrackingSessionId;

  // Session
  late Map<String, dynamic> _session;

  // Subscriptions
  StreamSubscription<bool>? _playingSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<PlayerState>? _playerStateSub;

  int? _sleepTimerMinutes;
  StreamSubscription<int?>? _sleepTimerSub;

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
        _currentTrack = miniPlayer.currentTrack;
        _currentPosition = miniPlayer.position;
        _totalDuration = miniPlayer.duration;
        _isPlaying = miniPlayer.isPlaying;

        if (_totalDuration.inMilliseconds > 0) {
          _currentProgress =
              (_currentPosition.inMilliseconds / _totalDuration.inMilliseconds)
                  .clamp(0.0, 1.0);
        }

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
          'intro': {'title': 'Introduction', 'audioUrl': '', 'duration': 120},
          'subliminal': {
            'title': 'Subliminal',
            'audioUrl': '',
            'duration': 3600,
          },
        };

    _setupStreamListeners();
    _addToRecentSessions();
    _checkFavoriteStatus();
    _checkPlaylistStatus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MiniPlayerProvider>().hide();

      _restoreStateFromMiniPlayer();
    });
  }

  Future<void> _restoreStateFromMiniPlayer() async {
    final miniPlayer = _miniPlayerProvider;

    if (miniPlayer == null || !miniPlayer.hasActiveSession) {
      await _initializeAudio(); // ← İLK KEZ BAŞLATIYORUZ
      return;
    }

    final isSameSession =
        miniPlayer.currentSession?['id'] == widget.sessionData?['id'];

    if (!isSameSession) {
      debugPrint('🆕 Different session, starting fresh');
      await _initializeAudio(); // ← FARKLI SESSION, YENİ BAŞLAT
      return;
    }

    // ✅ AYNI SESSION - SADECE STATE'İ RESTORE ET, AUDIO'YU DOKUNMA!
    final miniPlayerPosition = miniPlayer.position;
    final miniPlayerDuration = miniPlayer.duration;
    final miniPlayerTrack = miniPlayer.currentTrack;
    final wasPlaying = miniPlayer.isPlaying;

    debugPrint('🔄 Restoring from mini player (SMOOTH):');
    debugPrint('   Position: ${miniPlayerPosition.inSeconds}s');
    debugPrint('   Track: $miniPlayerTrack');
    debugPrint('   Was playing: $wasPlaying');

    setState(() {
      _currentTrack = miniPlayerTrack;
      _currentPosition = miniPlayerPosition;
      _totalDuration = miniPlayerDuration;
      _isPlaying = wasPlaying;
      if (_totalDuration.inMilliseconds > 0) {
        _currentProgress =
            (_currentPosition.inMilliseconds / _totalDuration.inMilliseconds)
                .clamp(0.0, 1.0);
      }
    });

    // ✅ Equalizer'ı sync et
    if (wasPlaying) {
      _eqController.repeat();
    }

    debugPrint('✅ Smooth transition completed - NO audio interruption');
  }

  Widget _buildScrollingText(String text, TextStyle style,
      {double maxWidth = double.infinity}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate text width
        final textPainter = TextPainter(
          text: TextSpan(text: text, style: style),
          maxLines: 1,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: double.infinity);

        final availableWidth =
            maxWidth != double.infinity ? maxWidth : constraints.maxWidth;

        // If text fits, return normal Text
        if (textPainter.width <= availableWidth) {
          return Text(
            text,
            style: style,
            maxLines: 1,
            textAlign: TextAlign.center,
          );
        }

        // If doesn't fit, return Marquee
        return SizedBox(
          height: style.fontSize! * 1.5,
          child: Marquee(
            text: text,
            style: style,
            scrollAxis: Axis.horizontal,
            crossAxisAlignment: CrossAxisAlignment.center,
            blankSpace: 50.0,
            velocity: 30.0,
            pauseAfterRound: const Duration(seconds: 2),
            startPadding: 10.0,
            accelerationDuration: const Duration(seconds: 1),
            accelerationCurve: Curves.linear,
            decelerationDuration: const Duration(milliseconds: 500),
            decelerationCurve: Curves.easeOut,
          ),
        );
      },
    );
  }

  void _checkFavoriteStatus() async {
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
        print('Error checking favorite status: $e');
      }
    }
  }

  void _checkPlaylistStatus() async {
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
        print('Error checking playlist status: $e');
      }
    }
  }

  void _addToRecentSessions() async {
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
        print('Added to recent sessions: ${_session['id']}');
      } catch (e) {
        print('Error adding to recent sessions: $e');
      }
    }
  }

  // --------- safe session helpers ----------
  Map<String, dynamic>? _section(String name) {
    final v = _session[name];
    if (v is Map) return Map<String, dynamic>.from(v as Map);
    return null;
  }

  T? _val<T>(String sectionName, String key) {
    final s = _section(sectionName);
    final v = s?[key];
    if (v is T) return v;
    return null;
  }

  String? _audioUrlFor(String sectionName) =>
      _val<String>(sectionName, 'audioUrl');

  String _titleFor(String sectionName, {required String fallback}) =>
      _val<String>(sectionName, 'title') ?? fallback;

  Duration _fallbackDurationFor(String section) {
    final secs = _val<int>(section, 'duration');
    if (secs != null && secs > 0) return Duration(seconds: secs);
    return section == 'intro'
        ? const Duration(seconds: 120)
        : const Duration(hours: 2);
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
        final totalMs = _totalDuration.inMilliseconds;
        if (totalMs > 0) {
          _currentProgress =
              (_currentPosition.inMilliseconds / totalMs).clamp(0.0, 1.0);
        }
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
        } else if (_autoPlayEnabled && _currentTrack == 'intro') {
          _switchToTrack('subliminal');
        }
      }
    });

    _sleepTimerSub = _audioService.sleepTimer.listen((m) {
      if (!mounted) return;
      setState(() => _sleepTimerMinutes = m);
      if (m == null && _isTracking) {
        ListeningTrackerService.endSession();
        _isTracking = false;
      }
    });
  }

  Future<void> _initializeAudio() async {
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
            print('Added to recent: ${_session['id']}');
          } catch (e) {
            print('Error adding to recent: $e');
          }
        }
      }

      // START TRACKING
      if (!_isTracking && _session['id'] != null) {
        _isTracking = true;
        _currentTrackingSessionId = _session['id'];

        await ListeningTrackerService.startSession(
          sessionId: _session['id'],
          sessionTitle: _session['title'] ?? 'Unknown Session',
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
    final String? audioUrl = _audioUrlFor(_currentTrack);

    if (audioUrl == null || audioUrl.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Audio file not found for current track'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      setState(() {
        _currentPosition = Duration.zero;
        _currentProgress = 0.0;
        _totalDuration =
            Duration.zero; // will be set by durationStream or setUrl
      });

      final resolved = await _audioService.playFromUrl(
        audioUrl,
        title: _titleFor(
          _currentTrack,
          fallback: _currentTrack == 'intro' ? 'Introduction' : 'Subliminal',
        ),
        artist: 'INSIDEX',
      );

      if (mounted && resolved != null) {
        setState(() => _totalDuration = resolved);
      }
    } catch (e) {
      if (!mounted) return;
      // Only shown if both attempts fail (transient errors are retried in service)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to play audio. ($e)'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _switchToTrack(String next) async {
    if (_currentTrack == next) return;

    if (_isTracking && next == 'subliminal') {
      print('User switched from intro to subliminal');
    }

    setState(() {
      _currentTrack = next;
      _currentPosition = Duration.zero;
      _currentProgress = 0.0;
      _totalDuration = Duration.zero; // refresh from player
    });

    await _audioService.stop();
    await _playCurrentTrack();
  }

  Future<void> _replay10() async {
    final newPos = _currentPosition - const Duration(seconds: 10);
    await _audioService.seek(newPos.isNegative ? Duration.zero : newPos);
  }

  Future<void> _forward10() async {
    final total = _totalDuration.inMilliseconds > 0
        ? _totalDuration
        : _fallbackDurationFor(_currentTrack);
    final newPos = _currentPosition + const Duration(seconds: 10);
    await _audioService.seek(
      newPos < total ? newPos : total - const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    if (_isTracking) {
      ListeningTrackerService.endSession().then((_) {
        print('Listening session ended and saved');
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
                    _buildHeader(),
                    Expanded(child: LayoutBuilder(
                      builder: (context, constraints) {
                        final Widget _inner = Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildCenterVisualizer(),
                            SizedBox(height: 40.h),
                            _buildSessionInfo(),
                            SizedBox(height: 30.h),
                            _buildTrackSelector(),
                            SizedBox(height: 30.h),
                            _buildProgressBar(),
                            SizedBox(height: 30.h),
                            _buildControls(),
                            SizedBox(height: 25.h),
                            _buildBottomActions(),
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

  // ---------------- UI blocks (Variant B colors) ----------------

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(
              Icons.keyboard_arrow_down,
              color: Colors.black,
              size: 30.sp,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            AppLocalizations.of(context).nowPlaying,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF5A5A5A),
              letterSpacing: 1.2,
            ),
          ),
          IconButton(
            icon: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.info_outline,
                color: Colors.black,
                size: 22.sp,
              ),
            ),
            onPressed: () {
              SessionInfoModal.show(
                context: context,
                session: _session,
                currentTrack: _currentTrack,
              );
            },
          ),
        ],
      ),
    );
  }

  /// Modern equalizer animation inside a subtle ring (replaces rotating note)
  Widget _buildCenterVisualizer() {
    return SizedBox(
      width: 220.w,
      height: 220.w,
      child: AnimatedBuilder(
        animation: _eqController,
        builder: (context, _) {
          final t = _eqController.value;
          final phases = [0.00, 0.22, 0.44, 0.66, 0.88];
          final bars = phases.map((p) {
            final s = 0.5 * (1 + math.sin(2 * math.pi * (t + p)));
            return 60 + 60 * s; // 60..120 px
          }).toList();

          return CustomPaint(painter: _EqPainter(bars));
        },
      ),
    );
  }

  Widget _buildSessionInfo() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 40.w),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: _buildScrollingText(
              _session['title'] ?? 'Untitled Session',
              GoogleFonts.inter(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
              maxWidth: MediaQuery.of(context).size.width - 40.w,
            ),
          ),
          SizedBox(height: 8.h),
          SizedBox(
            width: 150.w,
            child: _buildScrollingText(
              _titleFor(_currentTrack,
                  fallback:
                      _currentTrack == 'intro' ? 'Introduction' : 'Subliminal'),
              GoogleFonts.inter(
                fontSize: 14.sp,
                color: const Color(0xFF7A7A7A),
              ),
              maxWidth: 150.w,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackSelector() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 60.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5), // light gray capsule
        borderRadius: BorderRadius.circular(25.r),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _switchToTrack('intro'),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 10.h),
                decoration: BoxDecoration(
                  color: _currentTrack == 'intro'
                      ? const Color(0xFF191919) // selected: near-black
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  AppLocalizations.of(context).intro,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: _currentTrack == 'intro'
                        ? Colors.white
                        : const Color(0xFF7A7A7A),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _switchToTrack('subliminal'),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 10.h),
                decoration: BoxDecoration(
                  color: _currentTrack == 'subliminal'
                      ? const Color(0xFF191919)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  AppLocalizations.of(context).subliminal,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: _currentTrack == 'subliminal'
                        ? Colors.white
                        : const Color(0xFF7A7A7A),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final total = _totalDuration.inMilliseconds > 0
        ? _totalDuration
        : _fallbackDurationFor(_currentTrack);

    final value = total.inMilliseconds == 0
        ? 0.0
        : (_currentPosition.inMilliseconds / total.inMilliseconds).clamp(
            0.0,
            1.0,
          );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 30.w),
      child: Column(
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.black,
              inactiveTrackColor: const Color(0xFFE6E6E6),
              thumbColor: Colors.black,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6.r),
              trackHeight: 3.h,
              overlayShape: RoundSliderOverlayShape(overlayRadius: 12.r),
              overlayColor: Colors.black.withOpacity(0.1),
            ),
            child: Slider(
              value: value,
              onChanged: (v) {
                final newMs = (total.inMilliseconds * v).round();
                _audioService.seek(Duration(milliseconds: newMs));
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 5.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(_currentPosition),
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: const Color(0xFF6E6E6E),
                  ),
                ),
                Text(
                  _totalDuration.inMilliseconds > 0
                      ? _formatDuration(_totalDuration)
                      : '--:--',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: const Color(0xFF6E6E6E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.replay_10, color: Color(0xFF353535)),
          iconSize: 32.sp,
          onPressed: _replay10,
        ),
        SizedBox(width: 20.w),
        GestureDetector(
          onTap: _togglePlayPause,
          child: Container(
            width: 70.w,
            height: 70.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 35.sp,
            ),
          ),
        ),
        SizedBox(width: 20.w),
        IconButton(
          icon: const Icon(Icons.forward_10, color: Color(0xFF353535)),
          iconSize: 32.sp,
          onPressed: _forward10,
        ),
      ],
    );
  }

  Widget _buildBottomActions() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 50.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: Icon(
              Icons.loop,
              color: _isLooping ? Colors.black : const Color(0xFFBDBDBD),
            ),
            onPressed: () {
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
            },
          ),
          IconButton(
            icon: Icon(
              _isInPlaylist ? Icons.playlist_add_check : Icons.playlist_add,
              color: _isInPlaylist ? Colors.black : const Color(0xFFBDBDBD),
            ),
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null && _session['id'] != null) {
                setState(() => _isInPlaylist = !_isInPlaylist);

                try {
                  if (_isInPlaylist) {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .update({
                      'playlistSessionIds': FieldValue.arrayUnion([
                        _session['id'],
                      ]),
                    });

                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text(AppLocalizations.of(context).addedToPlaylist),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 1),
                      ),
                    );
                  } else {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .update({
                      'playlistSessionIds': FieldValue.arrayRemove([
                        _session['id'],
                      ]),
                    });

                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            AppLocalizations.of(context).removedFromPlaylist),
                        backgroundColor: Colors.orange,
                        duration: Duration(seconds: 1),
                      ),
                    );
                  }
                } catch (e) {
                  print('Error toggling playlist: $e');
                  setState(() => _isInPlaylist = !_isInPlaylist);

                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          AppLocalizations.of(context).errorUpdatingPlaylist),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
          ),
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.redAccent : const Color(0xFFBDBDBD),
            ),
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null && _session['id'] != null) {
                setState(() => _isFavorite = !_isFavorite);

                try {
                  if (_isFavorite) {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .update({
                      'favoriteSessionIds': FieldValue.arrayUnion([
                        _session['id'],
                      ]),
                    });
                  } else {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .update({
                      'favoriteSessionIds': FieldValue.arrayRemove([
                        _session['id'],
                      ]),
                    });
                  }
                } catch (e) {
                  print('Error toggling favorite: $e');
                  setState(() => _isFavorite = !_isFavorite);
                }
              }
            },
          ),
          Stack(
            children: [
              IconButton(
                icon: Icon(
                  Icons.bedtime,
                  color: _sleepTimerMinutes != null
                      ? Colors.black
                      : const Color(0xFFBDBDBD),
                ),
                onPressed: () {
                  PlayerModals.showSleepTimer(
                    context,
                    _sleepTimerMinutes, // mevcut değer
                    _audioService, // servis
                    (minutes) => setState(
                      () => _sleepTimerMinutes = minutes,
                    ), // callback
                  );
                },
              ),
              if (_sleepTimerMinutes != null)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_sleepTimerMinutes}m',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: Icon(
              _autoPlayEnabled ? Icons.queue_music : Icons.music_off,
              color: _autoPlayEnabled ? Colors.black : const Color(0xFFBDBDBD),
            ),
            onPressed: () {
              setState(() => _autoPlayEnabled = !_autoPlayEnabled);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _autoPlayEnabled
                        ? AppLocalizations.of(context).autoPlayEnabled
                        : AppLocalizations.of(context).autoPlayDisabled,
                  ),
                  backgroundColor: Colors.black,
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String two(int n) => n.toString().padLeft(2, '0');
    if (duration.inHours > 0) {
      return '${duration.inHours}:${two(duration.inMinutes.remainder(60))}:${two(duration.inSeconds.remainder(60))}';
    }
    return '${two(duration.inMinutes.remainder(60))}:${two(duration.inSeconds.remainder(60))}';
  }
}

// ---- painter for the equalizer bars ----
class _EqPainter extends CustomPainter {
  final List<double> bars; // heights (px)
  _EqPainter(this.bars);

  @override
  void paint(Canvas c, Size s) {
    final center = Offset(s.width / 2, s.height / 2);

    // subtle outer ring
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = const Color(0xFFE6E6E6);
    c.drawCircle(center, s.width / 2 - 4, ringPaint);

    // bars
    final barPaint = Paint()..color = const Color(0xFF191919);
    const barW = 14.0, gap = 12.0;
    final baseY = center.dy + 60;
    double startX = center.dx - (2 * barW + 2 * gap);

    for (int i = 0; i < bars.length; i++) {
      final h = bars[i];
      final rect = Rect.fromLTWH(startX + i * (barW + gap), baseY - h, barW, h);
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6));
      c.drawRRect(rrect, barPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _EqPainter old) => true;
}
