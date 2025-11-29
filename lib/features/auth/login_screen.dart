// lib/features/auth/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/form_validators.dart';
import '../../core/utils/firebase_error_handler.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/widgets/primary_button.dart';
import '../../services/firebase_service.dart';
import '../../providers/user_provider.dart';
import '../../core/responsive/auth_scaffold.dart';
import '../../services/auth_persistence_service.dart';
import '../../l10n/app_localizations.dart';
import '../../services/device_session_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;

  // Ayrı loading state'ler
  bool _isEmailLoading = false;
  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isEmailLoading = true);

    // ⭐ ÖNEMLİ: Password'ü sakla
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    final result = await FirebaseService.signIn(
      email: email,
      password: password,
    );

    setState(() => _isEmailLoading = false);

    if (!mounted) return;

    if (result['success']) {
      final user = result['user'];
      if (user != null) {
        // ⭐ BURASI KRİTİK - Session'ı kaydet
        debugPrint('SAVING AUTH SESSION for: ${user.email}');
        await AuthPersistenceService.saveAuthSession(user,
            password: password // ⭐ Password'ü geçiriyoruz
            );

        // Test için SharedPreferences'ı kontrol et
        final prefs = await SharedPreferences.getInstance();
        debugPrint('After save - Email: ${prefs.getString('user_email')}');
        debugPrint(
            'After save - Has credentials: ${prefs.getString('auth_credentials') != null}');
        debugPrint('💾 Saving active device session...');
        await DeviceSessionService().saveActiveDevice(user.uid);
        debugPrint('✅ Active device saved, other devices will be logged out');

        await context.read<UserProvider>().loadUserData(user.uid);
      }

      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else {
      final errorMessage = FirebaseErrorHandler.getErrorMessage(
        result['code'],
        context,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleForgotPassword() async {
    Navigator.pushNamed(context, AppRoutes.forgotPassword);
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.greyBorder,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Text(
            AppLocalizations.of(context).or,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.greyBorder,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Herhangi biri loading durumundaysa diğer butonları disable et
    final isAnyLoading = _isEmailLoading || _isGoogleLoading || _isAppleLoading;
    final l10n = AppLocalizations.of(context);

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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20.h),

                // Title
                Text(
                  l10n.welcomeBack,
                  style: GoogleFonts.inter(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),

                SizedBox(height: 8.h),

                // Subtitle
                Text(
                  l10n.signInToContinue,
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    color: AppColors.textSecondary,
                  ),
                ),

                SizedBox(height: 40.h),

                // Email Field
                CustomTextField(
                  controller: _emailController,
                  label: l10n.email,
                  hint: l10n.enterYourEmail,
                  keyboardType: TextInputType.emailAddress,
                  validator: FormValidators.validateEmail,
                  readOnly: isAnyLoading,
                ),

                SizedBox(height: 16.h),

                // Password Field
                CustomTextField(
                  controller: _passwordController,
                  label: l10n.password,
                  hint: l10n.enterYourPassword,
                  obscureText: !_isPasswordVisible,
                  validator: FormValidators.validatePassword,
                  readOnly: isAnyLoading,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: isAnyLoading
                        ? null
                        : () {
                            setState(
                                () => _isPasswordVisible = !_isPasswordVisible);
                          },
                  ),
                ),

                SizedBox(height: 16.h),

                // Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: isAnyLoading ? null : _handleForgotPassword,
                    child: Text(
                      l10n.forgotPassword,
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        color: isAnyLoading
                            ? AppColors.textSecondary
                            : AppColors.primaryGold,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 32.h),

                // Sign In Button
                PrimaryButton(
                  text: l10n.signIn,
                  onPressed: _handleLogin,
                  isLoading: _isEmailLoading,
                ),

                SizedBox(height: 24.h),

                // OR Divider
                _buildDivider(),

                SizedBox(height: 20.h),

                // Sign Up Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l10n.dontHaveAccount,
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    GestureDetector(
                      onTap: isAnyLoading
                          ? null
                          : () {
                              Navigator.pushNamed(context, AppRoutes.register);
                            },
                      child: Text(
                        l10n.signUp,
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          color: isAnyLoading
                              ? AppColors.primaryGold.withOpacity(0.5)
                              : AppColors.primaryGold,
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
