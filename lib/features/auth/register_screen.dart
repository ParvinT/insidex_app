// lib/features/auth/register_screen.dart

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../../core/themes/app_theme_extension.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/form_validators.dart';
import '../../core/utils/firebase_error_handler.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/widgets/primary_button.dart';
import '../../services/firebase_service.dart';
import 'otp_verification_screen.dart';
import '../../core/responsive/auth_scaffold.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/password_requirements_widget.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _showPasswordRequirements = false;
  bool _agreeToTerms = false;

  // Separate loading states for each button
  bool _isEmailLoading = false;
  final bool _isGoogleLoading = false;
  final bool _isAppleLoading = false;

  // Birth date fields
  bool _showBirthDatePicker = true;
  DateTime? _selectedBirthDate;

  @override
  void initState() {
    super.initState();
    _checkExistingBirthDate();
  }

  Future<void> _checkExistingBirthDate() async {
    final prefs = await SharedPreferences.getInstance();
    final birthDateString = prefs.getString('birthDate');

    if (mounted) {
      setState(() {
        if (birthDateString != null) {
          _selectedBirthDate = DateTime.parse(birthDateString);
          _showBirthDatePicker = false;
        } else {
          _showBirthDatePicker = true;
        }
      });
    }
  }

  int? get _userAge {
    if (_selectedBirthDate == null) return null;
    final now = DateTime.now();
    int age = now.year - _selectedBirthDate!.year;
    final hadBirthday = (now.month > _selectedBirthDate!.month) ||
        (now.month == _selectedBirthDate!.month &&
            now.day >= _selectedBirthDate!.day);
    if (!hadBirthday) age -= 1;
    return age;
  }

  bool get _isAgeValid => (_userAge ?? 0) >= 18;

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  void _showDatePicker() {
    final colors = context.colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SizedBox(
        height: 300,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(AppLocalizations.of(context).cancel),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(AppLocalizations.of(context).done),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: _selectedBirthDate ?? DateTime(2000, 1, 1),
                maximumDate: DateTime.now(),
                minimumDate: DateTime(1920),
                onDateTimeChanged: (date) {
                  setState(() => _selectedBirthDate = date);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    // Validate form fields
    if (!_formKey.currentState!.validate()) return;

    // Check if passwords match
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).passwordsDoNotMatch),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check terms and conditions agreement
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).pleaseAgreeToTerms),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Check birth date if shown
    if (_showBirthDatePicker) {
      if (_selectedBirthDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).pleaseSelectBirthDate),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      if (!_isAgeValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).youMustBeAtLeast18),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Save to SharedPreferences for later use
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('birthDate', _selectedBirthDate!.toIso8601String());
      await prefs.setInt('userAge', _userAge!);
    }

    setState(() => _isEmailLoading = true);

    // Only create OTP record, NOT Firebase Auth account
    final result = await FirebaseService.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      name: _nameController.text.trim(),
    );

    setState(() => _isEmailLoading = false);

    if (!mounted) return;

    if (result['success']) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).verificationCodeSent),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      // Navigate to OTP verification screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OTPVerificationScreen(
            email: _emailController.text.trim(),
          ),
        ),
      );
    } else {
      final errorMessage = FirebaseErrorHandler.getErrorMessage(
        result['code'],
        context,
      );
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // Check if any loading is active
    final bool isAnyLoading =
        _isEmailLoading || _isGoogleLoading || _isAppleLoading;

    return AuthScaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20.h),

                // Logo
                Center(
                  child: SvgPicture.asset(
                    'assets/images/logo.svg',
                    width: 120.w,
                    height: 40.h,
                    colorFilter: ColorFilter.mode(
                      colors.textPrimary,
                      BlendMode.srcIn,
                    ),
                  ),
                ),

                SizedBox(height: 40.h),

                // Create Account Title
                Text(
                  AppLocalizations.of(context).createAccount,
                  style: GoogleFonts.inter(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),

                SizedBox(height: 8.h),

                // Subtitle
                Text(
                  AppLocalizations.of(context).startYourHealingJourney,
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    color: colors.textSecondary,
                  ),
                ),

                SizedBox(height: 32.h),

                // Full Name Input Field
                CustomTextField(
                  controller: _nameController,
                  label: AppLocalizations.of(context).fullName,
                  hint: AppLocalizations.of(context).enterYourFullName,
                  validator: (value) =>
                      FormValidators.validateName(value, context),
                  suffixIcon: Icon(
                    Icons.person_outline,
                    color: colors.textSecondary,
                    size: 20.sp,
                  ),
                ),

                SizedBox(height: 16.h),

                // Email Input Field
                CustomTextField(
                  controller: _emailController,
                  label: AppLocalizations.of(context).email,
                  hint: AppLocalizations.of(context).enterYourEmail,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) =>
                      FormValidators.validateEmail(value, context),
                  suffixIcon: Icon(
                    Icons.email_outlined,
                    color: colors.textSecondary,
                    size: 20.sp,
                  ),
                ),

                SizedBox(height: 16.h),

                // Password Input Field
                CustomTextField(
                  controller: _passwordController,
                  label: AppLocalizations.of(context).password,
                  hint: AppLocalizations.of(context).createAPassword,
                  obscureText: !_isPasswordVisible,
                  validator: (value) =>
                      FormValidators.validateStrongPassword(value, context),
                  onChanged: (value) {
                    setState(() {
                      _showPasswordRequirements = value.isNotEmpty;
                    });
                  },
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: colors.textSecondary,
                      size: 20.sp,
                    ),
                    onPressed: () {
                      setState(() => _isPasswordVisible = !_isPasswordVisible);
                    },
                  ),
                ),
                if (_showPasswordRequirements) ...[
                  SizedBox(height: 12.h),
                  PasswordRequirementsWidget(
                    password: _passwordController.text,
                  ),
                ],
                SizedBox(height: 16.h),

                // Confirm Password Input Field
                CustomTextField(
                  controller: _confirmPasswordController,
                  label: AppLocalizations.of(context).confirmPassword,
                  hint: AppLocalizations.of(context).reenterYourPassword,
                  obscureText: !_isConfirmPasswordVisible,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(context).pleaseConfirmPassword;
                    }
                    if (value != _passwordController.text) {
                      return AppLocalizations.of(context).passwordsDoNotMatch;
                    }
                    return null;
                  },
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmPasswordVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: colors.textSecondary,
                      size: 20.sp,
                    ),
                    onPressed: () {
                      setState(() => _isConfirmPasswordVisible =
                          !_isConfirmPasswordVisible);
                    },
                  ),
                ),

                SizedBox(height: 20.h),

                // Birth Date Picker (conditional)
                if (_showBirthDatePicker) ...[
                  SizedBox(height: 16.h),

                  Text(
                    AppLocalizations.of(context).dateOfBirth,
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: colors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8.h),

                  GestureDetector(
                    onTap: isAnyLoading ? null : _showDatePicker,
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 14.h),
                      decoration: BoxDecoration(
                        color: colors.backgroundCard,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: _selectedBirthDate != null
                              ? (_isAgeValid ? colors.textPrimary : Colors.red)
                              : colors.border,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedBirthDate != null
                                ? _formatDate(_selectedBirthDate!)
                                : AppLocalizations.of(context)
                                    .selectYourBirthDate,
                            style: GoogleFonts.inter(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w500,
                              color: _selectedBirthDate != null
                                  ? colors.textPrimary
                                  : colors.textSecondary,
                            ),
                          ),
                          Icon(
                            Icons.calendar_today_outlined,
                            color: colors.textSecondary,
                            size: 20.sp,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Age validation feedback
                  if (_selectedBirthDate != null) ...[
                    SizedBox(height: 8.h),
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: _isAgeValid
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: _isAgeValid ? Colors.green : Colors.red,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isAgeValid ? Icons.check_circle : Icons.error,
                            color: _isAgeValid ? Colors.green : Colors.red,
                            size: 18.sp,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            _isAgeValid
                                ? '${AppLocalizations.of(context).age}: $_userAge ${AppLocalizations.of(context).yearsOld}'
                                : AppLocalizations.of(context)
                                    .youMustBeAtLeast18,
                            style: GoogleFonts.inter(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: _isAgeValid ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],

                SizedBox(height: 20.h),

                // Terms & Conditions Checkbox with clickable links
                Row(
                  children: [
                    SizedBox(
                      width: 20.w,
                      height: 20.w,
                      child: Checkbox(
                        value: _agreeToTerms,
                        onChanged: (value) {
                          setState(() => _agreeToTerms = value ?? false);
                        },
                        activeColor: colors.textPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            color: colors.textSecondary,
                          ),
                          children: [
                            TextSpan(
                                text: AppLocalizations.of(context).iAgreeToThe),
                            TextSpan(
                              text: AppLocalizations.of(context)
                                  .termsAndConditions,
                              style: GoogleFonts.inter(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w500,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.pushNamed(
                                      context, AppRoutes.termsOfService);
                                },
                            ),
                            TextSpan(text: AppLocalizations.of(context).and),
                            TextSpan(
                              text: AppLocalizations.of(context).privacyPolicy,
                              style: GoogleFonts.inter(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w500,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.pushNamed(
                                      context, AppRoutes.privacyPolicy);
                                },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 32.h),

                // Sign Up Button
                PrimaryButton(
                  text: AppLocalizations.of(context).signUp,
                  onPressed: _handleRegister,
                  isLoading: _isEmailLoading,
                ),

                SizedBox(height: 24.h),

                // Sign In Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppLocalizations.of(context).alreadyHaveAccount,
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        color: colors.textSecondary,
                      ),
                    ),
                    GestureDetector(
                      onTap: isAnyLoading
                          ? null
                          : () {
                              Navigator.pushReplacementNamed(
                                  context, AppRoutes.login);
                            },
                      child: Text(
                        AppLocalizations.of(context).signIn,
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          color: isAnyLoading
                              ? colors.textPrimary.withValues(alpha: 0.5)
                              : colors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 32.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
