// lib/features/search/widgets/search_history_item.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/responsive/context_ext.dart';

class SearchHistoryItem extends StatelessWidget {
  final String query;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const SearchHistoryItem({
    super.key,
    required this.query,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = context.isTablet;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(isTablet ? 12.r : 10.r),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 16.w : 12.w,
          vertical: isTablet ? 14.h : 12.h,
        ),
        margin: EdgeInsets.only(bottom: isTablet ? 10.h : 8.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isTablet ? 12.r : 10.r),
          border: Border.all(
            color: AppColors.greyBorder.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.history,
              color: AppColors.textSecondary,
              size: isTablet ? 20.sp : 18.sp,
            ),
            SizedBox(width: isTablet ? 14.w : 12.w),
            Expanded(
              child: Text(
                query,
                style: GoogleFonts.inter(
                  fontSize: isTablet ? 15.sp : 14.sp,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.close,
                color: AppColors.textSecondary,
                size: isTablet ? 18.sp : 16.sp,
              ),
              padding: EdgeInsets.all(isTablet ? 8.w : 6.w),
              constraints: const BoxConstraints(),
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}
