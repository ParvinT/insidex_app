// lib/features/profile/widgets/progress/progress_widgets.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/themes/app_theme_extension.dart';
import '../../services/progress_analytics_service.dart';
export '../../services/progress_analytics_service.dart' show ProgressPeriod;

// Stat Card Widget
class ProgressStatCard extends StatelessWidget {
  final String value;
  final String unit;
  final String label;
  final bool isCompact;

  const ProgressStatCard({
    super.key,
    required this.value,
    required this.unit,
    required this.label,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isCompact ? 12.h : 16.h,
        horizontal: 4.w,
      ),
      decoration: BoxDecoration(
        color: colors.backgroundCard,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: colors.textPrimary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: isCompact ? 22.sp : 28.sp,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                    height: 1,
                  ),
                ),
                SizedBox(width: 2.w),
                Text(
                  unit,
                  style: GoogleFonts.inter(
                    fontSize: isCompact ? 8.sp : 10.sp,
                    color: colors.textSecondary,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: isCompact ? 9.sp : 11.sp,
              color: colors.textSecondary,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// Circular Progress Painter
class CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;
  final double strokeWidth;

  CircularProgressPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background arc
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final progressAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      progressAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}

// Donut Widget
class ProgressDonut extends StatelessWidget {
  final double donutSize;
  final double stroke;
  final Map<String, dynamic> analytics;
  final ProgressPeriod period;

  const ProgressDonut({
    super.key,
    required this.donutSize,
    required this.stroke,
    required this.analytics,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final periodMinutes =
        (analytics['periodMinutes'] ?? analytics['todayMinutes'] ?? 0) as num;
    final periodGoal = (analytics['periodGoal'] ?? 30) as num;
    final double inner = donutSize - 2 * stroke - 16.0;

    // Progress color based on theme
    final progressColor = const Color(0xFF7DB9B6);
    final bgColor = colors.greyMedium;

    return SizedBox(
      width: donutSize,
      height: donutSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Progress ring
          CustomPaint(
            size: Size(donutSize, donutSize),
            painter: CircularProgressPainter(
              progress: (periodMinutes / periodGoal).clamp(0.0, 1.0),
              backgroundColor: bgColor,
              progressColor: progressColor,
              strokeWidth: stroke,
            ),
          ),
          // Center content
          SizedBox(
            width: inner,
            height: inner,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '$periodMinutes',
                    style: GoogleFonts.inter(
                      fontSize: 32.sp,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                      height: 1.0,
                    ),
                  ),
                ),
                SizedBox(height: 2.h),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _getPeriodLabel(context),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: colors.textSecondary,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getPeriodLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (period) {
      case ProgressPeriod.day:
        return l10n.minutesToday;
      case ProgressPeriod.week:
        return l10n.minutesThisWeek;
      case ProgressPeriod.month:
        return l10n.minutesThisMonth;
      case ProgressPeriod.year:
        return l10n.minutesThisYear;
      case ProgressPeriod.analytics:
        return l10n.minutesAllTime;
    }
  }
}

// Top Sessions Widget
class ProgressTopSessions extends StatelessWidget {
  final List<Map<String, dynamic>> topSessions;

  const ProgressTopSessions({
    super.key,
    required this.topSessions,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).topSessions,
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        SizedBox(height: 8.h),
        ..._buildSessionBars(context),
      ],
    );
  }

  List<Widget> _buildSessionBars(BuildContext context) {
    final appColors = context.colors;

    if (topSessions.isEmpty) {
      return [
        Text(
          AppLocalizations.of(context).noSessionsYet,
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            color: appColors.textLight,
            fontStyle: FontStyle.italic,
          ),
        ),
      ];
    }

    final bars = <Widget>[];
    final barColors = [
      const Color(0xFF7DB9B6),
      const Color(0xFFB5A495),
      const Color(0xFF9B8B7E),
    ];

    final maxMinutes =
        topSessions.isNotEmpty ? topSessions.first['totalMinutes'] as int : 1;

    for (int i = 0; i < topSessions.length && i < 3; i++) {
      final session = topSessions[i];
      final minutes = session['totalMinutes'] as int;
      final title = session['title'] as String;
      final width = maxMinutes > 0 ? (minutes / maxMinutes) : 0.0;

      bars.add(
        Container(
          margin: EdgeInsets.only(bottom: 6.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.length > 20 ? '${title.substring(0, 20)}...' : title,
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  color: appColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 2.h),
              Container(
                height: 28.h,
                decoration: BoxDecoration(
                  color: barColors[i].withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Stack(
                  children: [
                    FractionallySizedBox(
                      widthFactor: width,
                      child: Container(
                        decoration: BoxDecoration(
                          color: barColors[i],
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.w),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '$minutes ${AppLocalizations.of(context).min}',
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            color: appColors.background,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return bars;
  }
}

// Progress Bar Widget
class ProgressBar extends StatelessWidget {
  final String label;
  final double progress;
  final Color color;
  final bool isCompact;

  const ProgressBar({
    super.key,
    required this.label,
    required this.progress,
    required this.color,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Icon(Icons.circle, size: isCompact ? 6.sp : 8.sp, color: color),
        SizedBox(width: 8.w),
        ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: 40.w,
            maxWidth: 70.w,
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: isCompact ? 10.sp : 12.sp,
              color: colors.textPrimary,
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: isCompact ? 4.h : 6.h,
                decoration: BoxDecoration(
                  color: colors.greyMedium,
                  borderRadius: BorderRadius.circular(3.r),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: isCompact ? 4.h : 6.h,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3.r),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 8.w),
        Text(
          '${(progress * 100).toInt()}%',
          style: GoogleFonts.inter(
            fontSize: isCompact ? 9.sp : 11.sp,
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// Weekly Chart Widget
class ProgressWeeklyChart extends StatelessWidget {
  final Map<String, int> weeklyData;
  final int todayMinutes;
  final int weeklyTotal;
  final bool isCompact;
  final double chartHeight;

  const ProgressWeeklyChart({
    super.key,
    required this.weeklyData,
    required this.todayMinutes,
    required this.weeklyTotal,
    required this.isCompact,
    required this.chartHeight,
  });

  String _translateDayName(BuildContext context, String dayName) {
    final l10n = AppLocalizations.of(context);
    switch (dayName) {
      case 'Mon':
        return l10n.mon;
      case 'Tue':
        return l10n.tue;
      case 'Wed':
        return l10n.wed;
      case 'Thu':
        return l10n.thu;
      case 'Fri':
        return l10n.fri;
      case 'Sat':
        return l10n.sat;
      case 'Sun':
        return l10n.sun;
      default:
        return dayName;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: EdgeInsets.all(isCompact ? 12.w : 16.w),
      decoration: BoxDecoration(
        color: colors.backgroundCard,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context).thisWeek,
                style: GoogleFonts.inter(
                  fontSize: isCompact ? 12.sp : 14.sp,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              Text(
                '$weeklyTotal ${AppLocalizations.of(context).min} ${AppLocalizations.of(context).total}',
                style: GoogleFonts.inter(
                  fontSize: isCompact ? 10.sp : 12.sp,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          SizedBox(
            height: chartHeight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _buildWeeklyBars(context),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildWeeklyBars(BuildContext context) {
    final colors = context.colors;
    final now = DateTime.now();
    final bars = <Widget>[];

    int maxMinutes = 60;
    if (weeklyData.values.isNotEmpty) {
      final maxValue = weeklyData.values.reduce((a, b) => a > b ? a : b);
      if (maxValue > 0) {
        maxMinutes = maxValue;
      }
    }

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayName = ProgressAnalyticsService.getDayName(date.weekday);
      final minutes = weeklyData[dayName] ?? 0;

      // Use today's minutes for current day
      int displayMinutes = minutes;
      if (i == 0) {
        displayMinutes = todayMinutes > 0 ? todayMinutes : minutes;
      }

      final height = maxMinutes > 0 ? (displayMinutes / maxMinutes) : 0.0;

      Color barColor;
      if (displayMinutes == 0) {
        barColor = colors.greyMedium;
      } else if (i == 0) {
        barColor = const Color(0xFFB8A6D9);
      } else {
        barColor = const Color(0xFF7DB9B6);
      }

      bars.add(_buildDayBar(
          context, _translateDayName(context, dayName), height, barColor));
    }

    return bars;
  }

  Widget _buildDayBar(BuildContext context, String day, double t, Color color) {
    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          const double gap = 6;
          // chart yüksekliğine göre 10–13 aralığında ölçekle
          final double fs = (constraints.maxHeight * 0.12).clamp(10.0, 13.0);
          final double labelBox = fs + 8; // metrik payı

          // Bar için gerçekten kullanılabilir yükseklik
          final double maxBarH = (constraints.maxHeight - (labelBox + gap))
              .clamp(0.0, double.infinity);

          // Oransal bar yüksekliği (0..1 arası)
          final double barH = maxBarH * t.clamp(0.0, 1.0);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2), // yatay aralık
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: double.infinity,
                  height: barH,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ),
                const SizedBox(height: gap),
                SizedBox(
                  height: labelBox,
                  child: FittedBox(
                    // küçük ekranlarda metni güvenle sığdırır
                    fit: BoxFit.scaleDown,
                    child: Text(
                      day,
                      style: GoogleFonts.inter(
                        fontSize: fs,
                        height: 1.0,
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
