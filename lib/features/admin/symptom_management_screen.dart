// lib/features/admin/symptom_management_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../models/symptom_model.dart';
import '../../services/symptom_service.dart';
import '../../l10n/app_localizations.dart';
import 'add_symptom_screen.dart';

class SymptomManagementScreen extends StatefulWidget {
  const SymptomManagementScreen({super.key});

  @override
  State<SymptomManagementScreen> createState() =>
      _SymptomManagementScreenState();
}

class _SymptomManagementScreenState extends State<SymptomManagementScreen> {
  final SymptomService _symptomService = SymptomService();

  List<SymptomModel> _symptoms = [];
  bool _isLoading = true;
  String _selectedCategory = 'all'; // all, physical, mental, emotional

  @override
  void initState() {
    super.initState();
    _loadSymptoms();
  }

  Future<void> _loadSymptoms() async {
    setState(() => _isLoading = true);

    try {
      final symptoms = await _symptomService.getAllSymptoms(forceRefresh: true);

      if (mounted) {
        setState(() {
          _symptoms = symptoms;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context).errorLoadingData}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<SymptomModel> get _filteredSymptoms {
    if (_selectedCategory == 'all') {
      return _symptoms;
    }
    return _symptoms.where((s) => s.category == _selectedCategory).toList();
  }

  Future<void> _deleteSymptom(SymptomModel symptom) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).deleteSymptom),
        content: Text(
          '${AppLocalizations.of(context).deleteSymptomConfirm} "${symptom.getLocalizedName('en')}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child:  Text(AppLocalizations.of(context).delete),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _symptomService.deleteSymptom(symptom.id);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
              content: Text(AppLocalizations.of(context).symptomDeletedSuccessfully),
              backgroundColor: Colors.green,
            ),
          );
          _loadSymptoms();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).errorDeletingData),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _navigateToAddEdit({SymptomModel? symptom}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddSymptomScreen(symptomToEdit: symptom),
      ),
    );

    if (result == true) {
      _loadSymptoms();
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
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context).manageSymptoms,
          style: GoogleFonts.inter(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
            onPressed: _loadSymptoms,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Category Filter
                _buildCategoryFilter(),

                // Symptom List
                Expanded(
                  child: _filteredSymptoms.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: EdgeInsets.all(20.w),
                          itemCount: _filteredSymptoms.length,
                          itemBuilder: (context, index) {
                            final symptom = _filteredSymptoms[index];
                            return _buildSymptomCard(symptom);
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddEdit(),
        backgroundColor: AppColors.primaryGold,
        icon: const Icon(Icons.add),
        label: Text(AppLocalizations.of(context).addSymptom),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(
                'all', AppLocalizations.of(context).all, Icons.apps),
            SizedBox(width: 8.w),
            _buildFilterChip('physical', AppLocalizations.of(context).physical,
                Icons.fitness_center),
            SizedBox(width: 8.w),
            _buildFilterChip('mental', AppLocalizations.of(context).mental,
                Icons.psychology),
            SizedBox(width: 8.w),
            _buildFilterChip('emotional',
                AppLocalizations.of(context).emotional, Icons.favorite),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String category, String label, IconData icon) {
    final isSelected = _selectedCategory == category;

    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16.sp),
          SizedBox(width: 4.w),
          Text(label),
        ],
      ),
      onSelected: (selected) {
        setState(() => _selectedCategory = category);
      },
      selectedColor: AppColors.primaryGold.withOpacity(0.2),
      checkmarkColor: AppColors.primaryGold,
    );
  }

  Widget _buildSymptomCard(SymptomModel symptom) {
    return Card(
      margin: EdgeInsets.only(bottom: 16.h),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                color: _getCategoryColor(symptom.category).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              alignment: Alignment.center,
              child: Text(
                symptom.icon,
                style: TextStyle(fontSize: 24.sp),
              ),
            ),

            SizedBox(width: 16.w),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    symptom.getLocalizedName('en'),
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(symptom.category)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          symptom.category.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                            color: _getCategoryColor(symptom.category),
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        '${AppLocalizations.of(context).displayOrder}: ${symptom.order}',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'TR: ${symptom.getLocalizedName('tr')}',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Actions
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: AppColors.primaryGold),
                  onPressed: () => _navigateToAddEdit(symptom: symptom),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteSymptom(symptom),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.psychology_outlined,
            size: 80.sp,
            color: Colors.grey[300],
          ),
          SizedBox(height: 16.h),
          Text(
            AppLocalizations.of(context).noSymptomsFound,
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            AppLocalizations.of(context).tapToAddSymptom,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'physical':
        return Colors.blue;
      case 'mental':
        return Colors.purple;
      case 'emotional':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }
}
