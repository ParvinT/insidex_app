import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:marquee/marquee.dart';

import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/responsive/auth_scaffold.dart';
import '../../services/analytics_service.dart';
import '../../shared/models/user_preferences.dart';
import '../../l10n/app_localizations.dart';
import 'gender_screen.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen>
    with SingleTickerProviderStateMixin {
  final Set<UserGoal> _selectedGoals = {};
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _animationController.forward());

    AnalyticsService.logOnboardingStart();
    AnalyticsService.logScreenView('goals_screen');
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onContinue() {
    if (_selectedGoals.isEmpty) return;
    AnalyticsService.logGoalsSelected(
        _selectedGoals.map((g) => g.title).toList());
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GenderScreen(selectedGoals: _selectedGoals.toList()),
      ),
    );
  }

  String _getLocalizedGoalTitle(UserGoal goal) {
    final l10n = AppLocalizations.of(context);
    switch (goal) {
      case UserGoal.health:
        return l10n.health;
      case UserGoal.confidence:
        return l10n.confidence;
      case UserGoal.energy:
        return l10n.energy;
      case UserGoal.betterSleep:
        return l10n.betterSleep;
      case UserGoal.anxietyRelief:
        return l10n.anxietyRelief;
      case UserGoal.emotionalBalance:
        return l10n.emotionalBalance;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final size = mq.size;
    final bool isCompactHeight = size.height <= 740;
    final bool isNarrowWidth = size.width <= 420;

    final clamped = mq.copyWith(textScaler: const TextScaler.linear(1.0));
    return MediaQuery(
      data: isCompactHeight ? clamped : mq,
      child: AuthScaffold(
        bodyIsScrollable: true,
        backgroundColor: AppColors.backgroundWhite,
        bottomAreaVisualHeight: 0.0,
        bottomArea: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
          child: _BottomBar(
            enabled: _selectedGoals.isNotEmpty,
            onPressed: _onContinue,
          ),
        ),
        appBar: AppBar(
          backgroundColor: AppColors.backgroundWhite,
          elevation: 0,
          toolbarHeight: 64,
          automaticallyImplyLeading: false,
          actions: [
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 16),
              child: TextButton(
                onPressed: () async {
                  final navigator = Navigator.of(context);

                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('onboardingSkipped', true);
                  if (mounted) {
                    navigator.pushReplacementNamed(AppRoutes.welcome);
                  }
                },
                style: TextButton.styleFrom(
                  minimumSize: const Size(44, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: Text(
                  AppLocalizations.of(context).skip,
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProgressIndicator(),
                        SizedBox(height: 24.h),
                        Text(
                          AppLocalizations.of(context).tellUsAboutYourself,
                          style: GoogleFonts.inter(
                            fontSize: 28.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          AppLocalizations.of(context).answerQuickQuestions,
                          style: GoogleFonts.inter(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: 24.h),
                        Text(
                          AppLocalizations.of(context).whatAreYourGoals,
                          style: GoogleFonts.inter(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 16.h),
                      ],
                    ),
                  ),
                ),

                // Grid of goals
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent:
                          isNarrowWidth ? 180 : 220, // ← Daha kompakt
                      crossAxisSpacing: 12.w, // ← Az spacing
                      mainAxisSpacing: 12.h, // ← Az spacing
                      childAspectRatio: 0.95,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final goal = UserGoal.values[index];
                        final isSelected = _selectedGoals.contains(goal);
                        return _GoalCard(
                          goal: goal,
                          isSelected: isSelected,
                          localizedTitle: _getLocalizedGoalTitle(goal),
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedGoals.remove(goal);
                              } else {
                                _selectedGoals.add(goal);
                              }
                            });
                          },
                        );
                      },
                      childCount: UserGoal.values.length,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 4.h,
            decoration: BoxDecoration(
              color: AppColors.textPrimary,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Container(
            height: 4.h,
            decoration: BoxDecoration(
              color: AppColors.greyLight,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Container(
            height: 4.h,
            decoration: BoxDecoration(
              color: AppColors.greyLight,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
        ),
      ],
    );
  }
}

class _GoalCard extends StatelessWidget {
  final UserGoal goal;
  final bool isSelected;
  final VoidCallback onTap;
  final String localizedTitle;
  const _GoalCard(
      {required this.goal,
      required this.isSelected,
      required this.onTap,
      required this.localizedTitle});

  @override
  Widget build(BuildContext context) {
    // Ekran boyutuna göre responsive icon size
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isTablet = screenWidth >= 600;

    final iconSize = isTablet ? 52.0 : 48.0;
    final iconInnerSize = isTablet ? 26.0 : 24.0;
    final textSize = isTablet ? 14.0 : 13.0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.textPrimary : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isSelected ? AppColors.textPrimary : AppColors.greyBorder,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.textPrimary.withValues(alpha: 0.18)
                  : Colors.black.withValues(alpha: 0.06),
              blurRadius: isSelected ? 14 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: EdgeInsets.all(12.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon bubble - SABİT BOYUT
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.2)
                    : goal.color.withValues(alpha: 0.1),
              ),
              child: Icon(
                goal.icon,
                size: iconInnerSize,
                color: isSelected ? Colors.white : goal.color,
              ),
            ),

            SizedBox(height: 10.h),

            // Text - Marquee ile
            Flexible(
              child: _buildScrollingGoalText(
                localizedTitle,
                GoogleFonts.inter(
                  fontSize: textSize,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScrollingGoalText(String text, TextStyle style) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Text genişliğini hesapla
        final textPainter = TextPainter(
          text: TextSpan(text: text, style: style),
          maxLines: 1,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: double.infinity);

        final availableWidth = constraints.maxWidth;

        // Text sığıyorsa normal Text
        if (textPainter.width <= availableWidth) {
          return Text(
            text,
            style: style,
            maxLines: 1,
            textAlign: TextAlign.center,
          );
        }

        // Sığmıyorsa Marquee
        return SizedBox(
          height: style.fontSize! * 1.4,
          child: Marquee(
            text: text,
            style: style,
            scrollAxis: Axis.horizontal,
            crossAxisAlignment: CrossAxisAlignment.center,
            blankSpace: 30.0, // Boşluk
            velocity: 25.0, // Hız
            pauseAfterRound: const Duration(seconds: 1),
            startPadding: 5.0,
            accelerationDuration: const Duration(milliseconds: 800),
            accelerationCurve: Curves.easeInOut,
            decelerationDuration: const Duration(milliseconds: 400),
            decelerationCurve: Curves.easeOut,
          ),
        );
      },
    );
  }
}

class _BottomBar extends StatelessWidget {
  final bool enabled;
  final VoidCallback onPressed;
  const _BottomBar({required this.enabled, required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.fromLTRB(
        20.w,
        12.h,
        20.w,
        MediaQuery.of(context).padding.bottom + 12.h, // Safe area
      ),
      child: SizedBox(
        width: double.infinity,
        height: 48.h, // 52'den 48'e düşürdük
        child: ElevatedButton(
          onPressed: enabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.textPrimary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.greyLight,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r), // 16'dan 12'ye
            ),
            elevation: 0,
            shadowColor: Colors.transparent,
            padding: EdgeInsets.symmetric(horizontal: 16.w), // Padding ekledik
          ),
          child: FittedBox(
            // Yazı sığmazsa küçültsün
            fit: BoxFit.scaleDown,
            child: Text(
              AppLocalizations.of(context).continueButton,
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
