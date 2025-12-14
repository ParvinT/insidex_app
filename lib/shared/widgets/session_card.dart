// lib/shared/widgets/session_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';
import '../../core/themes/app_theme_extension.dart';
import '../../core/responsive/breakpoints.dart';
import '../../services/cache_manager_service.dart';
import '../../l10n/app_localizations.dart';
import '../../services/language_helper_service.dart';
import '../../services/session_localization_service.dart';
import '../../providers/locale_provider.dart';

class SessionCard extends StatelessWidget {
  final Map<String, dynamic> session;
  final VoidCallback onTap;
  final int? index;
  final bool showIndex;
  final bool isFavorite;
  final bool showFavoriteButton;
  final bool showRemoveButton;
  final bool showAddToPlaylist;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onRemove;
  final VoidCallback? onAddToPlaylist;

  const SessionCard({
    super.key,
    required this.session,
    required this.onTap,
    this.index,
    this.showIndex = false,
    this.isFavorite = false,
    this.showFavoriteButton = true,
    this.showRemoveButton = false,
    this.showAddToPlaylist = false,
    this.onToggleFavorite,
    this.onRemove,
    this.onAddToPlaylist,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint('🔍 SESSION DATA: ${session['id']}');
    debugPrint('🖼️ backgroundImages: ${session['backgroundImages']}');
    debugPrint('🖼️ OLD backgroundImage: ${session['backgroundImage']}');
    debugPrint('📝 title: ${session['title']}');
    final colors = context.colors;
    final mq = MediaQuery.of(context);
    final width = mq.size.width;

    // RESPONSIVE BREAKPOINTS
    final bool isTablet =
        width >= Breakpoints.tabletMin && width < Breakpoints.desktopMin;
    final bool isDesktop = width >= Breakpoints.desktopMin;

    // RESPONSIVE VALUES
    final double cardMargin = isTablet ? 18.h : 16.h;
    final double borderRadius = isTablet ? 18.r : 16.r;
    final double imageHeight = isDesktop ? 200.h : (isTablet ? 190.h : 180.h);
    final double contentPadding = isTablet ? 18.w : 16.w;
    final double titleSize =
        isTablet ? 19.sp.clamp(17.0, 21.0) : 18.sp.clamp(16.0, 20.0);
    final double iconSize = isTablet ? 22.sp : 20.sp;
    final double playButtonSize = isTablet ? 60.w : 56.w;
    final double playIconSize = isTablet ? 34.sp : 32.sp;

    final currentLanguage = context.watch<LocaleProvider>().locale.languageCode;
    final localizedContent = SessionLocalizationService.getLocalizedContent(
      session,
      currentLanguage,
    );

// Get language-specific image URL
    String imageUrl = '';

// Try multi-language images first
    if (session['backgroundImages'] is Map) {
      imageUrl = LanguageHelperService.getImageUrl(
        session['backgroundImages'],
        currentLanguage,
      );
    }

// Fallback: old single image format (backward compatibility)
    if (imageUrl.isEmpty && session['backgroundImage'] != null) {
      final backgroundImageRaw = session['backgroundImage'];
      imageUrl = (backgroundImageRaw != null &&
              backgroundImageRaw.toString().isNotEmpty)
          ? backgroundImageRaw.toString()
          : '';
    }

    debugPrint('🖼️ [SessionCard] Image URL for $currentLanguage: $imageUrl');
    final baseTitle = localizedContent.title.isNotEmpty
        ? localizedContent.title
        : AppLocalizations.of(context).untitledSession;

    final title = baseTitle;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: cardMargin),
        decoration: BoxDecoration(
          color: colors.backgroundCard,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: colors.textPrimary.withValues(alpha: 0.08),
              blurRadius: isTablet ? 12 : 10,
              offset: Offset(0, isTablet ? 5 : 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGE SECTION WITH CACHE
            _buildImageSection(
              context,
              imageUrl: imageUrl,
              imageHeight: imageHeight,
              borderRadius: borderRadius,
              playButtonSize: playButtonSize,
              playIconSize: playIconSize,
            ),

            // CONTENT SECTION
            Padding(
              padding: EdgeInsets.all(contentPadding),
              child: Row(
                children: [
                  // Index Number (optional)
                  if (showIndex && index != null) ...[
                    Container(
                      width: isTablet ? 36.w : 32.w,
                      height: isTablet ? 36.w : 32.w,
                      decoration: BoxDecoration(
                        color: colors.textPrimary.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(isTablet ? 9.r : 8.r),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$index',
                        style: GoogleFonts.inter(
                          fontSize: isTablet ? 15.sp : 14.sp,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    SizedBox(width: isTablet ? 14.w : 12.w),
                  ],

                  // Title
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: titleSize,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Action Buttons
                  if (showFavoriteButton && onToggleFavorite != null) ...[
                    SizedBox(width: isTablet ? 10.w : 8.w),
                    _buildActionButton(
                      icon: isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.redAccent : colors.textPrimary,
                      onTap: onToggleFavorite!,
                      iconSize: iconSize,
                      isTablet: isTablet,
                    ),
                  ],

                  if (showRemoveButton && onRemove != null) ...[
                    SizedBox(width: isTablet ? 10.w : 8.w),
                    _buildActionButton(
                      icon: Icons.remove_circle_outline,
                      color: Colors.redAccent,
                      onTap: onRemove!,
                      iconSize: iconSize,
                      isTablet: isTablet,
                    ),
                  ],

                  if (showAddToPlaylist && onAddToPlaylist != null) ...[
                    SizedBox(width: isTablet ? 10.w : 8.w),
                    _buildActionButton(
                      icon: Icons.playlist_add,
                      color: colors.textPrimary,
                      onTap: onAddToPlaylist!,
                      iconSize: iconSize,
                      isTablet: isTablet,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection(
    BuildContext context, {
    required String imageUrl,
    required double imageHeight,
    required double borderRadius,
    required double playButtonSize,
    required double playIconSize,
  }) {
    if (imageUrl.isEmpty) {
      return _buildImageWithGradient(
        context,
        imageHeight: imageHeight,
        borderRadius: borderRadius,
        playButtonSize: playButtonSize,
        playIconSize: playIconSize,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(borderRadius),
        topRight: Radius.circular(borderRadius),
      ),
      child: SizedBox(
        height: imageHeight, // ← EKLEME
        width: double.infinity,
        child: Stack(
          children: [
            // 1. CACHED IMAGE (en altta)
            Positioned.fill(
              // ← DEĞİŞTİRDİM
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                cacheManager: AppCacheManager.instance,
                fit: BoxFit.cover,
                placeholder: (context, url) {
                  debugPrint('⏳ Loading: $url');
                  return _buildShimmerPlaceholder(context);
                },
                errorWidget: (context, url, error) {
                  debugPrint('❌ ERROR loading image: $error');
                  return _buildErrorPlaceholder(context);
                },
                fadeInDuration: const Duration(milliseconds: 300),
                fadeOutDuration: const Duration(milliseconds: 200),
                httpHeaders: const {
                  'Access-Control-Allow-Origin': '*',
                },
              ),
            ),

            // 2. GRADIENT OVERLAY (ortada)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: imageHeight * 0.4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.6),
                    ],
                  ),
                ),
              ),
            ),

            // 3. PLAY BUTTON
            Center(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(100),
                  splashColor: context.colors.background.withValues(alpha: 0.3),
                  child: Container(
                    width: playButtonSize,
                    height: playButtonSize,
                    decoration: BoxDecoration(
                      color: context.colors.background.withValues(alpha: 0.95),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color:
                              context.colors.textPrimary.withValues(alpha: 0.3),
                          blurRadius: 12,
                          spreadRadius: 1,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      size: playIconSize,
                      color: context.colors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWithGradient(
    BuildContext context, {
    required double imageHeight,
    required double borderRadius,
    required double playButtonSize,
    required double playIconSize,
  }) {
    final colors = context.colors;
    final gradientColors = [
      colors.textPrimary.withValues(alpha: 0.7),
      colors.textPrimary.withValues(alpha: 0.5),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(borderRadius),
        topRight: Radius.circular(borderRadius),
      ),
      child: Container(
        height: imageHeight,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
        ),
        child: Stack(
          children: [
            // Emoji
            Center(
              child: Icon(
                Icons.music_note_rounded,
                size: 80.sp,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
            // Play button
            Center(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(100),
                  splashColor: Colors.white.withValues(alpha: 0.3),
                  child: Container(
                    width: playButtonSize,
                    height: playButtonSize,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.play_arrow,
                      size: playIconSize,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerPlaceholder(BuildContext context) {
    final colors = context.colors;
    return Shimmer.fromColors(
      baseColor: colors.greyMedium,
      highlightColor: colors.greyLight,
      child: Container(
        color: colors.backgroundPure,
      ),
    );
  }

  Widget _buildErrorPlaceholder(BuildContext context) {
    final colors = context.colors;
    final gradientColors = [
      colors.textPrimary.withValues(alpha: 0.7),
      colors.textPrimary.withValues(alpha: 0.5),
    ];
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.music_note_rounded,
          size: 80.sp,
          color: Colors.white.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required double iconSize,
    required bool isTablet,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isTablet ? 9.w : 8.w),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(isTablet ? 9.r : 8.r),
        ),
        child: Icon(
          icon,
          size: iconSize,
          color: color,
        ),
      ),
    );
  }
}
