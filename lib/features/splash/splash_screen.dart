// lib/features/splash/splash_screen_rotation.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:math' as math;
import '../offline/offline_mode_screen.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../services/auth_persistence_service.dart';
import '../../services/image_prefetch_service.dart';
import '../../l10n/app_localizations.dart';

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
    _checkAuthAndNavigate();
    ImagePrefetchService.prefetchPopularSessions(limit: 20);
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

      debugPrint('========== AUTH CHECK START ==========');

      try {
        // 1️⃣ CHECK REAL INTERNET CONNECTIVITY (not just WiFi status)
        final isOnline = await _checkRealConnectivity();
        debugPrint('Connectivity: ${isOnline ? "ONLINE" : "OFFLINE"}');

        // 2️⃣ CHECK IF USER HAS LOGGED IN BEFORE
        final prefs = await SharedPreferences.getInstance();
        final hasLoggedIn = prefs.getBool('has_logged_in') ?? false;
        debugPrint('Has logged in before: $hasLoggedIn');

        // 3️⃣ OFFLINE HANDLING
        if (!isOnline) {
          if (hasLoggedIn) {
            // User has logged in before - show offline mode
            debugPrint('OFFLINE + HAS_LOGGED_IN → Offline Mode Screen');
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const OfflineModeScreen()),
              );
            }
            return;
          } else {
            // Never logged in - need internet
            debugPrint('OFFLINE + NEVER_LOGGED_IN → Need internet');
            if (mounted) {
              _showInternetRequiredDialog();
            }
            return;
          }
        }

        // 4️⃣ ONLINE - NORMAL AUTH FLOW (mevcut kod aynen devam)
        User? firebaseUser = FirebaseAuth.instance.currentUser;
        debugPrint('Firebase User: ${firebaseUser?.email ?? "NULL"}');

        // Saved session kontrolü
        final hasSession = await AuthPersistenceService.hasValidSession();
        debugPrint('Has Valid Session: $hasSession');

        debugPrint('Saved Email: ${prefs.getString('user_email') ?? "NULL"}');
        debugPrint(
            'Saved Token: ${prefs.getString('fb_auth_token')?.substring(0, 20) ?? "NULL"}...');
        debugPrint('Token Timestamp: ${prefs.getInt('token_timestamp') ?? 0}');

        if (hasSession && firebaseUser != null) {
          debugPrint('Valid session found with Firebase user');

          // Try to refresh token, but continue even if it fails (offline mode)
          try {
            await firebaseUser.reload();
            debugPrint('Token refresh successful');
          } catch (e) {
            debugPrint('Token refresh failed (offline?): $e');
            // Continue anyway - user can use app in offline mode
          }

          // Navigate to HOME regardless of token refresh result
          if (mounted) {
            debugPrint('Navigating to HOME');
            Navigator.pushReplacementNamed(context, AppRoutes.home);
            return;
          }
        } else if (hasSession && firebaseUser == null) {
          debugPrint('Has session but no Firebase user, trying auto login...');
        }
        // Auto login dene
        debugPrint('Attempting auto sign-in...');
        final user = await AuthPersistenceService.autoSignIn();

        if (user != null) {
          debugPrint('Auto login successful: ${user.email}');
          if (mounted) {
            debugPrint('Navigating to HOME after auto login');
            Navigator.pushReplacementNamed(context, AppRoutes.home);
          }
        } else {
          debugPrint('Auto login failed, going to onboarding');
          if (mounted) {
            debugPrint('Navigating to GOALS SCREEN');
            Navigator.pushReplacementNamed(context, AppRoutes.goalsScreen);
          }
        }
      } catch (e) {
        debugPrint('ERROR in auth check: $e');
        debugPrint(e.toString());
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.goalsScreen);
        }
      }

      debugPrint('========== AUTH CHECK END ==========');
    });
  }

  /// Check real internet connectivity by making HTTP request
  Future<bool> _checkRealConnectivity() async {
    try {
      // First check basic connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        debugPrint('📡 [Connectivity] No network interface');
        return false;
      }

      // Then verify actual internet access with HTTP request
      final response = await http
          .get(
            Uri.parse('https://clients3.google.com/generate_204'),
          )
          .timeout(const Duration(seconds: 5));

      debugPrint('📡 [Connectivity] HTTP check: ${response.statusCode}');
      return response.statusCode == 204 || response.statusCode == 200;
    } catch (e) {
      debugPrint('📡 [Connectivity] Real check failed: $e');
      return false;
    }
  }

  void _showInternetRequiredDialog() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Row(
          children: [
            Icon(Icons.wifi_off_rounded, color: Colors.orange, size: 28.sp),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                l10n.noInternet,
                style: GoogleFonts.inter(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          l10n.internetRequiredForFirstLogin,
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _checkAuthAndNavigate();
            },
            child: Text(
              l10n.tryAgain,
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
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
