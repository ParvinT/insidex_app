// lib/features/premium/premium_waitlist_screen.dart

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/user_provider.dart';
import '../legal/privacy_policy_screen.dart';
import 'dart:math' as math;

class PremiumWaitlistScreen extends StatefulWidget {
  const PremiumWaitlistScreen({super.key});

  @override
  State<PremiumWaitlistScreen> createState() => _PremiumWaitlistScreenState();
}

class _PremiumWaitlistScreenState extends State<PremiumWaitlistScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final PageController _pageController = PageController();

  bool _agreedToPrivacy = false;
  bool _agreedToMarketing = false;
  bool _isSubmitting = false;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    // Pre-fill email if user is logged in
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _emailController.text = currentUser.email ?? '';
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _submitWaitlist() async {
    // Validate form
    if (!_formKey.currentState!.validate()) return;

    // Check privacy consent
    if (!_agreedToPrivacy) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the Privacy Policy'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Add to waitlist
      await FirebaseFirestore.instance.collection('waitlist').add({
        'email': _emailController.text.trim(),
        'joinedAt': FieldValue.serverTimestamp(),
        'privacyConsent': true,
        'marketingConsent': _agreedToMarketing,
        'consentDate': DateTime.now().toIso8601String(),
        'source': 'app',
        'userId': FirebaseAuth.instance.currentUser?.uid,
        'notified': false,
      });

      // Update user's marketing consent if logged in
      if (FirebaseAuth.instance.currentUser != null && mounted) {
        await context
            .read<UserProvider>()
            .updateMarketingConsent(_agreedToMarketing);
      }

      // Show success
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                '🎉 You\'re on the waitlist! We\'ll notify you when Premium launches.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );

        // Navigate back after delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final bool _isCompactH = mq.size.height <= 740;
    return MediaQuery(
        data: _isCompactH
            ? mq.copyWith(textScaler: const TextScaler.linear(1.0))
            : mq,
        child: Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF667eea),
                  const Color(0xFF764ba2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Close button
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),

                  // Premium Features Showcase - Sabit üst kısım
                  Flexible(
                    flex: 2,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: 150, // Minimum yükseklik
                            maxHeight: constraints
                                .maxHeight, // Flexible'ın verdiği max alan
                          ),
                          child: PageView(
                              controller: _pageController,
                              onPageChanged: (index) {
                                setState(() => _currentPage = index);
                              },
                              children: [
                                _buildFeatureCard(
                                  icon: Icons.download_rounded,
                                  title: 'Unlimited Offline Downloads',
                                  description:
                                      'Download all sessions and listen anywhere, anytime',
                                ),
                                _buildFeatureCard(
                                  icon: Icons.all_inclusive,
                                  title: 'Access All Sessions',
                                  description:
                                      'Unlock our entire library of premium sessions',
                                ),
                                _buildFeatureCard(
                                  icon: Icons.analytics_outlined,
                                  title: 'Advanced Progress Tracking',
                                  description:
                                      'Get detailed insights into your healing journey',
                                ),
                              ]),
                        );
                      },
                    ),
                  ),

                  // Page indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      return Container(
                        margin: EdgeInsets.symmetric(horizontal: 4.w),
                        width: _currentPage == index ? 24.w : 8.w,
                        height: 8.h,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? Colors.white
                              : Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      );
                    }),
                  ),

                  SizedBox(height: _isCompactH ? 8.h : 20.h),

                  // Waitlist Form - Expanded ile scroll edilebilir
                  Flexible(
                    flex: 3,
                    child: Container(
                      margin: EdgeInsets.only(left: 20.w, right: 20.w, top: 0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20.r),
                          topRight: Radius.circular(20.r),
                        ),
                      ),
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(20.w, 20.w, 20.w, 40.w),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Premium Coming Soon!',
                                style: GoogleFonts.inter(
                                  fontSize: _isCompactH ? 18.sp : 20.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),

                              SizedBox(height: 8.h),

                              Text(
                                'Be the first to know when we launch',
                                style: GoogleFonts.inter(
                                  fontSize: 14.sp.clamp(14, 18),
                                  color: AppColors.textSecondary,
                                ),
                              ),

                              SizedBox(height: 24.h),

                              // Email field
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  labelText: 'Email Address',
                                  prefixIcon: Icon(Icons.email_outlined),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  if (!RegExp(
                                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                      .hasMatch(value)) {
                                    return 'Please enter a valid email';
                                  }
                                  return null;
                                },
                              ),

                              SizedBox(height: 12.h),

                              // Privacy Policy consent (Required)
                              ConstrainedBox(
                                constraints: BoxConstraints(minHeight: 40.h),
                                child: CheckboxListTile(
                                  value: _agreedToPrivacy,
                                  onChanged: (value) {
                                    setState(() => _agreedToPrivacy = value!);
                                  },
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                  title: RichText(
                                    text: TextSpan(
                                      style: GoogleFonts.inter(
                                        fontSize: 12.sp,
                                        color: AppColors.textPrimary,
                                      ),
                                      children: [
                                        const TextSpan(text: 'I agree to the '),
                                        TextSpan(
                                          text: 'Privacy Policy',
                                          style: const TextStyle(
                                            color: Color(0xFF667eea),
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                          recognizer: TapGestureRecognizer()
                                            ..onTap = () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      const PrivacyPolicyScreen(),
                                                ),
                                              );
                                            },
                                        ),
                                        const TextSpan(
                                          text: ' *',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // Marketing consent (Optional)
                              ConstrainedBox(
                                constraints: BoxConstraints(minHeight: 40.h),
                                child: CheckboxListTile(
                                  value: _agreedToMarketing,
                                  onChanged: (value) {
                                    setState(() => _agreedToMarketing = value!);
                                  },
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                  title: Text(
                                    'Send me exclusive offers and updates',
                                    style: GoogleFonts.inter(
                                      fontSize: 12.sp,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(height: 16.h),

                              // Submit button
                              Container(
                                width: double.infinity,
                                height: 80.h.clamp(52.0, 85.0),
                                margin: EdgeInsets.symmetric(vertical: 8.h),
                                child: ElevatedButton(
                                  onPressed: _isSubmitting || !_agreedToPrivacy
                                      ? null
                                      : _submitWaitlist,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF667eea),
                                    disabledBackgroundColor: Colors.grey[400],
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                  ),
                                  child: _isSubmitting
                                      ? SizedBox(
                                          width: 20.w,
                                          height: 20.w,
                                          child:
                                              const CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(
                                          'Join Early Access Waitlist',
                                          style: GoogleFonts.inter(
                                            fontSize: 16.sp.clamp(16.0, 28.0),
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),

                              SizedBox(height: 8.h),

                              // Unsubscribe info
                              Text(
                                'You can unsubscribe at any time',
                                style: GoogleFonts.inter(
                                  fontSize: 11.sp,
                                  color: AppColors.textLight,
                                ),
                              ),

                              // Extra bottom padding for safety
                              SizedBox(
                                  height:
                                      MediaQuery.of(context).padding.bottom +
                                          20.h),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ));
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    final mq = MediaQuery.of(context);
    final bool _isCompactH = mq.size.height <= 740;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 40.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: math.min(60.w, 60.h),
            height: math.min(60.w, 60.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Icon(
              icon,
              size: math.min(32.sp, math.min(60.w, 60.h) * 0.6),
              color: Colors.white,
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: _isCompactH ? 16.sp : 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10.h),
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: _isCompactH ? 13.sp : 14.sp,
              color: Colors.white.withOpacity(0.9),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
