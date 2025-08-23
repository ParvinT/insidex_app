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

        if (!isAdmin) {
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Admin access required'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking admin access: $e');
    }
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);

    try {
      // Load user statistics
      final usersSnapshot = await _firestore.collection('users').get();
      final premiumUsers = usersSnapshot.docs
          .where((doc) => doc.data()['isPremium'] == true)
          .length;

      // Load session statistics
      final sessionsSnapshot = await _firestore.collection('sessions').get();

      // Load category statistics
      final categoriesSnapshot =
          await _firestore.collection('categories').get();

      setState(() {
        _statistics = {
          'totalUsers': usersSnapshot.size,
          'premiumUsers': premiumUsers,
          'totalSessions': sessionsSnapshot.size,
          'totalCategories': categoriesSnapshot.size,
        };
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading statistics: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showAdminMenu() {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700; // iPhone SE gibi küçük ekranlar

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true, // İçeriğin yüksekliğine göre ayarlanabilir
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.75, // Maksimum ekranın %75'i
      ),
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.backgroundWhite,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.r),
            topRight: Radius.circular(20.r),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: 12.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.greyBorder,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),

            SizedBox(height: isSmallScreen ? 12.h : 20.h),

            // Menu Title
            Text(
              'Admin Menu',
              style: GoogleFonts.inter(
                fontSize: isSmallScreen ? 16.sp : 18.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),

            SizedBox(height: isSmallScreen ? 12.h : 20.h),

            // Scrollable Menu Items
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildCompactMenuItem(
                      icon: Icons.dashboard,
                      title: 'Dashboard',
                      onTap: () => Navigator.pop(context),
                      isCompact: isSmallScreen,
                    ),
                    _buildCompactMenuItem(
                      icon: Icons.category,
                      title: 'Categories',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/admin/categories');
                      },
                      isCompact: isSmallScreen,
                    ),
                    _buildCompactMenuItem(
                      icon: Icons.music_note,
                      title: 'Sessions',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/admin/sessions');
                      },
                      isCompact: isSmallScreen,
                    ),
                    _buildCompactMenuItem(
                      icon: Icons.add_circle,
                      title: 'Add Session',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/admin/add-session');
                      },
                      isCompact: isSmallScreen,
                    ),
                    _buildCompactMenuItem(
                      icon: Icons.people,
                      title: 'Users',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/admin/users');
                      },
                      isCompact: isSmallScreen,
                    ),
                    _buildCompactMenuItem(
                      icon: Icons.settings,
                      title: 'Settings',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/admin/settings');
                      },
                      isCompact: isSmallScreen,
                    ),

                    // Divider
                    Padding(
                      padding: EdgeInsets.symmetric(
                          vertical: isSmallScreen ? 8.h : 12.h),
                      child: Divider(
                        color: AppColors.greyBorder,
                        height: 1,
                      ),
                    ),

                    _buildCompactMenuItem(
                      icon: Icons.logout,
                      title: 'Exit Admin Panel',
                      color: Colors.red,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      isCompact: isSmallScreen,
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: MediaQuery.of(context).padding.bottom + 20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
    bool isCompact = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 16.w,
          vertical: isCompact ? 12.h : 14.h,
        ),
        margin: EdgeInsets.only(bottom: isCompact ? 4.h : 8.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          color: Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: color ?? AppColors.textPrimary,
              size: isCompact ? 20.sp : 22.sp,
            ),
            SizedBox(width: 16.w),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: isCompact ? 14.sp : 15.sp,
                fontWeight: FontWeight.w500,
                color: color ?? AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
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
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        border: Border(
          bottom: BorderSide(
            color: AppColors.greyBorder.withOpacity(0.5),
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
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                color: AppColors.backgroundWhite,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                  color: AppColors.greyBorder,
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.arrow_back,
                color: AppColors.textPrimary,
                size: 18.sp,
              ),
            ),
          ),

          SizedBox(width: 12.w),

          // Admin Panel Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin Panel',
                  style: GoogleFonts.inter(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Manage your app',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Menu Button - Siyah yapıldı
          GestureDetector(
            onTap: _showAdminMenu,
            child: Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                color: AppColors.textPrimary, // Siyah arka plan
                borderRadius: BorderRadius.circular(10.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.menu,
                size: 18.sp,
                color: Colors.white, // Beyaz ikon
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
        color: AppColors.backgroundWhite,
        border: Border(
          right: BorderSide(
            color: AppColors.greyBorder.withOpacity(0.5),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Admin Header
          Container(
            padding: EdgeInsets.all(24.w),
            child: Column(
              children: [
                Icon(
                  Icons.admin_panel_settings,
                  color: AppColors.primaryGold,
                  size: 48.sp,
                ),
                SizedBox(height: 12.h),
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

          Divider(color: AppColors.greyBorder.withOpacity(0.5)),

          // Menu Items
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              child: Column(
                children: [
                  _buildSidebarItem(
                    icon: Icons.dashboard,
                    title: 'Dashboard',
                    isActive: true,
                  ),
                  _buildSidebarItem(
                    icon: Icons.category,
                    title: 'Categories',
                    onTap: () =>
                        Navigator.pushNamed(context, '/admin/categories'),
                  ),
                  _buildSidebarItem(
                    icon: Icons.music_note,
                    title: 'Sessions',
                    onTap: () =>
                        Navigator.pushNamed(context, '/admin/sessions'),
                  ),
                  _buildSidebarItem(
                    icon: Icons.add_circle,
                    title: 'Add Session',
                    onTap: () =>
                        Navigator.pushNamed(context, '/admin/add-session'),
                  ),
                  _buildSidebarItem(
                    icon: Icons.people,
                    title: 'Users',
                    onTap: () => Navigator.pushNamed(context, '/admin/users'),
                  ),
                  _buildSidebarItem(
                    icon: Icons.settings,
                    title: 'Settings',
                    onTap: () =>
                        Navigator.pushNamed(context, '/admin/settings'),
                  ),
                ],
              ),
            ),
          ),

          Divider(color: AppColors.greyBorder.withOpacity(0.5)),

          // Exit Button
          _buildSidebarItem(
            icon: Icons.logout,
            title: 'Exit Admin',
            isDestructive: true,
            onTap: () => Navigator.pop(context),
          ),

          SizedBox(height: 16.h),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    bool isActive = false,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primaryGold.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
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
          // Header
          Text(
            'Dashboard Overview',
            style: GoogleFonts.inter(
              fontSize: 24.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Welcome to your admin dashboard',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 24.h),

          // Statistics Grid
          _buildStatisticsGrid(),

          SizedBox(height: 32.h),

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
          childAspectRatio: constraints.maxWidth > 600 ? 1.8 : 1.4,
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
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.greyBorder.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20.sp,
                ),
              ),
              Icon(
                Icons.trending_up,
                color: Colors.green.shade400,
                size: 16.sp,
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 28.sp,
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
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.greyBorder.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Activity',
                style: GoogleFonts.inter(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  'View All',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: AppColors.primaryGold,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // Activity Items
          ...List.generate(3, (index) {
            final activities = [
              {
                'icon': Icons.person_add,
                'title': 'New user registered',
                'subtitle': 'john.doe@example.com',
                'time': '2 minutes ago',
                'color': Colors.blue,
              },
              {
                'icon': Icons.music_note,
                'title': 'New session added',
                'subtitle': 'Deep Sleep Meditation',
                'time': '1 hour ago',
                'color': Colors.green,
              },
              {
                'icon': Icons.star,
                'title': 'User upgraded to premium',
                'subtitle': 'jane.smith@example.com',
                'time': '3 hours ago',
                'color': AppColors.primaryGold,
              },
            ];

            final activity = activities[index];
            return Container(
              margin: EdgeInsets.only(bottom: 12.h),
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.greyLight.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: (activity['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      activity['icon'] as IconData,
                      color: activity['color'] as Color,
                      size: 16.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity['title'] as String,
                          style: GoogleFonts.inter(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          activity['subtitle'] as String,
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    activity['time'] as String,
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
