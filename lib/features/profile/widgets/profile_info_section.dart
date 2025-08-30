import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/user_provider.dart';

class ProfileInfoSection extends StatelessWidget {
  final UserProvider userProvider;

  const ProfileInfoSection({
    super.key,
    required this.userProvider,
  });

  @override
  Widget build(BuildContext context) {
    final userData = userProvider.userData ?? {};
    final createdAt = userData['createdAt']?.toDate() ?? DateTime.now();
    final memberSince = '${_getMonthName(createdAt.month)} ${createdAt.year}';

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.greyBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Information',
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16.h),
          _buildInfoRow('Member Since', memberSince),
          SizedBox(height: 12.h),
          _buildInfoRow(
            'Account Type',
            userProvider.isPremium ? 'Premium' : 'Free',
            isPremium: userProvider.isPremium,
          ),
          if (userProvider.isAdmin) ...[
            SizedBox(height: 12.h),
            _buildInfoRow('Role', 'Administrator', isAdmin: true),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value,
      {bool isPremium = false, bool isAdmin = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            color: AppColors.textSecondary,
          ),
        ),
        Container(
          padding: isPremium || isAdmin
              ? EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h)
              : null,
          decoration: isPremium || isAdmin
              ? BoxDecoration(
                  color: isAdmin
                      ? Colors.red.withOpacity(0.1)
                      : AppColors.primaryGold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: isAdmin ? Colors.red : AppColors.primaryGold,
                  ),
                )
              : null,
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight:
                  isPremium || isAdmin ? FontWeight.w600 : FontWeight.w500,
              color: isAdmin
                  ? Colors.red
                  : isPremium
                      ? AppColors.primaryGold
                      : AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}