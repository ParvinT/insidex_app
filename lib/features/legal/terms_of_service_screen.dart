// lib/features/legal/terms_of_service_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/responsive/context_ext.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isTablet = context.isTablet;
    final isDesktop = context.isDesktop;

    // Responsive değerler
    final double maxContentWidth =
        isDesktop ? 800 : (isTablet ? 600 : double.infinity);
    final double horizontalPadding =
        isDesktop ? 40.w : (isTablet ? 30.w : 20.w);
    final double titleSize =
        isDesktop ? 22.sp : (isTablet ? 20.sp : 20.sp.clamp(20.0, 22.0));
    final double headerTitleSize =
        isDesktop ? 26.sp : (isTablet ? 22.sp : 24.sp);
    final double sectionTitleSize =
        isDesktop ? 18.sp : (isTablet ? 16.sp : 18.sp);
    final double bodyTextSize = isDesktop ? 14.sp : (isTablet ? 13.sp : 14.sp);
    final double smallTextSize = isTablet ? 11.sp : 12.sp;
    final double warningTextSize = isTablet ? 12.sp : 13.sp;
    final double iconSize = isTablet ? 26.sp : 24.sp;

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Terms of Service',
          style: GoogleFonts.inter(
            fontSize: 20.sp.clamp(20.0, 22.0),
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20.h),

                // Header with Company Info
                Container(
                  padding: EdgeInsets.all(isTablet ? 20.w : 16.w),
                  decoration: BoxDecoration(
                    color: AppColors.greyLight.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'INSIDEX Terms of Use',
                        style: GoogleFonts.inter(
                          fontSize: headerTitleSize,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Effective Date: September 11, 2025',
                        style: GoogleFonts.inter(
                          fontSize: bodyTextSize,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        'ALZHAMI LTD\nCompany Number: 16545604\nRegistered Office: 85 Great Portland Street, London, England W1W 7LT',
                        style: GoogleFonts.inter(
                          fontSize: smallTextSize,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24.h),

                // Medical Disclaimer Warning
                Container(
                  padding: EdgeInsets.all(isTablet ? 14.w : 12.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3CD),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: const Color(0xFFFFC107)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: const Color(0xFFF57C00),
                        size: iconSize,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          'The App is not a medical device or substitute for professional medical advice.',
                          style: GoogleFonts.inter(
                            fontSize: warningTextSize,
                            color: const Color(0xFF856404),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24.h),

                // Introduction
                Text(
                  'These Terms govern your use of the INSIDEX mobile application and services provided by ALZHAMI LTD. By using our Services, you agree to these Terms.',
                  style: GoogleFonts.inter(
                    fontSize: bodyTextSize,
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                ),

                SizedBox(height: 24.h),

                // Sections
                _buildSection(
                  context: context,
                  title: '1. Eligibility and Account',
                  content:
                      '''You must be at least 18 years old to use the Services.

To access features, you must:
• Provide accurate information
• Maintain account security
• Be responsible for all account activities
• Notify us of unauthorized use at support@insidexapp.com
• Maintain only one account per person''',
                ),

                _buildSection(
                  context: context,
                  title: '2. License Grant',
                  content:
                      '''We grant you a limited, non-exclusive, non-transferable, revocable license for personal, non-commercial use.

You may NOT:
• Modify, reverse engineer, or decompile the App
• Rent, lease, sell, or sublicense
• Use for illegal purposes
• Violate these Terms

For iOS users: These Terms are between you and us, not Apple.''',
                ),

                _buildSection(
                  context: context,
                  title: '3. User Content and Conduct',
                  content:
                      '''You may input personal data for personalized recommendations via Firebase:
• Wellness goals from onboarding
• Gender and age information
• Listening preferences

You retain ownership but grant us a worldwide, royalty-free license to process your content.

Prohibited conduct:
• Illegal or harmful activities
• Uploading malware or viruses
• Interfering with the Services
• Making unsubstantiated medical claims
• Using as substitute for professional care''',
                ),

                _buildSection(
                  context: context,
                  title: '4. Intellectual Property',
                  content:
                      '''All content (audio programs, AI algorithms, designs) is owned by us or licensors and protected by law.

"INSIDEX" and related logos are our trademarks. You may not copy, distribute, or create derivative works without permission.''',
                ),

                _buildSection(
                  context: context,
                  title: '5. Subscriptions and Payments',
                  content: '''Free Features:
• Limited to 3 sessions per day

Premium Subscriptions:
• Unlimited access and advanced features
• Billed via App Store or Google Play
• Auto-renew unless canceled
• Refer to platform terms for refunds

For iOS: Managed through Apple ID.''',
                ),

                _buildSection(
                  context: context,
                  title: '6. Medical Disclaimer',
                  content:
                      '''THE SERVICES ARE PROVIDED "AS IS" WITHOUT WARRANTIES.

The App's subliminal audio is for self-improvement only. It does NOT:
• Diagnose, treat, or cure any condition
• Replace medical or psychological advice
• Substitute for professional care

Consult a healthcare provider before use, especially with health concerns.

WE SHALL NOT BE LIABLE FOR INDIRECT, INCIDENTAL, SPECIAL, OR CONSEQUENTIAL DAMAGES. OUR LIABILITY SHALL NOT EXCEED AMOUNTS PAID IN THE PAST 12 MONTHS.''',
                ),

                _buildSection(
                  context: context,
                  title: '7. Data Processing',
                  content: '''We use Firebase (Google) services for:
• Authentication and user management
• Database storage (Firestore) - europe-west region
• Analytics and performance monitoring
• File storage for audio content

See our Privacy Policy for details.''',
                ),

                _buildSection(
                  context: context,
                  title: '8. Indemnification',
                  content:
                      '''You agree to indemnify and hold us and Apple harmless from claims arising from:
• Your use of the Services
• Violation of these Terms
• Infringement of third-party rights''',
                ),

                _buildSection(
                  context: context,
                  title: '9. Termination',
                  content:
                      '''We may terminate your access anytime for violations.
Upon termination:
• Your license ends
• You must delete the App
• Certain sections survive termination''',
                ),

                _buildSection(
                  context: context,
                  title: '10. Governing Law',
                  content:
                      '''These Terms are governed by the laws of England and Wales.
Disputes resolved in London courts.

For iOS users: Claims against Apple subject to their terms.''',
                ),

                _buildSection(
                  context: context,
                  title: '11. Changes to Terms',
                  content: '''We may update these Terms.
Material changes notified via app or email.
Continued use constitutes acceptance.''',
                ),

                _buildSection(
                  context: context,
                  title: '12. Export Control',
                  content:
                      '''You confirm that you're not in a U.S.-embargoed country or on restricted lists, complying with Apple App Store guidelines.''',
                ),

                _buildSection(
                  context: context,
                  title: '13. Contact Us',
                  content: '''ALZHAMI LTD
Company Number: 16545604
85 Great Portland Street, London, W1W 7LT

General Inquiries: hello@insidexapp.com
Support: support@insidexapp.com
Phone: +44 7456 460096

Automated Emails: noreply@insidexapp.com
(Please do not reply to emails from this address)''',
                ),

                SizedBox(height: 32.h),

                // Agreement notice
                Container(
                  padding: EdgeInsets.all(isTablet ? 20.w : 16.w),
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
                      fontSize: bodyTextSize,
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
        ),
      ),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required String content,
  }) {
    final isTablet = context.isTablet;
    final isDesktop = context.isDesktop;
    final sectionTitleSize = isDesktop ? 18.sp : (isTablet ? 16.sp : 18.sp);
    final bodyTextSize = isDesktop ? 14.sp : (isTablet ? 13.sp : 14.sp);

    return Container(
      margin: EdgeInsets.only(bottom: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: sectionTitleSize,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            content.trim(),
            style: GoogleFonts.inter(
              fontSize: bodyTextSize,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
