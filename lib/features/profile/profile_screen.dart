import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/user_provider.dart';
import '../../core/routes/app_routes.dart';
import '../../l10n/app_localizations.dart';
import 'widgets/profile_header.dart';
import 'widgets/profile_info_section.dart';
import 'widgets/profile_action_button.dart';
import 'widgets/profile_menu_section.dart';
import 'widgets/avatar_picker_modal.dart';
import 'progress_screen.dart';
import '../../services/auth_persistence_service.dart';
import '../../services/audio/audio_player_service.dart';
import '../../providers/mini_player_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  bool _isEditing = false;
  String _selectedAvatar = 'turtle';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/auth/login');
      });
    } else {
      final userProvider = context.read<UserProvider>();
      _nameController.text = userProvider.userName;
      _selectedAvatar = userProvider.avatarEmoji;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        final userProvider = context.read<UserProvider>();
        _nameController.text = userProvider.userName;
        _selectedAvatar = userProvider.avatarEmoji;
      }
    });
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'name': _nameController.text.trim(),
        'avatarEmoji': _selectedAvatar,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final userProvider = context.read<UserProvider>();
      await userProvider.updateProfile(
        name: _nameController.text.trim(),
        avatarEmoji: _selectedAvatar,
      );

      setState(() {
        _isEditing = false;
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).profileUpdated),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).errorUpdatingProfile),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAvatarPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => AvatarPickerModal(
        selectedAvatar: _selectedAvatar,
        onAvatarSelected: (avatar) {
          setState(() {
            _selectedAvatar = avatar;
          });
        },
      ),
    );
  }

  Future<void> _handleSignOut() async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppLocalizations.of(context).signOutConfirmTitle,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Text(
          AppLocalizations.of(context).signOutConfirmMessage,
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              AppLocalizations.of(context).cancel,
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              AppLocalizations.of(context).signOut,
              style: GoogleFonts.inter(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (shouldSignOut == true) {
      debugPrint('🎵 [Profile] Stopping audio before logout...');
      try {
        final audioService = AudioPlayerService();
        await audioService.stop();
        debugPrint('✅ [Profile] Audio stopped');
      } catch (e) {
        debugPrint('⚠️ [Profile] Audio stop error: $e');
      }

      debugPrint('🎵 [Profile] Dismissing mini player...');
      try {
        final miniPlayerProvider = context.read<MiniPlayerProvider>();
        miniPlayerProvider.dismiss();
        debugPrint('✅ [Profile] Mini player dismissed');
      } catch (e) {
        debugPrint('⚠️ [Profile] Mini player dismiss error: $e');
      }
      await AuthPersistenceService.clearSession();
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/auth/welcome',
          (route) => false,
        );
      }
    }
  }

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
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundWhite,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        return Scaffold(
          backgroundColor: AppColors.backgroundWhite,
          appBar: AppBar(
            backgroundColor: AppColors.backgroundWhite,
            elevation: 0,
            centerTitle: true,
            toolbarHeight: (isTablet || isDesktop) ? 72 : kToolbarHeight,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              AppLocalizations.of(context).profile,
              style: GoogleFonts.inter(
                fontSize: 20.sp.clamp(20.0, 22.0),
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            actions: [
              TextButton(
                onPressed: _isEditing ? _saveProfile : _toggleEditMode,
                child: Text(
                  _isEditing
                      ? AppLocalizations.of(context).save
                      : AppLocalizations.of(context).edit,
                  style: GoogleFonts.inter(
                    fontSize: 14.sp.clamp(14.0, 18.0),
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryGold,
                  ),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(20.w),
            child: Column(
              children: [
                ProfileHeader(
                  userProvider: userProvider,
                  isEditing: _isEditing,
                  selectedAvatar: _selectedAvatar,
                  nameController: _nameController,
                  onAvatarTap: _showAvatarPicker,
                ),
                SizedBox(height: 32.h),
                ProfileInfoSection(userProvider: userProvider),
                SizedBox(height: 20.h),
                ProfileActionButton(
                  icon: Icons.analytics_outlined,
                  title: AppLocalizations.of(context).yourProgress,
                  subtitle: AppLocalizations.of(context).trackYourListening,
                  gradientColors: [
                    const Color(0xFF7DB9B6).withOpacity(0.1),
                    const Color(0xFFB8A6D9).withOpacity(0.1),
                  ],
                  borderColor: const Color(0xFF7DB9B6),
                  iconBackgroundColor: const Color(0xFF7DB9B6),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ProgressScreen()),
                    );
                  },
                ),
                SizedBox(height: 20.h),
                ProfileActionButton(
                  icon: Icons.insights_outlined,
                  title: AppLocalizations.of(context).myInsights,
                  subtitle:
                      AppLocalizations.of(context).viewPersonalizedWellness,
                  gradientColors: [
                    const Color(0xFFE8C5A0).withOpacity(0.1),
                    const Color(0xFF7DB9B6).withOpacity(0.1),
                  ],
                  borderColor: const Color(0xFFE8C5A0),
                  iconBackgroundColor: const Color(0xFFE8C5A0),
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.myInsights),
                ),
                SizedBox(height: 20.h),
                ProfileActionButton(
                  icon: Icons.star_rounded,
                  title: AppLocalizations.of(context).premiumWaitlist,
                  subtitle: AppLocalizations.of(context).joinEarlyAccess,
                  gradientColors: [
                    AppColors.primaryGold.withOpacity(0.15),
                    AppColors.primaryGold.withOpacity(0.05),
                  ],
                  borderColor: AppColors.primaryGold,
                  iconBackgroundColor: AppColors.primaryGold,
                  isGradientIcon: true,
                  onTap: () =>
                      Navigator.pushNamed(context, '/premium/waitlist'),
                ),
                SizedBox(height: 20.h),
                if (userProvider.isAdmin) ...[
                  ProfileActionButton(
                    icon: Icons.admin_panel_settings,
                    title: AppLocalizations.of(context).adminDashboard,
                    subtitle:
                        AppLocalizations.of(context).manageUsersAndSessions,
                    gradientColors: [
                      Colors.red.withOpacity(0.1),
                      Colors.orange.withOpacity(0.1),
                    ],
                    borderColor: Colors.red,
                    iconBackgroundColor: Colors.red,
                    onTap: () =>
                        Navigator.pushNamed(context, '/admin/dashboard'),
                  ),
                  SizedBox(height: 20.h),
                ],
                const ProfileMenuSection(),
                SizedBox(height: 32.h),
                SizedBox(
                  width: double.infinity,
                  height: 70.h,
                  child: ElevatedButton(
                    onPressed: _handleSignOut,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.withOpacity(0.1),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context).signOut,
                      style: GoogleFonts.inter(
                        fontSize: (18.sp).clamp(18.0, 22.0),
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
