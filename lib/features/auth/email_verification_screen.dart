// lib/features/auth/email_verification_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../services/email_service.dart';
import '../../shared/widgets/primary_button.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final User? _user = FirebaseAuth.instance.currentUser;
  bool _isResending = false;
  bool _isChecking = false;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;
  Timer? _verificationCheckTimer;
  StreamSubscription<bool>? _verificationStream;

  @override
  void initState() {
    super.initState();
    _startVerificationCheck();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _verificationCheckTimer?.cancel();
    _verificationStream?.cancel();
    super.dispose();
  }

  void _startVerificationCheck() {
    // Check verification status every 3 seconds
    _verificationStream =
        EmailService.emailVerificationStream().listen((isVerified) {
      if (isVerified) {
        _onEmailVerified();
      }
    });
  }

  void _onEmailVerified() {
    // Cancel timers
    _verificationStream?.cancel();
    _verificationCheckTimer?.cancel();

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Email verified successfully! 🎉'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );

    // Navigate to home after a short delay
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    });
  }

  Future<void> _resendVerificationEmail() async {
    if (_resendCooldown > 0) return;

    setState(() => _isResending = true);

    final result = await EmailService.sendEmailVerification();

    if (!mounted) return;

    setState(() => _isResending = false);

    if (result['success']) {
      // Start cooldown timer (60 seconds)
      _startCooldownTimer();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification email sent! Check your inbox.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Failed to send email'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _startCooldownTimer() {
    setState(() => _resendCooldown = 60);

    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown > 0) {
        setState(() => _resendCooldown--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _checkVerificationManually() async {
    setState(() => _isChecking = true);

    final isVerified = await EmailService.isEmailVerified();

    setState(() => _isChecking = false);

    if (isVerified) {
      _onEmailVerified();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email not verified yet. Please check your inbox.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _changeEmail() async {
    // Navigate back to register or show email change dialog
    Navigator.pushReplacementNamed(context, AppRoutes.register);
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.welcome);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            children: [
              const Spacer(flex: 1),

              // Email Icon
              Container(
                width: 120.w,
                height: 120.w,
                decoration: BoxDecoration(
                  color: AppColors.primaryGold.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.mark_email_unread_outlined,
                  size: 60.sp,
                  color: AppColors.primaryGold,
                ),
              ),

              SizedBox(height: 32.h),

              // Title
              Text(
                'Verify Your Email',
                style: GoogleFonts.inter(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),

              SizedBox(height: 12.h),

              // Subtitle
              Text(
                'We\'ve sent a verification email to',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 8.h),

              // User Email
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: AppColors.greyLight,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  _user?.email ?? 'your-email@example.com',
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),

              SizedBox(height: 24.h),

              // Instructions
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue,
                      size: 24.sp,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Please check your email and click the verification link to activate your account.',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 32.h),

              // Check Verification Button
              PrimaryButton(
                text: 'I\'ve Verified My Email',
                onPressed: _checkVerificationManually,
                isLoading: _isChecking,
              ),

              SizedBox(height: 16.h),

              // Resend Email Button
              OutlinedButton(
                onPressed:
                    _resendCooldown > 0 ? null : _resendVerificationEmail,
                style: OutlinedButton.styleFrom(
                  minimumSize: Size(double.infinity, 48.h),
                  side: BorderSide(
                    color: _resendCooldown > 0
                        ? AppColors.greyBorder
                        : AppColors.primaryGold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: _isResending
                    ? SizedBox(
                        width: 20.w,
                        height: 20.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primaryGold,
                          ),
                        ),
                      )
                    : Text(
                        _resendCooldown > 0
                            ? 'Resend Email ($_resendCooldown s)'
                            : 'Resend Verification Email',
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: _resendCooldown > 0
                              ? AppColors.textSecondary
                              : AppColors.primaryGold,
                        ),
                      ),
              ),

              const Spacer(flex: 2),

              // Footer Actions
              Column(
                children: [
                  TextButton(
                    onPressed: _changeEmail,
                    child: Text(
                      'Wrong email? Change it',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        color: AppColors.textSecondary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _signOut,
                    child: Text(
                      'Sign Out',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }
}
