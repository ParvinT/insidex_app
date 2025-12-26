// lib/features/admin/add_disease_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/themes/app_theme_extension.dart';
import '../../core/constants/app_languages.dart';
import '../../models/disease_model.dart';
import '../../models/quiz_category_model.dart';
import '../../features/quiz/services/quiz_category_service.dart';
import '../../services/disease/disease_service.dart';
import '../../l10n/app_localizations.dart';

class AddDiseaseScreen extends StatefulWidget {
  final DiseaseModel? diseaseToEdit;

  const AddDiseaseScreen({
    super.key,
    this.diseaseToEdit,
  });

  @override
  State<AddDiseaseScreen> createState() => _AddDiseaseScreenState();
}

class _AddDiseaseScreenState extends State<AddDiseaseScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final DiseaseService _diseaseService = DiseaseService();
  final QuizCategoryService _categoryService = QuizCategoryService();

  late TabController _tabController;

  // Controllers for each language
  final Map<String, TextEditingController> _nameControllers = {};

  // Other fields

  String _selectedGender = 'male';
  String? _selectedCategoryId;
  List<QuizCategoryModel> _categories = [];
  bool _isLoadingCategories = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Initialize tab controller
    _tabController = TabController(
      length: AppLanguages.supportedLanguages.length,
      vsync: this,
    );

    // Initialize controllers for each language
    for (var langCode in AppLanguages.supportedLanguages) {
      _nameControllers[langCode] = TextEditingController();
    }

    _loadCategories();

    // Load existing data if editing
    if (widget.diseaseToEdit != null) {
      _loadExistingData();
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _categoryService.getAllCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingCategories = false);
      }
    }
  }

  void _loadExistingData() {
    final disease = widget.diseaseToEdit!;

    // Load translations
    disease.translations.forEach((langCode, name) {
      if (_nameControllers.containsKey(langCode)) {
        _nameControllers[langCode]!.text = name;
      }
    });

    // Load other fields
    _selectedGender = disease.gender;
    _selectedCategoryId = disease.categoryId;

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

  Future<void> _saveDisease() async {
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
      // Build translations map
      final translations = <String, String>{};
      _nameControllers.forEach((langCode, controller) {
        if (controller.text.trim().isNotEmpty) {
          translations[langCode] = controller.text.trim();
        }
      });

      // Validate: at least English must be filled
      if (!translations.containsKey('en') || translations['en']!.isEmpty) {
        throw Exception(AppLocalizations.of(context).englishNameRequired);
      }

      // Create disease model
      final disease = DiseaseModel(
        id: widget.diseaseToEdit?.id ?? '',
        gender: _selectedGender,
        translations: translations,
        createdAt: widget.diseaseToEdit?.createdAt ?? DateTime.now(),
        categoryId: _selectedCategoryId,
      );

      // Save to Firestore
      bool success;
      if (widget.diseaseToEdit != null) {
        // Update
        success = await _diseaseService.updateDisease(
          widget.diseaseToEdit!.id,
          disease,
        );
      } else {
        // Create
        final docId = await _diseaseService.addDisease(disease);
        success = docId != null;
      }

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.diseaseToEdit != null
                    ? AppLocalizations.of(context).diseaseUpdatedSuccessfully
                    : AppLocalizations.of(context).diseaseCreatedSuccessfully,
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          throw Exception(AppLocalizations.of(context).failedToSaveDisease);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('${AppLocalizations.of(context).errorSavingData}: $e'),
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
          icon: Icon(Icons.close, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.diseaseToEdit != null
              ? AppLocalizations.of(context).editDisease
              : AppLocalizations.of(context).addDisease,
          style: GoogleFonts.inter(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Tab Bar
            _buildTabBar(colors),

            // Form Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Language-specific fields
                    _buildLanguageFields(colors),

                    SizedBox(height: 24.h),

                    _buildGenderDropdown(colors),

                    SizedBox(height: 32.h),

                    Text(
                      AppLocalizations.of(context).category,
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: colors.textSecondary,
                      ),
                    ),
                    _buildCategoryDropdown(colors),

                    SizedBox(height: 32.h),

                    // Save Button
                    _buildSaveButton(colors),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar(AppThemeExtension colors) {
    return Container(
      color: colors.backgroundPure,
      child: TabBar(
        controller: _tabController,
        labelColor: colors.textPrimary,
        unselectedLabelColor: colors.textSecondary,
        indicatorColor: colors.textPrimary,
        tabs: AppLanguages.supportedLanguages.map((langCode) {
          return Tab(
            text: AppLanguages.getLabel(langCode),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLanguageFields(AppThemeExtension colors) {
    return SizedBox(
      height: 120.h,
      child: TabBarView(
        controller: _tabController,
        children: AppLanguages.supportedLanguages.map((langCode) {
          return Padding(
            padding: EdgeInsets.only(top: 16.h),
            child: TextFormField(
              controller: _nameControllers[langCode],
              decoration: InputDecoration(
                labelText:
                    '${AppLocalizations.of(context).diseaseName} (${AppLanguages.getName(langCode)})',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                prefixIcon: Text(
                  AppLanguages.getFlag(langCode),
                  style: TextStyle(fontSize: 20.sp),
                ),
                prefixIconConstraints: BoxConstraints(minWidth: 48.w),
              ),
              validator: (value) {
                // Only English is required
                if (langCode == 'en' &&
                    (value == null || value.trim().isEmpty)) {
                  return AppLocalizations.of(context).englishNameRequired;
                }
                return null;
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGenderDropdown(AppThemeExtension colors) {
    return DropdownButtonFormField<String>(
      value: _selectedGender,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context).gender,
        hintText: AppLocalizations.of(context).selectGender,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
      items: [
        DropdownMenuItem(
          value: 'male',
          child: Text(AppLocalizations.of(context).male),
        ),
        DropdownMenuItem(
          value: 'female',
          child: Text(AppLocalizations.of(context).female),
        ),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() => _selectedGender = value);
        }
      },
      validator: (value) {
        if (value == null) {
          return AppLocalizations.of(context).pleaseSelectGender;
        }
        return null;
      },
    );
  }

  Widget _buildSaveButton(AppThemeExtension colors) {
    return SizedBox(
      width: double.infinity,
      height: 60.h,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveDisease,
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.textPrimary,
          foregroundColor: colors.textOnPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: _isLoading
            ? CircularProgressIndicator(color: colors.textOnPrimary)
            : Text(
                widget.diseaseToEdit != null
                    ? AppLocalizations.of(context).updateDisease
                    : AppLocalizations.of(context).addDisease,
                style: GoogleFonts.inter(
                  fontSize: 16.sp.clamp(12.0, 18.0),
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
      ),
    );
  }

  Widget _buildCategoryDropdown(AppThemeExtension colors) {
    if (_isLoadingCategories) {
      return Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: colors.backgroundElevated,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: colors.border.withValues(alpha: 0.3)),
        ),
        child: Center(
          child: SizedBox(
            width: 20.w,
            height: 20.w,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colors.textPrimary,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: colors.backgroundElevated,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: colors.border.withValues(alpha: 0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: _selectedCategoryId,
          hint: Text(
            AppLocalizations.of(context).selectCategoryOptional,
            style: GoogleFonts.inter(color: colors.textSecondary),
          ),
          isExpanded: true,
          dropdownColor: colors.backgroundElevated,
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            color: colors.textPrimary,
          ),
          items: [
            // None option
            DropdownMenuItem<String?>(
              value: null,
              child: Text(
                AppLocalizations.of(context).noCategory,
                style: GoogleFonts.inter(color: colors.textSecondary),
              ),
            ),
            // Category options
            ..._categories.map((category) {
              return DropdownMenuItem<String?>(
                value: category.id,
                child: Text(
                  category.getName('en'),
                  style: GoogleFonts.inter(color: colors.textPrimary),
                ),
              );
            }),
          ],
          onChanged: (value) {
            setState(() => _selectedCategoryId = value);
          },
        ),
      ),
    );
  }
}
