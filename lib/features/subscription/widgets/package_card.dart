// lib/features/subscription/widgets/package_card.dart

import 'dart:math' show max;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/themes/app_theme_extension.dart';
import '../../../core/constants/subscription_constants.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../models/subscription_package.dart';
import '../../../l10n/app_localizations.dart';

/// Card widget for displaying a subscription package option
/// Used in paywall screen to show available plans
class PackageCard extends StatelessWidget {
  final SubscriptionPackage package;
  final bool isSelected;
  final bool isCurrentPlan;
  final bool isTrialEligible;
  final VoidCallback onTap;

  const PackageCard({
    super.key,
    required this.package,
    required this.isSelected,
    this.isCurrentPlan = false,
    this.isTrialEligible = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isTablet =
        width >= Breakpoints.tabletMin && width < Breakpoints.desktopMin;
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: EdgeInsets.all(isTablet ? max(20, 20.w) : max(16, 16.w)),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.textPrimary.withValues(alpha: 0.05)
              : colors.backgroundCard,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isCurrentPlan
                ? Colors.green
                : (isSelected ? colors.textPrimary : colors.border),
            width: isSelected || isCurrentPlan ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colors.textPrimary.withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: Title + Badges
            _buildHeader(context, isTablet),

            SizedBox(height: 12.h),

            // Price
            _buildPrice(context, isTablet),

            SizedBox(height: 12.h),

            // Features
            _buildFeatures(context, isTablet),

            // Trial banner (if applicable and not current plan)
            if (package.hasTrial && !isCurrentPlan && isTrialEligible) ...[
              SizedBox(height: 12.h),
              _buildTrialBanner(context, isTablet),
            ],

            // Current plan banner
            if (isCurrentPlan) ...[
              SizedBox(height: 12.h),
              _buildCurrentPlanBanner(context, isTablet),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isTablet) {
    return Row(
      children: [
        // Tier icon
        Container(
          width: isTablet ? max(44, 44.w) : max(40, 40.w),
          height: isTablet ? max(44, 44.w) : max(40, 40.w),
          decoration: BoxDecoration(
            color: _getTierColor().withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(
            _getTierIcon(),
            color: _getTierColor(),
            size: isTablet ? 24.sp : 20.sp,
          ),
        ),

        SizedBox(width: 12.w),

        // Title
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getLocalizedTitle(context),
                style: GoogleFonts.inter(
                  fontSize: isTablet ? 18.sp : 16.sp,
                  fontWeight: FontWeight.w600,
                  color: context.colors.textPrimary,
                ),
              ),
              if (package.period == SubscriptionPeriod.yearly)
                Text(
                  _getLocalizedMonthlyEquivalent(context) ?? '',
                  style: GoogleFonts.inter(
                    fontSize: isTablet ? 13.sp : 12.sp,
                    color: context.colors.textSecondary,
                  ),
                ),
            ],
          ),
        ),

        // Badges
        _buildBadges(isTablet),
      ],
    );
  }

  Widget _buildBadges(bool isTablet) {
    return Wrap(
      spacing: 8.w,
      runSpacing: 4.h,
      children: [
        // Current plan badge (priority over popular)
        if (isCurrentPlan)
          Builder(
            builder: (context) {
              return Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 10.w,
                  vertical: 4.h,
                ),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check,
                      color: Colors.white,
                      size: isTablet ? 14.sp : 12.sp,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      AppLocalizations.of(context).packageBadgeCurrent,
                      style: GoogleFonts.inter(
                        fontSize: isTablet ? 11.sp : 10.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              );
            },
          )
        // Popular badge (only if not current plan)
        else if (package.isHighlighted)
          Builder(
            builder: (context) {
              final colors = context.colors;
              return Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 10.w,
                  vertical: 4.h,
                ),
                decoration: BoxDecoration(
                  color: colors.textPrimary,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  AppLocalizations.of(context).packageBadgePopular,
                  style: GoogleFonts.inter(
                    fontSize: isTablet ? 11.sp : 10.sp,
                    fontWeight: FontWeight.w700,
                    color: colors.textOnPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
              );
            },
          ),

        // Savings badge (always show if available)
        if (package.savingsPercent != null && !isCurrentPlan)
          Builder(
            builder: (context) {
              return Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 10.w,
                  vertical: 4.h,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Text(
                  AppLocalizations.of(context)
                      .packageBadgeSavings(package.savingsPercent!),
                  style: GoogleFonts.inter(
                    fontSize: isTablet ? 11.sp : 10.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.green.shade700,
                    letterSpacing: 0.5,
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildPrice(BuildContext context, bool isTablet) {
    final colors = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          package.localizedPrice,
          style: GoogleFonts.inter(
            fontSize: isTablet ? 32.sp : 28.sp,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        SizedBox(width: 4.w),
        Text(
          _getLocalizedPeriodSuffix(context),
          style: GoogleFonts.inter(
            fontSize: isTablet ? 15.sp : 14.sp,
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatures(BuildContext context, bool isTablet) {
    final colors = context.colors;
    return Column(
      children: package.features.map((feature) {
        return Padding(
          padding: EdgeInsets.only(bottom: 8.h),
          child: Row(
            children: [
              Icon(
                feature.isIncluded ? Icons.check_circle : Icons.cancel,
                color: feature.isIncluded
                    ? Colors.green
                    : colors.textSecondary.withValues(alpha: 0.5),
                size: isTablet ? 20.sp : 18.sp,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  _getLocalizedFeatureTitle(context, feature.title),
                  style: GoogleFonts.inter(
                    fontSize: isTablet ? 14.sp : 13.sp,
                    color: feature.isIncluded
                        ? colors.textPrimary
                        : colors.textSecondary.withValues(alpha: 0.7),
                    decoration:
                        feature.isIncluded ? null : TextDecoration.lineThrough,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTrialBanner(BuildContext context, bool isTablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 12.w,
        vertical: 10.h,
      ),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.card_giftcard,
            color: Colors.blue.shade700,
            size: isTablet ? 18.sp : 16.sp,
          ),
          SizedBox(width: 8.w),
          Text(
            AppLocalizations.of(context).packageTrialBanner(package.trialDays),
            style: GoogleFonts.inter(
              fontSize: isTablet ? 13.sp : 12.sp,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentPlanBanner(BuildContext context, bool isTablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 12.w,
        vertical: 10.h,
      ),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green.shade700,
            size: isTablet ? 18.sp : 16.sp,
          ),
          SizedBox(width: 8.w),
          Text(
            AppLocalizations.of(context).packageCurrentPlanBanner,
            style: GoogleFonts.inter(
              fontSize: isTablet ? 13.sp : 12.sp,
              fontWeight: FontWeight.w600,
              color: Colors.green.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Color _getTierColor() {
    switch (package.tier) {
      case SubscriptionTier.lite:
        return Colors.blue;
      case SubscriptionTier.standard:
        return Colors.purple;
      case SubscriptionTier.free:
        return Colors.grey;
    }
  }

  IconData _getTierIcon() {
    switch (package.tier) {
      case SubscriptionTier.lite:
        return Icons.music_note;
      case SubscriptionTier.standard:
        return Icons.star;
      case SubscriptionTier.free:
        return Icons.person;
    }
  }
  // ============================================================
// LOCALIZATION HELPERS
// ============================================================

  String _getLocalizedTitle(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (package.tier) {
      case SubscriptionTier.lite:
        return l10n.tierLite;
      case SubscriptionTier.standard:
        return package.period == SubscriptionPeriod.yearly
            ? l10n.tierYearlyStandard
            : l10n.tierStandard;
      case SubscriptionTier.free:
        return l10n.free;
    }
  }

  String _getLocalizedPeriodSuffix(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return package.period == SubscriptionPeriod.monthly
        ? l10n.periodMonth
        : l10n.periodYear;
  }

  String? _getLocalizedMonthlyEquivalent(BuildContext context) {
    if (package.monthlyEquivalent == null) return null;
    final l10n = AppLocalizations.of(context);
    final symbol = _getCurrencySymbol(package.currencyCode);
    final price = '$symbol${package.monthlyEquivalent!.toStringAsFixed(0)}';
    return l10n.monthlyEquivalentFormat(price);
  }

  String _getCurrencySymbol(String code) {
    const overrides = {'TRY': '₺', 'RUB': '₽'};
    if (overrides.containsKey(code.toUpperCase())) {
      return overrides[code.toUpperCase()]!;
    }
    return '\$';
  }

  String _getLocalizedFeatureTitle(BuildContext context, String originalTitle) {
    final l10n = AppLocalizations.of(context);
    switch (originalTitle) {
      case 'All audio sessions':
        return l10n.featureAllAudioSessions;
      case 'Background playback':
        return l10n.featureBackgroundPlayback;
      case 'Offline download':
        return l10n.featureOfflineDownloads;
      default:
        return originalTitle;
    }
  }
}
