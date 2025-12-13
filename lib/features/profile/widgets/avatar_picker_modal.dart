// lib/features/profile/widgets/avatar_picker_modal.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../../../core/themes/app_theme_extension.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/responsive/context_ext.dart';
import '../../../l10n/app_localizations.dart';

class AvatarPickerModal extends StatelessWidget {
  final String selectedAvatar;
  final Function(String) onAvatarSelected;

  const AvatarPickerModal({
    super.key,
    required this.selectedAvatar,
    required this.onAvatarSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // Responsive values
    final isTablet = context.isTablet;
    final isDesktop = context.isDesktop;
    final screenHeight = context.h;

    // Adaptive sizing
    final double modalHeight = isDesktop
        ? screenHeight * 0.6
        : (isTablet ? screenHeight * 0.55 : screenHeight * 0.5);

    final double horizontalPadding =
        isDesktop ? 32.w : (isTablet ? 24.w : 20.w);

    final double borderRadius = isDesktop ? 28.r : (isTablet ? 24.r : 20.r);

    final double titleSize =
        isTablet ? 22.sp.clamp(20.0, 24.0) : 20.sp.clamp(18.0, 22.0);

    final int crossAxisCount = isDesktop ? 4 : (isTablet ? 3 : 3);

    final double avatarSize = isDesktop ? 80.w : (isTablet ? 75.w : 65.w);

    final double gridSpacing = isTablet ? 20.w : 16.w;

    return Container(
      height: modalHeight,
      decoration: BoxDecoration(
        color: colors.backgroundElevated,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(borderRadius),
          topRight: Radius.circular(borderRadius),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: 12.h),
            width: isTablet ? 50.w : 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: colors.greyMedium,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),

          // Title
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: isTablet ? 20.h : 16.h,
            ),
            child: Text(
              AppLocalizations.of(context).chooseAvatar,
              style: GoogleFonts.inter(
                fontSize: titleSize,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
          ),

          // Avatar Grid
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 8.h,
              ),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: gridSpacing,
                mainAxisSpacing: gridSpacing,
                childAspectRatio: 1.0,
              ),
              itemCount: AppIcons.avatarIcons.length,
              itemBuilder: (context, index) {
                final avatar = AppIcons.avatarIcons[index];
                final isSelected = avatar['name'] == selectedAvatar;

                return GestureDetector(
                  onTap: () {
                    onAvatarSelected(avatar['name']);
                    Navigator.pop(context);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colors.textPrimary.withValues(alpha: 0.15)
                          : colors.greyLight,
                      borderRadius:
                          BorderRadius.circular(isTablet ? 18.r : 16.r),
                      border: Border.all(
                        color: isSelected
                            ? colors.textPrimary
                            : Colors.transparent,
                        width: 2.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color:
                                    colors.textPrimary.withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Lottie Animation
                        SizedBox(
                          width: avatarSize,
                          height: avatarSize,
                          child: Lottie.asset(
                            AppIcons.getAvatarAnimationPath(avatar['path']),
                            fit: BoxFit.contain,
                            repeat: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom safe area
          SizedBox(height: context.bottomPad + 16.h),
        ],
      ),
    );
  }
}
