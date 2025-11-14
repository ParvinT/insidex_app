// lib/features/library/categories_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCategories();
    _prefetchImages();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
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

    final double _ts = mq.textScaleFactor.clamp(1.0, 1.2);

    return MediaQuery(
      data: mq.copyWith(textScaleFactor: _ts),
      child: Scaffold(
        backgroundColor: AppColors.backgroundWhite,
        appBar: AppBar(
          toolbarHeight: toolbarH,
          backgroundColor: AppColors.backgroundWhite,
          elevation: 0,
          leadingWidth: leadingWidth,
          titleSpacing: isTablet ? 8 : 4,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: AppColors.textPrimary,
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
                          AppColors.textPrimary,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),

                  // ORTA: Ayraç tam ortada
                  Container(
                    height: dividerH,
                    width: 1.5,
                    color: AppColors.textPrimary.withOpacity(0.2),
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
                          color: AppColors.textPrimary,
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
            indicatorColor: AppColors.textPrimary,
            indicatorWeight: 3,
            labelColor: AppColors.textPrimary,
            unselectedLabelColor: AppColors.textSecondary,
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
    if (_isLoadingCategories) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.textPrimary,
        ),
      );
    }
    if (_categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.category_outlined,
              size: 64.sp,
              color: AppColors.greyMedium,
            ),
            SizedBox(height: 16.h),
            Text(
              AppLocalizations.of(context).noCategoriesYet,
              style: GoogleFonts.inter(
                fontSize: 18.sp,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).chooseCategory,
                style: GoogleFonts.inter(
                  fontSize: 24.sp.clamp(22.0, 34.0),
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                AppLocalizations.of(context).selectCategoryExplore,
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),

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
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              return _buildCategoryCard(category);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(CategoryModel category) {
    // Parse color
    Color cardColor = AppColors.textPrimary;

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
                    cardColor.withOpacity(0.8),
                    cardColor.withOpacity(0.4),
                  ],
                ),
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: cardColor.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
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
                                colors: [cardColor, cardColor.withOpacity(0.7)],
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [cardColor, cardColor.withOpacity(0.7)],
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
                              Colors.black.withOpacity(0.4),
                              Colors.black.withOpacity(0.6),
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
                              .where('category', isEqualTo: category.id)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Row(
                                children: [
                                  Icon(
                                    Icons.play_circle_filled,
                                    color: Colors.white.withOpacity(0.8),
                                    size: 16.sp,
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    '...  ${AppLocalizations.of(context).sessions}',
                                    style: GoogleFonts.inter(
                                      fontSize: 12.sp,
                                      color: Colors.white.withOpacity(0.8),
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
                                      color: Colors.white.withOpacity(0.8),
                                      size: 16.sp,
                                    ),
                                    SizedBox(width: 4.w),
                                    Text(
                                      '$count  ${AppLocalizations.of(context).sessions}',
                                      style: GoogleFonts.inter(
                                        fontSize: 12.sp,
                                        color: Colors.white.withOpacity(0.8),
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
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('sessions')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.textPrimary,
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              AppLocalizations.of(context).errorLoadingSessions,
              style: GoogleFonts.inter(
                fontSize: 16.sp.clamp(14.0, 22.0),
                color: AppColors.textSecondary,
              ),
            ),
          );
        }

        final allDocs = snapshot.data?.docs ?? [];

        // ✅ LANGUAGE FILTER
        return FutureBuilder<List<Map<String, dynamic>>>(
            future: SessionFilterService.filterSessionsByLanguage(allDocs),
            builder: (context, filteredSnapshot) {
              if (filteredSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.textPrimary,
                  ),
                );
              }

              final sessions = filteredSnapshot.data ?? [];

              if (sessions.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.library_music,
                        size: 64.sp,
                        color: AppColors.greyLight,
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        AppLocalizations.of(context).noSessionsAvailable,
                        style: GoogleFonts.inter(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: EdgeInsets.all(20.w),
                itemCount: sessions.length,
                itemBuilder: (context, index) {
                  final session = sessions[index]; // Already filtered Map
                  return _buildSessionItem(context, session);
                },
              );
            });
      },
    );
  }

// IMPORTANT: Only replace the _buildSessionItem method with this updated version
// Add CachedNetworkImage import at the top of the file if not present

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
}
