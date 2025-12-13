// lib/features/subscription/widgets/package_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/themes/app_theme_extension.dart';
import '../../../core/constants/subscription_constants.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../models/subscription_package.dart';

/// Card widget for displaying a subscription package option
/// Used in paywall screen to show available plans
class PackageCard extends StatelessWidget {
  final SubscriptionPackage package;
  final bool isSelected;
  final VoidCallback onTap;

  const PackageCard({
    super.key,
    required this.package,
    required this.isSelected,
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
        padding: EdgeInsets.all(isTablet ? 20.w : 16.w),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.textPrimary.withValues(alpha: 0.05)
              : colors.backgroundCard,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isSelected ? colors.textPrimary : colors.border,
            width: isSelected ? 2 : 1,
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

            // Trial banner (if applicable)
            if (package.hasTrial) ...[
              SizedBox(height: 12.h),
              _buildTrialBanner(context, isTablet),
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
          width: isTablet ? 44.w : 40.w,
          height: isTablet ? 44.w : 40.w,
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
                package.displayTitle,
                style: GoogleFonts.inter(
                  fontSize: isTablet ? 18.sp : 16.sp,
                  fontWeight: FontWeight.w600,
                  color: context.colors.textPrimary,
                ),
              ),
              if (package.period == SubscriptionPeriod.yearly)
                Text(
                  package.monthlyEquivalentDisplay ?? '',
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
    return Row(
      children: [
        // Popular badge
        if (package.isHighlighted)
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
                  'POPULAR',
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

        // Savings badge
        if (package.savingsPercent != null) ...[
          SizedBox(width: 8.w),
          Container(
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
              '${package.savingsPercent}% OFF',
              style: GoogleFonts.inter(
                fontSize: isTablet ? 11.sp : 10.sp,
                fontWeight: FontWeight.w700,
                color: Colors.green.shade700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
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
          package.periodSuffix,
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
                  feature.title,
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
            '${package.trialDays} days FREE trial',
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
}
