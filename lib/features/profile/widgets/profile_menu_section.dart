import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../change_password_screen.dart';
import '../../../l10n/app_localizations.dart';

class ProfileMenuSection extends StatelessWidget {
  const ProfileMenuSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildMenuItem(
          context: context,
          icon: Icons.lock_outline,
          title: AppLocalizations.of(context).changePassword,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ChangePasswordScreen(),
              ),
            );
          },
        ),
        _buildMenuItem(
          context: context,
          icon: Icons.settings,
          title: AppLocalizations.of(context).settings,
          onTap: () => Navigator.pushNamed(context, '/settings'),
        ),
        _buildMenuItem(
          context: context,
          icon: Icons.privacy_tip_outlined,
          title: AppLocalizations.of(context).privacyPolicy,
          onTap: () => Navigator.pushNamed(context, '/legal/privacy-policy'),
        ),
        _buildMenuItem(
          context: context,
          icon: Icons.description_outlined,
          title: AppLocalizations.of(context).termsOfService,
          onTap: () => Navigator.pushNamed(context, '/legal/terms-of-service'),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.greyBorder.withOpacity(0.3)),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 20.sp),
            SizedBox(width: 16.w),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
              size: 20.sp,
            ),
          ],
        ),
      ),
    );
  }
}
