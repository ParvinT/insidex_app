// lib/features/search/widgets/quiz_category_diseases_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/themes/app_theme_extension.dart';
import '../../../core/responsive/context_ext.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/disease_model.dart';
import '../../../models/quiz_category_model.dart';
import '../../../services/disease/disease_service.dart';
import '../../../services/disease/disease_cause_service.dart';
import '../../quiz/screens/quiz_results_screen.dart';

/// Bottom Sheet that displays diseases in a quiz category
/// Allows multi-selection and navigation to QuizResultsScreen
class QuizCategoryDiseasesSheet extends StatefulWidget {
  final QuizCategoryModel category;
  final String locale;

  const QuizCategoryDiseasesSheet({
    super.key,
    required this.category,
    required this.locale,
  });

  /// Show the bottom sheet
  static Future<void> show(
    BuildContext context, {
    required QuizCategoryModel category,
    required String locale,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QuizCategoryDiseasesSheet(
        category: category,
        locale: locale,
      ),
    );
  }

  @override
  State<QuizCategoryDiseasesSheet> createState() =>
      _QuizCategoryDiseasesSheetState();
}

class _QuizCategoryDiseasesSheetState extends State<QuizCategoryDiseasesSheet> {
  final DiseaseService _diseaseService = DiseaseService();
  final DiseaseCauseService _causeService = DiseaseCauseService();

  List<DiseaseModel> _diseases = [];
  Map<String, bool> _sessionAvailability = {};
  final Set<String> _selectedIds = {};
  bool _isLoading = true;

  static const int _maxSelection = 30;

  @override
  void initState() {
    super.initState();
    _loadDiseases();
  }

