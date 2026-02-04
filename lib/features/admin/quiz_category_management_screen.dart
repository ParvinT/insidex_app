// lib/features/admin/quiz_category_management_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/responsive/context_ext.dart';
import '../../core/themes/app_theme_extension.dart';
import '../../models/quiz_category_model.dart';
import '../../features/quiz/services/quiz_category_service.dart';
import '../../l10n/app_localizations.dart';
import 'add_quiz_category_screen.dart';
import 'widgets/admin_search_bar.dart';

class QuizCategoryManagementScreen extends StatefulWidget {
  const QuizCategoryManagementScreen({super.key});

  @override
  State<QuizCategoryManagementScreen> createState() =>
      _QuizCategoryManagementScreenState();
}

class _QuizCategoryManagementScreenState
    extends State<QuizCategoryManagementScreen> {
  final QuizCategoryService _categoryService = QuizCategoryService();

  List<QuizCategoryModel> _categories = [];
  Map<String, int> _maleCounts = {};
  Map<String, int> _femaleCounts = {};
  bool _isLoading = true;

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
      final maleCounts =
          await _categoryService.getCategoryDiseaseCounts('male');
      final femaleCounts =
          await _categoryService.getCategoryDiseaseCounts('female');

      // Sort alphabetically by English name
      categories.sort((a, b) {
        final nameA = a.getName('en').toLowerCase();
        final nameB = b.getName('en').toLowerCase();
        return nameA.compareTo(nameB);
      });

      if (mounted) {
        setState(() {
          _categories = categories;
          _maleCounts = maleCounts;
          _femaleCounts = femaleCounts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${AppLocalizations.of(context).errorLoadingCategories}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteCategory(QuizCategoryModel category) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).deleteCategory),
        content: Text(
          AppLocalizations.of(context)
              .deleteCategoryWithDiseaseNote(category.getName('en')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context).delete),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _categoryService.deleteCategory(category.id);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  AppLocalizations.of(context).categoryDeletedSuccessfully),
              backgroundColor: Colors.green,
            ),
          );
          _loadCategories();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(AppLocalizations.of(context).failedToDeleteCategory),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _navigateToAddCategory({QuizCategoryModel? category}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddQuizCategoryScreen(
          categoryToEdit: category,
        ),
      ),
    ).then((_) => _loadCategories());
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isTablet = context.isTablet;

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
          AppLocalizations.of(context).quizCategories,
          style: GoogleFonts.inter(
            fontSize: isTablet ? 22.sp : 20.sp,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: colors.textPrimary),
            onPressed: _loadCategories,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddCategory(),
        backgroundColor: colors.textPrimary,
        icon: Icon(Icons.add, color: colors.textOnPrimary),
        label: Text(
          AppLocalizations.of(context).addCategory,
          style: GoogleFonts.inter(
            color: colors.textOnPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
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
                    child: CircularProgressIndicator(color: colors.textPrimary))
                : _categories.isEmpty
                    ? _buildEmptyState(colors)
                    : _buildCategoryList(colors, isTablet),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppThemeExtension colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.category_outlined,
            size: 80.sp,
            color: colors.textSecondary.withValues(alpha: 0.5),
          ),
          SizedBox(height: 16.h),
          Text(
            AppLocalizations.of(context).noCategoriesYet,
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            AppLocalizations.of(context).addYourFirstQuizCategory,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              color: colors.textSecondary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList(AppThemeExtension colors, bool isTablet) {
    // Apply search filter
    var displayCategories = _categories;

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      displayCategories = _categories.where((category) {
        // Search in all language names
        for (final name in category.names.values) {
          if (name.toLowerCase().contains(query)) return true;
        }
        return false;
      }).toList();
    }

    // Show empty search result
    if (displayCategories.isEmpty && _searchQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 80.sp,
              color: colors.textSecondary.withValues(alpha: 0.5),
            ),
            SizedBox(height: 16.h),
            Text(
              AppLocalizations.of(context).noResultsFound,
              style: GoogleFonts.inter(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              AppLocalizations.of(context).tryDifferentKeywords,
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                color: colors.textSecondary.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(isTablet ? 24.w : 16.w),
      itemCount: displayCategories.length,
      itemBuilder: (context, index) {
        final category = displayCategories[index];
        return _buildCategoryCard(
          category: category,
          colors: colors,
          isTablet: isTablet,
        );
      },
    );
  }

  Widget _buildCategoryCard({
    required QuizCategoryModel category,
    required AppThemeExtension colors,
    required bool isTablet,
  }) {
    final maleCount = _maleCounts[category.id] ?? 0;
    final femaleCount = _femaleCounts[category.id] ?? 0;
    final totalCount = maleCount + femaleCount;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: colors.backgroundElevated,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: colors.border.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToAddCategory(category: category),
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.all(isTablet ? 16.w : 12.w),
            child: Row(
              children: [
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name
                      Text(
                        category.getName('en'),
                        style: GoogleFonts.inter(
                          fontSize: isTablet ? 16.sp : 14.sp,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),

                      SizedBox(height: 6.h),

                      // Info row
                      Wrap(
                        spacing: 8.w,
                        runSpacing: 4.h,
                        children: [
                          // Gender badge
                          _buildGenderBadge(category.gender, colors, context),

                          // Disease count
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: colors.greyLight.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.quiz_outlined,
                                  size: 12.sp,
                                  color: colors.textSecondary,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  '$totalCount ${AppLocalizations.of(context).diseases}',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.sp,
                                    color: colors.textSecondary,
                                  ),
                                ),
                                if (totalCount > 0) ...[
                                  SizedBox(width: 4.w),
                                  Text(
                                    '(♂$maleCount ♀$femaleCount)',
                                    style: GoogleFonts.inter(
                                      fontSize: 10.sp,
                                      color: colors.textSecondary
                                          .withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Delete button
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: Colors.red.withValues(alpha: 0.7),
                    size: 20.sp,
                  ),
                  onPressed: () => _deleteCategory(category),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGenderBadge(
      String gender, AppThemeExtension colors, BuildContext context) {
    Color badgeColor;
    IconData icon;
    String label;

    switch (gender) {
      case 'male':
        badgeColor = Colors.blue;
        icon = Icons.male;
        label = AppLocalizations.of(context).male;
        break;
      case 'female':
        badgeColor = Colors.pink;
        icon = Icons.female;
        label = AppLocalizations.of(context).female;
        break;
      default:
        badgeColor = Colors.purple;
        icon = Icons.people;
        label = AppLocalizations.of(context).both;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 8.w,
        vertical: 2.h,
      ),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12.sp,
            color: badgeColor,
          ),
          SizedBox(width: 4.w),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              fontWeight: FontWeight.w500,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }
}
