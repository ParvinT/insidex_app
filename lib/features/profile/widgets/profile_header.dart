import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/user_provider.dart';
import '../../../shared/widgets/custom_text_field.dart';

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
              width: 100.w,
              height: 100.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.greyLight,
                border: Border.all(
                  color: userProvider.isPremium
                      ? AppColors.primaryGold
                      : AppColors.greyBorder,
                  width: 3,
                ),
              ),
              child: Center(
                child: Text(
                  isEditing ? selectedAvatar : (userProvider.avatarEmoji ?? '👤'),
                  style: TextStyle(fontSize: 40.sp),
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
              label: 'Full Name',
              hint: 'Enter your name',
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