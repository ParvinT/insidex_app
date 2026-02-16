// lib/features/downloads/downloads_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:io';

import '../../core/themes/app_theme_extension.dart';
import '../../core/responsive/context_ext.dart';
import '../../core/routes/player_route.dart';
import '../../models/downloaded_session.dart';
import '../../models/play_context.dart';
import '../../providers/download_provider.dart';
import '../../providers/mini_player_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/upgrade_prompt.dart';
import '../../services/download/decryption_preloader.dart';
import '../../services/language_helper_service.dart';
import '../../services/audio/audio_player_service.dart';

/// Downloads Screen - Shows all downloaded sessions for offline playback
class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  final DecryptionPreloader _preloader = DecryptionPreloader();
  final ScrollController _scrollController = ScrollController();
  List<DownloadedSession> _currentDownloads = [];
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Refresh downloads when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final downloadProvider = context.read<DownloadProvider>();

      // Initialize preloader with current language
      final language = await LanguageHelperService.getCurrentLanguage();
      _preloader.initialize(language: language);

      if (!mounted) return;

      // Refresh downloads
      downloadProvider.refresh();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final currentLang = Localizations.localeOf(context).languageCode;
    _preloader.setLanguage(currentLang);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// Called when user scrolls - triggers pre-decryption for visible items
  void _onScroll() {
    _preloadVisibleSessions();
  }

  /// Preload visible sessions for instant playback
  void _preloadVisibleSessions() {
    if (_currentDownloads.isEmpty) return;

    // Get visible item indices
    final visibleIds = _getVisibleSessionIds();

    if (visibleIds.isNotEmpty) {
      _preloader.preloadVisibleSessions(visibleIds);
    }
  }

  /// Calculate which session IDs are currently visible
  List<String> _getVisibleSessionIds() {
    if (!_scrollController.hasClients) return [];
    if (_currentDownloads.isEmpty) return [];

    // Approximate item height (adjust based on your card size)
    const double itemHeight = 90.0;

    final scrollOffset = _scrollController.offset;
    final viewportHeight = _scrollController.position.viewportDimension;

    // Calculate visible range
    final firstVisible = (scrollOffset / itemHeight).floor();
    final lastVisible = ((scrollOffset + viewportHeight) / itemHeight).ceil();

    // Add buffer for smoother experience
    final startIndex = (firstVisible - 1).clamp(
      0,
      _currentDownloads.length - 1,
    );
    final endIndex = (lastVisible + 2).clamp(0, _currentDownloads.length);

    // Extract session IDs
    final visibleIds = <String>[];
    for (int i = startIndex; i < endIndex; i++) {
      visibleIds.add(_currentDownloads[i].sessionId);
    }

    return visibleIds;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final isTablet = context.isTablet;
    final isDesktop = context.isDesktop;

    // Responsive values
    final double horizontalPadding =
        isDesktop ? 32.w : (isTablet ? 24.w : 20.w);
    final double toolbarHeight = isDesktop ? 80.0 : (isTablet ? 70.0 : 60.0);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        toolbarHeight: toolbarHeight,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: colors.textPrimary,
            size: isTablet ? 28.sp : 24.sp,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.downloads,
          style: GoogleFonts.inter(
            fontSize: isTablet ? 22.sp : 20.sp,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          // Storage info button
          Consumer<DownloadProvider>(
            builder: (context, provider, _) {
              if (!provider.hasDownloads) return const SizedBox.shrink();

              return IconButton(
                icon: Icon(
                  Icons.storage_rounded,
                  color: colors.textSecondary,
                  size: isTablet ? 26.sp : 22.sp,
                ),
                onPressed: () => _showStorageInfo(context, provider),
              );
            },
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: Consumer<DownloadProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return _buildLoadingState();
          }

          if (!provider.hasDownloads) {
            return _buildEmptyState(l10n, isTablet);
          }

          return _buildDownloadsList(
            provider.downloads,
            provider,
            horizontalPadding,
            isTablet,
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(context.colors.textPrimary),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n, bool isTablet) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              width: isTablet ? 120.w : 100.w,
              height: isTablet ? 120.w : 100.w,
              decoration: BoxDecoration(
                color: colors.greyLight.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.download_rounded,
                size: isTablet ? 60.sp : 50.sp,
                color: colors.textLight,
              ),
            ),
            SizedBox(height: 24.h),

            // Title
            Text(
              l10n.noDownloads,
              style: GoogleFonts.inter(
                fontSize: isTablet ? 20.sp : 18.sp,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12.h),

            // Subtitle
            Text(
              l10n.noDownloadsMessage,
              style: GoogleFonts.inter(
                fontSize: isTablet ? 15.sp : 14.sp,
                color: colors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadsList(
    List<DownloadedSession> downloads,
    DownloadProvider provider,
    double horizontalPadding,
    bool isTablet,
  ) {
    _currentDownloads = downloads;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preloadVisibleSessions();
    });
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: 16.h,
      ),
      itemCount: downloads.length,
      itemBuilder: (context, index) {
        final download = downloads[index];
        return _buildDownloadCard(
          download,
          provider,
          isTablet,
          index == downloads.length - 1,
          index,
        );
      },
    );
  }

  Widget _buildDownloadCard(
    DownloadedSession download,
    DownloadProvider provider,
    bool isTablet,
    bool isLast,
    int index,
  ) {
    final colors = context.colors;
    final double imageSize = isTablet ? 80.w : 70.w;
    final double titleSize = isTablet ? 16.sp : 15.sp;
    final double subtitleSize = isTablet ? 13.sp : 12.sp;
    final double borderRadius = isTablet ? 16.r : 14.r;

    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 12.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _playDownload(download, index),
          borderRadius: BorderRadius.circular(borderRadius),
          child: Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: colors.backgroundCard,
              borderRadius: BorderRadius.circular(borderRadius),
              boxShadow: [
                BoxShadow(
                  color: colors.textPrimary.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Thumbnail
                _buildThumbnail(download, imageSize, borderRadius),
                SizedBox(width: 14.w),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Title
                      Text(
                        download.displayTitle,
                        style: GoogleFonts.inter(
                          fontSize: titleSize,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),

                      // Category & Language
                      Row(
                        children: [
                          if (download.categoryName != null) ...[
                            Text(
                              download.categoryName!,
                              style: GoogleFonts.inter(
                                fontSize: subtitleSize,
                                color: colors.textSecondary,
                              ),
                            ),
                            Text(
                              ' • ',
                              style: TextStyle(color: colors.textLight),
                            ),
                          ],
                          Text(
                            _getLanguageName(download.language),
                            style: GoogleFonts.inter(
                              fontSize: subtitleSize,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),

                      // Duration & Size
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: subtitleSize,
                            color: colors.textLight,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            download.formattedDuration,
                            style: GoogleFonts.inter(
                              fontSize: subtitleSize,
                              color: colors.textLight,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Icon(
                            Icons.storage_rounded,
                            size: subtitleSize,
                            color: colors.textLight,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            download.formattedFileSize,
                            style: GoogleFonts.inter(
                              fontSize: subtitleSize,
                              color: colors.textLight,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Delete button
                IconButton(
                  onPressed: () => _showDeleteDialog(download, provider),
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: colors.textLight,
                    size: isTablet ? 24.sp : 22.sp,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(
    DownloadedSession download,
    double size,
    double borderRadius,
  ) {
    // Check if user can play offline (Standard tier)
    final subscriptionProvider = context.read<SubscriptionProvider>();
    final isLocked = !subscriptionProvider.canDownload;

    // Check if local image exists
    final hasLocalImage = download.imagePath.isNotEmpty;

    Widget imageWidget;

    if (hasLocalImage) {
      final imageFile = File(download.imagePath);

      imageWidget = FutureBuilder<bool>(
        future: imageFile.exists(),
        builder: (context, snapshot) {
          if (snapshot.data == true) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius - 4),
              child: Image.file(
                imageFile,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    _buildPlaceholder(size, borderRadius),
              ),
            );
          }
          return _buildPlaceholder(size, borderRadius);
        },
      );
    } else {
      imageWidget = _buildPlaceholder(size, borderRadius);
    }

    // If locked, add overlay with lock icon
    if (isLocked) {
      return SizedBox(
        width: size,
        height: size,
        child: Stack(
          children: [
            // Image
            imageWidget,

            // Dark overlay + lock icon
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(borderRadius - 4),
                ),
                child: Center(
                  child: Icon(
                    Icons.lock_rounded,
                    color: Colors.white,
                    size: size * 0.35,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return imageWidget;
  }

  Widget _buildPlaceholder(double size, double borderRadius) {
    final colors = context.colors;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.greyLight,
        borderRadius: BorderRadius.circular(borderRadius - 4),
      ),
      child: Icon(
        Icons.music_note_rounded,
        color: colors.textLight,
        size: size * 0.4,
      ),
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'tr':
        return 'Türkçe';
      case 'ru':
        return 'Русский';
      case 'hi':
        return 'हिन्दी';
      default:
        return code.toUpperCase();
    }
  }

  Future<void> _playDownload(DownloadedSession download, int index) async {
    // ✅ CHECK SUBSCRIPTION - Can user play offline content?
    final subscriptionProvider = context.read<SubscriptionProvider>();

    if (!subscriptionProvider.canDownload) {
      // User is Lite or Free - check internet status
      final connectivityResult = await Connectivity().checkConnectivity();
      final hasInternet = connectivityResult.any(
        (result) => result != ConnectivityResult.none,
      );

      if (hasInternet) {
        // Online - show upgrade prompt with upgrade option
        final l10n = AppLocalizations.of(context);
        final purchased = await showUpgradeBottomSheet(
          context,
          feature: 'offline_playback',
          title: l10n.offlinePlaybackTitle,
          subtitle: l10n.offlinePlaybackSubtitle,
        );

        // If not purchased, don't play
        if (purchased != true) return;

        // Re-check after potential purchase
        if (!subscriptionProvider.canDownload) return;
      } else {
        // Offline - show info-only modal (no upgrade button)
        await showOfflineUpgradeInfo(context);
        return;
      }
    }

    // ✅ User has Standard - proceed with playback
    // Stop current audio and dismiss mini player BEFORE navigating
    final audioService = AudioPlayerService();
    await audioService.stop();

    // Dismiss mini player to prevent state conflicts
    if (mounted) {
      final miniPlayer = context.read<MiniPlayerProvider>();
      miniPlayer.dismiss();
    }

    // Small delay to ensure cleanup completes
    await Future.delayed(const Duration(milliseconds: 100));

    _preloader.prioritize(download.sessionId);

    if (!mounted) return;

    final downloadProvider = context.read<DownloadProvider>();
    final sessionList =
        downloadProvider.downloads.map((d) => d.toPlayerSessionData()).toList();

    final playContext = PlayContext(
      type: PlayContextType.playlist,
      sourceTitle: AppLocalizations.of(context).downloads,
      sessionList: sessionList,
      currentIndex: index,
    );

    Navigator.push(
        context,
        PlayerRoute(
          sessionData: download.toPlayerSessionData(),
          playContext: playContext,
        ));
  }

  Future<void> _showDeleteDialog(
    DownloadedSession download,
    DownloadProvider provider,
  ) async {
    final l10n = AppLocalizations.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.colors.backgroundElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          l10n.removeDownload,
          style: GoogleFonts.inter(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: context.colors.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              download.displayTitle,
              style: GoogleFonts.inter(
                fontSize: 15.sp,
                fontWeight: FontWeight.w500,
                color: context.colors.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              l10n.removeDownloadMessage,
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                color: context.colors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              l10n.cancel,
              style: TextStyle(
                color: context.colors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n.remove,
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await provider.deleteDownload(download.sessionId, download.language);
    }
  }

  void _showStorageInfo(BuildContext context, DownloadProvider provider) {
    final l10n = AppLocalizations.of(context);
    final stats = provider.stats;
    final isTablet = context.isTablet;

    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.backgroundElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: context.colors.greyMedium,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 24.h),

            // Title
            Text(
              l10n.storageUsed,
              style: GoogleFonts.inter(
                fontSize: isTablet ? 20.sp : 18.sp,
                fontWeight: FontWeight.w600,
                color: context.colors.textPrimary,
              ),
            ),
            SizedBox(height: 24.h),

            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem(
                  icon: Icons.music_note_rounded,
                  value: '${stats?.totalCount ?? 0}',
                  label: l10n.sessions,
                  isTablet: isTablet,
                ),
                _buildStatItem(
                  icon: Icons.storage_rounded,
                  value: stats?.formattedSize ?? '0 MB',
                  label: l10n.totalSize,
                  isTablet: isTablet,
                ),
              ],
            ),
            SizedBox(height: 24.h),

            // Clear all button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _confirmClearAll(context, provider),
                icon: const Icon(Icons.delete_sweep_rounded, color: Colors.red),
                label: Text(
                  l10n.clearAllDownloads,
                  style: GoogleFonts.inter(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.red.withValues(alpha: 0.5)),
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required bool isTablet,
  }) {
    final colors = context.colors;
    return Column(
      children: [
        Container(
          width: isTablet ? 60.w : 50.w,
          height: isTablet ? 60.w : 50.w,
          decoration: BoxDecoration(
            color: colors.textPrimary.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: isTablet ? 28.sp : 24.sp,
            color: colors.textPrimary,
          ),
        ),
        SizedBox(height: 12.h),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: isTablet ? 22.sp : 20.sp,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: isTablet ? 14.sp : 13.sp,
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }

  Future<void> _confirmClearAll(
    BuildContext context,
    DownloadProvider provider,
  ) async {
    Navigator.pop(context); // Close bottom sheet

    final l10n = AppLocalizations.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.colors.backgroundElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          l10n.clearAllDownloads,
          style: GoogleFonts.inter(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: context.colors.textPrimary,
          ),
        ),
        content: Text(
          l10n.clearAllDownloadsMessage,
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            color: context.colors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              l10n.cancel,
              style: TextStyle(
                color: context.colors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n.clearAll,
              style: const TextStyle(
                  color: Colors.red, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await provider.deleteAllDownloads();
    }
  }
}
