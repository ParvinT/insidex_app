// lib/features/player/widgets/player_widgets.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:marquee/marquee.dart';
import '../../../l10n/app_localizations.dart';

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
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(
              Icons.keyboard_arrow_down,
              color: Colors.black,
              size: 30.sp,
            ),
            onPressed: onBack,
          ),
          Text(
            AppLocalizations.of(context).nowPlaying,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF5A5A5A),
              letterSpacing: 1.2,
            ),
          ),
          IconButton(
            icon: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.info_outline,
                color: Colors.black,
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

          return CustomPaint(painter: EqPainter(bars));
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
                color: Colors.black87,
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
                color: const Color(0xFF7A7A7A),
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
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(25.r),
              border: Border.all(
                color: const Color(0xFFE0E0E0),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.info_outline,
                  color: const Color(0xFF191919),
                  size: 18.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  AppLocalizations.of(context).introduction,
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF191919),
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
              activeTrackColor: Colors.black,
              inactiveTrackColor: const Color(0xFFE6E6E6),
              thumbColor: Colors.black,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6.r),
              trackHeight: 3.h,
              overlayShape: RoundSliderOverlayShape(overlayRadius: 12.r),
              overlayColor: Colors.black.withOpacity(0.1),
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
                    color: const Color(0xFF6E6E6E),
                  ),
                ),
                Text(
                  duration.inMilliseconds > 0
                      ? _formatDuration(duration)
                      : '--:--',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: const Color(0xFF6E6E6E),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.replay_10, color: Color(0xFF353535)),
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
              color: Colors.black,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 35.sp,
            ),
          ),
        ),
        SizedBox(width: 20.w),
        IconButton(
          icon: const Icon(Icons.forward_10, color: Color(0xFF353535)),
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
  final VoidCallback onLoop;
  final VoidCallback onFavorite;
  final VoidCallback onPlaylist;
  final VoidCallback onTimer;

  const PlayerBottomActions({
    super.key,
    required this.isLooping,
    required this.isFavorite,
    required this.isInPlaylist,
    required this.onLoop,
    required this.onFavorite,
    required this.onPlaylist,
    required this.onTimer,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 50.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: Icon(
              Icons.loop,
              color: isLooping ? Colors.black : const Color(0xFFBDBDBD),
            ),
            onPressed: onLoop,
          ),
          IconButton(
            icon: Icon(
              isInPlaylist ? Icons.playlist_add_check : Icons.playlist_add,
              color: isInPlaylist ? Colors.black : const Color(0xFFBDBDBD),
            ),
            onPressed: onPlaylist,
          ),
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red : const Color(0xFFBDBDBD),
            ),
            onPressed: onFavorite,
          ),
          IconButton(
            icon: const Icon(
              Icons.access_time,
              color: Color(0xFFBDBDBD),
            ),
            onPressed: onTimer,
          ),
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

  EqPainter(this.bars);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final ringRadius = size.width * 0.38;

    // Draw subtle ring
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.grey.shade300;
    canvas.drawCircle(Offset(cx, cy), ringRadius, ringPaint);

    // Draw bars
    final barPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.black87;

    final barWidth = 8.0;
    final spacing = 14.0;
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
      bars != oldDelegate.bars;
}
