// lib/features/profile/widgets/insights/stats_tab.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/themes/app_theme_extension.dart';

class StatsTab extends StatelessWidget {
  final Map<String, dynamic> userData;
  final Future<Map<String, int>>? weeklyActivityFuture;
  final Future<String>? longestSessionFuture;
  final Future<String>? favoriteTimeFuture;

  const StatsTab({
    super.key,
    required this.userData,
    required this.weeklyActivityFuture,
    required this.longestSessionFuture,
    required this.favoriteTimeFuture,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        children: [
          // Quick Stats Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12.h,
            crossAxisSpacing: 12.w,
            childAspectRatio: 1.3,
            children: [
              _buildStatCard(
                context,
                icon: Icons.calendar_today,
                label: AppLocalizations.of(context).daysActive,
                value: '${_calculateMemberDays()}',
                color: const Color(0xFF7DB9B6),
              ),
              _buildStatCard(
                context,
                icon: Icons.headphones,
                label: AppLocalizations.of(context).sessionsLabel,
                value:
                    '${(userData['completedSessionIds'] as List?)?.length ?? 0}',
                color: const Color(0xFFE8C5A0),
              ),
              _buildStatCard(
                context,
                icon: Icons.timer,
                label: AppLocalizations.of(context).minutesLabel,
                value: '${userData['totalListeningMinutes'] ?? 0}',
                color: const Color(0xFFB8A6D9),
              ),
              _buildStatCard(
                context,
                icon: Icons.local_fire_department,
                label: AppLocalizations.of(context).streakLabel,
                value: '${userData['currentStreak'] ?? 0}',
                color: Colors.orange,
              ),
            ],
          ),

          SizedBox(height: 20.h),

          // Activity Chart with real data
          _buildWeeklyActivityChart(context),

          SizedBox(height: 20.h),

          // Additional Stats
          _buildSessionStats(context),
        ],
      ),
    );
  }

  Widget _buildWeeklyActivityChart(BuildContext context) {
    final colors = context.colors;
    return FutureBuilder<Map<String, int>>(
      future: weeklyActivityFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 200.h,
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: colors.backgroundCard,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Center(
              child: CircularProgressIndicator(color: colors.textPrimary),
            ),
          );
        }

        final weeklyData = snapshot.data ?? {};

        return Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: colors.backgroundCard,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: colors.textPrimary.withValues(alpha: 0.05),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context).weeklyActivity,
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  Text(
                    '${_getTotalWeeklyMinutes(weeklyData)} ${AppLocalizations.of(context).minTotal}',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),

              // Bar chart
              SizedBox(
                height: 120.h,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildDayBar(
                        context,
                        AppLocalizations.of(context).mon[0],
                        weeklyData['Mon'] ?? 0),
                    _buildDayBar(
                        context,
                        AppLocalizations.of(context).tue[0],
                        weeklyData['Tue'] ?? 0),
                    _buildDayBar(
                        context,
                        AppLocalizations.of(context).wed[0],
                        weeklyData['Wed'] ?? 0),
                    _buildDayBar(
                        context,
                        AppLocalizations.of(context).thu[0],
                        weeklyData['Thu'] ?? 0),
                    _buildDayBar(
                        context,
                        AppLocalizations.of(context).fri[0],
                        weeklyData['Fri'] ?? 0),
                    _buildDayBar(
                        context,
                        AppLocalizations.of(context).sat[0],
                        weeklyData['Sat'] ?? 0),
                    _buildDayBar(
                        context,
                        AppLocalizations.of(context).sun[0],
                        weeklyData['Sun'] ?? 0),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSessionStats(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: colors.backgroundCard,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: colors.textPrimary.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).sessionStats,
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          SizedBox(height: 16.h),

          // Average Session - Synchronous
          _buildStatRow(
            context,
            label: AppLocalizations.of(context).averageSession,
            value: _calculateAverageSession(),
            icon: Icons.av_timer,
          ),
          SizedBox(height: 12.h),

          // Longest Session - Async
          FutureBuilder<String>(
            future: longestSessionFuture,
            builder: (context, snapshot) {
              return _buildStatRow(
                context,
                label: AppLocalizations.of(context).longestSession,
                value: snapshot.data ?? AppLocalizations.of(context).loading,
                icon: Icons.trending_up,
              );
            },
          ),
          SizedBox(height: 12.h),

          // Favorite Time - Async
          FutureBuilder<String>(
            future: favoriteTimeFuture,
            builder: (context, snapshot) {
              return _buildStatRow(
                context,
                label: AppLocalizations.of(context).favoriteTime,
                value: snapshot.data ?? AppLocalizations.of(context).loading,
                icon: Icons.access_time,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final colors = context.colors;
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: colors.backgroundCard,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: colors.textPrimary.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22.sp),
          SizedBox(height: 6.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10.sp,
                color: colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayBar(
    BuildContext context,
    String day,
    int minutes,
  ) {
    final colors = context.colors;
    const maxHeight = 80.0;
    final height =
        minutes > 0 ? (minutes / 120 * maxHeight).clamp(10.0, maxHeight) : 10.0;

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (minutes > 0)
            Text(
              '$minutes',
              style: GoogleFonts.inter(
                fontSize: 10.sp,
                color: const Color(0xFF7DB9B6),
                fontWeight: FontWeight.w600,
              ),
            ),
          SizedBox(height: 4.h),
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
            width: 28.w,
            height: height.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: minutes > 0
                    ? [
                        const Color(0xFF7DB9B6),
                        const Color(0xFF7DB9B6).withValues(alpha: 0.7),
                      ]
                    : [colors.greyMedium, colors.greyMedium],
              ),
              borderRadius: BorderRadius.circular(4.r),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            day,
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: colors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    final colors = context.colors;
    return Row(
      children: [
        Icon(
          icon,
          size: 20.sp,
          color: const Color(0xFF7DB9B6),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              color: colors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }

  // Helper methods
  int _calculateMemberDays() {
    final createdAt = userData['createdAt'] as Timestamp?;
    if (createdAt == null) return 0;

    final joinDate = createdAt.toDate();
    return DateTime.now().difference(joinDate).inDays;
  }

  String _calculateAverageSession() {
    final totalMinutes = userData['totalListeningMinutes'] ?? 0;
    final totalSessions =
        (userData['completedSessionIds'] as List?)?.length ?? 1;

    if (totalSessions == 0) return '0 min';

    final average = totalMinutes ~/ totalSessions;
    return '$average min';
  }

  int _getTotalWeeklyMinutes(Map<String, int> weeklyData) {
    return weeklyData.values.fold(0, (total, minutes) => total + minutes);
  }
}
