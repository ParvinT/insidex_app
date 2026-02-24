// lib/features/player/widgets/player_album_art.dart
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../../services/cache_manager_service.dart';
import '../../../core/themes/app_theme_extension.dart';

/// YouTube Music style album art with integrated equalizer and swipe navigation.
/// Supports swiping left/right to navigate between sessions in the queue.
class PlayerAlbumArt extends StatefulWidget {
  final String? imageUrl;
  final String? localImagePath;
  final AnimationController equalizerController;
  final bool isPlaying;

  // Swipe navigation
  final bool hasPrevious;
  final bool hasNext;
  final VoidCallback? onSwipePrevious;
  final VoidCallback? onSwipeNext;

  // Transition lock - parent tells us when a session change is in progress
  final bool isTransitioning;

  const PlayerAlbumArt({
    super.key,
    required this.imageUrl,
    this.localImagePath,
    required this.equalizerController,
    required this.isPlaying,
    this.hasPrevious = false,
    this.hasNext = false,
    this.onSwipePrevious,
    this.onSwipeNext,
    this.isTransitioning = false,
  });

  @override
  State<PlayerAlbumArt> createState() => _PlayerAlbumArtState();
}

class _PlayerAlbumArtState extends State<PlayerAlbumArt>
    with SingleTickerProviderStateMixin {
  late AnimationController _continuousController;

  // Horizontal drag tracking for swipe gesture
  double _dragOffset = 0.0;
  bool _swipeTriggered = false;

  // Swipe thresholds
  static const double _swipeThreshold = 80.0;
  static const double _velocityThreshold = 300.0;
  static const double _maxDragOffset = 120.0;

  // Unique key for AnimatedSwitcher based on current image
  Key get _imageKey => ValueKey(
        widget.imageUrl ?? widget.localImagePath ?? 'placeholder',
      );

  @override
  void initState() {
    super.initState();
    _continuousController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _continuousController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double imageSize = _calculateImageSize(size);
    final double imageHeight = imageSize * 9 / 16;
    final double borderRadius = imageSize * 0.08;

    final bool canSwipe =
        !widget.isTransitioning && (widget.hasPrevious || widget.hasNext);

    return SizedBox(
      width: imageSize,
      height: imageHeight,
      child: GestureDetector(
        onHorizontalDragStart: canSwipe ? _onDragStart : null,
        onHorizontalDragUpdate: canSwipe ? _onDragUpdate : null,
        onHorizontalDragEnd: canSwipe ? _onDragEnd : null,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          child: Transform.translate(
            key: _imageKey,
            offset: Offset(_dragOffset, 0),
            child: Opacity(
              opacity: (1.0 - (_dragOffset.abs() / _maxDragOffset) * 0.3)
                  .clamp(0.5, 1.0),
              child: _buildAlbumArt(imageSize, imageHeight, borderRadius),
            ),
          ),
        ),
      ),
    );
  }

  // =================== SWIPE GESTURE HANDLING ===================

  void _onDragStart(DragStartDetails details) {
    _swipeTriggered = false;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_swipeTriggered) return;

    double newOffset = _dragOffset + details.delta.dx;

    // Constrain drag: only allow directions that have sessions
    if (newOffset > 0 && !widget.hasPrevious) {
      newOffset = newOffset * 0.2; // Rubber band effect
    }
    if (newOffset < 0 && !widget.hasNext) {
      newOffset = newOffset * 0.2; // Rubber band effect
    }

    setState(() {
      _dragOffset = newOffset.clamp(-_maxDragOffset, _maxDragOffset);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (_swipeTriggered) return;

    final velocity = details.primaryVelocity ?? 0;
    final absOffset = _dragOffset.abs();

    bool shouldNavigate = false;
    bool goNext = false;

    // Check velocity-based flick
    if (velocity.abs() > _velocityThreshold) {
      if (velocity < 0 && widget.hasNext) {
        shouldNavigate = true;
        goNext = true;
      } else if (velocity > 0 && widget.hasPrevious) {
        shouldNavigate = true;
        goNext = false;
      }
    }
    // Check distance-based swipe
    else if (absOffset > _swipeThreshold) {
      if (_dragOffset < 0 && widget.hasNext) {
        shouldNavigate = true;
        goNext = true;
      } else if (_dragOffset > 0 && widget.hasPrevious) {
        shouldNavigate = true;
        goNext = false;
      }
    }

    if (shouldNavigate) {
      _swipeTriggered = true;

      if (goNext) {
        widget.onSwipeNext?.call();
      } else {
        widget.onSwipePrevious?.call();
      }
    }

    // Animate drag offset back to zero
    setState(() {
      _dragOffset = 0.0;
    });
  }

  // =================== ALBUM ART CONTENT ===================

  Widget _buildAlbumArt(
    double imageSize,
    double imageHeight,
    double borderRadius,
  ) {
    return Container(
      width: imageSize,
      height: imageHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          children: [
            // Background Image
            _buildImage(widget.imageUrl, widget.localImagePath),

            // Dark Overlay
            _buildDarkOverlay(),

            // Equalizer
            Center(
              child: widget.isPlaying
                  ? AnimatedBuilder(
                      animation: _continuousController,
                      builder: (context, _) => _buildAnimatedEqualizer(),
                    )
                  : _buildStaticEqualizer(),
            ),
          ],
        ),
      ),
    );
  }

  // =================== IMAGE BUILDERS ===================

  Widget _buildImage(String? imageUrl, String? localPath) {
    if (localPath != null && localPath.isNotEmpty) {
      final file = File(localPath);
      return Positioned.fill(
        child: FutureBuilder<bool>(
          future: file.exists(),
          builder: (context, snapshot) {
            if (snapshot.data == true) {
              return Image.file(
                file,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildPlaceholder(),
              );
            }
            return _buildNetworkOrPlaceholder(imageUrl);
          },
        ),
      );
    }

    return _buildNetworkOrPlaceholder(imageUrl);
  }

  Widget _buildNetworkOrPlaceholder(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return _buildPlaceholder();
    }

    return Positioned.fill(
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        cacheManager: AppCacheManager.instance,
        fit: BoxFit.cover,
        placeholder: (context, url) => _buildPlaceholder(),
        errorWidget: (context, url, error) => _buildPlaceholder(),
      ),
    );
  }

  // =================== SIZING ===================

  double _calculateImageSize(Size screenSize) {
    final width = screenSize.width;
    final height = screenSize.height;

    if (width >= 600) {
      return width * 0.5;
    }

    if (height <= 700) {
      return width * 0.70;
    }

    return width * 0.75;
  }

  // =================== DECORATIONS ===================

  Widget _buildPlaceholder() {
    final colors = context.colors;
    return Shimmer.fromColors(
      baseColor: colors.greyMedium,
      highlightColor: colors.greyLight,
      child: Container(
        color: colors.backgroundPure,
      ),
    );
  }

  Widget _buildDarkOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 0.8,
            colors: [
              Colors.black.withValues(alpha: 0.3),
              Colors.black.withValues(alpha: 0.6),
            ],
          ),
        ),
      ),
    );
  }

  // =================== EQUALIZER ===================

  Widget _buildStaticEqualizer() {
    return SizedBox(
      width: 80.w,
      height: 80.w,
      child: CustomPaint(
        painter: _EqualizerPainter([30, 45, 60, 45, 30]),
      ),
    );
  }

  Widget _buildAnimatedEqualizer() {
    final t = _continuousController.value * 5000;

    final bars = List.generate(5, (i) {
      final speed = 2.5 + i * 0.5;
      final phase = t * speed + i * 1.2;

      final height1 = (1 + math.sin(phase)) / 2;
      final height2 = (1 + math.sin(phase * 1.7 + 1.5)) / 2;

      final combined = (height1 + height2) / 2;

      return 20 + 40 * combined;
    });

    return SizedBox(
      width: 80.w,
      height: 80.w,
      child: CustomPaint(
        painter: _EqualizerPainter(bars),
      ),
    );
  }
}

// =================== PAINTERS ===================

class _EqualizerPainter extends CustomPainter {
  final List<double> barHeights;

  _EqualizerPainter(this.barHeights);

  @override
  void paint(Canvas canvas, Size size) {
    const barWidth = 4.0;
    const spacing = 7.0;
    final centerY = size.height / 2;

    final totalWidth =
        (barHeights.length * barWidth) + ((barHeights.length - 1) * spacing);
    var startX = (size.width - totalWidth) / 2;

    for (int i = 0; i < barHeights.length; i++) {
      final barHeight = barHeights[i];
      final y1 = centerY - barHeight / 2;

      final gradientPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.6),
            Colors.grey.shade400.withValues(alpha: 0.4),
          ],
        ).createShader(Rect.fromLTWH(startX, y1, barWidth, barHeight))
        ..style = PaintingStyle.fill;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(startX, y1, barWidth, barHeight),
        const Radius.circular(2.0),
      );

      canvas.drawRRect(rect, gradientPaint);

      startX += barWidth + spacing;
    }
  }

  @override
  bool shouldRepaint(_EqualizerPainter oldDelegate) => true;
}
