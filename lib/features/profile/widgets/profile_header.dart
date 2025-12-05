import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/responsive/context_ext.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/user_provider.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../l10n/app_localizations.dart';

class ProfileHeader extends StatelessWidget {
  final UserProvider userProvider;
  final bool isEditing;
  final String selectedAvatar;
  final TextEditingController nameController;
  final VoidCallback onAvatarTap;

  const ProfileHeader({
    super.key,
    required this.userProvider,
    required this.isEditing,
    required this.selectedAvatar,
    required this.nameController,
    required this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: context.isTablet ? 120.w : 100.w,
              height: context.isTablet ? 120.w : 100.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.greyLight,
                border: Border.all(
                  color: userProvider.isPremium
                      ? AppColors.textPrimary
                      : AppColors.greyBorder,
                  width: 3,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(context.isTablet ? 14.w : 12.w),
                child: Lottie.asset(
                  AppIcons.getAvatarPath(
                    isEditing ? selectedAvatar : userProvider.avatarEmoji,
                  ),
                  fit: BoxFit.contain,
                  repeat: true,
                ),
              ),
            ),
            if (isEditing)
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: onAvatarTap,
                  child: Container(
                    width: 32.w,
                    height: 32.w,
                    decoration: BoxDecoration(
                      color: AppColors.textPrimary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(
                      Icons.edit,
                      size: 16.sp,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 16.h),
        if (isEditing)
          SizedBox(
            width: 200.w,
            child: CustomTextField(
              controller: nameController,
              label: AppLocalizations.of(context).fullName,
              hint: AppLocalizations.of(context).enterYourName,
            ),
          )
        else
          Text(
            userProvider.userName,
            style: GoogleFonts.inter(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        SizedBox(height: 4.h),
        Text(
          userProvider.userEmail,
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
