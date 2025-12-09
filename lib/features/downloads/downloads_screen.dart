// lib/features/downloads/downloads_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:io';

import '../../core/constants/app_colors.dart';
import '../../core/responsive/context_ext.dart';
import '../../models/downloaded_session.dart';
import '../../providers/download_provider.dart';
import '../../l10n/app_localizations.dart';
import '../player/audio_player_screen.dart';
import '../../services/download/decryption_preloader.dart';
import '../../services/language_helper_service.dart';

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
    final l10n = AppLocalizations.of(context);
    final isTablet = context.isTablet;
    final isDesktop = context.isDesktop;

    // Responsive values
    final double horizontalPadding =
        isDesktop ? 32.w : (isTablet ? 24.w : 20.w);
    final double toolbarHeight = isDesktop ? 80.0 : (isTablet ? 70.0 : 60.0);

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        toolbarHeight: toolbarHeight,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppColors.textPrimary,
            size: isTablet ? 28.sp : 24.sp,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.downloads,
          style: GoogleFonts.inter(
            fontSize: isTablet ? 22.sp : 20.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
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
                  color: AppColors.textSecondary,
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
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.textPrimary),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n, bool isTablet) {
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
                color: AppColors.greyLight.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.download_rounded,
                size: isTablet ? 60.sp : 50.sp,
                color: AppColors.textLight,
              ),
            ),
            SizedBox(height: 24.h),

            // Title
            Text(
              l10n.noDownloads,
              style: GoogleFonts.inter(
                fontSize: isTablet ? 20.sp : 18.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12.h),

            // Subtitle
            Text(
              l10n.noDownloadsMessage,
              style: GoogleFonts.inter(
                fontSize: isTablet ? 15.sp : 14.sp,
                color: AppColors.textSecondary,
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
        );
      },
    );
  }

  Widget _buildDownloadCard(
    DownloadedSession download,
    DownloadProvider provider,
    bool isTablet,
    bool isLast,
  ) {
    final double imageSize = isTablet ? 80.w : 70.w;
    final double titleSize = isTablet ? 16.sp : 15.sp;
    final double subtitleSize = isTablet ? 13.sp : 12.sp;
    final double borderRadius = isTablet ? 16.r : 14.r;

    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 12.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _playDownload(download),
          borderRadius: BorderRadius.circular(borderRadius),
          child: Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(borderRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
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
                          color: AppColors.textPrimary,
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
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const Text(
                              ' • ',
                              style: TextStyle(color: AppColors.textLight),
                            ),
                          ],
                          Text(
                            _getLanguageName(download.language),
                            style: GoogleFonts.inter(
                              fontSize: subtitleSize,
                              color: AppColors.textSecondary,
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
                            color: AppColors.textLight,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            download.formattedDuration,
                            style: GoogleFonts.inter(
                              fontSize: subtitleSize,
                              color: AppColors.textLight,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Icon(
                            Icons.storage_rounded,
                            size: subtitleSize,
                            color: AppColors.textLight,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            download.formattedFileSize,
                            style: GoogleFonts.inter(
                              fontSize: subtitleSize,
                              color: AppColors.textLight,
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
                    color: AppColors.textLight,
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
    // Check if local image exists
    final hasLocalImage = download.imagePath.isNotEmpty;

    if (hasLocalImage) {
      final imageFile = File(download.imagePath);

      return FutureBuilder<bool>(
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
    }

    return _buildPlaceholder(size, borderRadius);
  }

  Widget _buildPlaceholder(double size, double borderRadius) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.greyLight,
        borderRadius: BorderRadius.circular(borderRadius - 4),
      ),
      child: Icon(
        Icons.music_note_rounded,
        color: AppColors.textLight,
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

  Future<void> _playDownload(DownloadedSession download) async {
    _preloader.prioritize(download.sessionId);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AudioPlayerScreen(sessionData: download.toPlayerSessionData()),
      ),
    );
  }

  Future<void> _showDeleteDialog(
    DownloadedSession download,
    DownloadProvider provider,
  ) async {
    final l10n = AppLocalizations.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          l10n.removeDownload,
          style: GoogleFonts.inter(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
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
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              l10n.removeDownloadMessage,
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              l10n.cancel,
              style: const TextStyle(
                color: AppColors.textSecondary,
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
      backgroundColor: Colors.white,
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
                color: AppColors.greyMedium,
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
                color: AppColors.textPrimary,
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
    return Column(
      children: [
        Container(
          width: isTablet ? 60.w : 50.w,
          height: isTablet ? 60.w : 50.w,
          decoration: BoxDecoration(
            color: AppColors.textPrimary.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: isTablet ? 28.sp : 24.sp,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 12.h),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: isTablet ? 22.sp : 20.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: isTablet ? 14.sp : 13.sp,
            color: AppColors.textSecondary,
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
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          l10n.clearAllDownloads,
          style: GoogleFonts.inter(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          l10n.clearAllDownloadsMessage,
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              l10n.cancel,
              style: const TextStyle(
                color: AppColors.textSecondary,
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
