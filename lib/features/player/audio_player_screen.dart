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
  bool _autoPlayEnabled = true; // Auto-play varsayılan olarak açık
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

          // Duration yoksa veya hatalıysa session'dan al
          if (_totalDuration.inSeconds == 0 ||
              _totalDuration.inSeconds < position.inSeconds) {
            _setDurationFromSession();
          }

          // Progress hesaplama - duration'ın doğru olduğundan emin ol
          if (_totalDuration.inSeconds > 0) {
            // Position, duration'ı geçmesin
            if (position.inSeconds <= _totalDuration.inSeconds) {
              _currentProgress = position.inSeconds / _totalDuration.inSeconds;
            } else {
              // Position duration'ı geçtiyse, duration yanlış demektir
              _setDurationFromSession();
              if (_totalDuration.inSeconds > position.inSeconds) {
                _currentProgress =
                    position.inSeconds / _totalDuration.inSeconds;
              } else {
                _currentProgress = 0.99; // Maksimum %99
              }
            }
            _currentProgress = _currentProgress.clamp(0.0, 1.0);

            // Check for track completion for auto-play
            if (_autoPlayEnabled &&
                _currentTrack == 'intro' &&
                position.inSeconds >= _totalDuration.inSeconds - 1 &&
                _totalDuration.inSeconds > 0) {
              _handleTrackCompletion();
            }
          } else {
            _currentProgress = 0.0;
          }
        });
      }
    });

    _durationSubscription = _audioService.duration.listen((duration) {
      if (mounted) {
        // Duration kontrolü - 0 veya hatalı ise session'dan al
        if (duration.inSeconds > 0 && duration.inSeconds < 10800) {
          // Max 3 saat
          setState(() {
            _totalDuration = duration;
          });
        } else {
          // Session'dan duration'ı al
          _setDurationFromSession();
        }
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

  // Session'dan duration ayarla
  void _setDurationFromSession() {
    if (_currentTrack == 'intro' && _session['intro'] != null) {
      final introDuration = _session['intro']['duration'];
      if (introDuration != null) {
        setState(() {
          _totalDuration = Duration(seconds: introDuration);
        });
      }
    } else if (_currentTrack == 'subliminal' &&
        _session['subliminal'] != null) {
      final subliminalDuration = _session['subliminal']['duration'];
      if (subliminalDuration != null) {
        setState(() {
          _totalDuration = Duration(seconds: subliminalDuration);
        });
      }
    }
  }

  void _handleTrackCompletion() {
    if (_currentTrack == 'intro' && _autoPlayEnabled && !_isLooping) {
      // Auto-play subliminal after intro
      _completionCheckTimer?.cancel();
      _completionCheckTimer = Timer(Duration(milliseconds: 500), () {
        if (mounted) {
          _switchToTrack('subliminal');

          // Bildirim göster
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

      // Session'dan duration'ı al
      final durationInSeconds = _currentTrack == 'intro'
          ? (_session['intro']['duration'] ?? 120)
          : (_session['subliminal']['duration'] ?? 7200);

      await _audioService.playFromUrl(
        audioUrl,
        title: _currentTrack == 'intro'
            ? (_session['intro']['title'] ?? 'Introduction')
            : (_session['subliminal']['title'] ?? 'Subliminal'),
        artist: 'INSIDEX',
        durationInSeconds: durationInSeconds, // Duration'ı gönder
      );

      // Duration'ı manuel olarak da ayarla
      setState(() {
        _totalDuration = Duration(seconds: durationInSeconds);
      });
    } catch (e) {
      print('Error playing audio: $e');
      setState(() => _isPlaying = false);
    }
  }

  void _switchToTrack(String track) async {
    if (_currentTrack == track) return;

    setState(() {
      _currentTrack = track;
      _currentPosition = Duration.zero;
      _currentProgress = 0.0;
      _totalDuration = Duration.zero; // Reset duration
    });

    await _audioService.stop();
    await Future.delayed(Duration(milliseconds: 200));

    // Track değiştiğinde duration'ı session'dan ayarla
    _setDurationFromSession();

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
        backgroundColor: AppColors.primaryGold,
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
        backgroundColor: AppColors.primaryGold,
        duration: Duration(seconds: 1),
      ),
    );
  }

  // 10 saniye geri al (düzeltildi)
  void _replay10() async {
    final newPosition = _currentPosition - const Duration(seconds: 10);
    await _audioService
        .seek(newPosition.isNegative ? Duration.zero : newPosition);
  }

  // 10 saniye ileri al (düzeltildi)
  void _forward10() async {
    final newPosition = _currentPosition + const Duration(seconds: 10);
    if (_totalDuration > Duration.zero && newPosition < _totalDuration) {
      await _audioService.seek(newPosition);
    } else if (_totalDuration > Duration.zero) {
      await _audioService.seek(_totalDuration - const Duration(seconds: 1));
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
                ? (_session['intro']['title'] ?? 'Introduction')
                : (_session['subliminal']['title'] ?? 'Subliminal'),
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
                      ? Colors.white.withOpacity(0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  'Introduction',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
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
                  seconds: (_totalDuration.inSeconds * value).round(),
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

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 10 saniye geri
        IconButton(
          icon: Icon(Icons.replay_10, color: Colors.white70),
          iconSize: 32.sp,
          onPressed: _replay10,
        ),

        SizedBox(width: 20.w),

        // Play/Pause
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

        // 10 saniye ileri
        IconButton(
          icon: Icon(Icons.forward_10, color: Colors.white70),
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
          // Loop
          IconButton(
            icon: Icon(
              Icons.loop,
              color: _isLooping ? AppColors.primaryGold : Colors.white38,
            ),
            onPressed: _toggleLoop,
          ),

          // Favorite
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.redAccent : Colors.white38,
            ),
            onPressed: () => setState(() => _isFavorite = !_isFavorite),
          ),

          // Sleep Timer
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

          // Auto-play toggle
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
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
