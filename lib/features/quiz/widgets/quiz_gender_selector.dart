// lib/features/quiz/widgets/quiz_gender_selector.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/themes/app_theme_extension.dart';

class QuizGenderSelector extends StatelessWidget {
  final String selectedGender;
  final String maleLabel;
  final String femaleLabel;
  final bool isTablet;
  final Animation<double> firstButtonAnimation;
  final Animation<double> secondButtonAnimation;
  final ValueChanged<String> onGenderChanged;

  const QuizGenderSelector({
    super.key,
    required this.selectedGender,
    required this.maleLabel,
    required this.femaleLabel,
    required this.isTablet,
    required this.firstButtonAnimation,
    required this.secondButtonAnimation,
    required this.onGenderChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Transform.translate(
                offset: Offset(
                    -20 * (1 - firstButtonAnimation.value), 0),
                child: Opacity(
                  opacity: firstButtonAnimation.value.clamp(0.0, 1.0),
                  child: _buildGenderButton(
                    context: context,
                    gender: 'male',
                    label: maleLabel,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Transform.translate(
                offset: Offset(
                    20 * (1 - secondButtonAnimation.value), 0),
                child: Opacity(
                  opacity: secondButtonAnimation.value.clamp(0.0, 1.0),
                  child: _buildGenderButton(
                    context: context,
                    gender: 'female',
                    label: femaleLabel,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderButton({
    required BuildContext context,
    required String gender,
    required String label,
  }) {
    final colors = context.colors;
    final isSelected = selectedGender == gender;

    return GestureDetector(
      onTap: () => onGenderChanged(gender),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 14.w : 12.w,
          vertical: isTablet ? 9.h : 8.h,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? (context.isDarkMode
                  ? colors.textPrimary.withValues(alpha: 0.85)
                  : colors.textPrimary)
              : colors.backgroundCard,
          borderRadius: BorderRadius.circular(100.r),
          border: Border.all(
            color: isSelected
                ? (context.isDarkMode
                    ? colors.textPrimary.withValues(alpha: 0.85)
                    : colors.textPrimary)
                : colors.border,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: isTablet ? 14.sp : 13.sp,
              fontWeight: FontWeight.w600,
              color: isSelected ? colors.textOnPrimary : colors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}