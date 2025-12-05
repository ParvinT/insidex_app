// lib/features/profile/progress_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math;
import 'dart:async';
import '../../services/listening_tracker_service.dart';
import '../../l10n/app_localizations.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Real data from Firebase
  Map<String, dynamic> _analyticsData = {};
  bool _isLoading = true;
  bool _mounted = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this, initialIndex: 2);
    _loadAnalyticsData();

    // Auto refresh every 5 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
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
      debugPrint('Error loading analytics: $e');
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

  String _translateDayName(String dayName) {
    final l10n = AppLocalizations.of(context);
    switch (dayName) {
      case 'Mon':
        return l10n.mon;
      case 'Tue':
        return l10n.tue;
      case 'Wed':
        return l10n.wed;
      case 'Thu':
        return l10n.thu;
      case 'Fri':
        return l10n.fri;
      case 'Sat':
        return l10n.sat;
      case 'Sun':
        return l10n.sun;
      default:
        return dayName;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final screenSize = mq.size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    // Improved responsive detection
    final bool isCompactDevice = screenHeight < 700 || screenWidth < 360;
    final bool isTablet = screenWidth >= 600 && screenWidth < 1024;
    final bool isShortWide =
        screenWidth >= 1024 && screenHeight <= 800; // Nest Hub (Max)
    final bool isDesktop = screenWidth >= 1024 && !isShortWide;

    // Adaptive sizing
    final double donutSize = isCompactDevice
        ? 120
        : isShortWide
            ? 110
            : isTablet
                ? 140
                : isDesktop
                    ? 160
                    : 130;

    final double chartHeight = isCompactDevice
        ? 120
        : isShortWide
            ? 100
            : isTablet
                ? 160
                : 140;

    final double statCardPadding = isCompactDevice ? 8 : 16;
    final double spacingUnit = isCompactDevice
        ? 12
        : isShortWide
            ? 16
            : 24;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: (isTablet || isDesktop) ? 72 : kToolbarHeight,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            AppLocalizations.of(context).yourProgress,
            style: GoogleFonts.inter(
              fontSize: (isTablet || isDesktop) ? 22 : 20,
              height: 1.15,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ),
      ),
      body: MediaQuery(
        data: (screenHeight <= 740)
            ? mq.copyWith(textScaler: const TextScaler.linear(1.0))
            : mq,
        child: RefreshIndicator(
          onRefresh: () async => _loadAnalyticsData(),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(isCompactDevice ? 12.w : 20.w),

                  // 1) Max içerik genişliği + merkezleme (Nest Hub/Max’ta aşırı yayılmayı keser)
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Description
                          Text(
                            AppLocalizations.of(context).trackYourListening,
                            style: GoogleFonts.inter(
                              fontSize: isCompactDevice ? 12.sp : 14.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: spacingUnit.h),

                          // 2) Stat Cards — Row/Expanded yerine genişliği kontrollü Wrap
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final double gap = 12.w;
                              final double perCard =
                                  (constraints.maxWidth - (2 * gap)) / 3;
                              final double maxCardW =
                                  isDesktop ? 320 : (isTablet ? 300 : perCard);
                              final double cardW =
                                  perCard > maxCardW ? maxCardW : perCard;

                              return Wrap(
                                spacing: gap,
                                runSpacing: gap,
                                children: [
                                  SizedBox(
                                    width: cardW,
                                    child: _buildStatCard(
                                      value:
                                          '${_analyticsData['totalMinutes'] ?? 0}',
                                      unit: AppLocalizations.of(context).min,
                                      label: AppLocalizations.of(context)
                                          .totalListening,
                                      isCompact: isCompactDevice,
                                      padding: statCardPadding,
                                    ),
                                  ),
                                  SizedBox(
                                    width: cardW,
                                    child: _buildStatCard(
                                      value:
                                          '${_analyticsData['totalSessions'] ?? 0}',
                                      unit: AppLocalizations.of(context)
                                          .subliminals,
                                      label: AppLocalizations.of(context)
                                          .totalSessions,
                                      isCompact: isCompactDevice,
                                      padding: statCardPadding,
                                    ),
                                  ),
                                  SizedBox(
                                    width: cardW,
                                    child: _buildStatCard(
                                      value:
                                          '${_analyticsData['currentStreak'] ?? 0}',
                                      unit: AppLocalizations.of(context).days,
                                      label: AppLocalizations.of(context)
                                          .currentStreak,
                                      isCompact: isCompactDevice,
                                      padding: statCardPadding,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          SizedBox(height: spacingUnit.h),

                          // Period tabs - Fixed alignment
                          Container(
                            height: 40.h,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEEEEE),
                              borderRadius: BorderRadius.circular(24.r),
                            ),
                            padding: EdgeInsets.all(3.w),
                            child: TabBar(
                              controller: _tabController,
                              isScrollable: false, // Always fill width
                              indicator: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(20.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              indicatorSize: TabBarIndicatorSize.tab,
                              labelColor: Colors.white,
                              unselectedLabelColor: Colors.black87,
                              labelStyle: GoogleFonts.inter(
                                fontSize: isCompactDevice ? 10.sp : 11.sp,
                                fontWeight: FontWeight.w600,
                              ),
                              unselectedLabelStyle: GoogleFonts.inter(
                                fontSize: isCompactDevice ? 10.sp : 11.sp,
                                fontWeight: FontWeight.w500,
                              ),
                              labelPadding: EdgeInsets.zero,
                              tabs: [
                                Tab(
                                    text:
                                        AppLocalizations.of(context).analytics),
                                Tab(text: AppLocalizations.of(context).year),
                                Tab(text: AppLocalizations.of(context).month),
                                Tab(text: AppLocalizations.of(context).week),
                                Tab(text: AppLocalizations.of(context).day),
                              ],
                              onTap: (i) {
                                final periods = [
                                  AppLocalizations.of(context).analytics,
                                  AppLocalizations.of(context).year,
                                  AppLocalizations.of(context).month,
                                  AppLocalizations.of(context).week,
                                  AppLocalizations.of(context).day,
                                ];
                              },
                            ),
                          ),
                          SizedBox(height: spacingUnit.h),

                          // Donut + Top Sessions - short-wide (Hub/Max) cihazlarda stack
                          if (isCompactDevice || isShortWide) ...[
                            Center(
                              child: _Donut(
                                donutSize: donutSize,
                                stroke: isCompactDevice ? 15 : 20,
                                analytics: _analyticsData,
                              ),
                            ),
                            SizedBox(height: 16.h),
                            _TopSessions(_buildTopSessionBars),
                          ] else ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _Donut(
                                  donutSize: donutSize,
                                  stroke: 20,
                                  analytics: _analyticsData,
                                ),
                                SizedBox(width: 20.w),
                                Expanded(
                                    child: _TopSessions(_buildTopSessionBars)),
                              ],
                            ),
                          ],
                          SizedBox(height: spacingUnit.h),

                          // Progress bars
                          Column(
                            children: [
                              _buildProgressBar(
                                AppLocalizations.of(context).day,
                                (_analyticsData['monthlyProgress']
                                        as Map<String, double>?)?['Day'] ??
                                    0.0,
                                const Color(0xFFE8C5A0),
                                isCompact: isCompactDevice,
                              ),
                              SizedBox(height: 12.h),
                              _buildProgressBar(
                                AppLocalizations.of(context).week,
                                (_analyticsData['monthlyProgress']
                                        as Map<String, double>?)?['Week'] ??
                                    0.0,
                                const Color(0xFF7DB9B6),
                                isCompact: isCompactDevice,
                              ),
                              SizedBox(height: 12.h),
                              _buildProgressBar(
                                AppLocalizations.of(context).month,
                                (_analyticsData['monthlyProgress']
                                        as Map<String, double>?)?['Month'] ??
                                    0.0,
                                const Color(0xFF7DB9B6),
                                isCompact: isCompactDevice,
                              ),
                              SizedBox(height: 12.h),
                              _buildProgressBar(
                                AppLocalizations.of(context).year,
                                (_analyticsData['monthlyProgress']
                                        as Map<String, double>?)?['Year'] ??
                                    0.0,
                                const Color(0xFF9B8B7E),
                                isCompact: isCompactDevice,
                              ),
                            ],
                          ),
                          SizedBox(height: spacingUnit.h),

                          // Weekly chart
                          Container(
                            padding:
                                EdgeInsets.all(isCompactDevice ? 12.w : 16.w),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      AppLocalizations.of(context).thisWeek,
                                      style: GoogleFonts.inter(
                                        fontSize:
                                            isCompactDevice ? 12.sp : 14.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      '${_analyticsData['weeklyTotal'] ?? 0} ${AppLocalizations.of(context).min} ${AppLocalizations.of(context).total}',
                                      style: GoogleFonts.inter(
                                        fontSize:
                                            isCompactDevice ? 10.sp : 12.sp,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16.h),
                                SizedBox(
                                  height: chartHeight,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: _buildWeeklyBars(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: mq.padding.bottom + 20),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String value,
    required String unit,
    required String label,
    required bool isCompact,
    required double padding,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isCompact ? 12.h : 16.h,
        horizontal: 4.w,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: isCompact ? 22.sp : 28.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    height: 1,
                  ),
                ),
                SizedBox(width: 2.w),
                Text(
                  unit,
                  style: GoogleFonts.inter(
                    fontSize: isCompact ? 8.sp : 10.sp,
                    color: Colors.black54,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: isCompact ? 9.sp : 11.sp,
              color: Colors.grey[600],
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
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
          AppLocalizations.of(context).noSessionsYet,
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
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 2.h),
              Container(
                height: 28.h,
                decoration: BoxDecoration(
                  color: colors[i].withValues(alpha: 0.2),
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
                          '$minutes ${AppLocalizations.of(context).min}',
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

  Widget _buildProgressBar(String label, double progress, Color color,
      {bool isCompact = false}) {
    return Row(
      children: [
        Icon(Icons.circle, size: isCompact ? 6.sp : 8.sp, color: color),
        SizedBox(width: 8.w),
        ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: 40.w,
            maxWidth: 70.w,
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: isCompact ? 10.sp : 12.sp,
              color: Colors.black87,
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: isCompact ? 4.h : 6.h,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(3.r),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: isCompact ? 4.h : 6.h,
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
            fontSize: isCompact ? 9.sp : 11.sp,
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

      bars.add(_buildDayBar(_translateDayName(dayName), height, barColor));
    }

    return bars;
  }

  Widget _buildDayBar(String day, double t, Color color) {
    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          const double gap = 6;
          // chart yüksekliğine göre 10–13 aralığında ölçekle
          final double fs = (constraints.maxHeight * 0.12).clamp(10.0, 13.0);
          final double labelBox = fs + 8; // metrik payı

          // Bar için gerçekten kullanılabilir yükseklik
          final double maxBarH = (constraints.maxHeight - (labelBox + gap))
              .clamp(0.0, double.infinity);

          // Oransal bar yüksekliği (0..1 arası)
          final double barH = maxBarH * t.clamp(0.0, 1.0);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2), // yatay aralık
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: double.infinity,
                  height: barH,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ),
                const SizedBox(height: gap),
                SizedBox(
                  height: labelBox,
                  child: FittedBox(
                    // küçük ekranlarda metni güvenle sığdırır
                    fit: BoxFit.scaleDown,
                    child: Text(
                      day,
                      style: GoogleFonts.inter(
                        fontSize: fs,
                        height: 1.0,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
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

class _Donut extends StatelessWidget {
  const _Donut(
      {required this.donutSize, required this.stroke, required this.analytics});
  final double donutSize;
  final double stroke;
  final Map<String, dynamic> analytics;

  @override
  Widget build(BuildContext context) {
    final today = (analytics['todayMinutes'] ?? 0) as num;
    final double inner = donutSize - 2 * stroke - 8.0;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: donutSize,
        maxHeight: donutSize,
        minWidth: 100,
        minHeight: 100,
      ),
      child: SizedBox(
        width: donutSize,
        height: donutSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size(donutSize, donutSize),
              painter: CircularProgressPainter(
                progress: (today / 30.0).clamp(0.0, 1.0),
                backgroundColor: const Color(0xFFEAEAEA),
                progressColor: const Color(0xFF7DB9B6),
                strokeWidth: stroke,
              ),
            ),
            SizedBox(
              width: inner,
              height: inner,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$today',
                        style: GoogleFonts.inter(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        AppLocalizations.of(context).minutesToday,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopSessions extends StatelessWidget {
  const _TopSessions(this.builder);
  final List<Widget> Function() builder;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).topSessions,
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 8.h),
        ...builder(),
      ],
    );
  }
}
