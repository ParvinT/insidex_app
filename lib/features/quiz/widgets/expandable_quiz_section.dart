// lib/features/quiz/widgets/expandable_quiz_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/responsive/context_ext.dart';
import '../services/quiz_service.dart';
import 'disease_card.dart';
import 'how_it_works_sheet.dart';
import '../screens/quiz_results_screen.dart';
import '../../../models/disease_model.dart';
import '../../../l10n/app_localizations.dart';

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
  String _selectedGender = 'male';
  Locale? _previousLocale;

  // Pagination state
  int _currentPage = 0;
  static const int _itemsPerPage = 10;
  // Selection state
  Set<String> _selectedDiseaseIds = {};
  static const int _maxSelection = 10;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Listen to locale changes
    final currentLocale = Localizations.localeOf(context);

    // If locale changed and quiz is open, close it
    if (_previousLocale != null &&
        _previousLocale != currentLocale &&
        _isQuizExpanded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _isQuizExpanded = false;
          _diseases.clear();
          _selectedDiseaseIds.clear();
          _currentPage = 0;
        });
      });
    }

    _previousLocale = currentLocale;
  }

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

      final diseases = await _quizService.getDiseasesByGender(
        _selectedGender,
        forceRefresh: true,
      );

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

  Future<void> _onGenderChanged(String gender) async {
    if (_selectedGender == gender) return;

    setState(() {
      _selectedGender = gender;
      _isLoadingDiseases = true;
      _currentPage = 0;
      _selectedDiseaseIds.clear();
    });

    final diseases = await _quizService.getDiseasesByGender(
      gender,
      forceRefresh: true,
    );

    if (mounted) {
      setState(() {
        _diseases = diseases;
        _isLoadingDiseases = false;
      });

      // Reset page controller
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
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

  void _showHowItWorks() {
    HowItWorksSheet.show(context);
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

    final double itemHeight;
    if (context.isDesktop) {
      itemHeight = 56.h;
    } else if (isTablet) {
      itemHeight = 54.h;
    } else {
      itemHeight = 50.h;
    }

    final spacing = 10.h;
    final topBottomPadding = 16.h;

    final gridHeight =
        (rows * itemHeight) + ((rows - 1) * spacing) + topBottomPadding;

    final double maxHeight;
    if (context.isDesktop) {
      maxHeight = 350.h;
    } else if (isTablet) {
      maxHeight = 300.h;
    } else {
      final screenHeight = context.h;
      if (screenHeight <= 667) {
        maxHeight = 220.h;
      } else if (screenHeight <= 736) {
        maxHeight = 240.h;
      } else if (screenHeight <= 812) {
        maxHeight = 260.h;
      } else {
        maxHeight = 280.h;
      }
    }

    return gridHeight.clamp(100.h, maxHeight);
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
          horizontal: isTablet ? 20.w : 16.w,
          vertical: isTablet ? 16.h : 12.h,
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                AppLocalizations.of(context).startEmotionalTestFree,
                style: GoogleFonts.inter(
                  fontSize: (isTablet ? 15.sp : 13.sp).clamp(11.0, 16.0),
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(width: 8.w),
            Icon(
              Icons.keyboard_arrow_down,
              color: Colors.white,
              size: (isTablet ? 22.sp : 20.sp).clamp(18.0, 24.0),
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
              padding: EdgeInsets.all(isTablet ? 18.w : 14.w),
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
                              AppLocalizations.of(context).noDiseasesAvailable,
                              style: GoogleFonts.inter(
                                fontSize: 14.sp,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Gender filter buttons
                            Padding(
                              padding: EdgeInsets.only(bottom: 10.h),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _buildGenderButton(
                                      gender: 'male',
                                      label:
                                          AppLocalizations.of(context).mensTest,
                                      isTablet: isTablet,
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: _buildGenderButton(
                                      gender: 'female',
                                      label: AppLocalizations.of(context)
                                          .womensTest,
                                      isTablet: isTablet,
                                    ),
                                  ),
                                ],
                              ),
                            ),

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
                                  return _buildDiseaseGrid(pageIndex, isTablet);
                                },
                              ),
                            ),

                            _buildPaginationControls(isTablet),
                            SizedBox(height: 6.h),

                            _buildSelectionFooter(isTablet),
                          ],
                        ))
          : const SizedBox.shrink(),
    );
  }

  Widget _buildPaginationControls(bool isTablet) {
    if (_totalPages <= 1) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final isCompact = availableWidth < 340;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 10.w : (isTablet ? 16.w : 12.w),
            vertical: isCompact ? 8.h : (isTablet ? 12.h : 10.h),
          ),
          decoration: BoxDecoration(
            color: AppColors.greyLight.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Selection counter
              Flexible(
                flex: isCompact ? 2 : 3,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(
                          isCompact ? 5.w : (isTablet ? 8.w : 6.w)),
                      decoration: BoxDecoration(
                        color: _selectionCount > 0
                            ? Colors.black
                            : Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check,
                        size: isCompact ? 12.sp : (isTablet ? 16.sp : 14.sp),
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: isCompact ? 6.w : 10.w),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            AppLocalizations.of(context).selected,
                            style: GoogleFonts.inter(
                              fontSize:
                                  isCompact ? 9.sp : (isTablet ? 12.sp : 10.sp),
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            '$_selectionCount / $_maxSelection',
                            style: GoogleFonts.inter(
                              fontSize: isCompact
                                  ? 12.sp
                                  : (isTablet ? 16.sp : 14.sp),
                              fontWeight: FontWeight.w700,
                              color: _selectionCount > 0
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(width: isCompact ? 6.w : 8.w),

              GestureDetector(
                onTap: _showHowItWorks,
                child: Container(
                  padding: EdgeInsets.all(
                      isCompact ? 8.w : (isTablet ? 12.w : 10.w)),
                  child: Lottie.asset(
                    AppIcons.getUiAnimationPath('information.json'),
                    width: isCompact ? 28.sp : (isTablet ? 36.sp : 32.sp),
                    height: isCompact ? 28.sp : (isTablet ? 36.sp : 32.sp),
                    fit: BoxFit.cover,
                    repeat: true,
                  ),
                ),
              ),

              SizedBox(width: isCompact ? 6.w : 8.w),

              // Next button
              Flexible(
                flex: 2,
                child: GestureDetector(
                  onTap: _canProceed ? _proceedToResults : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompact ? 12.w : (isTablet ? 18.w : 14.w),
                      vertical: isCompact ? 8.h : (isTablet ? 12.h : 10.h),
                    ),
                    decoration: BoxDecoration(
                      gradient: _canProceed
                          ? LinearGradient(
                              colors: [
                                Colors.black,
                                Colors.black.withOpacity(0.85)
                              ],
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
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            AppLocalizations.of(context).next,
                            style: GoogleFonts.inter(
                              fontSize: isCompact
                                  ? 11.sp
                                  : (isTablet ? 14.sp : 12.sp),
                              fontWeight: FontWeight.w700,
                              color:
                                  _canProceed ? Colors.white : Colors.grey[500],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.clip,
                          ),
                        ),
                        SizedBox(width: isCompact ? 4.w : 6.w),
                        Icon(
                          Icons.arrow_forward,
                          size: isCompact ? 12.sp : (isTablet ? 16.sp : 14.sp),
                          color: _canProceed ? Colors.white : Colors.grey[500],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDiseaseGrid(int pageIndex, bool isTablet) {
    final startIndex = pageIndex * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, _diseases.length);

    if (startIndex >= _diseases.length) {
      return const SizedBox.shrink();
    }

    final pageDiseases = _diseases.sublist(startIndex, endIndex);

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final availableHeight = constraints.maxHeight;

        const crossAxisCount = 2;
        final horizontalPadding = 4.w;
        final crossAxisSpacing = 10.w;

        final totalHorizontalPadding = horizontalPadding * 2;
        final totalSpacing = crossAxisSpacing * (crossAxisCount - 1);
        final itemWidth =
            (availableWidth - totalHorizontalPadding - totalSpacing) /
                crossAxisCount;

        final rows = (pageDiseases.length / crossAxisCount).ceil();
        final mainAxisSpacing = 10.h;

        final verticalPadding = 8.h;
        final totalVerticalPadding = verticalPadding * 2;
        final totalVerticalSpacing = mainAxisSpacing * (rows - 1);

        final availableHeightForItems =
            availableHeight - totalVerticalPadding - totalVerticalSpacing;
        final itemHeight = availableHeightForItems / rows;

        final childAspectRatio = itemWidth / itemHeight;

        return GridView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: crossAxisSpacing,
            mainAxisSpacing: mainAxisSpacing,
            childAspectRatio: childAspectRatio,
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
      },
    );
  }

  // Gender Button Widget
  Widget _buildGenderButton({
    required String gender,
    required String label,
    required bool isTablet,
  }) {
    final isSelected = _selectedGender == gender;

    return GestureDetector(
      onTap: () => _onGenderChanged(gender),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 14.w : 12.w,
          vertical: isTablet ? 9.h : 8.h,
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
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: isTablet ? 14.sp : 13.sp,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
