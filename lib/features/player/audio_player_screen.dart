// lib/features/player/audio_player_screen_modern.dart

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
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

  // Audio Service
  final AudioPlayerService _audioService = AudioPlayerService();

  // Audio State
  bool _isPlaying = false;
  bool _isFavorite = false;
  bool _isLooping = false;
  bool _isShuffled = false;
  String _currentTrack = 'intro'; // 'intro' or 'subliminal'
  bool _autoPlayEnabled = true;
  double _currentProgress = 0.0;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  double _volume = 0.7;
  int? _sleepTimerMinutes;

  // Session data
  late Map<String, dynamic> _session;
  late int _introDuration;
  late int _subliminalDuration;

  // Stream subscriptions
  StreamSubscription<bool>? _playingSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;

  @override
  void initState() {
    super.initState();
    print('SESSION DATA RECEIVED:');
    print('Title: ${widget.sessionData?['title']}');
    print('Background Image: ${widget.sessionData?['backgroundImage']}');
    print('Intro Audio URL: ${widget.sessionData?['intro']?['audioUrl']}');
    print(
        'Subliminal Audio URL: ${widget.sessionData?['subliminal']?['audioUrl']}');

    // Initialize session data
    _session = widget.sessionData ??
        {
          'id': 'test_session',
          'title': 'Deep Sleep Healing',
          'category': 'Sleep',
          'backgroundImage':
              'https://images.unsplash.com/photo-1511295742362-92c96b1cf484?w=800',
          'intro': {
            'title': 'Relaxation Introduction',
            'duration': 120,
            'description': 'A gentle introduction to prepare your mind',
            'audioUrl':
                'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
          },
          'subliminal': {
            'title': 'Deep Sleep Subliminals',
            'duration': 7200,
            'description':
                'Powerful subliminal affirmations for deep healing sleep',
            'audioUrl':
                'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
          },
        };

    _introDuration = _session['intro']['duration'] as int;
    _subliminalDuration = _session['subliminal']['duration'] as int;
    _totalDuration = Duration(seconds: _introDuration);

    // Initialize animations
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _waveController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    // Initialize audio
    _initializeAudio();

    // Check if favorite
    _checkFavoriteStatus();
  }

  Future<void> _initializeAudio() async {
    await _audioService.initialize();

    // Listen to playback state
    _playingSubscription = _audioService.isPlaying.listen((playing) {
      if (mounted) {
        setState(() => _isPlaying = playing);
        if (playing) {
          _waveController.repeat();
        } else {
          _waveController.stop();
        }
      }
    });

    // Listen to position updates
    _positionSubscription = _audioService.position.listen((position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
          // Calculate progress based on actual duration from audio service
          final actualDuration = _audioService.totalDuration;
          if (actualDuration.inSeconds > 0) {
            _currentProgress = position.inSeconds / actualDuration.inSeconds;
            _currentProgress = _currentProgress.clamp(0.0, 1.0);
            _totalDuration = actualDuration;
          }
        });

        // Auto-play next track when current finishes
        if (_autoPlayEnabled &&
            _currentTrack == 'intro' &&
            position.inSeconds >= _totalDuration.inSeconds - 1 &&
            _totalDuration.inSeconds > 0) {
          _switchToTrack('subliminal');
        }
      }
    });

    // Listen to duration updates
    _durationSubscription = _audioService.duration.listen((duration) {
      if (mounted && duration.inSeconds > 0) {
        setState(() {
          _totalDuration = duration;
        });
      }
    });

    // Listen to volume changes
    _audioService.volume.listen((volume) {
      if (mounted) {
        setState(() => _volume = volume);
      }
    });

    // Listen to sleep timer
    _audioService.sleepTimer.listen((minutes) {
      if (mounted) {
        setState(() => _sleepTimerMinutes = minutes);
      }
    });
  }

  void _checkFavoriteStatus() async {
    // Check if session is in favorites
    // TODO: Implement with Firebase
    setState(() {
      _isFavorite = false; // Default
    });
  }

  void _handleTrackCompletion() {
    if (_currentTrack == 'intro' && _autoPlayEnabled) {
      // Auto-play subliminal after intro
      _switchToTrack('subliminal');
    } else if (_isLooping) {
      // Loop current track
      _audioService.seek(Duration.zero);
      _playCurrentTrack();
    }
  }

  @override
  void dispose() {
    _playingSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Image with Blur
          _buildBackgroundImage(),

          // Dark Overlay
          Container(
            color: Colors.black.withOpacity(0.4),
          ),

          // Main Content
          SafeArea(
            child: Column(
              children: [
                // Top Bar
                _buildTopBar(),

                // Main Player Area
                Expanded(
                  child: Column(
                    children: [
                      const Spacer(),

                      // Album Art / Session Image
                      _buildAlbumArt(),

                      SizedBox(height: 40.h),

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

          // Sleep Timer Overlay (if active)
          if (_sleepTimerMinutes != null)
            Positioned(
              top: 100.h,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    '💤 Sleep timer: ${_sleepTimerMinutes} min',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBackgroundImage() {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: CachedNetworkImageProvider(
            _session['backgroundImage'] ??
                'https://images.unsplash.com/photo-1511295742362-92c96b1cf484?w=800',
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          color: Colors.black.withOpacity(0.2),
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
          IconButton(
            icon: Icon(Icons.more_vert, color: Colors.white, size: 24.sp),
            onPressed: _showOptionsMenu,
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumArt() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform.scale(
          scale: _isPlaying ? 1.0 + (_pulseController.value * 0.02) : 1.0,
          child: Container(
            width: 280.w,
            height: 280.w,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 30,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20.r),
              child: Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: _session['backgroundImage'] ??
                        'https://images.unsplash.com/photo-1511295742362-92c96b1cf484?w=800',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[800],
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Colors.white30,
                        ),
                      ),
                    ),
                  ),
                  // Playing indicator overlay
                  if (_isPlaying)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black26,
                      ),
                      child: Center(
                        child: _buildWaveAnimation(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWaveAnimation() {
    return SizedBox(
      width: 80.w,
      height: 40.h,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(5, (index) {
          return AnimatedBuilder(
            animation: _waveController,
            builder: (context, child) {
              final delay = index * 0.15;
              final animation = Tween<double>(
                begin: 0.2,
                end: 1.0,
              ).animate(CurvedAnimation(
                parent: _waveController,
                curve: Interval(delay, 1.0, curve: Curves.easeInOut),
              ));

              return Container(
                width: 4.w,
                height: 40.h * animation.value,
                decoration: BoxDecoration(
                  color: Colors.white70,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              );
            },
          );
        }),
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
          _buildTrackTab(
            title: 'Introduction',
            duration: _formatDuration(Duration(seconds: _introDuration)),
            isActive: _currentTrack == 'intro',
            onTap: () => _switchToTrack('intro'),
          ),
          _buildTrackTab(
            title: 'Subliminal',
            duration: _formatDuration(Duration(seconds: _subliminalDuration)),
            isActive: _currentTrack == 'subliminal',
            onTap: () => _switchToTrack('subliminal'),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackTab({
    required String title,
    required String duration,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            color:
                isActive ? Colors.white.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Column(
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive ? Colors.white : Colors.white70,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                duration,
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  color: isActive ? Colors.white70 : Colors.white54,
                ),
              ),
              if (_autoPlayEnabled && isActive && _currentTrack == 'intro')
                Padding(
                  padding: EdgeInsets.only(top: 4.h),
                  child: Text(
                    'Auto-play next ➜',
                    style: GoogleFonts.inter(
                      fontSize: 9.sp,
                      color: Colors.greenAccent,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 40.w),
      child: Column(
        children: [
          // Track Title
          Text(
            _currentTrack == 'intro'
                ? _session['intro']['title']
                : _session['subliminal']['title'],
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            _session['title'],
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              color: Colors.white70,
            ),
          ),
          SizedBox(height: 24.h),

          // Progress Slider
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4.h,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8.r),
              overlayShape: RoundSliderOverlayShape(overlayRadius: 16.r),
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.white24,
              thumbColor: Colors.white,
              overlayColor: Colors.white24,
            ),
            child: Slider(
              value: _currentProgress,
              onChanged: (value) async {
                setState(() => _currentProgress = value);
                final newPosition = Duration(
                    milliseconds:
                        (_totalDuration.inMilliseconds * value).round());
                await _audioService.seek(newPosition);
              },
            ),
          ),

          // Time Labels
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(_currentPosition),
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: Colors.white70,
                  ),
                ),
                Text(
                  '-${_formatDuration(_totalDuration - _currentPosition)}',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: Colors.white70,
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
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 40.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Shuffle
          IconButton(
            icon: Icon(
              Icons.shuffle,
              color: _isShuffled ? Colors.greenAccent : Colors.white54,
              size: 24.sp,
            ),
            onPressed: () {
              setState(() => _isShuffled = !_isShuffled);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isShuffled ? 'Shuffle ON' : 'Shuffle OFF'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),

          // Previous
          IconButton(
            icon: Icon(Icons.skip_previous, color: Colors.white, size: 36.sp),
            onPressed: _previousTrack,
          ),

          // Play/Pause
          GestureDetector(
            onTap: _togglePlayPause,
            child: Container(
              width: 72.w,
              height: 72.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.white70],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                size: 36.sp,
                color: Colors.black87,
              ),
            ),
          ),

          // Next
          IconButton(
            icon: Icon(Icons.skip_next, color: Colors.white, size: 36.sp),
            onPressed: _nextTrack,
          ),

          // Loop
          IconButton(
            icon: Icon(
              Icons.repeat,
              color: _isLooping ? Colors.greenAccent : Colors.white54,
              size: 24.sp,
            ),
            onPressed: () {
              setState(() => _isLooping = !_isLooping);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isLooping ? 'Loop ON' : 'Loop OFF'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomOptions() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 40.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Favorite
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.redAccent : Colors.white70,
              size: 24.sp,
            ),
            onPressed: _toggleFavorite,
          ),

          // Sleep Timer
          IconButton(
            icon: Icon(
              Icons.bedtime,
              color: _sleepTimerMinutes != null
                  ? Colors.blueAccent
                  : Colors.white70,
              size: 24.sp,
            ),
            onPressed: _showSleepTimer,
          ),

          // Volume
          IconButton(
            icon: Icon(Icons.volume_up, color: Colors.white70, size: 24.sp),
            onPressed: _showVolumeControl,
          ),

          // Playlist/Queue
          IconButton(
            icon: Icon(Icons.queue_music, color: Colors.white70, size: 24.sp),
            onPressed: _showPlaylist,
          ),

          // Share
          IconButton(
            icon: Icon(Icons.share, color: Colors.white70, size: 24.sp),
            onPressed: _shareSession,
          ),
        ],
      ),
    );
  }

  // Action Methods
  void _switchToTrack(String track) async {
    if (_currentTrack != track) {
      // Stop current playback
      await _audioService.stop();

      setState(() {
        _currentTrack = track;
        _currentPosition = Duration.zero;
        _currentProgress = 0.0;
        _totalDuration = Duration(
            seconds: track == 'intro' ? _introDuration : _subliminalDuration);
      });

      // If was playing, start the new track
      if (_isPlaying) {
        await _playCurrentTrack();
      }
    }
  }

  void _togglePlayPause() async {
    // Immediately update UI state
    setState(() => _isPlaying = !_isPlaying);

    if (_isPlaying) {
      // Start playing
      await _playCurrentTrack();
      _waveController.repeat();
    } else {
      // Pause
      await _audioService.pause();
      _waveController.stop();
    }
  }

  Future<void> _playCurrentTrack() async {
    try {
      final audioUrl = _currentTrack == 'intro'
          ? _session['intro']['audioUrl']
          : _session['subliminal']['audioUrl'];

      // Test URL - gerçek uygulamada Firebase'den gelecek
      final testUrl = audioUrl ??
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3';

      await _audioService.playFromUrl(
        testUrl,
        title: _currentTrack == 'intro'
            ? _session['intro']['title']
            : _session['subliminal']['title'],
        artist: 'INSIDEX',
      );

      // Update total duration for current track
      setState(() {
        _totalDuration = Duration(
            seconds: _currentTrack == 'intro'
                ? _introDuration
                : _subliminalDuration);
      });
    } catch (e) {
      print('Error playing audio: $e');
      setState(() => _isPlaying = false);
      _waveController.stop();
    }
  }

  void _previousTrack() {
    if (_currentPosition.inSeconds > 3) {
      // If more than 3 seconds played, restart current track
      _audioService.seek(Duration.zero);
    } else if (_currentTrack == 'subliminal') {
      // Go back to intro
      _switchToTrack('intro');
    } else {
      // Already at intro, restart
      _audioService.seek(Duration.zero);
    }
  }

  void _nextTrack() {
    if (_currentTrack == 'intro') {
      _switchToTrack('subliminal');
    } else {
      // Already at subliminal, maybe go to next session or stop
      if (_isLooping) {
        _switchToTrack('intro');
      }
    }
  }

  void _toggleFavorite() async {
    setState(() => _isFavorite = !_isFavorite);

    // Save to Firebase
    if (_session['id'] != null) {
      await FirebaseService.toggleFavorite(_session['id']);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(_isFavorite ? 'Added to favorites' : 'Removed from favorites'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _showSleepTimer() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Sleep Timer',
                  style: GoogleFonts.inter(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8.h),
                if (_sleepTimerMinutes != null)
                  Text(
                    'Active: $_sleepTimerMinutes minutes',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      color: Colors.greenAccent,
                    ),
                  ),
                SizedBox(height: 24.h),
                Wrap(
                  spacing: 12.w,
                  runSpacing: 12.h,
                  children: [15, 30, 45, 60, 90, 120].map((minutes) {
                    final isSelected = _sleepTimerMinutes == minutes;
                    return ChoiceChip(
                      label: Text(
                        '$minutes min',
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          _audioService.setSleepTimer(minutes);
                          setState(() => _sleepTimerMinutes = minutes);
                          setModalState(() {}); // Update modal state

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text('Sleep timer set to $minutes minutes'),
                              duration: Duration(seconds: 2),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else {
                          _audioService.cancelSleepTimer();
                          setState(() => _sleepTimerMinutes = null);
                          setModalState(() {}); // Update modal state
                        }
                        Navigator.pop(context);
                      },
                      backgroundColor: Colors.grey[800],
                      selectedColor: Colors.greenAccent.withOpacity(0.3),
                      checkmarkColor: Colors.greenAccent,
                      side: BorderSide(
                        color:
                            isSelected ? Colors.greenAccent : Colors.grey[700]!,
                        width: isSelected ? 2 : 1,
                      ),
                    );
                  }).toList(),
                ),
                if (_sleepTimerMinutes != null) ...[
                  SizedBox(height: 16.h),
                  TextButton.icon(
                    onPressed: () {
                      _audioService.cancelSleepTimer();
                      setState(() => _sleepTimerMinutes = null);
                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Sleep timer cancelled'),
                          duration: Duration(seconds: 2),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    },
                    icon: Icon(Icons.cancel, color: Colors.redAccent),
                    label: Text(
                      'Cancel Timer',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ],
                SizedBox(height: 20.h),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showVolumeControl() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Volume Control',
                  style: GoogleFonts.inter(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 24.h),
                Row(
                  children: [
                    Icon(
                      _volume == 0 ? Icons.volume_off : Icons.volume_down,
                      color: Colors.white70,
                      size: 24.sp,
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 4.h,
                          thumbShape:
                              RoundSliderThumbShape(enabledThumbRadius: 10.r),
                          overlayShape:
                              RoundSliderOverlayShape(overlayRadius: 20.r),
                          activeTrackColor: Colors.greenAccent,
                          inactiveTrackColor: Colors.grey[700],
                          thumbColor: Colors.greenAccent,
                          overlayColor: Colors.greenAccent.withOpacity(0.2),
                        ),
                        child: Slider(
                          value: _volume,
                          min: 0.0,
                          max: 1.0,
                          divisions: 20,
                          onChanged: (value) {
                            // Update both modal state and main state
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
                    ),
                    Icon(
                      _volume > 0.7 ? Icons.volume_up : Icons.volume_down,
                      color: Colors.white70,
                      size: 24.sp,
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    '${(_volume * 100).round()}%',
                    style: GoogleFonts.inter(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.greenAccent,
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                // Quick volume presets
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [0.0, 0.25, 0.5, 0.75, 1.0].map((preset) {
                    return TextButton(
                      onPressed: () {
                        setModalState(() {
                          _volume = preset;
                        });
                        setState(() {
                          _volume = preset;
                        });
                        _audioService.setVolume(preset);
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: _volume == preset
                            ? Colors.greenAccent.withOpacity(0.2)
                            : Colors.grey[800],
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 8.h),
                      ),
                      child: Text(
                        '${(preset * 100).round()}%',
                        style: TextStyle(
                          color: _volume == preset
                              ? Colors.greenAccent
                              : Colors.white70,
                          fontWeight: _volume == preset
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 20.h),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showPlaylist() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Playlist feature coming soon!'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _shareSession() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Share feature coming soon!'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.info_outline, color: Colors.white70),
              title: Text(
                'Session Info',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                // Show session details
              },
            ),
            ListTile(
              leading: Icon(Icons.download, color: Colors.white70),
              title: Text(
                'Download for Offline',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Premium feature')),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.report_problem, color: Colors.white70),
              title: Text(
                'Report Issue',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                // Report issue
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);
      return '${hours}h ${minutes}m';
    } else {
      final minutes = duration.inMinutes.remainder(60);
      final seconds = duration.inSeconds.remainder(60);
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }
}
