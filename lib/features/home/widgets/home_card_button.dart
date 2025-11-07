// lib/features/home/widgets/home_card_button.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/cache_manager_service.dart';

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
    // Fallback to local asset if no image URL
    if (widget.imageUrl == null || widget.imageUrl!.isEmpty) {
      return Image.asset(
        'assets/images/home_card_fallback.jpg',
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return _buildFallbackGradient();
        },
      );
    }

    return CachedNetworkImage(
      imageUrl: widget.imageUrl!,
      cacheManager: AppCacheManager.instance,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      placeholder: (context, url) => _buildShimmerPlaceholder(),
      errorWidget: (context, url, error) => _buildFallbackGradient(),
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

  /// Fallback gradient if no image
  Widget _buildFallbackGradient() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFCCCBCB),
            const Color(0xFFE0E0E0),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          widget.icon ?? Icons.music_note,
          size: 48.sp,
          color: AppColors.textPrimary.withOpacity(0.3),
        ),
      ),
    );
  }
}
