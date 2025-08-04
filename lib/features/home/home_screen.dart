import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
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

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isMenuOpen = false;

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
                      // ✅ Your Playlist Container (alt sağ yazı)
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

                      // ✅ All Subliminals Container (alt sağ yazı)
                      Positioned(
                        top: 120.h,
                        left: 0,
                        right: 0,
                        height: 200.h,
                        child: GestureDetector(
                          onTap: () {
                            // Tıklamada da açılsın
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CategoriesScreen(),
                              ),
                            );
                          },
                          onVerticalDragEnd: (details) {
                            // Aşağı kaydırma algılama - daha hassas
                            if (details.primaryVelocity! > 50) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const CategoriesScreen(),
                                ),
                              );
                            }
                          },
                          onVerticalDragUpdate: (details) {
                            // Alternatif: Drag sırasında da kontrol
                            if (details.delta.dy > 10) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const CategoriesScreen(),
                                ),
                              );
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFCCCBCB),
                              borderRadius: BorderRadius.circular(30.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
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
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                // Drag indicator - daha belirgin yapalım
                                Positioned(
                                  bottom: 8.h,
                                  left: 0,
                                  right: 0,
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.keyboard_arrow_down,
                                        color: AppColors.textPrimary
                                            .withOpacity(0.5),
                                        size: 20.sp,
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
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Header Container
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
                            padding: EdgeInsets.all(20.w),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    SvgPicture.asset(
                                      'assets/images/logo.svg',
                                      width: 100.w,
                                      height: 30.h,
                                      colorFilter: const ColorFilter.mode(
                                        AppColors.textPrimary,
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        _buildHeaderButton('Sign in', false),
                                        SizedBox(width: 12.w),
                                        GestureDetector(
                                          onTap: _toggleMenu,
                                          child:
                                              _buildHeaderButton('Menu', true),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                SizedBox(height: 20.h),
                                Container(
                                  height: 50.h,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(25.r),
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                      width: 1,
                                    ),
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
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Menu Overlay
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
    return Container(
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
