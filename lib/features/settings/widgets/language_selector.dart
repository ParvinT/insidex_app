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
                  decoration: const BoxDecoration(
                    color: AppColors.greyLight,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      localeProvider.getLanguageFlag(
                        localeProvider.locale.languageCode,
                      ),
                      style: TextStyle(fontSize: 20.sp),
                    ),
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

    final double titleSize =
        isTablet ? 20.sp.clamp(18.0, 22.0) : 18.sp.clamp(16.0, 20.0);

    final double itemSize =
        isTablet ? 16.sp.clamp(15.0, 17.0) : 15.sp.clamp(14.0, 16.0);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.symmetric(
              horizontal: 20.w,
              vertical: 100.h,
            ),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: 400.w,
                maxHeight: 500.h, // ← Max yükseklik ekle (overflow önlenir)
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(24.r), // ← Tüm köşeler yuvarlak
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Padding(
                      padding: EdgeInsets.all(20.w),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _getLocalizedTitle(
                                  localeProvider.locale.languageCode),
                              style: GoogleFonts.inter(
                                fontSize: titleSize,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(
                              Icons.close,
                              color: AppColors.textSecondary,
                              size: 24.sp,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1, color: AppColors.greyBorder),

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
                    }),

                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ));
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
              ? AppColors.textPrimary.withValues(alpha: 0.1)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            // Flag emoji
            Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  localeProvider.getLanguageFlag(locale.languageCode),
                  style: TextStyle(fontSize: 18.sp),
                ),
              ),
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
                      ? AppColors.textPrimary
                      : AppColors.textPrimary,
                ),
              ),
            ),

            // Check icon
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppColors.textPrimary,
                size: 24.sp,
              ),
          ],
        ),
      ),
    );
  }
}
