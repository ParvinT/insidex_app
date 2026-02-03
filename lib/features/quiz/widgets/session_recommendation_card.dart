// lib/features/quiz/widgets/session_recommendation_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/themes/app_theme_extension.dart';
import '../../../core/responsive/context_ext.dart';
import '../../../l10n/app_localizations.dart';

class SessionRecommendationCard extends StatelessWidget {
  final int? sessionNumber;
  final String sessionTitle;
  final VoidCallback onTap;
  final bool isPremium;
  final bool userHasPremium;

  const SessionRecommendationCard({
    super.key,
    this.sessionNumber,
    required this.sessionTitle,
    required this.onTap,
    this.isPremium = true,
    this.userHasPremium = false,
  });

  @override
  Widget build(BuildContext context) {
    // Responsive values
    final isTablet = context.isTablet;
    final isDesktop = context.isDesktop;

    final double cardPadding = isDesktop ? 24.w : (isTablet ? 20.w : 18.w);
    final double titleSize =
        isTablet ? 16.sp.clamp(15.0, 17.0) : 15.sp.clamp(14.0, 16.0);
    final double sessionTitleSize =
        isTablet ? 18.sp.clamp(17.0, 19.0) : 17.sp.clamp(16.0, 18.0);
    final double buttonPadding = isTablet ? 16.h : 14.h;
    final double borderRadius = isTablet ? 18.r : 16.r;

    final colors = context.colors;
    return Container(
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.textPrimary.withValues(alpha: 0.1),
            colors.textPrimary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: colors.textPrimary.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.recommend,
                color: colors.textPrimary,
                size: isTablet ? 24.sp : 22.sp,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  AppLocalizations.of(context).recommendedForYou,
                  style: GoogleFonts.inter(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              // Premium badge
              if (isPremium && !userHasPremium)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: colors.textPrimary,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock,
                        color: colors.textOnPrimary,
                        size: 12.sp,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        AppLocalizations.of(context).premium.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 10.sp.clamp(9.0, 11.0),
                          fontWeight: FontWeight.w700,
                          color: colors.textOnPrimary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          SizedBox(height: 16.h),

          // Session info
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: colors.backgroundCard,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: colors.border.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Session title
                Expanded(
                  child: Text(
                    sessionTitle,
                    style: GoogleFonts.inter(
                      fontSize: sessionTitleSize,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                SizedBox(width: 12.w),

                // Play icon
                Container(
                  width: isTablet ? 44.w : 40.w,
                  height: isTablet ? 44.w : 40.w,
                  decoration: BoxDecoration(
                    color: colors.textPrimary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: colors.textPrimary,
                    size: isTablet ? 28.sp : 26.sp,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16.h),

          // Listen Now button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.textPrimary,
                padding: EdgeInsets.symmetric(vertical: buttonPadding),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                elevation: 2,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isPremium && !userHasPremium) ...[
                    Icon(
                      Icons.lock_open,
                      color: colors.textOnPrimary,
                      size: 18.sp,
                    ),
                    SizedBox(width: 8.w),
                  ],
                  Text(
                    isPremium && !userHasPremium
                        ? AppLocalizations.of(context).unlockAndListen
                        : AppLocalizations.of(context).listenNow,
                    style: GoogleFonts.inter(
                      fontSize: isTablet ? 16.sp : 15.sp,
                      fontWeight: FontWeight.w600,
                      color: colors.textOnPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
