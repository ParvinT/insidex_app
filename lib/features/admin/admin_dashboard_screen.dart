// lib/features/admin/admin_dashboard_screen.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = true;
  Map<String, dynamic> _statistics = {};

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
    _loadStatistics();
  }

  Future<void> _checkAdminAccess() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unauthorized Access'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Check in admins collection
      final adminDoc =
          await _firestore.collection('admins').doc(user.uid).get();

      if (!adminDoc.exists) {
        // Also check in users collection for isAdmin field
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();

        final isAdmin = userDoc.data()?['isAdmin'] ?? false;

        if (!isAdmin && mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unauthorized Access'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error checking admin access: $e');
      }
    }
  }

  Future<void> _loadStatistics() async {
    try {
      setState(() => _isLoading = true);

      // Get total users count
      final usersSnapshot = await _firestore.collection('users').get();
      final totalUsers = usersSnapshot.docs.length;

      // Get premium users count
      final premiumUsersSnapshot = await _firestore
          .collection('users')
          .where('isPremium', isEqualTo: true)
          .get();
      final premiumUsers = premiumUsersSnapshot.docs.length;

      // Get total sessions count
      final sessionsSnapshot = await _firestore.collection('sessions').get();
      final totalSessions = sessionsSnapshot.docs.length;

      // Get total categories count
      final categoriesSnapshot =
          await _firestore.collection('categories').get();
      final totalCategories = categoriesSnapshot.docs.length;

      setState(() {
        _statistics = {
          'totalUsers': totalUsers,
          'premiumUsers': premiumUsers,
          'totalSessions': totalSessions,
          'totalCategories': totalCategories,
        };
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading statistics: $e');
      }
      setState(() => _isLoading = false);
    }
  }

  void _showAdminMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.r),
            topRight: Radius.circular(20.r),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: EdgeInsets.only(top: 12.h),
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 20.h),

              // Menu Title
              Text(
                'Admin Menu',
                style: GoogleFonts.inter(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 20.h),

              // Menu Items
              _buildMenuItem(
                icon: Icons.dashboard,
                title: 'Dashboard',
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              _buildMenuItem(
                icon: Icons.category,
                title: 'Categories',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/admin/categories');
                },
              ),
              _buildMenuItem(
                icon: Icons.music_note,
                title: 'Sessions',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/admin/sessions');
                },
              ),
              _buildMenuItem(
                icon: Icons.add_circle,
                title: 'Add Session',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/admin/add-session');
                },
              ),
              _buildMenuItem(
                icon: Icons.people,
                title: 'Users',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/admin/users');
                },
              ),
              _buildMenuItem(
                icon: Icons.settings,
                title: 'Settings',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/admin/settings');
                },
              ),
              Divider(height: 1),
              _buildMenuItem(
                icon: Icons.logout,
                title: 'Exit Admin Panel',
                color: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: color ?? AppColors.textPrimary,
        size: 24.sp,
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
          color: color ?? AppColors.textPrimary,
        ),
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 768;

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      body: SafeArea(
        child: isWideScreen
            ? Row(
                children: [
                  // Desktop Sidebar
                  _buildDesktopSidebar(),
                  // Main Content
                  Expanded(
                    child: _buildMainContent(),
                  ),
                ],
              )
            : Column(
                children: [
                  // Mobile Header with Menu
                  _buildMobileHeader(),
                  // Main Content
                  Expanded(
                    child: _buildMainContent(),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildMobileHeader() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: AppColors.greyBorder,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Back Button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: AppColors.backgroundWhite,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: AppColors.greyBorder,
                ),
              ),
              child: Icon(
                Icons.arrow_back,
                color: AppColors.textPrimary,
                size: 20.sp,
              ),
            ),
          ),

          SizedBox(width: 12.w),

          // Admin Panel Title
          Expanded(
            child: Row(
              children: [
                Icon(
                  Icons.admin_panel_settings,
                  color: Colors.red,
                  size: 24.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  'Admin Panel',
                  style: GoogleFonts.inter(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          // Menu Button (HomeScreen tarzı)
          GestureDetector(
            onTap: _showAdminMenu,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: AppColors.primaryGold,
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGold.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Menu',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Icon(
                    Icons.menu,
                    size: 14.sp,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopSidebar() {
    return Container(
      width: 250.w,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(
            color: AppColors.greyBorder,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Logo/Header
          Container(
            padding: EdgeInsets.all(20.w),
            child: Row(
              children: [
                Icon(
                  Icons.admin_panel_settings,
                  color: Colors.red,
                  size: 32.sp,
                ),
                SizedBox(width: 12.w),
                Text(
                  'Admin Panel',
                  style: GoogleFonts.inter(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          Divider(
            color: AppColors.greyBorder,
            thickness: 1,
            height: 1,
          ),

          // Navigation Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(vertical: 20.h),
              children: [
                _buildSidebarItem(
                  icon: Icons.dashboard,
                  title: 'Dashboard',
                  isActive: true,
                  onTap: () {},
                ),
                _buildSidebarItem(
                  icon: Icons.category,
                  title: 'Categories',
                  onTap: () {
                    Navigator.pushNamed(context, '/admin/categories');
                  },
                ),
                _buildSidebarItem(
                  icon: Icons.music_note,
                  title: 'Sessions',
                  onTap: () {
                    Navigator.pushNamed(context, '/admin/sessions');
                  },
                ),
                _buildSidebarItem(
                  icon: Icons.add_circle,
                  title: 'Add Session',
                  onTap: () {
                    Navigator.pushNamed(context, '/admin/add-session');
                  },
                ),
                _buildSidebarItem(
                  icon: Icons.people,
                  title: 'Users',
                  onTap: () {
                    Navigator.pushNamed(context, '/admin/users');
                  },
                ),
                _buildSidebarItem(
                  icon: Icons.settings,
                  title: 'Settings',
                  onTap: () {
                    Navigator.pushNamed(context, '/admin/settings');
                  },
                ),
              ],
            ),
          ),

          // Bottom section
          Divider(
            color: AppColors.greyBorder,
            thickness: 1,
            height: 1,
          ),

          // Logout
          _buildSidebarItem(
            icon: Icons.logout,
            title: 'Exit Admin',
            isDestructive: true,
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String title,
    bool isActive = false,
    bool isDestructive = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryGold.withOpacity(0.1) : null,
          border: isActive
              ? Border(
                  left: BorderSide(
                    color: AppColors.primaryGold,
                    width: 3,
                  ),
                )
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive
                  ? Colors.red
                  : isActive
                      ? AppColors.primaryGold
                      : AppColors.textSecondary,
              size: 20.sp,
            ),
            SizedBox(width: 12.w),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isDestructive
                    ? Colors.red
                    : isActive
                        ? AppColors.primaryGold
                        : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryGold,
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header - Mobilde gösterme çünkü yukarıda var
          if (MediaQuery.of(context).size.width > 768) ...[
            Text(
              'Dashboard Overview',
              style: GoogleFonts.inter(
                fontSize: 28.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Welcome to your admin dashboard',
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 32.h),
          ] else ...[
            // Mobile için başlık
            Text(
              'Dashboard Overview',
              style: GoogleFonts.inter(
                fontSize: 24.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Welcome to your admin dashboard',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 24.h),
          ],

          // Statistics Grid
          _buildStatisticsGrid(),

          SizedBox(height: 24.h),

          // Recent Activity
          _buildRecentActivity(),
        ],
      ),
    );
  }

  Widget _buildStatisticsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 2 : 1;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16.w,
          mainAxisSpacing: 16.h,
          childAspectRatio: constraints.maxWidth > 600 ? 1.5 : 1.2,
          children: [
            _buildStatCard(
              title: 'Total Users',
              value: '${_statistics['totalUsers'] ?? 0}',
              icon: Icons.people,
              color: Colors.blue,
            ),
            _buildStatCard(
              title: 'Premium Users',
              value: '${_statistics['premiumUsers'] ?? 0}',
              icon: Icons.star,
              color: AppColors.primaryGold,
            ),
            _buildStatCard(
              title: 'Total Sessions',
              value: '${_statistics['totalSessions'] ?? 0}',
              icon: Icons.music_note,
              color: Colors.green,
            ),
            _buildStatCard(
              title: 'Categories',
              value: '${_statistics['totalCategories'] ?? 0}',
              icon: Icons.category,
              color: Colors.purple,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.greyBorder,
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20.sp,
                ),
              ),
              Icon(
                Icons.trending_up,
                color: Colors.green,
                size: 16.sp,
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.greyBorder,
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
            'Recent Activity',
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),

          SizedBox(height: 20.h),

          // Activity List
          ...List.generate(5, (index) {
            return _buildActivityItem(
              title: 'New user registered',
              subtitle: 'user${index + 1}@example.com',
              time: '${index + 1} hours ago',
            );
          }),
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required String title,
    required String subtitle,
    required String time,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.greyBorder.withOpacity(0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8.w,
            height: 8.w,
            decoration: BoxDecoration(
              color: AppColors.primaryGold,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
