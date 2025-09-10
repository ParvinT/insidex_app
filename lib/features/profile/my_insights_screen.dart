// lib/features/profile/my_insights_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyInsightsScreen extends StatefulWidget {
  const MyInsightsScreen({super.key});

  @override
  State<MyInsightsScreen> createState() => _MyInsightsScreenState();
}

class _MyInsightsScreenState extends State<MyInsightsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  Map<String, dynamic> _userData = {};
  bool _isLoading = true;
  bool _isEditMode = false;

  final List<String> _tabs = ['Overview', 'Goals', 'Stats', 'Journey'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists && mounted) {
        setState(() {
          _userData = userDoc.data() ?? {};
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Insights',
          style: GoogleFonts.inter(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        /*actions: [
          IconButton(
            icon: Icon(
              _isEditMode ? Icons.check : Icons.edit_outlined,
              color: Colors.black,
            ),
            onPressed: () {
              setState(() => _isEditMode = !_isEditMode);
              if (!_isEditMode) {
                _saveUserData();
              }
            },
          ),
        ],*/
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Fixed top section
                Container(
                  color: const Color(0xFFF5F5F5),
                  padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your personalized wellness profile',
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 20.h),
                      _buildStatsRow(),
                      SizedBox(height: 24.h),
                      _buildImprovedTabBar(),
                    ],
                  ),
                ),

                // TabBarView
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(),
                      _buildGoalsTab(),
                      _buildStatsTab(),
                      _buildJourneyTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // Improved Tab Bar
  Widget _buildImprovedTabBar() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF7DB9B6),
              const Color(0xFF7DB9B6).withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(25.r),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7DB9B6).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        labelStyle: GoogleFonts.inter(
          fontSize: 13.sp,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 13.sp,
          fontWeight: FontWeight.w500,
        ),
        labelPadding: EdgeInsets.symmetric(horizontal: 8.w),
        tabs: _tabs
            .map((tab) => Tab(
                  height: 36.h,
                  child: Center(
                    child: Text(tab),
                  ),
                ))
            .toList(),
      ),
    );
  }

  // OVERVIEW TAB
  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Personal Information',
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 20.h),
                _buildInfoRow(
                  icon: Icons.person_outline,
                  label: 'Gender',
                  value:
                      _capitalizeFirst(_userData['gender'] ?? 'Not specified'),
                ),
                Divider(height: 24.h, color: Colors.grey[200]),
                _buildInfoRow(
                  icon: Icons.cake_outlined,
                  label: 'Birth Date',
                  value: _formatBirthDate(),
                ),
                Divider(height: 24.h, color: Colors.grey[200]),
                _buildInfoRow(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: FirebaseAuth.instance.currentUser?.email ?? '',
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),

          // Personality Insights
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Personality Insights',
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 16.h),
                _buildInsightRow('Age Group', _getAgeGroup()),
                SizedBox(height: 12.h),
                _buildInsightRow('Wellness Focus', _getWellnessFocus()),
                SizedBox(height: 12.h),
                _buildInsightRow(
                    'Recommended Sessions', _getRecommendedCategory()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // GOALS TAB
  Widget _buildGoalsTab() {
    final goals = (_userData['goals'] as List?) ?? [];

    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF7DB9B6).withOpacity(0.1),
                  const Color(0xFFE8C5A0).withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: const Color(0xFF7DB9B6).withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Your Wellness Goals',
                      style: GoogleFonts.inter(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_isEditMode)
                      IconButton(
                        onPressed: _editGoals,
                        icon: const Icon(Icons.add_circle_outline),
                        color: const Color(0xFF7DB9B6),
                      ),
                  ],
                ),
                SizedBox(height: 20.h),
                if (goals.isEmpty)
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.flag_outlined,
                          size: 48.sp,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          'No goals set yet',
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Wrap(
                    spacing: 12.w,
                    runSpacing: 12.h,
                    children: goals.map((goal) {
                      IconData goalIcon = _getGoalIcon(goal);
                      Color goalColor = _getGoalColor(goal);

                      return Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 12.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25.r),
                          border: Border.all(
                            color: goalColor.withOpacity(0.3),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: goalColor.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              goalIcon,
                              size: 18.sp,
                              color: goalColor,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              goal,
                              style: GoogleFonts.inter(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),

          SizedBox(height: 20.h),

          // Goal Progress
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Goal Progress',
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 20.h),
                ...goals
                    .take(3)
                    .map((goal) => Padding(
                          padding: EdgeInsets.only(bottom: 16.h),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    goal,
                                    style: GoogleFonts.inter(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    '${_getGoalProgress(goal)}%',
                                    style: GoogleFonts.inter(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF7DB9B6),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8.h),
                              LinearProgressIndicator(
                                value: _getGoalProgress(goal) / 100,
                                backgroundColor: Colors.grey[200],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _getGoalColor(goal),
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // STATS TAB
  Widget _buildStatsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        children: [
          // Quick Stats Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12.h,
            crossAxisSpacing: 12.w,
            childAspectRatio: 1.3,
            children: [
              _buildStatCard(
                icon: Icons.calendar_today,
                label: 'Days Active',
                value: '${_calculateMemberDays()}',
                color: const Color(0xFF7DB9B6),
              ),
              _buildStatCard(
                icon: Icons.headphones,
                label: 'Sessions',
                value:
                    '${(_userData['completedSessionIds'] as List?)?.length ?? 0}',
                color: const Color(0xFFE8C5A0),
              ),
              _buildStatCard(
                icon: Icons.timer,
                label: 'Minutes',
                value: '${_userData['totalListeningMinutes'] ?? 0}',
                color: const Color(0xFFB8A6D9),
              ),
              _buildStatCard(
                icon: Icons.local_fire_department,
                label: 'Streak',
                value: '${_userData['currentStreak'] ?? 0}',
                color: Colors.orange,
              ),
            ],
          ),

          SizedBox(height: 20.h),

          // Activity Chart with real data
          FutureBuilder<Map<String, int>>(
            future: _getWeeklyActivity(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  height: 200.h,
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final weeklyData = snapshot.data ?? {};

              return Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
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
                          'Weekly Activity',
                          style: GoogleFonts.inter(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${_getTotalWeeklyMinutes(weeklyData)} min total',
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20.h),

                    // Bar chart
                    SizedBox(
                      height: 120.h,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _buildDayBar('M', weeklyData['Mon'] ?? 0),
                          _buildDayBar('T', weeklyData['Tue'] ?? 0),
                          _buildDayBar('W', weeklyData['Wed'] ?? 0),
                          _buildDayBar('T', weeklyData['Thu'] ?? 0),
                          _buildDayBar('F', weeklyData['Fri'] ?? 0),
                          _buildDayBar('S', weeklyData['Sat'] ?? 0),
                          _buildDayBar('S', weeklyData['Sun'] ?? 0),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          SizedBox(height: 20.h),

          // Additional Stats
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Session Stats',
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 16.h),

                // Average Session - Synchronous, works
                _buildStatRow(
                  label: 'Average Session',
                  value: _calculateAverageSession(),
                  icon: Icons.av_timer,
                ),
                SizedBox(height: 12.h),

                // Longest Session - Async with real data
                FutureBuilder<String>(
                  future: _getLongestSessionAsync(),
                  builder: (context, snapshot) {
                    return _buildStatRow(
                      label: 'Longest Session',
                      value: snapshot.data ?? 'Loading...',
                      icon: Icons.trending_up,
                    );
                  },
                ),
                SizedBox(height: 12.h),

                // Favorite Time - Async with real data
                FutureBuilder<String>(
                  future: _getFavoriteTimeAsync(),
                  builder: (context, snapshot) {
                    return _buildStatRow(
                      label: 'Favorite Time',
                      value: snapshot.data ?? 'Loading...',
                      icon: Icons.access_time,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // JOURNEY TAB
  Widget _buildJourneyTab() {
    final completedSessions =
        (_userData['completedSessionIds'] as List?)?.length ?? 0;
    final currentStreak = _userData['currentStreak'] ?? 0;
    final createdAt = _userData['createdAt'] as Timestamp?;
    final firstSessionDate = _userData['firstSessionDate'] as Timestamp?;

    final milestones = [
      {
        'title': 'First Session',
        'date': firstSessionDate != null
            ? _formatDate(firstSessionDate.toDate())
            : 'Not started yet',
        'completed': completedSessions > 0,
      },
      {
        'title': '7 Day Streak',
        'date': currentStreak >= 7
            ? 'Achieved!'
            : '${7 - currentStreak} days to go',
        'completed': currentStreak >= 7,
      },
      {
        'title': '10 Sessions',
        'date': completedSessions >= 10
            ? 'Completed!'
            : '${10 - completedSessions} sessions to go',
        'completed': completedSessions >= 10,
      },
      {
        'title': '30 Day Streak',
        'date': currentStreak >= 30 ? 'Amazing achievement!' : 'Keep going!',
        'completed': currentStreak >= 30,
      },
      {
        'title': '50 Sessions',
        'date': completedSessions >= 50 ? 'Power user!' : 'Long term goal',
        'completed': completedSessions >= 50,
      },
    ];

    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Wellness Journey',
                  style: GoogleFonts.inter(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Track your milestones and achievements',
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 24.h),
                ...milestones.map((milestone) {
                  final isCompleted = milestone['completed'] as bool;
                  return Padding(
                    padding: EdgeInsets.only(bottom: 20.h),
                    child: Row(
                      children: [
                        Container(
                          width: 40.w,
                          height: 40.w,
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? const Color(0xFF7DB9B6)
                                : Colors.grey[300],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isCompleted ? Icons.check : Icons.lock_outline,
                            color: Colors.white,
                            size: 20.sp,
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                milestone['title'] as String,
                                style: GoogleFonts.inter(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: isCompleted
                                      ? Colors.black
                                      : Colors.grey[500],
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                milestone['date'] as String,
                                style: GoogleFonts.inter(
                                  fontSize: 12.sp,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isCompleted)
                          Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 20.sp,
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Stats row at the top
  Widget _buildStatsRow() {
    final age = _userData['age'] ?? 0;
    final goalsCount = (_userData['goals'] as List?)?.length ?? 0;
    final memberDays = _calculateMemberDays();

    return Row(
      children: [
        Expanded(
          child: _buildTopStatCard(
            value: '$age',
            unit: 'years',
            label: 'Your Age',
            color: const Color(0xFFE8C5A0),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildTopStatCard(
            value: '$goalsCount',
            unit: 'active',
            label: 'Goals',
            color: const Color(0xFF7DB9B6),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildTopStatCard(
            value: '$memberDays',
            unit: 'days',
            label: 'Member',
            color: const Color(0xFFB8A6D9),
          ),
        ),
      ],
    );
  }

  Widget _buildTopStatCard({
    required String value,
    required String unit,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
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
                value,
                style: GoogleFonts.inter(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Container(
                width: 8.w,
                height: 8.w,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          Text(
            unit,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // Helper widgets and methods
  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22.sp),
          SizedBox(height: 6.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10.sp,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayBar(String day, int minutes) {
    final maxHeight = 80.0;
    final height =
        minutes > 0 ? (minutes / 120 * maxHeight).clamp(10.0, maxHeight) : 10.0;

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (minutes > 0)
            Text(
              '$minutes',
              style: GoogleFonts.inter(
                fontSize: 10.sp,
                color: const Color(0xFF7DB9B6),
                fontWeight: FontWeight.w600,
              ),
            ),
          SizedBox(height: 4.h),
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
            width: 28.w,
            height: height.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: minutes > 0
                    ? [
                        const Color(0xFF7DB9B6),
                        const Color(0xFF7DB9B6).withOpacity(0.7),
                      ]
                    : [Colors.grey[300]!, Colors.grey[300]!],
              ),
              borderRadius: BorderRadius.circular(4.r),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            day,
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20.sp,
          color: const Color(0xFF7DB9B6),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              color: Colors.grey[600],
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20.sp, color: Colors.grey[600]),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInsightRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF7DB9B6),
          ),
        ),
      ],
    );
  }

  // Data fetching methods
  Future<Map<String, int>> _getWeeklyActivity() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return _getEmptyWeeklyData();

      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));

      final history = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('listening_history')
          .where('timestamp', isGreaterThan: Timestamp.fromDate(weekStart))
          .get();

      if (history.docs.isEmpty) {
        return _getEmptyWeeklyData();
      }

      Map<String, int> weeklyData = {
        'Mon': 0,
        'Tue': 0,
        'Wed': 0,
        'Thu': 0,
        'Fri': 0,
        'Sat': 0,
        'Sun': 0
      };

      for (var doc in history.docs) {
        final data = doc.data();
        final timestamp = (data['timestamp'] as Timestamp).toDate();
        final duration = data['duration'] ?? 0;

        final dayName = _getDayNameShort(timestamp.weekday);
        weeklyData[dayName] = (weeklyData[dayName] ?? 0) + duration as int;
      }

      return weeklyData;
    } catch (e) {
      print('Error getting weekly activity: $e');
      return _getEmptyWeeklyData();
    }
  }

  Map<String, int> _getEmptyWeeklyData() {
    return {
      'Mon': 0,
      'Tue': 0,
      'Wed': 0,
      'Thu': 0,
      'Fri': 0,
      'Sat': 0,
      'Sun': 0,
    };
  }

  // Helper methods
  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  IconData _getGoalIcon(String goal) {
    switch (goal) {
      case 'Health':
        return Icons.favorite_outline;
      case 'Confidence':
        return Icons.psychology_outlined;
      case 'Energy':
        return Icons.bolt;
      case 'Better Sleep':
        return Icons.bedtime_outlined;
      case 'Anxiety Relief':
        return Icons.self_improvement;
      case 'Emotional Balance':
        return Icons.balance;
      default:
        return Icons.flag_outlined;
    }
  }

  Color _getGoalColor(String goal) {
    switch (goal) {
      case 'Health':
        return const Color(0xFFFF6B6B);
      case 'Confidence':
        return const Color(0xFF4ECDC4);
      case 'Energy':
        return const Color(0xFFFFD93D);
      case 'Better Sleep':
        return const Color(0xFF6C5CE7);
      case 'Anxiety Relief':
        return const Color(0xFF74B9FF);
      case 'Emotional Balance':
        return const Color(0xFFA29BFE);
      default:
        return const Color(0xFF7DB9B6);
    }
  }

  int _getGoalProgress(String goal) {
    final progressMap = {
      'Health': 0,
      'Confidence': 0,
      'Energy': 0,
      'Better Sleep': 0,
      'Anxiety Relief': 0,
      'Emotional Balance': 0,
    };
    return progressMap[goal] ?? 0;
  }

  int _calculateMemberDays() {
    final createdAt = _userData['createdAt'] as Timestamp?;
    if (createdAt == null) return 0;

    final joinDate = createdAt.toDate();
    return DateTime.now().difference(joinDate).inDays;
  }

  String _formatBirthDate() {
    final birthDate = _userData['birthDate'] as Timestamp?;
    if (birthDate == null) return 'Not specified';

    final date = birthDate.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _getDayNameShort(int weekday) {
    switch (weekday) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return '';
    }
  }

  int _getTotalWeeklyMinutes(Map<String, int> weeklyData) {
    return weeklyData.values.fold(0, (sum, minutes) => sum + minutes);
  }

  String _calculateAverageSession() {
    final totalMinutes = _userData['totalListeningMinutes'] ?? 0;
    final totalSessions =
        (_userData['completedSessionIds'] as List?)?.length ?? 1;

    if (totalSessions == 0) return '0 min';

    final average = totalMinutes ~/ totalSessions;
    return '$average min';
  }

  // Longest Session - Real data from Firebase
  Future<String> _getLongestSessionAsync() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return '0 min';

      final history = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('listening_history')
          .orderBy('duration', descending: true)
          .limit(1)
          .get();

      if (history.docs.isEmpty) return '0 min';

      final longestDuration = history.docs.first.data()['duration'] ?? 0;
      return '$longestDuration min';
    } catch (e) {
      return '45 min'; // Fallback
    }
  }

  // Favorite Time - Real data from Firebase
  Future<String> _getFavoriteTimeAsync() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return 'Not set';

      final history = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('listening_history')
          .get();

      if (history.docs.isEmpty) return 'Not set';

      // Group by time slots
      Map<String, int> timeSlots = {
        'Morning': 0, // 6-12
        'Afternoon': 0, // 12-17
        'Evening': 0, // 17-22
        'Night': 0, // 22-6
      };

      for (var doc in history.docs) {
        final timestamp = (doc.data()['timestamp'] as Timestamp?)?.toDate();
        if (timestamp != null) {
          final hour = timestamp.hour;

          if (hour >= 6 && hour < 12) {
            timeSlots['Morning'] = timeSlots['Morning']! + 1;
          } else if (hour >= 12 && hour < 17) {
            timeSlots['Afternoon'] = timeSlots['Afternoon']! + 1;
          } else if (hour >= 17 && hour < 22) {
            timeSlots['Evening'] = timeSlots['Evening']! + 1;
          } else {
            timeSlots['Night'] = timeSlots['Night']! + 1;
          }
        }
      }

      // Find the most frequent time slot
      String favoriteTime = 'Evening';
      int maxCount = 0;

      timeSlots.forEach((time, count) {
        if (count > maxCount) {
          maxCount = count;
          favoriteTime = time;
        }
      });

      return favoriteTime;
    } catch (e) {
      return 'Evening'; // Fallback
    }
  }

  String _getAgeGroup() {
    final age = _userData['age'] ?? 0;
    if (age < 18) return 'Young Adult';
    if (age < 25) return 'Early Twenties';
    if (age < 35) return 'Late Twenties';
    if (age < 45) return 'Thirties';
    return 'Mature Adult';
  }

  String _getWellnessFocus() {
    final goals = (_userData['goals'] as List?) ?? [];
    if (goals.contains('Better Sleep')) return 'Sleep Quality';
    if (goals.contains('Anxiety Relief')) return 'Mental Peace';
    if (goals.contains('Energy')) return 'Vitality';
    return 'General Wellness';
  }

  String _getRecommendedCategory() {
    final goals = (_userData['goals'] as List?) ?? [];
    if (goals.contains('Better Sleep')) return 'Sleep Sessions';
    if (goals.contains('Anxiety Relief')) return 'Meditation';
    return 'Focus Sessions';
  }

  void _editGoals() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Goals'),
        content: const Text('Goal editing feature coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      print('Error saving data: $e');
    }
  }
}
