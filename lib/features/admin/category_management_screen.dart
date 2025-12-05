// lib/features/admin/category_management_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_languages.dart';
import '../../core/responsive/breakpoints.dart';
import '../../core/constants/app_icons.dart';
import '../../models/category_model.dart';
import '../../services/category/category_service.dart';
import '../../services/category/category_localization_service.dart';
import '../../services/category/category_filter_service.dart';
import '../../services/language_helper_service.dart';
import '../../l10n/app_localizations.dart';
import 'add_category_screen.dart';
import 'category_images_screen.dart';

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
  bool _showOnlyUserLanguage = true; // Toggle filter

  @override
  void initState() {
    super.initState();
    _loadCategories();
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
    final mq = MediaQuery.of(context);
    final width = mq.size.width;

    // Responsive breakpoints
    final bool isTablet =
        width >= Breakpoints.tabletMin && width < Breakpoints.desktopMin;
    final bool isDesktop = width >= Breakpoints.desktopMin;

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
          AppLocalizations.of(context).categoryManagement,
          style: GoogleFonts.inter(
            fontSize: isTablet ? 22.sp : 20.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          // Language filter toggle
          IconButton(
            icon: Icon(
              _showOnlyUserLanguage ? Icons.language : Icons.language_outlined,
              color: _showOnlyUserLanguage
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
            ),
            onPressed: _toggleLanguageFilter,
            tooltip: _showOnlyUserLanguage
                ? AppLocalizations.of(context).showingOnlyYourLanguage
                : AppLocalizations.of(context).showingAllLanguages,
          ),
          // Add button
          IconButton(
            icon: const Icon(Icons.add_circle, color: AppColors.textPrimary),
            onPressed: _navigateToAddCategory,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.textPrimary),
            )
          : _filteredCategories.isEmpty
              ? _buildEmptyState(isTablet, isDesktop)
              : _buildCategoryList(isTablet, isDesktop),
    );
  }

  Widget _buildEmptyState(bool isTablet, bool isDesktop) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.category_outlined,
            size: isTablet ? 80.sp : 64.sp,
            color: AppColors.greyMedium,
          ),
          SizedBox(height: 16.h),
          Text(
            AppLocalizations.of(context).noCategoriesYet,
            style: GoogleFonts.inter(
              fontSize: isTablet ? 20.sp : 18.sp,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            AppLocalizations.of(context).addFirstCategory,
            style: GoogleFonts.inter(
              fontSize: isTablet ? 16.sp : 14.sp,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 24.h),
          ElevatedButton.icon(
            onPressed: _navigateToAddCategory,
            icon: const Icon(Icons.add),
            label: Text(AppLocalizations.of(context).addNewCategory),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.textPrimary,
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

  Widget _buildCategoryList(bool isTablet, bool isDesktop) {
    return ListView.builder(
      padding: EdgeInsets.all(isTablet ? 24.w : 20.w),
      itemCount: _filteredCategories.length,
      itemBuilder: (context, index) {
        final category = _filteredCategories[index];
        return _buildCategoryCard(category, isTablet, isDesktop);
      },
    );
  }

  Widget _buildCategoryCard(
      CategoryModel category, bool isTablet, bool isDesktop) {
    return FutureBuilder<String>(
      future: CategoryLocalizationService.getLocalizedNameAuto(category),
      builder: (context, snapshot) {
        final localizedName = snapshot.data ?? category.getName('en');

        return Container(
          margin: EdgeInsets.only(bottom: 16.h),
          padding: EdgeInsets.all(isTablet ? 20.w : 16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.greyBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
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
                      AppColors.textPrimary,
                      AppColors.textPrimary.withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Padding(
                  padding: EdgeInsets.all(12.w),
                  child: Lottie.asset(
                    AppIcons.getAnimationPath(
                      AppIcons.getIconByName(category.iconName)?['path'] ??
                          'meditation.json',
                    ),
                    fit: BoxFit.contain,
                    repeat: true,
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
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        _buildLanguageBadges(category, isTablet),
                      ],
                    ),

                    SizedBox(height: 8.h),

                    // Metadata
                    Row(
                      children: [
                        // Session count
                        Icon(
                          Icons.play_circle_filled,
                          size: isTablet ? 18.sp : 16.sp,
                          color: AppColors.textPrimary,
                        ),
                        SizedBox(width: 4.w),
                        Flexible(
                          child: Text(
                            '${category.sessionCount} ${AppLocalizations.of(context).sessions}',
                            style: GoogleFonts.inter(
                              fontSize: isTablet ? 14.sp : 12.sp,
                              color: AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
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
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(width: 4.w),
                        Flexible(
                          child: Text(
                            '${category.backgroundImages.length} ${AppLocalizations.of(context).images}',
                            style: GoogleFonts.inter(
                              fontSize: isTablet ? 14.sp : 12.sp,
                              color: AppColors.textSecondary,
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
                      color: AppColors.textPrimary,
                      size: isTablet ? 24.sp : 22.sp,
                    ),
                    tooltip: AppLocalizations.of(context).manageImages,
                  ),
                  // Edit button
                  IconButton(
                    onPressed: () => _navigateToEditCategory(category),
                    icon: Icon(
                      Icons.edit,
                      color: AppColors.textPrimary,
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

  Widget _buildLanguageBadges(CategoryModel category, bool isTablet) {
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
              color: AppColors.textSecondary,
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
