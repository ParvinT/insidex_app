// lib/features/search/widgets/search_bar_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/responsive/context_ext.dart';

class SearchBarWidget extends StatelessWidget {
  final VoidCallback onTap;
  final bool enabled;

  const SearchBarWidget({
    super.key,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = context.isTablet;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        margin: EdgeInsets.zero,
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 18.w : 16.w,
          vertical: isTablet ? 14.h : 12.h,
        ),
        decoration: BoxDecoration(
          color: AppColors.greyLight,
          borderRadius: BorderRadius.circular(isTablet ? 14.r : 12.r),
          border: Border.all(
            color: AppColors.greyBorder.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.search,
              color: AppColors.textSecondary,
              size: isTablet ? 22.sp : 20.sp,
            ),
            SizedBox(width: isTablet ? 14.w : 12.w),
            Expanded(
              child: Text(
                AppLocalizations.of(context).searchSessions,
                style: GoogleFonts.inter(
                  fontSize: isTablet ? 16.sp : 15.sp,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
