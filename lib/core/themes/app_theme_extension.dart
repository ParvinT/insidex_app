import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Custom theme extension for semantic color access
/// Usage: Theme.of(context).extension<AppThemeExtension>()!.background
/// Or with extension method: context.colors.background
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  // Backgrounds
  final Color background;
  final Color backgroundPure;
  final Color backgroundCard;
  final Color backgroundElevated;
  final Color surface;

  // Text
  final Color textPrimary;
  final Color textSecondary;
  final Color textLight;
  final Color textOnPrimary;

  // Grey/Borders
  final Color greyLight;
  final Color greyMedium;
  final Color border;
  final Color divider;

  // Interactive
  final Color iconPrimary;
  final Color iconSecondary;

  const AppThemeExtension({
    required this.background,
    required this.backgroundPure,
    required this.backgroundCard,
    required this.backgroundElevated,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.textLight,
    required this.textOnPrimary,
    required this.greyLight,
    required this.greyMedium,
    required this.border,
    required this.divider,
    required this.iconPrimary,
    required this.iconSecondary,
  });

  // Light Theme Extension
  static const light = AppThemeExtension(
    background: AppColors.backgroundWhite,
    backgroundPure: AppColors.backgroundPure,
    backgroundCard: AppColors.backgroundCard,
    backgroundElevated: AppColors.backgroundElevated,
    surface: AppColors.backgroundPure,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    textLight: AppColors.textLight,
    textOnPrimary: AppColors.textOnDark,
    greyLight: AppColors.greyLight,
    greyMedium: AppColors.greyMedium,
    border: AppColors.greyBorder,
    divider: AppColors.dividerLight,
    iconPrimary: AppColors.textPrimary,
    iconSecondary: AppColors.textSecondary,
  );

  // Dark Theme Extension
  static const dark = AppThemeExtension(
    background: AppColors.darkBackground,
    backgroundPure: AppColors.darkBackgroundPure,
    backgroundCard: AppColors.darkBackgroundCard,
    backgroundElevated: AppColors.darkBackgroundElevated,
    surface: AppColors.darkSurface,
    textPrimary: AppColors.darkTextPrimary,
    textSecondary: AppColors.darkTextSecondary,
    textLight: AppColors.darkTextLight,
    textOnPrimary: AppColors.darkTextOnLight,
    greyLight: AppColors.darkGreyLight,
    greyMedium: AppColors.darkGreyMedium,
    border: AppColors.darkGreyBorder,
    divider: AppColors.darkDivider,
    iconPrimary: AppColors.darkTextPrimary,
    iconSecondary: AppColors.darkTextSecondary,
  );

  @override
  AppThemeExtension copyWith({
    Color? background,
    Color? backgroundPure,
    Color? backgroundCard,
    Color? backgroundElevated,
    Color? surface,
    Color? textPrimary,
    Color? textSecondary,
    Color? textLight,
    Color? textOnPrimary,
    Color? greyLight,
    Color? greyMedium,
    Color? border,
    Color? divider,
    Color? iconPrimary,
    Color? iconSecondary,
  }) {
    return AppThemeExtension(
      background: background ?? this.background,
      backgroundPure: backgroundPure ?? this.backgroundPure,
      backgroundCard: backgroundCard ?? this.backgroundCard,
      backgroundElevated: backgroundElevated ?? this.backgroundElevated,
      surface: surface ?? this.surface,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textLight: textLight ?? this.textLight,
      textOnPrimary: textOnPrimary ?? this.textOnPrimary,
      greyLight: greyLight ?? this.greyLight,
      greyMedium: greyMedium ?? this.greyMedium,
      border: border ?? this.border,
      divider: divider ?? this.divider,
      iconPrimary: iconPrimary ?? this.iconPrimary,
      iconSecondary: iconSecondary ?? this.iconSecondary,
    );
  }

  @override
  AppThemeExtension lerp(ThemeExtension<AppThemeExtension>? other, double t) {
    if (other is! AppThemeExtension) return this;

    return AppThemeExtension(
      background: Color.lerp(background, other.background, t)!,
      backgroundPure: Color.lerp(backgroundPure, other.backgroundPure, t)!,
      backgroundCard: Color.lerp(backgroundCard, other.backgroundCard, t)!,
      backgroundElevated:
          Color.lerp(backgroundElevated, other.backgroundElevated, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textLight: Color.lerp(textLight, other.textLight, t)!,
      textOnPrimary: Color.lerp(textOnPrimary, other.textOnPrimary, t)!,
      greyLight: Color.lerp(greyLight, other.greyLight, t)!,
      greyMedium: Color.lerp(greyMedium, other.greyMedium, t)!,
      border: Color.lerp(border, other.border, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      iconPrimary: Color.lerp(iconPrimary, other.iconPrimary, t)!,
      iconSecondary: Color.lerp(iconSecondary, other.iconSecondary, t)!,
    );
  }
}

/// Extension method for easy access
/// Usage: context.colors.background
extension AppThemeExtensionX on BuildContext {
  AppThemeExtension get colors =>
      Theme.of(this).extension<AppThemeExtension>() ?? AppThemeExtension.light;

  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}
