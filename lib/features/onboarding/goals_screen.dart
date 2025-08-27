import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/models/user_preferences.dart';
import 'gender_screen.dart';
import '../../services/analytics_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/routes/app_routes.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen>
    with SingleTickerProviderStateMixin {
  final Set<UserGoal> _selectedGoals = {};
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Animasyonu frame sonrası başlat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });

    AnalyticsService.logOnboardingStart();
    AnalyticsService.logScreenView('goals_screen');
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              // Skip onboarding
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('onboardingSkipped', true);

              if (mounted) {
                Navigator.pushReplacementNamed(context, AppRoutes.welcome);
              }
            },
            child: Text(
              'Skip',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                'Tell us about yourself',
                style: GoogleFonts.inter(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w600,
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
              SizedBox(height: 40.h),

              // Question
              Text(
                'What are your current goals',
                style: GoogleFonts.inter(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 24.h),

              // Goal Options
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Dinamik aspect ratio hesaplama
                      final screenWidth = MediaQuery.of(context).size.width;
                      final cardWidth = (screenWidth - 48.w - 16.w) / 2;
                      final cardHeight = cardWidth / 1.5;

                      return GridView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.zero,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16.w,
                          mainAxisSpacing: 16.h,
                          childAspectRatio: cardWidth / cardHeight,
                        ),
                        itemCount: UserGoal.values.length,
                        itemBuilder: (context, index) {
                          final goal = UserGoal.values[index];
                          final isSelected = _selectedGoals.contains(goal);
                          return _buildGoalCard(goal, isSelected, index);
                        },
                      );
                    },
                  ),
                ),
              ),

              // Continue Button
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                height: 56.h,
                child: ElevatedButton(
                  onPressed: _selectedGoals.isNotEmpty
                      ? () {
                          AnalyticsService.logGoalsSelected(
                            _selectedGoals.map((g) => g.title).toList(),
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GenderScreen(
                                selectedGoals: _selectedGoals.toList(),
                              ),
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.textPrimary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.greyLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                  child: Text(
                    'Continue',
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalCard(UserGoal goal, bool isSelected, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value.clamp(0.0, 1.0), // Scale değerini sınırla
          child: Opacity(
            opacity: value.clamp(0.0, 1.0), // Opacity değerini sınırla
            child: GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedGoals.remove(goal);
                  } else {
                    _selectedGoals.add(goal);
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.textPrimary : Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.textPrimary
                        : AppColors.greyBorder,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? AppColors.textPrimary.withOpacity(0.2)
                          : Colors.black.withOpacity(0.05),
                      blurRadius: isSelected ? 15 : 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(12.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icon with colored background
                      Flexible(
                        child: Container(
                          width: 45.w,
                          height: 45.w,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withOpacity(0.2)
                                : goal.color.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            goal.icon,
                            size: 24.sp,
                            color: isSelected ? Colors.white : goal.color,
                          ),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        goal.title,
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                          color:
                              isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
