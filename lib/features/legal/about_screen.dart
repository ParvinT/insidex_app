// lib/features/legal/about_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'About INSIDEX',
          style: GoogleFonts.inter(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo
            Center(
              child: Container(
                width: 100.w,
                height: 100.w,
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: SvgPicture.asset(
                  'assets/images/logo.svg',
                  width: 60.w,
                  height: 60.w,
                ),
              ),
            ),

            SizedBox(height: 24.h),

            // Version
            Center(
              child: Text(
                'Version 1.0.0',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  color: AppColors.textLight,
                ),
              ),
            ),

            SizedBox(height: 32.h),

            // Main Description
            Text(
              'Next-Generation Wellness',
              style: GoogleFonts.inter(
                fontSize: 24.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),

            SizedBox(height: 16.h),

            Text(
              'INSIDEX is a next-generation wellness app that combines subliminal programming, neuroscience, and sound therapy to help you restore balance, confidence, and vitality in daily life.',
              style: GoogleFonts.inter(
                fontSize: 15.sp,
                height: 1.6,
                color: AppColors.textSecondary,
              ),
            ),

            SizedBox(height: 24.h),

            // What We Offer
            _buildSection(
              title: '🎯 What We Offer',
              content:
                  'We offer personalized sound sessions for sleep, relaxation, fitness, driving, work, meditation, focus, emotional healing, and more. Each session uses affirmations embedded below the threshold of conscious perception — allowing your subconscious mind to absorb positive change naturally and gently.',
            ),

            // Our Mission
            _buildSection(
              title: '✨ Our Philosophy',
              content:
                  'INSIDEX is not just about healing — it\'s about reconnecting with yourself on a deeper level. Whether you\'re seeking clarity, emotional release, energy, or confidence, INSIDEX offers guided support for your journey.',
            ),

            // Types of Subliminals
            _buildSection(
              title: '🎵 Types of Sessions',
              content: '''We provide various types of subliminals:
              
- Relaxing tracks for deep rest and emotional reset
- Active tracks for workouts, driving, and high-focus tasks  
- Healing programs designed for daily progress with measurable results''',
            ),

            // Mission Statement
            Container(
              margin: EdgeInsets.only(top: 24.h, bottom: 24.h),
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryGold.withOpacity(0.1),
                    AppColors.primaryGold.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.primaryGold.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.favorite,
                    color: AppColors.primaryGold,
                    size: 32.sp,
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'Our Mission',
                    style: GoogleFonts.inter(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'To make mental wellness accessible, modern, and intuitive.',
                    style: GoogleFonts.inter(
                      fontSize: 15.sp,
                      height: 1.5,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Contact
            _buildSection(
              title: '📧 Contact Us',
              content: 'Email: insidexapp@gmail.com',
            ),

            SizedBox(height: 32.h),

            // Footer
            Center(
              child: Column(
                children: [
                  Text(
                    'Made with ❤️ in Istanbul',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      color: AppColors.textLight,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    '© 2025 INSIDEX. All rights reserved.',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String content,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            content,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              height: 1.6,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
