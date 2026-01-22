// lib/features/subscription/widgets/success_dialog.dart

import 'dart:math' show max;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/themes/app_theme_extension.dart';

/// Success dialog shown after successful purchase
class SuccessDialog extends StatefulWidget {
  final String title;
  final String subtitle;
  final String? planName;
  final bool isTrialStarted;
  final VoidCallback? onDismiss;

  const SuccessDialog({
    super.key,
    this.title = 'Welcome to Premium!',
    this.subtitle = 'You now have access to all features',
    this.planName,
    this.isTrialStarted = false,
    this.onDismiss,
  });

  @override
  State<SuccessDialog> createState() => _SuccessDialogState();
}

class _SuccessDialogState extends State<SuccessDialog>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _checkController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();

    // Dialog scale animation
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
    );

    // Checkmark animation
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _checkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _checkController, curve: Curves.easeOutBack),
    );

    // Start animations
    _scaleController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _checkController.forward();
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _checkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: max(24, 24.w)),
          child: Builder(builder: (context) {
            final colors = context.colors;
            return Container(
                padding: EdgeInsets.all(max(24, 24.w)),
                decoration: BoxDecoration(
                  color: colors.backgroundElevated,
                  borderRadius: BorderRadius.circular(24.r),
                  boxShadow: [
                    BoxShadow(
                      color: colors.textPrimary.withValues(alpha: 0.15),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animated success icon
                    _buildSuccessIcon(),

                    SizedBox(height: 20.h),

                    // Title
                    Text(
                      widget.title,
                      style: GoogleFonts.inter(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: 12.h),

                    // Plan badge (if provided)
                    if (widget.planName != null) ...[
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 8.h,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.amber.shade400,
                              Colors.orange.shade400,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.workspace_premium,
                              size: 18.sp,
                              color: Colors.white,
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              widget.planName!,
                              style: GoogleFonts.inter(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16.h),
                    ],

                    // Subtitle
                    Text(
                      widget.subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 15.sp,
                        color: colors.textSecondary,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    // Trial info
                    if (widget.isTrialStarted) ...[
                      SizedBox(height: 16.h),
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: Colors.green.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 18.sp,
                              color: Colors.green.shade700,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              '7-day free trial started',
                              style: GoogleFonts.inter(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w500,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    SizedBox(height: 24.h),

                    // Features unlocked
                    _buildFeaturesList(),

                    SizedBox(height: 24.h),

                    // Continue button
                    SizedBox(
                      width: double.infinity,
                      height: max(52, 52.h),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          widget.onDismiss?.call();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.textPrimary,
                          foregroundColor: colors.textOnPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Start Exploring',
                          style: GoogleFonts.inter(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ));
          }),
        ),
      ),
    );
  }

  Widget _buildSuccessIcon() {
    return AnimatedBuilder(
      animation: _checkController,
      builder: (context, child) {
        return Container(
          width: max(100, 100.w),
          height: max(100, 100.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.amber.shade300,
                Colors.orange.shade400,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Crown/Premium icon in background
              Opacity(
                opacity: 0.3,
                child: Icon(
                  Icons.workspace_premium,
                  size: 70.sp,
                  color: Colors.white,
                ),
              ),
              // Animated checkmark
              Transform.scale(
                scale: _checkAnimation.value,
                child: Icon(
                  Icons.check_rounded,
                  size: 50.sp,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeaturesList() {
    // Determine features based on plan
    final isStandard =
        widget.planName?.toLowerCase().contains('standard') ?? false;

    final features = [
      'All audio sessions',
      'Background playback',
      if (isStandard) 'Offline downloads',
    ];

    return Column(
      children: features.map((feature) {
        return Padding(
          padding: EdgeInsets.only(bottom: 8.h),
          child: Row(
            children: [
              Container(
                width: max(22, 22.w),
                height: max(22, 22.w),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  size: 14.sp,
                  color: Colors.green.shade600,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                feature,
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  color: context.colors.textPrimary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// Helper function to show success dialog
Future<void> showPurchaseSuccessDialog(
  BuildContext context, {
  String? planName,
  bool isTrialStarted = false,
  VoidCallback? onDismiss,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (context) => SuccessDialog(
      title: isTrialStarted ? 'Trial Started!' : 'Welcome to Premium!',
      subtitle: isTrialStarted
          ? 'Enjoy full access for the next 7 days'
          : 'You now have unlimited access to all features',
      planName: planName,
      isTrialStarted: isTrialStarted,
      onDismiss: onDismiss,
    ),
  );
}
