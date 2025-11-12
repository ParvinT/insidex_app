// lib/features/admin/add_disease_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_languages.dart';
import '../../models/disease_model.dart';
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

  late TabController _tabController;

  // Controllers for each language
  final Map<String, TextEditingController> _nameControllers = {};

  // Other fields

  final TextEditingController _orderController = TextEditingController();
  String _selectedCategory = 'physical';

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

    // Load existing data if editing
    if (widget.diseaseToEdit != null) {
      _loadExistingData();
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

    _orderController.text = disease.order.toString();
    _selectedCategory = disease.category;

    setState(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameControllers.values.forEach((controller) => controller.dispose());
    _orderController.dispose();
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
        throw Exception('English name is required');
      }

      // Create disease model
      final disease = DiseaseModel(
        id: widget.diseaseToEdit?.id ?? '',
        category: _selectedCategory,
        order: int.tryParse(_orderController.text) ?? 0,
        icon: '',
        translations: translations,
        createdAt: widget.diseaseToEdit?.createdAt ?? DateTime.now(),
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
          throw Exception('Failed to save disease');
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
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.diseaseToEdit != null
              ? AppLocalizations.of(context).editDisease
              : AppLocalizations.of(context).addDisease,
          style: GoogleFonts.inter(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Tab Bar
            _buildTabBar(),

            // Form Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Language-specific fields
                    _buildLanguageFields(),

                    SizedBox(height: 24.h),

                    // Category
                    _buildCategoryDropdown(),

                    SizedBox(height: 16.h),

                    // Order
                    _buildOrderField(),

                    SizedBox(height: 32.h),

                    // Save Button
                    _buildSaveButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primaryGold,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primaryGold,
        tabs: AppLanguages.supportedLanguages.map((langCode) {
          return Tab(
            text: AppLanguages.getLabel(langCode),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLanguageFields() {
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

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context).diseaseCategory,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
      items: [
        DropdownMenuItem(
          value: 'physical',
          child: Text(AppLocalizations.of(context).physical),
        ),
        DropdownMenuItem(
          value: 'mental',
          child: Text(AppLocalizations.of(context).mental),
        ),
        DropdownMenuItem(
          value: 'emotional',
          child: Text(AppLocalizations.of(context).emotional),
        ),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() => _selectedCategory = value);
        }
      },
      validator: (value) {
        if (value == null)
          return AppLocalizations.of(context).pleaseSelectCategory;
        return null;
      },
    );
  }

  Widget _buildOrderField() {
    return TextFormField(
      controller: _orderController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context).displayOrder,
        hintText: '1',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        helperText: AppLocalizations.of(context).lowerNumbersFirst,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return AppLocalizations.of(context).orderRequired;
        }
        if (int.tryParse(value) == null) {
          return AppLocalizations.of(context).mustBeNumber;
        }
        return null;
      },
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50.h,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveDisease,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGold,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                widget.diseaseToEdit != null
                    ? AppLocalizations.of(context).updateDisease
                    : AppLocalizations.of(context).addDisease,
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
