// lib/features/search/widgets/disease_search_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/themes/app_theme_extension.dart';
import '../../../core/responsive/context_ext.dart';
import '../../../l10n/app_localizations.dart';
import '../quiz_search_service.dart';

class DiseaseSearchCard extends StatelessWidget {
  final DiseaseSearchResult result;
  final VoidCallback? onTap;
  final String locale;

  const DiseaseSearchCard({
    super.key,
    required this.result,
    required this.locale,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isTablet = context.isTablet;
    final disease = result.disease;
    final category = result.category;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isTablet ? 16.w : 14.w),
        decoration: BoxDecoration(
          color: colors.backgroundCard,
          borderRadius: BorderRadius.circular(isTablet ? 16.r : 14.r),
          border: Border.all(
            color: colors.border.withValues(alpha: 0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.textPrimary.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Disease icon/indicator
            Container(
              width: isTablet ? 48.w : 40.w,
              height: isTablet ? 48.w : 40.w,
              decoration: BoxDecoration(
                color: _getGenderColor(disease.gender).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                Icons.healing,
                color: _getGenderColor(disease.gender),
                size: isTablet ? 24.sp : 20.sp,
              ),
            ),

            SizedBox(width: 14.w),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Disease name
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          disease.getLocalizedName(locale),
                          style: GoogleFonts.inter(
                            fontSize: isTablet ? 15.sp : 14.sp,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      SizedBox(width: 8.w),

                      // Gender badge
                      _buildGenderBadge(disease.gender, colors),
                    ],
                  ),

                  SizedBox(height: 6.h),

                  // Bottom row: Category + Session status
                  Row(
                    children: [
                      // Category
                      if (category != null) ...[
                        Icon(
                          Icons.folder_outlined,
                          size: 12.sp,
                          color: colors.textSecondary,
                        ),
                        SizedBox(width: 4.w),
                        Flexible(
                          child: Text(
                            category.getName(locale),
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              color: colors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ] else ...[
                        Icon(
                          Icons.folder_off_outlined,
                          size: 12.sp,
                          color: colors.textSecondary.withValues(alpha: 0.5),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          AppLocalizations.of(context).uncategorized,
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            color: colors.textSecondary.withValues(alpha: 0.5),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],

                      const Spacer(),

                      // Session status indicator
                      _buildSessionIndicator(colors, context),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderBadge(String gender, AppThemeExtension colors) {
    final badgeColor = _getGenderColor(gender);
    final icon = _getGenderIcon(gender);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 6.w,
        vertical: 2.h,
      ),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 11.sp,
            color: badgeColor,
          ),
          SizedBox(width: 2.w),
          Text(
            gender == 'male' ? '♂' : '♀',
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionIndicator(
      AppThemeExtension colors, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (result.hasSession) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.headphones,
            size: 12.sp,
            color: Colors.green,
          ),
          SizedBox(width: 4.w),
          Text(
            l10n.sessionAvailable,
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              fontWeight: FontWeight.w500,
              color: Colors.green,
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.hourglass_empty,
          size: 12.sp,
          color: colors.textSecondary.withValues(alpha: 0.5),
        ),
        SizedBox(width: 4.w),
        Text(
          l10n.comingSoon,
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            color: colors.textSecondary.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Color _getGenderColor(String gender) {
    switch (gender) {
      case 'male':
        return Colors.blue;
      case 'female':
        return Colors.pink;
      default:
        return Colors.purple;
    }
  }

  IconData _getGenderIcon(String gender) {
    switch (gender) {
      case 'male':
        return Icons.male;
      case 'female':
        return Icons.female;
      default:
        return Icons.people;
    }
  }
}
