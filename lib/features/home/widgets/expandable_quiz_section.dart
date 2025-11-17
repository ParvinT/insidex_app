// lib/screens/home/widgets/expandable_quiz_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/responsive/context_ext.dart';
import '../../../features/quiz/services/quiz_service.dart';
import '../../../features/quiz/widgets/disease_card.dart';
import '../../../features/quiz/screens/quiz_results_screen.dart';
import '../../../models/disease_model.dart';

class ExpandableQuizSection extends StatefulWidget {
  const ExpandableQuizSection({super.key});

  @override
  State<ExpandableQuizSection> createState() => _ExpandableQuizSectionState();
}

class _ExpandableQuizSectionState extends State<ExpandableQuizSection> {
  final QuizService _quizService = QuizService();
  late PageController _pageController;

  // Quiz state
  bool _isQuizExpanded = false;
  bool _isLoadingDiseases = false;
  List<DiseaseModel> _diseases = [];

  // Pagination state
  int _currentPage = 0;
  static const int _itemsPerPage = 10;
  // Selection state
  Set<String> _selectedDiseaseIds = {};
  static const int _maxSelection = 10;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Total pages
  int get _totalPages {
    if (_diseases.isEmpty) return 0;
    return (_diseases.length / _itemsPerPage).ceil();
  }

  // Selection getters
  bool get _canProceed => _selectedDiseaseIds.isNotEmpty;
  bool get _isMaxSelected => _selectedDiseaseIds.length >= _maxSelection;
  int get _selectionCount => _selectedDiseaseIds.length;

// Selected diseases
  List<DiseaseModel> get _selectedDiseases {
    return _diseases
        .where((disease) => _selectedDiseaseIds.contains(disease.id))
        .toList();
  }

  // Toggle quiz expansion
  Future<void> _toggleQuiz() async {
    if (!_isQuizExpanded && _diseases.isEmpty) {
      // Load diseases when expanding for the first time
      setState(() {
        _isQuizExpanded = true;
        _isLoadingDiseases = true;
        _currentPage = 0;
        _selectedDiseaseIds.clear();
      });

      final diseases = await _quizService.getAllDiseases();

      if (mounted) {
        setState(() {
          _diseases = diseases;
          _isLoadingDiseases = false;
        });
      }
    } else {
      // Just toggle
      setState(() {
        _isQuizExpanded = !_isQuizExpanded;
        if (_isQuizExpanded) {
          _currentPage = 0;
          _selectedDiseaseIds.clear();
        }
      });
    }
  }

  void _toggleDiseaseSelection(String diseaseId) {
    setState(() {
      if (_selectedDiseaseIds.contains(diseaseId)) {
        // Deselect
        _selectedDiseaseIds.remove(diseaseId);
      } else {
        // Select (if not max)
        if (!_isMaxSelected) {
          _selectedDiseaseIds.add(diseaseId);
        }
      }
    });
  }

  bool _isDiseaseSelected(String diseaseId) {
    return _selectedDiseaseIds.contains(diseaseId);
  }

