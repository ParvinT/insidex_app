// lib/features/quiz/widgets/session_recommendation_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/responsive/context_ext.dart';

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
    final double titleSize = isTablet ? 16.sp.clamp(15.0, 17.0) : 15.sp.clamp(14.0, 16.0);
    final double sessionTitleSize = isTablet ? 18.sp.clamp(17.0, 19.0) : 17.sp.clamp(16.0, 18.0);
    final double buttonPadding = isTablet ? 16.h : 14.h;
    final double borderRadius = isTablet ? 18.r : 16.r;

    return Container(
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryGold.withOpacity(0.1),
            AppColors.primaryGold.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: AppColors.primaryGold.withOpacity(0.3),
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
                color: AppColors.primaryGold,
                size: isTablet ? 24.sp : 22.sp,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'Recommended for you',
                  style: GoogleFonts.inter(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryGold,
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
                    color: AppColors.primaryGold,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock,
                        color: Colors.white,
                        size: 12.sp,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        'PREMIUM',
                        style: GoogleFonts.inter(
                          fontSize: 10.sp.clamp(9.0, 11.0),
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: AppColors.greyBorder.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Session number
                if (sessionNumber != null) ...[
                  Container(
                    width: isTablet ? 50.w : 46.w,
                    height: isTablet ? 50.w : 46.w,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryGold,
                          AppColors.primaryGold.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$sessionNumber',
                      style: GoogleFonts.inter(
                        fontSize: isTablet ? 16.sp : 15.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                ],

                // Session title
                Expanded(
                  child: Text(
                    sessionTitle,
                    style: GoogleFonts.inter(
                      fontSize: sessionTitleSize,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
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
                    color: AppColors.primaryGold.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: AppColors.primaryGold,
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
                backgroundColor: AppColors.primaryGold,
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
                      color: Colors.white,
                      size: 18.sp,
                    ),
                    SizedBox(width: 8.w),
                  ],
                  Text(
                    isPremium && !userHasPremium
                        ? 'Unlock & Listen'
                        : 'Listen Now',
                    style: GoogleFonts.inter(
                      fontSize: isTablet ? 16.sp : 15.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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