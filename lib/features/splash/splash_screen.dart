import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _dropController;
  late AnimationController _bounceController;
  late AnimationController _fadeController;

  late Animation<double> _dropAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _navigateToNext();
  }

  void _initAnimations() {
    // Drop animation controller
    _dropController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Bounce animation controller
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Fade animation controller for text
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Logo drop animation - yukarıdan aşağıya
    _dropAnimation = Tween<double>(
      begin: -300.0, // Ekranın üstünden başla
      end: 0.0, // Merkeze gel
    ).animate(CurvedAnimation(
      parent: _dropController,
      curve: Curves.fastOutSlowIn,
    ));

    // Bounce effect when landing
    _bounceAnimation = Tween<double>(
      begin: 1.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));

    // Text fade animation
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    // Start animations sequence
    _dropController.forward().then((_) {
      _bounceController.forward();
      _fadeController.forward();
    });
  }

  void _navigateToNext() {
    Future.delayed(const Duration(seconds: 3), () {
      // TODO: Navigate to onboarding or home
    });
  }

  @override
  void dispose() {
    _dropController.dispose();
    _bounceController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo with drop animation
            AnimatedBuilder(
              animation: Listenable.merge([_dropController, _bounceController]),
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _dropAnimation.value),
                  child: Transform.scale(
                    scale: _bounceAnimation.value,
                    child: _buildLogo(isDark),
                  ),
                );
              },
            ),

            SizedBox(height: 40.h),

            // Tagline with fade animation
            AnimatedBuilder(
              animation: _fadeController,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Text(
                    AppConstants.appTagline,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w300,
                      color: AppColors.textSecondary,
                      letterSpacing: 1.5,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo(bool isDark) {
    return SvgPicture.asset(
      'assets/images/logo.svg',
      width: 220.w,
      height: 60.h,
      fit: BoxFit.contain,
      colorFilter: isDark
          ? ColorFilter.mode(AppColors.primaryGoldLight, BlendMode.srcIn)
          : null,
    );
  }
}
