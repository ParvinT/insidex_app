// lib/features/search/widgets/quiz_category_search_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/themes/app_theme_extension.dart';
import '../../../core/responsive/context_ext.dart';
import '../../../l10n/app_localizations.dart';
import '../quiz_search_service.dart';

class QuizCategorySearchCard extends StatelessWidget {
  final QuizCategorySearchResult result;
  final VoidCallback? onTap;
  final String locale;

  const QuizCategorySearchCard({
    super.key,
    required this.result,
    required this.locale,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isTablet = context.isTablet;
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
            // Icon
            Container(
              width: isTablet ? 52.w : 44.w,
              height: isTablet ? 52.w : 44.w,
              decoration: BoxDecoration(
                color: _getGenderColor(category.gender).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                _getIconData(category.iconName),
                color: _getGenderColor(category.gender),
                size: isTablet ? 26.sp : 22.sp,
              ),
            ),

            SizedBox(width: 14.w),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category name
                  Text(
                    category.getName(locale),
                    style: GoogleFonts.inter(
                      fontSize: isTablet ? 16.sp : 14.sp,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  SizedBox(height: 6.h),

                  // Info row
                  Row(
                    children: [
                      // Gender badge
                      _buildGenderBadge(category.gender, colors, context),

                      SizedBox(width: 10.w),

                      // Disease count
                      _buildDiseaseCount(colors, isTablet),
                    ],
                  ),
                ],
              ),
            ),

            // Arrow
            Icon(
              Icons.arrow_forward_ios,
              color: colors.textSecondary.withValues(alpha: 0.5),
              size: isTablet ? 16.sp : 14.sp,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderBadge(
      String gender, AppThemeExtension colors, BuildContext context) {
    final badgeColor = _getGenderColor(gender);
    final icon = _getGenderIcon(gender);
    final l10n = AppLocalizations.of(context);

    String label;
    switch (gender) {
      case 'male':
        label = l10n.male;
        break;
      case 'female':
        label = l10n.female;
        break;
      default:
        label = l10n.both;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 8.w,
        vertical: 4.h,
      ),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12.sp,
            color: badgeColor,
          ),
          SizedBox(width: 4.w),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiseaseCount(AppThemeExtension colors, bool isTablet) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 8.w,
        vertical: 4.h,
      ),
      decoration: BoxDecoration(
        color: colors.greyLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.list_alt,
            size: 12.sp,
            color: colors.textSecondary,
          ),
          SizedBox(width: 4.w),
          Text(
            '${result.totalCount}',
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              fontWeight: FontWeight.w500,
              color: colors.textSecondary,
            ),
          ),
          if (result.totalCount > 0) ...[
            SizedBox(width: 4.w),
            Text(
              '(♂${result.maleCount} ♀${result.femaleCount})',
              style: GoogleFonts.inter(
                fontSize: 10.sp,
                color: colors.textSecondary.withValues(alpha: 0.7),
              ),
            ),
          ],
        ],
      ),
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

  IconData _getIconData(String iconName) {
    const iconMap = {
      'face': Icons.face,
      'person': Icons.person,
      'no_drinks': Icons.no_drinks,
      'child_care': Icons.child_care,
      'psychology': Icons.psychology,
      'psychology_alt': Icons.psychology_alt,
      'restaurant': Icons.restaurant,
      'favorite': Icons.favorite,
      'accessibility_new': Icons.accessibility_new,
      'air': Icons.air,
      'visibility': Icons.visibility,
      'mood': Icons.mood,
      'water_drop': Icons.water_drop,
      'medical_services': Icons.medical_services,
      'health_and_safety': Icons.health_and_safety,
      'fitness_center': Icons.fitness_center,
      'category': Icons.category,
      'healing': Icons.healing,
      'local_hospital': Icons.local_hospital,
      'monitor_heart': Icons.monitor_heart,
      'medication': Icons.medication,
      'vaccines': Icons.vaccines,
      'bloodtype': Icons.bloodtype,
      'sick': Icons.sick,
      'elderly': Icons.elderly,
      'pregnant_woman': Icons.pregnant_woman,
      'male': Icons.male,
      'female': Icons.female,
    };

    return iconMap[iconName] ?? Icons.category;
  }
}
