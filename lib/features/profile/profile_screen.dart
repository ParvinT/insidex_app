import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/widgets/primary_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  // Static data - Firebase bağlandığında buralar değişecek
  String _selectedAvatar = '👤';
  bool _isEditing = false;

  // Mock user data - Firebase'den gelecek
  final Map<String, dynamic> _mockUserData = {
    'name': 'John Doe',
    'email': 'john.doe@example.com',
    'joinDate': 'October 2024',
    'sessionsListened': 45,
    'totalMinutes': 320,
    'favoriteCategory': 'Sleep',
    'avatar': '👤',
  };

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
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    // Firebase'den veri gelince bu method'u güncelleyeceğiz
    _nameController.text = _mockUserData['name'];
    _emailController.text = _mockUserData['email'];
    _selectedAvatar = _mockUserData['avatar'];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

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
          'Profile',
          style: GoogleFonts.inter(
            fontSize: 24.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _toggleEditMode,
            child: Text(
              _isEditing ? 'Cancel' : 'Edit',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: _isEditing ? Colors.red : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            children: [
              SizedBox(height: 20.h),

              // Avatar Section
              _buildAvatarSection(),

              SizedBox(height: 32.h),

              // User Info Section
              _buildUserInfoSection(),

              SizedBox(height: 32.h),

              // Stats Section
              _buildStatsSection(),

              SizedBox(height: 32.h),

              // Save Button (only visible when editing)
              if (_isEditing) ...[
                PrimaryButton(
                  text: 'Save Changes',
                  onPressed: _saveChanges,
                ),
                SizedBox(height: 20.h),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
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
        children: [
          // Avatar Display
          GestureDetector(
            onTap: _isEditing ? _showAvatarPicker : null,
            child: Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                color: AppColors.greyLight,
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      _isEditing ? AppColors.textPrimary : AppColors.greyBorder,
                  width: _isEditing ? 2 : 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  _selectedAvatar,
                  style: TextStyle(fontSize: 32.sp),
                ),
              ),
            ),
          ),

          if (_isEditing) ...[
            SizedBox(height: 8.h),
            Text(
              'Tap to change avatar',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUserInfoSection() {
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
            'Personal Information',
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 20.h),

          // Name Field
          if (_isEditing) ...[
            CustomTextField(
              controller: _nameController,
              label: 'Full Name',
              hint: 'Enter your name',
            ),
            SizedBox(height: 16.h),
          ] else ...[
            _buildInfoRow('Name', _mockUserData['name']),
            SizedBox(height: 16.h),
          ],

          // Email Field (read-only for now)
          _buildInfoRow('Email', _mockUserData['email']),
          SizedBox(height: 16.h),

          // Join Date
          _buildInfoRow('Member Since', _mockUserData['joinDate']),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100.w,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
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

          // Stats Grid
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.play_circle_outline,
                  value: '${_mockUserData['sessionsListened']}',
                  label: 'Sessions\nListened',
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.access_time,
                  value: '${_mockUserData['totalMinutes']}m',
                  label: 'Total\nMinutes',
                ),
              ),
            ],
          ),

          SizedBox(height: 16.h),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.favorite_outline,
                  value: _mockUserData['favoriteCategory'],
                  label: 'Favorite\nCategory',
                  isString: true,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.trending_up,
                  value: '7',
                  label: 'Day\nStreak',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    bool isString = false,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.greyLight,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: AppColors.textPrimary,
            size: 24.sp,
          ),
          SizedBox(height: 8.h),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: isString ? 12.sp : 18.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showAvatarPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.greyBorder,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'Choose Avatar',
              style: GoogleFonts.inter(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 20.h),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 16.w,
                mainAxisSpacing: 16.h,
              ),
              itemCount: _availableAvatars.length,
              itemBuilder: (context, index) {
                final avatar = _availableAvatars[index];
                final isSelected = avatar == _selectedAvatar;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedAvatar = avatar;
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.greyMedium
                          : AppColors.greyLight,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.textPrimary
                            : AppColors.greyBorder,
                        width: isSelected ? 2 : 1,
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
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        // Cancel - reset data
        _loadUserData();
      }
    });
  }

  void _saveChanges() {
    // Firebase'e kaydetme işlemi burada olacak
    // Şimdilik mock data'yı güncelliyoruz
    _mockUserData['name'] = _nameController.text;
    _mockUserData['avatar'] = _selectedAvatar;

    setState(() {
      _isEditing = false;
    });

    // Success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Profile updated successfully!',
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: AppColors.textPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
      ),
    );

    print('Profile saved: ${_nameController.text}, Avatar: $_selectedAvatar');
  }
}
