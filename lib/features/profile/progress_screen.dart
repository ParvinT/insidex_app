// lib/features/profile/progress_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../../l10n/app_localizations.dart';
import '../../core/themes/app_theme_extension.dart';
import 'services/progress_analytics_service.dart';
import 'widgets/progress/progress_widgets.dart';

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
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this, initialIndex: 2);
    _loadAnalyticsData();

    // Auto refresh every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _loadAnalyticsData();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalyticsData() async {
    final data = await ProgressAnalyticsService.loadAnalyticsData();
    if (mounted) {
      setState(() {
        _analyticsData = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
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

    final double spacingUnit = isCompactDevice
        ? 12
        : isShortWide
            ? 16
            : 24;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.backgroundCard,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: (isTablet || isDesktop) ? 72 : kToolbarHeight,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
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
              color: colors.textPrimary,
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
              ? Center(
                  child: CircularProgressIndicator(color: colors.textPrimary))
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(isCompactDevice ? 12.w : 20.w),
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
                              color: colors.textSecondary,
                            ),
                          ),
                          SizedBox(height: spacingUnit.h),

                          // Stat Cards
                          _buildStatCards(isCompactDevice, isDesktop, isTablet),
                          SizedBox(height: spacingUnit.h),

                          // Period tabs
                          _buildPeriodTabs(isCompactDevice),
                          SizedBox(height: spacingUnit.h),

                          // Donut + Top Sessions
                          _buildDonutAndTopSessions(
                            isCompactDevice,
                            isShortWide,
                            donutSize,
                          ),
                          SizedBox(height: spacingUnit.h),

                          // Progress bars
                          _buildProgressBars(isCompactDevice),
                          SizedBox(height: spacingUnit.h),

                          // Weekly chart
                          ProgressWeeklyChart(
                            weeklyData: _analyticsData['weeklyData']
                                    as Map<String, int>? ??
                                {},
                            todayMinutes:
                                _analyticsData['todayMinutes'] as int? ?? 0,
                            weeklyTotal:
                                _analyticsData['weeklyTotal'] as int? ?? 0,
                            isCompact: isCompactDevice,
                            chartHeight: chartHeight,
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

  Widget _buildStatCards(bool isCompact, bool isDesktop, bool isTablet) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double gap = 12.w;
        final double perCard = (constraints.maxWidth - (2 * gap)) / 3;
        final double maxCardW = isDesktop ? 320 : (isTablet ? 300 : perCard);
        final double cardW = perCard > maxCardW ? maxCardW : perCard;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            SizedBox(
              width: cardW,
              child: ProgressStatCard(
                value: '${_analyticsData['totalMinutes'] ?? 0}',
                unit: AppLocalizations.of(context).min,
                label: AppLocalizations.of(context).totalListening,
                isCompact: isCompact,
              ),
            ),
            SizedBox(
              width: cardW,
              child: ProgressStatCard(
                value: '${_analyticsData['totalSessions'] ?? 0}',
                unit: AppLocalizations.of(context).subliminals,
                label: AppLocalizations.of(context).totalSessions,
                isCompact: isCompact,
              ),
            ),
            SizedBox(
              width: cardW,
              child: ProgressStatCard(
                value: '${_analyticsData['currentStreak'] ?? 0}',
                unit: AppLocalizations.of(context).days,
                label: AppLocalizations.of(context).currentStreak,
                isCompact: isCompact,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPeriodTabs(bool isCompact) {
    final colors = context.colors;
    return Container(
      height: 40.h,
      decoration: BoxDecoration(
        color: colors.greyLight,
        borderRadius: BorderRadius.circular(24.r),
      ),
      padding: EdgeInsets.all(3.w),
      child: TabBar(
        controller: _tabController,
        isScrollable: false,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: colors.textPrimary,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: colors.textPrimary.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: colors.textOnPrimary,
        unselectedLabelColor: colors.textPrimary,
        labelStyle: GoogleFonts.inter(
          fontSize: isCompact ? 10.sp : 11.sp,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: isCompact ? 10.sp : 11.sp,
          fontWeight: FontWeight.w500,
        ),
        labelPadding: EdgeInsets.zero,
        tabs: [
          Tab(text: AppLocalizations.of(context).analytics),
          Tab(text: AppLocalizations.of(context).year),
          Tab(text: AppLocalizations.of(context).month),
          Tab(text: AppLocalizations.of(context).week),
          Tab(text: AppLocalizations.of(context).day),
        ],
        onTap: (i) {},
      ),
    );
  }

  Widget _buildDonutAndTopSessions(
    bool isCompact,
    bool isShortWide,
    double donutSize,
  ) {
    final topSessions =
        _analyticsData['topSessions'] as List<Map<String, dynamic>>? ?? [];

    if (isCompact || isShortWide) {
      return Column(
        children: [
          Center(
            child: ProgressDonut(
              donutSize: donutSize,
              stroke: isCompact ? 15 : 20,
              analytics: _analyticsData,
            ),
          ),
          SizedBox(height: 16.h),
          ProgressTopSessions(topSessions: topSessions),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProgressDonut(
          donutSize: donutSize,
          stroke: 20,
          analytics: _analyticsData,
        ),
        SizedBox(width: 20.w),
        Expanded(child: ProgressTopSessions(topSessions: topSessions)),
      ],
    );
  }

  Widget _buildProgressBars(bool isCompact) {
    final monthlyProgress =
        _analyticsData['monthlyProgress'] as Map<String, double>? ?? {};

    return Column(
      children: [
        ProgressBar(
          label: AppLocalizations.of(context).day,
          progress: monthlyProgress['Day'] ?? 0.0,
          color: const Color(0xFFE8C5A0),
          isCompact: isCompact,
        ),
        SizedBox(height: 12.h),
        ProgressBar(
          label: AppLocalizations.of(context).week,
          progress: monthlyProgress['Week'] ?? 0.0,
          color: const Color(0xFF7DB9B6),
          isCompact: isCompact,
        ),
        SizedBox(height: 12.h),
        ProgressBar(
          label: AppLocalizations.of(context).month,
          progress: monthlyProgress['Month'] ?? 0.0,
          color: const Color(0xFF7DB9B6),
          isCompact: isCompact,
        ),
        SizedBox(height: 12.h),
        ProgressBar(
          label: AppLocalizations.of(context).year,
          progress: monthlyProgress['Year'] ?? 0.0,
          color: const Color(0xFF9B8B7E),
          isCompact: isCompact,
        ),
      ],
    );
  }
}
