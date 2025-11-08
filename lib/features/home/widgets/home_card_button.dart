// lib/features/home/widgets/home_card_button.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/cache_manager_service.dart';
import '../../../l10n/app_localizations.dart';

/// Home Card Button Widget
/// A beautiful card with background image, overlay, and smooth tap animations
class HomeCardButton extends StatefulWidget {
  final String? imageUrl;
  final String title;
  final IconData? icon;
  final VoidCallback onTap;
  final double height;

  const HomeCardButton({
    super.key,
    required this.imageUrl,
    required this.title,
    this.icon,
    required this.onTap,
    this.height = 200.0,
  });

  @override
  State<HomeCardButton> createState() => _HomeCardButtonState();
}

class _HomeCardButtonState extends State<HomeCardButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    // Scale animation for tap feedback
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _scaleController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _scaleController.reverse();

    // Navigate with smooth transition
    Future.delayed(const Duration(milliseconds: 100), () {
      widget.onTap();
    });
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: Container(
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isPressed ? 0.1 : 0.15),
                blurRadius: _isPressed ? 15 : 20,
                offset: Offset(0, _isPressed ? 8 : 10),
                spreadRadius: _isPressed ? 0 : 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30.r),
            child: Stack(
              children: [
                // 1. Background Image
                _buildBackgroundImage(),

                // 2. Dark Gradient Overlay
                _buildGradientOverlay(),

                // 3. Content (Icon + Title)
                _buildContent(),

                // 4. Shimmer effect on press (optional)
                if (_isPressed) _buildPressedOverlay(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Background image with fade-in animation
  Widget _buildBackgroundImage() {
    if (widget.imageUrl == null || widget.imageUrl!.isEmpty) {
      return _buildBrandPlaceholder(showOfflineBadge: false);
    }

    return CachedNetworkImage(
      imageUrl: widget.imageUrl!,
      cacheManager: AppCacheManager.instance,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      placeholder: (context, url) => _buildShimmerPlaceholder(),
      errorWidget: (context, url, error) {
        // 👈 BURASI YENİ - Network error detection
        final isNetworkError = error.toString().contains('SocketException') ||
            error.toString().contains('Failed host lookup') ||
            error.toString().contains('NetworkImageLoadException');

        return _buildBrandPlaceholder(showOfflineBadge: isNetworkError);
      },
      fadeInDuration: const Duration(milliseconds: 500),
      fadeOutDuration: const Duration(milliseconds: 300),
    );
  }

  /// Dark gradient overlay for text readability
  Widget _buildGradientOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.2),
            Colors.black.withOpacity(0.5),
          ],
          stops: const [0.0, 1.0],
        ),
      ),
    );
  }

  /// Content: Icon and Title
  Widget _buildContent() {
    return Padding(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon in top-right
          if (widget.icon != null)
            Align(
              alignment: Alignment.topRight,
              child: Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  widget.icon,
                  size: 16.sp,
                  color: Colors.white,
                ),
              ),
            ),

          const Spacer(),

          // Title at bottom
          Text(
            widget.title,
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Pressed overlay effect
  Widget _buildPressedOverlay() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
      ),
    );
  }

  /// Shimmer placeholder while loading
  Widget _buildShimmerPlaceholder() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        color: Colors.white,
      ),
    );
  }

  Widget _buildBrandPlaceholder({required bool showOfflineBadge}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryGoldLight.withOpacity(0.8),
            AppColors.primaryGold.withOpacity(0.85),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Subtle dot pattern
          Positioned.fill(
            child: CustomPaint(
              painter: _DotPatternPainter(),
            ),
          ),

          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated icon
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.92, end: 1.0),
                  duration: const Duration(milliseconds: 1500),
                  curve: Curves.easeInOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        padding: EdgeInsets.all(20.w),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          widget.icon ?? Icons.music_note_rounded,
                          size: 42.sp,
                          color: Colors.white.withOpacity(0.95),
                        ),
                      ),
                    );
                  },
                ),

                SizedBox(height: 16.h),

                // Brand name
                Text(
                  'INSIDEX',
                  style: GoogleFonts.inter(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withOpacity(0.95),
                    letterSpacing: 3,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Offline badge
          if (showOfflineBadge)
            Positioned(
              bottom: 12.h,
              right: 12.w,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 6.h,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.25),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.cloud_off_rounded,
                      size: 14.sp,
                      color: Colors.white.withOpacity(0.95),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      AppLocalizations.of(context).offline,
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.95),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.fill;

    const spacing = 25.0;
    const dotSize = 1.5;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotSize, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
