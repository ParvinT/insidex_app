// lib/features/auth/otp_verification_screen.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../shared/widgets/primary_button.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String email;
  final String? name;
  final bool isNewUser;

  const OTPVerificationScreen({
    super.key,
    required this.email,
    this.name,
    this.isNewUser = true,
  });

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );

  final List<FocusNode> _focusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );

  String _verificationCode = '';
  bool _isVerifying = false;
  bool _isResending = false;
  int _resendCooldown = 60;
  Timer? _cooldownTimer;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _generateAndSendOTP();
    _startCooldownTimer();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  // Generate random 6-digit OTP
  String _generateOTP() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  // Store OTP in Firestore and queue email
  Future<void> _generateAndSendOTP() async {
    _verificationCode = _generateOTP();

    try {
      // Store OTP in Firestore with expiry
      await _firestore.collection('otp_verifications').doc(widget.email).set({
        'code': _verificationCode,
        'email': widget.email,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': DateTime.now().add(const Duration(minutes: 10)),
        'attempts': 0,
        'verified': false,
      });

      // Queue OTP email for sending
      await _firestore.collection('mail_queue').add({
        'to': widget.email,
        'template': {
          'name': 'otp_verification',
          'data': {
            'userName': widget.name ?? 'User',
            'otpCode': _verificationCode,
            'validMinutes': '10',
          },
        },
        'subject': 'Your INSIDEX Verification Code: $_verificationCode',
        'html': _getOTPEmailHTML(_verificationCode, widget.name ?? 'User'),
        'createdAt': FieldValue.serverTimestamp(),
        'type': 'otp',
      });

      debugPrint('OTP sent: $_verificationCode');
    } catch (e) {
      debugPrint('Error sending OTP: $e');
    }
  }

  // Verify entered OTP
  Future<void> _verifyOTP() async {
    // Combine all text field values
    String enteredCode = _controllers.map((c) => c.text).join();

    if (enteredCode.length != 6) {
      _showError('Please enter the complete 6-digit code');
      return;
    }

    setState(() => _isVerifying = true);

    try {
      // Get OTP document from Firestore
      final otpDoc = await _firestore
          .collection('otp_verifications')
          .doc(widget.email)
          .get();

      if (!otpDoc.exists) {
        _showError('Verification code expired. Please request a new one.');
        setState(() => _isVerifying = false);
        return;
      }

      final data = otpDoc.data()!;
      final storedCode = data['code'];
      final expiresAt = (data['expiresAt'] as Timestamp).toDate();
      final attempts = data['attempts'] ?? 0;

      // Check if code has expired
      if (DateTime.now().isAfter(expiresAt)) {
        _showError('Verification code expired. Please request a new one.');
        setState(() => _isVerifying = false);
        return;
      }

      // Check attempts (max 5)
      if (attempts >= 5) {
        _showError('Too many attempts. Please request a new code.');
        setState(() => _isVerifying = false);
        return;
      }

      // Verify code
      if (enteredCode == storedCode) {
        // Mark as verified
        await otpDoc.reference.update({
          'verified': true,
          'verifiedAt': FieldValue.serverTimestamp(),
        });

        // Update user's email verification status
        final user = _auth.currentUser;
        if (user != null) {
          await _firestore.collection('users').doc(user.uid).update({
            'emailVerified': true,
            'emailVerifiedAt': FieldValue.serverTimestamp(),
          });
        }

        // Success!
        _showSuccess('Email verified successfully!');

        // Navigate to home after delay
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pushReplacementNamed(context, AppRoutes.home);
          }
        });
      } else {
        // Wrong code - increment attempts
        await otpDoc.reference.update({
          'attempts': FieldValue.increment(1),
        });

        _showError('Invalid code. Please try again.');
        _clearFields();
      }
    } catch (e) {
      debugPrint('Error verifying OTP: $e');
      _showError('Verification failed. Please try again.');
    } finally {
      setState(() => _isVerifying = false);
    }
  }

  // Resend OTP
  Future<void> _resendOTP() async {
    if (_resendCooldown > 0) return;

    setState(() => _isResending = true);

    await _generateAndSendOTP();

    setState(() => _isResending = false);

    _showSuccess('New verification code sent!');
    _startCooldownTimer();
    _clearFields();
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

  void _clearFields() {
    for (var controller in _controllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  // OTP Email HTML Template
  String _getOTPEmailHTML(String otpCode, String userName) {
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; line-height: 1.6; color: #333; margin: 0; padding: 0; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 40px 30px; text-align: center; border-radius: 10px 10px 0 0; }
        .content { background: white; padding: 40px 30px; border: 1px solid #e0e0e0; border-radius: 0 0 10px 10px; }
        .otp-box { background: #f8f9fa; border: 2px dashed #667eea; border-radius: 10px; padding: 25px; margin: 30px 0; text-align: center; }
        .otp-code { font-size: 36px; font-weight: bold; color: #667eea; letter-spacing: 8px; font-family: 'Courier New', monospace; }
        .info-box { background: #fff3cd; border-left: 4px solid #ffc107; padding: 15px; margin: 20px 0; }
        .footer { text-align: center; padding: 20px; color: #888; font-size: 14px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1 style="margin: 0;">INSIDEX</h1>
            <p style="margin: 10px 0 0 0;">Email Verification</p>
        </div>
        
        <div class="content">
            <h2>Hello $userName!</h2>
            
            <p>Thank you for signing up with INSIDEX. To complete your registration, please enter the following verification code in the app:</p>
            
            <div class="otp-box">
                <div class="otp-code">$otpCode</div>
                <p style="margin: 10px 0 0 0; color: #666; font-size: 14px;">Enter this code in the app</p>
            </div>
            
            <div class="info-box">
                <p style="margin: 0;"><strong>⏱️ This code expires in 10 minutes</strong></p>
                <p style="margin: 5px 0 0 0;">For security reasons, do not share this code with anyone.</p>
            </div>
            
            <p>If you didn't request this code, please ignore this email.</p>
            
            <p>Need help? Contact us at support@insidex.app</p>
            
            <p>Best regards,<br>
            <strong>The INSIDEX Team</strong></p>
        </div>
        
        <div class="footer">
            <p>© 2025 INSIDEX. All rights reserved.</p>
        </div>
    </div>
</body>
</html>
    ''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            children: [
              const Spacer(flex: 1),

              // Icon
              Container(
                width: 100.w,
                height: 100.w,
                decoration: BoxDecoration(
                  color: AppColors.primaryGold.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.email_outlined,
                  size: 50.sp,
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
                'Enter the 6-digit code sent to',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                ),
              ),

              SizedBox(height: 8.h),

              Text(
                widget.email,
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),

              SizedBox(height: 40.h),

              // OTP Input Fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 45.w,
                    height: 55.h,
                    child: TextFormField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: GoogleFonts.inter(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: AppColors.greyLight,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: const BorderSide(
                            color: AppColors.greyBorder,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: const BorderSide(
                            color: AppColors.primaryGold,
                            width: 2,
                          ),
                        ),
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      onChanged: (value) {
                        if (value.isNotEmpty && index < 5) {
                          _focusNodes[index + 1].requestFocus();
                        }
                        if (value.isEmpty && index > 0) {
                          _focusNodes[index - 1].requestFocus();
                        }

                        // Auto-verify when all fields are filled
                        if (_controllers.every((c) => c.text.isNotEmpty)) {
                          _verifyOTP();
                        }
                      },
                    ),
                  );
                }),
              ),

              SizedBox(height: 40.h),

              // Verify Button
              PrimaryButton(
                text: 'Verify Code',
                onPressed: _verifyOTP,
                isLoading: _isVerifying,
              ),

              SizedBox(height: 20.h),

              // Resend Code
              TextButton(
                onPressed: _resendCooldown > 0 ? null : _resendOTP,
                child: Text(
                  _resendCooldown > 0
                      ? 'Resend code in $_resendCooldown s'
                      : 'Resend Code',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: _resendCooldown > 0
                        ? AppColors.textSecondary
                        : AppColors.primaryGold,
                  ),
                ),
              ),

              const Spacer(flex: 2),

              // Info Text
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue,
                      size: 20.sp,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        'Code expires in 10 minutes',
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 32.h),
            ],
          ),
        ),
      ),
    );
  }
}
