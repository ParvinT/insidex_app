// lib/features/profile/widgets/insights/overview_tab.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/themes/app_theme_extension.dart';

class OverviewTab extends StatelessWidget {
  final Map<String, dynamic> userData;

  const OverviewTab({
    super.key,
    required this.userData,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        children: [
          // Personal Information
          Container(
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
                  AppLocalizations.of(context).personalInformation,
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                SizedBox(height: 20.h),
                _buildInfoRow(
                  context,
                  icon: Icons.person_outline,
                  label: AppLocalizations.of(context).gender,
                  value: _getLocalizedGender(context, userData['gender'] ?? ''),
                ),
                Divider(height: 24.h, color: colors.border),
                _buildInfoRow(
                  context,
                  icon: Icons.cake_outlined,
                  label: AppLocalizations.of(context).birthDate,
                  value: _formatBirthDate(context),
                ),
                Divider(height: 24.h, color: colors.border),
                _buildInfoRow(
                  context,
                  icon: Icons.email_outlined,
                  label: AppLocalizations.of(context).email,
                  value: FirebaseAuth.instance.currentUser?.email ?? '',
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),

          // Personality Insights
          Container(
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
                  AppLocalizations.of(context).personalityInsights,
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                SizedBox(height: 16.h),
                _buildInsightRow(
                  context,
                  AppLocalizations.of(context).ageGroup,
                  _getAgeGroup(context),
                ),
                SizedBox(height: 12.h),
                _buildInsightRow(
                  context,
                  AppLocalizations.of(context).wellnessFocus,
                  _getWellnessFocus(context),
                ),
                SizedBox(height: 12.h),
                _buildInsightRow(
                  context,
                  AppLocalizations.of(context).recommendedSessions,
                  _getRecommendedCategory(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final colors = context.colors;
    return Row(
      children: [
        Icon(icon, size: 20.sp, color: colors.textSecondary),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: colors.textSecondary,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInsightRow(BuildContext context, String label, String value) {
    final colors = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            color: colors.textSecondary,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF7DB9B6),
          ),
        ),
      ],
    );
  }

  String _getLocalizedGender(BuildContext context, String gender) {
    final l10n = AppLocalizations.of(context);
    return gender.toLowerCase() == 'male' ? l10n.male : l10n.female;
  }

  String _formatBirthDate(BuildContext context) {
    final birthDate = userData['birthDate'] as Timestamp?;
    if (birthDate == null) return AppLocalizations.of(context).notSpecified;

    final date = birthDate.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getAgeGroup(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final age = userData['age'] ?? 0;
    if (age < 18) return l10n.youngAdult;
    if (age < 25) return l10n.earlyTwenties;
    if (age < 35) return l10n.lateTwenties;
    if (age < 45) return l10n.thirties;
    return l10n.matureAdult;
  }

  String _getWellnessFocus(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final goals = (userData['goals'] as List?) ?? [];
    if (goals.contains('Better Sleep')) return l10n.sleepQuality;
    if (goals.contains('Anxiety Relief')) return l10n.mentalPeace;
    if (goals.contains('Energy')) return l10n.vitality;
    return l10n.generalWellness;
  }

  String _getRecommendedCategory(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final goals = (userData['goals'] as List?) ?? [];
    if (goals.contains('Better Sleep')) return l10n.sleepSessions;
    if (goals.contains('Anxiety Relief')) return l10n.meditation;
    return l10n.focusSessions;
  }
}