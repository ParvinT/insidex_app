// lib/shared/widgets/device_logout_dialog.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/responsive/context_ext.dart';
import '../../l10n/app_localizations.dart';

/// Full screen dialog that shows countdown before automatic logout
/// Cannot be dismissed by user
/// Shows security warning to change password if unauthorized access
class DeviceLogoutDialog extends StatefulWidget {
  final VoidCallback onLogout;
  final int countdownSeconds;

  const DeviceLogoutDialog({
    Key? key,
    required this.onLogout,
    this.countdownSeconds = 30,
  }) : super(key: key);

  @override
  State<DeviceLogoutDialog> createState() => _DeviceLogoutDialogState();
}

class _DeviceLogoutDialogState extends State<DeviceLogoutDialog> {
  late int _remainingSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.countdownSeconds;
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remainingSeconds--;
      });

      if (_remainingSeconds <= 0) {
        timer.cancel();
        widget.onLogout();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Responsive values
    final isTablet = context.isTablet;
    final isDesktop = context.isDesktop;

    final double maxContentWidth =
        isDesktop ? 550 : (isTablet ? 500 : double.infinity);
    final double horizontalPadding =
        isDesktop ? 40.w : (isTablet ? 32.w : 24.w);

    final double iconSize =
        isTablet ? 80.sp.clamp(70.0, 90.0) : 70.sp.clamp(60.0, 80.0);
    final double titleSize =
        isTablet ? 22.sp.clamp(20.0, 24.0) : 20.sp.clamp(18.0, 22.0);
    final double bodySize =
        isTablet ? 16.sp.clamp(15.0, 17.0) : 15.sp.clamp(14.0, 16.0);
    final double warningSize =
        isTablet ? 14.sp.clamp(13.0, 15.0) : 13.sp.clamp(12.0, 14.0);
    final double countdownSize =
        isTablet ? 48.sp.clamp(42.0, 54.0) : 42.sp.clamp(36.0, 48.0);

    return WillPopScope(
      // Prevent back button
      onWillPop: () async => false,
      child: Material(
        color: Colors.black.withOpacity(0.85),
        child: Center(
          child: Container(
            width: maxContentWidth,
            margin: EdgeInsets.symmetric(horizontal: horizontalPadding),
            padding: EdgeInsets.all(isTablet ? 32.w : 24.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Warning Icon
                Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.warning_rounded,
                    color: Colors.orange,
                    size: iconSize * 0.6,
                  ),
                ),

                SizedBox(height: isTablet ? 24.h : 20.h),

                // Title
                Text(
                  AppLocalizations.of(context).accountOpenedOnAnotherDevice,
                  style: GoogleFonts.inter(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: isTablet ? 16.h : 12.h),

                // Message
                Text(
                  AppLocalizations.of(context).accountOpenedMessage,
                  style: GoogleFonts.inter(
                    fontSize: bodySize,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: isTablet ? 24.h : 20.h),

                // ⭐ SECURITY WARNING BOX
                Container(
                  padding: EdgeInsets.all(isTablet ? 16.w : 14.w),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        color: Colors.red,
                        size: isTablet ? 22.sp : 20.sp,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)
                              .securityWarningUnauthorized,
                          style: GoogleFonts.inter(
                            fontSize: warningSize,
                            color: Colors.red.shade700,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: isTablet ? 28.h : 24.h),

                // Countdown
                Container(
                  width: isTablet ? 120.w : 100.w,
                  height: isTablet ? 120.w : 100.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _getCountdownColor(),
                      width: 6,
                    ),
                    color: _getCountdownColor().withOpacity(0.1),
                  ),
                  child: Center(
                    child: Text(
                      '$_remainingSeconds',
                      style: GoogleFonts.inter(
                        fontSize: countdownSize,
                        fontWeight: FontWeight.w700,
                        color: _getCountdownColor(),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: isTablet ? 16.h : 12.h),

                // Seconds text
                Text(
                  _remainingSeconds == 1
                      ? AppLocalizations.of(context).second
                      : AppLocalizations.of(context).seconds,
                  style: GoogleFonts.inter(
                    fontSize: bodySize * 0.9,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getCountdownColor() {
    if (_remainingSeconds <= 10) return Colors.red;
    if (_remainingSeconds <= 20) return Colors.orange;
    return AppColors.primaryGold;
  }
}
