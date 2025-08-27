// lib/features/onboarding/birth_date_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/models/user_preferences.dart';
import '../auth/welcome_screen.dart';
import '../../services/analytics_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/routes/app_routes.dart';

class BirthDateScreen extends StatefulWidget {
  final List<UserGoal> selectedGoals;
  final Gender selectedGender;

  const BirthDateScreen({
    super.key,
    required this.selectedGoals,
    required this.selectedGender,
  });

  @override
  State<BirthDateScreen> createState() => _BirthDateScreenState();
}

class _BirthDateScreenState extends State<BirthDateScreen> {
  DateTime? _selectedDate;
  bool _isLoading = false;
  String? _errorMessage;

  // Age requirements
  static const int minimumAge = 13; // App Store/Play Store minimum
  static const int recommendedAge = 16; // Recommended for subliminal content

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('birthdate_screen');
  }

  // Calculate user age
  int? get _userAge {
    if (_selectedDate == null) return null;

    final now = DateTime.now();
    int age = now.year - _selectedDate!.year;

    // Adjust if birthday hasn't occurred this year
    if (now.month < _selectedDate!.month ||
        (now.month == _selectedDate!.month && now.day < _selectedDate!.day)) {
      age--;
    }

    return age;
  }

  // Validate age
  bool get _isAgeValid {
    if (_userAge == null) return false;
    return _userAge! >= minimumAge;
  }

  bool get _isAgeRecommended {
    if (_userAge == null) return false;
    return _userAge! >= recommendedAge;
  }

  // Save data and continue
  Future<void> _saveAndContinue() async {
    if (_selectedDate == null) {
      setState(() {
        _errorMessage = 'Please select your birth date';
      });
      return;
    }

    if (!_isAgeValid) {
      setState(() {
        _errorMessage =
            'You must be at least $minimumAge years old to use this app';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Save to SharedPreferences for offline access
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('birthDate', _selectedDate!.toIso8601String());
      await prefs.setInt('userAge', _userAge!);
      await prefs.setString('gender', widget.selectedGender.toString());
      await prefs.setStringList(
          'goals', widget.selectedGoals.map((g) => g.title).toList());
      await prefs.setBool('onboardingComplete', true);

// Analytics log ekleyin:
      await AnalyticsService.logBirthDateSelected(
        _userAge!,
        _userAge! < 16,
      );
      await AnalyticsService.logOnboardingComplete();
      // Check if user is authenticated
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Save to Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
            {
              'uid': user.uid,
              'email': user.email,
              'birthDate': Timestamp.fromDate(_selectedDate!),
              'age': _userAge,
              'ageRestricted':
                  _userAge! < recommendedAge, // Flag for users under 16
              'gender': widget.selectedGender.toString().split('.').last,
              'goals': widget.selectedGoals.map((g) => g.title).toList(),
              'onboardingComplete': true,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(
                merge: true)); // merge: true - update if exists, create if not
      }

      // Create UserPreferences object
      final userPrefs = UserPreferences(
        goals: widget.selectedGoals,
        gender: widget.selectedGender,
        birthDate: _selectedDate,
      );

      // Navigate to welcome screen
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const WelcomeScreen(),
          ),
          (route) => false, // Remove all previous routes
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error saving data. Please try again.';
      });
      print('Error saving birth date: $e');
    }
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
              // Save what we have so far
              final prefs = await SharedPreferences.getInstance();
              await prefs.setStringList(
                  'goals', widget.selectedGoals.map((g) => g.title).toList());
              await prefs.setString('gender', widget.selectedGender.toString());
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
              // Progress indicator - Step 3 of 3
              _buildProgressIndicator(),
              SizedBox(height: 32.h),

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
                'This helps us personalize your experience',
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 40.h),

              // Question
              Text(
                'Date of Birth',
                style: GoogleFonts.inter(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 24.h),

              // Date Picker Button
              GestureDetector(
                onTap: _showDatePicker,
                child: Container(
                  padding: EdgeInsets.all(20.w),
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
                      Icon(
                        Icons.calendar_today_outlined,
                        color: AppColors.textSecondary,
                        size: 20.sp,
                      ),
                    ],
                  ),
                ),
              ),

              // Age display and validation
              if (_selectedDate != null) ...[
                SizedBox(height: 16.h),
                Container(
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
                            ? (_isAgeRecommended
                                ? Icons.check_circle
                                : Icons.warning)
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
                              ? (_isAgeRecommended
                                  ? 'Age: $_userAge years old'
                                  : 'Age: $_userAge (Some content may be restricted)')
                              : 'You must be at least $minimumAge years old',
                          style: GoogleFonts.inter(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w500,
                            color: _isAgeValid
                                ? (_isAgeRecommended
                                    ? Colors.green
                                    : Colors.orange)
                                : Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Error message
              if (_errorMessage != null) ...[
                SizedBox(height: 12.h),
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 18.sp,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const Spacer(),

              // Privacy info
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppColors.greyLight,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lock_outline,
                      color: AppColors.textSecondary,
                      size: 16.sp,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'Your information is secure and will never be shared',
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20.h),

              // Continue Button
              SizedBox(
                width: double.infinity,
                height: 56.h,
                child: ElevatedButton(
                  onPressed:
                      (_selectedDate != null && _isAgeValid && !_isLoading)
                          ? _saveAndContinue
                          : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.textPrimary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.greyLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 24.w,
                          height: 24.w,
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
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

  Widget _buildProgressIndicator() {
    return Row(
      children: List.generate(
        3,
        (index) => Expanded(
          child: Container(
            height: 4.h,
            margin: EdgeInsets.only(right: index < 2 ? 8.w : 0),
            decoration: BoxDecoration(
              color: AppColors.primaryGold,
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        height: 300.h,
        padding: EdgeInsets.only(top: 16.h),
        child: Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 16.sp,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {
                        _errorMessage = null; // Clear any previous errors
                      });
                    },
                    child: Text(
                      'Done',
                      style: GoogleFonts.inter(
                        color: AppColors.primaryGold,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Date Picker
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: _selectedDate ?? DateTime(2000, 1, 1),
                maximumDate: DateTime.now(),
                minimumDate: DateTime(1900),
                onDateTimeChanged: (DateTime newDate) {
                  setState(() {
                    _selectedDate = newDate;
                  });
                },
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
