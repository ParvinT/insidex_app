// lib/features/auth/forgot_password_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/constants/app_colors.dart';
import '../../core/responsive/auth_scaffold.dart';
import '../../core/responsive/context_ext.dart';
import '../../core/utils/form_validators.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/widgets/primary_button.dart';
import '../../services/firebase_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _isEmailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await FirebaseService.resetPassword(
        _emailController.text.trim(),
      );

      if (!mounted) return;

      if (result['success']) {
        setState(() => _isEmailSent = true);
      } else {
        // Kullanıcı bulunamadı hatası için özel dialog
        if (result['code'] == 'user-not-found') {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
              title: Row(
                children: [
                  Icon(Icons.person_off, color: Colors.orange, size: 24.sp),
                  SizedBox(width: 12.w),
                  Text(
                    'Account Not Found',
                    style: GoogleFonts.inter(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              content: Text(
                'No account exists with this email address.\n\nWould you like to create a new account instead?',
                style: GoogleFonts.inter(fontSize: 14.sp, height: 1.5),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(color: AppColors.textSecondary),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pushReplacementNamed(context, '/auth/register');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGold,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: Text(
                    'Sign Up',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          // Diğer hatalar için normal SnackBar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Failed to send reset email'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleBackToLogin() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      bodyIsScrollable: true,
      body: SingleChildScrollView(
        padding:
            EdgeInsets.symmetric(horizontal: context.isTablet ? 32.w : 24.w),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: context.isDesktop ? 600 : double.infinity,
            ),
            child: _isEmailSent ? _buildSuccessView() : _buildResetForm(),
          ),
        ),
      ),
    );
  }

  Widget _buildResetForm() {
    // Sizin context extension'larınızı kullanıyoruz
    final isTablet = context.isTablet;
    final isDesktop = context.isDesktop;
    final isCompact = context.isCompactH;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: context.isTablet ? 40.h : 20.h),

          // Logo - responsive boyutlar
          SvgPicture.asset(
            'assets/images/logo.svg',
            width: isDesktop
                ? 160.w
                : isTablet
                    ? 140.w
                    : 120.w,
            height: isDesktop
                ? 53.h
                : isTablet
                    ? 47.h
                    : 40.h,
            colorFilter: const ColorFilter.mode(
              AppColors.textPrimary,
              BlendMode.srcIn,
            ),
          ),

          SizedBox(height: isCompact ? 32.h : 48.h),

          // Lock Icon
          Container(
            width: isTablet ? 90.w : 80.w,
            height: isTablet ? 90.w : 80.w,
            decoration: BoxDecoration(
              color: AppColors.primaryGold.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lock_reset_rounded,
              color: AppColors.primaryGold,
              size: isTablet ? 45.sp : 40.sp,
            ),
          ),

          SizedBox(height: isTablet ? 40.h : 32.h),

          // Title
          Text(
            'Forgot Password?',
            style: GoogleFonts.inter(
              fontSize:
                  isTablet ? 32.sp.clamp(28.0, 36.0) : 28.sp.clamp(24.0, 32.0),
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: isTablet ? 16.h : 12.h),

          // Description
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.isDesktop ? 60.w : 0,
            ),
            child: Text(
              'Don\'t worry! It happens. Please enter the email associated with your account.',
              style: GoogleFonts.inter(
                fontSize: isTablet ? 17.sp : 16.sp,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          SizedBox(height: isTablet ? 48.h : 40.h),

          // Email Field - Constrained width for desktop
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: context.isDesktop ? 500 : double.infinity,
            ),
            child: CustomTextField(
              controller: _emailController,
              label: 'Email Address',
              hint: 'Enter your email',
              keyboardType: TextInputType.emailAddress,
              validator: FormValidators.validateEmail,
              readOnly: _isLoading,
              suffixIcon: Icon(
                Icons.email_outlined,
                color: AppColors.textSecondary,
                size: isTablet ? 22.sp : 20.sp,
              ),
            ),
          ),

          SizedBox(height: isTablet ? 40.h : 32.h),

          // Submit Button - Constrained width for desktop
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: context.isDesktop ? 500 : double.infinity,
            ),
            child: PrimaryButton(
              text: 'Send Reset Link',
              onPressed: _handleResetPassword,
              isLoading: _isLoading,
              height: isTablet ? 56 : 48,
            ),
          ),

          SizedBox(height: isTablet ? 32.h : 24.h),

          // Back to Login
          TextButton(
            onPressed: _isLoading ? null : _handleBackToLogin,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.arrow_back,
                  size: isTablet ? 18.sp : 16.sp,
                  color: _isLoading
                      ? AppColors.textSecondary
                      : AppColors.primaryGold,
                ),
                SizedBox(width: 8.w),
                Text(
                  'Back to Login',
                  style: GoogleFonts.inter(
                    fontSize: isTablet ? 15.sp : 14.sp,
                    color: _isLoading
                        ? AppColors.textSecondary
                        : AppColors.primaryGold,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: isTablet ? 48.h : 40.h),

          // Security Note - Responsive width
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: context.isDesktop ? 600 : double.infinity,
            ),
            child: Container(
              padding: EdgeInsets.all(isTablet ? 20.w : 16.w),
              decoration: BoxDecoration(
                color: AppColors.greyLight.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: AppColors.greyBorder,
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.textSecondary,
                    size: isTablet ? 22.sp : 20.sp,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'For security reasons, we will send a password reset link to your registered email if it exists in our system.',
                      style: GoogleFonts.inter(
                        fontSize: isTablet ? 13.sp : 12.sp,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 40.h),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    // Context extension kullanımı (daha basit ve çalışıyor)
    final isTablet = context.isTablet;
    final isDesktop = context.isDesktop;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: isTablet ? 80.h : 60.h),

        // INSIDEX Logo at top
        SvgPicture.asset(
          'assets/images/logo.svg',
          width: isDesktop
              ? 160.w
              : isTablet
                  ? 140.w
                  : 120.w,
          height: isDesktop
              ? 53.h
              : isTablet
                  ? 47.h
                  : 40.h,
          colorFilter: const ColorFilter.mode(
            AppColors.textPrimary,
            BlendMode.srcIn,
          ),
        ),

        SizedBox(height: isTablet ? 48.h : 40.h),

        // Success Icon
        Container(
          width: isTablet ? 110.w : 100.w,
          height: isTablet ? 110.w : 100.w,
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.mark_email_read_outlined,
            color: Colors.green,
            size: isTablet ? 55.sp : 50.sp,
          ),
        ),

        SizedBox(height: isTablet ? 40.h : 32.h),

        // Success Title
        Text(
          'Check Your Email',
          style: GoogleFonts.inter(
            fontSize: isTablet ? 32.sp : 28.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),

        SizedBox(height: isTablet ? 20.h : 16.h),

        // Email Display
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 20.w : 16.w,
            vertical: isTablet ? 10.h : 8.h,
          ),
          decoration: BoxDecoration(
            color: AppColors.greyLight,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Text(
            _emailController.text,
            style: GoogleFonts.inter(
              fontSize: isTablet ? 17.sp : 16.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),

        SizedBox(height: isTablet ? 28.h : 24.h),

        // Success Message
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.isDesktop
                ? 80.w
                : isTablet
                    ? 40.w
                    : 20.w,
          ),
          child: Text(
            'We have sent a password reset link to your email address. Please check your inbox and follow the instructions.',
            style: GoogleFonts.inter(
              fontSize: isTablet ? 17.sp : 16.sp,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        SizedBox(height: isTablet ? 48.h : 40.h),

        // Check Spam Note - Responsive
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: context.isDesktop ? 600 : double.infinity,
          ),
          child: Container(
            margin: EdgeInsets.symmetric(
              horizontal: isTablet ? 32.w : 20.w,
            ),
            padding: EdgeInsets.all(isTablet ? 20.w : 16.w),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: Colors.orange.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: isTablet ? 22.sp : 20.sp,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Didn\'t receive the email?',
                        style: GoogleFonts.inter(
                          fontSize: isTablet ? 15.sp : 14.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Please check your spam folder or try resending the email after a few minutes.',
                        style: GoogleFonts.inter(
                          fontSize: isTablet ? 13.sp : 12.sp,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: isTablet ? 48.h : 40.h),

        // Back to Login Button - Constrained width
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: context.isDesktop ? 500 : double.infinity,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 32.w : 0,
            ),
            child: PrimaryButton(
              text: 'Back to Login',
              onPressed: _handleBackToLogin,
              height: isTablet ? 56 : 48,
            ),
          ),
        ),

        SizedBox(height: isTablet ? 20.h : 16.h),

        // Try Different Email Button
        TextButton(
          onPressed: _isLoading
              ? null
              : () {
                  setState(() => _isEmailSent = false);
                },
          child: Text(
            'Try Different Email',
            style: GoogleFonts.inter(
              fontSize: isTablet ? 15.sp : 14.sp,
              color: AppColors.primaryGold,
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.underline,
            ),
          ),
        ),

        SizedBox(height: isTablet ? 60.h : 40.h),
      ],
    );
  }
}
