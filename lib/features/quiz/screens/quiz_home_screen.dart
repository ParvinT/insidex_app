// lib/features/quiz/screens/quiz_home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/responsive/context_ext.dart';
import '../../../models/disease_model.dart';
import '../../../l10n/app_localizations.dart';
import '../services/quiz_service.dart';
import '../widgets/disease_card.dart';
import 'disease_detail_screen.dart';

class QuizHomeScreen extends StatefulWidget {
  const QuizHomeScreen({super.key});

  @override
  State<QuizHomeScreen> createState() => _QuizHomeScreenState();
}

class _QuizHomeScreenState extends State<QuizHomeScreen> {
  final QuizService _quizService = QuizService();

  List<DiseaseModel> _diseases = [];
  Map<String, int> _categoryCounts = {};
  bool _isLoading = true;
  String _selectedGender = 'all';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final diseases = await _quizService.getDiseasesByGender(
        _selectedGender,
        forceRefresh: true,
      );

      final counts = await _quizService.getDiseaseCounts();

      if (mounted) {
        setState(() {
          _diseases = diseases;
          _categoryCounts = counts;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading quiz data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _onGenderChanged(String gender) async {
    if (_selectedGender == gender) return;

    setState(() {
      _selectedGender = gender;
      _isLoading = true;
    });

    final diseases = await _quizService.getDiseasesByGender(gender);

    if (mounted) {
      setState(() {
        _diseases = diseases;
        _isLoading = false;
      });
    }
  }

  Future<void> _onSearch(String query) async {
    if (query.trim().isEmpty) {
      _loadData();
      return;
    }

    setState(() => _isLoading = true);

    final results = await _quizService.searchDiseases(query);

    if (mounted) {
      setState(() {
        _diseases = results;
        _isLoading = false;
      });
    }
  }

  void _navigateToDetail(DiseaseModel disease) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiseaseDetailScreen(disease: disease),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Responsive values
    final isTablet = context.isTablet;
    final isDesktop = context.isDesktop;

    final double horizontalPadding =
        isDesktop ? 32.w : (isTablet ? 24.w : 20.w);
    final double titleSize =
        isTablet ? 28.sp.clamp(26.0, 30.0) : 24.sp.clamp(22.0, 26.0);
    final double subtitleSize =
        isTablet ? 15.sp.clamp(14.0, 16.0) : 14.sp.clamp(13.0, 15.0);

    // Grid configuration
    final int crossAxisCount = isDesktop ? 4 : (isTablet ? 3 : 2);
    final double childAspectRatio = isDesktop ? 0.85 : (isTablet ? 0.9 : 0.95);

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Health Quiz',
          style: GoogleFonts.inter(
            fontSize: isTablet ? 22.sp : 20.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Section
          Container(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 8.h),

                // Title
                Text(
                  'What are you experiencing?',
                  style: GoogleFonts.inter(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),

                SizedBox(height: 8.h),

                // Subtitle
                Text(
                  'Select a condition to get personalized healing recommendations',
                  style: GoogleFonts.inter(
                    fontSize: subtitleSize,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                  ),
                ),

                SizedBox(height: 20.h),

                // Search bar
                _buildSearchBar(isTablet),

                SizedBox(height: 20.h),

                // Gender
                _buildGenderFilters(isTablet),

                SizedBox(height: 20.h),
              ],
            ),
          ),

          // Disease Grid
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _diseases.isEmpty
                    ? _buildEmptyState(isTablet)
                    : _buildDiseaseGrid(
                        crossAxisCount, childAspectRatio, horizontalPadding),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isTablet) {
    return TextField(
      controller: _searchController,
      onChanged: _onSearch,
      decoration: InputDecoration(
        hintText: 'Search diseases...',
        hintStyle: GoogleFonts.inter(
          fontSize: isTablet ? 15.sp : 14.sp,
          color: AppColors.textSecondary,
        ),
        prefixIcon: Icon(
          Icons.search,
          color: AppColors.textSecondary,
          size: isTablet ? 24.sp : 22.sp,
        ),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                onPressed: () {
                  _searchController.clear();
                  _loadData();
                },
              )
            : null,
        filled: true,
        fillColor: AppColors.greyLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16.w,
          vertical: isTablet ? 16.h : 14.h,
        ),
      ),
    );
  }

  Widget _buildGenderFilters(bool isTablet) {
    return Column(
      children: [
        // Big CTA Button
        _buildBigCTAButton(isTablet),

        SizedBox(height: 16.h),

        // Gender Test Buttons
        Row(
          children: [
            Expanded(
              child: _buildGenderTestButton(
                gender: 'male',
                label: "Take the Men's Test",
                isTablet: isTablet,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildGenderTestButton(
                gender: 'female',
                label: "Take the Women's Test",
                isTablet: isTablet,
              ),
            ),
          ],
        ),

        SizedBox(height: 12.h),

        // Info Text
        Text(
          'In 3 minutes you\'ll get:\na personalized map of deep-rooted causes\na 7-day audio plan (morning/day/night)\na 15-second preview tailored to you',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: isTablet ? 12.sp : 11.sp,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),

        SizedBox(height: 8.h),

        // Disclaimer
        Text(
          'Private & free. Not a medical service. Works best with daily listening.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: isTablet ? 11.sp : 10.sp,
            color: AppColors.textSecondary.withOpacity(0.7),
            height: 1.3,
          ),
        ),
      ],
    );
  }

  // Big CTA Button (Start My Emotional Test — Free)
  Widget _buildBigCTAButton(bool isTablet) {
    return GestureDetector(
      onTap: () {
        // Show modal to select gender or just scroll down
        _showGenderSelectionHint();
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 32.w : 28.w,
          vertical: isTablet ? 18.h : 16.h,
        ),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(100.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          'Start My Emotional Test — Free',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: isTablet ? 18.sp : 16.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

// Gender Test Button
  Widget _buildGenderTestButton({
    required String gender,
    required String label,
    required bool isTablet,
  }) {
    final isSelected = _selectedGender == gender;
    final count = _categoryCounts[gender] ?? 0;
    final totalCount = _categoryCounts['all'] ?? 1;
    final percentage =
        totalCount > 0 ? ((count / totalCount) * 100).round() : 0;

    return GestureDetector(
      onTap: () => _onGenderChanged(gender),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 20.w : 16.w,
          vertical: isTablet ? 16.h : 14.h,
        ),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(100.r),
          border: Border.all(
            color: isSelected ? Colors.black : AppColors.greyBorder,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            // Label
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: isTablet ? 15.sp : 14.sp,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textPrimary,
                height: 1.2,
              ),
            ),

            if (isSelected) ...[
              SizedBox(height: 8.h),

              // Percentage Badge
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 4.h,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  '$percentage%',
                  style: GoogleFonts.inter(
                    fontSize: isTablet ? 13.sp : 12.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

// Gender Selection Hint (optional)
  void _showGenderSelectionHint() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please select a test below to get started'),
        duration: Duration(seconds: 2),
        backgroundColor: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildDiseaseGrid(
      int crossAxisCount, double childAspectRatio, double horizontalPadding) {
    return GridView.builder(
      padding:
          EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8.h),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16.w,
        mainAxisSpacing: 16.h,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: _diseases.length,
      itemBuilder: (context, index) {
        final disease = _diseases[index];
        return DiseaseCard(
          disease: disease,
          onTap: () => _navigateToDetail(disease),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/lottie/loading.json',
            width: 120.w,
            height: 120.w,
          ),
          SizedBox(height: 16.h),
          Text(
            'Loading diseases...',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isTablet) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: isTablet ? 80.sp : 64.sp,
            color: AppColors.greyMedium,
          ),
          SizedBox(height: 16.h),
          Text(
            'No diseases found',
            style: GoogleFonts.inter(
              fontSize: isTablet ? 18.sp : 16.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Try adjusting your filters or search',
            style: GoogleFonts.inter(
              fontSize: isTablet ? 14.sp : 13.sp,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
