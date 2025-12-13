// lib/features/settings/widgets/language_selector.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/themes/app_theme_extension.dart';
import '../../../providers/locale_provider.dart';
import '../../../core/responsive/context_ext.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, _) {
        return InkWell(
          onTap: () => _showLanguageModal(context, localeProvider),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            decoration: BoxDecoration(
              color: colors.backgroundCard,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: colors.border,
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
                    color: colors.greyLight,
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
                          color: colors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        localeProvider.getLanguageName(
                          localeProvider.locale.languageCode,
                        ),
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16.sp,
                  color: colors.textSecondary,
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
                maxHeight: 500.h,
              ),
              decoration: BoxDecoration(
                color: context.colors.backgroundElevated,
                borderRadius: BorderRadius.circular(24.r),
                boxShadow: [
                  BoxShadow(
                    color: context.colors.textPrimary.withValues(alpha: 0.1),
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
                                color: context.colors.textPrimary,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(
                              Icons.close,
                              color: context.colors.textSecondary,
                              size: 24.sp,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),

                    Divider(height: 1, color: context.colors.border),

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
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.textPrimary.withValues(alpha: 0.1)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            // Flag emoji
            Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                color: colors.greyLight,
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
                  color: colors.textPrimary,
                ),
              ),
            ),

            // Check icon
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: colors.textPrimary,
                size: 24.sp,
              ),
          ],
        ),
      ),
    );
  }
}
