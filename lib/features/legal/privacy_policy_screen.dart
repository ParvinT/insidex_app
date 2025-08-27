// lib/features/legal/privacy_policy_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
          'Privacy Policy',
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
                    'Privacy Policy',
                    style: GoogleFonts.inter(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Last Updated: January 27, 2025',
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
              title: '1. Information We Collect',
              content: '''
INSIDEX ("we", "our", or "us") collects the following information:
• Email address (for waitlist registration and account creation)
• Name (optional, for personalization)
• Usage analytics (anonymous)
• Device information (for app performance)
• Session listening history
• User preferences and settings
              ''',
            ),

            _buildSection(
              title: '2. How We Use Your Information',
              content: '''
We use the collected information to:
• Notify you about premium features and updates
• Send product announcements and newsletters
• Provide customer support
• Improve our app and services
• Personalize your experience
• Process your account registration
              ''',
            ),

            _buildSection(
              title: '3. Data Storage and Security',
              content: '''
Your data is securely stored on Google Firebase infrastructure with industry-standard security protocols. Our servers are located in europe-west region. We implement appropriate technical and organizational measures to protect your data.
              ''',
            ),

            _buildSection(
              title: '4. Your Rights',
              content: '''
You have the right to:
• Access your personal data
• Request deletion of your data
• Unsubscribe from our emails
• Data portability
• Correct inaccurate data
• Object to data processing

To exercise these rights, contact us at: support@insidex.app
              ''',
            ),

            _buildSection(
              title: '5. Data Sharing',
              content: '''
We do not sell, trade, or rent your personal information to third parties. We may share your information only:
• With your consent
• To comply with legal obligations
• With service providers (Firebase, email services)
              ''',
            ),

            _buildSection(
              title: '6. Cookies',
              content: '''
We use essential cookies to maintain your session and preferences. You can control cookies through your browser settings.
              ''',
            ),

            _buildSection(
              title: '7. Children\'s Privacy',
              content: '''
Our service is not intended for children under 13. We do not knowingly collect information from children under 13. If you are a parent and believe we have collected your child's information, please contact us immediately.
              ''',
            ),

            _buildSection(
              title: '8. Email Communications',
              content: '''
By joining our waitlist, you agree to receive emails about:
• Product updates
• Premium features launch
• Special offers (if opted in)

You can unsubscribe at any time using the link in our emails.
              ''',
            ),

            _buildSection(
              title: '9. Data Retention',
              content: '''
We retain your data for as long as necessary to provide our services or as required by law. You may request deletion at any time.
              ''',
            ),

            _buildSection(
              title: '10. Changes to This Policy',
              content: '''
We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last Updated" date.
              ''',
            ),

            _buildSection(
              title: '11. Contact Us',
              content: '''
If you have any questions about this Privacy Policy, please contact us:
• Email: support@insidex.app
• Website: https://insidex.app
              ''',
            ),

            _buildSection(
              title: '12. Legal Basis for Processing (GDPR)',
              content: '''
We process your data based on:
• Your consent
• Legitimate interests
• Contractual necessity
• Legal obligations
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
                'By using INSIDEX, you agree to the collection and use of information in accordance with this Privacy Policy.',
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
