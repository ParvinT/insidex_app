import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_colors.dart';
import '../../core/responsive/auth_scaffold.dart';
import '../../core/routes/app_routes.dart';
import '../../services/analytics_service.dart';
import '../../shared/models/user_preferences.dart';
import '../auth/welcome_screen.dart';

class BirthDateScreen extends StatefulWidget {
  final List<UserGoal> selectedGoals;
  final Gender selectedGender;
  const BirthDateScreen(
      {super.key, required this.selectedGoals, required this.selectedGender});

  @override
  State<BirthDateScreen> createState() => _BirthDateScreenState();
}

class _BirthDateScreenState extends State<BirthDateScreen> {
  DateTime? _selectedDate;
  bool _isLoading = false;
  String? _errorMessage;

  static const int minimumAge = 18;
  static const int recommendedAge = 18;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('birthdate_screen');
  }

  int? get _userAge {
    if (_selectedDate == null) return null;
    final now = DateTime.now();
    int age = now.year - _selectedDate!.year;
    final hadBirthday = (now.month > _selectedDate!.month) ||
        (now.month == _selectedDate!.month && now.day >= _selectedDate!.day);
    if (!hadBirthday) age -= 1;
    return age;
  }

  bool get _isAgeValid => (_userAge ?? 0) >= minimumAge;
  bool get _isAgeRecommended => (_userAge ?? 0) >= recommendedAge;

  Future<void> _saveAndContinue() async {
    if (_selectedDate == null) {
      setState(() => _errorMessage = 'Please select your birth date');
      return;
    }
    if (!_isAgeValid) {
      setState(() => _errorMessage =
          'You must be at least $minimumAge years old to use this app');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('birthDate', _selectedDate!.toIso8601String());
      await prefs.setInt('userAge', _userAge!);
      await prefs.setString('gender', widget.selectedGender.toString());
      await prefs.setStringList(
          'goals', widget.selectedGoals.map((g) => g.title).toList());

      await AnalyticsService.logBirthDateSelected(_userAge!, _userAge! < 18);
      await AnalyticsService.logOnboardingComplete();

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'birthDate': Timestamp.fromDate(_selectedDate!),
          'age': _userAge,
          'ageRestricted': _userAge! < 18,
          'gender': widget.selectedGender.toString().split('.').last,
          'goals': widget.selectedGoals.map((g) => g.title).toList(),
          'onboardingComplete': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error saving data. Please try again.';
      });
      // ignore: avoid_print
      print('Error saving birth date: $e');
    }
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
        bodyIsScrollable: true,
        backgroundColor: AppColors.backgroundWhite,
        bottomAreaVisualHeight: bottomVisual,
        bottomArea: _BottomBar(
          enabled: _selectedDate != null && _isAgeValid && !_isLoading,
          loading: _isLoading,
          onPressed: _saveAndContinue,
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
                  await prefs.setString(
                      'gender', widget.selectedGender.toString());
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
                            color: AppColors.textPrimary),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'This helps us personalize your experience',
                        style: GoogleFonts.inter(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textSecondary),
                      ),
                      SizedBox(height: 24.h),
                      Text(
                        'Date of Birth',
                        style: GoogleFonts.inter(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary),
                      ),
                      SizedBox(height: 16.h),
                      _dateInput(),
                      SizedBox(height: 12.h),
                      if (_selectedDate != null) _ageBadge(),
                      if (_errorMessage != null) ...[
                        SizedBox(height: 12.h),
                        _errorBanner(_errorMessage!)
                      ],
                      SizedBox(height: 12.h),
                      _privacyInfo(),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: 24.h)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dateInput() {
    return GestureDetector(
      onTap: _showDatePicker,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: _errorMessage != null
                ? Colors.red
                : _selectedDate != null
                    ? AppColors.textPrimary
                    : AppColors.greyBorder,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedDate != null
                  ? _formatDate(_selectedDate!)
                  : 'Select your birth date',
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: _selectedDate != null
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
            Icon(Icons.calendar_today_outlined,
                color: AppColors.textSecondary, size: 20.sp),
          ],
        ),
      ),
    );
  }

  Widget _ageBadge() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: _isAgeValid
            ? (_isAgeRecommended
                ? Colors.green.withOpacity(0.1)
                : Colors.orange.withOpacity(0.1))
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: _isAgeValid
              ? (_isAgeRecommended ? Colors.green : Colors.orange)
              : Colors.red,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isAgeValid
                ? (_isAgeRecommended ? Icons.check_circle : Icons.warning)
                : Icons.error,
            color: _isAgeValid
                ? (_isAgeRecommended ? Colors.green : Colors.orange)
                : Colors.red,
            size: 20.sp,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              _isAgeValid
                  ? 'Age: ${_userAge} years old'
                  : 'You must be at least 18 years old',
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: _isAgeValid
                    ? (_isAgeRecommended ? Colors.green : Colors.orange)
                    : Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorBanner(String msg) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8.r)),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 18.sp),
          SizedBox(width: 8.w),
          Expanded(
              child: Text(msg,
                  style:
                      GoogleFonts.inter(fontSize: 12.sp, color: Colors.red))),
        ],
      ),
    );
  }

  Widget _privacyInfo() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
          color: AppColors.greyLight,
          borderRadius: BorderRadius.circular(12.r)),
      child: Row(
        children: [
          Icon(Icons.lock_outline, color: AppColors.textSecondary, size: 16.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'Your information is secure and will never be shared',
              style: GoogleFonts.inter(
                  fontSize: 11.sp, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      children: List.generate(
        3,
        (index) => Expanded(
          child: Container(
            height: 4.h,
            margin: EdgeInsets.only(right: index < 2 ? 8.w : 0),
            decoration: BoxDecoration(
              color: AppColors.textPrimary,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
        ),
      ),
    );
  }

  void _showDatePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
      builder: (_) => SizedBox(
        height: 300.h,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel',
                        style: GoogleFonts.inter(
                            color: AppColors.textSecondary, fontSize: 16.sp)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Done',
                        style: GoogleFonts.inter(
                            color: AppColors.textPrimary,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                maximumDate: DateTime.now(),
                initialDateTime: _selectedDate ?? DateTime(2000, 1, 1),
                onDateTimeChanged: (date) => setState(() {
                  _selectedDate = date;
                  _errorMessage = null;
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _BottomBar extends StatelessWidget {
  final bool enabled;
  final bool loading;
  final VoidCallback onPressed;
  const _BottomBar(
      {required this.enabled, required this.loading, required this.onPressed});

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
          onPressed: enabled && !loading ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.textPrimary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.greyLight,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r)),
          ),
          child: loading
              ? SizedBox(
                  width: 24.w,
                  height: 24.w,
                  child: const CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : Text('Continue',
                  style: GoogleFonts.inter(
                      fontSize: 16.sp, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}
