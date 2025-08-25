// lib/features/player/audio_player_screen.dart

import 'dart:async';
import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../services/audio_player_service.dart';
import 'widgets/player_modals.dart';
import 'test_audio_data.dart'; // Add test data import

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

    // Initialize session data - use test data if no session provided
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
    // Get safe area and screen dimensions for responsive design
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final safeAreaTop = mediaQuery.padding.top;
    final safeAreaBottom = mediaQuery.padding.bottom;
    final availableHeight = screenHeight - safeAreaTop - safeAreaBottom;

    // Responsive sizing based on available height
    final isSmallScreen = availableHeight < 700; // For phones like Huawei P20
    final visualizerSize = isSmallScreen ? 200.w : 250.w;
    final controlButtonSize = isSmallScreen ? 50.w : 60.w;
    final iconButtonSize = isSmallScreen ? 36.w : 44.w;

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
              // Header
              _buildHeader(),

              // Main content - use Expanded with Column for proper spacing
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Container(
                    height: isSmallScreen
                        ? null
                        : availableHeight - 60.h, // Adjust for header
                    child: Column(
                      mainAxisAlignment: isSmallScreen
                          ? MainAxisAlignment.start
                          : MainAxisAlignment.spaceEvenly,
                      children: [
                        // Visualizer Section
                        Flexible(
                          flex: isSmallScreen ? 0 : 3,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(height: isSmallScreen ? 20.h : 10.h),
                              _buildVisualizer(visualizerSize),
                            ],
                          ),
                        ),

                        // Middle Section - Session Info & Track Selector
                        Flexible(
                          flex: isSmallScreen ? 0 : 2,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(height: isSmallScreen ? 20.h : 10.h),
                              _buildSessionInfo(),
                              SizedBox(height: isSmallScreen ? 15.h : 20.h),
                              _buildTrackSelector(),
                            ],
                          ),
                        ),

                        // Controls Section
                        Flexible(
                          flex: isSmallScreen ? 0 : 3,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(height: isSmallScreen ? 15.h : 10.h),
                              _buildProgressBar(),
                              SizedBox(height: isSmallScreen ? 20.h : 25.h),
                              _buildPlaybackControls(
                                  controlButtonSize, iconButtonSize),
                              SizedBox(height: isSmallScreen ? 15.h : 20.h),
                              _buildAdditionalControls(),
                              SizedBox(height: isSmallScreen ? 20.h : 10.h),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
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
                color: Colors.white, size: 28.sp),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            'NOW PLAYING',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
              letterSpacing: 1.2,
            ),
          ),
          // Empty container to maintain spacing instead of three dots
          SizedBox(width: 44.w),
        ],
      ),
    );
  }

  Widget _buildVisualizer(double size) {
    return Container(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Animated waves
          AnimatedBuilder(
            animation: _waveController,
            builder: (context, child) {
              return CustomPaint(
                size: Size(size, size),
                painter: WavePainter(
                  animation: _waveController,
                  color: AppColors.primaryGold.withOpacity(0.3),
                ),
              );
            },
          ),

          // Center circle with emoji
          Container(
            width: size * 0.6,
            height: size * 0.6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryGold,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryGold.withOpacity(0.5),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Center(
              child: Text(
                _session['emoji'] ?? '🎵',
                style: TextStyle(fontSize: size * 0.25),
              ),
            ),
          ),
        ],
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
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 8.h),
          Text(
            _currentTrack == 'intro'
                ? (_session['intro']['title'] ?? 'Introduction')
                : (_session['subliminal']['title'] ?? 'Subliminal'),
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
                      ? Colors.white.withOpacity(0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  'Introduction',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: _currentTrack == 'intro'
                        ? FontWeight.w600
                        : FontWeight.w400,
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
                    fontWeight: _currentTrack == 'subliminal'
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: _currentTrack == 'subliminal'
                        ? AppColors.textPrimary
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
                setState(() => _currentProgress = value);
                final newPosition = Duration(
                  seconds: (_totalDuration.inSeconds * value).round(),
                );
                _audioService.seek(newPosition);
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w),
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
                  _formatDuration(_totalDuration),
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

  Widget _buildPlaybackControls(double mainButtonSize, double sideButtonSize) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Previous/Replay button
        IconButton(
          icon: Icon(Icons.replay_10, color: Colors.white70),
          iconSize: sideButtonSize * 0.6,
          onPressed: () => _audioService.replay_15(),
        ),

        SizedBox(width: 20.w),

        // Play/Pause button
        GestureDetector(
          onTap: _togglePlayPause,
          child: Container(
            width: mainButtonSize,
            height: mainButtonSize,
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
              color: AppColors.textPrimary,
              size: mainButtonSize * 0.5,
            ),
          ),
        ),

        SizedBox(width: 20.w),

        // Next/Forward button
        IconButton(
          icon: Icon(Icons.forward_10, color: Colors.white70),
          iconSize: sideButtonSize * 0.6,
          onPressed: () => _audioService.forward_15(),
        ),
      ],
    );
  }

  Widget _buildAdditionalControls() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 40.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Loop button
          IconButton(
            icon: Icon(
              Icons.loop,
              color: _isLooping ? AppColors.primaryGold : Colors.white38,
            ),
            iconSize: 22.sp,
            onPressed: () {
              setState(() => _isLooping = !_isLooping);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isLooping ? 'Loop enabled' : 'Loop disabled'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),

          // Favorite button
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.redAccent : Colors.white38,
            ),
            iconSize: 22.sp,
            onPressed: () {
              setState(() => _isFavorite = !_isFavorite);
            },
          ),

          // Sleep timer
          IconButton(
            icon: Icon(
              Icons.bedtime,
              color: _sleepTimerMinutes != null
                  ? AppColors.primaryGold
                  : Colors.white38,
            ),
            iconSize: 22.sp,
            onPressed: () {
              PlayerModals.showSleepTimer(
                context,
                _sleepTimerMinutes,
                _audioService,
                (minutes) {
                  setState(() => _sleepTimerMinutes = minutes);
                },
              );
            },
          ),

          // Volume control
          IconButton(
            icon: Icon(
              Icons.volume_up,
              color: Colors.white38,
            ),
            iconSize: 22.sp,
            onPressed: () {
              PlayerModals.showVolumeControl(
                context,
                _volume,
                _audioService,
                (newVolume) {
                  setState(() => _volume = newVolume);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}

// Wave Painter for visualizer
class WavePainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;

  WavePainter({
    required this.animation,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) / 2;

    for (int i = 0; i < 3; i++) {
      final progress = ((animation.value + (i * 0.2)) % 1.0);
      final radius = maxRadius * progress;
      final opacity = 1.0 - progress;

      paint.color = color.withOpacity(opacity * 0.5);
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) => true;
}
