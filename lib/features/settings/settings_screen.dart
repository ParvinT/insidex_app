// lib/features/settings/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/user_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Settings states
  bool _notificationsEnabled = true;
  String _selectedLanguage = 'English';
  String _selectedTheme = 'Light';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppColors.textPrimary,
            size: 24.sp,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: GoogleFonts.inter(
            fontSize: 24.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Account Section
                _buildSectionHeader('Account'),
                SizedBox(height: 12.h),
                _buildSettingsCard([
                  _buildSettingItem(
                    icon: Icons.person_outline,
                    title: 'Edit Profile',
                    onTap: () => _handleProfileEdit(),
                  ),
                  _buildDivider(),
                  _buildSettingItem(
                    icon: Icons.logout_outlined,
                    title: 'Sign Out',
                    isDestructive: true,
                    onTap: () => _handleSignOut(),
                  ),
                ]),

                SizedBox(height: 32.h),

                // App Section
                _buildSectionHeader('App'),
                SizedBox(height: 12.h),
                _buildSettingsCard([
                  _buildSwitchItem(
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    subtitle: 'Receive reminders and updates',
                    value: _notificationsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _notificationsEnabled = value;
                      });
                    },
                  ),
                  _buildDivider(),
                  _buildSettingItem(
                    icon: Icons.language_outlined,
                    title: 'Language',
                    subtitle: _selectedLanguage,
                    onTap: () => _showLanguageDialog(),
                  ),
                  _buildDivider(),
                  _buildSettingItem(
                    icon: Icons.palette_outlined,
                    title: 'Theme',
                    subtitle: _selectedTheme,
                    onTap: () => _showThemeDialog(),
                  ),
                ]),

                SizedBox(height: 32.h),

                // About Section
                _buildSectionHeader('About'),
                SizedBox(height: 12.h),
                _buildSettingsCard([
                  _buildSettingItem(
                    icon: Icons.info_outline,
                    title: 'About',
                    onTap: () {
                      // TODO: Navigate to about screen
                    },
                  ),
                  _buildDivider(),
                  _buildSettingItem(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    onTap: () {
                      // Navigate to Privacy Policy screen
                      Navigator.pushNamed(context, AppRoutes.privacyPolicy);
                    },
                  ),
                  _buildDivider(),
                  _buildSettingItem(
                    icon: Icons.description_outlined,
                    title: 'Terms of Service',
                    onTap: () {
                      // Navigate to Terms of Service screen
                      Navigator.pushNamed(context, AppRoutes.termsOfService);
                    },
                  ),
                ]),

                SizedBox(height: 32.h),

                // Version info
                Center(
                  child: Text(
                    'Version 1.0.0',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: AppColors.textLight,
                    ),
                  ),
                ),

                SizedBox(height: 24.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 18.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.greyBorder,
          width: 1,
        ),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? subtitle,
    bool isDestructive = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: Row(
          children: [
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: isDestructive
                    ? Colors.red.withOpacity(0.1)
                    : AppColors.greyLight,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                icon,
                color: isDestructive ? Colors.red : AppColors.textPrimary,
                size: 20.sp,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      color: isDestructive ? Colors.red : AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: 2.h),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textLight,
              size: 16.sp,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: AppColors.greyLight,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              icon,
              color: AppColors.textPrimary,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.textPrimary,
            inactiveThumbColor: AppColors.textSecondary,
            inactiveTrackColor: AppColors.greyLight,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: EdgeInsets.only(left: 76.w),
      child: const Divider(
        height: 1,
        thickness: 1,
        color: AppColors.greyBorder,
      ),
    );
  }

  // Action Methods
  void _handleProfileEdit() {
    Navigator.pushNamed(context, AppRoutes.profile);
  }

  Future<void> _handleSignOut() async {
    // Show confirmation dialog
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'Sign Out',
          style: GoogleFonts.inter(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Sign Out',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldSignOut == true) {
      try {
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.welcome,
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to sign out: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'Select Language',
          style: GoogleFonts.inter(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption('English'),
            _buildLanguageOption('Turkish', isDisabled: true),
            _buildLanguageOption('Spanish', isDisabled: true),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String language, {bool isDisabled = false}) {
    return ListTile(
      title: Text(
        language,
        style: GoogleFonts.inter(
          fontSize: 14.sp,
          color: isDisabled ? AppColors.textLight : AppColors.textPrimary,
        ),
      ),
      trailing: _selectedLanguage == language && !isDisabled
          ? Icon(Icons.check, color: AppColors.textPrimary, size: 20.sp)
          : null,
      onTap: isDisabled
          ? null
          : () {
              setState(() {
                _selectedLanguage = language;
              });
              Navigator.pop(context);
            },
    );
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'Select Theme',
          style: GoogleFonts.inter(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeOption('Light'),
            _buildThemeOption('Dark'),
            _buildThemeOption('System'),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(String theme) {
    return ListTile(
      title: Text(
        theme,
        style: GoogleFonts.inter(
          fontSize: 14.sp,
          color: AppColors.textPrimary,
        ),
      ),
      trailing: _selectedTheme == theme
          ? Icon(Icons.check, color: AppColors.textPrimary, size: 20.sp)
          : null,
      onTap: () {
        setState(() {
          _selectedTheme = theme;
        });
        Navigator.pop(context);
      },
    );
  }
}
