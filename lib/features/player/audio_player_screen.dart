import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';


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

  // Audio State
  bool _isPlaying = false;
  bool _showSubtitles = false;
  double _currentPosition = 0.0; // 0.0 to 1.0
  double _volume = 0.7;

  // Timer
  int? _sleepTimer;

  // Audio Selection State
  bool _includeIntro = true;
  bool _includeSubliminal = true;

  // Mock session data
  late Map<String, dynamic> _session;

  @override
  void initState() {
    super.initState();

    // Initialize session data
    _session = widget.sessionData ??
        {
          'title': 'Sleep',
          'category': 'Deep Sleep Healing',
          'backgroundGradient': [
            const Color(0xFF1e3c72),
            const Color(0xFF2a5298)
          ],
          'intro': {
            'title': 'Relaxation Introduction',
            'duration': 120, // 2 minutes in seconds
            'description':
                'A gentle introduction to prepare your mind for deep healing',
          },
          'subliminal': {
            'title': 'Deep Sleep Subliminals',
            'duration': 7200, // 2 hours in seconds
            'affirmations': [
              'Deep Sleep Healing',
              'Nighttime Anxiety Release',
              'Positive Mindset Overnight'
            ],
          },
          'description':
              'Subliminals for sleep are designed to work gently as you drift off and throughout the night. Play them quietly, 70-80% volumes as your subconscious mind is more open to change, making subliminal programming highly effective.',
        };

    // Initialize animations
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _waveController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    // Start pulse animation
    _pulseController.repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  // Calculate total duration based on selection
  int _getTotalDuration() {
    int total = 0;
    if (_includeIntro) total += _session['intro']['duration'] as int;
    if (_includeSubliminal) total += _session['subliminal']['duration'] as int;
    return total;
  }

  // Get current playing audio type
  String _getCurrentPlayingType() {
    if (_includeIntro && _includeSubliminal) {
      // Calculate which part is playing based on position
      final introDuration = _session['intro']['duration'] as int;
      final totalDuration = _getTotalDuration();
      final currentSeconds = (_currentPosition * totalDuration).round();

      if (currentSeconds < introDuration) {
        return 'Playing: Introduction';
      } else {
        return 'Playing: Subliminal';
      }
    } else if (_includeIntro) {
      return 'Playing: Introduction';
    } else if (_includeSubliminal) {
      return 'Playing: Subliminal';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with Back Button
            _buildTopBar(),

            // Main Player Area
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: 20.h),

                    // Audio Selection Section
                    _buildAudioSelectionSection(),

                    SizedBox(height: 20.h),

                    // Player Card
                    _buildPlayerCard(),

                    SizedBox(height: 24.h),

                    // Volume Control
                    _buildVolumeControl(),

                    SizedBox(height: 24.h),

                    // Session Info Section
                    _buildSessionInfoSection(),

                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),

            // Bottom Navigation
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      child: Row(
        children: [
          // Back Button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.greyBorder,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back,
                color: AppColors.textPrimary,
                size: 20.sp,
              ),
            ),
          ),

          const Spacer(),

          // Logo
          Text(
            'Inside⊗',
            style: GoogleFonts.inter(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),

          const Spacer(),

          // Menu button
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.greyBorder,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.more_vert,
              color: AppColors.textPrimary,
              size: 20.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioSelectionSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: AppColors.greyBorder,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Audio Selection',
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16.h),

          // Introduction Toggle
          _buildAudioToggle(
            title: 'Introduction',
            subtitle: _formatDuration(_session['intro']['duration'] as int),
            description: _session['intro']['description'],
            icon: Icons.record_voice_over,
            value: _includeIntro,
            onChanged: (value) {
              setState(() {
                _includeIntro = value;
                // At least one must be selected
                if (!_includeIntro && !_includeSubliminal) {
                  _includeSubliminal = true;
                }
              });
            },
          ),

          SizedBox(height: 16.h),

          // Subliminal Toggle
          _buildAudioToggle(
            title: 'Subliminal Session',
            subtitle:
                _formatDuration(_session['subliminal']['duration'] as int),
            description:
                'Deep healing frequencies with subliminal affirmations',
            icon: Icons.waves,
            value: _includeSubliminal,
            onChanged: (value) {
              setState(() {
                _includeSubliminal = value;
                // At least one must be selected
                if (!_includeSubliminal && !_includeIntro) {
                  _includeIntro = true;
                }
              });
            },
          ),

          SizedBox(height: 16.h),

          // Total Duration Display
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppColors.greyLight,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.access_time,
                  color: AppColors.textPrimary,
                  size: 18.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  'Total Duration: ${_formatDuration(_getTotalDuration())}',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioToggle({
    required String title,
    required String subtitle,
    required String description,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: value
            ? AppColors.textPrimary.withOpacity(0.05)
            : AppColors.greyLight,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: value ? AppColors.textPrimary : AppColors.greyBorder,
          width: value ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: value
                      ? AppColors.textPrimary.withOpacity(0.1)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  icon,
                  color:
                      value ? AppColors.textPrimary : AppColors.textSecondary,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: AppColors.textPrimary,
                inactiveThumbColor: AppColors.textSecondary,
                inactiveTrackColor: AppColors.greyLight,
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: AppColors.greyBorder,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          children: [
            // Session Info
            Row(
              children: [
                // Sound wave icon
                Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    color: AppColors.greyLight,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.greyBorder,
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.graphic_eq,
                    color: AppColors.textPrimary,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 12.w),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _session['title'],
                        style: GoogleFonts.inter(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        _session['category'],
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Music note icon
                Icon(
                  Icons.music_note,
                  color: AppColors.textSecondary,
                  size: 24.sp,
                ),
              ],
            ),

            SizedBox(height: 20.h),

            // Currently Playing Indicator
            if (_isPlaying)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: AppColors.textPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  _getCurrentPlayingType(),
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),

            SizedBox(height: 20.h),

            // Animated Pulse Circle
            _buildAnimatedPulse(),

            SizedBox(height: 40.h),

            // Player Controls
            _buildPlayerControls(),

            SizedBox(height: 20.h),

            // Progress Bar
            _buildProgressBar(),

            SizedBox(height: 16.h),

            // Additional Controls
            _buildAdditionalControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedPulse() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return SizedBox(
          width: 120.w,
          height: 120.w,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Pulse rings
              for (int i = 0; i < 3; i++)
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      final delay = i * 0.3;
                      final animation = Tween<double>(
                        begin: 0.0,
                        end: 1.0,
                      ).animate(CurvedAnimation(
                        parent: _pulseController,
                        curve: Interval(delay, 1.0, curve: Curves.easeOut),
                      ));

                      return Transform.scale(
                        scale: animation.value * 0.8 + 0.2,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.textPrimary.withOpacity(
                                (1 - animation.value) * 0.3,
                              ),
                              width: 2,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

              // Center circle
              Container(
                width: 60.w,
                height: 60.w,
                decoration: BoxDecoration(
                  color: AppColors.greyLight,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.greyBorder,
                    width: 2,
                  ),
                ),
                child: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  color: AppColors.textPrimary,
                  size: 28.sp,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlayerControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Previous
        _buildControlButton(
          icon: Icons.skip_previous,
          onTap: _previousTrack,
        ),

        SizedBox(width: 20.w),

        // Play/Pause
        GestureDetector(
          onTap: _togglePlayPause,
          child: Container(
            width: 56.w,
            height: 56.w,
            decoration: BoxDecoration(
              color: AppColors.textPrimary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 28.sp,
            ),
          ),
        ),

        SizedBox(width: 20.w),

        // Next
        _buildControlButton(
          icon: Icons.skip_next,
          onTap: _nextTrack,
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44.w,
        height: 44.w,
        decoration: BoxDecoration(
          color: AppColors.greyLight,
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.greyBorder,
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: AppColors.textPrimary,
          size: 20.sp,
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    final totalDuration = _getTotalDuration();
    final currentSeconds = (_currentPosition * totalDuration).round();

    return Column(
      children: [
        // Progress bar
        Container(
          height: 4.h,
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2.r),
            child: LinearProgressIndicator(
              value: _currentPosition,
              backgroundColor: AppColors.greyLight,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.textPrimary),
            ),
          ),
        ),

        SizedBox(height: 8.h),

        // Time labels
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(currentSeconds),
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                _formatDuration(totalDuration),
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Timer
        _buildIconButton(
          icon: Icons.timer,
          isActive: _sleepTimer != null,
          onTap: _showTimerDialog,
        ),

        // Subtitles
        _buildIconButton(
          icon: Icons.subtitles,
          isActive: _showSubtitles,
          onTap: () {
            setState(() {
              _showSubtitles = !_showSubtitles;
            });
          },
        ),

        // Share
        _buildIconButton(
          icon: Icons.share,
          onTap: () {
            // TODO: Share functionality
          },
        ),

        // Favorite
        _buildIconButton(
          icon: Icons.favorite_border,
          onTap: () {
            // TODO: Favorite functionality
          },
        ),
      ],
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40.w,
        height: 40.w,
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.textPrimary.withOpacity(0.1)
              : AppColors.greyLight,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: isActive ? AppColors.textPrimary : AppColors.greyBorder,
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
          size: 18.sp,
        ),
      ),
    );
  }

  Widget _buildVolumeControl() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 40.w),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.greyBorder,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.volume_down,
            color: AppColors.textSecondary,
            size: 20.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.textPrimary,
                inactiveTrackColor: AppColors.greyLight,
                thumbColor: AppColors.textPrimary,
                thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6.r),
                trackHeight: 3.h,
              ),
              child: Slider(
                value: _volume,
                onChanged: (value) {
                  setState(() {
                    _volume = value;
                  });
                },
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Icon(
            Icons.volume_up,
            color: AppColors.textSecondary,
            size: 20.sp,
          ),
        ],
      ),
    );
  }

  Widget _buildSessionInfoSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.greyBorder,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Session Details',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 12.h),

          // Show subliminal affirmations if selected
          if (_includeSubliminal) ...[
            Text(
              'Subliminal Affirmations:',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            ...(_session['subliminal']['affirmations'] as List<String>)
                .map((affirmation) {
              return Padding(
                padding: EdgeInsets.only(bottom: 4.h),
                child: Row(
                  children: [
                    Container(
                      width: 4.w,
                      height: 4.w,
                      decoration: const BoxDecoration(
                        color: AppColors.textSecondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        affirmation,
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            SizedBox(height: 12.h),
          ],

          Text(
            _session['description'],
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w400,
              color: AppColors.textLight,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 80.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
        border: const Border(
          top: BorderSide(
            color: AppColors.greyBorder,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(Icons.home_outlined, 'Home'),
          _buildNavItem(Icons.library_music_outlined, 'Library'),
          _buildNavItem(Icons.play_circle_outline, 'Playlist', isActive: true),
          _buildNavItem(Icons.chat_bubble_outline, 'AI Chat'),
          _buildNavItem(Icons.person_outline, 'Profile'),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, {bool isActive = false}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 24.sp,
          color: isActive ? AppColors.textPrimary : AppColors.textLight,
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10.sp,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: isActive ? AppColors.textPrimary : AppColors.textLight,
          ),
        ),
        if (isActive)
          Container(
            margin: EdgeInsets.only(top: 2.h),
            height: 2.h,
            width: 20.w,
            decoration: BoxDecoration(
              color: AppColors.textPrimary,
              borderRadius: BorderRadius.circular(1.r),
            ),
          ),
      ],
    );
  }

  // Audio Control Methods
  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _waveController.repeat();
      } else {
        _waveController.stop();
      }
    });
  }

  void _previousTrack() {
    setState(() {
      _currentPosition = 0.0;
    });
  }

  void _nextTrack() {
    // Skip to next part or next session
    if (_includeIntro && _includeSubliminal) {
      final introDuration = _session['intro']['duration'] as int;
      final totalDuration = _getTotalDuration();
      final currentSeconds = (_currentPosition * totalDuration).round();

      if (currentSeconds < introDuration) {
        // Skip to subliminal
        setState(() {
          _currentPosition = introDuration / totalDuration;
        });
      } else {
        // Go to end or next session
        setState(() {
          _currentPosition = 1.0;
        });
      }
    } else {
      // Single audio selected, go to end
      setState(() {
        _currentPosition = 1.0;
      });
    }
  }

  void _showTimerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'Sleep Timer',
          style: GoogleFonts.inter(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...[15, 30, 45, 60, 90].map((minutes) {
              return ListTile(
                title: Text(
                  '$minutes minutes',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    color: AppColors.textPrimary,
                  ),
                ),
                trailing: _sleepTimer == minutes
                    ? Icon(Icons.check,
                        color: AppColors.textPrimary, size: 20.sp)
                    : null,
                onTap: () {
                  setState(() {
                    _sleepTimer = minutes;
                  });
                  Navigator.pop(context);

                  // Show confirmation
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Sleep timer set for $minutes minutes',
                        style: GoogleFonts.inter(fontSize: 14.sp),
                      ),
                      backgroundColor: AppColors.textPrimary,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                  );
                },
              );
            }).toList(),
            ListTile(
              title: Text(
                'Cancel Timer',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                setState(() {
                  _sleepTimer = null;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    if (seconds < 3600) {
      // Less than an hour
      final minutes = seconds ~/ 60;
      final secs = seconds % 60;
      if (secs == 0) {
        return '$minutes minutes';
      }
      return '${minutes}:${secs.toString().padLeft(2, '0')}';
    } else {
      // An hour or more
      final hours = seconds ~/ 3600;
      final minutes = (seconds % 3600) ~/ 60;
      final secs = seconds % 60;
      if (hours == 1 && minutes == 0 && secs == 0) {
        return '1 hour';
      } else if (hours > 0 && minutes == 0 && secs == 0) {
        return '$hours hours';
      } else if (secs == 0) {
        return '$hours hours $minutes minutes';
      }
      return '${hours}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
  }
}
