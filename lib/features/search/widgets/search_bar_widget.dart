// lib/features/search/widgets/search_bar_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/themes/app_theme_extension.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/responsive/context_ext.dart';

class SearchBarWidget extends StatelessWidget {
  final VoidCallback onTap;
  final bool enabled;

  const SearchBarWidget({
    super.key,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = context.isTablet;

    final double horizontalPadding =
        isTablet ? (18.w).clamp(14.0, 20.0) : (16.w).clamp(12.0, 18.0);
    final double verticalPadding =
        isTablet ? (14.h).clamp(12.0, 16.0) : (12.h).clamp(10.0, 14.0);
    final colors = context.colors;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        margin: EdgeInsets.zero,
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        decoration: BoxDecoration(
          color: colors.greyLight,
          borderRadius: BorderRadius.circular(
            (isTablet ? 14.r : 12.r).clamp(10.0, 16.0),
          ),
          border: Border.all(
            color: colors.border.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.search,
              color: colors.textSecondary,
              size: (isTablet ? 22.sp : 20.sp).clamp(18.0, 24.0),
            ),
            SizedBox(width: isTablet ? 14.w : 12.w),
            Expanded(
              child: Text(
                AppLocalizations.of(context).searchSessions,
                style: GoogleFonts.inter(
                  fontSize: (isTablet ? 16.sp : 15.sp).clamp(13.0, 18.0),
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
