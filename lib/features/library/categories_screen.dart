// lib/features/library/categories_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/themes/app_theme_extension.dart';
import 'sessions_list_screen.dart';
import '../player/audio_player_screen.dart';
import '../../shared/widgets/session_card.dart';
import '../../core/responsive/breakpoints.dart';
import '../../core/constants/app_icons.dart';
import '../../l10n/app_localizations.dart';
import '../../services/session_filter_service.dart';
import '../../models/category_model.dart';
import '../../services/category/category_service.dart';
import '../../services/category/category_localization_service.dart';
import '../../services/language_helper_service.dart';
import '../../services/cache_manager_service.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CategoryService _categoryService = CategoryService();
  late TabController _tabController;

  // Categories list
  List<CategoryModel> _categories = [];
  bool _isLoadingCategories = true;

  // PAGINATION STATE
  List<Map<String, dynamic>> _allSessions = [];
  DocumentSnapshot? _lastDocument;
  bool _hasMoreSessions = true;
  bool _isLoadingSessions = false;
  int _recursiveCallCount = 0;
  String _selectedGenderFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCategories();
    _prefetchImages();
    _loadInitialSessions();
    _loadUserGender();
  }

  Future<void> _loadUserGender() async {
    final gender = await SessionFilterService.getUserGender();
    if (mounted && gender != null) {
      setState(() {
        _selectedGenderFilter = gender;
      });
      _loadInitialSessions();
    } else {
      _loadInitialSessions();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(CategoriesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Reset pagination when widget updates (e.g. language change)
    debugPrint('🔄 [CategoriesScreen] Widget updated, resetting pagination');

    // Reset all sessions state
    setState(() {
      _allSessions = [];
      _lastDocument = null;
      _hasMoreSessions = true;
    });

    // Reload categories and sessions
    _loadCategories();
    _loadInitialSessions();
  }

  Future<void> _prefetchImages() async {
    await _categoryService.smartPrefetchCategoryImages();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoadingCategories = true);

    try {
      // Get categories filtered by user's language
      final categories = await _categoryService.getCategoriesByLanguage();
      final userLanguage = await LanguageHelperService.getCurrentLanguage();
      categories.sort((a, b) {
        final nameA = a.getName(userLanguage).toLowerCase();
        final nameB = b.getName(userLanguage).toLowerCase();
        return nameA.compareTo(nameB);
      });

      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
      });

      debugPrint('✅ Loaded ${categories.length} categories for user language');
    } catch (e) {
      debugPrint('❌ Error loading categories: $e');
      setState(() {
        _categories = [];
        _isLoadingCategories = false;
      });
    }
  }

  Future<void> _loadInitialSessions() async {
    setState(() {
      _allSessions = [];
      _lastDocument = null;
      _hasMoreSessions = true;
    });

    await _loadMoreSessions();
  }

  Future<void> _loadMoreSessions() async {
    if (_isLoadingSessions || !_hasMoreSessions) {
      debugPrint('⏸️ [Pagination] Already loading or no more sessions');
      return;
    }

    // 🆕 Prevent infinite loop
    if (_recursiveCallCount > 10) {
      debugPrint('⚠️ [Pagination] Max recursive calls reached, stopping');
      setState(() {
        _hasMoreSessions = false;
        _isLoadingSessions = false;
      });
      _recursiveCallCount = 0;
      return;
    }

    setState(() => _isLoadingSessions = true);

    try {
      debugPrint('📥 [Pagination] Loading sessions...');

      Query query = _firestore
          .collection('sessions')
          .orderBy('createdAt', descending: true)
          .limit(20);

      if (_lastDocument != null) {
        query = query.startAfter([_lastDocument!['createdAt']]);
        debugPrint('📄 [Pagination] Starting after: ${_lastDocument!.id}');
      }

      final snapshot = await query.get();
      debugPrint('📦 [Pagination] Fetched ${snapshot.docs.length} sessions');

      if (snapshot.docs.isEmpty) {
        setState(() {
          _hasMoreSessions = false;
          _isLoadingSessions = false;
        });
        _recursiveCallCount = 0; // 🆕 Reset
        debugPrint('🏁 [Pagination] No more sessions');
        return;
      }

      // Apply language filter
      final filtered =
          await SessionFilterService.filterSessionsByLanguageAndGender(
        snapshot.docs,
        _selectedGenderFilter,
      );
      debugPrint('🌍 [Pagination] After language filter: ${filtered.length}');

      // 🆕 AUTO-RECURSIVE: If all filtered and more docs exist
      if (filtered.isEmpty && snapshot.docs.length == 20) {
        debugPrint(
            '⚠️ [Pagination] All filtered out, auto-loading more... (attempt ${_recursiveCallCount + 1}/10)');
        _lastDocument = snapshot.docs.last;
        _recursiveCallCount++; // 🆕 Increment
        setState(() => _isLoadingSessions = false);
        await _loadMoreSessions(); // 🆕 Recursive call
        return;
      }

      // 🆕 Reset counter on success
      _recursiveCallCount = 0;

      setState(() {
        _allSessions.addAll(filtered);
        _lastDocument = snapshot.docs.last;
        _hasMoreSessions = snapshot.docs.length == 20;
        _isLoadingSessions = false;
      });

      debugPrint('✅ [Pagination] Total sessions now: ${_allSessions.length}');
    } catch (e) {
      debugPrint('❌ [Pagination] Error: $e');
      _recursiveCallCount = 0; // 🆕 Reset on error
      setState(() => _isLoadingSessions = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final mq = MediaQuery.of(context);
    final width = mq.size.width;

    final bool isTablet =
        width >= Breakpoints.tabletMin && width < Breakpoints.desktopMin;
    final bool isDesktop = width >= Breakpoints.desktopMin;

    final double leadingWidth = isTablet ? 64 : 56;
    final double leadingPad = isTablet ? 12 : 8;

    final double toolbarH = isDesktop ? 64.0 : (isTablet ? 60.0 : 40.0);

    final double logoW = isDesktop ? 100.0 : (isTablet ? 88.0 : 68.0);
    final double logoH = toolbarH * 0.70;
    final double dividerH = (logoH * 0.9).clamp(18.0, 36.0);

    final double ts = mq.textScaler.scale(1.0).clamp(1.0, 1.2);

    return MediaQuery(
      data: mq.copyWith(textScaler: TextScaler.linear(ts)),
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          toolbarHeight: toolbarH,
          backgroundColor: colors.background,
          elevation: 0,
          leadingWidth: leadingWidth,
          titleSpacing: isTablet ? 8 : 4,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: colors.textPrimary,
              size: (24.sp).clamp(20.0, 28.0),
            ),
            padding: EdgeInsets.only(left: leadingPad),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: LayoutBuilder(
            builder: (context, c) {
              return Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Expanded(
                    child: Center(
                      // ← ORTALAMA EKLE
                      child: SvgPicture.asset(
                        'assets/images/logo.svg',
                        width: logoW,
                        height: logoH,
                        fit: BoxFit.contain,
                        colorFilter: ColorFilter.mode(
                          colors.textPrimary,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),

                  // ORTA: Ayraç tam ortada
                  Container(
                    height: dividerH,
                    width: 1.5,
                    color: colors.textPrimary.withValues(alpha: 0.2),
                    margin: EdgeInsets.symmetric(
                        horizontal: 8.w), // ← Biraz margin ekle
                  ),

                  Expanded(
                    child: Center(
                      child: Text(
                        AppLocalizations.of(context).allSubliminals,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: (15.sp).clamp(14.0, 20.0),
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                  )
                ],
              );
            },
          ),
          bottom: TabBar(
            isScrollable: false,
            padding: EdgeInsets.zero,
            labelPadding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 32 : (isTablet ? 28 : 20),
            ),
            indicatorPadding:
                EdgeInsets.symmetric(horizontal: isTablet ? 10 : 6),
            controller: _tabController,
            indicatorColor: colors.textPrimary,
            indicatorWeight: 3,
            labelColor: colors.textPrimary,
            unselectedLabelColor: colors.textSecondary,
            labelStyle: GoogleFonts.inter(
              fontSize: (14.sp).clamp(12.0, 18.0),
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: GoogleFonts.inter(
              fontSize: (14.sp).clamp(12.0, 18.0),
              fontWeight: FontWeight.w500,
            ),
            tabs: [
              Tab(text: AppLocalizations.of(context).categories),
              Tab(text: AppLocalizations.of(context).allSessions),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildCategoriesTab(),
            _buildAllSessionsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesTab() {
    final colors = context.colors;
    if (_isLoadingCategories) {
      return Center(
        child: CircularProgressIndicator(
          color: colors.textPrimary,
        ),
      );
    }

    final filteredCategories = _selectedGenderFilter == 'all'
        ? _categories
        : _categories.where((cat) {
            return cat.gender == 'both' || cat.gender == _selectedGenderFilter;
          }).toList();

    if (filteredCategories.isEmpty) {
      return Column(
        children: [
          _buildGenderFilter(colors),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.category_outlined,
                    size: 64.sp,
                    color: colors.greyMedium,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    AppLocalizations.of(context).noCategoriesYet,
                    style: GoogleFonts.inter(
                      fontSize: 18.sp,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildGenderFilter(colors),

        // Header
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).chooseCategory,
                style: GoogleFonts.inter(
                  fontSize: 24.sp.clamp(22.0, 34.0),
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                AppLocalizations.of(context).selectCategoryExplore,
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w400,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 16.h),

        // Categories Grid
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16.w,
              mainAxisSpacing: 16.h,
              childAspectRatio: 1.0,
            ),
            itemCount: filteredCategories.length,
            itemBuilder: (context, index) {
              final category = filteredCategories[index];
              return _buildCategoryCard(category);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(CategoryModel category) {
    final colors = context.colors;
    // Parse color
    Color cardColor = colors.textPrimary;

    return FutureBuilder<String>(
        future: CategoryLocalizationService.getLocalizedNameAuto(category),
        builder: (context, snapshot) {
          final localizedName = snapshot.data ?? category.getName('en');

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SessionsListScreen(
                    categoryTitle: localizedName,
                    categoryIconName: category.iconName,
                    categoryId: category.id,
                  ),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    cardColor.withValues(alpha: 0.8),
                    cardColor.withValues(alpha: 0.4),
                  ],
                ),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Stack(
                children: [
                  if (category.backgroundImages.isNotEmpty)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24.r),
                        child: CachedNetworkImage(
                          imageUrl: _categoryService
                                  .getRandomBackgroundImage(category) ??
                              '',
                          cacheManager: AppCacheManager.instance,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  cardColor,
                                  cardColor.withValues(alpha: 0.7)
                                ],
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  cardColor,
                                  cardColor.withValues(alpha: 0.7)
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Dark overlay for readability
                  if (category.backgroundImages.isNotEmpty)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24.r),
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.4),
                              Colors.black.withValues(alpha: 0.6),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),

                  // Content
                  Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon
                        SizedBox(
                          width: 60.w,
                          height: 60.w,
                          child: Lottie.asset(
                            AppIcons.getAnimationPath(
                              AppIcons.getIconByName(
                                      category.iconName)?['path'] ??
                                  'meditation.json',
                            ),
                            fit: BoxFit.contain,
                            repeat: true,
                          ),
                        ),

                        const Spacer(),

                        // Title
                        Text(
                          localizedName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),

                        SizedBox(height: 4.h),

                        // Session Count
                        StreamBuilder<QuerySnapshot>(
                          stream: _firestore
                              .collection('sessions')
                              .where('categoryId', isEqualTo: category.id)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Row(
                                children: [
                                  Icon(
                                    Icons.play_circle_filled,
                                    color: Colors.white.withValues(alpha: 0.8),
                                    size: 16.sp,
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    '...  ${AppLocalizations.of(context).sessions}',
                                    style: GoogleFonts.inter(
                                      fontSize: 12.sp,
                                      color:
                                          Colors.white.withValues(alpha: 0.8),
                                    ),
                                  ),
                                ],
                              );
                            }

                            final allDocs = snapshot.data?.docs ?? [];

                            // ✅ LANGUAGE FILTER
                            return FutureBuilder<List<Map<String, dynamic>>>(
                              future:
                                  SessionFilterService.filterSessionsByLanguage(
                                      allDocs),
                              builder: (context, filteredSnapshot) {
                                final count =
                                    filteredSnapshot.data?.length ?? 0;

                                return Row(
                                  children: [
                                    Icon(
                                      Icons.play_circle_filled,
                                      color:
                                          Colors.white.withValues(alpha: 0.8),
                                      size: 16.sp,
                                    ),
                                    SizedBox(width: 4.w),
                                    Text(
                                      '$count  ${AppLocalizations.of(context).sessions}',
                                      style: GoogleFonts.inter(
                                        fontSize: 12.sp,
                                        color:
                                            Colors.white.withValues(alpha: 0.8),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }

  Widget _buildAllSessionsTab() {
    final colors = context.colors;
    // Loading state
    if (_isLoadingSessions && _allSessions.isEmpty) {
      return Center(
        child: CircularProgressIndicator(
          color: colors.textPrimary,
        ),
      );
    }

    // Empty state
    if (_allSessions.isEmpty && !_hasMoreSessions) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.library_music,
              size: 64.sp,
              color: colors.greyLight,
            ),
            SizedBox(height: 16.h),
            Text(
              AppLocalizations.of(context).noSessionsAvailable,
              style: GoogleFonts.inter(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    // Sessions list with pagination
    return Column(
      children: [
        // 🆕 Gender Filter
        _buildGenderFilter(colors),

        // Sessions list
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(20.w),
            itemCount: _allSessions.length + (_hasMoreSessions ? 1 : 0),
            itemBuilder: (context, index) {
              // See more button at the end
              if (index == _allSessions.length) {
                if (_isLoadingSessions) {
                  // Loading indicator
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 20.h),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: colors.textPrimary,
                      ),
                    ),
                  );
                } else {
                  // See More button
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 20.h),
                    child: Center(
                      child: ElevatedButton(
                        onPressed: _loadMoreSessions,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.textPrimary,
                          padding: EdgeInsets.symmetric(
                            horizontal: 32.w,
                            vertical: 12.h,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: Text(
                          AppLocalizations.of(context).seeMore,
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  );
                }
              }

              // Session item
              final session = _allSessions[index];
              return _buildSessionItem(context, session);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSessionItem(BuildContext context, Map<String, dynamic> session) {
    // Add session ID if not present
    if (!session.containsKey('id')) {
      final sessionDoc = _firestore.collection('sessions').doc();
      session['id'] = sessionDoc.id;
    }

    return SessionCard(
      session: session,
      onTap: () {
        // Navigate to Audio Player
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AudioPlayerScreen(
              sessionData: session,
            ),
          ),
        );
      },
    );
  }

  Widget _buildGenderFilter(AppThemeExtension colors) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      child: Row(
        children: [
          Text(
            '${AppLocalizations.of(context).filterLabel}: ',
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
                  _buildFilterChip(
                      'all', '🌐 ${AppLocalizations.of(context).all}', colors),
                  SizedBox(width: 8.w),
                  _buildFilterChip(
                      'male', '♂ ${AppLocalizations.of(context).male}', colors),
                  SizedBox(width: 8.w),
                  _buildFilterChip('female',
                      '♀ ${AppLocalizations.of(context).female}', colors),
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
          _loadInitialSessions();
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
