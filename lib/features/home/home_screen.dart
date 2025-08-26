import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../features/library/categories_screen.dart';
import '../../shared/widgets/menu_overlay.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _isMenuOpen = false;

  // thresholds
  static const double _dragThreshold = 60.0;

  // All Subliminals (drag down)
  double _dragOffset = 0.0;
  bool _isDragging = false;
  bool _readyToNavigate = false;

  // Your Playlist (drag down — aynı davranış)
  double _playlistDragOffset = 0.0;
  bool _isPlaylistDragging = false;
  bool _playlistReadyToNavigate = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _playlistPulseController;
  late Animation<double> _playlistPulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
        duration: const Duration(milliseconds: 1500), vsync: this)
      ..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _playlistPulseController = AnimationController(
        duration: const Duration(milliseconds: 1500), vsync: this)
      ..repeat(reverse: true);
    _playlistPulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
          parent: _playlistPulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _playlistPulseController.dispose();
    super.dispose();
  }

  void _toggleMenu() => setState(() => _isMenuOpen = !_isMenuOpen);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Stack(
        children: [
          SafeArea(
            child: Stack(
              children: [
                Positioned.fill(child: _buildBackground()),

                // Z-order sabit
                _buildPlaylistCard(),
                _buildAllSubliminalsCard(),
                _buildHeader(),
              ],
            ),
          ),
          if (_isMenuOpen)
            MenuOverlay(onClose: () => setState(() => _isMenuOpen = false)),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ---------- parts ----------

  Widget _buildBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.grey[200]!, Colors.grey[300]!],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: 240.h,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 25,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildHeaderButton('Category', false),
                  _buildHeaderButton('Menu', true),
                ],
              ),
              Text(
                'Welcome to Insidex',
                style: GoogleFonts.inter(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                height: 48.h,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(15.r),
                  border: Border.all(color: Colors.grey[300]!, width: 1),
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Icon(Icons.search,
                          color: Colors.grey[400], size: 22.sp),
                    ),
                    const Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Your Playlist (All Subliminals ile aynı his) ----------
  Widget _buildPlaylistCard() {
    final progress = (_playlistDragOffset / _dragThreshold).clamp(0.0, 1.0);

    return Positioned(
      top: 160.h + (_playlistDragOffset.clamp(0, _dragThreshold) * 0.3),
      left: 0,
      right: 0,
      height: 200.h,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragStart: (_) => setState(() => _isPlaylistDragging = true),
        onVerticalDragUpdate: (details) {
          setState(() {
            // geri sarma: 0..threshold aralığı
            _playlistDragOffset = (_playlistDragOffset + details.delta.dy)
                .clamp(0.0, _dragThreshold);
            final wasReady = _playlistReadyToNavigate;
            _playlistReadyToNavigate = _playlistDragOffset >= _dragThreshold;
            if (_playlistReadyToNavigate && !wasReady) {
              HapticFeedback.lightImpact();
            }
          });
        },
        onVerticalDragEnd: (details) async {
          final v = details.primaryVelocity ?? 0.0; // aşağı hızlı -> pozitif
          if (_playlistReadyToNavigate || v > 500) {
            // >>> POPUP: Coming Soon <<<
            await showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.r)),
                content: Text(
                  'Coming Soon!',
                  style: GoogleFonts.inter(
                      fontSize: 16.sp, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('OK',
                        style: TextStyle(color: AppColors.primaryGold)),
                  ),
                ],
              ),
            );
          }
          setState(() {
            _isPlaylistDragging = false;
            _playlistReadyToNavigate = false;
            _playlistDragOffset = 0.0;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          transform: Matrix4.identity()
            ..scale(_isPlaylistDragging ? 0.97 : 1.0),
          decoration: BoxDecoration(
            color: _playlistReadyToNavigate
                ? const Color(0xFFD4AF37)
                : const Color(0xFFCCCBCB),
            borderRadius: BorderRadius.circular(30.r),
            boxShadow: [
              BoxShadow(
                color: _playlistReadyToNavigate
                    ? AppColors.primaryGold.withOpacity(0.3)
                    : Colors.black.withOpacity(0.08),
                blurRadius: _isPlaylistDragging ? 25 : 15,
                offset: Offset(0, _isPlaylistDragging ? 12 : 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Başlık
              Positioned(
                right: 20.w,
                bottom: 20.h,
                child: Text(
                  'Your Playlist',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: _playlistReadyToNavigate
                        ? Colors.white
                        : AppColors.textPrimary,
                  ),
                ),
              ),
              // Indicator: altta
              Positioned(
                bottom: 8.h,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    AnimatedBuilder(
                      animation: _playlistPulseAnimation,
                      builder: (_, __) {
                        return Transform.scale(
                          scale: _playlistPulseAnimation.value,
                          child: Icon(
                            _playlistReadyToNavigate
                                ? Icons.lock_open
                                : Icons.keyboard_arrow_down,
                            size: 20.sp,
                            color: _playlistReadyToNavigate
                                ? Colors.white.withOpacity(0.85)
                                : AppColors.textPrimary.withOpacity(0.5),
                          ),
                        );
                      },
                    ),
                    Container(
                      width: 50.w,
                      height: 5.h,
                      decoration: BoxDecoration(
                        color: AppColors.textPrimary.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(3.r),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress,
                        child: Container(
                          decoration: BoxDecoration(
                            color: _playlistReadyToNavigate
                                ? Colors.white
                                : AppColors.primaryGold,
                            borderRadius: BorderRadius.circular(3.r),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- All Subliminals ----------
  Widget _buildAllSubliminalsCard() {
    final progress = (_dragOffset / _dragThreshold).clamp(0.0, 1.0);

    return Positioned(
      top: 100.h + (_dragOffset.clamp(0, _dragThreshold) * 0.3),
      left: 0,
      right: 0,
      height: 200.h,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CategoriesScreen()),
          );
        },
        onVerticalDragStart: (_) => setState(() => _isDragging = true),
        onVerticalDragUpdate: (details) {
          setState(() {
            _dragOffset =
                (_dragOffset + details.delta.dy).clamp(0.0, _dragThreshold);
            final wasReady = _readyToNavigate;
            _readyToNavigate = _dragOffset >= _dragThreshold;
            if (_readyToNavigate && !wasReady) {
              HapticFeedback.lightImpact();
            }
          });
        },
        onVerticalDragEnd: (details) {
          final v = details.primaryVelocity ?? 0.0; // aşağı hızlı -> pozitif
          if (_readyToNavigate || v > 500) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CategoriesScreen()),
            );
          }
          setState(() {
            _isDragging = false;
            _readyToNavigate = false;
            _dragOffset = 0.0;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()..scale(_isDragging ? 0.97 : 1.0),
          decoration: BoxDecoration(
            color: _readyToNavigate
                ? const Color(0xFFD4AF37)
                : const Color(0xFFCCCBCB),
            borderRadius: BorderRadius.circular(30.r),
            boxShadow: [
              BoxShadow(
                color: _readyToNavigate
                    ? AppColors.primaryGold.withOpacity(0.3)
                    : Colors.black.withOpacity(0.1),
                blurRadius: _isDragging ? 25 : 20,
                offset: Offset(0, _isDragging ? 12 : 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: 20.w,
                bottom: 20.h,
                child: Text(
                  'All Subliminals',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color:
                        _readyToNavigate ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
              Positioned(
                bottom: 8.h,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Icon(
                            _readyToNavigate
                                ? Icons.lock_open
                                : Icons.keyboard_arrow_down,
                            color: _readyToNavigate
                                ? Colors.white.withOpacity(0.8)
                                : AppColors.textPrimary.withOpacity(0.5),
                            size: 20.sp,
                          ),
                        );
                      },
                    ),
                    Container(
                      width: 50.w,
                      height: 5.h,
                      decoration: BoxDecoration(
                        color: AppColors.textPrimary.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(3.r),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress,
                        child: Container(
                          decoration: BoxDecoration(
                            color: _readyToNavigate
                                ? Colors.white
                                : AppColors.primaryGold,
                            borderRadius: BorderRadius.circular(3.r),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderButton(String text, bool isDark) {
    return GestureDetector(
      onTap: isDark ? _toggleMenu : null,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isDark ? AppColors.textPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: AppColors.textPrimary, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isDark) ...[
              Icon(Icons.category_outlined,
                  size: 14.sp, color: AppColors.textPrimary),
              SizedBox(width: 4.w),
            ],
            Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            if (isDark) ...[
              SizedBox(width: 4.w),
              const Icon(Icons.menu, size: 14, color: Colors.white),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 80.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(Icons.home_outlined, 'Home', 0),
          _buildNavItem(Icons.library_music_outlined, 'Library', 1),
          _buildNavItem(Icons.play_circle_outline, 'Playlist', 2),
          _buildNavItem(Icons.chat_bubble_outline, 'AI Chat', 3),
          _buildNavItem(Icons.person_outline, 'Profile', 4),
        ],
      ),
    );
  }

  // lib/features/home/home_screen.dart içinde
// _buildNavItem metodunu bulun ve şu şekilde güncelleyin:

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedIndex = index);

        switch (index) {
          case 0:
            // Home - zaten home'dayız
            break;
          case 1:
            // Library - Coming Soon
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.r)),
                  title: Row(
                    children: [
                      Icon(
                        Icons.library_music,
                        color: AppColors.primaryGold,
                        size: 28.sp,
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        'Library',
                        style: GoogleFonts.inter(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.construction,
                        size: 64.sp,
                        color: AppColors.primaryGold.withOpacity(0.5),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'Coming Soon!',
                        style: GoogleFonts.inter(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Your personal library with favorites, downloads, and listening history will be available soon.',
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'OK',
                        style: GoogleFonts.inter(
                          color: AppColors.primaryGold,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ).then((_) {
              // Dialog kapandıktan sonra Home'a geri dön
              if (mounted) {
                setState(() => _selectedIndex = 0);
              }
            });
            break;
          case 2:
            // Playlist - Coming Soon
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.r)),
                  title: Row(
                    children: [
                      Icon(
                        Icons.playlist_play,
                        color: AppColors.primaryGold,
                        size: 28.sp,
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        'Playlist',
                        style: GoogleFonts.inter(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.construction,
                        size: 64.sp,
                        color: AppColors.primaryGold.withOpacity(0.5),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'Coming Soon!',
                        style: GoogleFonts.inter(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Create and manage your custom playlists for a personalized experience.',
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'OK',
                        style: GoogleFonts.inter(
                          color: AppColors.primaryGold,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ).then((_) {
              if (mounted) {
                setState(() => _selectedIndex = 0);
              }
            });
            break;
          case 3:
            // AI Chat - Coming Soon
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.r)),
                  title: Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        color: AppColors.primaryGold,
                        size: 28.sp,
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        'AI Assistant',
                        style: GoogleFonts.inter(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.construction,
                        size: 64.sp,
                        color: AppColors.primaryGold.withOpacity(0.5),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'Coming Soon!',
                        style: GoogleFonts.inter(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Your personal AI wellness coach will help you choose the perfect sessions and track your progress.',
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'OK',
                        style: GoogleFonts.inter(
                          color: AppColors.primaryGold,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ).then((_) {
              if (mounted) {
                setState(() => _selectedIndex = 0);
              }
            });
            break;
          case 4:
            // Profile
            Navigator.pushNamed(context, AppRoutes.profile);
            break;
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: isSelected ? AppColors.primaryGold : Colors.grey[400],
                size: 24.sp),
            SizedBox(height: 4.h),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10.sp,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.primaryGold : Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
