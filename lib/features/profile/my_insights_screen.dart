// lib/features/profile/my_insights_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_localizations.dart';
import '../../core/themes/app_theme_extension.dart';
import 'services/insights_service.dart';
import 'widgets/insights/insights_header.dart';
import 'widgets/insights/overview_tab.dart';
import 'widgets/insights/goals_tab.dart';
import 'widgets/insights/stats_tab.dart';
import 'widgets/insights/journey_tab.dart';

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

  // Cached futures for FutureBuilder (prevents rebuild on every setState)
  Future<Map<String, int>>? _weeklyActivityFuture;
  Future<String>? _longestSessionFuture;
  Future<String>? _favoriteTimeFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadUserData();
    _loadAsyncData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<String> get _tabs {
    final l10n = AppLocalizations.of(context);
    return [
      l10n.overview,
      l10n.goalsTab,
      l10n.stats,
      l10n.journey,
    ];
  }

  Future<void> _loadUserData() async {
    final data = await InsightsService.loadUserData();
    if (data != null && mounted) {
      setState(() {
        _userData = data;
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _loadAsyncData() {
    _weeklyActivityFuture = InsightsService.getWeeklyActivity();
    _longestSessionFuture = InsightsService.getLongestSession();
    _favoriteTimeFuture = _getFavoriteTimeLocalized();
  }

  Future<String> _getFavoriteTimeLocalized() async {
    final timeSlot = await InsightsService.getFavoriteTimeSlot();
    if (!mounted) return timeSlot;

    final l10n = AppLocalizations.of(context);
    switch (timeSlot) {
      case 'Morning':
        return l10n.morning;
      case 'Afternoon':
        return l10n.afternoon;
      case 'Evening':
        return l10n.evening;
      case 'Night':
        return l10n.night;
      default:
        return l10n.evening;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: _buildAppBar(),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colors.textPrimary))
          : Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      OverviewTab(userData: _userData),
                      GoalsTab(userData: _userData),
                      StatsTab(
                        userData: _userData,
                        weeklyActivityFuture: _weeklyActivityFuture,
                        longestSessionFuture: _longestSessionFuture,
                        favoriteTimeFuture: _favoriteTimeFuture,
                      ),
                      JourneyTab(userData: _userData),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final colors = context.colors;
    return AppBar(
      backgroundColor: colors.backgroundCard,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: colors.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        AppLocalizations.of(context).myInsights,
        style: GoogleFonts.inter(
          fontSize: 20.sp,
          fontWeight: FontWeight.w600,
          color: colors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final colors = context.colors;
    return Container(
      color: colors.background,
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).yourPersonalizedProfile,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              color: colors.textSecondary,
            ),
          ),
          SizedBox(height: 20.h),
          InsightsStatsRow(userData: _userData),
          SizedBox(height: 24.h),
          InsightsTabBar(
            tabController: _tabController,
            tabs: _tabs,
          ),
        ],
      ),
    );
  }
}
