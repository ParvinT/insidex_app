// lib/features/search/widgets/search_history_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/themes/app_theme_extension.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/responsive/context_ext.dart';
import 'search_history_item.dart';

class SearchHistoryView extends StatelessWidget {
  final List<String> searches;
  final Function(String) onSearchTap;
  final VoidCallback onClearAll;
  final Function(String) onRemove;
  final bool isLoading;

  const SearchHistoryView({
    super.key,
    required this.searches,
    required this.onSearchTap,
    required this.onClearAll,
    required this.onRemove,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = context.isTablet;
    final l10n = AppLocalizations.of(context);

    // Loading state
    // Loading state
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: context.colors.textPrimary,
        ),
      );
    }

    // Empty state
    if (searches.isEmpty) {
      return _buildEmptyState(context, isTablet, l10n);
    }

    // History list
    return Column(
      children: [
        // Header
        _buildHeader(context, isTablet, l10n),

        // List
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 24.w : 20.w,
              vertical: isTablet ? 12.h : 8.h,
            ),
            itemCount: searches.length,
            itemBuilder: (context, index) {
              final query = searches[index];
              return SearchHistoryItem(
                query: query,
                onTap: () => onSearchTap(query),
                onRemove: () => onRemove(query),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(
      BuildContext context, bool isTablet, AppLocalizations l10n) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 24.w : 20.w,
        vertical: isTablet ? 10.h : 8.h,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            l10n.recentSearches,
            style: GoogleFonts.inter(
              fontSize: isTablet ? 16.sp : 15.sp,
              color: context.colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (searches.isNotEmpty)
            TextButton(
              onPressed: onClearAll,
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 12.w : 8.w,
                  vertical: isTablet ? 6.h : 4.h,
                ),
              ),
              child: Text(
                l10n.clearAll,
                style: GoogleFonts.inter(
                  fontSize: isTablet ? 13.sp : 12.sp,
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
      BuildContext context, bool isTablet, AppLocalizations l10n) {
    final colors = context.colors;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: isTablet ? 80.sp : 64.sp,
            color: colors.greyMedium,
          ),
          SizedBox(height: isTablet ? 24.h : 16.h),
          Text(
            l10n.search,
            style: GoogleFonts.inter(
              fontSize: isTablet ? 20.sp : 18.sp,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
          SizedBox(height: isTablet ? 10.h : 8.h),
          Text(
            l10n.searchSessions,
            style: GoogleFonts.inter(
              fontSize: isTablet ? 15.sp : 14.sp,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
