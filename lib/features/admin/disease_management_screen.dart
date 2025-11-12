// lib/features/admin/disease_management_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../models/disease_model.dart';
import '../../services/disease/disease_service.dart';
import '../../l10n/app_localizations.dart';
import 'add_disease_screen.dart';

class DiseaseManagementScreen extends StatefulWidget {
  const DiseaseManagementScreen({super.key});

  @override
  State<DiseaseManagementScreen> createState() =>
      _DiseaseManagementScreenState();
}

class _DiseaseManagementScreenState extends State<DiseaseManagementScreen> {
  final DiseaseService _diseaseService = DiseaseService();

  List<DiseaseModel> _diseases = [];
  bool _isLoading = true;
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    _loadDiseases();
  }

  Future<void> _loadDiseases() async {
    setState(() => _isLoading = true);

    try {
      final diseases = await _diseaseService.getAllDiseases(forceRefresh: true);

      if (mounted) {
        setState(() {
          _diseases = diseases;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('${AppLocalizations.of(context).errorLoadingData}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<DiseaseModel> get _filteredDiseases {
    if (_selectedCategory == 'all') {
      return _diseases;
    }
    return _diseases.where((s) => s.category == _selectedCategory).toList();
  }

  Future<void> _deleteDisease(DiseaseModel disease) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).deleteDisease),
        content: Text(
          '${AppLocalizations.of(context).deleteDiseaseConfirm} "${disease.getLocalizedName('en')}"?',
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
      final success = await _diseaseService.deleteDisease(disease.id);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(AppLocalizations.of(context).diseaseDeletedSuccessfully),
              backgroundColor: Colors.green,
            ),
          );
          _loadDiseases();
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

  Future<void> _navigateToAddEdit({DiseaseModel? disease}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddDiseaseScreen(diseaseToEdit: disease),
      ),
    );

    if (result == true) {
      _loadDiseases();
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
          AppLocalizations.of(context).manageDiseases,
          style: GoogleFonts.inter(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
            onPressed: _loadDiseases,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Category Filter
                _buildCategoryFilter(),

                // Disease List
                Expanded(
                  child: _filteredDiseases.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: EdgeInsets.all(20.w),
                          itemCount: _filteredDiseases.length,
                          itemBuilder: (context, index) {
                            final disease = _filteredDiseases[index];
                            return _buildDiseaseCard(disease);
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddEdit(),
        backgroundColor: AppColors.primaryGold,
        icon: const Icon(Icons.add),
        label: Text(AppLocalizations.of(context).addDisease),
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

  Widget _buildDiseaseCard(DiseaseModel disease) {
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
                color: _getCategoryColor(disease.category).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              alignment: Alignment.center,
              child: Text(
                disease.icon,
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
                    disease.getLocalizedName('en'),
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
                          color: _getCategoryColor(disease.category)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          disease.category.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                            color: _getCategoryColor(disease.category),
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        '${AppLocalizations.of(context).displayOrder}: ${disease.order}',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'TR: ${disease.getLocalizedName('tr')}',
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
                  onPressed: () => _navigateToAddEdit(disease: disease),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteDisease(disease),
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
            AppLocalizations.of(context).noDiseasesFound,
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            AppLocalizations.of(context).tapToAddDisease,
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
