import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/constants/app_colors.dart';
import '../../core/responsive/responsive_scaffold.dart';
import '../../core/responsive/context_ext.dart';
import '../../features/library/categories_screen.dart';
import '../../features/playlist/playlist_screen.dart';
import '../../shared/widgets/menu_overlay.dart';
import '../../core/routes/app_routes.dart';
import '../../services/notifications/notification_service.dart';
import '../../services/home_card_service.dart';
import 'widgets/home_card_button.dart';
import '../../l10n/app_localizations.dart';
import '../search/search_screen.dart';
import '../search/widgets/search_bar_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // Menu state
  bool _isMenuOpen = false;
  void _toggleMenu() => setState(() => _isMenuOpen = !_isMenuOpen);

  List<Map<String, dynamic>> _homeCards = [];
  bool _isLoadingCards = true;

  @override
  void initState() {
    super.initState();
    _loadHomeCards();
    _startSmartPrefetch();

    // Check notification permission after screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.checkAndShowPermissionDialog(context);
    });
  }

  Future<void> _loadHomeCards() async {
    try {
      final cards = await HomeCardService.fetchHomeCards();

      if (mounted) {
        setState(() {
          _homeCards = cards;
          _isLoadingCards = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading home cards: $e');
      if (mounted) {
        setState(() => _isLoadingCards = false);
      }
    }
  }

  void _startSmartPrefetch() {
    Future.microtask(() {
      HomeCardService.smartPrefetch();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = context.isTablet;
    final isDesktop = context.isDesktop;
    final screenHeight = context.h;

    // 🎯 IMPROVED: Dynamic header height based on device type and screen height
    final double headerH;
    if (isDesktop) {
      headerH = 180.0;
    } else if (isTablet) {
      headerH = (screenHeight * 0.18).clamp(160.0, 200.0);
    } else {
      // Smart phone height calculation
      if (screenHeight <= 667) {
        headerH = 100.0; // iPhone SE, 8
      } else if (screenHeight <= 736) {
        headerH = 110.0; // iPhone 8 Plus
      } else if (screenHeight <= 812) {
        headerH = 120.0; // iPhone X, 11 Pro
      } else if (screenHeight <= 896) {
        headerH = 130.0; // iPhone 11, XR
      } else {
        headerH = 140.0; // iPhone 14 Pro Max+
      }
    }

    return PopScope(
      canPop: true,
      child: ResponsiveScaffold(
        appBar: null,
        body: Stack(
          children: [
            // background
            Positioned.fill(child: _buildBackground()),
            // content
            ..._buildHomeCards(headerH),
            _buildHeader(height: headerH),
            // overlay
            if (_isMenuOpen)
              Positioned.fill(
                child: MenuOverlay(onClose: _toggleMenu),
              ),
          ],
        ),
        bottomNav: _buildBottomNavContent(),
      ),
    );
  }

  List<Widget> _buildHomeCards(double headerH) {
    if (_isLoadingCards) {
      return [
        Positioned(
          top: headerH + 16.h,
          left: 0,
          right: 0,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ];
    }

    if (_homeCards.isEmpty) {
      return [];
    }

    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive column count
    int crossAxisCount;
    if (screenWidth > 1200) {
      crossAxisCount = 4; // Large tablets / Desktop
    } else if (screenWidth > 800) {
      crossAxisCount = 3; // Medium tablets
    } else if (screenWidth > 600) {
      crossAxisCount = 3; // Small tablets
    } else {
      crossAxisCount = 2; // Phones
    }

    // Calculate card dimensions
    final totalPadding = 24.w * 2; // Left + Right padding
    final totalGaps = 12.w * (crossAxisCount - 1); // Gaps between cards
    final availableWidth = screenWidth - totalPadding - totalGaps;
    final cardWidth = availableWidth / crossAxisCount;
    final cardHeight = cardWidth * 1.0; // Aspect ratio

    // 🎯 IMPROVED: Calculate safe bottom space to prevent overflow
    final bottomNavHeight = context.isTablet ? 64.0 : 60.0;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final totalBottomSpace = bottomNavHeight + safeBottom + 16.h;

    return [
      Positioned(
        top: headerH + 16.h,
        left: 24.w,
        right: 24.w,
        bottom: totalBottomSpace, // 🎯 FIXED: Add bottom constraint
        child: SingleChildScrollView(
          // 🎯 FIXED: Add scroll wrapper for overflow protection
          physics: const BouncingScrollPhysics(),
          child: GridView.builder(
            shrinkWrap: true, // 🎯 FIXED: Let GridView size itself
            physics:
                const NeverScrollableScrollPhysics(), // Parent handles scroll
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12.w,
              mainAxisSpacing: 12.h,
              childAspectRatio: cardWidth / cardHeight,
            ),
            itemCount: _homeCards.length,
            itemBuilder: (context, index) {
              final card = _homeCards[index];
              final title = HomeCardService.getLocalizedTitleFromKey(
                context,
                card['cardType'],
              );

              return HomeCardButton(
                imageUrl: card['randomImage'],
                title: title,
                icon: _getIconData(card['icon']),
                onTap: () => _navigateToCard(card['navigateTo']),
                height: cardHeight,
              );
            },
          ),
        ),
      ),
    ];
  }

  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'home_outlined':
        return Icons.home_outlined;
      case 'playlist_play':
        return Icons.playlist_play;
      case 'music_note':
        return Icons.music_note;
      default:
        return Icons.music_note;
    }
  }

  void _navigateToCard(String? navigateTo) {
    if (navigateTo == null) return;

    switch (navigateTo) {
      case 'categories':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CategoriesScreen()),
        );
        break;
      case 'playlist':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PlaylistScreen()),
        );
        break;
    }
  }

  // ---------- UI parts ----------
  Widget _buildHeader({required double height}) {
    // 🎯 IMPROVED: Add safe area for notch/status bar
    final topSafeArea = MediaQuery.of(context).padding.top;

    return Positioned(
      top: topSafeArea, // 🎯 FIXED: Respect notch area
      left: 0,
      right: 0,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 20.w, // ← Basitleştir
          vertical: 8.h,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Logo with safe sizing
                SvgPicture.asset(
                  'assets/images/logo.svg',
                  height: 26.h, // 🎯 IMPROVED: Clamped size
                  fit: BoxFit.contain,
                  colorFilter:
                      ColorFilter.mode(AppColors.textPrimary, BlendMode.srcIn),
                ),
                const Spacer(),
                _buildHeaderButton(AppLocalizations.of(context).menu, true),
              ],
            ),
            SizedBox(height: context.isTablet ? 14.h : 12.h),
            SearchBarWidget(
              onTap: () {
                Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) {
                      return const SearchScreen();
                    },
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                      const begin = Offset(0.0, 1.0);
                      const end = Offset.zero;
                      const curve = Curves.easeInOut;

                      var tween = Tween(begin: begin, end: end).chain(
                        CurveTween(curve: curve),
                      );

                      return SlideTransition(
                        position: animation.drive(tween),
                        child: child,
                      );
                    },
                    transitionDuration: const Duration(milliseconds: 400),
                  ),
                );
              },
            ),
            SizedBox(height: 8.h),
          ],
        ),
      ),
    );
  }

  // Background
  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF9F9F9), Color(0xFFEFEFEF)],
        ),
      ),
    );
  }

  // Header menu button
  Widget _buildHeaderButton(String text, bool isFilled) {
    return InkWell(
      onTap: _toggleMenu,
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: (12.w).clamp(10.0, 16.0), // 🎯 IMPROVED: Clamped padding
          vertical: (8.h).clamp(6.0, 10.0),
        ),
        decoration: BoxDecoration(
          color: isFilled ? Colors.black : Colors.transparent,
          borderRadius: BorderRadius.circular(20.r),
          border: isFilled ? null : Border.all(color: Colors.black, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: GoogleFonts.inter(
                fontSize:
                    (12.sp).clamp(11.0, 14.0), // 🎯 IMPROVED: Clamped font size
                fontWeight: FontWeight.w600,
                color: isFilled ? Colors.white : Colors.black,
              ),
            ),
            SizedBox(width: 6.w),
            Icon(
              Icons.menu,
              size: (14.sp).clamp(12.0, 16.0), // 🎯 IMPROVED: Clamped icon size
              color: isFilled ? Colors.white : Colors.black,
            ),
          ],
        ),
      ),
    );
  }

  // Bottom nav content (only content; height/shape is in ResponsiveScaffold)
  Widget _buildBottomNavContent() {
    int current = 0; // TODO: wire with state if needed

    Widget item(IconData icon, String label, int idx, VoidCallback onTap) {
      final selected = current == idx;
      return InkWell(
        onTap: onTap,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: context.isTablet ? 24 : 22,
                  color: selected ? AppColors.textPrimary : Colors.grey[500]),
              const SizedBox(height: 4),
              SizedBox(
                width: context.isTablet ? 76 : 64,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: context.isTablet ? 11 : 10,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected ? AppColors.textPrimary : Colors.grey[500],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final l10n = AppLocalizations.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        item(Icons.home_outlined, l10n.home, 0, () {}),
        item(Icons.play_circle_outline, l10n.playlist, 1, () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const PlaylistScreen()));
        }),
        item(Icons.person_outline, l10n.profile, 2, () {
          AppRoutes.navigateToProfile(context);
        }),
      ],
    );
  }
}
