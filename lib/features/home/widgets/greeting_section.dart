// lib/features/home/widgets/greeting_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/themes/app_theme_extension.dart';
import '../../../core/responsive/context_ext.dart';
import '../../../models/quote_model.dart';
import '../../../services/daily_quote_service.dart';
import '../../../l10n/app_localizations.dart';

/// Greeting section with personalized welcome message,
/// daily quote, and mini stats
class GreetingSection extends StatefulWidget {
  const GreetingSection({super.key});

  @override
  State<GreetingSection> createState() => _GreetingSectionState();
}

class _GreetingSectionState extends State<GreetingSection> {
  final DailyQuoteService _quoteService = DailyQuoteService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // User data
  String? _userName;
  List<String> _userGoals = [];
  int _currentStreak = 0;
  int _totalMinutes = 0;
  int _totalSessions = 0;

  // Quote
  QuoteModel? _todayQuote;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadUserData(),
      _loadTodayQuote(),
    ]);

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _userName = data['name'] as String?;
          _userGoals = List<String>.from(data['goals'] ?? []);
          _currentStreak = data['currentStreak'] as int? ?? 0;
          _totalMinutes = data['totalListeningMinutes'] as int? ?? 0;
          _totalSessions = (data['completedSessionIds'] as List?)?.length ?? 0;
        });
      }
    } catch (e) {
      debugPrint('❌ [GreetingSection] Error loading user data: $e');
    }
  }

  Future<void> _loadTodayQuote() async {
    try {
      // Wait for user data to load first
      await Future.delayed(const Duration(milliseconds: 100));

      final quote = await _quoteService.getTodayQuote(
        userGoals: _userGoals,
        streak: _currentStreak,
      );

      if (mounted) {
        setState(() => _todayQuote = quote);
      }
    } catch (e) {
      debugPrint('❌ [GreetingSection] Error loading quote: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isTablet = context.isTablet;
    final locale = Localizations.localeOf(context).languageCode;

    if (_isLoading) {
      return _buildLoadingState(colors, isTablet);
    }

    return Container(
      margin: EdgeInsets.only(bottom: isTablet ? 20.h : 16.h),
      padding: EdgeInsets.all(isTablet ? 20.w : 16.w),
      decoration: BoxDecoration(
        color: colors.backgroundCard,
        borderRadius: BorderRadius.circular(isTablet ? 20.r : 16.r),
        border: Border.all(
          color: colors.border.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.textPrimary.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting
          _buildGreeting(colors, locale, isTablet),

          // Quote (if available)
          if (_todayQuote != null) ...[
            SizedBox(height: isTablet ? 16.h : 12.h),
            _buildQuote(colors, locale, isTablet),
          ],

          // Mini Stats
          SizedBox(height: isTablet ? 16.h : 12.h),
          _buildMiniStats(colors, isTablet),
        ],
      ),
    );
  }

  Widget _buildLoadingState(AppThemeExtension colors, bool isTablet) {
    return Container(
      margin: EdgeInsets.only(bottom: isTablet ? 20.h : 16.h),
      padding: EdgeInsets.all(isTablet ? 20.w : 16.w),
      decoration: BoxDecoration(
        color: colors.backgroundCard,
        borderRadius: BorderRadius.circular(isTablet ? 20.r : 16.r),
        border: Border.all(
          color: colors.border.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting skeleton
          Container(
            width: 180.w,
            height: 24.h,
            decoration: BoxDecoration(
              color: colors.border.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          SizedBox(height: 12.h),
          // Quote skeleton
          Container(
            width: double.infinity,
            height: 60.h,
            decoration: BoxDecoration(
              color: colors.border.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
          SizedBox(height: 12.h),
          // Stats skeleton
          Container(
            width: double.infinity,
            height: 40.h,
            decoration: BoxDecoration(
              color: colors.border.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreeting(
      AppThemeExtension colors, String locale, bool isTablet) {
    final greeting = DailyQuoteService.getGreeting(_userName, locale);

    return Text(
      greeting,
      style: GoogleFonts.inter(
        fontSize: (isTablet ? 22.sp : 20.sp).clamp(18.0, 26.0),
        fontWeight: FontWeight.w700,
        color: colors.textPrimary,
      ),
    );
  }

  Widget _buildQuote(AppThemeExtension colors, String locale, bool isTablet) {
    final quoteText = _todayQuote!.getText(locale);
    final author = _todayQuote!.author;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 16.w : 14.w),
      decoration: BoxDecoration(
        color: colors.textPrimary.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(isTablet ? 14.r : 12.r),
        border: Border.all(
          color: colors.textPrimary.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quote icon
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.format_quote,
                size: (isTablet ? 20.sp : 18.sp).clamp(16.0, 22.0),
                color: colors.textSecondary.withValues(alpha: 0.5),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  quoteText,
                  style: GoogleFonts.inter(
                    fontSize: (isTablet ? 14.sp : 13.sp).clamp(12.0, 16.0),
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.italic,
                    color: colors.textPrimary.withValues(alpha: 0.85),
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),

          // Author (if available)
          if (author != null && author.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '— $author',
                style: GoogleFonts.inter(
                  fontSize: (isTablet ? 12.sp : 11.sp).clamp(10.0, 14.0),
                  fontWeight: FontWeight.w500,
                  color: colors.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMiniStats(AppThemeExtension colors, bool isTablet) {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 14.w : 12.w,
        vertical: isTablet ? 12.h : 10.h,
      ),
      decoration: BoxDecoration(
        color: colors.textPrimary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(isTablet ? 12.r : 10.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Streak
          _buildStatItem(
            icon: Icons.local_fire_department,
            value: '$_currentStreak',
            label: l10n.days,
            color: Colors.orange,
            isTablet: isTablet,
            colors: colors,
          ),

          _buildDivider(colors),

          // Total Minutes
          _buildStatItem(
            icon: Icons.timer_outlined,
            value: _formatMinutes(_totalMinutes, l10n),
            label: l10n.total,
            color: const Color(0xFF7DB9B6),
            isTablet: isTablet,
            colors: colors,
          ),

          _buildDivider(colors),

          // Total Sessions
          _buildStatItem(
            icon: Icons.headphones_outlined,
            value: '$_totalSessions',
            label: l10n.sessionsLabel,
            color: const Color(0xFFB8A6D9),
            isTablet: isTablet,
            colors: colors,
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
    required bool isTablet,
    required AppThemeExtension colors,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: (isTablet ? 18.sp : 16.sp).clamp(14.0, 20.0),
          color: color,
        ),
        SizedBox(width: 6.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: (isTablet ? 14.sp : 13.sp).clamp(12.0, 16.0),
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: (isTablet ? 10.sp : 9.sp).clamp(8.0, 12.0),
                fontWeight: FontWeight.w500,
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDivider(AppThemeExtension colors) {
    return Container(
      width: 1,
      height: 30.h,
      color: colors.border.withValues(alpha: 0.3),
    );
  }

  String _formatMinutes(int minutes, AppLocalizations l10n) {
    if (minutes < 60) {
      return '$minutes ${l10n.min}';
    } else {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      if (mins > 0) {
        return '$hours${l10n.hourShort} $mins${l10n.min}';
      }
      return '$hours${l10n.hourShort}';
    }
  }
}
