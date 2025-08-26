// lib/features/player/audio_player_screen.dart

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../services/audio_player_service.dart';
import 'widgets/player_modals.dart';
import 'test_audio_data.dart';

class AudioPlayerScreen extends StatefulWidget {
  final Map<String, dynamic>? sessionData;

  const AudioPlayerScreen({
    super.key,
    this.sessionData,
  });

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen>
    with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late AnimationController _rotationController;

  // Audio Service
  final AudioPlayerService _audioService = AudioPlayerService();

  // Audio State
  bool _isPlaying = false;
  bool _isFavorite = false;
  bool _isLooping = false;
  bool _autoPlayEnabled = true;
  String _currentTrack = 'intro';
  double _currentProgress = 0.0;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  final double _volume = 0.7;
  int? _sleepTimerMinutes;

  // Session data
  late Map<String, dynamic> _session;

  // Stream subscriptions
  StreamSubscription<bool>? _playingSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;

  // Track completion timer
  Timer? _completionCheckTimer;

  /// ----------------------------
  /// Helpers for safe session access
  /// ----------------------------
  Map<String, dynamic>? _section(String name) {
    final v = _session[name];
    if (v is Map) {
      // ensure it is a map with String keys
      return Map<String, dynamic>.from(v as Map);
    }
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

  int _durationSecondsFor(String sectionName, {required int fallback}) =>
      _val<int>(sectionName, 'duration') ?? fallback;

  Duration _effectiveDurationFor(String sectionName) {
    final fallback = sectionName == 'intro' ? 120 : 7200;
    final secs = _durationSecondsFor(sectionName, fallback: fallback);
    return Duration(seconds: secs);
  }

  @override
  void initState() {
    super.initState();

    // Initialize session data
    _session = widget.sessionData ?? TestAudioData.getTestSession();

    // Initialize animations
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _waveController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );

    // Initialize audio
    _initializeAudio();
  }

  Future<void> _initializeAudio() async {
    await _audioService.initialize();
    await _audioService.setVolume(_volume);

    _playingSubscription = _audioService.isPlaying.listen((playing) {
      if (!mounted) return;
      setState(() => _isPlaying = playing);
      if (playing) {
        _waveController.repeat();
        _rotationController.repeat();
      } else {
        _waveController.stop();
        _rotationController.stop();
      }
    });

    _positionSubscription = _audioService.position.listen((position) {
      if (!mounted) return;
      setState(() {
        _currentPosition = position;

        // Use session duration (intro/subliminal) as effective duration
        final effectiveDuration = _effectiveDurationFor(_currentTrack);

        if (effectiveDuration.inSeconds > 0) {
          _currentProgress = position.inSeconds / effectiveDuration.inSeconds;
          _currentProgress = _currentProgress.clamp(0.0, 1.0);

          // Check for track completion (auto-play from intro → subliminal)
          if (_autoPlayEnabled &&
              _currentTrack == 'intro' &&
              position.inSeconds >= effectiveDuration.inSeconds - 1) {
            _handleTrackCompletion();
          }
        } else {
          _currentProgress = 0.0;
        }
      });
    });

    _durationSubscription = _audioService.duration.listen((duration) {
      if (!mounted) return;
      if (duration.inSeconds > 0) {
        setState(() {
          _totalDuration = duration;
        });
      }
    });

    // Listen to sleep timer
    _audioService.sleepTimer.listen((minutes) {
      if (!mounted) return;
      setState(() {
        _sleepTimerMinutes = minutes;
      });
    });
  }

  void _setDurationFromSession() {
    setState(() {
      _totalDuration = _effectiveDurationFor(_currentTrack);
    });
  }

