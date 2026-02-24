// lib/features/auth/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/themes/app_theme_extension.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/form_validators.dart';
import '../../core/utils/firebase_error_handler.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/widgets/primary_button.dart';
import '../../services/firebase_service.dart';
import '../../services/notifications/topic_management_service.dart';
import '../../services/auth_persistence_service.dart';
import '../../services/device_session_service.dart';
import '../../providers/user_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/locale_provider.dart';
import '../../core/responsive/auth_scaffold.dart';
import '../../l10n/app_localizations.dart';
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
  final bool _isGoogleLoading = false;
  final bool _isAppleLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isEmailLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final locale = context.read<LocaleProvider>().locale.languageCode;
    final subProvider = context.read<SubscriptionProvider>();
    final userProvider = context.read<UserProvider>();

    final result = await FirebaseService.signIn(
      email: email,
      password: password,
    );

    setState(() => _isEmailLoading = false);

    if (!mounted) return;

    if (result['success']) {
      final user = result['user'];
      if (user != null) {
        debugPrint('SAVING AUTH SESSION for: ${user.email}');
        await AuthPersistenceService.saveAuthSession(user, password: password);

        final prefs = await SharedPreferences.getInstance();
        debugPrint('After save - Email: ${prefs.getString('user_email')}');
        debugPrint(
            'After save - Has credentials: ${prefs.getString('auth_credentials') != null}');
        debugPrint('💾 Saving active device session...');
        final savedToken =
            await DeviceSessionService().saveActiveDevice(user.uid);
        debugPrint('✅ Active device saved: ${savedToken?.substring(0, 20)}...');

        await Future.delayed(const Duration(milliseconds: 500));

        await userProvider.loadUserData(user.uid);
        await prefs.setBool('has_logged_in', true);
        await prefs.setString('cached_user_id', user.uid);
        debugPrint('✅ [Login] has_logged_in flag and user ID saved');

        // Subscribe to FCM topics for push notifications
        try {
          await subProvider.waitForInitialization();
          await TopicManagementService().subscribeUserTopics(
            language: locale,
            tier: subProvider.tier.name,
          );
          debugPrint('✅ FCM topics subscribed');
        } catch (e) {
          debugPrint('⚠️ FCM topic subscription error: $e');
        }
      }

      if (!mounted) return;

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
    final colors = context.colors;
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: colors.border,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Text(
            AppLocalizations.of(context).or,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: colors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: colors.border,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isAnyLoading = _isEmailLoading || _isGoogleLoading || _isAppleLoading;
    final l10n = AppLocalizations.of(context);

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

                // Title
                Text(
                  l10n.welcomeBack,
                  style: GoogleFonts.inter(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),

                SizedBox(height: 8.h),

                // Subtitle
                Text(
                  l10n.signInToContinue,
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    color: colors.textSecondary,
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
                      color: colors.textSecondary,
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
                            ? colors.textSecondary
                            : colors.textPrimary,
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
                        color: colors.textSecondary,
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
