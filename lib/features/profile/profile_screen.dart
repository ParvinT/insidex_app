// lib/features/profile/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/user_provider.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/widgets/primary_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  bool _isEditing = false;
  String _selectedAvatar = '👤';

  // Available avatars for selection
  final List<String> _availableAvatars = [
    '👤',
    '😊',
    '🧘',
    '✨',
    '🌙',
    '⚡',
    '💫',
    '🦋'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        // Cancel editing - reset the name
        final userProvider = context.read<UserProvider>();
        _nameController.text = userProvider.userName;
      }
    });
  }

  Future<void> _saveProfile() async {
    final userProvider = context.read<UserProvider>();

    setState(() => _isEditing = false);

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    // Update profile
    final success = await userProvider.updateProfile(
      name: _nameController.text.trim(),
    );

    // Hide loading
    if (mounted) Navigator.pop(context);

    // Show result
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Profile updated successfully'
                : 'Failed to update profile',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _handleSignOut() async {
    // Show confirmation dialog
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Sign Out',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Sign Out',
              style: GoogleFonts.inter(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (shouldSignOut == true) {
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
  void initState() {
    super.initState();
    // Check if user is logged in on init
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/auth/login');
      });
    } else {
      final userProvider = context.read<UserProvider>();
      _nameController.text = userProvider.userName;
    }
  }

  @override
  Widget build(BuildContext context) {
    // First check if user is logged in
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      // No user logged in, redirect to login
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
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Profile',
              style: GoogleFonts.inter(
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            actions: [
              TextButton(
                onPressed: _isEditing ? _saveProfile : _toggleEditMode,
                child: Text(
                  _isEditing ? 'Save' : 'Edit',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: _isEditing
                        ? AppColors.primaryGold
                        : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(20.w),
            child: Column(
              children: [
                // Avatar Section
                _buildAvatarSection(userProvider),
                SizedBox(height: 32.h),

                // User Info Section
                _buildUserInfoSection(userProvider),
                SizedBox(height: 24.h),

                // Stats Section
                _buildStatsSection(userProvider),
                SizedBox(height: 24.h),

                // Premium Badge (if applicable)
                if (!userProvider.isPremium) ...[
                  _buildPremiumPrompt(),
                  SizedBox(height: 16.h),
                ],

                // Admin Badge (if applicable)
                if (userProvider.isAdmin) ...[
                  _buildAdminBadge(),
                  SizedBox(height: 16.h),
                  _buildAdminPanelButton(),
                  SizedBox(height: 16.h),
                ],

                SizedBox(height: 16.h),

                // Sign Out Button
                _buildSignOutButton(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvatarSection(UserProvider userProvider) {
    return Column(
      children: [
        Stack(
          children: [
            // Avatar circle
            Container(
              width: 100.w,
              height: 100.w,
              decoration: BoxDecoration(
                color: AppColors.greyLight,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primaryGold,
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  _selectedAvatar,
                  style: TextStyle(fontSize: 40.sp),
                ),
              ),
            ),

            // Edit icon
            if (_isEditing)
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => _showAvatarPicker(),
                  child: Container(
                    width: 32.w,
                    height: 32.w,
                    decoration: BoxDecoration(
                      color: AppColors.primaryGold,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
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

        // User name
        if (_isEditing)
          SizedBox(
            width: 200.w,
            child: CustomTextField(
              controller: _nameController,
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

        // User email
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

  Widget _buildUserInfoSection(UserProvider userProvider) {
    final userData = userProvider.userData ?? {};
    final createdAt = userData['createdAt']?.toDate() ?? DateTime.now();
    final memberSince = '${_getMonthName(createdAt.month)} ${createdAt.year}';

    return Container(
      padding: EdgeInsets.all(20.w),
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

  Widget _buildStatsSection(UserProvider userProvider) {
    final userData = userProvider.userData ?? {};

    return Container(
      padding: EdgeInsets.all(20.w),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Journey',
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              _buildStatItem(
                icon: Icons.headphones,
                value: '${userData['totalListeningMinutes'] ?? 0}',
                label: 'Minutes',
                color: AppColors.primaryGold,
              ),
              SizedBox(width: 16.w),
              _buildStatItem(
                icon: Icons.check_circle,
                value:
                    '${(userData['completedSessionIds'] as List?)?.length ?? 0}',
                label: 'Completed',
                color: Colors.green,
              ),
              SizedBox(width: 16.w),
              _buildStatItem(
                icon: Icons.favorite,
                value:
                    '${(userData['favoriteSessionIds'] as List?)?.length ?? 0}',
                label: 'Favorites',
                color: Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: color.withOpacity(0.2),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24.sp,
              color: color,
            ),
            SizedBox(height: 8.h),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumPrompt() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryGold.withOpacity(0.1),
            AppColors.primaryGoldLight.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.primaryGold.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.star,
            color: AppColors.primaryGold,
            size: 32.sp,
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Upgrade to Premium',
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Unlock all sessions and features',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            color: AppColors.primaryGold,
            size: 16.sp,
          ),
        ],
      ),
    );
  }

  Widget _buildAdminBadge() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.red.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.admin_panel_settings,
            color: Colors.red,
            size: 24.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Administrator Access',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
                Text(
                  'You have full admin privileges',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: Colors.red.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.verified,
            color: Colors.red,
            size: 20.sp,
          ),
        ],
      ),
    );
  }

  Widget _buildAdminPanelButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.pushNamed(context, '/admin/dashboard');
        },
        icon: const Icon(Icons.dashboard_customize),
        label: Text(
          'Open Admin Panel',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 14.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  Widget _buildSignOutButton() {
    return SizedBox(
      width: double.infinity,
      child: PrimaryButton(
        text: 'Sign Out',
        onPressed: _handleSignOut,
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showAvatarPicker() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Choose Avatar',
              style: GoogleFonts.inter(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 20.h),
            Wrap(
              spacing: 16.w,
              runSpacing: 16.h,
              children: _availableAvatars.map((avatar) {
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedAvatar = avatar);
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 60.w,
                    height: 60.w,
                    decoration: BoxDecoration(
                      color: _selectedAvatar == avatar
                          ? AppColors.primaryGold.withOpacity(0.2)
                          : AppColors.greyLight,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _selectedAvatar == avatar
                            ? AppColors.primaryGold
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        avatar,
                        style: TextStyle(fontSize: 28.sp),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }
}
