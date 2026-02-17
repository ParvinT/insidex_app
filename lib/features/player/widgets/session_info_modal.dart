import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../l10n/app_localizations.dart';
import '../../../services/session_localization_service.dart';
import '../../../services/language_helper_service.dart';
import '../../../services/markdown_content_service.dart';
import '../../../core/themes/app_theme_extension.dart';
import '../../../shared/widgets/auto_marquee_text.dart';

class SessionInfoModal {
  static Future<void> show({
    required BuildContext context,
    required Map<String, dynamic> session,
  }) async {
    // 🆕 async
    // 🆕 Prepare localized content BEFORE showing modal
    final language = await LanguageHelperService.getCurrentLanguage();

    if (!context.mounted) return;

    final localizedContent = SessionLocalizationService.getLocalizedContent(
      session,
      language,
    );

// Build title with session number
    final localizedSession = Map<String, dynamic>.from(session);

    final title = localizedContent.title.isNotEmpty
        ? localizedContent.title
        : (session['title'] ?? 'Untitled Session');

    localizedSession['_displayTitle'] = title;
    // Load philosophy text from assets (not Firebase)
    final philosophyText = await MarkdownContentService.loadTextContent(
      contentName: 'session_philosophy',
      languageCode: language,
    );
    localizedSession['_displayDescription'] = philosophyText;

    if (!context.mounted) return;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: context.colors.textPrimary.withValues(alpha: 0.07),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Container();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutBack,
              ),
            ),
            child: _SessionInfoContent(
              session: localizedSession, // 🆕 localized session
              animation: animation,
            ),
          ),
        );
      },
    );
  }
}

class _SessionInfoContent extends StatelessWidget {
  final Map<String, dynamic> session;
  final Animation<double> animation;

  const _SessionInfoContent({
    required this.session,
    required this.animation,
  });

  @override
  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final w = mq.size.width;
    final h = mq.size.height;

    // Adaptive modal width/height for phones, tablets, and hubs.
    final bool isUltraWide = w >= 1200;
    final bool isTablet = w >= 768 && w < 1200;

    final double modalW = () {
      if (isUltraWide) return (w * 0.60).clamp(480.0, 820.0);
      if (isTablet) return (w * 0.70).clamp(420.0, 720.0);
      return (w * 0.92).clamp(320.0, 420.0);
    }();

    final double modalH = (h * (isUltraWide ? 0.90 : 0.86)).clamp(360.0, 900.0);

    // Keep large accessibility text sane inside this modal only.
    final double clampedTextScale = mq.textScaler.scale(1.0).clamp(1.0, 1.2);

    return MediaQuery(
      data: mq.copyWith(textScaler: TextScaler.linear(clampedTextScale)),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: modalW,
            maxHeight: modalH,
          ),
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: context.colors.backgroundElevated,
              borderRadius: BorderRadius.circular(24.r),
              boxShadow: [
                BoxShadow(
                  color: context.colors.textPrimary.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(context),
                // Scrollable content; never overflows.
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                        24.w, 16.h, 24.w, 24.h + mq.viewPadding.bottom),
                    physics: const ClampingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSessionTitle(context),
                        if (session['_displayDescription'] != null &&
                            session['_displayDescription']
                                .toString()
                                .trim()
                                .isNotEmpty)
                          _buildDescription(context),
                        _buildNowPlayingCard(context),
                        SizedBox(height: 8.h),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: colors.greyLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: colors.textPrimary,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.music_note_rounded,
              color: colors.textOnPrimary,
              size: 24.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              AppLocalizations.of(context).currentSession,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: colors.greyMedium,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                color: colors.textPrimary,
                size: 20.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionTitle(BuildContext context) {
    String displayTitle =
        (session['_displayTitle'] ?? session['title'] ?? 'Untitled Session')
            .replaceAll(RegExp(r'<[^>]*>'), '')
            .replaceAll(RegExp(r'\*\*([^\*]*)\*\*'), '\$1')
            .replaceAll(RegExp(r'__([^_]*)__'), '\$1')
            .replaceAll(RegExp(r'\*([^\*]*)\*'), '\$1')
            .replaceAll(RegExp(r'_([^_]*)_'), '\$1')
            .replaceAll(RegExp(r'<u>([^<]*)</u>'), '\$1')
            .replaceAll(RegExp(r'<mark>([^<]*)</mark>'), '\$1')
            .trim();

    return Padding(
      padding: EdgeInsets.only(top: 20.h, bottom: 16.h),
      child: Text(
        displayTitle,
        style: GoogleFonts.inter(
          fontSize: (24.sp).clamp(18.sp, 30.sp),
          fontWeight: FontWeight.w700,
          color: context.colors.textPrimary,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }

  Widget _buildDescription(BuildContext context) {
    String rawDescription = session['_displayDescription'] ??
        (session['description'] ??
            AppLocalizations.of(context).noDescriptionAvailable);

    String cleanDescription = rawDescription
        .replaceAll(RegExp(r'<[^>]*>'), '') // HTML tags
        .replaceAll(RegExp(r'\*\*([^\*]*)\*\*'), '\$1') // Bold markdown
        .replaceAll(RegExp(r'__([^_]*)__'), '\$1') // Bold markdown
        .replaceAll(RegExp(r'\*([^\*]*)\*'), '\$1') // Italic markdown
        .replaceAll(RegExp(r'_([^_]*)_'), '\$1') // Italic markdown
        .replaceAll(RegExp(r'<u>([^<]*)</u>'), '\$1') // Underline HTML
        .replaceAll(RegExp(r'<mark>([^<]*)</mark>'), '\$1') // Highlight HTML
        .trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).ourApproach,
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            color: context.colors.textSecondary,
            letterSpacing: 1.2,
            decoration: TextDecoration.none,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          cleanDescription,
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            color: context.colors.textPrimary,
            height: 1.6,
            decoration: TextDecoration.none,
          ),
        ),
        SizedBox(height: 24.h),
      ],
    );
  }

  Widget _buildNowPlayingCard(BuildContext context) {
    final colors = context.colors;
    return Container(
      margin: EdgeInsets.only(bottom: 24.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: colors.textPrimary,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              color: colors.textOnPrimary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: colors.textOnPrimary.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.play_arrow_rounded,
              color: colors.textOnPrimary,
              size: 28.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).nowPlaying,
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: colors.textOnPrimary.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                    decoration: TextDecoration.none,
                  ),
                ),
                SizedBox(height: 4.h),
                _buildSessionTitleWithMarquee(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionTitleWithMarquee(BuildContext context) {
    String sessionTitle =
        (session['_displayTitle'] ?? session['title'] ?? 'Unknown Session')
            .replaceAll(RegExp(r'<[^>]*>'), '')
            .replaceAll(RegExp(r'\*\*([^\*]*)\*\*'), r'$1')
            .replaceAll(RegExp(r'__([^_]*)__'), r'$1')
            .replaceAll(RegExp(r'\*([^\*]*)\*'), r'$1')
            .replaceAll(RegExp(r'_([^_]*)_'), r'$1')
            .replaceAll(RegExp(r'<u>([^<]*)</u>'), r'$1')
            .replaceAll(RegExp(r'<mark>([^<]*)</mark>'), r'$1')
            .trim();

    return AutoMarqueeText(
      text: sessionTitle,
      style: GoogleFonts.inter(
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
        color: context.colors.textOnPrimary,
        decoration: TextDecoration.none,
      ),
    );
  }
}
