// lib/features/admin/widgets/searchable_picker_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/themes/app_theme_extension.dart';
import '../../../core/responsive/context_ext.dart';
import '../../../l10n/app_localizations.dart';

/// A generic item for the searchable picker
class PickerItem<T> {
  final T value;
  final String title;
  final String? subtitle;
  final String? gender; // 'male', 'female', or null
  final Widget? leading;

  const PickerItem({
    required this.value,
    required this.title,
    this.subtitle,
    this.gender,
    this.leading,
  });
}

/// Configuration for gender filter
class GenderFilterConfig {
  final bool enabled;
  final String allLabel;
  final String maleLabel;
  final String femaleLabel;

  const GenderFilterConfig({
    this.enabled = false,
    this.allLabel = 'All',
    this.maleLabel = 'Male',
    this.femaleLabel = 'Female',
  });
}

/// Reusable searchable picker bottom sheet
///
/// Features:
/// - Search functionality with debounce
/// - Optional gender filter (All/Male/Female)
/// - Responsive design for phone/tablet
/// - Customizable item rendering
///
/// Usage:
/// ```dart
/// final result = await showSearchablePickerSheet<String>(
///   context: context,
///   title: 'Select Disease',
///   items: diseases.map((d) => PickerItem(
///     value: d.id,
///     title: d.name,
///     gender: d.gender,
///   )).toList(),
///   selectedValue: _selectedDiseaseId,
///   genderFilter: GenderFilterConfig(enabled: true),
/// );
/// ```
Future<T?> showSearchablePickerSheet<T>({
  required BuildContext context,
  required String title,
  required List<PickerItem<T>> items,
  T? selectedValue,
  String? searchHint,
  GenderFilterConfig genderFilter = const GenderFilterConfig(),
}) async {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _SearchablePickerSheet<T>(
      title: title,
      items: items,
      selectedValue: selectedValue,
      searchHint: searchHint,
      genderFilter: genderFilter,
    ),
  );
}

class _SearchablePickerSheet<T> extends StatefulWidget {
  final String title;
  final List<PickerItem<T>> items;
  final T? selectedValue;
  final String? searchHint;
  final GenderFilterConfig genderFilter;

  const _SearchablePickerSheet({
    required this.title,
    required this.items,
    this.selectedValue,
    this.searchHint,
    required this.genderFilter,
  });

  @override
  State<_SearchablePickerSheet<T>> createState() =>
      _SearchablePickerSheetState<T>();
}

