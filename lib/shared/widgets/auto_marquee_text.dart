import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';

class AutoMarqueeText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final double velocity;
  final double blankSpace;
  final Duration pauseAfterRound;
  final Duration startAfter;
  final Alignment alignment;

  const AutoMarqueeText({
    super.key,
    required this.text,
    required this.style,
    this.velocity = 30.0,
    this.blankSpace = 40.0,
    this.pauseAfterRound = const Duration(seconds: 2),
    this.startAfter = const Duration(seconds: 1),
    this.alignment = Alignment.centerLeft,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textPainter = TextPainter(
          text: TextSpan(text: text, style: style),
          maxLines: 1,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: double.infinity);

        final isOverflowing = textPainter.size.width > constraints.maxWidth;

        if (isOverflowing) {
          return SizedBox(
            height: textPainter.size.height * 1.15,
            child: Marquee(
              text: text,
              style: style,
              scrollAxis: Axis.horizontal,
              crossAxisAlignment: CrossAxisAlignment.center,
              blankSpace: blankSpace,
              velocity: velocity,
              pauseAfterRound: pauseAfterRound,
              startAfter: startAfter,
              accelerationDuration: const Duration(milliseconds: 500),
              accelerationCurve: Curves.easeOut,
              decelerationDuration: const Duration(milliseconds: 500),
              decelerationCurve: Curves.easeIn,
            ),
          );
        }

        return Align(
          alignment: alignment,
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        );
      },
    );
  }
}