  void _handleTrackCompletion() {
    if (_currentTrack == 'intro' && _autoPlayEnabled && !_isLooping) {
      _completionCheckTimer?.cancel();
      _completionCheckTimer = Timer(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        _switchToTrack('subliminal');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Now playing: Subliminal Session',
              style: GoogleFonts.inter(fontSize: 14.sp),
            ),
            backgroundColor: AppColors.primaryGold,
            duration: const Duration(seconds: 2),
          ),
        );
      });
    } else if (_isLooping) {
      _audioService.seek(Duration.zero);
      _audioService.play();
    }
  }

  void _togglePlayPause() async {
    if (_isPlaying) {
      await _audioService.pause();
    } else {
      if (_currentPosition.inSeconds > 0) {
        await _audioService.play();
      } else {
        await _playCurrentTrack();
      }
    }
  }

  Future<void> _playCurrentTrack() async {
    try {
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

      // Set duration from session before playing
      _setDurationFromSession();

      await _audioService.playFromUrl(
        audioUrl,
        title: _titleFor(
          _currentTrack,
          fallback: _currentTrack == 'intro' ? 'Introduction' : 'Subliminal',
        ),
        artist: 'INSIDEX',
      );

      // Force set duration after playing (keeps slider correct for long files)
      setState(() {
        _totalDuration = _effectiveDurationFor(_currentTrack);
      });
    } catch (e) {
      // ignore: avoid_print
      print('Error playing audio: $e');
      if (mounted) setState(() => _isPlaying = false);
    }
  }

  void _switchToTrack(String track) async {
    if (_currentTrack == track) return;

    setState(() {
      _currentTrack = track;
      _currentPosition = Duration.zero;
      _currentProgress = 0.0;
    });

    await _audioService.stop();
    await Future.delayed(const Duration(milliseconds: 200));
    await _playCurrentTrack();
  }

  void _toggleAutoPlay() {
    setState(() {
      _autoPlayEnabled = !_autoPlayEnabled;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(_autoPlayEnabled ? 'Auto-play enabled' : 'Auto-play disabled'),
        backgroundColor: AppColors.primaryGold,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _toggleLoop() {
    setState(() {
      _isLooping = !_isLooping;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isLooping ? 'Loop enabled' : 'Loop disabled'),
        backgroundColor: AppColors.primaryGold,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _replay10() async {
    final newPosition = _currentPosition - const Duration(seconds: 10);
    await _audioService
        .seek(newPosition.isNegative ? Duration.zero : newPosition);
  }

  void _forward10() async {
    final newPosition = _currentPosition + const Duration(seconds: 10);
    final effectiveDuration = _effectiveDurationFor(_currentTrack);

    if (effectiveDuration > Duration.zero && newPosition < effectiveDuration) {
      await _audioService.seek(newPosition);
    } else if (effectiveDuration > Duration.zero) {
      await _audioService.seek(effectiveDuration - const Duration(seconds: 1));
    }
  }

  @override
  void dispose() {
    _completionCheckTimer?.cancel();
    _playingSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _pulseController.dispose();
    _waveController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black,
              Colors.grey[900]!,
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildAlbumArt(),
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.keyboard_arrow_down,
                color: Colors.white, size: 30.sp),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            'NOW PLAYING',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white60,
              letterSpacing: 1.2,
            ),
          ),
          IconButton(
            icon: Icon(Icons.more_vert, color: Colors.white, size: 24.sp),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumArt() {
    return Container(
      width: 220.w,
      height: 220.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            AppColors.primaryGold.withOpacity(0.8),
            AppColors.primaryGold,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGold.withOpacity(0.3),
            blurRadius: 30,
            spreadRadius: 10,
          ),
        ],
      ),
      child: Center(
        child: AnimatedBuilder(
          animation: _rotationController,
          builder: (context, child) {
            return Transform.rotate(
              angle: _rotationController.value * 2 * math.pi,
              child: Icon(
                Icons.music_note,
                size: 80.sp,
                color: Colors.white,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSessionInfo() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 40.w),
      child: Column(
        children: [
          Text(
            _session['title'] ?? 'Unknown Session',
            style: GoogleFonts.inter(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          Text(
            _currentTrack == 'intro'
                ? _titleFor('intro', fallback: 'Introduction')
                : _titleFor('subliminal', fallback: 'Subliminal'),
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
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
        color: Colors.white.withOpacity(0.1),
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
                      ? AppColors.primaryGold
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  'Intro',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: _currentTrack == 'intro'
                        ? Colors.black
                        : Colors.white60,
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
                      ? AppColors.primaryGold
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  'Subliminal',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: _currentTrack == 'subliminal'
                        ? Colors.black
                        : Colors.white60,
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
    final effectiveDuration = _effectiveDurationFor(_currentTrack);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 30.w),
      child: Column(
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primaryGold,
              inactiveTrackColor: Colors.white24,
              thumbColor: AppColors.primaryGold,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6.r),
              trackHeight: 3.h,
              overlayShape: RoundSliderOverlayShape(overlayRadius: 12.r),
              overlayColor: AppColors.primaryGold.withOpacity(0.2),
            ),
            child: Slider(
              value: _currentProgress,
              onChanged: (value) {
                final newPosition = Duration(
                  seconds: (effectiveDuration.inSeconds * value).round(),
                );
                _audioService.seek(newPosition);
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
                    color: Colors.white60,
                  ),
                ),
                Text(
                  _formatDuration(effectiveDuration),
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: Colors.white60,
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
          icon: const Icon(Icons.replay_10, color: Colors.white70),
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
              color: AppColors.primaryGold,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryGold.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.black,
              size: 35.sp,
            ),
          ),
        ),
        SizedBox(width: 20.w),
        IconButton(
          icon: const Icon(Icons.forward_10, color: Colors.white70),
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
              color: _isLooping ? AppColors.primaryGold : Colors.white38,
            ),
            onPressed: _toggleLoop,
          ),
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.redAccent : Colors.white38,
            ),
            onPressed: () => setState(() => _isFavorite = !_isFavorite),
          ),
          IconButton(
            icon: Icon(
              Icons.bedtime,
              color: _sleepTimerMinutes != null
                  ? AppColors.primaryGold
                  : Colors.white38,
            ),
            onPressed: () {
              PlayerModals.showSleepTimer(
                context,
                _sleepTimerMinutes,
                _audioService,
                (minutes) => setState(() => _sleepTimerMinutes = minutes),
              );
            },
          ),
          IconButton(
            icon: Icon(
              _autoPlayEnabled ? Icons.queue_music : Icons.music_off,
              color: _autoPlayEnabled ? AppColors.primaryGold : Colors.white38,
            ),
            onPressed: _toggleAutoPlay,
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');

    if (duration.inHours > 0) {
      final hours = duration.inHours;
      final minutes = twoDigits(duration.inMinutes.remainder(60));
      final seconds = twoDigits(duration.inSeconds.remainder(60));
      return '$hours:$minutes:$seconds';
    } else {
      final minutes = twoDigits(duration.inMinutes.remainder(60));
      final seconds = twoDigits(duration.inSeconds.remainder(60));
      return '$minutes:$seconds';
    }
  }
}
