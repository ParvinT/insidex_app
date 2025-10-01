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

  bool _navigationHandled = false;

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

  void _checkAuthAndNavigate() async {
    try {
      // Minimum 3 saniye splash göster (animasyon için)
      await Future.delayed(const Duration(seconds: 3));

      // Önce SharedPreferences'tan kontrol et (Huawei için fallback)
      final prefs = await SharedPreferences.getInstance();
      final hasLoggedInBefore = prefs.getBool('has_logged_in') ?? false;
      final savedUserId = prefs.getString('cached_user_id');

      debugPrint('🔍 Checking auth status...');
      debugPrint('📱 Has logged in before: $hasLoggedInBefore');
      debugPrint('💾 Saved user ID: $savedUserId');

      // Firebase Auth kontrolü - try/catch ile sarmalayalım
      User? currentUser;
      try {
        // Önce mevcut kullanıcıyı kontrol et (senkron)
        currentUser = FirebaseAuth.instance.currentUser;
        debugPrint('🔥 Current user (immediate): ${currentUser?.email}');

        // Eğer kullanıcı yoksa ve daha önce giriş yapılmışsa, biraz bekle
        if (currentUser == null && hasLoggedInBefore) {
          debugPrint('⏳ Waiting for auth state to settle...');

          // Firebase Auth'un yüklenmesini bekle (max 2 saniye)
          await Future.delayed(const Duration(seconds: 2));

          // Tekrar kontrol et
          currentUser = FirebaseAuth.instance.currentUser;
          debugPrint('🔥 Current user (after wait): ${currentUser?.email}');
        }
      } catch (e) {
        debugPrint('⚠️ Error checking Firebase Auth: $e');
        // Firebase Auth hatası durumunda SharedPreferences'a güven
        if (hasLoggedInBefore && savedUserId != null) {
          debugPrint('📱 Using cached login state for navigation');
          _navigateToHome();
          return;
        }
      }

      // Navigation kararı
      if (!mounted) return;

      if (currentUser != null) {
        // Firebase'den kullanıcı alındı
        debugPrint('✅ User is logged in via Firebase: ${currentUser.email}');

        // Cache'i güncelle
        await prefs.setBool('has_logged_in', true);
        await prefs.setString('cached_user_id', currentUser.uid);

        _navigateToHome();
      } else if (hasLoggedInBefore && savedUserId != null) {
        // Firebase'den alınamadı ama cache'de var (Huawei için)
        debugPrint('📱 Using cached auth state, navigating to home');
        _navigateToHome();
      } else {
        // Kullanıcı giriş yapmamış
        debugPrint('❌ User is not logged in, going to onboarding');
        _navigateToOnboarding();
      }
    } catch (e) {
      debugPrint('❌ Error in auth check: $e');
      // Hata durumunda güvenli taraf: onboarding
      _navigateToOnboarding();
    }
  }

  void _navigateToHome() {
    if (_navigationHandled || !mounted) return;
    _navigationHandled = true;
    Navigator.pushReplacementNamed(context, AppRoutes.home);
  }

  void _navigateToOnboarding() {
    if (_navigationHandled || !mounted) return;
    _navigationHandled = true;
    Navigator.pushReplacementNamed(context, AppRoutes.goalsScreen);
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
