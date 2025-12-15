// lib/features/profile/widgets/insights/journey_tab.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/themes/app_theme_extension.dart';

class JourneyTab extends StatelessWidget {
  final Map<String, dynamic> userData;

  const JourneyTab({
    super.key,
    required this.userData,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final completedSessions =
        (userData['completedSessionIds'] as List?)?.length ?? 0;
    final currentStreak = userData['currentStreak'] ?? 0;
    final firstSessionDate = userData['firstSessionDate'] as Timestamp?;

    final l10n = AppLocalizations.of(context);
    final milestones = _buildMilestones(
      context,
      l10n,
      completedSessions,
      currentStreak,
      firstSessionDate,
    );

    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: colors.backgroundCard,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.yourWellnessJourney,
                  style: GoogleFonts.inter(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  l10n.trackMilestones,
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    color: colors.textSecondary,
                  ),
                ),
                SizedBox(height: 24.h),
                ...milestones.map((milestone) {
                  return _buildMilestoneItem(context, milestone);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _buildMilestones(
    BuildContext context,
    AppLocalizations l10n,
    int completedSessions,
    int currentStreak,
    Timestamp? firstSessionDate,
  ) {
    return [
      {
        'title': l10n.firstSession,
        'date': firstSessionDate != null
            ? _formatDate(context, firstSessionDate.toDate())
            : l10n.notStartedYet,
        'completed': completedSessions > 0,
      },
      {
        'title': l10n.sevenDayStreak,
        'date': currentStreak >= 7
            ? l10n.achieved
            : '${7 - currentStreak} ${l10n.daysToGo}',
        'completed': currentStreak >= 7,
      },
      {
        'title': l10n.tenSessions,
        'date': completedSessions >= 10
            ? l10n.completed
            : '${10 - completedSessions} ${l10n.sessionsToGo}',
        'completed': completedSessions >= 10,
      },
      {
        'title': l10n.thirtyDayStreak,
        'date': currentStreak >= 30 ? l10n.amazingAchievement : l10n.keepGoing,
        'completed': currentStreak >= 30,
      },
      {
        'title': l10n.fiftySessions,
        'date': completedSessions >= 50 ? l10n.powerUser : l10n.longTermGoal,
        'completed': completedSessions >= 50,
      },
    ];
  }

  Widget _buildMilestoneItem(
    BuildContext context,
    Map<String, dynamic> milestone,
  ) {
    final colors = context.colors;
    final isCompleted = milestone['completed'] as bool;

    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: isCompleted ? const Color(0xFF7DB9B6) : colors.greyMedium,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCompleted ? Icons.check : Icons.lock_outline,
              color: colors.backgroundCard,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  milestone['title'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: isCompleted ? colors.textPrimary : colors.textLight,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  milestone['date'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (isCompleted)
            Icon(
              Icons.star,
              color: Colors.amber,
              size: 20.sp,
            ),
        ],
      ),
    );
  }

  String _formatDate(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).languageCode;
    final formatted = DateFormat('MMM d, y', locale).format(date);
    return _capitalizeFirst(formatted);
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
