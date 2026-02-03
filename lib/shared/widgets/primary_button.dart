// lib/shared/widgets/primary_button.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/themes/app_theme_extension.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? width;
  final double height;
  final Color? backgroundColor;
  final Color? textColor;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.width,
    this.height = 48, // Reduced from 56
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      width: width ?? double.infinity,
      height: height.h,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? colors.textPrimary,
          foregroundColor: textColor ?? colors.textOnPrimary,
          disabledBackgroundColor: colors.greyLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 0),
        ),
        child: Center(
          // Explicit center
          child: isLoading
              ? SizedBox(
                  height: 20.h,
                  width: 20.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      textColor ?? colors.textOnPrimary,
                    ),
                  ),
                )
              : Text(
                  text,
                  style: GoogleFonts.inter(
                    fontSize: 14.sp, // Reduced from 16.sp
                    fontWeight: FontWeight.w600,
                    height: 1.0, // Line height adjustment
                  ),
                  textAlign: TextAlign.center,
                ),
        ),
      ),
    );
  }
}
