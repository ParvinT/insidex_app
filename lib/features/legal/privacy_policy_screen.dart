// lib/features/legal/privacy_policy_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/responsive/context_ext.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
          'Privacy Policy',
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
                        'INSIDEX Privacy Policy',
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
                        'Data Controller: ALZHAMI LTD\nCompany Number: 16545604\nRegistered Office: 85 Great Portland Street, London, England W1W 7LT',
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

                // Introduction
                Text(
                  'ALZHAMI LTD ("we," "us," or "our") respects your privacy and is committed to protecting your personal data. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our INSIDEX mobile application and related services.',
                  style: GoogleFonts.inter(
                    fontSize: bodyTextSize,
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                ),

                SizedBox(height: 24.h),

                // Content sections
                _buildSection(
                  context: context,
                  title: '1. Information We Collect',
                  content:
                      '''We collect information to provide personalized subliminal audio recommendations and improve the App.

Personal Information:
• Account Data: Email address, name, password (encrypted)
• Profile Data: Date of birth, gender (from onboarding), avatar emoji
• Preferences: Selected wellness goals during onboarding

Usage and Activity Data:
• Listening History: Sessions played, duration, timestamps
• User Interactions: 
  - Favorite session IDs
  - Completed session IDs
  - Playlist session IDs
  - Recent session IDs (last 10)
  - Total listening minutes
  - Daily sessions played count
• Account Status: Premium membership status, account type

Technical Information:
• Authentication: Firebase Auth tokens and user ID
• Device Data: Device type, OS version, app version
• Analytics: App usage via Firebase Analytics (anonymized)
• Timestamps: Account creation, last active date

Consent Records:
• Privacy consent acceptance
• Marketing consent preferences''',
                ),

                _buildSection(
                  context: context,
                  title: '2. How We Collect Information',
                  content:
                      '''• Directly from You: When you create an account, select preferences, or contact support
• Automatically: Through Firebase services when you use the App
• Third-Party Services: Firebase (Google) for authentication, database, and analytics''',
                ),

                _buildSection(
                  context: context,
                  title: '3. How We Use Your Information',
                  content: '''Service Delivery:
• Provide access to subliminal audio sessions
• Track your progress and listening history
• Maintain your favorites and playlists
• Enforce daily session limits (3 sessions/day for free users)

Personalization:
• Generate AI-powered recommendations
• Customize content based on your goals
• Remember preferences and recent sessions

Communication:
• Send OTP verification codes
• Welcome emails and service updates
• Marketing (only with explicit consent)

Service Improvement:
• Analyze usage patterns
• Fix bugs and technical issues
• Develop new features

Security and Compliance:
• Prevent fraud and unauthorized access
• Enforce Terms of Service
• Comply with legal obligations''',
                ),

                _buildSection(
                  context: context,
                  title: '4. Data Storage and Service Providers',
                  content: '''Firebase (Google):
• Purpose: Authentication, database (Firestore), storage, analytics
• Location: europe-west region
• Security: Industry-standard encryption

Email Services:
• Purpose: OTP verification, newsletters (with consent)
• Data Shared: Email address, name

All service providers are GDPR-compliant.''',
                ),

                _buildSection(
                  context: context,
                  title: '5. Data Sharing',
                  content:
                      '''We do not sell your personal data. We share data only:
• With service providers (Firebase, email)
• For legal requirements
• In case of business transfers (with notice)
• With your explicit consent
• As aggregated, anonymized insights''',
                ),

                _buildSection(
                  context: context,
                  title: '6. Data Security',
                  content: '''We implement:
• Encryption in transit (HTTPS/TLS)
• Encryption at rest (Firebase security)
• Access controls and authentication
• Regular security audits
• Secure password storage

Report breaches to: support@insidexapp.com''',
                ),

                _buildSection(
                  context: context,
                  title: '7. Data Retention',
                  content: '''• Active Accounts: Data retained while active
• Inactive Accounts: Deleted after 24 months
• Deleted Accounts: Data removed within 30 days
• Analytics: Anonymized after 14 months
• Legal Obligations: Some data retained as required by law''',
                ),

                _buildSection(
                  context: context,
                  title: '8. Your Rights (GDPR)',
                  content: '''You have the right to:
• Access your personal data
• Correct inaccurate data
• Request deletion ("right to be forgotten")
• Restrict processing
• Object to processing
• Data portability
• Withdraw consent anytime

Contact: support@insidexapp.com (response within 30 days)

You may lodge complaints with the UK ICO at ico.org.uk''',
                ),

                _buildSection(
                  context: context,
                  title: '9. International Data Transfers',
                  content: '''Data is stored in UK/EU (Firebase europe-west). 
Transfers outside EEA are protected by:
• Standard Contractual Clauses (SCCs)
• Adequacy decisions
• GDPR safeguards''',
                ),

                _buildSection(
                  context: context,
                  title: '10. Age Restriction',
                  content: '''The Services are for users 18+ only. 
We do not knowingly collect data from anyone under 18.
If we discover such data, we delete it immediately.

Parents: Contact support@insidexapp.com if you believe we have your child's data.''',
                ),

                _buildSection(
                  context: context,
                  title: '11. Cookies and Tracking',
                  content: '''The App uses:
• Essential cookies for authentication
• Firebase Analytics (can be disabled)
• No third-party advertising or tracking pixels''',
                ),

                _buildSection(
                  context: context,
                  title: '12. Changes to This Policy',
                  content:
                      '''We may update this policy. Material changes notified via:
• In-app notification
• Email (if provided)
• Update notice on app launch

Continued use constitutes acceptance.''',
                ),

                _buildSection(
                  context: context,
                  title: '13. Contact Information',
                  content: '''Data Controller:
ALZHAMI LTD
Company Number: 16545604
85 Great Portland Street, London, W1W 7LT

Contact:
General Inquiries: hello@insidexapp.com
Support: support@insidexapp.com
Phone: +44 7456 460096

Automated Emails: noreply@insidexapp.com
(Please do not reply to emails from this address)''',
                ),

                SizedBox(height: 32.h),

                // Compliance notice
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
                    'This policy complies with UK GDPR, Apple App Store guidelines, and Privacy Manifest requirements.',
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
