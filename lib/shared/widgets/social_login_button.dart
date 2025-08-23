// lib/shared/widgets/social_login_button.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

class SocialLoginButton extends StatelessWidget {
  final VoidCallback onTap;
  final String label;
  final bool isDark;
  final bool isLoading;
  final bool isDisabled;

  const SocialLoginButton({
    super.key,
    required this.onTap,
    required this.label,
    this.isDark = false,
    this.isLoading = false,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool canTap = !isLoading && !isDisabled;

    return GestureDetector(
      onTap: canTap ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 48.h,
        decoration: BoxDecoration(
          color: isDisabled
              ? (isDark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.white.withOpacity(0.5))
              : (isDark ? Colors.black : Colors.white),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isDisabled
                ? AppColors.greyBorder.withOpacity(0.3)
                : (isDark ? Colors.black : AppColors.greyBorder),
            width: 1.5,
          ),
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 20.w,
                  height: 20.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon
                    Icon(
                      label.toLowerCase().contains('google')
                          ? Icons.g_mobiledata
                          : Icons.apple,
                      color: isDisabled
                          ? (isDark
                              ? Colors.white.withOpacity(0.3)
                              : AppColors.textPrimary.withOpacity(0.3))
                          : (isDark ? Colors.white : AppColors.textPrimary),
                      size: 24.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: isDisabled
                            ? (isDark
                                ? Colors.white.withOpacity(0.3)
                                : AppColors.textPrimary.withOpacity(0.3))
                            : (isDark ? Colors.white : AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