  void _proceedToResults() {
    if (!_canProceed) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizResultsScreen(
          selectedDiseases: _selectedDiseases,
        ),
      ),
    );
  }

  void _goToPage(int page) {
    if (page >= 0 && page < _totalPages) {
      _pageController.animateToPage(
        page,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  double _calculateGridHeight(bool isTablet) {
    if (_diseases.isEmpty) return 200.h;

    // Calculate items on current page (max 10)
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, _diseases.length);
    final itemCount = endIndex - startIndex;

    if (itemCount == 0) return 200.h;

    // 2 columns -> max 5 rows
    final rows = (itemCount / 2).ceil();

    // Height per row
    final itemHeight = isTablet ? 58.h : 52.h;
    final spacing = 10.h;
    final topBottomPadding = 16.h;

    final gridHeight =
        (rows * itemHeight) + ((rows - 1) * spacing) + topBottomPadding;

    // Max 5 rows (10 items) = ~300h
    return gridHeight.clamp(100.h, 320.h);
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = context.isTablet;

    return Column(
      children: [
        // Quiz button
        _buildQuizButton(isTablet),

        // Expandable quiz grid
        _buildExpandableQuizGrid(isTablet),
      ],
    );
  }

  Widget _buildQuizButton(bool isTablet) {
    return GestureDetector(
      onTap: _toggleQuiz,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 20.w : 18.w,
          vertical: isTablet ? 16.h : 14.h,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.black,
              Colors.black.withOpacity(0.85),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(isTablet ? 28.r : 24.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Start My Emotional Test — Free',
              style: GoogleFonts.inter(
                fontSize: isTablet ? 16.sp : 15.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 8.w),
            AnimatedRotation(
              duration: const Duration(milliseconds: 300),
              turns: _isQuizExpanded ? 0.5 : 0,
              child: Icon(
                Icons.keyboard_arrow_down,
                color: Colors.white,
                size: isTablet ? 24.sp : 22.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableQuizGrid(bool isTablet) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      child: _isQuizExpanded
          ? Container(
              margin: EdgeInsets.only(top: 12.h),
              padding: EdgeInsets.all(isTablet ? 20.w : 16.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(isTablet ? 20.r : 16.r),
                border: Border.all(
                  color: AppColors.greyBorder.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: _isLoadingDiseases
                  ? SizedBox(
                      height: 200.h,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryGold,
                        ),
                      ),
                    )
                  : _diseases.isEmpty
                      ? SizedBox(
                          height: 200.h,
                          child: Center(
                            child: Text(
                              'No diseases available',
                              style: GoogleFonts.inter(
                                fontSize: 14.sp,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        )
                      : ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: 500.h,
                          ),
                          child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Horizontal PageView for disease grid
                                  SizedBox(
                                    height: _calculateGridHeight(isTablet),
                                    child: PageView.builder(
                                      controller: _pageController,
                                      onPageChanged: (page) {
                                        setState(() => _currentPage = page);
                                      },
                                      itemCount: _totalPages,
                                      itemBuilder: (context, pageIndex) {
                                        return _buildDiseaseGrid(
                                            pageIndex, isTablet);
                                      },
                                    ),
                                  ),

                                  _buildPaginationControls(isTablet),
                                  SizedBox(height: 12.h),

                                  _buildSelectionFooter(isTablet),
                                ],
                              ))))
          : const SizedBox.shrink(),
    );
  }

  Widget _buildPaginationControls(bool isTablet) {
    if (_totalPages <= 1) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_totalPages, (index) {
          // Show first 2, last 2, and current page context
          if (_totalPages > 7) {
            if (index > 1 && index < _totalPages - 2) {
              if (index < _currentPage - 1 || index > _currentPage + 1) {
                // Show ellipsis
                if (index == 2 || index == _totalPages - 3) {
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2.w),
                    child: Text(
                      '...',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }
            }
          }

          return GestureDetector(
            onTap: () => _goToPage(index),
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 4.w),
              width: isTablet ? 10.w : 8.w,
              height: isTablet ? 10.w : 8.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentPage == index
                    ? Colors.black
                    : AppColors.greyBorder.withOpacity(0.5),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSelectionFooter(bool isTablet) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 20.w : 16.w,
        vertical: isTablet ? 16.h : 14.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.greyLight.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Selection counter
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isTablet ? 8.w : 6.w),
                decoration: BoxDecoration(
                  color: _selectionCount > 0 ? Colors.black : Colors.grey[300],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  size: isTablet ? 16.sp : 14.sp,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 10.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selected Conditions',
                    style: GoogleFonts.inter(
                      fontSize: isTablet ? 12.sp : 11.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    '$_selectionCount / $_maxSelection',
                    style: GoogleFonts.inter(
                      fontSize: isTablet ? 16.sp : 15.sp,
                      fontWeight: FontWeight.w700,
                      color: _selectionCount > 0
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Next button
          GestureDetector(
            onTap: _canProceed ? _proceedToResults : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 24.w : 20.w,
                vertical: isTablet ? 14.h : 12.h,
              ),
              decoration: BoxDecoration(
                gradient: _canProceed
                    ? LinearGradient(
                        colors: [Colors.black, Colors.black.withOpacity(0.85)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: _canProceed ? null : Colors.grey[300],
                borderRadius: BorderRadius.circular(24.r),
                boxShadow: _canProceed
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Next',
                    style: GoogleFonts.inter(
                      fontSize: isTablet ? 15.sp : 14.sp,
                      fontWeight: FontWeight.w700,
                      color: _canProceed ? Colors.white : Colors.grey[500],
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Icon(
                    Icons.arrow_forward,
                    size: isTablet ? 18.sp : 16.sp,
                    color: _canProceed ? Colors.white : Colors.grey[500],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiseaseGrid(int pageIndex, bool isTablet) {
    // Calculate diseases for this page
    final startIndex = pageIndex * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, _diseases.length);

    if (startIndex >= _diseases.length) {
      return const SizedBox.shrink();
    }

    final pageDiseases = _diseases.sublist(startIndex, endIndex);

    return GridView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 8.h),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10.w,
        mainAxisSpacing: 10.h,
        childAspectRatio: isTablet ? 2.6 : 2.9,
      ),
      itemCount: pageDiseases.length,
      itemBuilder: (context, index) {
        final disease = pageDiseases[index];
        final isSelected = _isDiseaseSelected(disease.id);
        final isDisabled = _isMaxSelected && !isSelected;

        return DiseaseCard(
          disease: disease,
          isSelected: isSelected,
          isDisabled: isDisabled,
          onTap: () => _toggleDiseaseSelection(disease.id),
        );
      },
    );
  }
}
