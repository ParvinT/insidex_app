// lib/shared/widgets/category_icon.dart

import 'package:flutter/material.dart';
import '../../core/constants/app_icons.dart';
import '../../core/themes/app_theme_extension.dart';

/// Reusable category icon widget that replaces Lottie animations.
///
/// Automatically adapts to dark/light mode using [ColorFiltered].
/// The source PNGs are black icons with transparent backgrounds.
/// - Light mode: displayed as-is (black)
/// - Dark mode: inverted to white
/// - On dark surfaces (e.g. category cards with photo overlay): forced white
///
/// Usage:
/// ```dart
/// CategoryIcon(name: 'brain', size: 48)
/// CategoryIcon(name: 'heart', size: 32, forceBrightness: Brightness.dark)
/// ```
class CategoryIcon extends StatelessWidget {
  /// Icon name matching the Firestore `iconName` field
  final String name;

  /// Icon display size (width & height)
  final double size;

  /// Optional color override. When set, the icon is tinted with this color.
  /// When null, the icon automatically adapts to theme brightness.
  final Color? color;

  /// Force a specific brightness regardless of theme.
  /// Use [Brightness.dark] when placing on dark backgrounds (e.g. photo cards).
  final Brightness? forceBrightness;

  /// BoxFit for the image
  final BoxFit fit;

  const CategoryIcon({
    super.key,
    required this.name,
    required this.size,
    this.color,
    this.forceBrightness,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    final assetPath = AppIcons.getIconAssetPath(name);
    final effectiveColor = _resolveColor(context);

    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: fit,
        color: effectiveColor,
        colorBlendMode: BlendMode.srcIn,
        errorBuilder: (context, error, stackTrace) {
          // Fallback: show a generic icon if PNG not found
          return Icon(
            Icons.category,
            size: size * 0.6,
            color: effectiveColor,
          );
        },
      ),
    );
  }

  /// Resolve the effective icon color based on theme and overrides.
  Color _resolveColor(BuildContext context) {
    // Explicit color override takes priority
    if (color != null) return color!;

    // Determine brightness
    final brightness =
        forceBrightness ?? Theme.of(context).brightness;

    // On dark backgrounds → white icon, on light backgrounds → keep black
    if (brightness == Brightness.dark) {
      return Colors.white;
    }

    // Light mode: use the original black color (no tint needed,
    // but we apply textPrimary for theme consistency)
    return context.colors.textPrimary;
  }
}