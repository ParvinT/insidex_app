// lib/features/player/widgets/player_widgets.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:marquee/marquee.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/themes/app_theme_extension.dart';

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
            icon: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: colors.greyLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.info_outline,
                color: colors.textPrimary,
                size: 22.sp,
              ),
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
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 40.w),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: ScrollingText(
              text: title,
              style: GoogleFonts.inter(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
              maxWidth: MediaQuery.of(context).size.width - 40.w,
            ),
          ),
          SizedBox(height: 8.h),
          SizedBox(
            width: 150.w,
            child: ScrollingText(
              text: subtitle,
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                color: colors.textSecondary,
              ),
              maxWidth: 150.w,
            ),
          ),
        ],
      ),
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
    final colors = context.colors;
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
              color: colors.greyLight,
              borderRadius: BorderRadius.circular(25.r),
              border: Border.all(
                color: colors.border,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.info_outline,
                  color: colors.textPrimary,
                  size: 18.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  AppLocalizations.of(context).introduction,
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
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
class PlayerProgressBar extends StatelessWidget {
  final Duration position;
  final Duration duration;
  final Function(Duration) onSeek;

  const PlayerProgressBar({
    super.key,
    required this.position,
    required this.duration,
    required this.onSeek,
  });

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final total =
        duration.inMilliseconds > 0 ? duration : const Duration(minutes: 10);

    final value = total.inMilliseconds == 0
        ? 0.0
        : (position.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 30.w),
      child: Column(
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: colors.textPrimary,
              inactiveTrackColor: colors.greyLight,
              thumbColor: colors.textPrimary,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6.r),
              trackHeight: 3.h,
              overlayShape: RoundSliderOverlayShape(overlayRadius: 12.r),
              overlayColor: colors.textPrimary.withValues(alpha: 0.1),
            ),
            child: Slider(
              value: value,
              onChanged: (v) {
                final newMs = (total.inMilliseconds * v).round();
                onSeek(Duration(milliseconds: newMs));
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 5.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(position),
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: colors.textSecondary,
                  ),
                ),
                Text(
                  duration.inMilliseconds > 0
                      ? _formatDuration(duration)
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

/// Play/Pause controls with skip buttons
class PlayerPlayControls extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onPlayPause;
  final VoidCallback onReplay10;
  final VoidCallback onForward10;

  const PlayerPlayControls({
    super.key,
    required this.isPlaying,
    required this.onPlayPause,
    required this.onReplay10,
    required this.onForward10,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(
            Icons.replay_10,
            color:
                context.isDarkMode ? colors.textSecondary : colors.textPrimary,
          ),
          iconSize: 32.sp,
          onPressed: onReplay10,
        ),
        SizedBox(width: 20.w),
        GestureDetector(
          onTap: onPlayPause,
          child: Container(
            width: 70.w,
            height: 70.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.isDarkMode
                  ? colors.textSecondary
                  : colors.textPrimary,
              boxShadow: [
                BoxShadow(
                  color: (context.isDarkMode
                          ? colors.textSecondary
                          : colors.textPrimary)
                      .withValues(alpha: 0.12),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              isPlaying ? Icons.pause : Icons.play_arrow,
              color: colors.textOnPrimary,
              size: 35.sp,
            ),
          ),
        ),
        SizedBox(width: 20.w),
        IconButton(
          icon: Icon(
            Icons.forward_10,
            color:
                context.isDarkMode ? colors.textSecondary : colors.textPrimary,
          ),
          iconSize: 32.sp,
          onPressed: onForward10,
        ),
      ],
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
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 50.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: Icon(
              Icons.loop,
              color: isLooping ? colors.textPrimary : colors.textLight,
            ),
            onPressed: onLoop,
          ),

          if (!isOffline)
            IconButton(
              icon: Icon(
                isInPlaylist ? Icons.playlist_add_check : Icons.playlist_add,
                color: isInPlaylist ? colors.textPrimary : colors.textLight,
              ),
              onPressed: onPlaylist,
            ),

          // Favorite
          if (!isOffline)
            IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.red : colors.textLight,
              ),
              onPressed: onFavorite,
            ),

          // Timer
          IconButton(
            icon: Icon(
              Icons.access_time,
              color: isTimerActive ? colors.textPrimary : colors.textLight,
            ),
            onPressed: onTimer,
          ),

          if (downloadButton != null) downloadButton!,
        ],
      ),
    );
  }
}

/// Scrolling text widget for long titles
class ScrollingText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final double maxWidth;

  const ScrollingText({
    super.key,
    required this.text,
    required this.style,
    required this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);

    final needsScrolling = textPainter.didExceedMaxLines;

    if (!needsScrolling) {
      return Text(
        text,
        style: style,
        maxLines: 1,
        overflow: TextOverflow.visible,
        textAlign: TextAlign.center,
      );
    }

    return SizedBox(
      width: maxWidth,
      height: style.fontSize! * 1.5,
      child: Marquee(
        text: text,
        style: style,
        scrollAxis: Axis.horizontal,
        crossAxisAlignment: CrossAxisAlignment.center,
        blankSpace: 40.w,
        velocity: 30.0,
        pauseAfterRound: const Duration(seconds: 2),
        startPadding: 10.w,
        accelerationDuration: const Duration(milliseconds: 500),
        accelerationCurve: Curves.easeInOut,
        decelerationDuration: const Duration(milliseconds: 500),
        decelerationCurve: Curves.easeInOut,
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
