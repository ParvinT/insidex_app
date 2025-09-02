// lib/features/auth/welcome_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../shared/widgets/social_login_button.dart';

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

              // Welcome Text - Only "Welcome" now
              Text(
                'Welcome',
                style: GoogleFonts.inter(
                  fontSize: 36.sp,
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

              /* // Google Sign In Button
              SocialLoginButton(
                onTap: () {
                  // TODO: Google sign in
                  print('Google sign in tapped');
                },
                label: 'Google',
              ),

              SizedBox(height: 16.h),

              // Apple Sign In Button
              SocialLoginButton(
                onTap: () {
                  // TODO: Apple sign in
                  print('Apple sign in tapped');
                },
                label: 'Apple ID',
                isDark: true,
              ),

              SizedBox(height: 16.h), */

              // Email Sign In Button
              _buildEmailButton(
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.login);
                },
              ),

              const Spacer(),

              // Continue as Guest Link
              TextButton(
                onPressed: () {
                  // Navigate to home as guest
                  Navigator.pushReplacementNamed(context, AppRoutes.home);
                },
                child: Text(
                  'Continue as a Guest',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),

              SizedBox(height: 16.h),

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
                      Navigator.pushNamed(context, AppRoutes.register);
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

  Widget _buildEmailButton({required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 48.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: AppColors.greyBorder,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.email_outlined,
                color: AppColors.textPrimary,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Email + Password',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
