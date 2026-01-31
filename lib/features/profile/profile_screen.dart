import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/themes/app_theme_extension.dart';
import '../../providers/user_provider.dart';
import '../../core/routes/app_routes.dart';
import '../../l10n/app_localizations.dart';
import '../downloads/downloads_screen.dart';
import 'widgets/profile_header.dart';
import 'widgets/profile_info_section.dart';
import 'widgets/profile_action_button.dart';
import 'widgets/profile_menu_section.dart';
import 'widgets/avatar_picker_modal.dart';
import 'progress_screen.dart';
import '../../services/auth_persistence_service.dart';
import '../../services/audio/audio_player_service.dart';
import '../../providers/mini_player_provider.dart';
import '../../shared/widgets/upgrade_prompt.dart';
import '../../providers/subscription_provider.dart';
import '../subscription/paywall_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  bool _isEditing = false;
  String _selectedAvatar = 'turtle';

  @override
  void initState() {
    super.initState();
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/auth/login');
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final userProvider = context.read<UserProvider>();
        setState(() {
          _nameController.text = userProvider.userName;
          _selectedAvatar = userProvider.avatarEmoji;
        });
      });
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
    final userProvider = context.read<UserProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final successText = AppLocalizations.of(context).profileUpdated;
    final errorText = AppLocalizations.of(context).errorUpdatingProfile;
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

      await userProvider.updateProfile(
        name: _nameController.text.trim(),
        avatarEmoji: _selectedAvatar,
      );

      setState(() {
        _isEditing = false;
      });

      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(successText),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(errorText),
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

  String _getSubscriptionSubtitle(
      BuildContext context, SubscriptionProvider provider) {
    final l10n = AppLocalizations.of(context);
    final tierName = provider.tier.displayName;

    if (provider.isInTrial) {
      final daysLeft = provider.trialDaysRemaining;
      return l10n.profileSubtitleTrial(tierName, daysLeft);
    }

    final daysLeft = provider.daysRemaining;
    if (daysLeft > 0) {
      return l10n.profileSubtitleDaysRemaining(tierName, daysLeft);
    }

    return l10n.profileSubtitlePlan(tierName);
  }

  Future<void> _handleSignOut() async {
    final miniPlayerProvider = context.read<MiniPlayerProvider>();
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
              style: GoogleFonts.inter(color: context.colors.textSecondary),
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
        miniPlayerProvider.dismiss();
        debugPrint('✅ [Profile] Mini player dismissed');
      } catch (e) {
        debugPrint('⚠️ [Profile] Mini player dismiss error: $e');
      }
      await AuthPersistenceService.fullLogout();
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
    final colors = context.colors;
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
      return Scaffold(
        backgroundColor: colors.background,
        body:
            Center(child: CircularProgressIndicator(color: colors.textPrimary)),
      );
    }

    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        return Scaffold(
          backgroundColor: colors.background,
          appBar: AppBar(
            backgroundColor: colors.background,
            elevation: 0,
            centerTitle: true,
            toolbarHeight: (isTablet || isDesktop) ? 72 : kToolbarHeight,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: colors.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              AppLocalizations.of(context).profile,
              style: GoogleFonts.inter(
                fontSize: 20.sp.clamp(20.0, 22.0),
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
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
                    color: colors.textPrimary,
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
                    const Color(0xFF7DB9B6).withValues(alpha: 0.1),
                    const Color(0xFFB8A6D9).withValues(alpha: 0.1),
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
                    const Color(0xFFE8C5A0).withValues(alpha: 0.1),
                    const Color(0xFF7DB9B6).withValues(alpha: 0.1),
                  ],
                  borderColor: const Color(0xFFE8C5A0),
                  iconBackgroundColor: const Color(0xFFE8C5A0),
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.myInsights),
                ),
                SizedBox(height: 20.h),
                // Downloads button
                ProfileActionButton(
                  icon: Icons.download_rounded,
                  title: AppLocalizations.of(context).downloads,
                  subtitle: AppLocalizations.of(context).offlineListening,
                  gradientColors: [
                    const Color(0xFF6B8E9B).withValues(alpha: 0.1),
                    const Color(0xFF4A7C8C).withValues(alpha: 0.1),
                  ],
                  borderColor: const Color(0xFF6B8E9B),
                  iconBackgroundColor: const Color(0xFF6B8E9B),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DownloadsScreen()),
                  ),
                ),

                SizedBox(height: 20.h),
                Consumer<SubscriptionProvider>(
                  builder: (context, subProvider, _) {
                    // Premium user - show subscription info
                    if (subProvider.isActive) {
                      return Column(
                        children: [
                          ProfileActionButton(
                            icon: Icons.workspace_premium,
                            title: AppLocalizations.of(context)
                                .profileSubscriptionTitle,
                            subtitle:
                                _getSubscriptionSubtitle(context, subProvider),
                            gradientColors: [
                              Colors.amber.withValues(alpha: 0.15),
                              Colors.orange.withValues(alpha: 0.1),
                            ],
                            borderColor: Colors.amber,
                            iconBackgroundColor: Colors.amber.shade700,
                            onTap: () => showManageSubscriptionSheet(context),
                          ),
                          SizedBox(height: 20.h),
                        ],
                      );
                    }

                    // Free user - show upgrade button
                    return Column(
                      children: [
                        ProfileActionButton(
                          icon: Icons.workspace_premium,
                          title: AppLocalizations.of(context)
                              .profileUpgradeToPremium,
                          subtitle: AppLocalizations.of(context)
                              .profileUnlockAllFeatures,
                          gradientColors: [
                            Colors.amber.withValues(alpha: 0.15),
                            Colors.orange.withValues(alpha: 0.1),
                          ],
                          borderColor: Colors.amber,
                          iconBackgroundColor: Colors.amber.shade700,
                          onTap: () => showPaywall(context),
                        ),
                        SizedBox(height: 20.h),
                      ],
                    );
                  },
                ),
                if (userProvider.isAdmin) ...[
                  ProfileActionButton(
                    icon: Icons.admin_panel_settings,
                    title: AppLocalizations.of(context).adminDashboard,
                    subtitle:
                        AppLocalizations.of(context).manageUsersAndSessions,
                    gradientColors: [
                      Colors.red.withValues(alpha: 0.1),
                      Colors.orange.withValues(alpha: 0.1),
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
                      backgroundColor: Colors.red.withValues(alpha: 0.1),
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
