// lib/features/player/widgets/player_widgets.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/themes/app_theme_extension.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/auto_marquee_text.dart';

/// Header with back button, title, and info button
class PlayerHeader extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onInfo;

  const PlayerHeader({
    super.key,
    required this.onBack,
    required this.onInfo,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(
              Icons.keyboard_arrow_down,
              color: colors.textPrimary,
              size: 30.sp,
            ),
            onPressed: onBack,
          ),
          Text(
            AppLocalizations.of(context).nowPlaying,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.info_outline,
              color: colors.textPrimary,
              size: 26.sp,
            ),
            onPressed: onInfo,
          ),
        ],
      ),
    );
  }
}

/// Modern equalizer animation visualizer
class PlayerVisualizer extends StatelessWidget {
  final AnimationController controller;
  final bool isPlaying;

  const PlayerVisualizer({
    super.key,
    required this.controller,
    required this.isPlaying,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      width: 220.w,
      height: 220.w,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final t = controller.value;
          final phases = [0.00, 0.22, 0.44, 0.66, 0.88];
          final bars = phases.map((p) {
            final s = 0.5 * (1 + math.sin(2 * math.pi * (t + p)));
            return 60 + 60 * s; // 60..120 px
          }).toList();

          return CustomPaint(
              painter: EqPainter(
            bars,
            ringColor: colors.greyMedium,
            barColor: colors.textPrimary,
          ));
        },
      ),
    );
  }
}

/// Session title and subtitle info
class PlayerSessionInfo extends StatelessWidget {
  final String title;
  final String subtitle;

