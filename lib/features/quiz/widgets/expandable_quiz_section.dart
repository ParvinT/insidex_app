// lib/features/quiz/widgets/expandable_quiz_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/themes/app_theme_extension.dart';
import '../../../core/responsive/context_ext.dart';
import '../services/quiz_service.dart';
import 'disease_card.dart';
import 'how_it_works_sheet.dart';
import '../screens/quiz_results_screen.dart';
import '../../../models/disease_model.dart';
import '../../../models/quiz_category_model.dart';
import '../../../l10n/app_localizations.dart';

class ExpandableQuizSection extends StatefulWidget {
  const ExpandableQuizSection({super.key});

  @override
  State<ExpandableQuizSection> createState() => _ExpandableQuizSectionState();
}

class _ExpandableQuizSectionState extends State<ExpandableQuizSection>
    with TickerProviderStateMixin {
  final QuizService _quizService = QuizService();
  late PageController _pageController;

  // Quiz state
  bool _isInfoPressed = false;
  late AnimationController _expandController;
  late AnimationController _staggerController;
  bool _isQuizExpanded = false;
  bool _isLoadingDiseases = false;
  List<DiseaseModel> _diseases = [];
  String _selectedGender = 'male';
  String? _selectedCategoryId;
  List<QuizCategoryModel> _categories = [];
  bool _isLoadingCategories = false;
  Locale? _previousLocale;

  // Pagination state
  int _currentPage = 0;
  static const int _itemsPerPage = 10;
  // Selection state
  final Set<String> _selectedDiseaseIds = {};
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
          _selectedCategoryId = null;
          _categories.clear();
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

    _expandController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Staggered animation controller for grid items
    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _expandController.dispose();
    _staggerController.dispose();
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
    if (_isQuizExpanded) {
      // Collapse: first reverse stagger, then collapse container
      await _staggerController.reverse();
      await _expandController.reverse();
      if (mounted) {
        setState(() {
          _isQuizExpanded = false;
        });
      }
    } else {
      _expandController.value = 0.0;

      // Expand
      setState(() {
        _isQuizExpanded = true;
        _currentPage = 0;
        _selectedDiseaseIds.clear();
        _selectedCategoryId = null;
      });

      // Start container animation
      await _expandController.forward();

      // Load categories first
      await _loadCategories();

      // Load diseases
      await _loadDiseases();
    }
  }

  Future<void> _onGenderChanged(String gender) async {
    if (_selectedGender == gender) return;

    setState(() {
      _selectedGender = gender;
      _selectedCategoryId = null; // Reset category when gender changes
      _currentPage = 0;
      _selectedDiseaseIds.clear();
      _categories.clear(); // Clear categories to reload for new gender
    });

    // Reload categories for new gender
    await _loadCategories();
    await _loadDiseases();
  }

  /// Load categories from service
  Future<void> _loadCategories() async {
    setState(() => _isLoadingCategories = true);

    try {
      final currentLang = Localizations.localeOf(context).languageCode;
      final categories = await _quizService.getCategoriesByGender(
        _selectedGender,
        currentLang,
        forceRefresh: true,
      );

      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading categories: $e');
      if (mounted) {
        setState(() => _isLoadingCategories = false);
      }
    }
  }

  /// Load diseases based on selected gender and category
  Future<void> _loadDiseases() async {
    setState(() => _isLoadingDiseases = true);

    try {
      final diseases = await _quizService.getDiseasesByCategoryAndGender(
        _selectedCategoryId,
        _selectedGender,
        forceRefresh: true,
      );

      if (mounted) {
        setState(() {
          _diseases = diseases;
          _isLoadingDiseases = false;
          _currentPage = 0;
        });

        // Reset page controller
        if (_pageController.hasClients) {
          _pageController.jumpToPage(0);
        }

        // Start stagger animation
        _staggerController.forward(from: 0.0);
      }
    } catch (e) {
      debugPrint('❌ Error loading diseases: $e');
      if (mounted) {
        setState(() => _isLoadingDiseases = false);
      }
    }
  }

  /// Handle category selection
  Future<void> _onCategoryChanged(String? categoryId) async {
    if (_selectedCategoryId == categoryId) return;

    setState(() {
      _selectedCategoryId = categoryId;
      _currentPage = 0;
      _selectedDiseaseIds.clear();
    });

    await _loadDiseases();
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
          color: context.isDarkMode
              ? context.colors.textPrimary.withValues(alpha: 0.85)
              : context.colors.textPrimary,
          borderRadius: BorderRadius.circular(isTablet ? 28.r : 24.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: isTablet ? MainAxisSize.max : MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                AppLocalizations.of(context).startEmotionalTestFree,
                style: GoogleFonts.inter(
                  fontSize: (isTablet ? 15.sp : 13.sp).clamp(11.0, 16.0),
                  fontWeight: FontWeight.w700,
                  color: context.colors.textOnPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(width: 8.w),
            AnimatedBuilder(
              animation: _expandController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _expandController.value *
                      3.14159, // 180 derece (π radian)
                  child: child,
                );
              },
              child: Icon(
                Icons.keyboard_arrow_down,
                color: context.colors.textOnPrimary,
                size: (isTablet ? 22.sp : 20.sp).clamp(18.0, 24.0),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableQuizGrid(bool isTablet) {
    return (_isQuizExpanded || _expandController.isAnimating)
        ? AnimatedBuilder(
            animation: _expandController,
            builder: (context, child) {
              return Transform.scale(
                scale: 0.3 + (0.7 * _expandController.value), // 0.3'ten 1.0'a
                alignment: Alignment.topRight, // Butonun altından başla
                child: ClipRect(
                  child: Align(
                    alignment: Alignment.topCenter,
                    heightFactor: _expandController.value,
                    child: child,
                  ),
                ),
              );
            },
            child: Builder(
              builder: (context) {
                final colors = context.colors;
                return Container(
                    margin: EdgeInsets.only(top: 12.h),
                    padding: EdgeInsets.all(isTablet ? 18.w : 14.w),
                    decoration: BoxDecoration(
                      color: colors.backgroundCard,
                      borderRadius:
                          BorderRadius.circular(isTablet ? 20.r : 16.r),
                      border: Border.all(
                        color: colors.border.withValues(alpha: 0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colors.textPrimary.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: (_isLoadingDiseases || _isLoadingCategories)
                        ? SizedBox(
                            height: 200.h,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: colors.textPrimary,
                              ),
                            ),
                          )
                        : _diseases.isEmpty
                            ? SizedBox(
                                height: 200.h,
                                child: Center(
                                  child: Text(
                                    AppLocalizations.of(context)
                                        .noDiseasesAvailable,
                                    style: GoogleFonts.inter(
                                      fontSize: 14.sp,
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                ),
                              )
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Gender filter buttons with stagger animation
                                  AnimatedBuilder(
                                    animation: _staggerController,
                                    builder: (context, child) {
                                      // First button appears at 0.0-0.3
                                      final firstButtonAnim = Tween<double>(
                                        begin: 0.0,
                                        end: 1.0,
                                      ).animate(CurvedAnimation(
                                        parent: _staggerController,
                                        curve: const Interval(0.0, 0.3,
                                            curve: Curves.easeOut),
                                      ));

                                      // Second button appears at 0.1-0.4
                                      final secondButtonAnim = Tween<double>(
                                        begin: 0.0,
                                        end: 1.0,
                                      ).animate(CurvedAnimation(
                                        parent: _staggerController,
                                        curve: const Interval(0.1, 0.4,
                                            curve: Curves.easeOut),
                                      ));

                                      return Padding(
                                        padding: EdgeInsets.only(bottom: 10.h),
                                        child: IntrinsicHeight(
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              Expanded(
                                                child: Transform.translate(
                                                  offset: Offset(
                                                      -20 *
                                                          (1 -
                                                              firstButtonAnim
                                                                  .value),
                                                      0),
                                                  child: Opacity(
                                                    opacity: firstButtonAnim
                                                        .value
                                                        .clamp(0.0, 1.0),
                                                    child: _buildGenderButton(
                                                      gender: 'male',
                                                      label:
                                                          AppLocalizations.of(
                                                                  context)
                                                              .mensTest,
                                                      isTablet: isTablet,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 12.w),
                                              Expanded(
                                                child: Transform.translate(
                                                  offset: Offset(
                                                      20 *
                                                          (1 -
                                                              secondButtonAnim
                                                                  .value),
                                                      0),
                                                  child: Opacity(
                                                    opacity: secondButtonAnim
                                                        .value
                                                        .clamp(0.0, 1.0),
                                                    child: _buildGenderButton(
                                                      gender: 'female',
                                                      label:
                                                          AppLocalizations.of(
                                                                  context)
                                                              .womensTest,
                                                      isTablet: isTablet,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  // Category selector
                                  SizedBox(height: 12.h),
                                  _buildCategorySelector(isTablet),
                                  SizedBox(height: 8.h),

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
                                  SizedBox(height: 6.h),

                                  _buildSelectionFooter(isTablet),
                                ],
                              ));
              },
            ))
        : const SizedBox.shrink();
  }

  Widget _buildPaginationControls(bool isTablet) {
    if (_totalPages <= 1) return const SizedBox.shrink();
    final colors = context.colors;

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
                        color: colors.textSecondary,
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
                    ? colors.textPrimary
                    : colors.border.withValues(alpha: 0.5),
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
        final colors = context.colors;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 10.w : (isTablet ? 16.w : 12.w),
            vertical: isCompact ? 8.h : (isTablet ? 12.h : 10.h),
          ),
          decoration: BoxDecoration(
            color: colors.greyLight.withValues(alpha: 0.5),
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
                            ? colors.textPrimary
                            : colors.greyMedium,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check,
                        size: isCompact ? 12.sp : (isTablet ? 16.sp : 14.sp),
                        color: colors.textOnPrimary,
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
                              color: colors.textSecondary,
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
                                  ? colors.textPrimary
                                  : colors.textSecondary,
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
                onTapDown: (_) => setState(() => _isInfoPressed = true),
                onTapUp: (_) {
                  setState(() => _isInfoPressed = false);
                  _showHowItWorks();
                },
                onTapCancel: () => setState(() => _isInfoPressed = false),
                child: AnimatedScale(
                  scale: _isInfoPressed ? 0.85 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeInOut,
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
                      color: _canProceed
                          ? (context.isDarkMode
                              ? colors.textPrimary.withValues(alpha: 0.85)
                              : colors.textPrimary)
                          : colors.greyMedium,
                      borderRadius: BorderRadius.circular(24.r),
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
                              color: _canProceed
                                  ? colors.textOnPrimary
                                  : colors.textLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.clip,
                          ),
                        ),
                        SizedBox(width: isCompact ? 4.w : 6.w),
                        Icon(
                          Icons.arrow_forward,
                          size: isCompact ? 12.sp : (isTablet ? 16.sp : 14.sp),
                          color: _canProceed
                              ? colors.textOnPrimary
                              : colors.textLight,
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

            // Staggered animation for each card
            final startInterval = (index * 0.1).clamp(0.0, 0.6);
            final endInterval = (startInterval + 0.4).clamp(0.0, 1.0);

            final itemAnimation = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: _staggerController,
              curve: Interval(
                startInterval,
                endInterval,
                curve: Curves.easeOutBack,
              ),
            ));

            return AnimatedBuilder(
              animation: itemAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: 0.5 + (0.5 * itemAnimation.value),
                  child: Opacity(
                    opacity: itemAnimation.value.clamp(0.0, 1.0),
                    child: child,
                  ),
                );
              },
              child: DiseaseCard(
                disease: disease,
                isSelected: isSelected,
                isDisabled: isDisabled,
                onTap: () => _toggleDiseaseSelection(disease.id),
              ),
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
    final colors = context.colors;
    final isSelected = _selectedGender == gender;

    return GestureDetector(
      onTap: () => _onGenderChanged(gender),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 14.w : 12.w,
          vertical: isTablet ? 9.h : 8.h,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? (context.isDarkMode
                  ? colors.textPrimary.withValues(alpha: 0.85)
                  : colors.textPrimary)
              : colors.backgroundCard,
          borderRadius: BorderRadius.circular(100.r),
          border: Border.all(
            color: isSelected
                ? (context.isDarkMode
                    ? colors.textPrimary.withValues(alpha: 0.85)
                    : colors.textPrimary)
                : colors.border,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: isTablet ? 14.sp : 13.sp,
              fontWeight: FontWeight.w600,
              color: isSelected ? colors.textOnPrimary : colors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  /// Build category selector chips
  Widget _buildCategorySelector(bool isTablet) {
    final colors = context.colors;
    final currentLang = Localizations.localeOf(context).languageCode;

    if (_isLoadingCategories) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: SizedBox(
          height: 36.h,
          child: Center(
            child: SizedBox(
              width: 20.w,
              height: 20.w,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colors.textPrimary,
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: isTablet ? 42.h : 36.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        itemCount: _categories.length + 1, // +1 for "All" option
        itemBuilder: (context, index) {
          if (index == 0) {
            // "All Categories" chip
            return _buildCategoryChip(
              id: null,
              name: AppLocalizations.of(context).allCategories,
              iconName: 'category',
              isSelected: _selectedCategoryId == null,
              isTablet: isTablet,
            );
          }

          final category = _categories[index - 1];
          return _buildCategoryChip(
            id: category.id,
            name: category.getName(currentLang),
            iconName: category.iconName,
            isSelected: _selectedCategoryId == category.id,
            isTablet: isTablet,
          );
        },
      ),
    );
  }

  Widget _buildCategoryChip({
    required String? id,
    required String name,
    required String iconName,
    required bool isSelected,
    required bool isTablet,
  }) {
    final colors = context.colors;

    return GestureDetector(
      onTap: () => _onCategoryChanged(id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.only(right: 8.w),
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 14.w : 12.w,
          vertical: isTablet ? 8.h : 6.h,
        ),
        decoration: BoxDecoration(
          color: isSelected ? colors.textPrimary : colors.backgroundElevated,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected
                ? colors.textPrimary
                : colors.border.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getCategoryIcon(iconName),
              size: isTablet ? 16.sp : 14.sp,
              color: isSelected ? colors.textOnPrimary : colors.textSecondary,
            ),
            SizedBox(width: 6.w),
            Text(
              name,
              style: GoogleFonts.inter(
                fontSize: isTablet ? 13.sp : 12.sp,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? colors.textOnPrimary : colors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String iconName) {
    const iconMap = {
      'face': Icons.face,
      'person': Icons.person,
      'no_drinks': Icons.no_drinks,
      'child_care': Icons.child_care,
      'psychology': Icons.psychology,
      'psychology_alt': Icons.psychology_alt,
      'restaurant': Icons.restaurant,
      'favorite': Icons.favorite,
      'accessibility_new': Icons.accessibility_new,
      'air': Icons.air,
      'visibility': Icons.visibility,
      'mood': Icons.mood,
      'water_drop': Icons.water_drop,
      'medical_services': Icons.medical_services,
      'health_and_safety': Icons.health_and_safety,
      'fitness_center': Icons.fitness_center,
      'category': Icons.category,
      'healing': Icons.healing,
      'local_hospital': Icons.local_hospital,
      'monitor_heart': Icons.monitor_heart,
      'medication': Icons.medication,
      'vaccines': Icons.vaccines,
      'bloodtype': Icons.bloodtype,
      'sick': Icons.sick,
      'elderly': Icons.elderly,
      'pregnant_woman': Icons.pregnant_woman,
      'male': Icons.male,
      'female': Icons.female,
    };

    return iconMap[iconName] ?? Icons.category;
  }
}
