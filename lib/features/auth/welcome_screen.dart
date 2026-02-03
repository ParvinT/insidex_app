// lib/features/auth/welcome_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/themes/app_theme_extension.dart';
import '../../core/routes/app_routes.dart';
import '../../core/responsive/auth_scaffold.dart';
import '../../l10n/app_localizations.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // NOTE: We provide a scrollable body to AuthScaffold (bodyIsScrollable: true)
    // so it won't wrap with an extra scroll and it will only add safe bottom padding if needed.
    return AuthScaffold(
      backgroundColor: colors.background,
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
                    Builder(
                      builder: (context) {
                        final screenWidth = MediaQuery.of(context).size.width;
                        final bool isTablet = screenWidth >= 600;
                        final bool isDesktop = screenWidth >= 1024;

                        // Ekran boyutuna göre logo boyutu
                        final logoWidth = isDesktop
                            ? 180.w
                            : isTablet
                                ? 160.w
                                : 140.w;

                        final logoHeight = isDesktop
                            ? 60.h
                            : isTablet
                                ? 55.h
                                : 48.h;

                        return Container(
                          alignment: Alignment.center,
                          child: SvgPicture.asset(
                            'assets/images/logo.svg',
                            width: logoWidth,
                            height: logoHeight,
                            fit: BoxFit.contain,
                            colorFilter: ColorFilter.mode(
                              colors.textPrimary,
                              BlendMode.srcIn,
                            ),
                          ),
                        );
                      },
                    ),

                    SizedBox(height: 28.h),

                    // Title
                    Text(
                      AppLocalizations.of(context).welcome,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize:
                            48.sp, // Keep your styling; ScreenUtil will adapt
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                        height: 1.15,
                      ),
                    ),

                    SizedBox(height: 16.h),

                    // Subtitle
                    Text(
                      AppLocalizations.of(context).createYourPersonalProfile,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w400,
                        color: colors.textSecondary,
                        height: 1.5,
                      ),
                    ),

                    SizedBox(height: 28.h),

                    // EMAIL + PASSWORD CTA (kept as a full-width button-like surface)
                    SizedBox(
                      width: double.infinity,
                      child: _OutlinedBigButton(
                        label: AppLocalizations.of(context).emailPassword,
                        onTap: () {
                          // Preserve original navigation
                          Navigator.of(context).pushNamed(AppRoutes.login);
                        },
                      ),
                    ),

                    SizedBox(height: 12.h),

                    SizedBox(height: 32.h),

                    // Sign Up
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          AppLocalizations.of(context).dontHaveAccount,
                          style: GoogleFonts.inter(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w400,
                            color: colors.textSecondary,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.of(context).pushNamed(AppRoutes.register);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Text(
                              AppLocalizations.of(context).signUp,
                              style: GoogleFonts.inter(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w700,
                                color: colors.textPrimary,
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
    final colors = context.colors;
    return Material(
      color: colors.backgroundCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colors.border, width: 1),
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
              Icon(Icons.mail_outline, size: 22.sp, color: colors.textPrimary),
              SizedBox(width: 10.w),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
