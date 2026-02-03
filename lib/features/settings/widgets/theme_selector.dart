// lib/features/settings/widgets/theme_selector.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/themes/app_theme_extension.dart';
import '../../../providers/theme_provider.dart';
import '../../../l10n/app_localizations.dart';

class ThemeSelector extends StatelessWidget {
  const ThemeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return InkWell(
          onTap: () => _showThemeBottomSheet(context),
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            decoration: BoxDecoration(
              color: colors.backgroundCard,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    color: colors.textPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    _getThemeIcon(themeProvider.themeMode),
                    color: colors.textPrimary,
                    size: 22.sp,
                  ),
                ),
                SizedBox(width: 14.w),

                // Title & Current Value
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.appearance,
                        style: GoogleFonts.inter(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        _getThemeLabel(context, themeProvider.themeMode),
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow
                Icon(
                  Icons.chevron_right,
                  color: colors.textSecondary,
                  size: 24.sp,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getThemeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode_outlined;
      case ThemeMode.dark:
        return Icons.dark_mode_outlined;
      case ThemeMode.system:
        return Icons.settings_suggest_outlined;
    }
  }

  String _getThemeLabel(BuildContext context, ThemeMode mode) {
    final l10n = AppLocalizations.of(context);
    switch (mode) {
      case ThemeMode.light:
        return l10n.lightMode;
      case ThemeMode.dark:
        return l10n.darkMode;
      case ThemeMode.system:
        return l10n.systemDefault;
    }
  }

  void _showThemeBottomSheet(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: colors.backgroundElevated,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: EdgeInsets.only(top: 12.h),
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: colors.greyMedium,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),

              // Title
              Padding(
                padding: EdgeInsets.all(20.w),
                child: Text(
                  l10n.appearance,
                  style: GoogleFonts.inter(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ),

              Divider(height: 1, color: colors.divider),

              // Theme Options
              Consumer<ThemeProvider>(
                builder: (context, themeProvider, child) {
                  return Column(
                    children: [
                      _buildThemeOptionTile(
                        context: context,
                        icon: Icons.light_mode_outlined,
                        title: l10n.lightMode,
                        subtitle: l10n.lightModeSubtitle,
                        isSelected: themeProvider.themeMode == ThemeMode.light,
                        onTap: () {
                          themeProvider.setThemeMode(ThemeMode.light);
                          Navigator.pop(context);
                        },
                        colors: colors,
                      ),
                      _buildThemeOptionTile(
                        context: context,
                        icon: Icons.dark_mode_outlined,
                        title: l10n.darkMode,
                        subtitle: l10n.darkModeSubtitle,
                        isSelected: themeProvider.themeMode == ThemeMode.dark,
                        onTap: () {
                          themeProvider.setThemeMode(ThemeMode.dark);
                          Navigator.pop(context);
                        },
                        colors: colors,
                      ),
                      _buildThemeOptionTile(
                        context: context,
                        icon: Icons.settings_suggest_outlined,
                        title: l10n.systemDefault,
                        subtitle: l10n.systemDefaultSubtitle,
                        isSelected: themeProvider.themeMode == ThemeMode.system,
                        onTap: () {
                          themeProvider.setThemeMode(ThemeMode.system);
                          Navigator.pop(context);
                        },
                        colors: colors,
                      ),
                    ],
                  );
                },
              ),

              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeOptionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    required AppThemeExtension colors,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        color: isSelected ? colors.textPrimary.withValues(alpha: 0.05) : null,
        child: Row(
          children: [
            // Icon
            Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                color: isSelected
                    ? colors.textPrimary.withValues(alpha: 0.15)
                    : colors.greyLight,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                icon,
                color: isSelected ? colors.textPrimary : colors.textSecondary,
                size: 24.sp,
              ),
            ),
            SizedBox(width: 16.w),

            // Title & Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: colors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Radio Button
            Container(
              width: 24.w,
              height: 24.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? colors.textPrimary : colors.border,
                  width: 2,
                ),
                color: isSelected ? colors.textPrimary : Colors.transparent,
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      color: colors.textOnPrimary,
                      size: 16.sp,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
