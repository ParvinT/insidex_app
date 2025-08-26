import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/widgets/primary_button.dart';
import '../player/audio_player_screen.dart';

class SessionDetailScreen extends StatefulWidget {
  final Map<String, dynamic> sessionData;

  const SessionDetailScreen({
    super.key,
    required this.sessionData,
  });

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  bool _isFavorite = false;

  // Mock session data - Firebase'den gelecek
  late Map<String, dynamic> _session;

  @override
  void initState() {
    super.initState();

    // Initialize with passed data or mock data
    _session = widget.sessionData.isNotEmpty
        ? widget.sessionData
        : {
            'title': 'Deep Sleep Healing',
            'category': 'Sleep',
            'emoji': '😴',
            'duration': '2 hours 2 minutes',
            'introDuration': '2 minutes',
            'subliminalDuration': '2 hours',
            'description':
                'This powerful sleep session combines gentle healing frequencies with subliminal affirmations designed to promote deep, restorative sleep. Perfect for those struggling with insomnia or seeking better sleep quality.',
            'benefits': [
              'Promotes deeper sleep cycles',
              'Reduces nighttime anxiety',
              'Enhances natural healing during sleep',
              'Improves morning energy levels'
            ],
            'subliminals': [
              'I sleep deeply and peacefully',
              'My body heals while I rest',
              'I wake up refreshed and energized',
              'Sleep comes naturally to me'
            ],
            'backgroundGradient': [
              const Color(0xFF1e3c72),
              const Color(0xFF2a5298)
            ],
            'playCount': 1247,
            'rating': 4.8,
            'tags': ['Sleep', 'Healing', 'Anxiety Relief', 'Insomnia'],
          };
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
              (_session['backgroundGradient'] as List<Color>)[0]
                  .withOpacity(0.1),
              AppColors.backgroundWhite,
            ],
            stops: const [0.0, 0.3],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              _buildAppBar(),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 20.h),

                      // Session Header
                      _buildSessionHeader(),

                      SizedBox(height: 24.h),

                      // Duration Info
                      _buildDurationInfo(),

                      SizedBox(height: 24.h),

                      // Description
                      _buildDescription(),

                      SizedBox(height: 24.h),

                      // Benefits
                      _buildBenefits(),

                      SizedBox(height: 24.h),

                      // Subliminal Preview
                      _buildSubliminalPreview(),

                      SizedBox(height: 24.h),

                      // Stats
                      _buildStats(),

                      SizedBox(height: 32.h),
                    ],
                  ),
                ),
              ),

              // Bottom Action Area
              _buildBottomActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
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

          // Favorite Button
          GestureDetector(
            onTap: () {
              setState(() {
                _isFavorite = !_isFavorite;
              });
            },
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
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? Colors.red : AppColors.textPrimary,
                size: 20.sp,
              ),
            ),
          ),

          SizedBox(width: 12.w),

          // Share Button
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
              Icons.share,
              color: AppColors.textPrimary,
              size: 20.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionHeader() {
    return Container(
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
      child: Row(
        children: [
          // Emoji Icon
          Container(
            width: 60.w,
            height: 60.w,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _session['backgroundGradient'] ??
                    [
                      const Color(0xFF1e3c72),
                      const Color(0xFF2a5298),
                    ],
              ),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Center(
              child: Text(
                _session['emoji'] ?? '🎵',
                style: TextStyle(fontSize: 28.sp),
              ),
            ),
          ),

          SizedBox(width: 16.w),

          // Session Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _session['title'] ?? 'Untitled Session',
                  style: GoogleFonts.inter(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  _session['category'] ?? 'General',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 8.h),

                // Tags
                if (_session['tags'] != null)
                  Wrap(
                    spacing: 8.w,
                    children:
                        (_session['tags'] as List<String>).take(2).map((tag) {
                      return Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: AppColors.greyLight,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          tag,
                          style: GoogleFonts.inter(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationInfo() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.greyBorder,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildDurationItem(
              icon: Icons.play_circle_outline,
              label: 'Intro',
              duration: _session['introDuration'] ?? '2 minutes',
            ),
          ),
          Container(
            width: 1,
            height: 40.h,
            color: AppColors.greyBorder,
          ),
          Expanded(
            child: _buildDurationItem(
              icon: Icons.graphic_eq,
              label: 'Subliminal',
              duration: _session['subliminalDuration'] ?? '2 hours',
            ),
          ),
          Container(
            width: 1,
            height: 40.h,
            color: AppColors.greyBorder,
          ),
          Expanded(
            child: _buildDurationItem(
              icon: Icons.timer,
              label: 'Total',
              duration: _session['duration'] ?? '2 hours 2 minutes',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationItem({
    required IconData icon,
    required String label,
    required String duration,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppColors.textPrimary,
          size: 20.sp,
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10.sp,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          duration,
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.greyBorder,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About This Session',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            _session['description'] ?? 'No description available.',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefits() {
    if (_session['benefits'] == null) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.greyBorder,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Benefits',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 12.h),
          ...(_session['benefits'] as List<String>).map((benefit) {
            return Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Row(
                children: [
                  Container(
                    width: 6.w,
                    height: 6.w,
                    decoration: const BoxDecoration(
                      color: AppColors.textPrimary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      benefit,
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSubliminalPreview() {
    if (_session['subliminals'] == null) return const SizedBox.shrink();

    final subliminalsList = _session['subliminals'] as List<String>;

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.greyBorder,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Subliminal Affirmations',
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.greyLight,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  'Preview',
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ...subliminalsList.take(3).map((subliminal) {
            return Padding(
              padding: EdgeInsets.only(bottom: 6.h),
              child: Text(
                '"$subliminal"',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            );
          }),
          if (subliminalsList.length > 3) ...[
            SizedBox(height: 8.h),
            Text(
              '+ ${subliminalsList.length - 3} more affirmations',
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.textLight,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.greyBorder,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              icon: Icons.play_arrow,
              value: '${_session['playCount'] ?? 0}',
              label: 'Plays',
            ),
          ),
          Container(
            width: 1,
            height: 40.h,
            color: AppColors.greyBorder,
          ),
          Expanded(
            child: _buildStatItem(
              icon: Icons.star,
              value: '${_session['rating'] ?? 0.0}',
              label: 'Rating',
            ),
          ),
          Container(
            width: 1,
            height: 40.h,
            color: AppColors.greyBorder,
          ),
          Expanded(
            child: _buildStatItem(
              icon: Icons.favorite,
              value: '${((_session['playCount'] ?? 0) * 0.12).round()}',
              label: 'Likes',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppColors.textPrimary,
          size: 20.sp,
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10.sp,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
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
        children: [
          // Add to Playlist
          Expanded(
            flex: 1,
            child: Container(
              height: 48.h,
              decoration: BoxDecoration(
                color: AppColors.greyLight,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: AppColors.greyBorder,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.playlist_add,
                  color: AppColors.textPrimary,
                  size: 24.sp,
                ),
              ),
            ),
          ),

          SizedBox(width: 12.w),

          // Play Button
          Expanded(
            flex: 3,
            child: PrimaryButton(
              text: 'Start Session',
              onPressed: () {
                // Prepare complete session data for Audio Player
                final audioSessionData = {
                  'title': _session['title'] ?? 'Session',
                  'category': _session['category'] ?? 'General',
                  'emoji': _session['emoji'] ?? '🎵',
                  'backgroundGradient': _session['backgroundGradient'] ??
                      [const Color(0xFF1e3c72), const Color(0xFF2a5298)],
                  'intro': {
                    'title': 'Relaxation Introduction',
                    'duration': 120, // 2 minutes in seconds
                    'description': _session['description'] ??
                        'A gentle introduction to prepare your mind',
                  },
                  'subliminal': {
                    'title': _session['title'] ?? 'Subliminal Session',
                    'duration': 7200, // 2 hours in seconds
                    'affirmations': _session['subliminals'] ??
                        [
                          'Positive affirmation 1',
                          'Positive affirmation 2',
                          'Positive affirmation 3'
                        ],
                  },
                  'description': _session['description'] ??
                      'This session is designed to help you achieve your goals through powerful subliminal programming.',
                };

                // Navigate to Audio Player with complete session data
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AudioPlayerScreen(
                      sessionData: audioSessionData,
                    ),
                  ),
                );
              },
              backgroundColor: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
