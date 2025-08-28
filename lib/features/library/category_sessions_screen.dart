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

              return _buildSessionCard(
                sessionId: sessionId,
                sessionData: session,
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
            // Image Section - ESKİSİ GİBİ AYNEN KALSIN
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
                  // Background Image or Emoji - ESKİSİ GİBİ
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
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.primaryGold.withOpacity(0.8),
                                AppColors.primaryGold.withOpacity(0.4),
                              ],
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.primaryGold.withOpacity(0.8),
                                AppColors.primaryGold.withOpacity(0.4),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    // Resim yoksa sadece gradient göster, emoji yok
                    Container(
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
                ],
              ),
            ),

            // Content Section - SADECE BAŞLIK VE KATEGORİ
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  // Title
                  Expanded(
                    child: Text(
                      sessionData['title'] ?? 'Untitled Session',
                      style: GoogleFonts.inter(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  SizedBox(width: 8.w),

                  // Category Badge
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGold.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      sessionData['category'] ?? 'General',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primaryGold,
                      ),
                    ),
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
