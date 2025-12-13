import 'package:flutter/material.dart';

class AppColors {
  // Prevent instantiation
  AppColors._();

  // ============================================================
  // LIGHT THEME COLORS
  // ============================================================

  // Backgrounds - Light
  static const Color backgroundWhite = Color(0xFFF8F8F8);
  static const Color backgroundPure = Color(0xFFFFFFFF);
  static const Color backgroundCard = Color(0xFFF5F5F5);
  static const Color backgroundElevated = Color(0xFFFFFFFF);
  static const Color backgroundMarble = Color(0xFFF5F0E8);
  static const Color backgroundBeige = Color(0xFFF5F0E8);

  // Text Colors - Light
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textLight = Color(0xFF999999);
  static const Color textOnDark = Color(0xFFFFFFFF);

  // Grey Tones - Light
  static const Color greyLight = Color(0xFFEEEEEE);
  static const Color greyMedium = Color(0xFFE0E0E0);
  static const Color greyBorder = Color(0xFFD6D6D6);

  // Dividers - Light
  static const Color dividerLight = Color(0xFFE0E0E0);
  static const Color dividerDark = Color(0xFFCCCCCC);

  // ============================================================
  // DARK THEME COLORS (Soft Dark - Spotify/Instagram style)
  // ============================================================

  // Backgrounds - Dark (NOT pure black, soft dark grey)
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkBackgroundPure = Color(0xFF0D0D0D);
  static const Color darkBackgroundCard = Color(0xFF1E1E1E);
  static const Color darkBackgroundElevated = Color(0xFF282828);
  static const Color darkSurface = Color(0xFF1A1A1A);

  // Text Colors - Dark
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFB3B3B3);
  static const Color darkTextLight = Color(0xFF727272);
  static const Color darkTextOnLight = Color(0xFF121212);

  // Grey Tones - Dark
  static const Color darkGreyLight = Color(0xFF2A2A2A);
  static const Color darkGreyMedium = Color(0xFF3D3D3D);
  static const Color darkGreyBorder = Color(0xFF404040);

  // Dividers - Dark
  static const Color darkDivider = Color(0xFF2A2A2A);
  static const Color darkDividerLight = Color(0xFF1F1F1F);

  // ============================================================
  // ACCENT COLORS (Same for both themes)
  // ============================================================

  static const Color accentPrimary = Color(0xFF1A1A1A);
  static const Color accentSuccess = Color(0xFF4CAF50);
  static const Color accentError = Color(0xFFE53935);
  static const Color accentWarning = Color(0xFFFFA726);
  static const Color accentInfo = Color(0xFF29B6F6);

  // Premium/Special
  static const Color premiumGold = Color(0xFFFFD700);
  static const Color premiumAmber = Color(0xFFFFC107);
}
