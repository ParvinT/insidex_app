// lib/features/quiz/widgets/disease_cause_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/responsive/context_ext.dart';

class DiseaseCauseCard extends StatelessWidget {
  final String causeContent;

  const DiseaseCauseCard({
    super.key,
    required this.causeContent,
  });

  @override
  Widget build(BuildContext context) {
    // Responsive values
    final isTablet = context.isTablet;
    final isDesktop = context.isDesktop;

    final double cardPadding = isDesktop ? 24.w : (isTablet ? 20.w : 18.w);

    final double contentSize =
        isTablet ? 15.sp.clamp(14.0, 16.0) : 14.sp.clamp(13.0, 15.0);
    final double borderRadius = isTablet ? 18.r : 16.r;

    return Container(
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: AppColors.greyBorder.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Content
          Text(
            causeContent,
            style: GoogleFonts.inter(
              fontSize: contentSize,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
            maxLines: 6,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
