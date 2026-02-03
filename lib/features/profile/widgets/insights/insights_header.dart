// lib/features/profile/widgets/insights/insights_header.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/themes/app_theme_extension.dart';

class InsightsStatsRow extends StatelessWidget {
  final Map<String, dynamic> userData;

  const InsightsStatsRow({
    super.key,
    required this.userData,
  });

  @override
  Widget build(BuildContext context) {
    final age = userData['age'] ?? 0;
    final goalsCount = (userData['goals'] as List?)?.length ?? 0;
    final memberDays = _calculateMemberDays();
    final l10n = AppLocalizations.of(context);

    return Row(
      children: [
        Expanded(
          child: _TopStatCard(
            value: '$age',
            unit: l10n.years,
            label: l10n.yourAge,
            color: const Color(0xFFE8C5A0),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _TopStatCard(
            value: '$goalsCount',
            unit: l10n.active,
            label: l10n.goalsLabel,
            color: const Color(0xFF7DB9B6),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _TopStatCard(
            value: '$memberDays',
            unit: l10n.days,
            label: l10n.member,
            color: const Color(0xFFB8A6D9),
          ),
        ),
      ],
    );
  }

  int _calculateMemberDays() {
    final createdAt = userData['createdAt'] as Timestamp?;
    if (createdAt == null) return 0;

    final joinDate = createdAt.toDate();
    return DateTime.now().difference(joinDate).inDays;
  }
}

class _TopStatCard extends StatelessWidget {
  final String value;
  final String unit;
  final String label;
  final Color color;

  const _TopStatCard({
    required this.value,
    required this.unit,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: colors.backgroundCard,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                value,
                style: GoogleFonts.inter(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              Container(
                width: 8.w,
                height: 8.w,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          Text(
            unit,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class InsightsTabBar extends StatelessWidget {
  final TabController tabController;
  final List<String> tabs;

  const InsightsTabBar({
    super.key,
    required this.tabController,
    required this.tabs,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      height: 40.h,
      decoration: BoxDecoration(
        color: colors.greyLight,
        borderRadius: BorderRadius.circular(24.r),
      ),
      padding: EdgeInsets.all(3.w),
      child: TabBar(
        controller: tabController,
        isScrollable: false,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: colors.textPrimary,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: colors.textPrimary.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: colors.textOnPrimary,
        unselectedLabelColor: colors.textPrimary,
        labelStyle: GoogleFonts.inter(
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 11.sp,
          fontWeight: FontWeight.w500,
        ),
        labelPadding: EdgeInsets.zero,
        tabs: tabs.map((tab) => Tab(text: tab)).toList(),
      ),
    );
  }
}