  const PlayerSessionInfo({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = MediaQuery.of(context).size.width >= 600;
        final horizontalPadding = isTablet ? 60.w : 40.w;
        final subtitleWidth = isTablet ? 220.w : 180.w;
        final titleFontSize = isTablet ? 24.sp : 20.sp;
        final subtitleFontSize = isTablet ? 16.sp : 14.sp;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            children: [
              AutoMarqueeText(
                text: title,
                style: GoogleFonts.inter(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
                alignment: Alignment.center,
              ),
              SizedBox(height: 8.h),
              SizedBox(
                width: subtitleWidth,
                child: AutoMarqueeText(
                  text: subtitle,
                  style: GoogleFonts.inter(
                    fontSize: subtitleFontSize,
                    color: colors.textSecondary,
                  ),
                  alignment: Alignment.center,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Introduction button
class IntroductionButton extends StatelessWidget {
  final VoidCallback onTap;

  const IntroductionButton({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 60.w),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(25.r),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 24.w),
            decoration: BoxDecoration(
              color: AppColors.darkBackgroundElevated.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(25.r),
              border: Border.all(
                color: AppColors.darkTextPrimary.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.darkTextPrimary,
                  size: 18.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  AppLocalizations.of(context).introduction,
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkTextPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Progress bar with time labels
/// Uses local state during drag to prevent jitter from position stream
class PlayerProgressBar extends StatefulWidget {
  final Duration position;
  final Duration duration;
  final Function(Duration) onSeek;

  const PlayerProgressBar({
    super.key,
    required this.position,
    required this.duration,
    required this.onSeek,
  });

  @override
  State<PlayerProgressBar> createState() => _PlayerProgressBarState();
}

class _PlayerProgressBarState extends State<PlayerProgressBar> {
  bool _isDragging = false;
  double _dragValue = 0.0;

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final total = widget.duration.inMilliseconds > 0
        ? widget.duration
        : const Duration(minutes: 10);

    // During drag, use local value; otherwise use stream value
    final double value = _isDragging
        ? _dragValue
        : (total.inMilliseconds == 0
            ? 0.0
            : (widget.position.inMilliseconds / total.inMilliseconds)
                .clamp(0.0, 1.0));

    // Display position based on current state
    final displayPosition = _isDragging
        ? Duration(milliseconds: (total.inMilliseconds * _dragValue).round())
        : widget.position;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 30.w),
      child: Column(
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: colors.textPrimary,
              inactiveTrackColor: colors.textPrimary.withValues(alpha: 0.3),
              thumbColor: colors.textPrimary,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6.r),
              trackHeight: 3.h,
              overlayShape: RoundSliderOverlayShape(overlayRadius: 12.r),
              overlayColor: colors.textPrimary.withValues(alpha: 0.1),
            ),
            child: Slider(
              value: value,
              onChangeStart: (v) {
                setState(() {
                  _isDragging = true;
                  _dragValue = v;
                });
              },
              onChanged: (v) {
                setState(() {
                  _dragValue = v;
                });
              },
              onChangeEnd: (v) {
                final newMs = (total.inMilliseconds * v).round();
                widget.onSeek(Duration(milliseconds: newMs));
                setState(() {
                  _isDragging = false;
                });
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 5.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(displayPosition),
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: colors.textSecondary,
                  ),
                ),
                Text(
                  widget.duration.inMilliseconds > 0
                      ? _formatDuration(widget.duration)
                      : '--:--',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Play/Pause controls with skip and previous/next buttons
class PlayerPlayControls extends StatelessWidget {
  final bool isPlaying;
  final bool hasPrevious;
  final bool hasNext;
  final VoidCallback onPlayPause;
  final VoidCallback onReplay10;
  final VoidCallback onForward10;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const PlayerPlayControls({
    super.key,
    required this.isPlaying,
    this.hasPrevious = false,
    this.hasNext = false,
    required this.onPlayPause,
    required this.onReplay10,
    required this.onForward10,
    this.onPrevious,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;

    final double skipTrackSize = isTablet ? 42.w : 36.w;
    final double skipTrackIconSize = isTablet ? 24.sp : 20.sp;
    final double skipTimeSize = isTablet ? 50.w : 48.w;
    final double skipTimeIconSize = isTablet ? 28.sp : 26.sp;
    final double playPauseSize = isTablet ? 74.w : 70.w;
    final double playPauseIconSize = isTablet ? 38.sp : 35.sp;
    final double innerSpacing = isTablet ? 18.w : 14.w;
    final double outerSpacing = isTablet ? 14.w : 10.w;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Previous track
        _buildTrackButton(
          icon: Icons.skip_previous_rounded,
          enabled: hasPrevious,
          onTap: onPrevious,
          size: skipTrackSize,
          iconSize: skipTrackIconSize,
        ),

        SizedBox(width: outerSpacing),

        // Rewind 10s
        Container(
          width: skipTimeSize,
          height: skipTimeSize,
          decoration: BoxDecoration(
            color: AppColors.darkBackgroundElevated.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(
              Icons.replay_10,
              color: AppColors.darkTextPrimary,
            ),
            iconSize: skipTimeIconSize,
            padding: EdgeInsets.zero,
            onPressed: onReplay10,
          ),
        ),

        SizedBox(width: innerSpacing),

        // Play/Pause
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onPlayPause,
          child: Container(
            width: playPauseSize,
            height: playPauseSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.darkTextPrimary.withValues(alpha: 0.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.darkBackgroundPure.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              isPlaying ? Icons.pause : Icons.play_arrow,
              color: AppColors.darkTextOnLight,
              size: playPauseIconSize,
            ),
          ),
        ),

        SizedBox(width: innerSpacing),

        // Forward 10s
        Container(
          width: skipTimeSize,
          height: skipTimeSize,
          decoration: BoxDecoration(
            color: AppColors.darkBackgroundElevated.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(
              Icons.forward_10,
              color: AppColors.darkTextPrimary,
            ),
            iconSize: skipTimeIconSize,
            padding: EdgeInsets.zero,
            onPressed: onForward10,
          ),
        ),

        SizedBox(width: outerSpacing),

        // Next track
        _buildTrackButton(
          icon: Icons.skip_next_rounded,
          enabled: hasNext,
          onTap: onNext,
          size: skipTrackSize,
          iconSize: skipTrackIconSize,
        ),
      ],
    );
  }

  Widget _buildTrackButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback? onTap,
    required double size,
    required double iconSize,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: enabled ? 1.0 : 0.3,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.darkBackgroundElevated.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: AppColors.darkTextPrimary,
            size: iconSize,
          ),
        ),
      ),
    );
  }
}

/// Bottom action buttons (loop, favorite, playlist, timer)
class PlayerBottomActions extends StatelessWidget {
  final bool isLooping;
  final bool isFavorite;
  final bool isInPlaylist;
  final bool isOffline;
  final bool isTimerActive;
  final VoidCallback onLoop;
  final VoidCallback onFavorite;
  final VoidCallback onPlaylist;
  final VoidCallback onTimer;
  final Widget? downloadButton;

  const PlayerBottomActions({
    super.key,
    required this.isLooping,
    required this.isFavorite,
    required this.isInPlaylist,
    this.isOffline = false,
    this.isTimerActive = false,
    required this.onLoop,
    required this.onFavorite,
    required this.onPlaylist,
    required this.onTimer,
    this.downloadButton,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 30.w),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: colors.background.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(
          color: colors.textPrimary.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: Icon(
              Icons.loop,
              color: isLooping ? colors.textPrimary : colors.textSecondary,
            ),
            onPressed: onLoop,
          ),

          if (!isOffline)
            IconButton(
              icon: Icon(
                isInPlaylist ? Icons.playlist_add_check : Icons.playlist_add,
                color: isInPlaylist ? colors.textPrimary : colors.textSecondary,
              ),
              onPressed: onPlaylist,
            ),

          // Favorite
          if (!isOffline)
            IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.red : colors.textSecondary,
              ),
              onPressed: onFavorite,
            ),

          // Timer
          IconButton(
            icon: Icon(
              Icons.access_time,
              color: isTimerActive ? colors.textPrimary : colors.textSecondary,
            ),
            onPressed: onTimer,
          ),

          if (downloadButton != null) downloadButton!,
        ],
      ),
    );
  }
}

/// Equalizer painter for visualizer
class EqPainter extends CustomPainter {
  final List<double> bars;
  final Color ringColor;
  final Color barColor;
  EqPainter(this.bars, {required this.ringColor, required this.barColor});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final ringRadius = size.width * 0.38;

    // Draw subtle ring
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = ringColor;
    canvas.drawCircle(Offset(cx, cy), ringRadius, ringPaint);

    // Draw bars
    final barPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = barColor;
    const barWidth = 8.0;
    const spacing = 14.0;
    final totalW = (bars.length * barWidth) + ((bars.length - 1) * spacing);
    var x = cx - totalW / 2;

    for (final h in bars) {
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, cy - h / 2, barWidth, h),
        const Radius.circular(4),
      );
      canvas.drawRRect(rect, barPaint);
      x += barWidth + spacing;
    }
  }

  @override
  bool shouldRepaint(covariant EqPainter oldDelegate) =>
      bars != oldDelegate.bars ||
      ringColor != oldDelegate.ringColor ||
      barColor != oldDelegate.barColor;
}
