// lib/features/admin/admin_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import 'disease_management_screen.dart';
import 'disease_cause_management_screen.dart';
import '../../l10n/app_localizations.dart';

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
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _checkAuthenticationAndAccess();
    _loadStatistics();
  }

  Future<void> _checkAuthenticationAndAccess() async {
    try {
      // Check if user is authenticated
      _currentUser = _auth.currentUser;

      if (_currentUser == null) {
        // No authenticated user, redirect to login
        debugPrint('ERROR: No authenticated user found!');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(AppLocalizations.of(context).pleaseLoginToAccessAdmin),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
          // Navigate to login screen
          Navigator.pushReplacementNamed(context, '/auth/login');
        }
        return;
      }

      debugPrint('Current user authenticated: ${_currentUser!.email}');
      debugPrint('User UID: ${_currentUser!.uid}');

      // Check admin privileges
      final adminDoc =
          await _firestore.collection('admins').doc(_currentUser!.uid).get();

      if (!adminDoc.exists) {
        // Check in users collection for isAdmin field
        final userDoc =
            await _firestore.collection('users').doc(_currentUser!.uid).get();
        final isAdmin = userDoc.data()?['isAdmin'] ?? false;

        if (!isAdmin) {
          debugPrint(
              'User ${_currentUser!.email} does not have admin privileges');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context).adminAccessRequired),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
              ),
            );
            Navigator.pop(context);
          }
        } else {
          debugPrint('User ${_currentUser!.email} has admin privileges');
        }
      } else {
        debugPrint('User ${_currentUser!.email} is in admins collection');
      }
    } catch (e) {
      debugPrint('Error checking authentication/access: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${AppLocalizations.of(context).errorOccurred}: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
    final isSmallScreen = screenHeight < 700;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.75,
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
              color: Colors.black.withValues(alpha: 0.1),
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
              AppLocalizations.of(context).adminMenu,
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
                      title: AppLocalizations.of(context).dashboard,
                      onTap: () => Navigator.pop(context),
                      isCompact: isSmallScreen,
                    ),
                    _buildCompactMenuItem(
                      icon: Icons.category,
                      title: AppLocalizations.of(context).categories,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/admin/categories');
                      },
                      isCompact: isSmallScreen,
                    ),

                    _buildCompactMenuItem(
                      icon: Icons.psychology,
                      title: AppLocalizations.of(context).manageDiseases,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DiseaseManagementScreen(),
                          ),
                        );
                      },
                      isCompact: isSmallScreen,
                    ),
                    _buildCompactMenuItem(
                      icon: Icons.map,
                      title: AppLocalizations.of(context).manageDiseaseCauses,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const DiseaseCauseManagementScreen(),
                          ),
                        );
                      },
                      isCompact: isSmallScreen,
                    ),

                    _buildCompactMenuItem(
                      icon: Icons.home_outlined,
                      title: AppLocalizations.of(context).homeCards,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/admin/home-cards');
                      },
                      isCompact: isSmallScreen,
                    ),
                    _buildCompactMenuItem(
                      icon: Icons.music_note,
                      title: AppLocalizations.of(context).sessions,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/admin/sessions');
                      },
                      isCompact: isSmallScreen,
                    ),
                    _buildCompactMenuItem(
                      icon: Icons.add_circle,
                      title: AppLocalizations.of(context).addSession,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/admin/add-session');
                      },
                      isCompact: isSmallScreen,
                    ),
                    _buildCompactMenuItem(
                      icon: Icons.people,
                      title: AppLocalizations.of(context).users,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/admin/users');
                      },
                      isCompact: isSmallScreen,
                    ),
                    _buildCompactMenuItem(
                      icon: Icons.card_giftcard,
                      title: 'Grant Subscription',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(
                            context, '/admin/grant-subscription');
                      },
                      isCompact: isSmallScreen,
                    ),
                    _buildCompactMenuItem(
                      icon: Icons.settings,
                      title: AppLocalizations.of(context).settings,
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
                        color: AppColors.greyBorder.withValues(alpha: 0.5),
                      ),
                    ),

                    // Sign Out
                    _buildCompactMenuItem(
                      icon: Icons.logout,
                      title: AppLocalizations.of(context).signOut,
                      onTap: () async {
                        final navigator = Navigator.of(context);
                        navigator.pop();
                        await _auth.signOut();
                        if (mounted) {
                          navigator.pushReplacementNamed('/auth/login');
                        }
                      },
                      color: Colors.red,
                      isCompact: isSmallScreen,
                    ),

                    // Current User Info
                    if (_currentUser != null)
                      Container(
                        margin: EdgeInsets.only(top: 16.h, bottom: 8.h),
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: AppColors.greyLight.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.account_circle,
                              size: 16.sp,
                              color: AppColors.textSecondary,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              _currentUser!.email ?? 'Admin',
                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                    SizedBox(height: isSmallScreen ? 12.h : 20.h),
                  ],
                ),
              ),
            ),
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
    required bool isCompact,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 16.w,
          vertical: isCompact ? 10.h : 12.h,
        ),
        margin: EdgeInsets.symmetric(vertical: isCompact ? 2.h : 4.h),
        decoration: BoxDecoration(
          color: color != null
              ? color.withValues(alpha: 0.05)
              : AppColors.backgroundWhite,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: color?.withValues(alpha: 0.2) ??
                AppColors.greyBorder.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: color ?? AppColors.textPrimary,
              size: isCompact ? 18.sp : 20.sp,
            ),
            SizedBox(width: 12.w),
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

  Widget _buildMainContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.textPrimary,
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
            AppLocalizations.of(context).dashboardOverview,
            style: GoogleFonts.inter(
              fontSize: 24.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            AppLocalizations.of(context).welcomeToAdminDashboard,
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
              title: AppLocalizations.of(context).totalUsers,
              value: '${_statistics['totalUsers'] ?? 0}',
              icon: Icons.people,
              color: Colors.blue,
            ),
            _buildStatCard(
              title: AppLocalizations.of(context).premiumUsers,
              value: '${_statistics['premiumUsers'] ?? 0}',
              icon: Icons.star,
              color: AppColors.textPrimary,
            ),
            _buildStatCard(
              title: AppLocalizations.of(context).totalSessions,
              value: '${_statistics['totalSessions'] ?? 0}',
              icon: Icons.music_note,
              color: Colors.green,
            ),
            _buildStatCard(
              title: AppLocalizations.of(context).totalCategories,
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
          color: AppColors.greyBorder.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
                  color: color.withValues(alpha: 0.1),
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
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.greyBorder.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).recentActivity,
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16.h),

          // Activity list placeholder
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            separatorBuilder: (context, index) => SizedBox(height: 12.h),
            itemBuilder: (context, index) {
              return Row(
                children: [
                  Container(
                    width: 8.w,
                    height: 8.w,
                    decoration: const BoxDecoration(
                      color: AppColors.textPrimary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'New session added to Sleep category',
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '2h ago',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
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
            color: AppColors.greyBorder.withValues(alpha: 0.5),
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
                  AppLocalizations.of(context).adminPanel,
                  style: GoogleFonts.inter(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  AppLocalizations.of(context).manageYourApp,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Menu Button
          GestureDetector(
            onTap: _showAdminMenu,
            child: Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                color: AppColors.textPrimary,
                borderRadius: BorderRadius.circular(10.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.menu,
                size: 18.sp,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      body: SafeArea(
        child: Column(
          children: [
            // Header with Menu (unified)
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
}
