import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/themes/app_theme_extension.dart';

class PlayerIntroductionModal {
  static void show({
    required BuildContext context,
    required Map<String, dynamic> session,
  }) {
    final l10n = AppLocalizations.of(context);
    final title = l10n.introduction;

    final content = session['_localizedIntroContent'] ??
        session['introduction']?['content'] ??
        '';

    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.noIntroductionAvailable),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: context.colors.backgroundElevated,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: 12.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: context.colors.greyMedium,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),

            // Header
            Padding(
              padding: EdgeInsets.all(20.w),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w700,
                        color: context.colors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon:
                        Icon(Icons.close, color: context.colors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: context.colors.border),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20.w),
                child: Text(
                  content,
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    height: 1.6,
                    color: context.colors.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}