// lib/features/settings/widgets/language_selector.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/locale_provider.dart';
import '../../../core/responsive/context_ext.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, _) {
        return InkWell(
          onTap: () => _showLanguageModal(context, localeProvider),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: AppColors.greyBorder,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    color: AppColors.greyLight,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    Icons.language,
                    color: AppColors.textPrimary, // ← SİYAH
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 16.w),

                // Title and Current Language
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getLocalizedTitle(localeProvider.locale.languageCode),
                        style: GoogleFonts.inter(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        localeProvider.getLanguageName(
                          localeProvider.locale.languageCode,
                        ),
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16.sp,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Seçili dile göre başlık
  String _getLocalizedTitle(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'Language';
      case 'ru':
        return 'Язык';
      case 'tr':
        return 'Dil';
      case 'hi':
        return 'भाषा';
      default:
        return 'Language';
    }
  }

  // Modal Popup
  void _showLanguageModal(
    BuildContext context,
    LocaleProvider localeProvider,
  ) {
    // Responsive değerler
    final isTablet = context.isTablet;
    final isDesktop = context.isDesktop;

    final double modalWidth = isDesktop
        ? 400
        : (isTablet
            ? MediaQuery.of(context).size.width * 0.7
            : double.infinity);

    final double titleSize =
        isTablet ? 20.sp.clamp(18.0, 22.0) : 18.sp.clamp(16.0, 20.0);

    final double itemSize =
        isTablet ? 16.sp.clamp(15.0, 17.0) : 15.sp.clamp(14.0, 16.0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          width: modalWidth,
          margin: isDesktop || isTablet
              ? EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.15,
                )
              : EdgeInsets.zero,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24.r),
              topRight: Radius.circular(24.r),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: EdgeInsets.only(top: 12.h),
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.greyBorder,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),

              // Title
              Padding(
                padding: EdgeInsets.all(20.w),
                child: Text(
                  _getLocalizedTitle(localeProvider.locale.languageCode),
                  style: GoogleFonts.inter(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),

              Divider(height: 1, color: AppColors.greyBorder),

              // Language Options
              ...LocaleProvider.supportedLocales.map((locale) {
                final isSelected = localeProvider.locale == locale;
                return _buildLanguageOption(
                  context: context,
                  locale: locale,
                  isSelected: isSelected,
                  onTap: () {
                    localeProvider.setLocale(locale);
                    Navigator.pop(context);
                  },
                  localeProvider: localeProvider,
                  itemSize: itemSize,
                );
              }).toList(),

              SizedBox(height: 20.h),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption({
    required BuildContext context,
    required Locale locale,
    required bool isSelected,
    required VoidCallback onTap,
    required LocaleProvider localeProvider,
    required double itemSize,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryGold.withOpacity(0.1)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            // Flag emoji
            Text(
              localeProvider.getLanguageFlag(locale.languageCode),
              style: TextStyle(fontSize: 28.sp),
            ),
            SizedBox(width: 12.w),

            // Language name
            Expanded(
              child: Text(
                localeProvider.getLanguageName(locale.languageCode),
                style: GoogleFonts.inter(
                  fontSize: itemSize,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? AppColors.primaryGold
                      : AppColors.textPrimary,
                ),
              ),
            ),

            // Check icon
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppColors.primaryGold,
                size: 24.sp,
              ),
          ],
        ),
      ),
    );
  }
}
