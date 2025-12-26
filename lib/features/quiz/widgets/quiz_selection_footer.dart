// lib/features/quiz/widgets/quiz_selection_footer.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/themes/app_theme_extension.dart';

class QuizSelectionFooter extends StatefulWidget {
  final int selectionCount;
  final int maxSelection;
  final bool canProceed;
  final bool isTablet;
  final String selectedLabel;
  final String nextLabel;
  final VoidCallback onInfoPressed;
  final VoidCallback onNextPressed;

  const QuizSelectionFooter({
    super.key,
    required this.selectionCount,
    required this.maxSelection,
    required this.canProceed,
    required this.isTablet,
    required this.selectedLabel,
    required this.nextLabel,
    required this.onInfoPressed,
    required this.onNextPressed,
  });

  @override
  State<QuizSelectionFooter> createState() => _QuizSelectionFooterState();
}

class _QuizSelectionFooterState extends State<QuizSelectionFooter> {
  bool _isInfoPressed = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final isCompact = availableWidth < 340;
        final colors = context.colors;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 10.w : (widget.isTablet ? 16.w : 12.w),
            vertical: isCompact ? 8.h : (widget.isTablet ? 12.h : 10.h),
          ),
          decoration: BoxDecoration(
            color: colors.greyLight.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Selection counter
              Flexible(
                flex: isCompact ? 2 : 3,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(
                          isCompact ? 5.w : (widget.isTablet ? 8.w : 6.w)),
                      decoration: BoxDecoration(
                        color: widget.selectionCount > 0
                            ? colors.textPrimary
                            : colors.greyMedium,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check,
                        size: isCompact ? 12.sp : (widget.isTablet ? 16.sp : 14.sp),
                        color: colors.textOnPrimary,
                      ),
                    ),
                    SizedBox(width: isCompact ? 6.w : 10.w),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.selectedLabel,
                            style: GoogleFonts.inter(
                              fontSize:
                                  isCompact ? 9.sp : (widget.isTablet ? 12.sp : 10.sp),
                              fontWeight: FontWeight.w500,
                              color: colors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            '${widget.selectionCount} / ${widget.maxSelection}',
                            style: GoogleFonts.inter(
                              fontSize: isCompact
                                  ? 12.sp
                                  : (widget.isTablet ? 16.sp : 14.sp),
                              fontWeight: FontWeight.w700,
                              color: widget.selectionCount > 0
                                  ? colors.textPrimary
                                  : colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(width: isCompact ? 6.w : 8.w),

              GestureDetector(
                onTapDown: (_) => setState(() => _isInfoPressed = true),
                onTapUp: (_) {
                  setState(() => _isInfoPressed = false);
                  widget.onInfoPressed();
                },
                onTapCancel: () => setState(() => _isInfoPressed = false),
                child: AnimatedScale(
                  scale: _isInfoPressed ? 0.85 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeInOut,
                  child: Container(
                    padding: EdgeInsets.all(
                        isCompact ? 8.w : (widget.isTablet ? 12.w : 10.w)),
                    child: Lottie.asset(
                      AppIcons.getUiAnimationPath('information.json'),
                      width: isCompact ? 28.sp : (widget.isTablet ? 36.sp : 32.sp),
                      height: isCompact ? 28.sp : (widget.isTablet ? 36.sp : 32.sp),
                      fit: BoxFit.cover,
                      repeat: true,
                    ),
                  ),
                ),
              ),

              SizedBox(width: isCompact ? 6.w : 8.w),

              // Next button
              Flexible(
                flex: 2,
                child: GestureDetector(
                  onTap: widget.canProceed ? widget.onNextPressed : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompact ? 12.w : (widget.isTablet ? 18.w : 14.w),
                      vertical: isCompact ? 8.h : (widget.isTablet ? 12.h : 10.h),
                    ),
                    decoration: BoxDecoration(
                      color: widget.canProceed
                          ? (context.isDarkMode
                              ? colors.textPrimary.withValues(alpha: 0.85)
                              : colors.textPrimary)
                          : colors.greyMedium,
                      borderRadius: BorderRadius.circular(24.r),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            widget.nextLabel,
                            style: GoogleFonts.inter(
                              fontSize: isCompact
                                  ? 11.sp
                                  : (widget.isTablet ? 14.sp : 12.sp),
                              fontWeight: FontWeight.w700,
                              color: widget.canProceed
                                  ? colors.textOnPrimary
                                  : colors.textLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.clip,
                          ),
                        ),
                        SizedBox(width: isCompact ? 4.w : 6.w),
                        Icon(
                          Icons.arrow_forward,
                          size: isCompact ? 12.sp : (widget.isTablet ? 16.sp : 14.sp),
                          color: widget.canProceed
                              ? colors.textOnPrimary
                              : colors.textLight,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}