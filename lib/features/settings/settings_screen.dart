import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _offlineDownload = false;
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
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 24.h),

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

              // Audio Section
              _buildSectionHeader('Audio'),
              SizedBox(height: 12.h),
              _buildSettingsCard([
                _buildSwitchItem(
                  icon: Icons.download_outlined,
                  title: 'Offline Download',
                  subtitle: 'Download sessions for offline use',
                  value: _offlineDownload,
                  onChanged: (value) {
                    setState(() {
                      _offlineDownload = value;
                    });
                  },
                ),
              ]),

              SizedBox(height: 32.h),

              // Legal Section
              _buildSectionHeader('Legal'),
              SizedBox(height: 12.h),
              _buildSettingsCard([
                _buildSettingItem(
                  icon: Icons.description_outlined,
                  title: 'Terms of Service',
                  onTap: () => _handleTermsOfService(),
                ),
                _buildDivider(),
                _buildSettingItem(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  onTap: () => _handlePrivacyPolicy(),
                ),
                _buildDivider(),
                _buildSettingItem(
                  icon: Icons.code_outlined,
                  title: 'Licenses',
                  onTap: () => _handleLicenses(),
                ),
              ]),

              SizedBox(height: 32.h),

              // About Section
              _buildSectionHeader('About'),
              SizedBox(height: 12.h),
              _buildSettingsCard([
                _buildSettingItem(
                  icon: Icons.info_outline,
                  title: 'App Version',
                  subtitle: '1.0.0',
                  showArrow: false,
                ),
                _buildDivider(),
                _buildSettingItem(
                  icon: Icons.email_outlined,
                  title: 'Contact Us',
                  onTap: () => _handleContactUs(),
                ),
                _buildDivider(),
                _buildSettingItem(
                  icon: Icons.star_outline,
                  title: 'Rate App',
                  onTap: () => _handleRateApp(),
                ),
              ]),

              SizedBox(height: 40.h),
            ],
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
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? subtitle,
    bool showArrow = true,
    bool isDestructive = false,
    VoidCallback? onTap,
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
            if (showArrow && onTap != null)
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
      child: Divider(
        height: 1,
        thickness: 1,
        color: AppColors.greyBorder,
      ),
    );
  }

  // Action Methods
  void _handleProfileEdit() {
    print('Edit Profile tapped');
    // TODO: Navigate to profile edit screen
  }

  void _handleSignOut() {
    showDialog(
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
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Handle sign out
              print('User signed out');
            },
            child: Text(
              'Sign Out',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
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
            _buildLanguageOption('Coming Soon...', isDisabled: true),
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
      trailing: _selectedLanguage == language
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
            _buildThemeOption('Dark', isDisabled: true),
            _buildThemeOption('System', isDisabled: true),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(String theme, {bool isDisabled = false}) {
    return ListTile(
      title: Row(
        children: [
          Text(
            theme,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              color: isDisabled ? AppColors.textLight : AppColors.textPrimary,
            ),
          ),
          if (isDisabled) ...[
            SizedBox(width: 8.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: AppColors.greyLight,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                  color: AppColors.greyBorder,
                  width: 1,
                ),
              ),
              child: Text(
                'Coming Soon',
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
      trailing: _selectedTheme == theme
          ? Icon(Icons.check, color: AppColors.textPrimary, size: 20.sp)
          : null,
      onTap: isDisabled
          ? null
          : () {
              setState(() {
                _selectedTheme = theme;
              });
              Navigator.pop(context);
            },
    );
  }

  void _handleTermsOfService() {
    print('Terms of Service tapped');
    // TODO: Navigate to terms screen or show web view
  }

  void _handlePrivacyPolicy() {
    print('Privacy Policy tapped');
    // TODO: Navigate to privacy policy screen or show web view
  }

  void _handleLicenses() {
    showLicensePage(
      context: context,
      applicationName: 'INSIDEX',
      applicationVersion: '1.0.0',
    );
  }

  void _handleContactUs() {
    print('Contact Us tapped');
    // TODO: Open email or contact form
  }

  void _handleRateApp() {
    print('Rate App tapped');
    // TODO: Open app store rating
  }
}
