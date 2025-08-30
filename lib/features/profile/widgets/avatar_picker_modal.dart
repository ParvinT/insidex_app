import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';

class AvatarPickerModal extends StatelessWidget {
  final String selectedAvatar;
  final Function(String) onAvatarSelected;

  static final List<String> availableAvatars = [
    '👤',
    '😊',
    '😎',
    '🤓',
    '🧑‍💻',
    '👨‍🎨',
    '👩‍🏫',
    '🧑‍🚀',
    '🦄',
    '🐼',
    '🦋',
    '🐢',
    '🦉',
    '🐙',
    '🦊',
    '🐨',
    '🌟',
    '⭐',
    '✨',
    '💫',
    '🔥',
    '⚡',
    '🌈',
    '🌙',
    '🎯',
    '🎨',
    '🎭',
    '🎪',
    '🎸',
    '🎮',
    '🧩',
    '🎲'
  ];

  const AvatarPickerModal({
    super.key,
    required this.selectedAvatar,
    required this.onAvatarSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
      ),
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.only(top: 12.h),
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20.w),
            child: Text(
              'Choose Avatar',
              style: GoogleFonts.inter(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.all(20.w),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                crossAxisSpacing: 12.w,
                mainAxisSpacing: 12.h,
              ),
              itemCount: availableAvatars.length,
              itemBuilder: (context, index) {
                final avatar = availableAvatars[index];
                final isSelected = avatar == selectedAvatar;

                return GestureDetector(
                  onTap: () {
                    onAvatarSelected(avatar);
                    Navigator.pop(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryGold.withOpacity(0.2)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryGold
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        avatar,
                        style: TextStyle(fontSize: 24.sp),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
