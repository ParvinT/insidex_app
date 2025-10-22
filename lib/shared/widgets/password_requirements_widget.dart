// lib/shared/widgets/password_requirements_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/responsive/context_ext.dart';
import '../../l10n/app_localizations.dart';

// Enum for password strength levels (no localization needed)
enum PasswordStrengthLevel { none, weak, fair, good, strong }

class PasswordRequirementsWidget extends StatefulWidget {
  final String password;
  final String? excludePassword; // For "different from current" check
  final bool showDifferentCheck; // Show "different from current" requirement

  const PasswordRequirementsWidget({
    super.key,
    required this.password,
    this.excludePassword,
    this.showDifferentCheck = false,
  });

  @override
  State<PasswordRequirementsWidget> createState() =>
      _PasswordRequirementsWidgetState();
}

class _PasswordRequirementsWidgetState extends State<PasswordRequirementsWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _heightAnimation;

  // Password strength tracking (NO localization here)
  double _passwordStrength = 0.0;
  PasswordStrengthLevel _strengthLevel = PasswordStrengthLevel.none;
  Color _passwordStrengthColor = Colors.red;

  // Password requirements tracking
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasNumber = false;
  bool _isDifferent = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _heightAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    // Safe to call - no context dependency
    _checkPasswordStrength(widget.password);
    _animationController.forward();
  }

  @override
  void didUpdateWidget(PasswordRequirementsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.password != widget.password ||
        oldWidget.excludePassword != widget.excludePassword) {
      _checkPasswordStrength(widget.password);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // NO LOCALIZATION - only calculates strength level
  void _checkPasswordStrength(String password) {
    // Update requirement checks
    setState(() {
      _hasMinLength = password.length >= 8;
      _hasUppercase = password.contains(RegExp(r'[A-Z]'));
      _hasLowercase = password.contains(RegExp(r'[a-z]'));
      _hasNumber = password.contains(RegExp(r'[0-9]'));

      if (widget.showDifferentCheck && widget.excludePassword != null) {
        _isDifferent = password.isEmpty || password != widget.excludePassword;
      } else {
        _isDifferent = true; // Not applicable
      }
    });

    double strength = 0;
    PasswordStrengthLevel level = PasswordStrengthLevel.none;
    Color strengthColor = Colors.red;

    if (password.isEmpty) {
      setState(() {
        _passwordStrength = 0;
        _strengthLevel = PasswordStrengthLevel.none;
        _passwordStrengthColor = Colors.red;
      });
      return;
    }

    // Check criteria
    if (password.length >= 8) strength += 0.2;
    if (password.length >= 12) strength += 0.1;
    if (password.contains(RegExp(r'[A-Z]'))) strength += 0.2;
    if (password.contains(RegExp(r'[a-z]'))) strength += 0.2;
    if (password.contains(RegExp(r'[0-9]'))) strength += 0.2;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength += 0.1;

    // Determine strength level (NO LOCALIZATION)
    if (strength <= 0.3) {
      level = PasswordStrengthLevel.weak;
      strengthColor = Colors.red;
    } else if (strength <= 0.5) {
      level = PasswordStrengthLevel.fair;
      strengthColor = Colors.orange;
    } else if (strength <= 0.7) {
      level = PasswordStrengthLevel.good;
      strengthColor = const Color(0xFFFFB800);
    } else {
      level = PasswordStrengthLevel.strong;
      strengthColor = Colors.green;
    }

    setState(() {
      _passwordStrength = strength;
      _strengthLevel = level;
      _passwordStrengthColor = strengthColor;
    });
  }

  // Helper method to get localized strength text (called in build)
  String _getLocalizedStrengthText() {
    switch (_strengthLevel) {
      case PasswordStrengthLevel.weak:
        return AppLocalizations.of(context).weak;
      case PasswordStrengthLevel.fair:
        return AppLocalizations.of(context).fair;
      case PasswordStrengthLevel.good:
        return AppLocalizations.of(context).good;
      case PasswordStrengthLevel.strong:
        return AppLocalizations.of(context).strong;
      case PasswordStrengthLevel.none:
      default:
        return '';
    }
  }

  Widget _buildRequirement(String text, {required bool isMet}) {
    final bool showStatus = widget.password.isNotEmpty;
    final Color iconColor = showStatus
        ? (isMet ? Colors.green : Colors.red.withOpacity(0.5))
        : AppColors.textSecondary.withOpacity(0.3);

    final Color textColor = showStatus
        ? (isMet ? AppColors.textPrimary : AppColors.textSecondary)
        : AppColors.textSecondary.withOpacity(0.6);

    // Responsive sizing
    final isTablet = context.isTablet;
    final iconSize = isTablet ? 14.0 : 12.0;
    final textSize =
        isTablet ? 12.sp.clamp(11.0, 13.0) : 11.sp.clamp(10.0, 12.0);

    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        children: [
          Icon(
            isMet && showStatus ? Icons.check_circle : Icons.circle_outlined,
            color: iconColor,
            size: iconSize,
          ),
          SizedBox(width: 6.w),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: textSize,
                color: textColor,
                fontWeight:
                    isMet && showStatus ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = context.isTablet;

    return SizeTransition(
      sizeFactor: _heightAnimation,
      axisAlignment: -1.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Password Strength Bar
          if (_passwordStrength > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context).passwordStrength,
                  style: GoogleFonts.inter(
                    fontSize: isTablet
                        ? 12.sp.clamp(11.0, 13.0)
                        : 11.sp.clamp(10.0, 12.0),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  _getLocalizedStrengthText(), // ← Localization happens HERE in build
                  style: GoogleFonts.inter(
                    fontSize: isTablet
                        ? 12.sp.clamp(11.0, 13.0)
                        : 11.sp.clamp(10.0, 12.0),
                    fontWeight: FontWeight.w700,
                    color: _passwordStrengthColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 6.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(10.r),
              child: LinearProgressIndicator(
                value: _passwordStrength,
                backgroundColor: AppColors.textSecondary.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation(_passwordStrengthColor),
                minHeight: 6.h,
              ),
            ),
            SizedBox(height: 12.h),
          ],

          // Requirements List
          Container(
            padding: EdgeInsets.all(12.w.clamp(12.0, 16.0)),
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withOpacity(0.03),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: AppColors.textSecondary.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.textSecondary,
                      size: isTablet ? 14.0 : 12.0,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      AppLocalizations.of(context).passwordRequirements,
                      style: GoogleFonts.inter(
                        fontSize: isTablet
                            ? 12.sp.clamp(11.0, 13.0)
                            : 11.sp.clamp(10.0, 12.0),
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                _buildRequirement(
                  AppLocalizations.of(context).atLeast8Characters,
                  isMet: _hasMinLength,
                ),
                _buildRequirement(
                  AppLocalizations.of(context).oneUppercaseLetter,
                  isMet: _hasUppercase,
                ),
                _buildRequirement(
                  AppLocalizations.of(context).oneLowercaseLetter,
                  isMet: _hasLowercase,
                ),
                _buildRequirement(
                  AppLocalizations.of(context).oneNumber,
                  isMet: _hasNumber,
                ),
                if (widget.showDifferentCheck)
                  _buildRequirement(
                    AppLocalizations.of(context).differentFromCurrent,
                    isMet: _isDifferent,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
