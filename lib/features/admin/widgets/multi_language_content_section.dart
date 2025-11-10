// lib/features/admin/widgets/multi_language_content_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_languages.dart'; // 🆕 IMPORT

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        _buildSectionTitle('📝 Content (Multi-Language)'),

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
                  AppLanguages.getLabel(lang), // 🆕 Dynamic label
                ),
              );
            }).toList(),
          ),
        ),

        SizedBox(height: 20.h),

        // Current Language Fields
        _buildLanguageFields(context, selectedLanguage),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 18.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildLanguageTab(BuildContext context, String lang, String label) {
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
      backgroundColor =
          isSelected ? AppColors.primaryGold : Colors.green.shade50;
      statusIcon = Icon(Icons.check_circle, size: 16.sp, color: Colors.green);
    } else if (hasContent || hasAudio) {
      // Partial: only content OR only audio
      borderColor = Colors.orange;
      backgroundColor =
          isSelected ? AppColors.primaryGold : Colors.orange.shade50;
      statusIcon = Icon(Icons.warning, size: 16.sp, color: Colors.orange);
    } else {
      // Empty
      borderColor = Colors.grey.shade300;
      backgroundColor =
          isSelected ? AppColors.primaryGold : Colors.grey.shade100;
      statusIcon = Icon(Icons.circle_outlined, size: 16.sp, color: Colors.grey);
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
                color: isSelected ? Colors.white : AppColors.textPrimary,
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

  Widget _buildLanguageFields(BuildContext context, String lang) {
    final controllers = contentControllers[lang]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Language indicator
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: AppColors.primaryGold.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6.r),
          ),
          child: Text(
            'Editing: ${AppLanguages.getFullLabel(lang)}', // 🆕 Dynamic label
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryGold,
            ),
          ),
        ),

        SizedBox(height: 16.h),

        // Title Field
        TextField(
          controller: controllers['title']!,
          decoration: InputDecoration(
            labelText: 'Title ($lang)',
            hintText: 'Enter session title',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: AppColors.primaryGold, width: 2),
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
            labelText: 'Description ($lang)',
            hintText: 'Enter session description',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: AppColors.primaryGold, width: 2),
            ),
          ),
          style: GoogleFonts.inter(fontSize: 14.sp),
        ),

        SizedBox(height: 16.h),

        // Introduction Title
        TextField(
          controller: controllers['introTitle']!,
          decoration: InputDecoration(
            labelText: 'Introduction Title ($lang)',
            hintText: 'e.g., About This Session',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: AppColors.primaryGold, width: 2),
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
            labelText: 'Introduction Content ($lang)',
            hintText: 'Describe what this session does...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: AppColors.primaryGold, width: 2),
            ),
          ),
          style: GoogleFonts.inter(fontSize: 14.sp),
        ),
      ],
    );
  }
}
