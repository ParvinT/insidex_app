// lib/features/admin/disease_cause_management_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/themes/app_theme_extension.dart';
import '../../models/disease_cause_model.dart';
import '../../models/disease_model.dart';
import '../../services/disease/disease_cause_service.dart';
import '../../services/disease/disease_service.dart';
import '../../l10n/app_localizations.dart';
import 'add_disease_cause_screen.dart';
import 'widgets/admin_search_bar.dart';

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

  // Search
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  List<DiseaseCauseModel> get _filteredCauses {
    var causes = _causes;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      causes = causes.where((cause) {
        // Search by disease name
        final disease = _diseasesById[cause.diseaseId];
        if (disease != null) {
          final searchableNames = [
            disease.getLocalizedName('en'),
            disease.getLocalizedName('tr'),
            disease.getLocalizedName('ru'),
            disease.getLocalizedName('hi'),
          ];
          if (searchableNames
              .any((name) => name.toLowerCase().contains(query))) {
            return true;
          }
        }

        // Search by session number
        if (cause.sessionNumber.toString().contains(query)) return true;

        // Search by content
        final searchableContent = [
          cause.getLocalizedContent('en'),
          cause.getLocalizedContent('tr'),
          cause.getLocalizedContent('ru'),
          cause.getLocalizedContent('hi'),
        ];
        if (searchableContent
            .any((content) => content.toLowerCase().contains(query))) {
          return true;
        }

        return false;
      }).toList();
    }

    return causes;
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
          AppLocalizations.of(context).manageDiseaseCauses,
          style: GoogleFonts.inter(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: colors.textPrimary),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colors.textPrimary))
          : Column(
              children: [
                // Search Bar
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
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

                // Cause List
                Expanded(
                  child: _filteredCauses.isEmpty
                      ? _buildEmptyState(colors)
                      : ListView.builder(
                          padding: EdgeInsets.all(20.w),
                          itemCount: _filteredCauses.length,
                          itemBuilder: (context, index) {
                            final cause = _filteredCauses[index];
                            return _buildCauseCard(cause, colors);
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddEdit(),
        backgroundColor: colors.textPrimary,
        foregroundColor: colors.textOnPrimary,
        icon: const Icon(Icons.add),
        label: Text(AppLocalizations.of(context).addDiseaseCause),
      ),
    );
  }

  Widget _buildCauseCard(DiseaseCauseModel cause, AppThemeExtension colors) {
    final disease = _diseasesById[cause.diseaseId];
    final diseaseName = disease?.getLocalizedName('en') ??
        AppLocalizations.of(context).unknownDisease;

    return Card(
      margin: EdgeInsets.only(bottom: 16.h),
      elevation: 2,
      color: colors.backgroundPure,
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
                        ? Colors.blue.withValues(alpha: 0.1)
                        : Colors.pink.withValues(alpha: 0.1),
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
                          color: colors.textPrimary,
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
                      icon: Icon(Icons.edit, color: colors.textPrimary),
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
                color: colors.greyLight,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                cause.getLocalizedContent('en'),
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: colors.textSecondary,
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

  Widget _buildEmptyState(AppThemeExtension colors) {
    final isSearching = _searchQuery.isNotEmpty;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearching
                ? Icons.search_off_rounded
                : Icons.medical_information_outlined,
            size: 80.sp,
            color: colors.greyMedium,
          ),
          SizedBox(height: 16.h),
          Text(
            isSearching
                ? AppLocalizations.of(context).noResultsFound
                : AppLocalizations.of(context).noDiseaseCausesFound,
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            isSearching
                ? AppLocalizations.of(context).tryDifferentKeywords
                : AppLocalizations.of(context).tapToAddDiseaseCause,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
