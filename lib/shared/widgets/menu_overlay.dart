import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

class MenuOverlay extends StatefulWidget {
  final VoidCallback onClose;
  
  const MenuOverlay({
    super.key,
    required this.onClose,
  });

  @override
  State<MenuOverlay> createState() => _MenuOverlayState();
}

class _MenuOverlayState extends State<MenuOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _closeMenu() {
    _animationController.reverse().then((_) {
      widget.onClose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Stack(
          children: [
            // Dark overlay
            GestureDetector(
              onTap: _closeMenu,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                ),
              ),
            ),
            
            // Menu panel
            Align(
              alignment: Alignment.centerRight,
              child: SlideTransition(
                position: _slideAnimation,
                child: Container(
                  width: 280.w,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30.r),
                      bottomLeft: Radius.circular(30.r),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(-5, 0),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Padding(
                          padding: EdgeInsets.all(24.w),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Menu',
                                style: GoogleFonts.inter(
                                  fontSize: 24.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              IconButton(
                                onPressed: _closeMenu,
                                icon: Icon(
                                  Icons.close,
                                  color: AppColors.textPrimary,
                                  size: 24.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        Divider(
                          color: AppColors.greyBorder,
                          thickness: 1,
                          height: 1,
                        ),
                        
                        // Menu Items
                        Expanded(
                          child: ListView(
                            padding: EdgeInsets.symmetric(vertical: 20.h),
                            children: [
                              _buildMenuItem(
                                icon: Icons.person_outline,
                                title: 'Profile',
                                onTap: () {
                                  print('Profile tapped');
                                  // TODO: Navigate to profile
                                },
                              ),
                              _buildMenuItem(
                                icon: Icons.settings_outlined,
                                title: 'Settings',
                                onTap: () {
                                  print('Settings tapped');
                                  // TODO: Navigate to settings
                                },
                              ),
                            ],
                          ),
                        ),
                        
                        // Bottom section
                        Divider(
                          color: AppColors.greyBorder,
                          thickness: 1,
                          height: 1,
                        ),
                        
                        Padding(
                          padding: EdgeInsets.all(24.w),
                          child: Column(
                            children: [
                              // Version info
                              Text(
                                'Version 1.0.0',
                                style: GoogleFonts.inter(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              // Logo or brand
                              Text(
                                'INSIDEX',
                                style: GoogleFonts.inter(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                  letterSpacing: 2,
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
            ),
          ],
        );
      },
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppColors.textPrimary,
              size: 24.sp,
            ),
            SizedBox(width: 16.w),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
              size: 20.sp,
            ),
          ],
        ),
      ),
    );
  }
}