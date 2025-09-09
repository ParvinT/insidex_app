// lib/core/responsive/context_ext.dart
import 'package:flutter/material.dart';
import 'breakpoints.dart';

extension ContextX on BuildContext {
  Size get screenSize => MediaQuery.of(this).size;
  double get w => screenSize.width;
  double get h => screenSize.height;
  double get bottomPad => MediaQuery.of(this).padding.bottom;
  double get topPad => MediaQuery.of(this).padding.top;
  double get kbInset => MediaQuery.of(this).viewInsets.bottom;

  bool get isMobile => w < Breakpoints.tabletMin;
  bool get isTablet => w >= Breakpoints.tabletMin && w < Breakpoints.desktopMin;
  bool get isDesktop => w >= Breakpoints.desktopMin;
  bool get isCompactH => h <= Breakpoints.compactHeight;
}
