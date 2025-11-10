// lib/features/admin/add_symptom_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_languages.dart';
import '../../models/symptom_model.dart';
import '../../services/symptom_service.dart';

class AddSymptomScreen extends StatefulWidget {
  final SymptomModel? symptomToEdit;

  const AddSymptomScreen({
    super.key,
    this.symptomToEdit,
  });

  @override
  State<AddSymptomScreen> createState() => _AddSymptomScreenState();
}

class _AddSymptomScreenState extends State<AddSymptomScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final SymptomService _symptomService = SymptomService();

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
    if (widget.symptomToEdit != null) {
      _loadExistingData();
    }
  }

  void _loadExistingData() {
    final symptom = widget.symptomToEdit!;

    // Load translations
    symptom.translations.forEach((langCode, name) {
      if (_nameControllers.containsKey(langCode)) {
        _nameControllers[langCode]!.text = name;
      }
    });

    // Load other fields
    
    _orderController.text = symptom.order.toString();
    _selectedCategory = symptom.category;

    setState(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameControllers.values.forEach((controller) => controller.dispose());
    _orderController.dispose();
    super.dispose();
  }

  Future<void> _saveSymptom() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
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

      // Create symptom model
      final symptom = SymptomModel(
        id: widget.symptomToEdit?.id ?? '',
        category: _selectedCategory,
        order: int.tryParse(_orderController.text) ?? 0,
        icon: '',
        translations: translations,
        createdAt: widget.symptomToEdit?.createdAt ?? DateTime.now(),
      );

      // Save to Firestore
      bool success;
      if (widget.symptomToEdit != null) {
        // Update
        success = await _symptomService.updateSymptom(
          widget.symptomToEdit!.id,
          symptom,
        );
      } else {
        // Create
        final docId = await _symptomService.addSymptom(symptom);
        success = docId != null;
      }

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.symptomToEdit != null
                    ? 'Symptom updated successfully'
                    : 'Symptom created successfully',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          throw Exception('Failed to save symptom');
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
          widget.symptomToEdit != null ? 'Edit Symptom' : 'Add Symptom',
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
                labelText: 'Symptom Name (${AppLanguages.getName(langCode)})',
                hintText: 'e.g., Poor Sleep Quality',
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
                  return 'English name is required';
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
        labelText: 'Category',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
      items: const [
        DropdownMenuItem(value: 'physical', child: Text('Physical')),
        DropdownMenuItem(value: 'mental', child: Text('Mental')),
        DropdownMenuItem(value: 'emotional', child: Text('Emotional')),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() => _selectedCategory = value);
        }
      },
      validator: (value) {
        if (value == null) return 'Please select a category';
        return null;
      },
    );
  }

 

  Widget _buildOrderField() {
    return TextFormField(
      controller: _orderController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'Display Order',
        hintText: '1',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        helperText: 'Lower numbers appear first',
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Order is required';
        }
        if (int.tryParse(value) == null) {
          return 'Must be a number';
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
        onPressed: _isLoading ? null : _saveSymptom,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGold,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                widget.symptomToEdit != null ? 'Update Symptom' : 'Add Symptom',
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
