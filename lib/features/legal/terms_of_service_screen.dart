// lib/features/legal/terms_of_service_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

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
          'Terms of Service',
          style: GoogleFonts.inter(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.greyLight.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Terms of Service',
                    style: GoogleFonts.inter(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Effective Date: January 27, 2025',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // Content sections
            _buildSection(
              title: '1. Acceptance of Terms',
              content: '''
By downloading, installing, or using INSIDEX ("the App"), you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use our App.
              ''',
            ),

            _buildSection(
              title: '2. Description of Service',
              content: '''
INSIDEX provides subliminal audio sessions, sound healing, and meditation content designed to support mental wellness and personal development. The App is not a substitute for professional medical or psychological treatment.
              ''',
            ),

            _buildSection(
              title: '3. User Accounts',
              content: '''
• You must be at least 13 years old to use this App
• You are responsible for maintaining the confidentiality of your account
• You agree to provide accurate and complete information
• One person or legal entity may not maintain more than one account
              ''',
            ),

            _buildSection(
              title: '4. Subscription and Payments',
              content: '''
• Premium features will be available through in-app purchases
• Subscription fees are non-refundable except as required by law
• We reserve the right to change subscription fees upon 30 days notice
• Free trial periods, if offered, automatically convert to paid subscriptions unless cancelled
              ''',
            ),

            _buildSection(
              title: '5. Content and Intellectual Property',
              content: '''
• All content in the App is owned by INSIDEX or its licensors
• You may not copy, modify, distribute, sell, or lease any part of our services
• User-generated content remains your property, but you grant us a license to use it
• You may not use our content for commercial purposes without permission
              ''',
            ),

            _buildSection(
              title: '6. Medical Disclaimer',
              content: '''
• INSIDEX is not intended to diagnose, treat, cure, or prevent any disease
• The App is not a substitute for professional medical advice
• Always consult with a qualified healthcare provider
• If you experience any adverse effects, discontinue use immediately
              ''',
            ),

            _buildSection(
              title: '7. User Conduct',
              content: '''
You agree not to:
• Use the App for any illegal purposes
• Attempt to reverse engineer or hack the App
• Share your account with others
• Upload malicious content or spam
• Violate any applicable laws or regulations
              ''',
            ),

            _buildSection(
              title: '8. Privacy',
              content: '''
Your use of our App is also governed by our Privacy Policy. Please review our Privacy Policy, which also governs the App and informs users of our data collection practices.
              ''',
            ),

            _buildSection(
              title: '9. Limitation of Liability',
              content: '''
INSIDEX and its affiliates will not be liable for any indirect, incidental, special, consequential, or punitive damages resulting from your use or inability to use the App.
              ''',
            ),

            _buildSection(
              title: '10. Termination',
              content: '''
We may terminate or suspend your account immediately, without prior notice or liability, for any reason whatsoever, including without limitation if you breach the Terms.
              ''',
            ),

            _buildSection(
              title: '11. Changes to Terms',
              content: '''
We reserve the right to modify these terms at any time. We will notify users of any material changes via email or in-app notification.
              ''',
            ),

            _buildSection(
              title: '12. Governing Law',
              content: '''
These Terms shall be governed and construed in accordance with the laws of [Your Country], without regard to its conflict of law provisions.
              ''',
            ),

            _buildSection(
              title: '13. Contact Information',
              content: '''
For any questions about these Terms of Service, please contact us:
• Email: insidexapp@gmail.com
              ''',
            ),

            SizedBox(height: 32.h),

            // Agreement notice
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.primaryGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: AppColors.primaryGold.withOpacity(0.3),
                ),
              ),
              child: Text(
                'By using INSIDEX, you acknowledge that you have read, understood, and agree to be bound by these Terms of Service.',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  color: AppColors.textPrimary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            SizedBox(height: 40.h),
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
            content.trim(),
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
