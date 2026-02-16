// lib/features/player/widgets/up_next_card.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../../core/themes/app_theme_extension.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/mini_player_provider.dart';
import '../../../providers/auto_play_provider.dart';
import '../../../services/session_localization_service.dart';
import '../../../services/language_helper_service.dart';

/// Displays the next session in the queue with a tappable card.
///
/// Shows session thumbnail, title, and queue position.
/// Tapping the card or the skip button advances to the next session.
/// Hidden when no next session exists in the queue.
class UpNextCard extends StatelessWidget {
  final String currentLanguage;

  const UpNextCard({
    super.key,
    required this.currentLanguage,
  });

  @override
  Widget build(BuildContext context) {
    final miniPlayer = context.watch<MiniPlayerProvider>();
    final colors = context.colors;

    final hasNext = miniPlayer.hasNext;
    final nextSession = miniPlayer.nextSession;

    // Hide completely if no queue or no next session
    if (!miniPlayer.supportsAutoPlay || !hasNext || nextSession == null) {
      return const SizedBox.shrink();
    }

    // Hide if auto-play is disabled
    final autoPlay = context.watch<AutoPlayProvider>();
    if (!autoPlay.isEnabled) {
      return const SizedBox.shrink();
    }

    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 50.w : 30.w,
        vertical: 8.h,
      ),
      child: Container(
        padding: EdgeInsets.all(isTablet ? 14.w : 12.w),
        decoration: BoxDecoration(
          color: colors.backgroundElevated.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(isTablet ? 16.r : 14.r),
          border: Border.all(
            color: colors.textPrimary.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Thumbnail
            _buildThumbnail(context, nextSession, isTablet),
            SizedBox(width: isTablet ? 14.w : 10.w),

            // Session info
            Expanded(
              child: _buildSessionInfo(
                context,
                nextSession,
                miniPlayer,
                isTablet,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =================== THUMBNAIL ===================

  Widget _buildThumbnail(
    BuildContext context,
    Map<String, dynamic> session,
    bool isTablet,
  ) {
    final colors = context.colors;
    final size = isTablet ? 52.w : 44.w;
    final radius = isTablet ? 10.r : 8.r;
    final iconSize = isTablet ? 22.sp : 18.sp;

    final isOffline = session['_isOffline'] == true;
    final localImagePath = session['_localImagePath'] as String?;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: colors.greyLight,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: _buildThumbnailContent(
          context,
          session,
          isOffline,
          localImagePath,
          iconSize,
        ),
      ),
    );
  }

  Widget _buildThumbnailContent(
    BuildContext context,
    Map<String, dynamic> session,
    bool isOffline,
    String? localImagePath,
    double iconSize,
  ) {
    final colors = context.colors;

    // Offline: use local image
    if (isOffline && localImagePath != null) {
      final file = File(localImagePath);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover);
      }
    }

    // Online: use LanguageHelperService with proper fallback
    final imageUrl = LanguageHelperService.getImageUrl(
      session['backgroundImages'] as Map<String, dynamic>?,
      currentLanguage,
    );

    if (imageUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        placeholder: (_, __) => _buildPlaceholderIcon(colors, iconSize),
        errorWidget: (_, __, ___) => _buildPlaceholderIcon(colors, iconSize),
      );
    }

    return _buildPlaceholderIcon(colors, iconSize);
  }

  Widget _buildPlaceholderIcon(AppThemeExtension colors, double iconSize) {
    return Center(
      child: Icon(
        Icons.music_note_rounded,
        color: colors.textSecondary,
        size: iconSize,
      ),
    );
  }

  // =================== SESSION INFO ===================

  Widget _buildSessionInfo(
    BuildContext context,
    Map<String, dynamic> session,
    MiniPlayerProvider miniPlayer,
    bool isTablet,
  ) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);

    final title = _getSessionTitle(session);
    final queueLabel = miniPlayer.queuePositionLabel;

    final labelFontSize = isTablet ? 11.sp : 10.sp;
    final titleFontSize = isTablet ? 15.sp : 13.sp;
    final metaFontSize = isTablet ? 12.sp : 10.sp;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // "Up Next" label
        Text(
          l10n.upNext,
          style: GoogleFonts.inter(
            fontSize: labelFontSize,
            fontWeight: FontWeight.w600,
            color: colors.textSecondary,
            letterSpacing: 0.8,
          ),
          maxLines: 1,
        ),
        SizedBox(height: 3.h),

        // Session title
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: titleFontSize,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        // Queue position
        if (queueLabel != null) ...[
          SizedBox(height: 2.h),
          Text(
            queueLabel,
            style: GoogleFonts.inter(
              fontSize: metaFontSize,
              color: colors.textSecondary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ],
    );
  }

  // =================== HELPERS ===================

  String _getSessionTitle(Map<String, dynamic> session) {
    // Try pre-set display title (from auto-play transitions)
    final displayTitle = session['_displayTitle'] as String?;
    if (displayTitle != null && displayTitle.isNotEmpty) return displayTitle;

    // Use SessionLocalizationService with proper language fallback
    final localized = SessionLocalizationService.getLocalizedContent(
      session,
      currentLanguage,
    );
    if (localized.title.isNotEmpty) return localized.title;

    // Final fallback
    return session['title'] as String? ?? 'Untitled Session';
  }
}
