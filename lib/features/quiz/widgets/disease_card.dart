// lib/features/quiz/widgets/disease_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../../../core/themes/app_theme_extension.dart';
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
    final isTablet = context.isTablet;

    final double fontSize =
        isTablet ? 14.sp.clamp(13.0, 16.0) : 13.sp.clamp(12.0, 15.0);
    final double borderRadius = isTablet ? 16.r : 14.r;
    final double horizontalPadding = isTablet ? 14.w : 12.w;
    final double verticalPadding = isTablet ? 12.h : 10.h;

    return FutureBuilder<String>(
      future: LanguageHelperService.getCurrentLanguage(),
      builder: (context, snapshot) {
        final currentLanguage = snapshot.data ?? 'en';
        final diseaseName = disease.getLocalizedName(currentLanguage);
        final colors = context.colors;
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
                  ? (context.isDarkMode
                      ? colors.textPrimary.withValues(alpha: 0.85)
                      : colors.textPrimary)
                  : (isDisabled ? colors.greyLight : colors.backgroundCard),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: isSelected
                    ? (context.isDarkMode
                        ? colors.textPrimary.withValues(alpha: 0.85)
                        : colors.textPrimary)
                    : colors.border.withValues(alpha: 0.3),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Center(
              child: AutoSizeText(
                diseaseName,
                style: GoogleFonts.inter(
                  fontSize: fontSize,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? colors.textOnPrimary
                      : (isDisabled ? colors.textLight : colors.textPrimary),
                  height: 1.2,
                ),
                maxLines: 2,
                minFontSize: 7,
                stepGranularity: 0.5,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                wrapWords: true,
              ),
            ),
          ),
        );
      },
    );
  }
}
