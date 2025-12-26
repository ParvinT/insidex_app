// lib/features/quiz/widgets/expandable_quiz_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/themes/app_theme_extension.dart';
import '../../../core/responsive/context_ext.dart';
import '../services/quiz_service.dart';
import 'how_it_works_sheet.dart';
import 'quiz_gender_selector.dart';
import 'quiz_search_bar.dart';
import 'quiz_category_chips.dart';
import 'quiz_selection_footer.dart';
import 'quiz_disease_grid.dart';
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

  // Animation controllers
  late AnimationController _expandController;
  late AnimationController _staggerController;

  // Quiz state
  bool _isQuizExpanded = false;
  bool _isLoadingDiseases = false;
  bool _isLoadingCategories = false;
  List<DiseaseModel> _diseases = [];
  String _selectedGender = 'male';
  String? _selectedCategoryId;
  List<QuizCategoryModel> _categories = [];
  Locale? _previousLocale;

  // Search state
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<DiseaseModel> _filteredDiseases = [];

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

    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _pageController.dispose();
    _searchController.dispose();
    _expandController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  // Computed properties
  List<DiseaseModel> get _displayDiseases {
    return _searchQuery.isEmpty ? _diseases : _filteredDiseases;
  }

  bool get _canProceed => _selectedDiseaseIds.isNotEmpty;

  List<DiseaseModel> get _selectedDiseases {
    return _diseases
        .where((disease) => _selectedDiseaseIds.contains(disease.id))
        .toList();
  }

  // Toggle quiz expansion
  Future<void> _toggleQuiz() async {
    if (_isQuizExpanded) {
      await _staggerController.reverse();
      await _expandController.reverse();
      if (mounted) {
        setState(() {
          _isQuizExpanded = false;
          _searchController.clear();
          _searchQuery = '';
          _filteredDiseases = [];
        });
      }
    } else {
      _expandController.value = 0.0;

      setState(() {
        _isQuizExpanded = true;
        _currentPage = 0;
        _selectedDiseaseIds.clear();
        _selectedCategoryId = null;
      });

      await _expandController.forward();
      await _loadCategories();
      await _loadDiseases();
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();

    if (query == _searchQuery) return;

    setState(() {
      _searchQuery = query;
      _currentPage = 0;

      if (query.isEmpty) {
        _filteredDiseases = [];
      } else {
        final currentLang = Localizations.localeOf(context).languageCode;
        _filteredDiseases = _diseases.where((disease) {
          final name = disease.getLocalizedName(currentLang).toLowerCase();
          final englishName = disease.getLocalizedName('en').toLowerCase();
          return name.contains(query) || englishName.contains(query);
        }).toList();
      }
    });

    if (_pageController.hasClients) {
      _pageController.jumpToPage(0);
    }

    _staggerController.forward(from: 0.0);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _filteredDiseases = [];
      _currentPage = 0;
    });

    if (_pageController.hasClients) {
      _pageController.jumpToPage(0);
    }

    _staggerController.forward(from: 0.0);
  }

  Future<void> _onGenderChanged(String gender) async {
    if (_selectedGender == gender) return;

    setState(() {
      _selectedGender = gender;
      _selectedCategoryId = null;
      _currentPage = 0;
      _selectedDiseaseIds.clear();
      _categories.clear();
      _searchController.clear();
      _searchQuery = '';
      _filteredDiseases = [];
    });

    await _loadCategories();
    await _loadDiseases();
  }

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

        if (_pageController.hasClients) {
          _pageController.jumpToPage(0);
        }

        _staggerController.forward(from: 0.0);
      }
    } catch (e) {
      debugPrint('❌ Error loading diseases: $e');
      if (mounted) {
        setState(() => _isLoadingDiseases = false);
      }
    }
  }

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
        _selectedDiseaseIds.remove(diseaseId);
      } else {
        if (_selectedDiseaseIds.length < _maxSelection) {
          _selectedDiseaseIds.add(diseaseId);
        }
      }
    });
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

  @override
  Widget build(BuildContext context) {
    final isTablet = context.isTablet;

    return Column(
      children: [
        _buildQuizButton(isTablet),
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
                  angle: _expandController.value * 3.14159,
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
    if (!_isQuizExpanded && !_expandController.isAnimating) {
      return const SizedBox.shrink();
    }

    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final currentLang = Localizations.localeOf(context).languageCode;

    return AnimatedBuilder(
      animation: _expandController,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.3 + (0.7 * _expandController.value),
          alignment: Alignment.topRight,
          child: ClipRect(
            child: Align(
              alignment: Alignment.topCenter,
              heightFactor: _expandController.value,
              child: child,
            ),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(top: 12.h),
        padding: EdgeInsets.all(isTablet ? 18.w : 14.w),
        decoration: BoxDecoration(
          color: colors.backgroundCard,
          borderRadius: BorderRadius.circular(isTablet ? 20.r : 16.r),
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
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Gender selector with stagger animation
                  AnimatedBuilder(
                    animation: _staggerController,
                    builder: (context, child) {
                      final firstButtonAnim = Tween<double>(
                        begin: 0.0,
                        end: 1.0,
                      ).animate(CurvedAnimation(
                        parent: _staggerController,
                        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
                      ));

                      final secondButtonAnim = Tween<double>(
                        begin: 0.0,
                        end: 1.0,
                      ).animate(CurvedAnimation(
                        parent: _staggerController,
                        curve: const Interval(0.1, 0.4, curve: Curves.easeOut),
                      ));

                      return QuizGenderSelector(
                        selectedGender: _selectedGender,
                        maleLabel: l10n.mensTest,
                        femaleLabel: l10n.womensTest,
                        isTablet: isTablet,
                        firstButtonAnimation: firstButtonAnim,
                        secondButtonAnimation: secondButtonAnim,
                        onGenderChanged: _onGenderChanged,
                      );
                    },
                  ),

                  SizedBox(height: 12.h),

                  // Search bar
                  QuizSearchBar(
                    controller: _searchController,
                    hintText: l10n.search,
                    isTablet: isTablet,
                    showClearButton: _searchQuery.isNotEmpty,
                    onClear: _clearSearch,
                  ),

                  SizedBox(height: 8.h),

                  // Category chips
                  QuizCategoryChips(
                    categories: _categories,
                    selectedCategoryId: _selectedCategoryId,
                    currentLanguage: currentLang,
                    allCategoriesLabel: l10n.allCategories,
                    isTablet: isTablet,
                    isLoading: _isLoadingCategories,
                    onCategoryChanged: _onCategoryChanged,
                  ),

                  SizedBox(height: 8.h),

                  // Conditional: Grid or Empty state
                  if (_displayDiseases.isEmpty)
                    SizedBox(
                      height: 120.h,
                      child: Center(
                        child: Text(
                          _searchQuery.isNotEmpty
                              ? l10n.noResultsFound
                              : l10n.noDiseasesAvailable,
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    )
                  else
                    QuizDiseaseGrid(
                      diseases: _displayDiseases,
                      selectedDiseaseIds: _selectedDiseaseIds,
                      maxSelection: _maxSelection,
                      currentPage: _currentPage,
                      itemsPerPage: _itemsPerPage,
                      isTablet: isTablet,
                      pageController: _pageController,
                      staggerController: _staggerController,
                      onPageChanged: (page) {
                        setState(() => _currentPage = page);
                      },
                      onDiseaseToggle: _toggleDiseaseSelection,
                    ),

                  // Selection footer
                  QuizSelectionFooter(
                    selectionCount: _selectedDiseaseIds.length,
                    maxSelection: _maxSelection,
                    canProceed: _canProceed,
                    isTablet: isTablet,
                    selectedLabel: l10n.selected,
                    nextLabel: l10n.next,
                    onInfoPressed: _showHowItWorks,
                    onNextPressed: _proceedToResults,
                  ),
                ],
              ),
      ),
    );
  }
}
