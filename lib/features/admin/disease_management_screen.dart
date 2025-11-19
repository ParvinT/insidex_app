// lib/features/admin/disease_management_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/responsive/context_ext.dart';
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
  String _selectedGender = 'all';

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
    var diseases = _selectedGender == 'all'
        ? _diseases
        : _diseases.where((s) => s.gender == _selectedGender).toList();

    diseases.sort((a, b) {
      final nameA = a.getLocalizedName('en').toLowerCase();
      final nameB = b.getLocalizedName('en').toLowerCase();
      return nameA.compareTo(nameB);
    });

    return diseases;
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
                _buildGenderFilter(),

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

  Widget _buildGenderFilter() {
    final isTablet = context.isTablet;
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      child: Row(
        children: [
          _buildFilterChip('all', l10n.all, isTablet),
          SizedBox(width: 10.w),
          _buildFilterChip('male', l10n.male, isTablet),
          SizedBox(width: 10.w),
          _buildFilterChip('female', l10n.female, isTablet),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, bool isTablet) {
    final isSelected = _selectedGender == value;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedGender = value);
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 18.w : 16.w,
          vertical: isTablet ? 10.h : 8.h,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGold : Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected ? AppColors.primaryGold : AppColors.greyBorder,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: isTablet ? 14.sp : 13.sp,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
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
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Disease name (English)
                  Text(
                    disease.getLocalizedName('en'),
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8.h),

                  // Gender badge
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: disease.gender == 'male'
                          ? Colors.blue.withOpacity(0.1)
                          : Colors.pink.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      disease.gender == 'male'
                          ? AppLocalizations.of(context).male.toUpperCase()
                          : AppLocalizations.of(context).female.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                        color: disease.gender == 'male'
                            ? Colors.blue[700]
                            : Colors.pink[700],
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),

                  SizedBox(height: 8.h),

                  // Turkish translation
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
}
