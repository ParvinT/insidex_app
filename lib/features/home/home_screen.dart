import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'widgets/home_card_button.dart';
import 'widgets/greeting_section.dart';
import '../../core/themes/app_theme_extension.dart';
import '../../core/responsive/responsive_scaffold.dart';
import '../../core/responsive/context_ext.dart';
import '../../features/library/categories_screen.dart';
import '../../features/playlist/playlist_screen.dart';
import '../../shared/widgets/menu_overlay.dart';
import '../../core/routes/app_routes.dart';
import '../../services/notifications/notification_service.dart';
import '../../services/home_card_service.dart';
import '../quiz/widgets/expandable_quiz_section.dart';
import '../../l10n/app_localizations.dart';
import '../search/search_screen.dart';
import '../../providers/download_provider.dart';
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
    _initializeDownloadProvider();
    _loadHomeCards();
    _startSmartPrefetch();

    // Check notification permission after screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.checkAndShowPermissionDialog(context);
    });
  }

  void _initializeDownloadProvider() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<DownloadProvider>().initialize(user.uid);
        debugPrint(
            '✅ DownloadProvider initialized for user: ${user.uid.substring(0, 8)}...');
      });
    }
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
  Widget build(BuildContext context) {
    final colors = context.colors;
    return PopScope(
      canPop: true,
      child: ResponsiveScaffold(
        appBar: null,
        body: Stack(
          children: [
            // Background + Main Content
            Container(
              color: colors.background,
              child: Column(
                children: [
                  // Header (Logo + Search + Quiz)
                  _buildHeader(),

                  // Scrollable Cards
                  Expanded(
                    child: _buildScrollableContent(),
                  ),
                ],
              ),
            ),

            // Menu overlay
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

  Widget _buildScrollableContent() {
    if (_isLoadingCards) {
      return Center(
        child: CircularProgressIndicator(
          color: context.colors.textPrimary,
        ),
      );
    }

    if (_homeCards.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context).noCardsAvailable,
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            color: context.colors.textSecondary,
          ),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;

    int crossAxisCount;
    if (screenWidth > 1200) {
      crossAxisCount = 4;
    } else if (screenWidth > 800) {
      crossAxisCount = 3;
    } else if (screenWidth > 600) {
      crossAxisCount = 3;
    } else {
      crossAxisCount = 2;
    }

    final horizontalPadding = 24.w;
    final totalPadding = horizontalPadding * 2;
    final totalGaps = 12.w * (crossAxisCount - 1);
    final availableWidth = screenWidth - totalPadding - totalGaps;
    final cardWidth = availableWidth / crossAxisCount;
    final cardHeight = cardWidth * 1.0;

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: horizontalPadding,
        right: horizontalPadding,
        top: 16.h,
        bottom: 16.h,
      ),
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          const GreetingSection(),
          const ExpandableQuizSection(),
          SizedBox(height: 20.h),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
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
        ],
      ),
    );
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
  Widget _buildHeader() {
    final isTablet = context.isTablet;
    final isDesktop = context.isDesktop;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 24.w : 20.w,
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SizedBox(height: isTablet ? 20.h : 16.h),

            // Logo + Menu button row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Logo
                SvgPicture.asset(
                  'assets/images/logo.svg',
                  height: isDesktop ? 32.h : (isTablet ? 28.h : 26.h),
                  fit: BoxFit.contain,
                  colorFilter: ColorFilter.mode(
                    context.colors.textPrimary,
                    BlendMode.srcIn,
                  ),
                ),

                // Menu button
                _buildHeaderButton(AppLocalizations.of(context).menu, true),
              ],
            ),

            SizedBox(height: isTablet ? 14.h : 12.h),

            // Search bar
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
          ],
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
          color: isFilled
              ? (context.isDarkMode
                  ? context.colors.textPrimary.withValues(alpha: 0.85)
                  : context.colors.textPrimary)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20.r),
          border: isFilled
              ? null
              : Border.all(color: context.colors.textPrimary, width: 1),
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
                color: isFilled
                    ? context.colors.textOnPrimary
                    : context.colors.textPrimary,
              ),
            ),
            SizedBox(width: 6.w),
            Icon(
              Icons.menu,
              size: (14.sp).clamp(12.0, 16.0), // 🎯 IMPROVED: Clamped icon size
              color: isFilled
                  ? context.colors.textOnPrimary
                  : context.colors.textPrimary,
            ),
          ],
        ),
      ),
    );
  }

  // Bottom nav content (only content; height/shape is in ResponsiveScaffold)
  Widget _buildBottomNavContent() {
    final colors = context.colors;
    int current = 0;

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
                  color: selected ? colors.textPrimary : colors.textSecondary),
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
                    color: selected ? colors.textPrimary : colors.textSecondary,
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
