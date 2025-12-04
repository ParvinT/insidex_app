// lib/features/downloads/widgets/download_button.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../providers/download_provider.dart';
import '../../../providers/locale_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/downloaded_session.dart';

/// Download button widget for session cards
/// Shows different states: not downloaded, downloading, downloaded
class DownloadButton extends StatefulWidget {
  final Map<String, dynamic> session;
  final double? size;
  final bool showBackground;
  final VoidCallback? onDownloadStarted;
  final VoidCallback? onDownloadCompleted;
  final VoidCallback? onDeleted;

  const DownloadButton({
    super.key,
    required this.session,
    this.size,
    this.showBackground = true,
    this.onDownloadStarted,
    this.onDownloadCompleted,
    this.onDeleted,
  });

  @override
  State<DownloadButton> createState() => _DownloadButtonState();
}

class _DownloadButtonState extends State<DownloadButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _isDownloaded = false;
  bool _isChecking = true;

  // ✅ Track subscription to prevent memory leak
  StreamSubscription? _progressSubscription;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _checkDownloadStatus();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _progressSubscription?.cancel(); // ✅ Cancel subscription
    super.dispose();
  }

  Future<void> _checkDownloadStatus() async {
    final sessionId = widget.session['id'] as String?;
    if (sessionId == null) {
      setState(() => _isChecking = false);
      return;
    }

    final provider = context.read<DownloadProvider>();
    final language = context.read<LocaleProvider>().locale.languageCode;

    final isDownloaded = await provider.isDownloaded(sessionId, language);

    if (mounted) {
      setState(() {
        _isDownloaded = isDownloaded;
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final width = mq.size.width;
    final isTablet =
        width >= Breakpoints.tabletMin && width < Breakpoints.desktopMin;

    final double iconSize = widget.size ?? (isTablet ? 22.sp : 20.sp);
    final double buttonSize = iconSize * 1.8;

    final sessionId = widget.session['id'] as String?;
    if (sessionId == null) {
      return const SizedBox.shrink();
    }

    return Consumer2<DownloadProvider, LocaleProvider>(
      builder: (context, downloadProvider, localeProvider, _) {
        final language = localeProvider.locale.languageCode;
        final isDownloading =
            downloadProvider.isDownloading(sessionId, language);
        final progress = downloadProvider.getProgress(sessionId, language);

        // Show loading while checking
        if (_isChecking) {
          return SizedBox(
            width: buttonSize,
            height: buttonSize,
            child: Center(
              child: SizedBox(
                width: iconSize * 0.8,
                height: iconSize * 0.8,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.textSecondary.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          );
        }

        // Downloading state
        if (isDownloading && progress != null) {
          return _buildDownloadingButton(
            buttonSize: buttonSize,
            iconSize: iconSize,
            progress: progress.progress,
            onCancel: () =>
                _cancelDownload(downloadProvider, sessionId, language),
          );
        }

        // Downloaded state
        if (_isDownloaded) {
          return _buildDownloadedButton(
            buttonSize: buttonSize,
            iconSize: iconSize,
            isTablet: isTablet,
            onDelete: () => _showDeleteDialog(
                context, downloadProvider, sessionId, language),
          );
        }

        // Not downloaded state
        return _buildNotDownloadedButton(
          buttonSize: buttonSize,
          iconSize: iconSize,
          isTablet: isTablet,
          isOffline: downloadProvider.isOffline,
          onDownload: () => _startDownload(downloadProvider, language),
        );
      },
    );
  }

  Widget _buildNotDownloadedButton({
    required double buttonSize,
    required double iconSize,
    required bool isTablet,
    required bool isOffline,
    required VoidCallback onDownload,
  }) {
    return GestureDetector(
      onTap: isOffline ? null : onDownload,
      child: Container(
        width: buttonSize,
        height: buttonSize,
        decoration: widget.showBackground
            ? BoxDecoration(
                color: isOffline
                    ? AppColors.greyLight.withOpacity(0.5)
                    : AppColors.textPrimary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(buttonSize / 2),
              )
            : null,
        child: Icon(
          Icons.download_rounded,
          size: iconSize,
          color: isOffline ? AppColors.textLight : AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildDownloadingButton({
    required double buttonSize,
    required double iconSize,
    required double progress,
    required VoidCallback onCancel,
  }) {
    return GestureDetector(
      onTap: onCancel,
      child: SizedBox(
        width: buttonSize,
        height: buttonSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Progress circle
            SizedBox(
              width: buttonSize * 0.85,
              height: buttonSize * 0.85,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 2.5,
                backgroundColor: AppColors.greyLight,
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.textPrimary),
              ),
            ),
            // Stop icon
            Icon(
              Icons.stop_rounded,
              size: iconSize * 0.7,
              color: AppColors.textPrimary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadedButton({
    required double buttonSize,
    required double iconSize,
    required bool isTablet,
    required VoidCallback onDelete,
  }) {
    return GestureDetector(
      onTap: onDelete,
      child: Container(
        width: buttonSize,
        height: buttonSize,
        decoration: widget.showBackground
            ? BoxDecoration(
                color: Colors.green.withOpacity(0.12),
                borderRadius: BorderRadius.circular(buttonSize / 2),
              )
            : null,
        child: Icon(
          Icons.download_done_rounded,
          size: iconSize,
          color: Colors.green,
        ),
      ),
    );
  }

  Future<void> _startDownload(
      DownloadProvider provider, String language) async {
    widget.onDownloadStarted?.call();

    // ✅ Cancel previous subscription if exists
    await _progressSubscription?.cancel();

    final success = await provider.downloadSession(
      sessionData: widget.session,
      language: language,
    );

    if (success && mounted) {
      _listenForCompletion(provider, language);
    }
  }

  void _listenForCompletion(DownloadProvider provider, String language) {
    final sessionId = widget.session['id'] as String;
    final key = '${sessionId}_$language';

    // ✅ Store subscription for proper cleanup
    _progressSubscription = provider.progressStream.listen((progress) {
      if (progress.key == key) {
        if (progress.status == DownloadStatus.completed) {
          if (mounted) {
            setState(() => _isDownloaded = true);
            widget.onDownloadCompleted?.call();
          }
          // ✅ Cancel after completion
          _progressSubscription?.cancel();
        } else if (progress.status == DownloadStatus.failed) {
          // ✅ Handle cancel/failure - reset UI
          if (mounted) {
            setState(() => _isDownloaded = false);
          }
          _progressSubscription?.cancel();
        }
      }
    });
  }

  Future<void> _cancelDownload(
    DownloadProvider provider,
    String sessionId,
    String language,
  ) async {
    // ✅ Cancel subscription first
    await _progressSubscription?.cancel();
    _progressSubscription = null;

    await provider.cancelDownload(sessionId, language);

    // ✅ Reset state immediately
    if (mounted) {
      setState(() => _isDownloaded = false);
    }
  }

  Future<void> _showDeleteDialog(
    BuildContext context,
    DownloadProvider provider,
    String sessionId,
    String language,
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
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          l10n.removeDownloadMessage,
          style: TextStyle(
            fontSize: 14.sp,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              l10n.cancel,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n.remove,
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await provider.deleteDownload(sessionId, language);
      if (mounted) {
        setState(() => _isDownloaded = false);
        widget.onDeleted?.call();
      }
    }
  }
}

/// Small download indicator for mini player or compact views
class DownloadIndicator extends StatelessWidget {
  final bool isDownloaded;
  final double size;

  const DownloadIndicator({
    super.key,
    required this.isDownloaded,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    if (!isDownloaded) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.download_done_rounded,
        size: size,
        color: Colors.green,
      ),
    );
  }
}
