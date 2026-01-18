// lib/features/search/search_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../../core/themes/app_theme_extension.dart';
import '../../core/responsive/context_ext.dart';
import '../../core/constants/app_icons.dart';
import '../../l10n/app_localizations.dart';
import '../library/sessions_list_screen.dart';
import '../player/audio_player_screen.dart';
import '../../shared/widgets/session_card.dart';
import '../../services/session_filter_service.dart';
import '../quiz/screens/quiz_results_screen.dart';
import 'search_service.dart';
import 'search_history_service.dart';
import 'widgets/search_history_view.dart';
import 'quiz_search_service.dart';
import 'widgets/quiz_category_search_card.dart';
import 'widgets/disease_search_card.dart';
import 'widgets/quiz_category_diseases_sheet.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final SearchService _searchService = SearchService();
  final QuizSearchService _quizSearchService = QuizSearchService();
  final FocusNode _focusNode = FocusNode();
  final SearchHistoryService _historyService = SearchHistoryService();
  late TabController _tabController;

  List<String> _recentSearches = [];
  bool _isLoadingHistory = true;

  bool _isSearching = false;
  String _selectedGenderFilter = 'all';
  Map<String, dynamic> _searchResults = {
    'categories': <Map<String, dynamic>>[],
    'sessions': <Map<String, dynamic>>[],
  };
  Map<String, dynamic> _quizSearchResults = {
    'quizCategories': <QuizCategorySearchResult>[],
    'diseases': <DiseaseSearchResult>[],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadSearchHistory();
    _loadUserGender();

    // Auto-focus when opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  Future<void> _loadUserGender() async {
    final gender = await SessionFilterService.getUserGender();
    if (mounted && gender != null) {
      setState(() {
        _selectedGenderFilter = gender;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Load search history
  Future<void> _loadSearchHistory() async {
    setState(() => _isLoadingHistory = true);
    final history = await _historyService.getRecentSearches(limit: 10);
    setState(() {
      _recentSearches = history;
      _isLoadingHistory = false;
    });
  }

  /// Handle history item tap
  void _onHistoryItemTap(String query) {
    _searchController.text = query;
    _performSearch(query);
    _historyService.saveSearchQuery(query);
    _loadSearchHistory();
  }

  /// Remove history item
  Future<void> _removeHistoryItem(String query) async {
    await _historyService.removeSearchQuery(query);
    await _loadSearchHistory();
  }

  /// Clear all history
  Future<void> _clearAllHistory() async {
    final l10n = AppLocalizations.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          l10n.clearSearchHistory,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Text(
          l10n.clearSearchHistoryConfirmation,
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              l10n.cancel,
              style: GoogleFonts.inter(color: context.colors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n.clear,
              style: GoogleFonts.inter(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _historyService.clearHistory();
      await _loadSearchHistory();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.searchHistoryCleared),
            backgroundColor: context.colors.textPrimary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = {
          'categories': <Map<String, dynamic>>[],
          'sessions': <Map<String, dynamic>>[],
        };
        _quizSearchResults = {
          'quizCategories': <QuizCategorySearchResult>[],
          'diseases': <DiseaseSearchResult>[],
        };
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    // Search in parallel
    final results = await Future.wait([
      _searchService.search(query),
      _quizSearchService.searchAll(query),
    ]);

    // 🆕 Apply gender filter to sessions
    final searchResults = results[0];
    final sessions = searchResults['sessions'] as List<Map<String, dynamic>>;
    final filteredSessions = SessionFilterService.filterByGender(
      sessions,
      _selectedGenderFilter,
    );

    setState(() {
      _searchResults = {
        'categories': searchResults['categories'],
        'sessions': filteredSessions,
      };
      _quizSearchResults = results[1];
      _isSearching = false;
    });
  }

  int get _totalResults =>
      _searchService.getTotalResultCount(_searchResults) +
      _quizSearchService.getTotalQuizResultCount(_quizSearchResults);
  int get _categoryCount => (_searchResults['categories'] as List).length;
  int get _sessionCount => (_searchResults['sessions'] as List).length;
  int get _quizCategoryCount => // 🆕
      (_quizSearchResults['quizCategories'] as List<QuizCategorySearchResult>)
          .length;
  int get _diseaseCount => // 🆕
      (_quizSearchResults['diseases'] as List<DiseaseSearchResult>).length;
  int get _quizTotalCount => _quizCategoryCount + _diseaseCount;

  @override
  Widget build(BuildContext context) {
    final isTablet = context.isTablet;
    final l10n = AppLocalizations.of(context);

    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
          child: Column(
        children: [
          // Search TextField
          _buildSearchTextField(isTablet, l10n),

          // Result count
          if (_searchController.text.isNotEmpty && !_isSearching)
            _buildResultCount(isTablet, l10n),

          // Tabs
          if (_searchController.text.isNotEmpty && !_isSearching)
            _buildTabs(isTablet, l10n),

          // Content
          Expanded(
            child: _isSearching
                ? _buildLoadingState()
                : _searchController.text.isEmpty
                    ? SearchHistoryView(
                        searches: _recentSearches,
                        onSearchTap: _onHistoryItemTap,
                        onClearAll: _clearAllHistory,
                        onRemove: _removeHistoryItem,
                        isLoading: _isLoadingHistory,
                      )
                    : _buildSearchResults(isTablet, l10n),
          ),
        ],
      )),
    );
  }

  Widget _buildSearchTextField(bool isTablet, AppLocalizations l10n) {
    final colors = context.colors;
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isTablet ? 24.w : 20.w,
        vertical: isTablet ? 14.h : 12.h,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 18.w : 16.w,
      ),
      decoration: BoxDecoration(
        color: colors.greyLight,
        borderRadius: BorderRadius.circular(isTablet ? 14.r : 12.r),
        border: Border.all(
          color: colors.border.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            color: colors.textSecondary,
            size: isTablet ? 22.sp : 20.sp,
          ),
          SizedBox(width: isTablet ? 14.w : 12.w),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              style: GoogleFonts.inter(
                fontSize: isTablet ? 16.sp : 15.sp,
                color: colors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: l10n.searchSessions,
                hintStyle: GoogleFonts.inter(
                  fontSize: isTablet ? 16.sp : 15.sp,
                  color: colors.textSecondary,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (value) {
                _performSearch(value);
              },
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: Icon(
                Icons.clear,
                color: colors.textSecondary,
                size: isTablet ? 22.sp : 20.sp,
              ),
              onPressed: () {
                _searchController.clear();
                _performSearch('');
              },
            )
          else
            IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: colors.textSecondary,
                size: isTablet ? 22.sp : 20.sp,
              ),
              onPressed: () => Navigator.pop(context),
            ),
        ],
      ),
    );
  }

  Widget _buildResultCount(bool isTablet, AppLocalizations l10n) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 24.w : 20.w,
        vertical: isTablet ? 10.h : 8.h,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          l10n.foundResults(_totalResults.toString()),
          style: GoogleFonts.inter(
            fontSize: isTablet ? 15.sp : 14.sp,
            color: context.colors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildTabs(bool isTablet, AppLocalizations l10n) {
    final colors = context.colors;
    return TabBar(
      controller: _tabController,
      labelColor: colors.textPrimary,
      unselectedLabelColor: colors.textSecondary,
      indicatorColor: colors.textPrimary,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 24.w : 20.w),
      labelPadding: EdgeInsets.symmetric(horizontal: isTablet ? 16.w : 12.w),
      labelStyle: GoogleFonts.inter(
        fontSize: (isTablet ? 14.sp : 13.sp).clamp(11.0, 16.0),
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: GoogleFonts.inter(
        fontSize: (isTablet ? 14.sp : 13.sp).clamp(11.0, 16.0),
        fontWeight: FontWeight.w500,
      ),
      tabs: [
        Tab(text: '${l10n.allResults} ($_totalResults)'),
        Tab(text: '${l10n.searchCategories} ($_categoryCount)'),
        Tab(text: '${l10n.searchSessionsTab} ($_sessionCount)'),
        Tab(text: '${l10n.quizTab} ($_quizTotalCount)'),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: CircularProgressIndicator(
        color: context.colors.textPrimary,
      ),
    );
  }

  Widget _buildSearchResults(bool isTablet, AppLocalizations l10n) {
    if (_totalResults == 0) {
      return _buildNoResults(isTablet, l10n);
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildAllResults(isTablet),
        _buildCategoriesTab(isTablet),
        _buildSessionsTab(isTablet),
        _buildQuizTab(isTablet),
      ],
    );
  }

  Widget _buildNoResults(bool isTablet, AppLocalizations l10n) {
    final colors = context.colors;
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: isTablet ? 80.sp : 64.sp,
              color: colors.greyMedium,
            ),
            SizedBox(height: isTablet ? 24.h : 16.h),
            Text(
              l10n.noResultsFound,
              style: GoogleFonts.inter(
                fontSize: isTablet ? 20.sp : 18.sp,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
            SizedBox(height: isTablet ? 10.h : 8.h),
            Text(
              l10n.tryDifferentKeywords,
              style: GoogleFonts.inter(
                fontSize: isTablet ? 15.sp : 14.sp,
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllResults(bool isTablet) {
    return ListView(
      padding: EdgeInsets.all(isTablet ? 24.w : 20.w),
      children: [
        if (_categoryCount > 0) ...[
          _buildSectionHeader(
              isTablet, AppLocalizations.of(context).searchCategories),
          SizedBox(height: isTablet ? 14.h : 12.h),
          ..._buildCategoryItems(isTablet),
          SizedBox(height: isTablet ? 28.h : 24.h),
        ],
        if (_sessionCount > 0) ...[
          _buildSectionHeader(
              isTablet, AppLocalizations.of(context).searchSessionsTab),
          SizedBox(height: isTablet ? 14.h : 12.h),
          ..._buildSessionItems(isTablet),
          SizedBox(height: isTablet ? 28.h : 24.h),
        ],

// 🆕 Quiz Categories
        if (_quizCategoryCount > 0) ...[
          _buildSectionHeader(
              isTablet, AppLocalizations.of(context).quizCategoriesSection),
          SizedBox(height: isTablet ? 14.h : 12.h),
          ..._buildQuizCategoryItems(isTablet),
          SizedBox(height: isTablet ? 28.h : 24.h),
        ],

// 🆕 Diseases
        if (_diseaseCount > 0) ...[
          _buildSectionHeader(
              isTablet, AppLocalizations.of(context).diseasesSection),
          SizedBox(height: isTablet ? 14.h : 12.h),
          ..._buildDiseaseItems(isTablet),
        ],
      ],
    );
  }

  Widget _buildCategoriesTab(bool isTablet) {
    if (_categoryCount == 0) {
      return _buildNoResults(isTablet, AppLocalizations.of(context));
    }

    return ListView(
      padding: EdgeInsets.all(isTablet ? 24.w : 20.w),
      children: _buildCategoryItems(isTablet),
    );
  }

  Widget _buildSessionsTab(bool isTablet) {
    if (_sessionCount == 0) {
      return _buildNoResults(isTablet, AppLocalizations.of(context));
    }

    return Column(
      children: [
        _buildGenderFilter(context.colors),

        // Sessions list
        Expanded(
          child: ListView(
            padding: EdgeInsets.all(isTablet ? 24.w : 20.w),
            children: _buildSessionItems(isTablet),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(bool isTablet, String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: isTablet ? 18.sp : 16.sp,
        fontWeight: FontWeight.w700,
        color: context.colors.textPrimary,
      ),
    );
  }

  List<Widget> _buildCategoryItems(bool isTablet) {
    final categories =
        _searchResults['categories'] as List<Map<String, dynamic>>;

    return categories.map((category) {
      return Padding(
        padding: EdgeInsets.only(bottom: isTablet ? 14.h : 12.h),
        child: _buildCategoryCard(category, isTablet),
      );
    }).toList();
  }

  Widget _buildCategoryCard(Map<String, dynamic> category, bool isTablet) {
    return GestureDetector(
      onTap: () async {
        final navigator = Navigator.of(context);
        if (_searchController.text.trim().isNotEmpty) {
          await _historyService.saveSearchQuery(_searchController.text.trim());
          await _loadSearchHistory();
        }
        if (!mounted) return;
        navigator.push(
          MaterialPageRoute(
            builder: (_) => SessionsListScreen(
              categoryTitle: category['name'],
              categoryIconName: category['iconName'],
              categoryId: category['id'],
            ),
          ),
        );
      },
      child: Builder(
        builder: (context) {
          final colors = context.colors;
          return Container(
            padding: EdgeInsets.all(isTablet ? 18.w : 16.w),
            decoration: BoxDecoration(
              color: colors.backgroundCard,
              borderRadius: BorderRadius.circular(isTablet ? 18.r : 16.r),
              border: Border.all(
                color: colors.border,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.textPrimary.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Icon with colored background
                Container(
                  width: isTablet ? 56.w : 48.w,
                  height: isTablet ? 56.w : 48.w,
                  padding: EdgeInsets.all(8.w),
                  child: Lottie.asset(
                    AppIcons.getAnimationPath(
                      AppIcons.getIconByName(category['iconName'])?['path'] ??
                          'meditation.json',
                    ),
                    fit: BoxFit.contain,
                    repeat: true,
                  ),
                ),

                SizedBox(width: isTablet ? 18.w : 16.w),

                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category['name'],
                        style: GoogleFonts.inter(
                          fontSize: isTablet ? 18.sp : 16.sp,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                      if ((category['description'] ?? '')
                          .toString()
                          .isNotEmpty) ...[
                        SizedBox(height: 4.h),
                        Text(
                          category['description'] ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: isTablet ? 13.sp : 12.sp,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Arrow
                Icon(
                  Icons.arrow_forward_ios,
                  color: colors.textSecondary,
                  size: isTablet ? 20.sp : 18.sp,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildSessionItems(bool isTablet) {
    final sessions = _searchResults['sessions'] as List<Map<String, dynamic>>;

    return sessions.map((session) {
      return Padding(
        padding: EdgeInsets.only(bottom: isTablet ? 14.h : 12.h),
        child: _buildSessionCard(session, isTablet),
      );
    }).toList();
  }

  Widget _buildSessionCard(Map<String, dynamic> session, bool isTablet) {
    // Yeni SessionCard widget'ını kullan
    return SessionCard(
      session: session,
      onTap: () async {
        final navigator = Navigator.of(context);

        // Save search query to history
        if (_searchController.text.trim().isNotEmpty) {
          await _historyService.saveSearchQuery(_searchController.text.trim());
          await _loadSearchHistory();
        }

        if (!mounted) return;

        // Navigate to audio player
        navigator.push(
          MaterialPageRoute(
            builder: (_) => AudioPlayerScreen(sessionData: session),
          ),
        );
      },
    );
  }

  // 🆕 Quiz Tab
  Widget _buildQuizTab(bool isTablet) {
    if (_quizTotalCount == 0) {
      return _buildNoResults(isTablet, AppLocalizations.of(context));
    }

    return ListView(
      padding: EdgeInsets.all(isTablet ? 24.w : 20.w),
      children: [
        // Quiz Categories
        if (_quizCategoryCount > 0) ...[
          _buildSectionHeader(
              isTablet, AppLocalizations.of(context).quizCategoriesSection),
          SizedBox(height: isTablet ? 14.h : 12.h),
          ..._buildQuizCategoryItems(isTablet),
          SizedBox(height: isTablet ? 28.h : 24.h),
        ],

        // Diseases
        if (_diseaseCount > 0) ...[
          _buildSectionHeader(
              isTablet, AppLocalizations.of(context).diseasesSection),
          SizedBox(height: isTablet ? 14.h : 12.h),
          ..._buildDiseaseItems(isTablet),
        ],
      ],
    );
  }

// 🆕 Quiz Category Items
  List<Widget> _buildQuizCategoryItems(bool isTablet) {
    final quizCategories =
        _quizSearchResults['quizCategories'] as List<QuizCategorySearchResult>;
    final currentLang = Localizations.localeOf(context).languageCode;

    return quizCategories.map((result) {
      return Padding(
        padding: EdgeInsets.only(bottom: isTablet ? 14.h : 12.h),
        child: QuizCategorySearchCard(
          result: result,
          locale: currentLang,
          onTap: () async {
            await _saveSearchAndNavigate();
            if (!mounted) return;

            // Show bottom sheet with diseases
            QuizCategoryDiseasesSheet.show(
              context,
              category: result.category,
              locale: currentLang,
            );
          },
        ),
      );
    }).toList();
  }

// 🆕 Disease Items
  List<Widget> _buildDiseaseItems(bool isTablet) {
    final diseases =
        _quizSearchResults['diseases'] as List<DiseaseSearchResult>;
    final currentLang = Localizations.localeOf(context).languageCode;

    return diseases.map((result) {
      return Padding(
        padding: EdgeInsets.only(bottom: isTablet ? 14.h : 12.h),
        child: DiseaseSearchCard(
          result: result,
          locale: currentLang,
          onTap: () async {
            await _saveSearchAndNavigate();
            if (!mounted) return;

            // Navigate to QuizResultsScreen with this disease
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => QuizResultsScreen(
                  selectedDiseases: [result.disease],
                ),
              ),
            );
          },
        ),
      );
    }).toList();
  }

// 🆕 Helper: Save search and navigate
  Future<void> _saveSearchAndNavigate() async {
    if (_searchController.text.trim().isNotEmpty) {
      await _historyService.saveSearchQuery(_searchController.text.trim());
      await _loadSearchHistory();
    }
  }

  Widget _buildGenderFilter(AppThemeExtension colors) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      child: Row(
        children: [
          Text(
            'Filter: ',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: colors.textSecondary,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('all', '🌐 All', colors),
                  SizedBox(width: 8.w),
                  _buildFilterChip('male', '♂ Male', colors),
                  SizedBox(width: 8.w),
                  _buildFilterChip('female', '♀ Female', colors),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
      String value, String label, AppThemeExtension colors) {
    final isSelected = _selectedGenderFilter == value;
    return GestureDetector(
      onTap: () {
        if (_selectedGenderFilter != value) {
          setState(() => _selectedGenderFilter = value);
          // Re-run search with new filter
          _performSearch(_searchController.text);
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? colors.textPrimary : colors.greyLight,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected ? colors.textPrimary : colors.border,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? colors.textOnPrimary : colors.textSecondary,
          ),
        ),
      ),
    );
  }
}
