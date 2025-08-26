// lib/features/library/category_sessions_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../player/audio_player_screen.dart';

class CategorySessionsScreen extends StatefulWidget {
  final String categoryTitle;
  final String categoryEmoji;
  final String? categoryId;
  final bool showAllSessions;

  const CategorySessionsScreen({
    super.key,
    required this.categoryTitle,
    required this.categoryEmoji,
    this.categoryId,
    this.showAllSessions = false,
  });

  @override
  State<CategorySessionsScreen> createState() => _CategorySessionsScreenState();
}

class _CategorySessionsScreenState extends State<CategorySessionsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Text(
              widget.categoryEmoji,
              style: TextStyle(fontSize: 24.sp),
            ),
            SizedBox(width: 8.w),
            Text(
              widget.categoryTitle,
              style: GoogleFonts.inter(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: widget.showAllSessions
            ? FirebaseFirestore.instance
                .collection('sessions')
                .orderBy('createdAt', descending: true)
                .snapshots()
            : FirebaseFirestore.instance
                .collection('sessions')
                .where('category', isEqualTo: widget.categoryTitle)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryGold,
              ),
            );
          }

          if (snapshot.hasError) {
            print('Error: ${snapshot.error}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48.sp, color: Colors.red),
                  SizedBox(height: 16.h),
                  Text(
                    'Error loading sessions',
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '${snapshot.error}',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            );
          }

          final sessions = snapshot.data?.docs ?? [];

          if (sessions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.music_off,
                    size: 64.sp,
                    color: AppColors.greyLight,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'No sessions available',
                    style: GoogleFonts.inter(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Check back later for new content',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(20.w),
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final sessionDoc = sessions[index];
              final session = sessionDoc.data() as Map<String, dynamic>;
              final sessionId = sessionDoc.id;

              // Calculate total duration
              final introDuration = session['intro']?['duration'] ?? 0;
              final subliminalDuration =
                  session['subliminal']?['duration'] ?? 0;
              final totalDuration = introDuration + subliminalDuration;

              return _buildSessionCard(
                sessionId: sessionId,
                sessionData: session,
                totalDuration: totalDuration,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSessionCard({
    required String sessionId,
    required Map<String, dynamic> sessionData,
    required int totalDuration,
  }) {
    return GestureDetector(
      onTap: () {
        // Prepare complete session data for audio player
        final completeSessionData = {
          'id': sessionId,
          ...sessionData,
        };

        // Navigate to Audio Player
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AudioPlayerScreen(
              sessionData: completeSessionData,
            ),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Image Section
            Container(
              height: 180.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.r),
                  topRight: Radius.circular(16.r),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryGold.withOpacity(0.8),
                    AppColors.primaryGold.withOpacity(0.4),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Background Image
                  if (sessionData['backgroundImage'] != null &&
                      sessionData['backgroundImage'].toString().isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16.r),
                        topRight: Radius.circular(16.r),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: sessionData['backgroundImage'],
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: AppColors.greyLight,
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: AppColors.greyLight,
                          child: Icon(
                            Icons.image_not_supported,
                            size: 40.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    )
                  else
                    Center(
                      child: Text(
                        sessionData['emoji'] ?? '🎵',
                        style: TextStyle(fontSize: 60.sp),
                      ),
                    ),

                  // Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16.r),
                        topRight: Radius.circular(16.r),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.3),
                        ],
                      ),
                    ),
                  ),

                  // Play Button Overlay
                  Center(
                    child: Container(
                      width: 56.w,
                      height: 56.w,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.play_arrow,
                        size: 32.sp,
                        color: AppColors.primaryGold,
                      ),
                    ),
                  ),

                  // Duration Badge
                  Positioned(
                    top: 12.h,
                    right: 12.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        _formatDuration(totalDuration),
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content Section
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    sessionData['title'] ?? 'Untitled Session',
                    style: GoogleFonts.inter(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  SizedBox(height: 8.h),

                  // Description
                  if (sessionData['description'] != null &&
                      sessionData['description'].toString().isNotEmpty)
                    Text(
                      sessionData['description'],
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                  SizedBox(height: 12.h),

                  // Info Row
                  Row(
                    children: [
                      // Introduction
                      if (sessionData['intro'] != null) ...[
                        Icon(
                          Icons.record_voice_over,
                          size: 16.sp,
                          color: AppColors.primaryGold,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          'Intro ${_formatDuration(sessionData['intro']['duration'] ?? 0)}',
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(width: 16.w),
                      ],

                      // Subliminal
                      if (sessionData['subliminal'] != null) ...[
                        Icon(
                          Icons.waves,
                          size: 16.sp,
                          color: AppColors.primaryGold,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          'Subliminal ${_formatDuration(sessionData['subliminal']['duration'] ?? 0)}',
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],

                      const Spacer(),

                      // Category Badge
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGold.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          sessionData['category'] ?? 'General',
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryGold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) {
      return '${seconds}s';
    } else if (seconds < 3600) {
      final minutes = seconds ~/ 60;
      final remainingSeconds = seconds % 60;
      if (remainingSeconds == 0) {
        return '${minutes}m';
      }
      return '${minutes}m ${remainingSeconds}s';
    } else {
      final hours = seconds ~/ 3600;
      final remainingMinutes = (seconds % 3600) ~/ 60;
      if (remainingMinutes == 0) {
        return '${hours}h';
      }
      return '${hours}h ${remainingMinutes}m';
    }
  }
}
