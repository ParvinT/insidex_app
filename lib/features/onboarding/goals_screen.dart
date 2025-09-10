import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/responsive/auth_scaffold.dart';
import '../../services/analytics_service.dart';
import '../../shared/models/user_preferences.dart';
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

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final size = mq.size;
    final bool isCompactHeight = size.height <= 740;
    final bool isNarrowWidth = size.width <= 420;

    final clamped = mq.copyWith(textScaler: const TextScaler.linear(1.0));
    final bool isWideOrShort = size.width >= 1024 || size.height <= 740;
    final double bottomVisual = isWideOrShort ? 96.0 : 80.0;
    return MediaQuery(
      data: isCompactHeight ? clamped : mq,
      child: AuthScaffold(
        bodyIsScrollable: true,
        backgroundColor: AppColors.backgroundWhite,
        bottomAreaVisualHeight: bottomVisual,
        bottomArea: _BottomBar(
          enabled: _selectedGoals.isNotEmpty,
          onPressed: _onContinue,
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
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('onboardingSkipped', true);
                  if (mounted) {
                    Navigator.pushReplacementNamed(context, AppRoutes.welcome);
                  }
                },
                style: TextButton.styleFrom(
                  minimumSize: const Size(44, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: Text(
                  'Skip',
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
                          'Tell us about yourself',
                          style: GoogleFonts.inter(
                            fontSize: 28.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Answer a few quick questions to get personalized recommendations',
                          style: GoogleFonts.inter(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: 24.h),
                        Text(
                          'What are your current goals',
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
                      maxCrossAxisExtent: isNarrowWidth ? 210 : 260,
                      crossAxisSpacing: 16.w,
                      mainAxisSpacing: 16.h,
                      // bir miktar daha yüksek tile: emojiler kesilmesin
                      childAspectRatio: isCompactHeight ? 1.0 : 1.20,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final goal = UserGoal.values[index];
                        final isSelected = _selectedGoals.contains(goal);
                        return _GoalCard(
                          goal: goal,
                          isSelected: isSelected,
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
                SliverToBoxAdapter(child: SizedBox(height: 24.h)),
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
  const _GoalCard(
      {required this.goal, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Emojilerin/ikonların kesilmesini ve 1–2 satır metnin sığmamasını
    // FittedBox yaklaşımıyla kesin olarak önlüyoruz.
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
                  ? AppColors.textPrimary.withOpacity(0.18)
                  : Colors.black.withOpacity(0.06),
              blurRadius: isSelected ? 14 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon bubble
                Container(
                  width: 44.w,
                  height: 44.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? Colors.white.withOpacity(0.2)
                        : goal.color.withOpacity(0.1),
                  ),
                  child: Icon(
                    goal.icon,
                    size: 22.sp,
                    color: isSelected ? Colors.white : goal.color,
                  ),
                ),
                SizedBox(height: 8.h),
                // Title (2 lines max)
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 140.w),
                  child: Text(
                    goal.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
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
}

class _BottomBar extends StatelessWidget {
  final bool enabled;
  final VoidCallback onPressed;
  const _BottomBar({required this.enabled, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isWideOrShort = size.width >= 1024 || size.height <= 740;
    final double buttonHeight = isWideOrShort ? 100.h : 56.h;
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 12.h),
      child: SizedBox(
        width: double.infinity,
        height: buttonHeight,
        child: ElevatedButton(
          onPressed: enabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.textPrimary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.greyLight,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r)),
          ),
          child: Text('Continue',
              style: GoogleFonts.inter(
                  fontSize: 16.sp, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}
