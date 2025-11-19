// lib/features/admin/disease_cause_management_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../models/disease_cause_model.dart';
import '../../models/disease_model.dart';
import '../../services/disease/disease_cause_service.dart';
import '../../services/disease/disease_service.dart';
import '../../l10n/app_localizations.dart';
import 'add_disease_cause_screen.dart';

class DiseaseCauseManagementScreen extends StatefulWidget {
  const DiseaseCauseManagementScreen({super.key});

  @override
  State<DiseaseCauseManagementScreen> createState() =>
      _DiseaseCauseManagementScreenState();
}

class _DiseaseCauseManagementScreenState
    extends State<DiseaseCauseManagementScreen> {
  final DiseaseCauseService _causeService = DiseaseCauseService();
  final DiseaseService _diseaseService = DiseaseService();

  List<DiseaseCauseModel> _causes = [];
  Map<String, DiseaseModel> _diseasesById = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load diseases first
      final diseases = await _diseaseService.getAllDiseases(forceRefresh: true);
      _diseasesById = {for (var s in diseases) s.id: s};

      // Load disease causes
      final causes =
          await _causeService.getAllDiseaseCauses(forceRefresh: true);

      if (mounted) {
        setState(() {
          _causes = causes;
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

  Future<void> _deleteCause(DiseaseCauseModel cause) async {
    final disease = _diseasesById[cause.diseaseId];
    final diseaseName =
        disease?.getLocalizedName('en') ?? AppLocalizations.of(context).unknown;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).deleteDiseaseCause),
        content: Text(
            '${AppLocalizations.of(context).deleteDiseaseCauseConfirm} "$diseaseName"?'),
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
      final success = await _causeService.deleteDiseaseCause(cause.id);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  AppLocalizations.of(context).diseaseCauseDeletedSuccessfully),
              backgroundColor: Colors.green,
            ),
          );
          _loadData();
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

  Future<void> _navigateToAddEdit({DiseaseCauseModel? cause}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddDiseaseCauseScreen(causeToEdit: cause),
      ),
    );

    if (result == true) {
      _loadData();
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
          AppLocalizations.of(context).manageDiseaseCauses,
          style: GoogleFonts.inter(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _causes.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: EdgeInsets.all(20.w),
                  itemCount: _causes.length,
                  itemBuilder: (context, index) {
                    final cause = _causes[index];
                    return _buildCauseCard(cause);
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddEdit(),
        backgroundColor: AppColors.primaryGold,
        icon: const Icon(Icons.add),
        label: Text(AppLocalizations.of(context).addDiseaseCause),
      ),
    );
  }

  Widget _buildCauseCard(DiseaseCauseModel cause) {
    final disease = _diseasesById[cause.diseaseId];
    final diseaseName = disease?.getLocalizedName('en') ??
        AppLocalizations.of(context).unknownDisease;

    return Card(
      margin: EdgeInsets.only(bottom: 16.h),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Gender badge
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: disease?.gender == 'male'
                        ? Colors.blue.withOpacity(0.1)
                        : Colors.pink.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    disease?.gender == 'male'
                        ? AppLocalizations.of(context).male.toUpperCase()
                        : AppLocalizations.of(context).female.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w700,
                      color: disease?.gender == 'male'
                          ? Colors.blue[700]
                          : Colors.pink[700],
                    ),
                  ),
                ),

                SizedBox(width: 12.w),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${AppLocalizations.of(context).forDisease} $diseaseName',
                        style: GoogleFonts.inter(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '${AppLocalizations.of(context).recommendsSession} №${cause.sessionNumber}',
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Actions
                Column(
                  children: [
                    IconButton(
                      icon:
                          const Icon(Icons.edit, color: AppColors.primaryGold),
                      onPressed: () => _navigateToAddEdit(cause: cause),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteCause(cause),
                    ),
                  ],
                ),
              ],
            ),

            SizedBox(height: 12.h),

            // Content Preview
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                cause.getLocalizedContent('en'),
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
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
            Icons.medical_information_outlined,
            size: 80.sp,
            color: Colors.grey[300],
          ),
          SizedBox(height: 16.h),
          Text(
            AppLocalizations.of(context).noDiseaseCausesFound,
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            AppLocalizations.of(context).tapToAddDiseaseCause,
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
