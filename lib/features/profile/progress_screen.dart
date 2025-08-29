// lib/features/profile/progress_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math;
import 'dart:async';
import '../../core/constants/app_colors.dart';
import '../../providers/user_provider.dart';
import '../../services/listening_tracker_service.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'Month';

  // Real data from Firebase
  Map<String, dynamic> _analyticsData = {};
  bool _isLoading = true;
  bool _mounted = true;
  Timer? _refreshTimer;

  // Time periods
  final List<String> _periods = ['Analytics', 'Year', 'Month', 'Week', 'Day'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this, initialIndex: 2);
    _loadAnalyticsData();

    // Auto refresh every 5 seconds
    _refreshTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (mounted) {
        _loadAnalyticsData();
      }
    });
  }

  @override
  void dispose() {
    _mounted = false;
    _refreshTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalyticsData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Get user data from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        if (_mounted && mounted) {
          setState(() {
            _analyticsData = _getDefaultAnalytics();
            _isLoading = false;
          });
        }
        return;
      }

      // Get real listening history
      final history =
          await ListeningTrackerService.getListeningHistory(days: 30);

      // Get real weekly stats
      final weeklyStats = await ListeningTrackerService.getWeeklyStats();

      // Calculate real streak
      final streak = await ListeningTrackerService.calculateStreak();

      // Calculate monthly progress (real data)
      final monthlyProgress = _calculateRealMonthlyProgress(history);

      // Get top sessions (real data)
      final topSessions = _calculateTopSessions(history);

      // Calculate total weekly minutes
      final weeklyTotal =
          weeklyStats.values.fold(0, (sum, minutes) => sum + minutes);

      if (_mounted && mounted) {
        setState(() {
          _analyticsData = {
            'totalMinutes': userDoc.data()?['totalListeningMinutes'] ?? 0,
            'totalSessions':
                (userDoc.data()?['completedSessionIds'] as List?)?.length ?? 0,
            'currentStreak': streak,
            'weeklyData': weeklyStats,
            'weeklyTotal': weeklyTotal,
            'monthlyProgress': monthlyProgress,
            'topSessions': topSessions,
            'todayMinutes': _getTodayMinutes(history),
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading analytics: $e');
      if (_mounted && mounted) {
        setState(() {
          _analyticsData = _getDefaultAnalytics();
          _isLoading = false;
        });
      }
    }
  }

  Map<String, dynamic> _getDefaultAnalytics() {
    return {
      'totalMinutes': 0,
      'totalSessions': 0,
      'currentStreak': 0,
      'weeklyData': <String, int>{},
      'weeklyTotal': 0,
      'monthlyProgress': <String, double>{
        'Day': 0.0,
        'Week': 0.0,
        'Month': 0.0,
        'Year': 0.0,
      },
      'topSessions': <Map<String, dynamic>>[],
      'todayMinutes': 0,
    };
  }

  int _getTodayMinutes(List<Map<String, dynamic>> history) {
    final today = DateTime.now().toIso8601String().split('T')[0];
    int totalMinutes = 0;

    for (var session in history) {
      if (session['date'] == today) {
        final status = session['status'] as String?;
        if (status == 'completed') {
          totalMinutes += (session['duration'] as int? ?? 0);
        } else if (status == 'playing' || status == 'paused') {
          // Include accumulated duration for ongoing sessions
          totalMinutes += (session['accumulatedDuration'] as int? ?? 0);
        }
      }
    }

    return totalMinutes;
  }

  Map<String, double> _calculateRealMonthlyProgress(
      List<Map<String, dynamic>> history) {
    final now = DateTime.now();

    // Calculate goals
    const dailyGoal = 30;
    const weeklyGoal = 150;
    const monthlyGoal = 600;
    const yearlyGoal = 7200;

    // Calculate actual listening
    int dayMinutes = 0;
    int weekMinutes = 0;
    int monthMinutes = 0;
    int yearMinutes = 0;

    for (var session in history) {
      final timestamp = session['timestamp'] as Timestamp?;
      if (timestamp == null) continue;

      final sessionDate = timestamp.toDate();
      final status = session['status'] as String?;

      int duration = 0;
      if (status == 'completed') {
        duration = session['duration'] as int? ?? 0;
      } else if (status == 'playing' || status == 'paused') {
        duration = session['accumulatedDuration'] as int? ?? 0;
      }

      // Today
      if (sessionDate.day == now.day &&
          sessionDate.month == now.month &&
          sessionDate.year == now.year) {
        dayMinutes += duration;
      }

      if (duration == 0) continue;

      // This week
      if (sessionDate.isAfter(now.subtract(const Duration(days: 7)))) {
        weekMinutes += duration;
      }

      // This month
      if (sessionDate.month == now.month && sessionDate.year == now.year) {
        monthMinutes += duration;
      }

      // This year
      if (sessionDate.year == now.year) {
        yearMinutes += duration;
      }
    }

    return {
      'Day': (dayMinutes / dailyGoal).clamp(0.0, 1.0),
      'Week': (weekMinutes / weeklyGoal).clamp(0.0, 1.0),
      'Month': (monthMinutes / monthlyGoal).clamp(0.0, 1.0),
      'Year': (yearMinutes / yearlyGoal).clamp(0.0, 1.0),
    };
  }

  List<Map<String, dynamic>> _calculateTopSessions(
      List<Map<String, dynamic>> history) {
    final sessionStats = <String, Map<String, dynamic>>{};

    for (var session in history) {
      final status = session['status'] as String?;
      final sessionId = session['sessionId'] as String? ?? '';
      if (sessionId.isEmpty) continue;

      int duration = 0;
      if (status == 'completed') {
        duration = session['duration'] as int? ?? 0;
      } else if (status == 'playing' || status == 'paused') {
        duration = session['accumulatedDuration'] as int? ?? 0;
      }

      final title = session['sessionTitle'] as String? ?? 'Unknown Session';

      if (sessionStats.containsKey(sessionId)) {
        sessionStats[sessionId]!['totalMinutes'] =
            (sessionStats[sessionId]!['totalMinutes'] as int) + duration;
        sessionStats[sessionId]!['count'] =
            (sessionStats[sessionId]!['count'] as int) + 1;
      } else {
        sessionStats[sessionId] = {
          'sessionId': sessionId,
          'title': title,
          'totalMinutes': duration,
          'count': 1,
        };
      }
    }

    // Sort by total minutes and get top 3
    final sorted = sessionStats.values.toList()
      ..sort((a, b) =>
          (b['totalMinutes'] as int).compareTo(a['totalMinutes'] as int));

    return sorted.take(3).toList();
  }

  String _getDayName(int weekday) {
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
          'Your Progress',
          style: GoogleFonts.inter(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadAnalyticsData();
        },
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Subtitle
                    Text(
                      'Track your listening habits and improvements',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 20.h),

                    // Stats Cards
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            value: '${_analyticsData['totalMinutes'] ?? 0}',
                            unit: 'min',
                            label: 'Total Listening',
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: _buildStatCard(
                            value: '${_analyticsData['totalSessions'] ?? 0}',
                            unit: 'subliminals',
                            label: 'Total Sessions',
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: _buildStatCard(
                            value: '${_analyticsData['currentStreak'] ?? 0}',
                            unit: 'days streak',
                            label: 'Current Streak',
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24.h),

                    // Period Tabs
                    Container(
                      height: 40.h,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEEEEE),
                        borderRadius: BorderRadius.circular(24.r),
                      ),
                      padding: EdgeInsets.all(3.w),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(20.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.black87,
                        labelStyle: GoogleFonts.inter(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                        ),
                        unselectedLabelStyle: GoogleFonts.inter(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w500,
                        ),
                        labelPadding: EdgeInsets.zero,
                        tabs: _periods
                            .map((period) => Tab(text: period))
                            .toList(),
                        onTap: (index) {
                          setState(() {
                            _selectedPeriod = _periods[index];
                          });
                        },
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // Circular Progress with Top Sessions
                    Row(
                      children: [
                        // Circular Progress
                        SizedBox(
                          width: 140.w,
                          height: 140.w,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CustomPaint(
                                size: Size(140.w, 140.w),
                                painter: CircularProgressPainter(
                                  progress:
                                      (_analyticsData['todayMinutes'] ?? 0) /
                                          30.0,
                                  backgroundColor: Colors.grey[300]!,
                                  progressColor: const Color(0xFF7DB9B6),
                                  strokeWidth: 20.w,
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${_analyticsData['todayMinutes'] ?? 0}',
                                    style: GoogleFonts.inter(
                                      fontSize: 32.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  Text(
                                    'minutes today',
                                    style: GoogleFonts.inter(
                                      fontSize: 12.sp,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 20.w),

                        // Top Sessions
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Top Sessions',
                                style: GoogleFonts.inter(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              ...(_buildTopSessionBars()),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24.h),

                    // Progress Bars
                    Column(
                      children: [
                        _buildProgressBar(
                            'Day',
                            (_analyticsData['monthlyProgress']
                                    as Map<String, double>?)?['Day'] ??
                                0.0,
                            const Color(0xFFE8C5A0)),
                        SizedBox(height: 12.h),
                        _buildProgressBar(
                            'Week',
                            (_analyticsData['monthlyProgress']
                                    as Map<String, double>?)?['Week'] ??
                                0.0,
                            const Color(0xFF7DB9B6)),
                        SizedBox(height: 12.h),
                        _buildProgressBar(
                            'Month',
                            (_analyticsData['monthlyProgress']
                                    as Map<String, double>?)?['Month'] ??
                                0.0,
                            const Color(0xFF7DB9B6)),
                        SizedBox(height: 12.h),
                        _buildProgressBar(
                            'Year',
                            (_analyticsData['monthlyProgress']
                                    as Map<String, double>?)?['Year'] ??
                                0.0,
                            const Color(0xFF9B8B7E)),
                      ],
                    ),
                    SizedBox(height: 24.h),

                    // Weekly Chart
                    Container(
                      height: 180.h,
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'This Week',
                                style: GoogleFonts.inter(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${_analyticsData['weeklyTotal'] ?? 0} min total',
                                style: GoogleFonts.inter(
                                  fontSize: 12.sp,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16.h),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: _buildWeeklyBars(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStatCard({
    required String value,
    required String unit,
    required String label,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  height: 1,
                ),
              ),
              SizedBox(width: 2.w),
              Text(
                unit,
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  color: Colors.black54,
                  height: 1,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: Colors.grey[600],
              height: 1.2,
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTopSessionBars() {
    final topSessions =
        _analyticsData['topSessions'] as List<Map<String, dynamic>>? ?? [];

    if (topSessions.isEmpty) {
      return [
        Text(
          'No sessions yet',
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            color: Colors.grey[500],
            fontStyle: FontStyle.italic,
          ),
        ),
      ];
    }

    final bars = <Widget>[];
    final colors = [
      const Color(0xFF7DB9B6),
      const Color(0xFFB5A495),
      const Color(0xFF9B8B7E),
    ];

    final maxMinutes =
        topSessions.isNotEmpty ? topSessions.first['totalMinutes'] as int : 1;

    for (int i = 0; i < topSessions.length && i < 3; i++) {
      final session = topSessions[i];
      final minutes = session['totalMinutes'] as int;
      final title = session['title'] as String;
      final width = maxMinutes > 0 ? (minutes / maxMinutes) : 0.0;

      bars.add(
        Container(
          margin: EdgeInsets.only(bottom: 6.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.length > 20 ? '${title.substring(0, 20)}...' : title,
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 2.h),
              Container(
                height: 28.h,
                decoration: BoxDecoration(
                  color: colors[i].withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Stack(
                  children: [
                    FractionallySizedBox(
                      widthFactor: width,
                      child: Container(
                        decoration: BoxDecoration(
                          color: colors[i],
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.w),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '$minutes min',
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return bars;
  }

  Widget _buildProgressBar(String label, double progress, Color color) {
    return Row(
      children: [
        Icon(Icons.circle, size: 8.sp, color: color),
        SizedBox(width: 8.w),
        SizedBox(
          width: 40.w,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: Colors.black87,
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 6.h,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(3.r),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 6.h,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3.r),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 8.w),
        Text(
          '${(progress * 100).toInt()}%',
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildWeeklyBars() {
    final weeklyData = _analyticsData['weeklyData'] as Map<String, int>? ?? {};
    final now = DateTime.now();
    final bars = <Widget>[];

    int maxMinutes = 60;
    if (weeklyData.values.isNotEmpty) {
      final maxValue = weeklyData.values.reduce((a, b) => a > b ? a : b);
      if (maxValue > 0) {
        maxMinutes = maxValue;
      }
    }

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayName = _getDayName(date.weekday);
      final minutes = weeklyData[dayName] ?? 0;

      // Use today's minutes for current day
      int displayMinutes = minutes;
      if (i == 0) {
        displayMinutes = _analyticsData['todayMinutes'] ?? minutes;
      }

      final height = maxMinutes > 0 ? (displayMinutes / maxMinutes) : 0.0;

      Color barColor;
      if (displayMinutes == 0) {
        barColor = Colors.grey[300]!;
      } else if (i == 0) {
        barColor = const Color(0xFFB8A6D9);
      } else {
        barColor = const Color(0xFF7DB9B6);
      }

      bars.add(_buildDayBar(dayName.substring(0, 3), height, barColor));
    }

    return bars;
  }

  Widget _buildDayBar(String day, double height, Color color) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 2.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              width: double.infinity,
              height: 100.h * height.clamp(0.0, 1.0),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.vertical(top: Radius.circular(4.r)),
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              day,
              style: GoogleFonts.inter(
                fontSize: 9.sp,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Circular Progress Painter
class CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;
  final double strokeWidth;

  CircularProgressPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background arc
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final progressAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      progressAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
