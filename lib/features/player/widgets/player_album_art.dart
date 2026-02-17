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

  // Next/Previous session images for peek effect
  final String? nextImageUrl;
  final String? nextLocalImagePath;
  final String? previousImageUrl;
  final String? previousLocalImagePath;

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
    this.nextImageUrl,
    this.nextLocalImagePath,
    this.previousImageUrl,
    this.previousLocalImagePath,
  });

  @override
  State<PlayerAlbumArt> createState() => _PlayerAlbumArtState();
}

class _PlayerAlbumArtState extends State<PlayerAlbumArt>
    with SingleTickerProviderStateMixin {
  late AnimationController _continuousController;
  late PageController _pageController;

  bool _isSwiping = false;
  bool _isTransitionLocked = false;

  // Current page starts at the "current" session index
  int get _currentPageIndex => widget.hasPrevious ? 1 : 0;

  @override
  void initState() {
    super.initState();
    _continuousController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _pageController = PageController(initialPage: _currentPageIndex);
  }

  @override
  void didUpdateWidget(covariant PlayerAlbumArt oldWidget) {
    super.didUpdateWidget(oldWidget);

    // When session changes (after swipe completes), reset PageController
    final oldId = oldWidget.imageUrl ?? oldWidget.localImagePath;
    final newId = widget.imageUrl ?? widget.localImagePath;

    if (oldId != newId && !_isSwiping) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pageController.hasClients) {
          _pageController.jumpToPage(_currentPageIndex);
        }
      });
    }
  }

  @override
  void dispose() {
    _continuousController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double imageSize = _calculateImageSize(size);
    final double imageHeight = imageSize * 9 / 16;
    final double borderRadius = imageSize * 0.08;

    return SizedBox(
      width: imageSize,
      height: imageHeight,
      child: PageView.builder(
        controller: _pageController,
        itemCount: _totalPages,
        physics: _totalPages > 1 && !_isTransitionLocked
            ? const BouncingScrollPhysics()
            : const NeverScrollableScrollPhysics(),
        onPageChanged: _onPageChanged,
        itemBuilder: (context, index) {
          final pageType = _getPageType(index);
          return _buildPage(pageType, imageSize, imageHeight, borderRadius);
        },
      ),
    );
  }

  // =================== PAGE MANAGEMENT ===================

  int get _totalPages {
    int count = 1; // current
    if (widget.hasPrevious) count++;
    if (widget.hasNext) count++;
    return count;
  }

  _PageType _getPageType(int index) {
    if (widget.hasPrevious) {
      if (index == 0) return _PageType.previous;
      if (index == 1) return _PageType.current;
      return _PageType.next;
    } else {
      if (index == 0) return _PageType.current;
      return _PageType.next;
    }
  }

  void _onPageChanged(int index) {
    final pageType = _getPageType(index);

    if (pageType == _PageType.previous && !_isTransitionLocked) {
      _isSwiping = true;
      _isTransitionLocked = true;
      widget.onSwipePrevious?.call();
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          setState(() {
            _isSwiping = false;
            _isTransitionLocked = false;
          });
        }
      });
    } else if (pageType == _PageType.next && !_isTransitionLocked) {
      _isSwiping = true;
      _isTransitionLocked = true;
      widget.onSwipeNext?.call();
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          setState(() {
            _isSwiping = false;
            _isTransitionLocked = false;
          });
        }
      });
    }
  }

  // =================== PAGE CONTENT ===================

  Widget _buildPage(
    _PageType type,
    double imageSize,
    double imageHeight,
    double borderRadius,
  ) {
    String? imageUrl;
    String? localPath;

    switch (type) {
      case _PageType.previous:
        imageUrl = widget.previousImageUrl;
        localPath = widget.previousLocalImagePath;
        break;
      case _PageType.current:
        imageUrl = widget.imageUrl;
        localPath = widget.localImagePath;
        break;
      case _PageType.next:
        imageUrl = widget.nextImageUrl;
        localPath = widget.nextLocalImagePath;
        break;
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Container(
        width: imageSize,
        height: imageHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: type == _PageType.current
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Stack(
            children: [
              // Background Image
              _buildImage(imageUrl, localPath),

              // Dark Overlay
              _buildDarkOverlay(),

              // Equalizer (only on current page)
              if (type == _PageType.current)
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

// =================== ENUMS & PAINTERS ===================

enum _PageType { previous, current, next }

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
