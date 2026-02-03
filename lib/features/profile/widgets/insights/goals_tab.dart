// lib/features/profile/widgets/insights/goals_tab.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/themes/app_theme_extension.dart';

class GoalsTab extends StatelessWidget {
  final Map<String, dynamic> userData;

  const GoalsTab({
    super.key,
    required this.userData,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final goals = (userData['goals'] as List?) ?? [];

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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context).yourWellnessGoals,
                      style: GoogleFonts.inter(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                if (goals.isEmpty)
                  _buildEmptyState(context)
                else
                  _buildGoalsList(context, goals),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.flag_outlined,
            size: 48.sp,
            color: colors.greyMedium,
          ),
          SizedBox(height: 12.h),
          Text(
            AppLocalizations.of(context).noGoalsYet,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsList(
    BuildContext context,
    List goals,
  ) {
    final colors = context.colors;
    return Wrap(
      spacing: 12.w,
      runSpacing: 12.h,
      children: goals.map((goal) {
        IconData goalIcon = _getGoalIcon(goal);
        Color goalColor = _getGoalColor(goal);

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 12.h,
          ),
          decoration: BoxDecoration(
            color: colors.backgroundCard,
            borderRadius: BorderRadius.circular(25.r),
            border: Border.all(
              color: goalColor.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: goalColor.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                goalIcon,
                size: 18.sp,
                color: goalColor,
              ),
              SizedBox(width: 8.w),
              Text(
                _getLocalizedGoalName(context, goal),
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _getLocalizedGoalName(BuildContext context, String goal) {
    final l10n = AppLocalizations.of(context);

    switch (goal) {
      case 'Health':
        return l10n.health;
      case 'Confidence':
        return l10n.confidence;
      case 'Energy':
        return l10n.energy;
      case 'Better Sleep':
        return l10n.betterSleep;
      case 'Anxiety Relief':
        return l10n.anxietyRelief;
      case 'Emotional Balance':
        return l10n.emotionalBalance;
      default:
        return goal;
    }
  }

  IconData _getGoalIcon(String goal) {
    switch (goal) {
      case 'Health':
        return Icons.favorite_outline;
      case 'Confidence':
        return Icons.psychology_outlined;
      case 'Energy':
        return Icons.bolt;
      case 'Better Sleep':
        return Icons.bedtime_outlined;
      case 'Anxiety Relief':
        return Icons.self_improvement;
      case 'Emotional Balance':
        return Icons.balance;
      default:
        return Icons.flag_outlined;
    }
  }

  Color _getGoalColor(String goal) {
    switch (goal) {
      case 'Health':
        return const Color(0xFFFF6B6B);
      case 'Confidence':
        return const Color(0xFF4ECDC4);
      case 'Energy':
        return const Color(0xFFFFD93D);
      case 'Better Sleep':
        return const Color(0xFF6C5CE7);
      case 'Anxiety Relief':
        return const Color(0xFF74B9FF);
      case 'Emotional Balance':
        return const Color(0xFFA29BFE);
      default:
        return const Color(0xFF7DB9B6);
    }
  }
}
