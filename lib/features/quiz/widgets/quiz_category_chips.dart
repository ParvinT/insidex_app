// lib/features/quiz/widgets/quiz_category_chips.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/themes/app_theme_extension.dart';
import '../../../models/quiz_category_model.dart';

class QuizCategoryChips extends StatelessWidget {
  final List<QuizCategoryModel> categories;
  final String? selectedCategoryId;
  final String currentLanguage;
  final String allCategoriesLabel;
  final bool isTablet;
  final bool isLoading;
  final ValueChanged<String?> onCategoryChanged;

  const QuizCategoryChips({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.currentLanguage,
    required this.allCategoriesLabel,
    required this.isTablet,
    required this.isLoading,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (isLoading) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: SizedBox(
          height: 36.h,
          child: Center(
            child: SizedBox(
              width: 20.w,
              height: 20.w,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colors.textPrimary,
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: isTablet ? 42.h : 36.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        itemCount: categories.length + 1, // +1 for "All" option
        itemBuilder: (context, index) {
          if (index == 0) {
            // "All Categories" chip
            return _buildCategoryChip(
              context: context,
              id: null,
              name: allCategoriesLabel,
              isSelected: selectedCategoryId == null,
            );
          }

          final category = categories[index - 1];
          return _buildCategoryChip(
            context: context,
            id: category.id,
            name: category.getName(currentLanguage),
            isSelected: selectedCategoryId == category.id,
          );
        },
      ),
    );
  }

  Widget _buildCategoryChip({
    required BuildContext context,
    required String? id,
    required String name,
    required bool isSelected,
  }) {
    final colors = context.colors;

    return GestureDetector(
      onTap: () => onCategoryChanged(id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.only(right: 8.w),
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 14.w : 12.w,
          vertical: isTablet ? 8.h : 6.h,
        ),
        decoration: BoxDecoration(
          color: isSelected ? colors.textPrimary : colors.backgroundElevated,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected
                ? colors.textPrimary
                : colors.border.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              name,
              style: GoogleFonts.inter(
                fontSize: isTablet ? 13.sp : 12.sp,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? colors.textOnPrimary : colors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
