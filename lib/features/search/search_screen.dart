// lib/features/search/search_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../core/responsive/context_ext.dart';
import 'search_service.dart';
import '../library/sessions_list_screen.dart';
import '../player/audio_player_screen.dart';
import '../../shared/widgets/session_card.dart';
import 'search_history_service.dart';
import 'widgets/search_history_view.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final SearchService _searchService = SearchService();
  final FocusNode _focusNode = FocusNode();
  final SearchHistoryService _historyService = SearchHistoryService();
  late TabController _tabController;

  List<String> _recentSearches = [];
  bool _isLoadingHistory = true;

  bool _isSearching = false;
  Map<String, dynamic> _searchResults = {
    'categories': <Map<String, dynamic>>[],
    'sessions': <Map<String, dynamic>>[],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSearchHistory();

    // Auto-focus when opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
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
              style: GoogleFonts.inter(color: AppColors.textSecondary),
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
            backgroundColor: AppColors.primaryGold,
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
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    final results = await _searchService.search(query);

    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
  }

  int get _totalResults => _searchService.getTotalResultCount(_searchResults);
  int get _categoryCount => (_searchResults['categories'] as List).length;
  int get _sessionCount => (_searchResults['sessions'] as List).length;

  @override
  Widget build(BuildContext context) {
    final isTablet = context.isTablet;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
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
                        // ⭐ BURAYI DEĞİŞTİR
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
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isTablet ? 24.w : 20.w,
        vertical: isTablet ? 14.h : 12.h,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 18.w : 16.w,
      ),
      decoration: BoxDecoration(
        color: AppColors.greyLight,
        borderRadius: BorderRadius.circular(isTablet ? 14.r : 12.r),
        border: Border.all(
          color: AppColors.greyBorder.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            color: AppColors.textSecondary,
            size: isTablet ? 22.sp : 20.sp,
          ),
          SizedBox(width: isTablet ? 14.w : 12.w),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              style: GoogleFonts.inter(
                fontSize: isTablet ? 16.sp : 15.sp,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: l10n.searchSessions,
                hintStyle: GoogleFonts.inter(
                  fontSize: isTablet ? 16.sp : 15.sp,
                  color: AppColors.textSecondary,
                ),
                border: InputBorder.none,
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
                color: AppColors.textSecondary,
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
                color: AppColors.textSecondary,
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
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildTabs(bool isTablet, AppLocalizations l10n) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isTablet ? 24.w : 20.w),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.textPrimary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primaryGold,
        isScrollable: false,
        labelPadding: EdgeInsets.symmetric(horizontal: isTablet ? 12.w : 8.w),
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
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        color: AppColors.primaryGold,
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
      ],
    );
  }

  Widget _buildNoResults(bool isTablet, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: isTablet ? 80.sp : 64.sp,
            color: AppColors.greyLight,
          ),
          SizedBox(height: isTablet ? 24.h : 16.h),
          Text(
            l10n.noResultsFound,
            style: GoogleFonts.inter(
              fontSize: isTablet ? 20.sp : 18.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: isTablet ? 10.h : 8.h),
          Text(
            l10n.tryDifferentKeywords,
            style: GoogleFonts.inter(
              fontSize: isTablet ? 15.sp : 14.sp,
              color: AppColors.textSecondary,
            ),
          ),
        ],
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

    return ListView(
      padding: EdgeInsets.all(isTablet ? 24.w : 20.w),
      children: _buildSessionItems(isTablet),
    );
  }

  Widget _buildSectionHeader(bool isTablet, String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: isTablet ? 18.sp : 16.sp,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
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
    final color = Color(int.parse(category['color']));

    return GestureDetector(
      onTap: () async {
        if (_searchController.text.trim().isNotEmpty) {
          await _historyService.saveSearchQuery(_searchController.text.trim());
          await _loadSearchHistory();
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SessionsListScreen(
              categoryTitle: category['title'],
              categoryEmoji: category['emoji'],
              categoryId: category['id'],
            ),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(isTablet ? 18.w : 16.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(isTablet ? 18.r : 16.r),
        ),
        child: Row(
          children: [
            Container(
              width: isTablet ? 56.w : 48.w,
              height: isTablet ? 56.w : 48.w,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(isTablet ? 14.r : 12.r),
              ),
              alignment: Alignment.center,
              child: Text(
                category['emoji'],
                style: TextStyle(fontSize: isTablet ? 32.sp : 28.sp),
              ),
            ),
            SizedBox(width: isTablet ? 18.w : 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category['title'],
                    style: GoogleFonts.inter(
                      fontSize: isTablet ? 18.sp : 16.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  if (category['description'].toString().isNotEmpty) ...[
                    SizedBox(height: 4.h),
                    Text(
                      category['description'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: isTablet ? 13.sp : 12.sp,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: isTablet ? 20.sp : 18.sp,
            ),
          ],
        ),
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
        // Save search query to history
        if (_searchController.text.trim().isNotEmpty) {
          await _historyService.saveSearchQuery(_searchController.text.trim());
          await _loadSearchHistory();
        }

        // Navigate to audio player
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AudioPlayerScreen(sessionData: session),
          ),
        );
      },
    );
  }
}
