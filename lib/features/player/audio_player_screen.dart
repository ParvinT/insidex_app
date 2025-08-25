// lib/features/player/audio_player_screen.dart

import 'dart:async';
import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../services/audio_player_service.dart';
import '../../services/firebase_service.dart';

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
  String _currentTrack = 'intro'; // 'intro' or 'subliminal'
  double _currentProgress = 0.0;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  double _volume = 0.7;
  int? _sleepTimerMinutes;

  // Session data
  late Map<String, dynamic> _session;

  // Stream subscriptions
  StreamSubscription<bool>? _playingSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;

  // Track completion timer
  Timer? _completionCheckTimer;

  @override
  void initState() {
    super.initState();

    // Initialize session data
    _session = widget.sessionData ??
        {
          'id': 'test_session',
          'title': 'Deep Sleep Healing',
          'category': 'Sleep',
          'emoji': '🌙',
          'intro': {
            'title': 'Relaxation Introduction',
            'description': 'A gentle introduction to prepare your mind',
            'audioUrl': '',
          },
          'subliminal': {
            'title': 'Deep Sleep Subliminals',
            'description':
                'Powerful subliminal affirmations for deep healing sleep',
            'audioUrl': '',
          },
        };

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

    // Set initial volume after initialization
    await _audioService.setVolume(_volume);

    _playingSubscription = _audioService.isPlaying.listen((playing) {
      if (mounted) {
        setState(() => _isPlaying = playing);
        if (playing) {
          _waveController.repeat();
          _rotationController.repeat();
        } else {
          _waveController.stop();
          _rotationController.stop();
        }
      }
    });

    _positionSubscription = _audioService.position.listen((position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
          if (_totalDuration.inSeconds > 0) {
            _currentProgress = position.inSeconds / _totalDuration.inSeconds;
            _currentProgress = _currentProgress.clamp(0.0, 1.0);

            // Check for track completion for auto-play
            if (_autoPlayEnabled &&
                position.inSeconds >= _totalDuration.inSeconds - 1 &&
                _totalDuration.inSeconds > 0) {
              _handleTrackCompletion();
            }
          }
        });
      }
    });

    _durationSubscription = _audioService.duration.listen((duration) {
      if (mounted && duration.inSeconds > 0) {
        setState(() {
          _totalDuration = duration;
        });
      }
    });

    // Listen to sleep timer updates
    _audioService.sleepTimer.listen((minutes) {
      if (mounted) {
        setState(() {
          _sleepTimerMinutes = minutes;
        });
      }
    });
  }

  void _handleTrackCompletion() {
    if (_currentTrack == 'intro' && _autoPlayEnabled) {
      // Auto-play subliminal after intro
      _completionCheckTimer?.cancel();
      _completionCheckTimer = Timer(Duration(milliseconds: 500), () {
        if (mounted && !_isLooping) {
          _switchToTrack('subliminal');
        }
      });
    } else if (_isLooping) {
      // Loop current track
      _audioService.seek(Duration.zero);
      _audioService.play();
    }
  }

  void _togglePlayPause() async {
    if (_isPlaying) {
      await _audioService.pause();
    } else {
      // Check if we need to resume or start fresh
      if (_currentPosition.inSeconds > 0) {
        await _audioService.play();
      } else {
        await _playCurrentTrack();
      }
    }
  }

  Future<void> _playCurrentTrack() async {
    try {
      final audioUrl = _currentTrack == 'intro'
          ? _session['intro']['audioUrl']
          : _session['subliminal']['audioUrl'];

      if (audioUrl == null || audioUrl.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Audio file not found for $_currentTrack'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Stop any currently playing audio first
      await _audioService.stop();

      // Small delay to ensure clean stop
      await Future.delayed(Duration(milliseconds: 100));

      await _audioService.playFromUrl(
        audioUrl,
        title: _currentTrack == 'intro'
            ? (_session['intro']['title'] ?? 'Introduction')
            : (_session['subliminal']['title'] ?? 'Subliminal'),
        artist: 'INSIDEX',
      );
    } catch (e) {
      print('Error playing audio: $e');
      setState(() => _isPlaying = false);
    }
  }

  void _switchToTrack(String track) async {
    if (_currentTrack == track) return; // Don't restart if same track

    setState(() {
      _currentTrack = track;
      _currentPosition = Duration.zero;
      _currentProgress = 0.0;
    });

    await _audioService.stop();
    await Future.delayed(Duration(milliseconds: 200)); // Clean transition
    await _playCurrentTrack();
  }

  void _toggleAutoPlay() {
    setState(() {
      _autoPlayEnabled = !_autoPlayEnabled;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(_autoPlayEnabled ? 'Auto-play enabled' : 'Auto-play disabled'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _toggleLoop() {
    setState(() {
      _isLooping = !_isLooping;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isLooping ? 'Loop enabled' : 'Loop disabled'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _showVolumeControl() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: BoxDecoration(
            color: AppColors.textPrimary.withOpacity(0.95),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20.r),
              topRight: Radius.circular(20.r),
            ),
          ),
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Volume Control',
                style: GoogleFonts.inter(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Icon(Icons.volume_down, color: Colors.white70),
                  Expanded(
                    child: Slider(
                      value: _volume,
                      activeColor: AppColors.primaryGold,
                      inactiveColor: Colors.white30,
                      onChanged: (value) {
                        setModalState(() {
                          _volume = value;
                        });
                        setState(() {
                          _volume = value;
                        });
                        _audioService.setVolume(value);
                      },
                    ),
                  ),
                  Icon(Icons.volume_up, color: Colors.white70),
                ],
              ),
              Text(
                '${(_volume * 100).toInt()}%',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSleepTimer() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.textPrimary.withOpacity(0.95),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.r),
            topRight: Radius.circular(20.r),
          ),
        ),
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Sleep Timer',
              style: GoogleFonts.inter(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 20.h),
            Wrap(
              spacing: 10.w,
              runSpacing: 10.h,
              children: [
                _buildTimerOption(15),
                _buildTimerOption(30),
                _buildTimerOption(45),
                _buildTimerOption(60),
                _buildTimerOption(90),
                if (_sleepTimerMinutes != null)
                  ElevatedButton(
                    onPressed: () {
                      _audioService.cancelSleepTimer();
                      setState(() {
                        _sleepTimerMinutes = null;
                      });
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Cancel Timer'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerOption(int minutes) {
    return ElevatedButton(
      onPressed: () {
        _audioService.setSleepTimer(minutes);
        setState(() {
          _sleepTimerMinutes = minutes;
        });
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sleep timer set for $minutes minutes'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryGold,
        foregroundColor: AppColors.textPrimary,
      ),
      child: Text('$minutes min'),
    );
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
      backgroundColor: AppColors.backgroundWhite,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.textPrimary,
              AppColors.textPrimary.withOpacity(0.95),
              Colors.black87,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar
              _buildTopBar(),

              // Main Player Area
              Expanded(
                child: Column(
                  children: [
                    const Spacer(),

                    // Animated Player Visual
                    _buildAnimatedPlayer(),

                    SizedBox(height: 40.h),

                    // Session Info
                    _buildSessionInfo(),

                    SizedBox(height: 24.h),

                    // Track Selector
                    _buildTrackSelector(),

                    SizedBox(height: 24.h),

                    // Progress Bar
                    _buildProgressBar(),

                    SizedBox(height: 32.h),

                    // Controls
                    _buildControls(),

                    const Spacer(),

                    // Bottom Options
                    _buildBottomOptions(),

                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: EdgeInsets.all(20.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.keyboard_arrow_down,
                color: Colors.white, size: 32.sp),
            onPressed: () => Navigator.pop(context),
          ),
          Column(
            children: [
              Text(
                'NOW PLAYING',
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                  letterSpacing: 1.5,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                _session['category'] ?? 'Session',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(width: 32.sp), // Empty space instead of menu button
        ],
      ),
    );
  }

  Widget _buildAnimatedPlayer() {
    return SizedBox(
      width: 280.w,
      height: 280.w,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer rotating ring
          AnimatedBuilder(
            animation: _rotationController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationController.value * 2 * math.pi,
                child: Container(
                  width: 280.w,
                  height: 280.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [
                        AppColors.primaryGold.withOpacity(0.3),
                        Colors.white.withOpacity(0.1),
                        AppColors.primaryGold.withOpacity(0.3),
                        Colors.white.withOpacity(0.1),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // Pulse rings
          ...List.generate(3, (index) {
            return AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final value = (_pulseController.value + (index * 0.33)) % 1.0;
                return Container(
                  width: 200.w + (80.w * value),
                  height: 200.w + (80.w * value),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          AppColors.primaryGold.withOpacity(0.3 * (1 - value)),
                      width: 2,
                    ),
                  ),
                );
              },
            );
          }),

          // Center circle with emoji
          Container(
            width: 180.w,
            height: 180.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryGold,
                  AppColors.primaryGold.withOpacity(0.7),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryGold.withOpacity(0.5),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedSwitcher(
                    duration: Duration(milliseconds: 300),
                    child: _isPlaying
                        ? _buildWaveAnimation()
                        : Text(
                            _session['emoji'] ?? '🎵',
                            style: TextStyle(fontSize: 60.sp),
                            key: ValueKey('emoji'),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaveAnimation() {
    return SizedBox(
      width: 60.w,
      height: 30.h,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(5, (index) {
          return AnimatedBuilder(
            animation: _waveController,
            builder: (context, child) {
              final value = math.sin((_waveController.value * 2 * math.pi) +
                  (index * math.pi / 5));
              return Container(
                width: 4.w,
                height: 10.h + (20.h * ((value + 1) / 2)),
                decoration: BoxDecoration(
                  color: AppColors.textPrimary,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildSessionInfo() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 40.w),
      child: Column(
        children: [
          Text(
            _session['title'] ?? 'Session',
            style: GoogleFonts.inter(
              fontSize: 24.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          Text(
            _currentTrack == 'intro'
                ? (_session['intro']['title'] ?? 'Introduction')
                : (_session['subliminal']['title'] ?? 'Subliminal'),
            style: GoogleFonts.inter(
              fontSize: 16.sp,
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
      margin: EdgeInsets.symmetric(horizontal: 40.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _switchToTrack('intro'),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                decoration: BoxDecoration(
                  color: _currentTrack == 'intro'
                      ? AppColors.primaryGold.withOpacity(0.3)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  'Introduction',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: _currentTrack == 'intro'
                        ? Colors.white
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
                padding: EdgeInsets.symmetric(vertical: 12.h),
                decoration: BoxDecoration(
                  color: _currentTrack == 'subliminal'
                      ? AppColors.primaryGold.withOpacity(0.3)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  'Subliminal',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: _currentTrack == 'subliminal'
                        ? Colors.white
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
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 40.w),
      child: Column(
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primaryGold,
              inactiveTrackColor: Colors.white.withOpacity(0.3),
              thumbColor: AppColors.primaryGold,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6.r),
              trackHeight: 3.h,
            ),
            child: Slider(
              value: _currentProgress,
              onChanged: (value) {
                final newPosition = Duration(
                  seconds: (value * _totalDuration.inSeconds).toInt(),
                );
                _audioService.seek(newPosition);
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(_currentPosition),
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: Colors.white60,
                  ),
                ),
                Text(
                  _formatDuration(_totalDuration),
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
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
          icon: Icon(Icons.skip_previous, color: Colors.white60, size: 32.sp),
          onPressed: () {
            if (_currentTrack == 'subliminal') {
              _switchToTrack('intro');
            }
          },
        ),
        SizedBox(width: 20.w),
        GestureDetector(
          onTap: _togglePlayPause,
          child: Container(
            width: 64.w,
            height: 64.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryGold,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryGold.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              color: AppColors.textPrimary,
              size: 32.sp,
            ),
          ),
        ),
        SizedBox(width: 20.w),
        IconButton(
          icon: Icon(Icons.skip_next, color: Colors.white60, size: 32.sp),
          onPressed: () {
            if (_currentTrack == 'intro') {
              _switchToTrack('subliminal');
            }
          },
        ),
      ],
    );
  }

  Widget _buildBottomOptions() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 40.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : Colors.white60,
              size: 24.sp,
            ),
            onPressed: () {
              setState(() => _isFavorite = !_isFavorite);
            },
          ),
          IconButton(
            icon: Icon(
              Icons.loop,
              color: _isLooping ? AppColors.primaryGold : Colors.white60,
              size: 24.sp,
            ),
            onPressed: _toggleLoop,
          ),
          IconButton(
            icon: Icon(
              Icons.playlist_play,
              color: _autoPlayEnabled ? AppColors.primaryGold : Colors.white60,
              size: 24.sp,
            ),
            onPressed: _toggleAutoPlay,
          ),
          IconButton(
            icon: Stack(
              children: [
                Icon(
                  Icons.bedtime,
                  color: _sleepTimerMinutes != null
                      ? AppColors.primaryGold
                      : Colors.white60,
                  size: 24.sp,
                ),
                if (_sleepTimerMinutes != null)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGold,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$_sleepTimerMinutes',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 8.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: _showSleepTimer,
          ),
          IconButton(
            icon: Icon(Icons.volume_up, color: Colors.white60, size: 24.sp),
            onPressed: _showVolumeControl,
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '${duration.inHours > 0 ? '${twoDigits(duration.inHours)}:' : ''}$minutes:$seconds';
  }
}
