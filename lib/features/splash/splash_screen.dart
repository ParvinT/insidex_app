// lib/features/splash/splash_screen_rotation.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math;
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/routes/app_routes.dart';
import '../../services/auth_persistence_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _fadeController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _textFadeAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimations();
    _checkAuthAndNavigate(); // sadece yönlendirme mantığı güncellendi
  }

  void _initAnimations() {
    // 3D rotation controller
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    // Fade controller
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Rotate around Y axis in 3D
    _rotationAnimation = Tween<double>(
      begin: math.pi * 2, // 360 degrees
      end: 0.0,
    ).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.easeOutBack),
    );

    // Logo fade
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    // Text fade
    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );
  }

  void _startAnimations() async {
    _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _rotationController.forward();
  }

  void _checkAuthAndNavigate() {
    Future.delayed(const Duration(seconds: 2), () async {
      if (!mounted) return;

      print('========== AUTH CHECK START ==========');

      try {
        // Firebase user kontrolü
        User? firebaseUser = FirebaseAuth.instance.currentUser;
        print('Firebase User: ${firebaseUser?.email ?? "NULL"}');

        // Saved session kontrolü
        final hasSession = await AuthPersistenceService.hasValidSession();
        print('Has Valid Session: $hasSession');

        // SharedPreferences'ı direkt kontrol et
        final prefs = await SharedPreferences.getInstance();
        print('Saved Email: ${prefs.getString('user_email') ?? "NULL"}');
        print(
            'Saved Token: ${prefs.getString('fb_auth_token')?.substring(0, 20) ?? "NULL"}...');
        print('Token Timestamp: ${prefs.getInt('token_timestamp') ?? 0}');

        if (hasSession) {
          print('Valid session found, checking Firebase user...');

          if (firebaseUser != null) {
            print('Firebase user exists, refreshing token...');

            try {
              await firebaseUser.reload();
              final token = await firebaseUser.getIdToken();
              print('Token refresh successful');

              if (mounted) {
                print('Navigating to HOME');
                Navigator.pushReplacementNamed(context, AppRoutes.home);
                return;
              }
            } catch (e) {
              print('Token refresh failed: $e');
            }
          } else {
            print('No Firebase user, trying auto login...');
          }
        }

        // Auto login dene
        print('Attempting auto sign-in...');
        final user = await AuthPersistenceService.autoSignIn();

        if (user != null) {
          print('Auto login successful: ${user.email}');
          if (mounted) {
            print('Navigating to HOME after auto login');
            Navigator.pushReplacementNamed(context, AppRoutes.home);
          }
        } else {
          print('Auto login failed, going to onboarding');
          if (mounted) {
            print('Navigating to GOALS SCREEN');
            Navigator.pushReplacementNamed(context, AppRoutes.goalsScreen);
          }
        }
      } catch (e) {
        print('ERROR in auth check: $e');
        print(e.toString());
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.goalsScreen);
        }
      }

      print('========== AUTH CHECK END ==========');
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite, // White background
      body: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge([_rotationController, _fadeController]),
          builder: (context, child) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 3D rotating logo
                Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001) // 3D perspective
                      ..rotateY(_rotationAnimation.value),
                    child: SvgPicture.asset(
                      'assets/images/logo.svg',
                      width: 220.w,
                      height: 65.h,
                      fit: BoxFit.contain,
                      colorFilter: const ColorFilter.mode(
                        AppColors.textPrimary,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 35.h),

                // Tagline
                Opacity(
                  opacity: _textFadeAnimation.value,
                  child: Text(
                    AppConstants.appTagline,
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w300,
                      color: AppColors.textSecondary,
                      letterSpacing: 1.8,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
