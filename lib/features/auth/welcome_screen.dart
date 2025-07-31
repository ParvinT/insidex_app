import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            children: [
              const Spacer(flex: 2),
              
              // Logo
              SvgPicture.asset(
                'assets/images/logo.svg',
                width: 180.w,
                height: 60.h,
                colorFilter: const ColorFilter.mode(
                  AppColors.textPrimary,
                  BlendMode.srcIn,
                ),
              ),
              
              SizedBox(height: 60.h),
              
              // Welcome Text
              Text(
                'Welcome to',
                style: GoogleFonts.inter(
                  fontSize: 32.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Inside⊗',
                style: GoogleFonts.inter(
                  fontSize: 32.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              
              SizedBox(height: 16.h),
              
              // Subtitle
              Text(
                'Create your personal profile\nto get custom subliminal sessions',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              
              SizedBox(height: 60.h),
              
              // Google Sign In Button
              _buildSocialButton(
                onTap: () {
                  // TODO: Google sign in
                  print('Google sign in tapped');
                },
                icon: 'assets/icons/google_icon.png', // Google icon ekleyeceğiz
                label: 'Google',
              ),
              
              SizedBox(height: 16.h),
              
              // Apple Sign In Button
              _buildSocialButton(
                onTap: () {
                  // TODO: Apple sign in
                  print('Apple sign in tapped');
                },
                icon: 'assets/icons/apple_icon.png', // Apple icon ekleyeceğiz
                label: 'Apple ID',
                isDark: true,
              ),
              
              SizedBox(height: 16.h),
              
              // Email Sign In Button
              _buildEmailButton(
                onTap: () {
                  // TODO: Navigate to email login
                  print('Email login tapped');
                },
              ),
              
              const Spacer(flex: 3),
              
              // Sign Up Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      // TODO: Navigate to sign up
                      print('Sign up tapped');
                    },
                    child: Text(
                      'Sign Up',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        color: AppColors.primaryGold,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 32.h),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSocialButton({
    required VoidCallback onTap,
    required String icon,
    required String label,
    bool isDark = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56.h,
        decoration: BoxDecoration(
          color: isDark ? AppColors.textPrimary : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isDark ? AppColors.textPrimary : AppColors.greyBorder,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Geçici olarak icon yerine placeholder
            Container(
              width: 24.w,
              height: 24.w,
              decoration: BoxDecoration(
                color: isDark ? Colors.white : AppColors.greyLight,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 12.w),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEmailButton({required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: AppColors.greyBorder,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            'Email + Password',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}