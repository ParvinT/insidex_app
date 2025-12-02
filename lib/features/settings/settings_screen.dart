// lib/features/settings/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../feedback/feedback_dialog.dart';
import '../notifications/notification_settings_screen.dart';
import '../../services/auth_persistence_service.dart';
import '../../services/audio/audio_player_service.dart';
import '../../providers/mini_player_provider.dart';
import 'widgets/language_selector.dart';
import '../../l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Settings states

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final screenSize = mq.size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final bool isTablet = screenWidth >= 600 && screenWidth < 1024;
    final bool isShortWide =
        screenWidth >= 1024 && screenHeight <= 800; // Nest Hub (Max)
    final bool isDesktop = screenWidth >= 1024 && !isShortWide;
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        toolbarHeight: (isTablet || isDesktop) ? 72 : kToolbarHeight,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppColors.textPrimary,
            size: 24.sp.clamp(24.0, 26.0),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context).settings,
          style: GoogleFonts.inter(
            fontSize: 24.sp.clamp(24.0, 28.0),
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
                _buildSectionHeader(AppLocalizations.of(context).account),
                SizedBox(height: 12.h),
                _buildSettingsCard([
                  _buildSettingItem(
                    icon: Icons.person_outline,
                    title: AppLocalizations.of(context).editProfile,
                    onTap: () => _handleProfileEdit(),
                  ),
                  _buildDivider(),
                  _buildSettingItem(
                    icon: Icons.logout_outlined,
                    title: AppLocalizations.of(context).signOut,
                    isDestructive: true,
                    onTap: () => _handleSignOut(),
                  ),
                ]),

                SizedBox(height: 32.h),

                _buildSectionHeader(AppLocalizations.of(context).app),
                SizedBox(height: 12.h),
                _buildSettingsCard([
                  _buildSettingItem(
                    icon: Icons.notifications_outlined,
                    title: AppLocalizations.of(context).notifications,
                    subtitle:
                        AppLocalizations.of(context).notificationsSubtitle,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const NotificationSettingsScreen(),
                        ),
                      );
                    },
                  ),
                ]),

                SizedBox(height: 32.h),

                _buildSectionHeader(AppLocalizations.of(context).language),
                SizedBox(height: 12.h),
                const LanguageSelector(),

                SizedBox(height: 32.h),
                _buildSectionHeader(
                    AppLocalizations.of(context).supportAndFeedback),
                SizedBox(height: 12.h),
                _buildSettingsCard([
                  _buildSettingItem(
                    icon: Icons.feedback_outlined,
                    title: AppLocalizations.of(context).sendFeedback,
                    subtitle: AppLocalizations.of(context).sendFeedbackSubtitle,
                    onTap: () => _showFeedbackDialog(),
                  ),
                  _buildDivider(),
                  _buildSettingItem(
                    icon: Icons.bug_report_outlined,
                    title: AppLocalizations.of(context).reportBug,
                    subtitle: AppLocalizations.of(context).reportBugSubtitle,
                    onTap: () => _showFeedbackDialog(isBugReport: true),
                  ),
                ]),

                SizedBox(height: 32.h),

                // About Section
                _buildSectionHeader(AppLocalizations.of(context).about),
                SizedBox(height: 12.h),
                _buildSettingsCard([
                  _buildSettingItem(
                    icon: Icons.info_outline,
                    title: AppLocalizations.of(context).aboutApp,
                    onTap: () => Navigator.pushNamed(context, AppRoutes.about),
                  ),
                  _buildDivider(),
                  _buildSettingItem(
                    icon: Icons.warning_amber_rounded,
                    title: AppLocalizations.of(context).disclaimer,
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.disclaimer),
                  ),
                  _buildDivider(),
                  _buildSettingItem(
                    icon: Icons.privacy_tip_outlined,
                    title: AppLocalizations.of(context).privacyPolicy,
                    onTap: () {
                      // Navigate to Privacy Policy screen
                      Navigator.pushNamed(context, AppRoutes.privacyPolicy);
                    },
                  ),
                  _buildDivider(),
                  _buildSettingItem(
                    icon: Icons.description_outlined,
                    title: AppLocalizations.of(context).termsOfService,
                    onTap: () {
                      // Navigate to Terms of Service screen
                      Navigator.pushNamed(context, AppRoutes.termsOfService);
                    },
                  ),
                ]),

                // Version info
                Center(
                  child: Text(
                    '${AppLocalizations.of(context).version} 1.0.0',
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
    AppRoutes.navigateToProfile(context);
  }

  void _showFeedbackDialog({bool isBugReport = false}) {
    FeedbackDialog.show(context, isBugReport: isBugReport);
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
          AppLocalizations.of(context).signOutConfirmTitle,
          style: GoogleFonts.inter(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          AppLocalizations.of(context).signOutConfirmMessage,
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              AppLocalizations.of(context).cancel,
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              AppLocalizations.of(context).confirm,
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
        debugPrint('🎵 [Settings] Stopping audio before logout...');
        try {
          final audioService = AudioPlayerService();
          await audioService.stop();
          debugPrint('✅ [Settings] Audio stopped');
        } catch (e) {
          debugPrint('⚠️ [Settings] Audio stop error: $e');
        }

        debugPrint('🎵 [Settings] Dismissing mini player...');
        try {
          final miniPlayerProvider = context.read<MiniPlayerProvider>();
          miniPlayerProvider.dismiss();
          debugPrint('✅ [Settings] Mini player dismissed');
        } catch (e) {
          debugPrint('⚠️ [Settings] Mini player dismiss error: $e');
        }

        await AuthPersistenceService.clearSession();

        await FirebaseAuth.instance.signOut();

        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('has_logged_in');
        await prefs.remove('cached_user_id');
        await prefs.remove('cached_user_email');

        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.welcome,
            (route) => false,
          );
        }
      } catch (e) {
        debugPrint('❌ Sign out error: $e');
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
}
