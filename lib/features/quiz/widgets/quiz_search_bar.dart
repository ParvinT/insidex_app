// lib/features/quiz/widgets/quiz_search_bar.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/themes/app_theme_extension.dart';

class QuizSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool isTablet;
  final bool showClearButton;
  final VoidCallback onClear;

  const QuizSearchBar({
    super.key,
    required this.controller,
    required this.hintText,
    required this.isTablet,
    required this.showClearButton,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 14.w : 12.w,
      ),
      decoration: BoxDecoration(
        color: colors.greyLight,
        borderRadius: BorderRadius.circular(isTablet ? 12.r : 10.r),
        border: Border.all(
          color: colors.border.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            color: colors.textSecondary,
            size: isTablet ? 20.sp : 18.sp,
          ),
          SizedBox(width: isTablet ? 10.w : 8.w),
          Expanded(
            child: TextField(
              controller: controller,
              style: GoogleFonts.inter(
                fontSize: isTablet ? 14.sp : 13.sp,
                color: colors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: GoogleFonts.inter(
                  fontSize: isTablet ? 14.sp : 13.sp,
                  color: colors.textSecondary.withValues(alpha: 0.7),
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(vertical: isTablet ? 12.h : 10.h),
                isDense: true,
              ),
            ),
          ),
          if (showClearButton)
            GestureDetector(
              onTap: onClear,
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Icon(
                  Icons.clear,
                  color: colors.textSecondary,
                  size: isTablet ? 18.sp : 16.sp,
                ),
              ),
            ),
        ],
      ),
    );
  }
}