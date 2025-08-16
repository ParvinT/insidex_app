// lib/features/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../features/library/categories_screen.dart';
import '../../shared/widgets/menu_overlay.dart';

class HomeScreen extends StatefulWidget {
  final bool isGuest;

  const HomeScreen({
    super.key,
    this.isGuest = false,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _isMenuOpen = false;

  // Drag animation variables for All Subliminals
  double _dragOffset = 0.0;
  bool _isDragging = false;
  bool _readyToNavigate = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Stack(
        children: [
          // Main content
          SafeArea(
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.grey[200]!,
                        Colors.grey[300]!,
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
                  child: Stack(
                    children: [
                      // ✅ Your Playlist Container (UNCHANGED)
                      Positioned(
                        top: 180.h,
                        left: 0,
                        right: 0,
                        height: 200.h,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFCCCBCB),
                            borderRadius: BorderRadius.circular(30.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                right: 20.w,
                                bottom: 20.h,
                                child: Text(
                                  'Your Playlist',
                                  style: GoogleFonts.inter(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ✅ All Subliminals Container (ENHANCED WITH ANIMATION)
                      Positioned(
                        top: 120.h +
                            (_dragOffset.clamp(0, 60) * 0.3), // Slight movement
                        left: 0,
                        right: 0,
                        height: 200.h,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CategoriesScreen(),
                              ),
                            );
                          },
                          onVerticalDragStart: (_) {
                            setState(() {
                              _isDragging = true;
                            });
                          },
                          onVerticalDragUpdate: (details) {
                            setState(() {
                              _dragOffset += details.delta.dy;
                              if (_dragOffset > 60) {
                                if (!_readyToNavigate) {
                                  HapticFeedback.lightImpact();
                                }
                                _readyToNavigate = true;
                              } else {
                                _readyToNavigate = false;
                              }
                            });
                          },
                          onVerticalDragEnd: (details) {
                            if (_readyToNavigate ||
                                details.primaryVelocity! > 500) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const CategoriesScreen(),
                                ),
                              );
                            }
                            // Reset
                            setState(() {
                              _isDragging = false;
                              _readyToNavigate = false;
                              _dragOffset = 0.0;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            transform: Matrix4.identity()
                              ..scale(_isDragging ? 0.97 : 1.0),
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
                                      color: _readyToNavigate
                                          ? Colors.white
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                // Drag indicator
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
                                                  ? Colors.white
                                                      .withOpacity(0.8)
                                                  : AppColors.textPrimary
                                                      .withOpacity(0.5),
                                              size: 20.sp,
                                            ),
                                          );
                                        },
                                      ),
                                      Container(
                                        width: 50.w,
                                        height: 5.h,
                                        decoration: BoxDecoration(
                                          color: AppColors.textPrimary
                                              .withOpacity(0.4),
                                          borderRadius:
                                              BorderRadius.circular(3.r),
                                        ),
                                        child: FractionallySizedBox(
                                          alignment: Alignment.centerLeft,
                                          widthFactor:
                                              (_dragOffset / 60).clamp(0, 1),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: _readyToNavigate
                                                  ? Colors.white
                                                  : AppColors.primaryGold,
                                              borderRadius:
                                                  BorderRadius.circular(3.r),
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
                      ),

                      // Header Container (UNCHANGED)
                      Positioned(
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
                                // Header buttons
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildHeaderButton('Category', false),
                                    _buildHeaderButton('Menu', true),
                                  ],
                                ),
                                // Title and Search
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Welcome to Insidex',
                                      style: GoogleFonts.inter(
                                        fontSize: 24.sp,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    SizedBox(height: 20.h),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 20.w,
                                        vertical: 14.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius:
                                            BorderRadius.circular(25.r),
                                      ),
                                      child: TextField(
                                        style: GoogleFonts.inter(
                                          fontSize: 16.sp,
                                          color: AppColors.textPrimary,
                                        ),
                                        decoration: InputDecoration(
                                          hintText: 'Search...',
                                          hintStyle: GoogleFonts.inter(
                                            fontSize: 16.sp,
                                            color: AppColors.textLight,
                                          ),
                                          prefixIcon: Icon(
                                            Icons.search,
                                            color: AppColors.textLight,
                                            size: 24.sp,
                                          ),
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 20.w,
                                            vertical: 14.h,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 20.h),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            height: 48.h,
                                            decoration: BoxDecoration(
                                              color: AppColors.textPrimary,
                                              borderRadius:
                                                  BorderRadius.circular(25.r),
                                            ),
                                            child: Center(
                                              child: Text(
                                                'Start Healing',
                                                style: GoogleFonts.inter(
                                                  fontSize: 14.sp,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 16.w),
                                        Expanded(
                                          child: Container(
                                            height: 48.h,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[300],
                                              borderRadius:
                                                  BorderRadius.circular(25.r),
                                            ),
                                            child: Center(
                                              child: Text(
                                                'My Programs',
                                                style: GoogleFonts.inter(
                                                  fontSize: 14.sp,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
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

          // Menu Overlay (UNCHANGED)
          if (_isMenuOpen)
            Positioned.fill(
              child: MenuOverlay(
                onClose: () {
                  setState(() {
                    _isMenuOpen = false;
                  });
                },
              ),
            ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
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
          border: Border.all(
            color: AppColors.textPrimary,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isDark) ...[
              Icon(
                Icons.menu,
                color: Colors.white,
                size: 14.sp,
              ),
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

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });

        // Navigation logic
        switch (index) {
          case 0:
            break;
          case 1:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CategoriesScreen()),
            ).then((_) {
              setState(() {
                _selectedIndex = 0;
              });
            });
            break;
          case 2:
          case 3:
            // Coming soon dialog
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  content: Text(
                    'Coming Soon!',
                    style: GoogleFonts.inter(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('OK'),
                    ),
                  ],
                );
              },
            );
            setState(() {
              _selectedIndex = 0;
            });
            break;
          case 4:
            Navigator.pushNamed(context, AppRoutes.profile).then((_) {
              setState(() {
                _selectedIndex = 0;
              });
            });
            break;
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24.sp,
              color: isSelected ? AppColors.textPrimary : AppColors.textLight,
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10.sp,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.textPrimary : AppColors.textLight,
              ),
            ),
            if (isSelected)
              Container(
                margin: EdgeInsets.only(top: 2.h),
                height: 2.h,
                width: 20.w,
                decoration: BoxDecoration(
                  color: AppColors.textPrimary,
                  borderRadius: BorderRadius.circular(1.r),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
