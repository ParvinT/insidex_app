// lib/features/auth/welcome_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/responsive/auth_scaffold.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // NOTE: We provide a scrollable body to AuthScaffold (bodyIsScrollable: true)
    // so it won't wrap with an extra scroll and it will only add safe bottom padding if needed.
    return AuthScaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      bodyIsScrollable: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Clamp max text width on very wide screens so typography stays nice.
          const double kMaxTextWidth = 720;
          final double horizontalPad =
              constraints.maxWidth >= 900 ? 64.0 : 24.0;

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(horizontalPad, 32, horizontalPad, 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: kMaxTextWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // App wordmark (kept as text; your real logo widget can stay here)
                    Text(
                      'InsideX',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        height: 1.2,
                      ),
                    ),

                    SizedBox(height: 28.h),

                    // Title
                    Text(
                      'Welcome',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize:
                            48.sp, // Keep your styling; ScreenUtil will adapt
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        height: 1.15,
                      ),
                    ),

                    SizedBox(height: 16.h),

                    // Subtitle
                    Text(
                      'Create your personal profile\nto get custom subliminal sessions',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),

                    SizedBox(height: 28.h),

                    // EMAIL + PASSWORD CTA (kept as a full-width button-like surface)
                    SizedBox(
                      width: double.infinity,
                      child: _OutlinedBigButton(
                        label: 'Email + Password',
                        onTap: () {
                          // Preserve original navigation
                          Navigator.of(context).pushNamed(AppRoutes.login);
                        },
                      ),
                    ),

                    SizedBox(height: 12.h),

                    // Continue as Guest
                    TextButton(
                      onPressed: () {
                        Navigator.of(context)
                            .pushReplacementNamed(AppRoutes.home);
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                            vertical: 8.h, horizontal: 4.w),
                      ),
                      child: Text(
                        'Continue as a Guest',
                        style: GoogleFonts.inter(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),

                    SizedBox(height: 16.h),

                    // Sign Up
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: GoogleFonts.inter(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.of(context).pushNamed(AppRoutes.register);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Text(
                              'Sign Up',
                              style: GoogleFonts.inter(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryGold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A simple, design-friendly outlined button used above for "Email + Password".
class _OutlinedBigButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _OutlinedBigButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.black.withOpacity(0.15), width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Left icon placeholder (envelope) – replace with your SVG if needed
              Icon(Icons.mail_outline,
                  size: 22.sp, color: AppColors.textPrimary),
              SizedBox(width: 10.w),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