  Future<void> _loadDiseases() async {
    try {
      final allDiseases = await _diseaseService.getAllDiseases();
      final allCauses = await _causeService.getAllDiseaseCauses();

      // Filter diseases by category
      final filtered =
          allDiseases.where((d) => d.categoryId == widget.category.id).toList();

      // Sort alphabetically
      filtered.sort((a, b) {
        final nameA = a.getLocalizedName(widget.locale).toLowerCase();
        final nameB = b.getLocalizedName(widget.locale).toLowerCase();
        return nameA.compareTo(nameB);
      });

      // Check session availability
      final causeMap = {for (var c in allCauses) c.diseaseId: c};
      final availability = <String, bool>{};
      for (final disease in filtered) {
        final cause = causeMap[disease.id];
        availability[disease.id] = cause != null && cause.hasRecommendedSession;
      }

      if (mounted) {
        setState(() {
          _diseases = filtered;
          _sessionAvailability = availability;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading diseases: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _toggleSelection(String diseaseId) {
    setState(() {
      if (_selectedIds.contains(diseaseId)) {
        _selectedIds.remove(diseaseId);
      } else if (_selectedIds.length < _maxSelection) {
        _selectedIds.add(diseaseId);
      }
    });
  }

  void _viewResults() {
    if (_selectedIds.isEmpty) return;

    final selectedDiseases =
        _diseases.where((d) => _selectedIds.contains(d.id)).toList();

    Navigator.pop(context); // Close bottom sheet

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizResultsScreen(
          selectedDiseases: selectedDiseases,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isTablet = context.isTablet;
    final l10n = AppLocalizations.of(context);

    final maxHeight = MediaQuery.of(context).size.height * 0.75;
    final screenWidth = MediaQuery.of(context).size.width;

    // Limit width on tablets/desktop
    final maxWidth = isTablet ? 600.0 : screenWidth;

    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: maxHeight,
          maxWidth: maxWidth,
        ),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(24.r),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            _buildDragHandle(colors),

            // Header
            _buildHeader(colors, isTablet),

            // Divider
            Divider(color: colors.border.withValues(alpha: 0.3), height: 1),

            // Content
            Flexible(
              child: _isLoading
                  ? _buildLoadingState(colors)
                  : _diseases.isEmpty
                      ? _buildEmptyState(colors, l10n)
                      : _buildDiseaseList(colors, isTablet),
            ),

            // Footer with button
            if (!_isLoading && _diseases.isNotEmpty)
              _buildFooter(colors, isTablet, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildDragHandle(AppThemeExtension colors) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 12.h),
      width: 40.w,
      height: 4.h,
      decoration: BoxDecoration(
        color: colors.greyMedium.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(2.r),
      ),
    );
  }

  Widget _buildHeader(AppThemeExtension colors, bool isTablet) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 24.w : 20.w,
        vertical: 12.h,
      ),
      child: Row(
        children: [
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.category.getName(widget.locale),
                  style: GoogleFonts.inter(
                    fontSize: (isTablet ? 18.sp : 16.sp).clamp(14.0, 20.0),
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  '${_diseases.length} ${AppLocalizations.of(context).diseases}',
                  style: GoogleFonts.inter(
                    fontSize: (isTablet ? 14.sp : 12.sp).clamp(10.0, 16.0),
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Close button
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.close,
              color: colors.textSecondary,
              size: isTablet ? 24.sp : 22.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(AppThemeExtension colors) {
    return SizedBox(
      height: 200.h,
      child: Center(
        child: CircularProgressIndicator(
          color: colors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppThemeExtension colors, AppLocalizations l10n) {
    return SizedBox(
      height: 200.h,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.healing_outlined,
              size: 48.sp,
              color: colors.greyMedium,
            ),
            SizedBox(height: 12.h),
            Text(
              l10n.noDiseasesAvailable,
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiseaseList(AppThemeExtension colors, bool isTablet) {
    return ListView.separated(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 24.w : 20.w,
        vertical: 12.h,
      ),
      shrinkWrap: true,
      itemCount: _diseases.length,
      separatorBuilder: (_, __) => SizedBox(height: 8.h),
      itemBuilder: (context, index) {
        final disease = _diseases[index];
        final isSelected = _selectedIds.contains(disease.id);
        final hasSession = _sessionAvailability[disease.id] ?? false;

        return _buildDiseaseItem(
          disease,
          isSelected,
          hasSession,
          colors,
          isTablet,
        );
      },
    );
  }

  Widget _buildDiseaseItem(
    DiseaseModel disease,
    bool isSelected,
    bool hasSession,
    AppThemeExtension colors,
    bool isTablet,
  ) {
    final l10n = AppLocalizations.of(context);

    return GestureDetector(
      onTap: () => _toggleSelection(disease.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(isTablet ? 14.w : 12.w),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.textPrimary.withValues(alpha: 0.08)
              : colors.backgroundCard,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected
                ? colors.textPrimary
                : colors.border.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Checkbox
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isTablet ? 24.w : 22.w,
              height: isTablet ? 24.w : 22.w,
              decoration: BoxDecoration(
                color: isSelected ? colors.textPrimary : Colors.transparent,
                borderRadius: BorderRadius.circular(6.r),
                border: Border.all(
                  color: isSelected ? colors.textPrimary : colors.greyMedium,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      color: colors.textOnPrimary,
                      size: isTablet ? 16.sp : 14.sp,
                    )
                  : null,
            ),

            SizedBox(width: 12.w),

            // Disease info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    disease.getLocalizedName(widget.locale),
                    style: GoogleFonts.inter(
                      fontSize: (isTablet ? 15.sp : 14.sp).clamp(12.0, 17.0),
                      fontWeight: FontWeight.w500,
                      color: colors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      // Gender badge
                      _buildGenderBadge(disease.gender, colors),

                      SizedBox(width: 8.w),

                      // Session status
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: hasSession
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          hasSession ? l10n.sessionAvailable : l10n.comingSoon,
                          style: GoogleFonts.inter(
                            fontSize: 10.sp.clamp(8.0, 12.0),
                            fontWeight: FontWeight.w600,
                            color: hasSession ? Colors.green : Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderBadge(String gender, AppThemeExtension colors) {
    final color = _getGenderColor(gender);
    IconData icon;
    switch (gender) {
      case 'male':
        icon = Icons.male;
        break;
      case 'female':
        icon = Icons.female;
        break;
      default:
        icon = Icons.people; // For "both" or unknown
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Icon(
        icon,
        size: 12.sp.clamp(10.0, 14.0),
        color: color,
      ),
    );
  }

  Widget _buildFooter(
    AppThemeExtension colors,
    bool isTablet,
    AppLocalizations l10n,
  ) {
    final canProceed = _selectedIds.isNotEmpty;

    return Container(
      padding: EdgeInsets.all(isTablet ? 24.w : 20.w),
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(
          top: BorderSide(
            color: colors.border.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Selection count
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 12.w,
                vertical: 8.h,
              ),
              decoration: BoxDecoration(
                color: colors.greyLight,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                '${_selectedIds.length} / $_maxSelection',
                style: GoogleFonts.inter(
                  fontSize: (isTablet ? 14.sp : 13.sp).clamp(11.0, 16.0),
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
            ),

            SizedBox(width: 12.w),

            // View Results button
            Expanded(
              child: ElevatedButton(
                onPressed: canProceed ? _viewResults : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.textPrimary,
                  disabledBackgroundColor: colors.greyLight,
                  foregroundColor: colors.textOnPrimary,
                  disabledForegroundColor: colors.textSecondary,
                  padding:
                      EdgeInsets.symmetric(vertical: isTablet ? 14.h : 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  '${l10n.viewResults} (${_selectedIds.length})',
                  style: GoogleFonts.inter(
                    fontSize: (isTablet ? 15.sp : 14.sp).clamp(12.0, 17.0),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getGenderColor(String gender) {
    switch (gender) {
      case 'male':
        return Colors.blue;
      case 'female':
        return Colors.pink;
      default:
        return Colors.purple;
    }
  }
}
