// lib/core/responsive/responsive_layout.dart
import 'package:flutter/material.dart';
import 'breakpoints.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  const ResponsiveLayout(
      {super.key, required this.mobile, this.tablet, this.desktop});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, c) {
      final w = c.maxWidth;
      if (w >= Breakpoints.desktopMin && desktop != null) return desktop!;
      if (w >= Breakpoints.tabletMin && tablet != null) return tablet!;
      return mobile;
    });
  }
}
