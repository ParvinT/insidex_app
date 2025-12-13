// lib/shared/widgets/upgrade_prompt.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/themes/app_theme_extension.dart';
import '../../core/responsive/breakpoints.dart';
import '../../core/constants/subscription_constants.dart';
import '../../features/subscription/paywall_screen.dart';
import '../../providers/subscription_provider.dart';

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
    final colors = context.colors;
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
            colors.textPrimary.withValues(alpha: 0.05),
            colors.textPrimary.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: colors.textPrimary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: isTablet ? 50.w : 44.w,
            height: isTablet ? 50.w : 44.w,
            decoration: BoxDecoration(
              color: colors.textPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.workspace_premium,
              color: colors.textPrimary,
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
                    color: colors.textPrimary,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: isTablet ? 13.sp : 12.sp,
                    color: colors.textSecondary,
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
              backgroundColor: colors.textPrimary,
              foregroundColor: colors.textOnPrimary,
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
                color: colors.textSecondary,
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
      builder: (ctx) {
        final colors = ctx.colors;
        return Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: colors.backgroundElevated,
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
                    color: colors.greyMedium,
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
                    color: colors.textPrimary,
                  ),
                ),

                SizedBox(height: 8.h),

                Text(
                  subtitle ?? 'Subscribe to access this feature and more',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    color: colors.textSecondary,
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
                          side: BorderSide(color: colors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: Text(
                          'Maybe Later',
                          style: GoogleFonts.inter(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.textPrimary,
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
        );
      });

  // If user wants to view plans, show paywall and return result
  if (wantsToViewPlans == true && context.mounted) {
    return showPaywall(context, feature: feature);
  }

  return false;
}

/// Shows manage subscription bottom sheet for premium users
Future<void> showManageSubscriptionSheet(BuildContext context) async {
  final subscriptionProvider = context.read<SubscriptionProvider>();

  await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final colors = ctx.colors;
        return Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: colors.backgroundElevated,
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
                    color: colors.greyMedium,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                SizedBox(height: 20.h),

                // Title
                Text(
                  'Your Subscription',
                  style: GoogleFonts.inter(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),

                SizedBox(height: 24.h),

                // Current plan card
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.amber.withValues(alpha: 0.15),
                        Colors.orange.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: Colors.amber.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 50.w,
                            height: 50.w,
                            decoration: BoxDecoration(
                              color: Colors.amber.shade700,
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Icon(
                              Icons.workspace_premium,
                              color: Colors.white,
                              size: 28.sp,
                            ),
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${subscriptionProvider.tier.displayName} Plan',
                                  style: GoogleFonts.inter(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w700,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  _getStatusText(subscriptionProvider),
                                  style: GoogleFonts.inter(
                                    fontSize: 14.sp,
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Trial/Expiry info
                      if (subscriptionProvider.isInTrial ||
                          subscriptionProvider.daysRemaining > 0) ...[
                        SizedBox(height: 16.h),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: subscriptionProvider.isInTrial
                                ? Colors.blue.withValues(alpha: 0.1)
                                : Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                subscriptionProvider.isInTrial
                                    ? Icons.schedule
                                    : Icons.check_circle,
                                size: 20.sp,
                                color: subscriptionProvider.isInTrial
                                    ? Colors.blue.shade700
                                    : Colors.green.shade700,
                              ),
                              SizedBox(width: 10.w),
                              Text(
                                subscriptionProvider.isInTrial
                                    ? '${subscriptionProvider.trialDaysRemaining} days left in trial'
                                    : '${subscriptionProvider.daysRemaining} days until renewal',
                                style: GoogleFonts.inter(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w500,
                                  color: subscriptionProvider.isInTrial
                                      ? Colors.blue.shade700
                                      : Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                SizedBox(height: 24.h),

                // Actions
                if (subscriptionProvider.tier != SubscriptionTier.standard) ...[
                  // Upgrade option
                  _buildManageActionTile(
                    ctx,
                    icon: Icons.arrow_upward,
                    iconColor: Colors.green,
                    title: 'Upgrade Plan',
                    subtitle: 'Get more features with Standard',
                    onTap: () {
                      Navigator.pop(ctx);
                      showPaywall(context);
                    },
                  ),
                  SizedBox(height: 12.h),
                ],

                // Cancel/Manage
                _buildManageActionTile(
                  ctx,
                  icon: Icons.settings,
                  iconColor: colors.textSecondary,
                  title: 'Manage in App Store',
                  subtitle: 'Change or cancel subscription',
                  onTap: () {
                    Navigator.pop(ctx);
                    // TODO: Open App Store/Play Store subscription management
                  },
                ),

                SizedBox(height: 20.h),
              ],
            ),
          ),
        );
      });
}

String _getStatusText(SubscriptionProvider provider) {
  if (provider.isInTrial) {
    return 'Trial • ${provider.subscription.period?.displayName ?? 'Monthly'}';
  }
  return 'Active • ${provider.subscription.period?.displayName ?? 'Monthly'}';
}

Widget _buildManageActionTile(
  BuildContext context, {
  required IconData icon,
  required Color iconColor,
  required String title,
  required String subtitle,
  required VoidCallback onTap,
}) {
  final colors = context.colors;
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12.r),
    child: Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: colors.greyLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: colors.border.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 16.sp,
            color: colors.textSecondary,
          ),
        ],
      ),
    ),
  );
}
