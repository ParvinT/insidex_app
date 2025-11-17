// lib/features/quiz/widgets/disease_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/responsive/context_ext.dart';
import '../../../models/disease_model.dart';
import '../../../services/language_helper_service.dart';

class DiseaseCard extends StatelessWidget {
  final DiseaseModel disease;
  final VoidCallback onTap;
  final bool isSelected;
  final bool isDisabled;

  const DiseaseCard({
    super.key,
    required this.disease,
    required this.onTap,
    this.isSelected = false,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    // Responsive values
    final isTablet = context.isTablet;

    final double fontSize =
        isTablet ? 15.sp.clamp(14.0, 16.0) : 14.sp.clamp(13.0, 15.0);
    final double borderRadius = isTablet ? 24.r : 22.r;
    final double horizontalPadding = isTablet ? 18.w : 16.w;
    final double verticalPadding = isTablet ? 14.h : 12.h;

    return FutureBuilder<String>(
      future: LanguageHelperService.getCurrentLanguage(),
      builder: (context, snapshot) {
        final currentLanguage = snapshot.data ?? 'en';
        final diseaseName = disease.getLocalizedName(currentLanguage);

        return InkWell(
          onTap: isDisabled && !isSelected ? null : onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.black
                  : (isDisabled ? Colors.grey[100] : Colors.white),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: isSelected
                    ? Colors.black
                    : AppColors.greyBorder.withOpacity(0.3),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                // Checkbox
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isTablet ? 20.w : 18.w,
                  height: isTablet ? 20.w : 18.w,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? Colors.white
                          : (isDisabled ? Colors.grey[400]! : Colors.black),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          size: isTablet ? 14.sp : 12.sp,
                          color: Colors.black,
                        )
                      : null,
                ),

                SizedBox(width: 10.w),

                // Disease name
                Expanded(
                  child: Text(
                    diseaseName,
                    style: GoogleFonts.inter(
                      fontSize: fontSize,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : (isDisabled
                              ? Colors.grey[400]
                              : AppColors.textPrimary),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
