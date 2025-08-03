import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200], // Hafif gri arka plan
      body: SafeArea(
        child: Column(
          children: [
            // Top Section Container
            Container(
              decoration: BoxDecoration(
                color: const Color.fromARGB(
                    255, 204, 203, 203), // Custom renk kodu
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40.r), // Daha oval
                  bottomRight: Radius.circular(40.r), // Daha oval
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header
                  _buildHeader(),

                  SizedBox(height: 16.h),

                  // Search Bar
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: _buildSearchBar(),
                  ),

                  SizedBox(height: 20.h),

                  // Action Buttons
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: _buildActionButtons(),
                  ),

                  SizedBox(height: 24.h),
                ],
              ),
            ),

            // TODO: All Subliminals, Playlist ve AI Chat eklenecek
            Expanded(
              child: Container(
                color: Colors.transparent, // Arka plan rengi görünsün
                child: Center(
                  child: Text(
                    'Content Area',
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo
          SvgPicture.asset(
            'assets/images/logo.svg',
            width: 100.w,
            height: 30.h,
            colorFilter: const ColorFilter.mode(
              AppColors.textPrimary,
              BlendMode.srcIn,
            ),
          ),

          // Right side buttons
          Row(
            children: [
              _buildHeaderButton('Sing in', false),
              SizedBox(width: 12.w),
              _buildHeaderButton('Menu', true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton(String text, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.textPrimary : Colors.transparent,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: AppColors.textPrimary,
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 50.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
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
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton('Start Healing', true),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: _buildActionButton('My Programs', false),
        ),
      ],
    );
  }

  Widget _buildActionButton(String text, bool isDark) {
    return Container(
      height: 48.h,
      decoration: BoxDecoration(
        color: isDark ? AppColors.textPrimary : AppColors.greyLight,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Center(
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 80.h,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24.sp,
              color: isSelected ? AppColors.primaryGold : AppColors.textLight,
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10.sp,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.primaryGold : AppColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
