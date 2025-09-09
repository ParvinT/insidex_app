// lib/features/library/session_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/widgets/primary_button.dart';
import '../player/audio_player_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SessionDetailScreen extends StatefulWidget {
  final Map<String, dynamic> sessionData;

  const SessionDetailScreen({super.key, required this.sessionData});

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  bool _isFavorite = false;
  late Map<String, dynamic> _session;

  @override
  void initState() {
    super.initState();

    // Use the Firebase data structure directly
    _session = widget.sessionData;

    debugPrint('====== SESSION DETAIL DATA ======');
    debugPrint('Session ID: ${_session['id']}');
    debugPrint('Title: ${_session['title']}');
    debugPrint('Category: ${_session['category']}');

    // Check intro data (Firebase uses 'intro', not 'introduction')
    if (_session.containsKey('intro')) {
      debugPrint('Intro URL: ${_session['intro']['audioUrl']}');
      debugPrint('Intro Title: ${_session['intro']['title']}');
    }

    // Check subliminal data
    if (_session.containsKey('subliminal')) {
      debugPrint('Subliminal URL: ${_session['subliminal']['audioUrl']}');
      debugPrint('Subliminal Title: ${_session['subliminal']['title']}');
    }
    debugPrint('=================================');
  }

  @override
  Widget build(BuildContext context) {
    // Get gradient colors or use defaults
    List<Color> gradientColors = [
      const Color(0xFF1e3c72),
      const Color(0xFF2a5298),
    ];

    if (_session['backgroundGradient'] != null) {
      if (_session['backgroundGradient'] is List) {
        gradientColors = List<Color>.from(_session['backgroundGradient']);
      }
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              gradientColors[0].withOpacity(0.1),
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
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Session Header Card
                      _buildHeaderCard(gradientColors),

                      SizedBox(height: 24.h),

                      // Description
                      _buildDescriptionSection(),

                      SizedBox(height: 24.h),

                      // Benefits
                      if (_session['benefits'] != null) ...[
                        _buildBenefitsSection(),
                        SizedBox(height: 24.h),
                      ],

                      // Subliminals Preview
                      if (_session['subliminals'] != null ||
                          _session['subliminal']?['affirmations'] != null) ...[
                        _buildSubliminalPreview(),
                        SizedBox(height: 24.h),
                      ],

                      // Stats
                      _buildStatsSection(),

                      SizedBox(height: 100.h), // Space for bottom button
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      // Bottom Action Button
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.all(20.w),
      child: Row(
        children: [
          // Back Button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
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
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
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
                color: _isFavorite ? Colors.red : AppColors.textSecondary,
                size: 20.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(List<Color> gradientColors) {
    // Calculate total duration - Firebase uses 'intro' not 'introduction'
    int totalSeconds = 0;

    if (_session['intro'] != null) {
      totalSeconds += (_session['intro']['duration'] as int? ?? 120);
    }

    if (_session['subliminal'] != null) {
      totalSeconds += (_session['subliminal']['duration'] as int? ?? 7200);
    }

    String durationText = _formatDuration(totalSeconds);

    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Emoji or Icon
          Text(_session['emoji'] ?? '🎵', style: TextStyle(fontSize: 48.sp)),

          SizedBox(height: 16.h),

          // Title
          Text(
            _session['title'] ?? 'Session',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 24.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 8.h),

          // Category
          Text(
            _session['category'] ?? 'General',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
          ),

          SizedBox(height: 16.h),

          // Duration info
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              durationText,
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About This Session',
          style: GoogleFonts.inter(
            fontSize: 18.sp.clamp(16.0, 24.0),
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 12.h),
        Text(
          _session['description'] ??
              'This session is designed to help you achieve your goals through powerful subliminal programming.',
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            height: 1.6,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitsSection() {
    final benefits = _session['benefits'] as List? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Benefits',
          style: GoogleFonts.inter(
            fontSize: 18.sp.clamp(16.0, 24.0),
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 12.h),
        ...benefits.map(
          (benefit) => Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.check_circle,
                  color: AppColors.primaryGold,
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    benefit.toString(),
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubliminalPreview() {
    // Get subliminals from either old or new structure
    List subliminals = [];

    if (_session['subliminals'] != null) {
      subliminals = _session['subliminals'] as List;
    } else if (_session['subliminal']?['affirmations'] != null) {
      subliminals = _session['subliminal']['affirmations'] as List;
    }

    if (subliminals.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sample Affirmations',
          style: GoogleFonts.inter(
            fontSize: 18.sp.clamp(16.0, 24.0),
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 12.h),
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColors.primaryGold.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            children: subliminals
                .take(3)
                .map(
                  (subliminal) => Padding(
                    padding: EdgeInsets.only(bottom: 8.h),
                    child: Row(
                      children: [
                        Icon(
                          Icons.format_quote,
                          color: AppColors.primaryGold,
                          size: 16.sp,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            subliminal.toString(),
                            style: GoogleFonts.inter(
                              fontSize: 13.sp,
                              fontStyle: FontStyle.italic,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
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
          Container(width: 1, height: 40.h, color: AppColors.greyBorder),
          Expanded(
            child: _buildStatItem(
              icon: Icons.star,
              value: '${_session['rating'] ?? 0.0}',
              label: 'Rating',
            ),
          ),
          Container(width: 1, height: 40.h, color: AppColors.greyBorder),
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
        Icon(icon, color: AppColors.textPrimary, size: 20.sp),
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
          // Add to Playlist Button
          // Add to Playlist Button
          Expanded(
            flex: 1,
            child: GestureDetector(
              onTap: () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null && _session['id'] != null) {
                  try {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .update({
                      'playlistSessionIds': FieldValue.arrayUnion([
                        _session['id'],
                      ]),
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Added to your playlist!'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  } catch (e) {
                    print('Error adding to playlist: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to add to playlist'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: Container(
                height: 48.h,
                decoration: BoxDecoration(
                  color: AppColors.greyLight,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColors.greyBorder, width: 1.5),
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
          ),
          SizedBox(width: 12.w),

          // Play Button - Send COMPLETE Firebase data
          Expanded(
            flex: 3,
            child: PrimaryButton(
              text: 'Start Session',
              onPressed: () {
                // Pass the complete session data AS IS from Firebase
                // Don't recreate the structure, just pass what we have
                final audioSessionData = Map<String, dynamic>.from(_session);

                debugPrint('====== SENDING TO AUDIO PLAYER ======');
                debugPrint('Session ID: ${audioSessionData['id']}');
                debugPrint(
                  'Intro URL: ${audioSessionData['intro']?['audioUrl']}',
                );
                debugPrint(
                  'Subliminal URL: ${audioSessionData['subliminal']?['audioUrl']}',
                );
                debugPrint('=====================================');

                // Navigate to Audio Player with the EXACT Firebase data
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AudioPlayerScreen(sessionData: audioSessionData),
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

  String _formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;

    if (hours > 0) {
      return '$hours hour${hours > 1 ? 's' : ''} $minutes min';
    } else {
      return '$minutes minutes';
    }
  }
}
