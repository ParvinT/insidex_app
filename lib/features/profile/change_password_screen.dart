// lib/features/profile/change_password_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/form_validators.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../core/utils/firebase_error_handler.dart';
import '../../shared/widgets/primary_button.dart';
import '../../core/responsive/context_ext.dart';
import '../../services/firebase_service.dart';
import '../../shared/widgets/animated_background.dart';
import '../../l10n/app_localizations.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  // Password strength tracking
  double _passwordStrength = 0.0;
  String _passwordStrengthText = '';
  Color _passwordStrengthColor = Colors.red;

  // Password requirements tracking
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasNumber = false;
  bool _isDifferent = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _checkPasswordStrength(String password) {
    // Update requirement checks
    setState(() {
      _hasMinLength = password.length >= 8;
      _hasUppercase = password.contains(RegExp(r'[A-Z]'));
      _hasLowercase = password.contains(RegExp(r'[a-z]'));
      _hasNumber = password.contains(RegExp(r'[0-9]'));
      _isDifferent =
          password.isEmpty || password != _currentPasswordController.text;
    });

    double strength = 0;
    String strengthText = '';
    Color strengthColor = Colors.red;

    if (password.isEmpty) {
      setState(() {
        _passwordStrength = 0;
        _passwordStrengthText = '';
        _passwordStrengthColor = Colors.red;
      });
      return;
    }

    // Check criteria
    if (password.length >= 8) strength += 0.2;
    if (password.length >= 12) strength += 0.1;
    if (password.contains(RegExp(r'[A-Z]'))) strength += 0.2;
    if (password.contains(RegExp(r'[a-z]'))) strength += 0.2;
    if (password.contains(RegExp(r'[0-9]'))) strength += 0.2;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength += 0.1;

    strength = strength.clamp(0.0, 1.0);

    // Determine strength text and color
    if (strength <= 0.25) {
      strengthText = AppLocalizations.of(context).weak;
      strengthColor = const Color(0xFFE74C3C);
    } else if (strength <= 0.5) {
      strengthText = AppLocalizations.of(context).fair;
      strengthColor = const Color(0xFFE67E22);
    } else if (strength <= 0.75) {
      strengthText = AppLocalizations.of(context).good;
      strengthColor = const Color(0xFFF39C12);
    } else {
      strengthText = AppLocalizations.of(context).strong;
      strengthColor = const Color(0xFF27AE60);
    }

    setState(() {
      _passwordStrength = strength;
      _passwordStrengthText = strengthText;
      _passwordStrengthColor = strengthColor;
    });
  }

  Future<void> _handleChangePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Use FirebaseService
      final result = await FirebaseService.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if (!mounted) return;

      if (result['success']) {
        _showSuccessDialog();
      } else {
        final errorMessage = FirebaseErrorHandler.getErrorMessage(
          result['code'],
          context,
        );
        _showErrorDialog(errorMessage);
      }
    } catch (e) {
      _showErrorDialog(
        AppLocalizations.of(context).unexpectedErrorOccurred,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 24.sp),
            SizedBox(width: 12.w),
            Flexible(
              child: Text(
                AppLocalizations.of(context).error,
                style: GoogleFonts.inter(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: GoogleFonts.inter(fontSize: 14.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context).ok,
              style: GoogleFonts.inter(
                color: AppColors.primaryGold,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60.w.clamp(60.0, 80.0),
              height: 60.w.clamp(60.0, 80.0),
              decoration: BoxDecoration(
                color: AppColors.primaryGold.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: AppColors.primaryGold,
                size: 36.sp.clamp(36.0, 48.0),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              AppLocalizations.of(context).passwordChanged,
              style: GoogleFonts.inter(
                fontSize: 18.sp.clamp(18.0, 22.0),
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              AppLocalizations.of(context).passwordChangedSuccess,
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 20.w.clamp(20.0, 30.0),
                vertical: 10.h.clamp(10.0, 14.0),
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryGold,
                borderRadius: BorderRadius.circular(25.r),
              ),
              child: Text(
                AppLocalizations.of(context).done,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use context extensions
    final isMobile = context.isMobile;
    final isTablet = context.isTablet;
    final isDesktop = context.isDesktop;
    final isCompact = context.isCompactH;

    // Calculate responsive sizes
    final screenWidth = context.w;
    final screenHeight = context.h;

    // Adaptive sizing
    final double horizontalPadding = isDesktop
        ? 40.w.clamp(40.0, 60.0)
        : isTablet
            ? 32.w.clamp(24.0, 40.0)
            : 20.w.clamp(16.0, 24.0);

    final double maxFormWidth = isDesktop
        ? 500.0
        : isTablet
            ? 450.0
            : double.infinity;

    final double logoWidth = isDesktop
        ? 120.w.clamp(100.0, 140.0)
        : isTablet
            ? 100.w.clamp(80.0, 120.0)
            : 80.w.clamp(70.0, 100.0);

    final double logoHeight = logoWidth * 0.33; // Maintain aspect ratio

    // Text sizes with clamp to prevent overflow
    final double titleSize =
        isTablet ? 24.sp.clamp(22.0, 28.0) : 22.sp.clamp(20.0, 24.0);

    final double bodyTextSize =
        isTablet ? 14.sp.clamp(13.0, 15.0) : 13.sp.clamp(12.0, 14.0);

    return AnimatedBackground(
      type: AnimationType.particles,
      opacity: 0.1,
      color: AppColors.primaryGold,
      particleCount: 10,
      enableOnMobile: true,
      child: Scaffold(
        backgroundColor: Colors.white.withOpacity(0.9),
        body: Stack(
          children: [
            // Main Content
            SafeArea(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxFormWidth),
                    child: Column(
                      children: [
                        // Header
                        SizedBox(height: isCompact ? 12.h : 20.h),

                        // Back Button and Logo
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Back button
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: Container(
                                padding: EdgeInsets.all(8.w.clamp(6.0, 10.0)),
                                decoration: BoxDecoration(
                                  color: AppColors.backgroundWhite,
                                  borderRadius: BorderRadius.circular(10.r),
                                  border: Border.all(
                                    color: AppColors.greyBorder,
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.arrow_back,
                                  color: AppColors.textPrimary,
                                  size: 18.sp.clamp(16.0, 22.0),
                                ),
                              ),
                            ),

                            // Logo
                            SvgPicture.asset(
                              'assets/images/logo.svg',
                              width: logoWidth,
                              height: logoHeight,
                              colorFilter: const ColorFilter.mode(
                                AppColors.textPrimary,
                                BlendMode.srcIn,
                              ),
                            ),

                            // Spacer
                            SizedBox(width: 40.w.clamp(36.0, 48.0)),
                          ],
                        ),

                        SizedBox(height: isCompact ? 20.h : 32.h),

                        // Title Card
                        Container(
                          padding: EdgeInsets.all(
                              isTablet ? 20.w.clamp(16.0, 24.0) : 16.w),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundWhite,
                            borderRadius: BorderRadius.circular(16.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 15,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Lock Icon
                              Container(
                                width: isTablet
                                    ? 56.w.clamp(50.0, 70.0)
                                    : 50.w.clamp(45.0, 60.0),
                                height: isTablet
                                    ? 56.w.clamp(50.0, 70.0)
                                    : 50.w.clamp(45.0, 60.0),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primaryGold.withOpacity(0.1),
                                      AppColors.primaryGold.withOpacity(0.05),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.lock_outline,
                                  color: AppColors.primaryGold,
                                  size: isTablet
                                      ? 28.sp.clamp(24.0, 35.0)
                                      : 24.sp.clamp(22.0, 30.0),
                                ),
                              ),

                              SizedBox(height: 12.h),

                              Text(
                                AppLocalizations.of(context)
                                    .changePasswordTitle,
                                style: GoogleFonts.inter(
                                  fontSize: titleSize,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),

                              SizedBox(height: 8.h),

                              Text(
                                AppLocalizations.of(context)
                                    .createStrongPassword,
                                style: GoogleFonts.inter(
                                  fontSize: bodyTextSize,
                                  color: AppColors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: isCompact ? 20.h : 28.h),

                        // Form Card
                        Container(
                          padding: EdgeInsets.all(isTablet
                              ? 24.w.clamp(20.0, 32.0)
                              : 20.w.clamp(16.0, 24.0)),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundWhite,
                            borderRadius: BorderRadius.circular(16.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 15,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Current Password
                                CustomTextField(
                                  controller: _currentPasswordController,
                                  label: AppLocalizations.of(context)
                                      .currentPassword,
                                  hint: AppLocalizations.of(context)
                                      .enterCurrentPassword,
                                  obscureText: !_isCurrentPasswordVisible,
                                  validator: (value) =>
                                      FormValidators.validatePassword(
                                          value, context),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isCurrentPasswordVisible
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: AppColors.textSecondary,
                                      size: 18.sp.clamp(16.0, 20.0),
                                    ),
                                    onPressed: () {
                                      setState(() => _isCurrentPasswordVisible =
                                          !_isCurrentPasswordVisible);
                                    },
                                  ),
                                ),

                                SizedBox(height: 16.h),

                                // New Password
                                CustomTextField(
                                  controller: _newPasswordController,
                                  label:
                                      AppLocalizations.of(context).newPassword,
                                  hint: AppLocalizations.of(context)
                                      .minCharacters,
                                  obscureText: !_isNewPasswordVisible,
                                  onChanged: (value) {
                                    _checkPasswordStrength(value);
                                    // Check if same as current password for warning
                                    if (value.isNotEmpty &&
                                        value ==
                                            _currentPasswordController.text) {
                                      // Show snackbar instead of inline error for better UX
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Row(
                                            children: [
                                              const Icon(Icons.warning,
                                                  color: Colors.white,
                                                  size: 20),
                                              const SizedBox(width: 8),
                                              Flexible(
                                                child: Text(
                                                  AppLocalizations.of(context)
                                                      .newPasswordMustBeDifferent,
                                                  style: GoogleFonts.inter(
                                                      fontSize: 13.sp),
                                                ),
                                              ),
                                            ],
                                          ),
                                          backgroundColor: Colors.orange,
                                          duration: const Duration(seconds: 3),
                                          behavior: SnackBarBehavior.floating,
                                          margin: EdgeInsets.all(20.w),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10.r),
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  validator: (value) {
                                    // Check if same as current
                                    if (value != null &&
                                        value ==
                                            _currentPasswordController.text) {
                                      return AppLocalizations.of(context)
                                          .mustBeDifferent; // Short message
                                    }
                                    // Then apply strong password validation
                                    return FormValidators
                                        .validateStrongPassword(value, context);
                                  },
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isNewPasswordVisible
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: AppColors.textSecondary,
                                      size: 18.sp.clamp(16.0, 20.0),
                                    ),
                                    onPressed: () {
                                      setState(() => _isNewPasswordVisible =
                                          !_isNewPasswordVisible);
                                    },
                                  ),
                                ),

                                // Password Strength Indicator
                                if (_passwordStrength > 0) ...[
                                  SizedBox(height: 12.h),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            AppLocalizations.of(context)
                                                .passwordStrength,
                                            style: GoogleFonts.inter(
                                              fontSize: 11.sp.clamp(10.0, 12.0),
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                          Text(
                                            _passwordStrengthText,
                                            style: GoogleFonts.inter(
                                              fontSize: 11.sp.clamp(10.0, 12.0),
                                              color: _passwordStrengthColor,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 6.h),
                                      ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(4.r),
                                        child: LinearProgressIndicator(
                                          value: _passwordStrength,
                                          backgroundColor: AppColors.greyLight,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  _passwordStrengthColor),
                                          minHeight: 5.h.clamp(4.0, 6.0),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],

                                SizedBox(height: 16.h),

                                // Confirm Password
                                CustomTextField(
                                  controller: _confirmPasswordController,
                                  label: AppLocalizations.of(context)
                                      .confirmNewPassword,
                                  hint: AppLocalizations.of(context)
                                      .reenterNewPassword,
                                  obscureText: !_isConfirmPasswordVisible,
                                  validator: (value) =>
                                      FormValidators.validateConfirmPassword(
                                    value,
                                    _newPasswordController.text,
                                    context,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isConfirmPasswordVisible
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: AppColors.textSecondary,
                                      size: 18.sp.clamp(16.0, 20.0),
                                    ),
                                    onPressed: () {
                                      setState(() => _isConfirmPasswordVisible =
                                          !_isConfirmPasswordVisible);
                                    },
                                  ),
                                ),

                                SizedBox(height: 24.h),

                                // Submit Button
                                PrimaryButton(
                                  text: AppLocalizations.of(context)
                                      .updatePassword,
                                  onPressed: _handleChangePassword,
                                  isLoading: _isLoading,
                                  height: isTablet
                                      ? 52.h.clamp(48.0, 56.0)
                                      : 48.h.clamp(44.0, 52.0),
                                ),

                                SizedBox(height: 16.h),

                                // Password Requirements
                                Container(
                                  padding:
                                      EdgeInsets.all(12.w.clamp(10.0, 16.0)),
                                  decoration: BoxDecoration(
                                    color: AppColors.greyLight.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(10.r),
                                    border: Border.all(
                                      color: AppColors.greyBorder,
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.info_outline,
                                            color: AppColors.textSecondary,
                                            size: 14.sp.clamp(12.0, 16.0),
                                          ),
                                          SizedBox(width: 6.w),
                                          Text(
                                            AppLocalizations.of(context)
                                                .passwordRequirements,
                                            style: GoogleFonts.inter(
                                              fontSize: 12.sp.clamp(11.0, 13.0),
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 8.h),
                                      _buildRequirement(
                                          AppLocalizations.of(context)
                                              .atLeast8Characters,
                                          isMet: _hasMinLength),
                                      _buildRequirement(
                                          AppLocalizations.of(context)
                                              .oneUppercaseLetter,
                                          isMet: _hasUppercase),
                                      _buildRequirement(
                                          AppLocalizations.of(context)
                                              .oneLowercaseLetter,
                                          isMet: _hasLowercase),
                                      _buildRequirement(
                                          AppLocalizations.of(context)
                                              .oneNumber,
                                          isMet: _hasNumber),
                                      _buildRequirement(
                                          AppLocalizations.of(context)
                                              .differentFromCurrent,
                                          isMet: _isDifferent),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: 32.h),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequirement(String text, {bool? isMet}) {
    final bool showStatus =
        isMet != null && _newPasswordController.text.isNotEmpty;
    final Color iconColor = showStatus
        ? (isMet! ? const Color(0xFF27AE60) : const Color(0xFFE74C3C))
        : AppColors.textLight;

    final IconData iconData = showStatus
        ? (isMet! ? Icons.check_circle : Icons.cancel)
        : Icons.circle_outlined;

    return Padding(
      padding: EdgeInsets.only(top: 3.h),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              iconData,
              key: ValueKey(iconData),
              color: iconColor,
              size: 12.sp.clamp(11.0, 14.0),
            ),
          ),
          SizedBox(width: 6.w),
          Flexible(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 11.sp.clamp(10.0, 12.0),
                color: showStatus && isMet!
                    ? const Color(0xFF27AE60)
                    : AppColors.textSecondary,
                fontWeight:
                    showStatus && isMet! ? FontWeight.w500 : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
