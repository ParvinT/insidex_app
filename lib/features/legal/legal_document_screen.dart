// lib/features/legal/legal_document_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/legal_document_service.dart';
import '../../providers/locale_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/responsive/context_ext.dart';

class LegalDocumentScreen extends StatelessWidget {
  final String documentName;
  final String title;

  const LegalDocumentScreen({
    Key? key,
    required this.documentName,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final locale = Provider.of<LocaleProvider>(context).locale;
    final isTablet = context.isTablet;
    final isDesktop = context.isDesktop;

    // Responsive değerler
    final double maxContentWidth =
        isDesktop ? 800 : (isTablet ? 600 : double.infinity);
    final double horizontalPadding =
        isDesktop ? 40.w : (isTablet ? 30.w : 20.w);

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.backgroundWhite,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 20.sp.clamp(20.0, 22.0),
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: FutureBuilder<String>(
        future: LegalDocumentService.loadDocument(
          documentName: documentName,
          languageCode: locale.languageCode,
        ),
        builder: (context, snapshot) {
          // Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: AppColors.textPrimary,
              ),
            );
          }

          // Error
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64.sp,
                      color: Colors.red,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Failed to load document',
                      style: GoogleFonts.inter(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Please try again later',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          // Success - Show Markdown
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxContentWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20.h),
                    Markdown(
                      data: snapshot.data ?? '',
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      styleSheet: _buildMarkdownStyleSheet(context),
                      selectable: true, // Metni kopyalanabilir yap
                      onTapLink: (text, href, title) {
                        if (href != null) {
                          _launchURL(href);
                        }
                      },
                    ),
                    SizedBox(height: 40.h),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Markdown stil ayarları
  MarkdownStyleSheet _buildMarkdownStyleSheet(BuildContext context) {
    final isTablet = context.isTablet;
    final isDesktop = context.isDesktop;

    return MarkdownStyleSheet(
      // Başlıklar
      h1: GoogleFonts.inter(
        fontSize: isDesktop ? 28.sp : (isTablet ? 26.sp : 24.sp),
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.3,
      ),
      h2: GoogleFonts.inter(
        fontSize: isDesktop ? 22.sp : (isTablet ? 20.sp : 20.sp),
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.3,
      ),
      h3: GoogleFonts.inter(
        fontSize: isDesktop ? 18.sp : (isTablet ? 17.sp : 18.sp),
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.3,
      ),

      // Paragraf
      p: GoogleFonts.inter(
        fontSize: isDesktop ? 15.sp : (isTablet ? 14.sp : 15.sp),
        height: 1.6,
        color: AppColors.textSecondary,
      ),

      // Liste
      listBullet: GoogleFonts.inter(
        fontSize: isDesktop ? 15.sp : (isTablet ? 14.sp : 15.sp),
        color: AppColors.textSecondary,
      ),

      // Blockquote
      blockquote: GoogleFonts.inter(
        fontSize: isDesktop ? 15.sp : (isTablet ? 14.sp : 15.sp),
        fontStyle: FontStyle.italic,
        color: AppColors.textSecondary.withValues(alpha: 0.8),
      ),
      blockquoteDecoration: BoxDecoration(
        color: AppColors.textPrimary.withValues(alpha: 0.05),
        border: Border(
          left: BorderSide(
            color: AppColors.textPrimary,
            width: 4.w,
          ),
        ),
      ),
      blockquotePadding: EdgeInsets.all(16.w),

      // Code
      code: GoogleFonts.robotoMono(
        fontSize: isDesktop ? 14.sp : (isTablet ? 13.sp : 14.sp),
        backgroundColor: AppColors.greyLight.withValues(alpha: 0.3),
      ),

      // Link
      a: GoogleFonts.inter(
        fontSize: isDesktop ? 15.sp : (isTablet ? 14.sp : 15.sp),
        color: AppColors.textPrimary,
        decoration: TextDecoration.underline,
      ),

      // Strong (Bold)
      strong: GoogleFonts.inter(
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),

      // Em (Italic)
      em: GoogleFonts.inter(
        fontStyle: FontStyle.italic,
      ),

      // Spacing
      blockSpacing: 16.h,
      listIndent: 24.w,

      // Horizontal Rule
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColors.greyBorder,
            width: 1.h,
          ),
        ),
      ),
    );
  }

  /// URL'yi aç
  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    }
  }
}