class _SearchablePickerSheetState<T> extends State<_SearchablePickerSheet<T>> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedGender = 'all'; // 'all', 'male', 'female'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<PickerItem<T>> get _filteredItems {
    var items = widget.items;

    // Apply gender filter
    if (widget.genderFilter.enabled && _selectedGender != 'all') {
      items = items.where((item) => item.gender == _selectedGender).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      items = items.where((item) {
        final titleMatch = item.title.toLowerCase().contains(query);
        final subtitleMatch =
            item.subtitle?.toLowerCase().contains(query) ?? false;
        return titleMatch || subtitleMatch;
      }).toList();
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isTablet = context.isTablet;
    final l10n = AppLocalizations.of(context);

    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive sizing
    final maxHeight = screenHeight * (isTablet ? 0.7 : 0.8);
    final maxWidth = isTablet ? 600.0 : screenWidth;
    final horizontalPadding = isTablet ? 24.w : 16.w;
    final itemPadding = isTablet ? 16.w : 12.w;

    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: maxHeight,
          maxWidth: maxWidth,
        ),
        margin:
            isTablet ? EdgeInsets.symmetric(horizontal: 40.w) : EdgeInsets.zero,
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(isTablet ? 24.r : 20.r),
            bottom: isTablet ? Radius.circular(24.r) : Radius.zero,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            _buildDragHandle(colors),

            // Header with title and close button
            _buildHeader(colors, isTablet),

            // Search bar
            _buildSearchBar(colors, isTablet, horizontalPadding),

            // Gender filter (if enabled)
            if (widget.genderFilter.enabled)
              _buildGenderFilter(colors, isTablet, horizontalPadding),

            // Divider
            Divider(
              color: colors.border.withValues(alpha: 0.3),
              height: 1,
            ),

            // Results count
            _buildResultsCount(colors, isTablet, horizontalPadding),

            // Items list
            Flexible(
              child: _filteredItems.isEmpty
                  ? _buildEmptyState(colors, isTablet, l10n)
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: 8.h,
                      ),
                      itemCount: _filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = _filteredItems[index];
                        final isSelected = item.value == widget.selectedValue;
                        return _buildListItem(
                          item,
                          isSelected,
                          colors,
                          isTablet,
                          itemPadding,
                        );
                      },
                    ),
            ),

            // Bottom safe area
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8.h),
          ],
        ),
      ),
    );
  }

  Widget _buildDragHandle(AppThemeExtension colors) {
    return Container(
      margin: EdgeInsets.only(top: 12.h),
      width: 40.w,
      height: 4.h,
      decoration: BoxDecoration(
        color: colors.greyMedium,
        borderRadius: BorderRadius.circular(2.r),
      ),
    );
  }

  Widget _buildHeader(AppThemeExtension colors, bool isTablet) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        isTablet ? 24.w : 20.w,
        16.h,
        isTablet ? 16.w : 8.w,
        12.h,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget.title,
              style: GoogleFonts.inter(
                fontSize: isTablet ? 22.sp : 20.sp,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.close,
              color: colors.textSecondary,
              size: isTablet ? 26.sp : 24.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(
    AppThemeExtension colors,
    bool isTablet,
    double horizontalPadding,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: 8.h,
      ),
      child: Container(
        height: isTablet ? 52.h : 48.h,
        decoration: BoxDecoration(
          color: colors.greyLight,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: colors.border.withValues(alpha: 0.3),
          ),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() => _searchQuery = value.trim());
          },
          style: GoogleFonts.inter(
            fontSize: isTablet ? 16.sp : 15.sp,
            color: colors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: widget.searchHint ?? AppLocalizations.of(context).search,
            hintStyle: GoogleFonts.inter(
              fontSize: isTablet ? 16.sp : 15.sp,
              color: colors.textSecondary.withValues(alpha: 0.7),
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: colors.textSecondary,
              size: isTablet ? 24.sp : 22.sp,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                    icon: Icon(
                      Icons.close_rounded,
                      color: colors.textSecondary,
                      size: isTablet ? 22.sp : 20.sp,
                    ),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: isTablet ? 14.h : 12.h,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGenderFilter(
    AppThemeExtension colors,
    bool isTablet,
    double horizontalPadding,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: 8.h,
      ),
      child: Row(
        children: [
          _buildGenderChip(
            'all',
            widget.genderFilter.allLabel,
            Icons.people_outline,
            Colors.purple,
            colors,
            isTablet,
          ),
          SizedBox(width: 8.w),
          _buildGenderChip(
            'male',
            widget.genderFilter.maleLabel,
            Icons.male,
            Colors.blue,
            colors,
            isTablet,
          ),
          SizedBox(width: 8.w),
          _buildGenderChip(
            'female',
            widget.genderFilter.femaleLabel,
            Icons.female,
            Colors.pink,
            colors,
            isTablet,
          ),
        ],
      ),
    );
  }

  Widget _buildGenderChip(
    String value,
    String label,
    IconData icon,
    Color accentColor,
    AppThemeExtension colors,
    bool isTablet,
  ) {
    final isSelected = _selectedGender == value;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedGender = value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 14.w : 12.w,
          vertical: isTablet ? 10.h : 8.h,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: 0.15)
              : colors.greyLight,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected ? accentColor : colors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: isTablet ? 18.sp : 16.sp,
              color: isSelected ? accentColor : colors.textSecondary,
            ),
            SizedBox(width: 6.w),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: isTablet ? 14.sp : 13.sp,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? accentColor : colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsCount(
    AppThemeExtension colors,
    bool isTablet,
    double horizontalPadding,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: 8.h,
      ),
      child: Row(
        children: [
          Text(
            '${_filteredItems.length} ${_filteredItems.length == 1 ? 'result' : 'results'}',
            style: GoogleFonts.inter(
              fontSize: isTablet ? 13.sp : 12.sp,
              color: colors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(
    PickerItem<T> item,
    bool isSelected,
    AppThemeExtension colors,
    bool isTablet,
    double itemPadding,
  ) {
    return GestureDetector(
      onTap: () => Navigator.pop(context, item.value),
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.all(itemPadding),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.textPrimary.withValues(alpha: 0.1)
              : colors.backgroundElevated,
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
            // Leading widget or gender badge
            if (item.leading != null)
              Padding(
                padding: EdgeInsets.only(right: 12.w),
                child: item.leading,
              )
            else if (item.gender != null)
              Padding(
                padding: EdgeInsets.only(right: 12.w),
                child: _buildGenderBadge(item.gender!, colors, isTablet),
              ),

            // Title and subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: GoogleFonts.inter(
                      fontSize: isTablet ? 16.sp : 15.sp,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: colors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.subtitle != null) ...[
                    SizedBox(height: 4.h),
                    Text(
                      item.subtitle!,
                      style: GoogleFonts.inter(
                        fontSize: isTablet ? 13.sp : 12.sp,
                        color: colors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Selected indicator
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: colors.textPrimary,
                size: isTablet ? 24.sp : 22.sp,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderBadge(
    String gender,
    AppThemeExtension colors,
    bool isTablet,
  ) {
    final isMale = gender == 'male';
    final color = isMale ? Colors.blue : Colors.pink;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 10.w : 8.w,
        vertical: isTablet ? 6.h : 4.h,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Icon(
        isMale ? Icons.male : Icons.female,
        size: isTablet ? 18.sp : 16.sp,
        color: color,
      ),
    );
  }

  Widget _buildEmptyState(
    AppThemeExtension colors,
    bool isTablet,
    AppLocalizations l10n,
  ) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: isTablet ? 64.sp : 56.sp,
              color: colors.greyMedium,
            ),
            SizedBox(height: 16.h),
            Text(
              l10n.noResultsFound,
              style: GoogleFonts.inter(
                fontSize: isTablet ? 18.sp : 16.sp,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              l10n.tryDifferentKeywords,
              style: GoogleFonts.inter(
                fontSize: isTablet ? 14.sp : 13.sp,
                color: colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
