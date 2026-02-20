// lib/features/admin/category_management_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/themes/app_theme_extension.dart';
import '../../core/constants/app_languages.dart';
import '../../core/responsive/breakpoints.dart';
import '../../models/category_model.dart';
import '../../services/category/category_service.dart';
import '../../services/category/category_localization_service.dart';
import '../../services/category/category_filter_service.dart';
import '../../services/language_helper_service.dart';
import '../../l10n/app_localizations.dart';
import '../../../shared/widgets/category_icon.dart';
import 'add_category_screen.dart';
import 'category_images_screen.dart';
import 'widgets/admin_search_bar.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  final CategoryService _categoryService = CategoryService();
  List<CategoryModel> _filteredCategories = [];
  bool _isLoading = true;
  bool _showOnlyUserLanguage = true;

  // Search
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);

    try {
      final categories =
          await _categoryService.getAllCategories(forceRefresh: true);

      if (_showOnlyUserLanguage) {
        final filtered =
            await CategoryFilterService.filterCategoriesByLanguage(categories);
        final userLanguage = await LanguageHelperService.getCurrentLanguage();
        filtered.sort((a, b) {
          final nameA = a.getName(userLanguage).toLowerCase();
          final nameB = b.getName(userLanguage).toLowerCase();
          return nameA.compareTo(nameB);
        });
        setState(() {
          _filteredCategories = filtered;
          _isLoading = false;
        });
      } else {
        categories.sort((a, b) {
          final nameA = a.getName('en').toLowerCase();
          final nameB = b.getName('en').toLowerCase();
          return nameA.compareTo(nameB);
        });
        setState(() {
          _filteredCategories = categories;
          _isLoading = false;
        });
      }

      // Debug: Print language stats
      CategoryFilterService.debugPrintLanguageStats(categories);
    } catch (e) {
      debugPrint('❌ Error loading categories: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleLanguageFilter() async {
    setState(() {
      _showOnlyUserLanguage = !_showOnlyUserLanguage;
    });
    await _loadCategories();
  }

  // =================== UI BUILDERS ===================

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final mq = MediaQuery.of(context);
    final width = mq.size.width;

    // Responsive breakpoints
    final bool isTablet =
        width >= Breakpoints.tabletMin && width < Breakpoints.desktopMin;
    final bool isDesktop = width >= Breakpoints.desktopMin;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context).categoryManagement,
          style: GoogleFonts.inter(
            fontSize: isTablet ? 22.sp : 20.sp,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        actions: [
          // Language filter toggle
          IconButton(
            icon: Icon(
              _showOnlyUserLanguage ? Icons.language : Icons.language_outlined,
              color: _showOnlyUserLanguage
                  ? colors.textPrimary
                  : colors.textSecondary,
            ),
            onPressed: _toggleLanguageFilter,
            tooltip: _showOnlyUserLanguage
                ? AppLocalizations.of(context).showingOnlyYourLanguage
                : AppLocalizations.of(context).showingAllLanguages,
          ),
          // Add button
          IconButton(
            icon: Icon(Icons.add_circle, color: colors.textPrimary),
            onPressed: _navigateToAddCategory,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: AdminSearchBar(
              controller: _searchController,
              onSearchChanged: (query) {
                setState(() => _searchQuery = query);
              },
              onClear: () {
                setState(() => _searchQuery = '');
              },
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(color: colors.textPrimary),
                  )
                : _buildCategoryContent(isTablet, isDesktop, colors),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryContent(
      bool isTablet, bool isDesktop, AppThemeExtension colors) {
    // Apply search filter
    var displayCategories = _filteredCategories;

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      displayCategories = _filteredCategories.where((category) {
        // Search in all language names
        for (final name in category.names.values) {
          if (name.toLowerCase().contains(query)) return true;
        }
        // Search in icon name
        if (category.iconName.toLowerCase().contains(query)) return true;
        return false;
      }).toList();
    }

    if (displayCategories.isEmpty) {
      // Show different message based on search vs no data
      if (_searchQuery.isNotEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: isTablet ? 80.sp : 64.sp,
                color: colors.greyMedium,
              ),
              SizedBox(height: 16.h),
              Text(
                AppLocalizations.of(context).noResultsFound,
                style: GoogleFonts.inter(
                  fontSize: isTablet ? 20.sp : 18.sp,
                  color: colors.textSecondary,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                AppLocalizations.of(context).tryDifferentKeywords,
                style: GoogleFonts.inter(
                  fontSize: isTablet ? 16.sp : 14.sp,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        );
      }
      return _buildEmptyState(isTablet, isDesktop, colors);
    }

    return ListView.builder(
      padding: EdgeInsets.all(isTablet ? 24.w : 20.w),
      itemCount: displayCategories.length,
      itemBuilder: (context, index) {
        final category = displayCategories[index];
        return _buildCategoryCard(category, isTablet, isDesktop, colors);
      },
    );
  }

  Widget _buildEmptyState(
      bool isTablet, bool isDesktop, AppThemeExtension colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.category_outlined,
            size: isTablet ? 80.sp : 64.sp,
            color: colors.greyMedium,
          ),
          SizedBox(height: 16.h),
          Text(
            AppLocalizations.of(context).noCategoriesYet,
            style: GoogleFonts.inter(
              fontSize: isTablet ? 20.sp : 18.sp,
              color: colors.textSecondary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            AppLocalizations.of(context).addFirstCategory,
            style: GoogleFonts.inter(
              fontSize: isTablet ? 16.sp : 14.sp,
              color: colors.textSecondary,
            ),
          ),
          SizedBox(height: 24.h),
          ElevatedButton.icon(
            onPressed: _navigateToAddCategory,
            icon: const Icon(Icons.add),
            label: Text(AppLocalizations.of(context).addNewCategory),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.textPrimary,
              foregroundColor: colors.textOnPrimary,
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 32.w : 24.w,
                vertical: isTablet ? 16.h : 14.h,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(CategoryModel category, bool isTablet,
      bool isDesktop, AppThemeExtension colors) {
    return FutureBuilder<String>(
      future: CategoryLocalizationService.getLocalizedNameAuto(category),
      builder: (context, snapshot) {
        final localizedName = snapshot.data ?? category.getName('en');

        return Container(
          margin: EdgeInsets.only(bottom: 16.h),
          padding: EdgeInsets.all(isTablet ? 20.w : 16.w),
          decoration: BoxDecoration(
            color: colors.backgroundPure,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: colors.border),
            boxShadow: [
              BoxShadow(
                color: colors.textPrimary.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: isTablet ? 60.w : 50.w,
                height: isTablet ? 60.w : 50.w,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colors.textPrimary,
                      colors.textPrimary.withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Padding(
                  padding: EdgeInsets.all(10.w),
                  child: CategoryIcon(
                    name: category.iconName,
                    size: isTablet ? 40.w : 30.w,
                    forceBrightness: Brightness.dark,
                  ),
                ),
              ),
              SizedBox(width: 16.w),

              // Category Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + Language Badges
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            localizedName,
                            style: GoogleFonts.inter(
                              fontSize: isTablet ? 18.sp : 16.sp,
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        _buildLanguageBadges(category, isTablet, colors),
                      ],
                    ),

                    SizedBox(height: 8.h),

                    // Metadata
                    Row(
                      children: [
                        // Session count - Real-time from Firestore
                        Icon(
                          Icons.play_circle_filled,
                          size: isTablet ? 18.sp : 16.sp,
                          color: colors.textPrimary,
                        ),
                        SizedBox(width: 4.w),
                        Flexible(
                          child: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('sessions')
                                .where('categoryId', isEqualTo: category.id)
                                .snapshots(),
                            builder: (context, snapshot) {
                              final count = snapshot.data?.docs.length ?? 0;
                              return Text(
                                '$count ${AppLocalizations.of(context).sessions}',
                                style: GoogleFonts.inter(
                                  fontSize: isTablet ? 14.sp : 12.sp,
                                  color: colors.textSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: 16.w),

                    // Image count
                    Row(
                      children: [
                        Icon(
                          Icons.image,
                          size: isTablet ? 18.sp : 16.sp,
                          color: colors.textSecondary,
                        ),
                        SizedBox(width: 4.w),
                        Flexible(
                          child: Text(
                            '${category.backgroundImages.length} ${AppLocalizations.of(context).images}',
                            style: GoogleFonts.inter(
                              fontSize: isTablet ? 14.sp : 12.sp,
                              color: colors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(width: 12.w),

              // Action Buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Manage Images button
                  IconButton(
                    onPressed: () => _manageImages(category),
                    icon: Icon(
                      Icons.photo_library,
                      color: colors.textPrimary,
                      size: isTablet ? 24.sp : 22.sp,
                    ),
                    tooltip: AppLocalizations.of(context).manageImages,
                  ),
                  // Edit button
                  IconButton(
                    onPressed: () => _navigateToEditCategory(category),
                    icon: Icon(
                      Icons.edit,
                      color: colors.textPrimary,
                      size: isTablet ? 24.sp : 22.sp,
                    ),
                    tooltip: AppLocalizations.of(context).editCategory,
                  ),
                  // Delete button
                  IconButton(
                    onPressed: () => _showDeleteConfirmation(category),
                    icon: Icon(
                      Icons.delete,
                      color: Colors.red,
                      size: isTablet ? 24.sp : 22.sp,
                    ),
                    tooltip: AppLocalizations.of(context).deleteCategory,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageBadges(
      CategoryModel category, bool isTablet, AppThemeExtension colors) {
    final availableLanguages = category.availableLanguages;

    // Show max 3 flags to prevent overflow
    final displayLanguages = availableLanguages.take(3).toList();
    final hasMore = availableLanguages.length > 3;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...displayLanguages.map((lang) {
          return Padding(
            padding: EdgeInsets.only(right: 2.w),
            child: Text(
              AppLanguages.getFlag(lang),
              style: TextStyle(fontSize: 14.sp),
            ),
          );
        }),
        if (hasMore)
          Text(
            '+${availableLanguages.length - 3}',
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }

  // =================== ACTIONS ===================

  Future<void> _navigateToAddCategory() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddCategoryScreen(),
      ),
    );

    if (result == true) {
      // Refresh list
      _loadCategories();
    }
  }

  Future<void> _navigateToEditCategory(CategoryModel category) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddCategoryScreen(categoryToEdit: category),
      ),
    );

    if (result == true) {
      // Refresh list
      _loadCategories();
    }
  }

  Future<void> _showDeleteConfirmation(CategoryModel category) async {
    final localizedName =
        await CategoryLocalizationService.getLocalizedNameAuto(category);

    if (!mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).deleteCategory),
        content: Text(
          AppLocalizations.of(context).deleteCategoryConfirm(localizedName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text(AppLocalizations.of(context).deleteCategory),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _deleteCategory(category);
    }
  }

  Future<void> _deleteCategory(CategoryModel category) async {
    try {
      final success = await _categoryService.deleteCategory(category.id);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(AppLocalizations.of(context).categoryDeletedSuccessfully),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh list
        _loadCategories();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).errorDeletingCategory),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('${AppLocalizations.of(context).errorDeletingCategory}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Navigate to image management screen
  Future<void> _manageImages(CategoryModel category) async {
    final userLanguage = await LanguageHelperService.getCurrentLanguage();

    if (!mounted) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryImagesScreen(
          categoryId: category.id,
          categoryName: category.getName(userLanguage),
        ),
      ),
    );

    // Refresh if images were updated
    if (result == true) {
      _loadCategories();
    }
  }
}
