// lib/features/admin/add_category_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_languages.dart';
import '../../core/responsive/breakpoints.dart';
import '../../models/category_model.dart';
import '../../services/category/category_service.dart';
import '../../core/constants/app_icons.dart';
import '../../l10n/app_localizations.dart';

class AddCategoryScreen extends StatefulWidget {
  final CategoryModel? categoryToEdit;

  const AddCategoryScreen({
    super.key,
    this.categoryToEdit,
  });

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final CategoryService _categoryService = CategoryService();

  // Multi-language name controllers (DYNAMIC)
  late final Map<String, TextEditingController> _nameControllers;

  // Selected values
  String _selectedIcon = 'meditation';
  String _selectedLanguage = AppLanguages.defaultLanguage;

  // Loading state
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Initialize controllers for each language
    _nameControllers = {
      for (final lang in AppLanguages.supportedLanguages)
        lang: TextEditingController()
    };

    // Load data if editing
    if (widget.categoryToEdit != null) {
      _loadExistingData();
    }
  }

  @override
  void dispose() {
    // Dispose all controllers
    _nameControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  void _loadExistingData() {
    final category = widget.categoryToEdit!;

    _selectedIcon = category.iconName;

    // Load names for each language
    category.names.forEach((lang, name) {
      if (_nameControllers.containsKey(lang)) {
        _nameControllers[lang]!.text = name;
      }
    });

    debugPrint('📝 Loaded category data for editing: ${category.id}');
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

    final double horizontalPadding =
        isDesktop ? 40.w : (isTablet ? 30.w : 20.w);
    final double verticalPadding = isDesktop ? 30.h : (isTablet ? 25.h : 20.h);

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
          widget.categoryToEdit != null
              ? AppLocalizations.of(context).editCategory
              : AppLocalizations.of(context).addNewCategory,
          style: GoogleFonts.inter(
            fontSize: isTablet ? 22.sp : 20.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon & Section
              _buildIconSection(isTablet, isDesktop),

              SizedBox(height: 30.h),

              // Multi-Language Names Section
              _buildMultiLanguageNamesSection(isTablet, isDesktop),

              SizedBox(height: 40.h),

              // Save Button
              _buildSaveButton(isTablet, isDesktop),

              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconSection(bool isTablet, bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 24.w : 20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.greyBorder),
      ),
      child: Row(
        children: [
          // ICon Selector
          GestureDetector(
            onTap: _showIconPicker,
            child: Container(
              width: isTablet ? 80.w : 70.w,
              height: isTablet ? 80.w : 70.w,
              decoration: BoxDecoration(
                color: AppColors.primaryGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: AppColors.primaryGold,
                  width: 2,
                ),
              ),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(18.w),
                  child: Lottie.asset(
                    AppIcons.getAnimationPath(
                      AppIcons.getIconByName(_selectedIcon)?['path'] ??
                          'meditation.json',
                    ),
                    fit: BoxFit.contain,
                    repeat: true,
                  ),
                ),
              ),
            ),
          ),

          SizedBox(width: 20.w),

          // Icon Description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).categoryIcon,
                  style: GoogleFonts.inter(
                    fontSize: isTablet ? 16.sp : 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  AppLocalizations.of(context).tapToChooseIcon,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiLanguageNamesSection(bool isTablet, bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 24.w : 20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.greyBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Text(
            '📝 ${AppLocalizations.of(context).categoryName} (${AppLocalizations.of(context).contentMultiLanguage})',
            style: GoogleFonts.inter(
              fontSize: isTablet ? 18.sp : 16.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),

          SizedBox(height: 20.h),

          // Language Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: AppLanguages.supportedLanguages.map((lang) {
                return Padding(
                  padding: EdgeInsets.only(right: 8.w),
                  child: _buildLanguageTab(lang, isTablet),
                );
              }).toList(),
            ),
          ),

          SizedBox(height: 24.h),

          // Language Indicator
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: AppColors.primaryGold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              '${AppLocalizations.of(context).editing}: ${AppLanguages.getFullLabel(_selectedLanguage)}',
              style: GoogleFonts.inter(
                fontSize: isTablet ? 14.sp : 12.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryGold,
              ),
            ),
          ),

          SizedBox(height: 16.h),

          // Name Input Field
          TextFormField(
            controller: _nameControllers[_selectedLanguage],
            decoration: InputDecoration(
              labelText:
                  '${AppLocalizations.of(context).categoryName} ($_selectedLanguage)',
              hintText: AppLocalizations.of(context).categoryNameHint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: const BorderSide(
                  color: AppColors.primaryGold,
                  width: 2,
                ),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 16.h,
              ),
            ),
            style: GoogleFonts.inter(fontSize: isTablet ? 16.sp : 14.sp),
          ),

          SizedBox(height: 12.h),

          // Helper Text
          Text(
            AppLocalizations.of(context).pleaseEnterTitleInOneLang,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageTab(String lang, bool isTablet) {
    final isSelected = _selectedLanguage == lang;
    final hasContent = _nameControllers[lang]!.text.trim().isNotEmpty;

    // Status colors
    Color borderColor;
    Color backgroundColor;
    Widget statusIcon;

    if (hasContent) {
      // Has content
      borderColor = Colors.green;
      backgroundColor =
          isSelected ? AppColors.primaryGold : Colors.green.shade50;
      statusIcon = Icon(Icons.check_circle,
          size: 16.sp, color: isSelected ? Colors.white : Colors.green);
    } else {
      // Empty
      borderColor = Colors.grey.shade300;
      backgroundColor =
          isSelected ? AppColors.primaryGold : Colors.grey.shade100;
      statusIcon = Icon(Icons.circle_outlined,
          size: 16.sp, color: isSelected ? Colors.white : Colors.grey);
    }

    return GestureDetector(
      onTap: () => setState(() => _selectedLanguage = lang),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 18.w : 16.w,
          vertical: isTablet ? 12.h : 10.h,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLanguages.getLabel(lang),
              style: GoogleFonts.inter(
                fontSize: isTablet ? 15.sp : 14.sp,
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            SizedBox(width: 6.w),
            statusIcon,
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton(bool isTablet, bool isDesktop) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveCategory,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGold,
          padding: EdgeInsets.symmetric(
            vertical: isTablet ? 18.h : 16.h,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? SizedBox(
                height: 20.h,
                width: 20.h,
                child: const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                widget.categoryToEdit != null
                    ? AppLocalizations.of(context).updateCategory
                    : AppLocalizations.of(context).addCategory,
                style: GoogleFonts.inter(
                  fontSize: isTablet ? 18.sp : 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  // =================== ACTIONS ===================

  void _showIconPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: 500.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.r),
            topRight: Radius.circular(20.r),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: 12.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),

            SizedBox(height: 20.h),

            // Title
            Text(
              AppLocalizations.of(context).selectIcon,
              style: GoogleFonts.inter(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),

            SizedBox(height: 20.h),

            // Icons Grid
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 20.h,
                  crossAxisSpacing: 20.w,
                  childAspectRatio: 0.9,
                ),
                itemCount: AppIcons.categoryIcons.length,
                itemBuilder: (context, index) {
                  final icon = AppIcons.categoryIcons[index];
                  final isSelected = icon['name'] == _selectedIcon;

                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedIcon = icon['name']!);
                      Navigator.pop(context);
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 100.w,
                          height: 100.w,
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? LinearGradient(
                                    colors: [
                                      AppColors.primaryGold,
                                      AppColors.primaryGold.withOpacity(0.7),
                                    ],
                                  )
                                : LinearGradient(
                                    colors: [
                                      Colors.grey.shade200,
                                      Colors.grey.shade300,
                                    ],
                                  ),
                            borderRadius: BorderRadius.circular(16.r),
                            border: isSelected
                                ? Border.all(
                                    color: AppColors.primaryGold,
                                    width: 3,
                                  )
                                : null,
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(20.w),
                            child: Lottie.asset(
                              AppIcons.getAnimationPath(icon['path']!),
                              fit: BoxFit.contain,
                              repeat: true,
                            ),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          icon['label']!,
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected
                                ? AppColors.primaryGold
                                : AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Collect names from all languages
    final names = <String, String>{};
    _nameControllers.forEach((lang, controller) {
      final name = controller.text.trim();
      if (name.isNotEmpty) {
        names[lang] = name;
      }
    });

    // Validate: at least one name must be provided
    if (names.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).pleaseEnterTitleInOneLang),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final category = CategoryModel(
        id: widget.categoryToEdit?.id ?? '',
        iconName: _selectedIcon,
        names: names,
        createdAt: widget.categoryToEdit?.createdAt,
        updatedAt: DateTime.now(),
        sessionCount: widget.categoryToEdit?.sessionCount ?? 0,
      );

      bool success;
      if (widget.categoryToEdit != null) {
        // Update existing
        success = await _categoryService.updateCategory(
          widget.categoryToEdit!.id,
          category,
        );
      } else {
        // Add new
        final id = await _categoryService.addCategory(category);
        success = id != null;
      }

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.categoryToEdit != null
                  ? AppLocalizations.of(context).categoryUpdatedSuccessfully
                  : AppLocalizations.of(context).categoryAddedSuccessfully,
            ),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context, true); // Return true to indicate success
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.categoryToEdit != null
                  ? AppLocalizations.of(context).errorUpdatingCategory
                  : AppLocalizations.of(context).errorAddingCategory,
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.of(context).errorOccurred}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
