// lib/features/legal/disclaimer_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

class DisclaimerScreen extends StatelessWidget {
  const DisclaimerScreen({super.key});

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
          'Disclaimer',
          style: GoogleFonts.inter(
            fontSize: 20.sp.clamp(20.0, 22.0),
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
            // Warning Banner
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: Colors.amber.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.amber[700],
                    size: 24.sp,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'Please read carefully before using INSIDEX',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // Medical Disclaimer
            _buildSection(
              icon: '⚕️',
              title: 'Not Medical Treatment',
              content:
                  'INSIDEX subliminal tracks are not medical treatments and are not intended to replace any medical advice or therapy. Results may vary for different individuals, and timeframes for perceived effects are not guaranteed.',
              isImportant: true,
            ),

            // No Warranties
            _buildSection(
              icon: '📋',
              title: 'No Warranties',
              content:
                  'All content is provided "as is" and without warranties of any kind. INSIDEX and its team are not liable for any direct, indirect, incidental, or consequential damages resulting from the use or misuse of our content.',
            ),

            // Safety Warning
            _buildSection(
              icon: '⚠️',
              title: 'Important Safety Note',
              content:
                  '''Some subliminal sessions may induce a deeply relaxed or meditative state. These should NOT be used while:
              
- Operating heavy machinery
- Driving (except our specially designed driving sessions)
- In situations requiring full alertness

Our dynamic tracks for driving, focus, and physical activity are clearly labeled and safe for their intended use.''',
              isImportant: true,
            ),

            // Medical Conditions
            _buildSection(
              icon: '🏥',
              title: 'Medical Conditions',
              content:
                  'Always consult your physician before using any audio program if you have a medical condition, especially:\n\n• Epilepsy or seizure disorders\n• Heart conditions\n• Mental health conditions\n• Hearing problems',
            ),

            // Age Restriction
            _buildSection(
              icon: '🔞',
              title: 'Age Restriction',
              content:
                  'This app is intended for users 13 years and older. Users under 18 should use the app with parental guidance.',
            ),

            // Professional Healthcare
            Container(
              margin: EdgeInsets.only(top: 24.h, bottom: 24.h),
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: AppColors.primaryGold.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.primaryGold.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.health_and_safety,
                    color: AppColors.primaryGold,
                    size: 32.sp,
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'Remember',
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Our content is a supportive tool for self-improvement and does not substitute professional healthcare.',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      height: 1.5,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Agreement
            Text(
              'By using INSIDEX, you acknowledge that you have read and understood this disclaimer.',
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                color: AppColors.textLight,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 32.h),

            // Last Updated
            Center(
              child: Text(
                'Last Updated: September 2025',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: AppColors.textLight,
                ),
              ),
            ),

            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String icon,
    required String title,
    required String content,
    bool isImportant = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 20.h),
      padding: isImportant ? EdgeInsets.all(16.w) : null,
      decoration: isImportant
          ? BoxDecoration(
              color: Colors.red.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: Colors.red.withOpacity(0.2),
              ),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: TextStyle(fontSize: 24.sp)),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color:
                        isImportant ? Colors.red[700] : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
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
