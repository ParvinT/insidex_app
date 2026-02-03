// lib/features/quiz/widgets/how_it_works_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/themes/app_theme_extension.dart';
import '../../../core/responsive/context_ext.dart';
import '../../../providers/locale_provider.dart';
import '../../../services/markdown_content_service.dart';
import '../../../l10n/app_localizations.dart';

class HowItWorksSheet extends StatefulWidget {
  const HowItWorksSheet({super.key});

  /// Show the bottom sheet with smooth animation
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => const HowItWorksSheet(),
    );
  }

  @override
  State<HowItWorksSheet> createState() => _HowItWorksSheetState();
}

class _HowItWorksSheetState extends State<HowItWorksSheet> {
  String _content = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    final locale = Provider.of<LocaleProvider>(context, listen: false).locale;

    final content = await MarkdownContentService.loadContent(
      contentName: 'how_it_works',
      languageCode: locale.languageCode,
    );

    if (mounted) {
      setState(() {
        _content = content;
        _isLoading = false;
      });
    }
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = context.isTablet;
    final isDesktop = context.isDesktop;
    final screenHeight = context.h;

    // Responsive values
    final double maxHeight =
        screenHeight * (isDesktop ? 0.7 : (isTablet ? 0.75 : 0.8));
    final double horizontalPadding =
        isDesktop ? 32.w : (isTablet ? 24.w : 20.w);
    final double verticalPadding = isDesktop ? 24.h : (isTablet ? 20.h : 16.h);
    final double borderRadius = isDesktop ? 28.r : (isTablet ? 24.r : 20.r);
    final double handleWidth = isTablet ? 50.w : 40.w;
    final double handleHeight = isTablet ? 5.h : 4.h;

    final colors = context.colors;
    return Container(
      constraints: BoxConstraints(
        maxHeight: maxHeight,
      ),
      decoration: BoxDecoration(
        color: colors.backgroundElevated,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(borderRadius),
          topRight: Radius.circular(borderRadius),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.textPrimary.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          _buildDragHandle(handleWidth, handleHeight),

          // Header with close button
          _buildHeader(isTablet, horizontalPadding),

          // Divider
          Divider(
            height: 1,
            thickness: 1,
            color: colors.border.withValues(alpha: 0.3),
          ),

          // Content
          Flexible(
            child: _isLoading
                ? _buildLoadingState()
                : _buildContent(
                    isTablet,
                    isDesktop,
                    horizontalPadding,
                    verticalPadding,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDragHandle(double width, double height) {
    return Container(
      margin: EdgeInsets.only(top: 12.h, bottom: 8.h),
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.colors.greyMedium,
        borderRadius: BorderRadius.circular(height / 2),
      ),
    );
  }

  Widget _buildHeader(bool isTablet, double horizontalPadding) {
    final colors = context.colors;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: 12.h,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Title
          Expanded(
            child: Row(
              children: [
                Icon(
                  Icons.help_outline_rounded,
                  size: isTablet ? 24.sp : 22.sp,
                  color: colors.textPrimary,
                ),
                SizedBox(width: 10.w),
                Flexible(
                  child: Text(
                    AppLocalizations.of(context).howItWorks,
                    style: GoogleFonts.inter(
                      fontSize: isTablet ? 20.sp : 18.sp,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Close button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: colors.greyLight.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close_rounded,
                size: isTablet ? 22.sp : 20.sp,
                color: colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return SizedBox(
      height: 200.h,
      child: Center(
        child: CircularProgressIndicator(
          color: context.colors.textPrimary,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildContent(
    bool isTablet,
    bool isDesktop,
    double horizontalPadding,
    double verticalPadding,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      child: MarkdownBody(
        data: _content,
        shrinkWrap: true,
        styleSheet: _buildMarkdownStyleSheet(isTablet, isDesktop),
        selectable: true,
        onTapLink: (text, href, title) {
          if (href != null) {
            _launchURL(href);
          }
        },
      ),
    );
  }

  MarkdownStyleSheet _buildMarkdownStyleSheet(bool isTablet, bool isDesktop) {
    final colors = context.colors;
    return MarkdownStyleSheet(
      h1: GoogleFonts.inter(
        fontSize: isDesktop ? 22.sp : (isTablet ? 20.sp : 18.sp),
        fontWeight: FontWeight.w700,
        color: colors.textPrimary,
        height: 1.3,
      ),
      h2: GoogleFonts.inter(
        fontSize: isDesktop ? 18.sp : (isTablet ? 17.sp : 16.sp),
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
        height: 1.3,
      ),
      p: GoogleFonts.inter(
        fontSize: isDesktop ? 15.sp : (isTablet ? 14.sp : 14.sp),
        height: 1.6,
        color: colors.textSecondary,
      ),
      listBullet: GoogleFonts.inter(
        fontSize: isDesktop ? 15.sp : (isTablet ? 14.sp : 14.sp),
        color: colors.textSecondary,
      ),
      strong: GoogleFonts.inter(
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
      ),
      em: GoogleFonts.inter(
        fontStyle: FontStyle.italic,
      ),
      listIndent: 20.w,
      pPadding: EdgeInsets.only(bottom: 12.h),
      h1Padding: EdgeInsets.only(top: 16.h, bottom: 8.h),
      h2Padding: EdgeInsets.only(top: 14.h, bottom: 6.h),
    );
  }
}
