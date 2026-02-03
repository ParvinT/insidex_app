// lib/features/admin/widgets/multi_language_content_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/themes/app_theme_extension.dart';
import '../../../core/constants/app_languages.dart';
import '../../../l10n/app_localizations.dart';

class MultiLanguageContentSection extends StatelessWidget {
  final Map<String, Map<String, TextEditingController>> contentControllers;
  final String selectedLanguage;
  final Function(String) onLanguageChanged;
  final Map<String, dynamic>? existingAudioUrls;
  final Map<String, PlatformFile?> uploadedAudios;

  const MultiLanguageContentSection({
    super.key,
    required this.contentControllers,
    required this.selectedLanguage,
    required this.onLanguageChanged,
    this.existingAudioUrls,
    required this.uploadedAudios,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        _buildSectionTitle(
            context, AppLocalizations.of(context).contentMultiLanguage, colors),

        SizedBox(height: 16.h),

        // Language Tabs - 🆕 DYNAMIC
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: AppLanguages.supportedLanguages.map((lang) {
              return Padding(
                padding: EdgeInsets.only(right: 8.w),
                child: _buildLanguageTab(
                  context,
                  lang,
                  AppLanguages.getLabel(lang),
                  colors, // 🆕 Dynamic label
                ),
              );
            }).toList(),
          ),
        ),

        SizedBox(height: 20.h),

        // Current Language Fields
        _buildLanguageFields(context, selectedLanguage, colors),
      ],
    );
  }

  Widget _buildSectionTitle(
      BuildContext context, String title, AppThemeExtension colors) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 18.sp,
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
      ),
    );
  }

  Widget _buildLanguageTab(BuildContext context, String lang, String label,
      AppThemeExtension colors) {
    final isSelected = selectedLanguage == lang;

    // Check if this language has content
    final controllers = contentControllers[lang]!;
    final hasContent = controllers['title']!.text.isNotEmpty;
    final hasAudio =
        uploadedAudios[lang] != null || (existingAudioUrls?[lang] != null);

    // Status colors
    Color borderColor;
    Color backgroundColor;
    Widget statusIcon;

    if (hasContent && hasAudio) {
      // Full: content + audio
      borderColor = Colors.green;
      backgroundColor = isSelected ? colors.textPrimary : Colors.green.shade50;
      statusIcon = Icon(Icons.check_circle, size: 16.sp, color: Colors.green);
    } else if (hasContent || hasAudio) {
      // Partial: only content OR only audio
      borderColor = Colors.orange;
      backgroundColor = isSelected ? colors.textPrimary : Colors.orange.shade50;
      statusIcon = Icon(Icons.warning, size: 16.sp, color: Colors.orange);
    } else {
      // Empty
      borderColor = colors.greyMedium;
      backgroundColor = isSelected ? colors.textPrimary : colors.greyLight;
      statusIcon =
          Icon(Icons.circle_outlined, size: 16.sp, color: colors.greyMedium);
    }

    return GestureDetector(
      onTap: () => onLanguageChanged(lang),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                color: isSelected ? colors.textOnPrimary : colors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            SizedBox(width: 6.w),
            statusIcon,
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageFields(
      BuildContext context, String lang, AppThemeExtension colors) {
    final controllers = contentControllers[lang]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Language indicator
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: colors.textPrimary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6.r),
          ),
          child: Text(
            '${AppLocalizations.of(context).editing}: ${AppLanguages.getFullLabel(lang)}',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
        ),

        SizedBox(height: 16.h),

        // Title Field
        TextField(
          controller: controllers['title']!,
          decoration: InputDecoration(
            labelText: '${AppLocalizations.of(context).title} ($lang)',
            hintText: AppLocalizations.of(context).enterSessionTitle,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: colors.textPrimary, width: 2),
            ),
          ),
          style: GoogleFonts.inter(fontSize: 16.sp),
        ),

        SizedBox(height: 16.h),

        // Description Field
        TextField(
          controller: controllers['description']!,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: '${AppLocalizations.of(context).description} ($lang)',
            hintText: AppLocalizations.of(context).enterSessionDescription,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: colors.textPrimary, width: 2),
            ),
          ),
          style: GoogleFonts.inter(fontSize: 14.sp),
        ),

        SizedBox(height: 16.h),

        // Introduction Title
        TextField(
          controller: controllers['introTitle']!,
          decoration: InputDecoration(
            labelText:
                '${AppLocalizations.of(context).introductionTitle} ($lang)',
            hintText: AppLocalizations.of(context).aboutThisSession,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: colors.textPrimary, width: 2),
            ),
          ),
          style: GoogleFonts.inter(fontSize: 16.sp),
        ),

        SizedBox(height: 16.h),

        // Introduction Content
        TextField(
          controller: controllers['introContent']!,
          maxLines: 5,
          decoration: InputDecoration(
            labelText:
                '${AppLocalizations.of(context).introductionContent} ($lang)',
            hintText: AppLocalizations.of(context).describeWhatSessionDoes,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: colors.textPrimary, width: 2),
            ),
          ),
          style: GoogleFonts.inter(fontSize: 14.sp),
        ),
      ],
    );
  }
}
