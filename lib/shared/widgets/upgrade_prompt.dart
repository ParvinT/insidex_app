// lib/shared/widgets/upgrade_prompt.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/responsive/breakpoints.dart';
import '../../features/subscription/paywall_screen.dart';

/// A prompt widget encouraging users to upgrade
/// Can be used as inline banner or bottom sheet
class UpgradePrompt extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? buttonText;
  final String feature;
  final VoidCallback? onDismiss;
  final bool showDismiss;

  const UpgradePrompt({
    super.key,
    this.title = 'Upgrade to Premium',
    this.subtitle = 'Unlock all features and sessions',
    this.buttonText,
    required this.feature,
    this.onDismiss,
    this.showDismiss = true,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isTablet =
        width >= Breakpoints.tabletMin && width < Breakpoints.desktopMin;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isTablet ? 24.w : 16.w,
        vertical: 12.h,
      ),
      padding: EdgeInsets.all(isTablet ? 20.w : 16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.textPrimary.withValues(alpha: 0.05),
            AppColors.textPrimary.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.textPrimary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: isTablet ? 50.w : 44.w,
            height: isTablet ? 50.w : 44.w,
            decoration: BoxDecoration(
              color: AppColors.textPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.workspace_premium,
              color: AppColors.textPrimary,
              size: isTablet ? 26.sp : 22.sp,
            ),
          ),

          SizedBox(width: 12.w),

          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: isTablet ? 16.sp : 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: isTablet ? 13.sp : 12.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(width: 8.w),

          // Upgrade button
          ElevatedButton(
            onPressed: () => showPaywall(context, feature: feature),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.textPrimary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 20.w : 16.w,
                vertical: isTablet ? 12.h : 10.h,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              elevation: 0,
            ),
            child: Text(
              buttonText ?? 'Upgrade',
              style: GoogleFonts.inter(
                fontSize: isTablet ? 14.sp : 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Dismiss button
          if (showDismiss && onDismiss != null) ...[
            SizedBox(width: 4.w),
            IconButton(
              onPressed: onDismiss,
              icon: Icon(
                Icons.close,
                color: AppColors.textSecondary,
                size: isTablet ? 22.sp : 20.sp,
              ),
              constraints: const BoxConstraints(),
              padding: EdgeInsets.all(8.w),
            ),
          ],
        ],
      ),
    );
  }
}

/// Shows upgrade prompt as a bottom sheet
/// Returns true if user purchased, false/null otherwise
Future<bool?> showUpgradeBottomSheet(
  BuildContext context, {
  required String feature,
  String? title,
  String? subtitle,
}) async {
  final wantsToViewPlans = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.greyBorder,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 20.h),

            // Premium icon
            Container(
              width: 70.w,
              height: 70.w,
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.workspace_premium,
                size: 35.sp,
                color: Colors.amber.shade700,
              ),
            ),

            SizedBox(height: 16.h),

            Text(
              title ?? 'Premium Feature',
              style: GoogleFonts.inter(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),

            SizedBox(height: 8.h),

            Text(
              subtitle ?? 'Subscribe to access this feature and more',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 24.h),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      side: BorderSide(color: AppColors.greyBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Text(
                      'Maybe Later',
                      style: GoogleFonts.inter(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.textPrimary,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'View Plans',
                      style: GoogleFonts.inter(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  // If user wants to view plans, show paywall and return result
  if (wantsToViewPlans == true && context.mounted) {
    return showPaywall(context, feature: feature);
  }

  return false;
}
