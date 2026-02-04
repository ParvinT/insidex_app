// lib/features/admin/add_quiz_category_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/themes/app_theme_extension.dart';
import '../../core/constants/app_languages.dart';
import '../../models/quiz_category_model.dart';
import '../../features/quiz/services/quiz_category_service.dart';
import '../../l10n/app_localizations.dart';

class AddQuizCategoryScreen extends StatefulWidget {
  final QuizCategoryModel? categoryToEdit;

  const AddQuizCategoryScreen({
    super.key,
    this.categoryToEdit,
  });

  @override
  State<AddQuizCategoryScreen> createState() => _AddQuizCategoryScreenState();
}

class _AddQuizCategoryScreenState extends State<AddQuizCategoryScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final QuizCategoryService _categoryService = QuizCategoryService();

  late TabController _tabController;

  // Controllers for names
  final Map<String, TextEditingController> _nameControllers = {};

  // Fields
  String _selectedGender = 'both'; // 'male', 'female', 'both'
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: AppLanguages.supportedLanguages.length,
      vsync: this,
    );

    // Initialize controllers for each language
    for (var langCode in AppLanguages.supportedLanguages) {
      _nameControllers[langCode] = TextEditingController();
    }

    // Load existing data if editing
    if (widget.categoryToEdit != null) {
      _loadExistingData();
    }
  }

  void _loadExistingData() {
    final category = widget.categoryToEdit!;

    _selectedGender = category.gender;

    // Load names
    category.names.forEach((langCode, name) {
      if (_nameControllers.containsKey(langCode)) {
        _nameControllers[langCode]!.text = name;
      }
    });

    setState(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (var controller in _nameControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).pleaseFillAllFields),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Build names map
      final names = <String, String>{};
      _nameControllers.forEach((langCode, controller) {
        if (controller.text.trim().isNotEmpty) {
          names[langCode] = controller.text.trim();
        }
      });

      // Validate: at least English must be filled
      if (!names.containsKey('en') || names['en']!.isEmpty) {
        throw Exception(AppLocalizations.of(context).englishNameRequired);
      }

      // Create category model
      final category = QuizCategoryModel(
        id: widget.categoryToEdit?.id ?? '',
        gender: _selectedGender,
        names: names,
        createdAt: widget.categoryToEdit?.createdAt ?? DateTime.now(),
      );

      // Save to Firestore
      bool success;
      if (widget.categoryToEdit != null) {
        success = await _categoryService.updateCategory(
          widget.categoryToEdit!.id,
          category,
        );
      } else {
        final docId = await _categoryService.addCategory(category);
        success = docId != null;
      }

      if (mounted) {
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
          Navigator.pop(context);
        } else {
          throw Exception(AppLocalizations.of(context).failedToSaveCategory);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

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
          widget.categoryToEdit != null
              ? AppLocalizations.of(context).editCategory
              : AppLocalizations.of(context).addCategory,
          style: GoogleFonts.inter(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveCategory,
            child: _isLoading
                ? SizedBox(
                    width: 20.w,
                    height: 20.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.textPrimary,
                    ),
                  )
                : Text(
                    AppLocalizations.of(context).save,
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Selection
              _buildSectionTitle(AppLocalizations.of(context).icon, colors),
              SizedBox(height: 8.h),

              // Gender Selection
              _buildSectionTitle(AppLocalizations.of(context).gender, colors),
              SizedBox(height: 8.h),
              _buildGenderSelector(colors),

              SizedBox(height: 24.h),

              // Names Section
              _buildSectionTitle(AppLocalizations.of(context).names, colors),
              SizedBox(height: 8.h),
              _buildLanguageTabs(colors),

              SizedBox(height: 100.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, AppThemeExtension colors) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        color: colors.textSecondary,
      ),
    );
  }

  Widget _buildGenderSelector(AppThemeExtension colors) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: colors.backgroundElevated,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: colors.border.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          _buildGenderOption('male', AppLocalizations.of(context).male,
              Icons.male, Colors.blue, colors),
          SizedBox(width: 12.w),
          _buildGenderOption('female', AppLocalizations.of(context).female,
              Icons.female, Colors.pink, colors),
          SizedBox(width: 12.w),
          _buildGenderOption('both', AppLocalizations.of(context).both,
              Icons.people, Colors.purple, colors),
        ],
      ),
    );
  }

  Widget _buildGenderOption(
    String value,
    String label,
    IconData icon,
    Color accentColor,
    AppThemeExtension colors,
  ) {
    final isSelected = _selectedGender == value;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedGender = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            color: isSelected
                ? accentColor.withValues(alpha: 0.2)
                : colors.background,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: isSelected ? accentColor : colors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? accentColor : colors.textSecondary,
                size: 24.sp,
              ),
              SizedBox(height: 4.h),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? accentColor : colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageTabs(AppThemeExtension colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.backgroundElevated,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: colors.border.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: colors.textPrimary,
            unselectedLabelColor: colors.textSecondary,
            indicatorColor: colors.textPrimary,
            tabs: AppLanguages.supportedLanguages.map((langCode) {
              return Tab(
                text: AppLanguages.getName(langCode).toUpperCase(),
              );
            }).toList(),
          ),
          SizedBox(
            height: 100.h,
            child: TabBarView(
              controller: _tabController,
              children: AppLanguages.supportedLanguages.map((langCode) {
                return _buildLanguageField(langCode, colors);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageField(String langCode, AppThemeExtension colors) {
    final isRequired = langCode == 'en';

    return Padding(
      padding: EdgeInsets.all(16.w),
      child: TextFormField(
        controller: _nameControllers[langCode],
        style: GoogleFonts.inter(color: colors.textPrimary),
        decoration: InputDecoration(
          labelText:
              '${AppLocalizations.of(context).categoryName}${isRequired ? ' *' : ''}',
          labelStyle: GoogleFonts.inter(color: colors.textSecondary),
          hintText: AppLocalizations.of(context).categoryNameHint,
          hintStyle: GoogleFonts.inter(
              color: colors.textSecondary.withValues(alpha: 0.5)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: BorderSide(color: colors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: BorderSide(color: colors.textPrimary),
          ),
        ),
        validator: isRequired
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return AppLocalizations.of(context).englishNameRequired;
                }
                return null;
              }
            : null,
      ),
    );
  }
}
