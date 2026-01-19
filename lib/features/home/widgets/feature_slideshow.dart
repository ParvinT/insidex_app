// lib/features/home/widgets/feature_slideshow.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/themes/app_theme_extension.dart';
import '../../../core/responsive/context_ext.dart';
import '../../../models/feature_slide_model.dart';
import '../../../services/feature_slides_service.dart';
import '../../../services/cache_manager_service.dart';

/// Feature slideshow with auto-scroll and animated text
class FeatureSlideshow extends StatefulWidget {
  const FeatureSlideshow({super.key});

  @override
  State<FeatureSlideshow> createState() => _FeatureSlideshowState();
}

class _FeatureSlideshowState extends State<FeatureSlideshow>
    with TickerProviderStateMixin {
  final FeatureSlidesService _service = FeatureSlidesService();
  final PageController _pageController = PageController();

  // Data
  List<FeatureSlidePageModel> _pages = [];
  List<String> _randomImages = [];
  bool _isLoading = true;

  // Auto-scroll
  Timer? _autoScrollTimer;
  int _currentPage = 0;
  static const Duration _autoScrollDuration = Duration(seconds: 8);
  static const Duration _animationDuration = Duration(milliseconds: 500);

  // Text animation
  late AnimationController _textAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Progress indicator
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadData();
  }

  void _initAnimations() {
    // Text animation controller
    _textAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textAnimationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _textAnimationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    // Progress indicator controller
    _progressController = AnimationController(
      vsync: this,
      duration: _autoScrollDuration,
    );
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    _textAnimationController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final data = await _service.getData();

      if (data == null || data.activePages.isEmpty) {
        debugPrint('⚠️ [FeatureSlideshow] No data available');
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final pages = data.activePages;
      final randomImages = await _service.getRandomizedImagesForPages(
        pageCount: pages.length,
      );
      await Future.wait(
        randomImages.map((url) => AppCacheManager.precacheImage(url)),
      );
      debugPrint('✅ [FeatureSlideshow] All images precached');

      if (mounted) {
        setState(() {
          _pages = pages;
          _randomImages = randomImages;
          _isLoading = false;
        });

        // Start animations
        _textAnimationController.forward();
        _startAutoScroll();
        _startProgress();
      }
    } catch (e) {
      debugPrint('❌ [FeatureSlideshow] Error loading data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(_autoScrollDuration, (_) {
      if (!mounted || _pages.isEmpty) return;

      final nextPage = (_currentPage + 1) % _pages.length;

      _pageController.animateToPage(
        nextPage,
        duration: _animationDuration,
        curve: Curves.easeInOut,
      );
    });
  }

  void _startProgress() {
    _progressController.forward(from: 0.0);
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);

    // Restart animations
    _textAnimationController.forward(from: 0.0);
    _progressController.forward(from: 0.0);

    // Reset timer on manual swipe
    _startAutoScroll();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = context.isTablet;
    final isDesktop = context.isDesktop;

    // Don't show if no data
    if (_isLoading) {
      return _buildLoadingState(isTablet);
    }

    if (_pages.isEmpty || _randomImages.isEmpty) {
      return const SizedBox.shrink();
    }

    // Responsive height
    final double height = isDesktop ? 280.h : (isTablet ? 240.h : 200.h);

    return Container(
      height: height,
      margin: EdgeInsets.only(bottom: isTablet ? 20.h : 16.h),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isTablet ? 20.r : 16.r),
        child: Stack(
          children: [
            // PageView
            PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: _pages.length,
              itemBuilder: (context, index) {
                return _buildSlide(
                  page: _pages[index],
                  imageUrl: _randomImages[index],
                  isTablet: isTablet,
                );
              },
            ),

            // Progress indicators
            Positioned(
              bottom: isTablet ? 16.h : 12.h,
              left: isTablet ? 24.w : 20.w,
              right: isTablet ? 24.w : 20.w,
              child: _buildProgressIndicators(isTablet),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(bool isTablet) {
    final colors = context.colors;
    final double height = isTablet ? 240.h : 200.h;

    return Container(
      height: height,
      margin: EdgeInsets.only(bottom: isTablet ? 20.h : 16.h),
      decoration: BoxDecoration(
        color: colors.backgroundCard,
        borderRadius: BorderRadius.circular(isTablet ? 20.r : 16.r),
        border: Border.all(
          color: colors.border.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Center(
        child: CircularProgressIndicator(
          color: colors.textSecondary,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildSlide({
    required FeatureSlidePageModel page,
    required String imageUrl,
    required bool isTablet,
  }) {
    final colors = context.colors;
    final locale = Localizations.localeOf(context).languageCode;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Background image
        CachedNetworkImage(
          imageUrl: imageUrl,
          cacheManager: AppCacheManager.instance,
          fit: BoxFit.cover,
          memCacheWidth: 1920,
          memCacheHeight: 1080,
          fadeInDuration: const Duration(milliseconds: 200),
          fadeOutDuration: const Duration(milliseconds: 100),
          placeholder: (context, url) => Container(
            color: colors.backgroundCard,
          ),
          errorWidget: (context, url, error) => Container(
            color: colors.backgroundCard,
            child: Icon(
              Icons.image_not_supported_outlined,
              color: colors.textSecondary,
              size: 48.sp,
            ),
          ),
        ),

        // Gradient overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.3),
                Colors.black.withValues(alpha: 0.7),
                Colors.black.withValues(alpha: 0.85),
              ],
              stops: const [0.0, 0.4, 0.7, 1.0],
            ),
          ),
        ),

        // Text content with animation
        Positioned(
          left: isTablet ? 24.w : 20.w,
          right: isTablet ? 24.w : 20.w,
          bottom: isTablet ? 48.h : 40.h,
          child: SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    page.getTitle(locale),
                    style: GoogleFonts.inter(
                      fontSize: (isTablet ? 24.sp : 20.sp).clamp(18.0, 28.0),
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.2,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.6),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: isTablet ? 10.h : 8.h),

                  // Subtitle
                  Text(
                    page.getSubtitle(locale),
                    style: GoogleFonts.inter(
                      fontSize: (isTablet ? 15.sp : 13.sp).clamp(12.0, 16.0),
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.4,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 8,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressIndicators(bool isTablet) {
    return Row(
      children: List.generate(_pages.length, (index) {
        final isActive = index == _currentPage;
        final isPast = index < _currentPage;

        return Expanded(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 2.w),
            height: isTablet ? 4.h : 3.h,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2.r),
              child: Stack(
                children: [
                  // Background
                  Container(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),

                  // Progress fill
                  if (isPast)
                    Container(
                      color: Colors.white,
                    )
                  else if (isActive)
                    AnimatedBuilder(
                      animation: _progressController,
                      builder: (context, child) {
                        return FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: _progressController.value,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(2.r),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
