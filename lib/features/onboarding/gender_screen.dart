import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_colors.dart';
import '../../core/responsive/auth_scaffold.dart';
import '../../core/routes/app_routes.dart';
import '../../services/analytics_service.dart';
import '../../shared/models/user_preferences.dart';
import 'birth_date_screen.dart';

class GenderScreen extends StatefulWidget {
  final List<UserGoal> selectedGoals;
  const GenderScreen({super.key, required this.selectedGoals});

  @override
  State<GenderScreen> createState() => _GenderScreenState();
}

class _GenderScreenState extends State<GenderScreen> {
  Gender? _selectedGender;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('gender_screen');
  }

  void _onContinue() {
    if (_selectedGender == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BirthDateScreen(
          selectedGoals: widget.selectedGoals,
          selectedGender: _selectedGender!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final size = mq.size;

    final bool isCompactHeight = size.height <= 740;
    final clamped = mq.copyWith(textScaler: const TextScaler.linear(1.0));

    final bool isWideOrShort = size.width >= 1024 || size.height <= 740;
    final double bottomVisual = isWideOrShort ? 96.0 : 80.0;

    return MediaQuery(
      data: isCompactHeight ? clamped : mq,
      child: AuthScaffold(
        bodyIsScrollable: true, // whole page scrolls
        backgroundColor: AppColors.backgroundWhite,
        bottomAreaVisualHeight: bottomVisual,
        bottomArea: _BottomBar(
          enabled: _selectedGender != null,
          onPressed: _onContinue,
        ),
        appBar: AppBar(
          backgroundColor: AppColors.backgroundWhite,
          elevation: 0,
          toolbarHeight: 64,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 16),
              child: TextButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setStringList(
                    'goals',
                    widget.selectedGoals.map((g) => g.title).toList(),
                  );
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
                        'This helps us personalize your experience',
                        style: GoogleFonts.inter(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 24.h),
                      Text(
                        'Gender',
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
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                sliver: SliverList(
                  delegate: SliverChildListDelegate.fixed([
                    _genderOption(Gender.male, 'Male'),
                    SizedBox(height: 16.h),
                    _genderOption(Gender.female, 'Female'),
                    SizedBox(height: 24.h),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _genderOption(Gender gender, String label) {
    final isSelected = _selectedGender == gender;
    return GestureDetector(
      onTap: () => setState(() => _selectedGender = gender),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.textPrimary : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
              color: isSelected ? AppColors.textPrimary : AppColors.greyBorder,
              width: 1.5),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.textPrimary.withOpacity(0.20)
                  : Colors.black.withOpacity(0.05),
              blurRadius: isSelected ? 14 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 24.w,
              height: 24.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: isSelected ? Colors.white : AppColors.greyBorder,
                    width: 2),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                          width: 12.w,
                          height: 12.w,
                          decoration: const BoxDecoration(
                              shape: BoxShape.circle, color: Colors.white)),
                    )
                  : null,
            ),
            SizedBox(width: 16.w),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
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
                  borderRadius: BorderRadius.circular(2.r))),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Container(
              height: 4.h,
              decoration: BoxDecoration(
                  color: AppColors.textPrimary,
                  borderRadius: BorderRadius.circular(2.r))),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Container(
              height: 4.h,
              decoration: BoxDecoration(
                  color: AppColors.greyLight,
                  borderRadius: BorderRadius.circular(2.r))),
        ),
      ],
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
