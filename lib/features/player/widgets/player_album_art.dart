// lib/features/player/widgets/player_album_art.dart
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../../services/cache_manager_service.dart';

/// YouTube Music style album art with integrated equalizer
/// Responsive design that adapts to screen size
class PlayerAlbumArt extends StatefulWidget {
  final String? imageUrl;
  final String? localImagePath;
  final AnimationController equalizerController;
  final bool isPlaying;

  const PlayerAlbumArt({
    super.key,
    required this.imageUrl,
    this.localImagePath,
    required this.equalizerController,
    required this.isPlaying,
  });

  @override
  State<PlayerAlbumArt> createState() => _PlayerAlbumArtState();
}

class _PlayerAlbumArtState extends State<PlayerAlbumArt>
    with SingleTickerProviderStateMixin {
  late AnimationController _continuousController;

  @override
  void initState() {
    super.initState();
    // ✅ Dedicated controller for seamless infinite animation
    _continuousController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10), // 1 hour (very long)
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

    // Responsive size calculation
    final double imageSize = _calculateImageSize(size);
    final double borderRadius = imageSize * 0.08; // 8% of image size

    return Container(
      width: imageSize,
      height: imageSize,
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
            // 1. Background Image
            _buildBackgroundImage(),

            // 2. Dark Overlay (for equalizer visibility)
            _buildDarkOverlay(),

            // 3. Equalizer (centered)
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

  /// Calculate responsive image size
  double _calculateImageSize(Size screenSize) {
    final width = screenSize.width;
    final height = screenSize.height;

    // Tablet/Desktop
    if (width >= 600) {
      return width * 0.5; // 50% of screen width
    }

    // Small phones
    if (height <= 700) {
      return width * 0.70; // 70% of screen width
    }

    // Normal phones
    return width * 0.75; // 75% of screen width
  }

  /// Background image with cache
  Widget _buildBackgroundImage() {
    if (widget.localImagePath != null && widget.localImagePath!.isNotEmpty) {
      final file = File(widget.localImagePath!);
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
            // Local file yoksa network'e fallback
            return _buildNetworkImage();
          },
        ),
      );
    }

    return _buildNetworkImage();
  }

  Widget _buildNetworkImage() {
    if (widget.imageUrl == null || widget.imageUrl!.isEmpty) {
      return _buildPlaceholder();
    }

    return Positioned.fill(
      child: CachedNetworkImage(
        imageUrl: widget.imageUrl!,
        cacheManager: AppCacheManager.instance,
        fit: BoxFit.cover,
        placeholder: (context, url) => _buildPlaceholder(),
        errorWidget: (context, url, error) => _buildPlaceholder(),
      ),
    );
  }

  /// Placeholder for loading/error states
  Widget _buildPlaceholder() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        color: Colors.white,
      ),
    );
  }

  /// Dark overlay for equalizer contrast
  Widget _buildDarkOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 0.8,
            colors: [
              Colors.black.withValues(alpha: 0.3), // Center lighter
              Colors.black.withValues(alpha: 0.6), // Edges darker
            ],
          ),
        ),
      ),
    );
  }

  /// Static equalizer (when paused)
  Widget _buildStaticEqualizer() {
    return SizedBox(
      width: 80.w,
      height: 80.w,
      child: CustomPaint(
        painter: _EqualizerPainter([30, 45, 60, 45, 30]),
      ),
    );
  }

  /// Animated equalizer (when playing)
  Widget _buildAnimatedEqualizer() {
    // ✅ Use dedicated continuous controller
    final t =
        _continuousController.value * 5000; // Scale up for visible movement

    final bars = List.generate(5, (i) {
      // Each bar has different speed
      final speed = 2.5 + i * 0.5;
      final phase = t * speed + i * 1.2;

      // Combine two sine waves
      final height1 = (1 + math.sin(phase)) / 2;
      final height2 = (1 + math.sin(phase * 1.7 + 1.5)) / 2;

      // Mix them together
      final combined = (height1 + height2) / 2;

      // Calculate bar height (20..60 range)
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

/// Custom painter for equalizer bars
class _EqualizerPainter extends CustomPainter {
  final List<double> barHeights;

  _EqualizerPainter(this.barHeights);

  @override
  void paint(Canvas canvas, Size size) {
    final barWidth = 4.0;
    final spacing = 7.0;
    final centerY = size.height / 2;

    final totalWidth =
        (barHeights.length * barWidth) + ((barHeights.length - 1) * spacing);
    var startX = (size.width - totalWidth) / 2;

    for (int i = 0; i < barHeights.length; i++) {
      final barHeight = barHeights[i];
      final y1 = centerY - barHeight / 2;

      // Gradient paint
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

      // Yuvarlatılmış köşeler
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

// Another good version for equalizer.
/*class _EqualizerPainter extends CustomPainter {
  final List<double> barHeights;

  _EqualizerPainter(this.barHeights);

  @override
  void paint(Canvas canvas, Size size) {
    final barWidth = 3.5;
    final spacing = 8.0;
    final centerY = size.height / 2;
    
    final totalWidth = (barHeights.length * barWidth) + 
                       ((barHeights.length - 1) * spacing);
    var startX = (size.width - totalWidth) / 2;

    for (int i = 0; i < barHeights.length; i++) {
      final barHeight = barHeights[i];
      final y1 = centerY - barHeight / 2;

      // 1. Outer glow (çok hafif)
      final glowPaint = Paint()
        ..color = Colors.white.withValues(alpha:0.1)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      final glowRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(startX - 1, y1 - 1, barWidth + 2, barHeight + 2),
        const Radius.circular(2.0),
      );
      canvas.drawRRect(glowRect, glowPaint);

      // 2. Main bar with frosted glass effect
      final glassPaint = Paint()
        ..color = Colors.white.withValues(alpha:0.25)
        ..style = PaintingStyle.fill;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(startX, y1, barWidth, barHeight),
        const Radius.circular(2.0),
      );
      canvas.drawRRect(rect, glassPaint);

      // 3. Inner highlight (cam parlama efekti)
      final highlightPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.white.withValues(alpha:0.4),
            Colors.white.withValues(alpha:0.0),
          ],
        ).createShader(Rect.fromLTWH(startX, y1, barWidth * 0.5, barHeight))
        ..style = PaintingStyle.fill;

      final highlightRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(startX, y1, barWidth * 0.4, barHeight),
        const Radius.circular(2.0),
      );
      canvas.drawRRect(highlightRect, highlightPaint);

      startX += barWidth + spacing;
    }
  }

  @override
  bool shouldRepaint(_EqualizerPainter oldDelegate) => true;
}*/
