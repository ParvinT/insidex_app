// lib/features/admin/emotional_map_management_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../models/emotional_map_model.dart';
import '../../models/symptom_model.dart';
import '../../services/emotional_map_service.dart';
import '../../services/symptom_service.dart';
import 'add_emotional_map_screen.dart';

class EmotionalMapManagementScreen extends StatefulWidget {
  const EmotionalMapManagementScreen({super.key});

  @override
  State<EmotionalMapManagementScreen> createState() =>
      _EmotionalMapManagementScreenState();
}

class _EmotionalMapManagementScreenState
    extends State<EmotionalMapManagementScreen> {
  final EmotionalMapService _mapService = EmotionalMapService();
  final SymptomService _symptomService = SymptomService();

  List<EmotionalMapModel> _maps = [];
  Map<String, SymptomModel> _symptomsById = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load symptoms first
      final symptoms = await _symptomService.getAllSymptoms(forceRefresh: true);
      _symptomsById = {for (var s in symptoms) s.id: s};

      // Load emotional maps
      final maps = await _mapService.getAllEmotionalMaps(forceRefresh: true);

      if (mounted) {
        setState(() {
          _maps = maps;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteMap(EmotionalMapModel map) async {
    final symptom = _symptomsById[map.symptomId];
    final symptomName = symptom?.getLocalizedName('en') ?? 'Unknown';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Emotional Map'),
        content: Text(
          'Are you sure you want to delete the emotional map for "$symptomName"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _mapService.deleteEmotionalMap(map.id);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Emotional map deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete emotional map'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _navigateToAddEdit({EmotionalMapModel? map}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEmotionalMapScreen(mapToEdit: map),
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
          'Emotional Map Management',
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
          : _maps.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: EdgeInsets.all(20.w),
                  itemCount: _maps.length,
                  itemBuilder: (context, index) {
                    final map = _maps[index];
                    return _buildMapCard(map);
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddEdit(),
        backgroundColor: AppColors.primaryGold,
        icon: const Icon(Icons.add),
        label: const Text('Add Emotional Map'),
      ),
    );
  }

  Widget _buildMapCard(EmotionalMapModel map) {
    final symptom = _symptomsById[map.symptomId];
    final symptomName = symptom?.getLocalizedName('en') ?? 'Unknown Symptom';
    final symptomIcon = symptom?.icon ?? '❓';

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
                // Symptom Icon
                Text(
                  symptomIcon,
                  style: TextStyle(fontSize: 32.sp),
                ),

                SizedBox(width: 12.w),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'For: $symptomName',
                        style: GoogleFonts.inter(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Recommends: Session №${map.sessionNumber}',
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
                      onPressed: () => _navigateToAddEdit(map: map),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteMap(map),
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
                map.getLocalizedContent('en'),
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
            Icons.map_outlined,
            size: 80.sp,
            color: Colors.grey[300],
          ),
          SizedBox(height: 16.h),
          Text(
            'No emotional maps found',
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Tap the + button to add an emotional map',
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
