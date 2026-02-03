// lib/features/profile/services/progress_analytics_service.dart

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/listening_tracker_service.dart';

/// Period filter for analytics
enum ProgressPeriod {
  analytics, // All time / Overview
  year,
  month,
  week,
  day,
}

class ProgressAnalyticsService {
  // Goals for each period
  static const int dailyGoal = 30;
  static const int weeklyGoal = 150;
  static const int monthlyGoal = 600;
  static const int yearlyGoal = 7200;

  static Map<String, dynamic> getDefaultAnalytics() {
    return {
      'totalMinutes': 0,
      'totalSessions': 0,
      'currentStreak': 0,
      'weeklyData': <String, int>{},
      'weeklyTotal': 0,
      'monthlyProgress': <String, double>{
        'Day': 0.0,
        'Week': 0.0,
        'Month': 0.0,
        'Year': 0.0,
      },
      'topSessions': <Map<String, dynamic>>[],
      'todayMinutes': 0,
      'periodMinutes': 0,
      'periodGoal': dailyGoal,
      'chartData': <String, int>{},
    };
  }

  // Load all analytics data from Firebase
  static Future<Map<String, dynamic>> loadAnalyticsData({
    ProgressPeriod period = ProgressPeriod.month,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return getDefaultAnalytics();

      // Get user data from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        return getDefaultAnalytics();
      }

      // Get real listening history
      final history =
          await ListeningTrackerService.getListeningHistory(days: 30);

      // Get real weekly stats
      final weeklyStats = await ListeningTrackerService.getWeeklyStats();

      // Calculate real streak
      final streak = await ListeningTrackerService.calculateStreak();

      // Calculate monthly progress (real data)
      final monthlyProgress = calculateMonthlyProgress(history);

      // Get top sessions (real data)
      final topSessions = calculateTopSessions(history);

      // Calculate total weekly minutes
      final weeklyTotal =
          weeklyStats.values.fold<int>(0, (total, minutes) => total + minutes);

      // Calculate period-specific data
      final periodMinutes = getPeriodMinutes(history, period);
      final periodGoal = getGoalForPeriod(period);
      final chartData = getChartDataForPeriod(history, period);
      final periodTopSessions = calculateTopSessionsForPeriod(history, period);

      return {
        'totalMinutes': userDoc.data()?['totalListeningMinutes'] ?? 0,
        'totalSessions':
            (userDoc.data()?['completedSessionIds'] as List?)?.length ?? 0,
        'currentStreak': streak,
        'weeklyData': weeklyStats,
        'weeklyTotal': weeklyTotal,
        'monthlyProgress': monthlyProgress,
        'topSessions': period == ProgressPeriod.analytics
            ? topSessions
            : periodTopSessions,
        'todayMinutes': getTodayMinutes(history),
        'periodMinutes': periodMinutes,
        'periodGoal': periodGoal,
        'chartData': chartData,
        'period': period,
        '_rawHistory': history,
      };
    } catch (e) {
      debugPrint('Error loading analytics: $e');
      return getDefaultAnalytics();
    }
  }

  // Calculate today's listening minutes
  static int getTodayMinutes(List<Map<String, dynamic>> history) {
    final today = DateTime.now().toIso8601String().split('T')[0];
    int totalMinutes = 0;

    for (var session in history) {
      if (session['date'] == today) {
        final status = session['status'] as String?;
        if (status == 'completed') {
          totalMinutes += (session['duration'] as int? ?? 0);
        } else if (status == 'playing' || status == 'paused') {
          // Include accumulated duration for ongoing sessions
          totalMinutes += (session['accumulatedDuration'] as int? ?? 0);
        }
      }
    }

    return totalMinutes;
  }

  // Calculate progress for day/week/month/year
  static Map<String, double> calculateMonthlyProgress(
      List<Map<String, dynamic>> history) {
    final now = DateTime.now();

    // Calculate goals
    const dailyGoal = 30;
    const weeklyGoal = 150;
    const monthlyGoal = 600;
    const yearlyGoal = 7200;

    // Calculate actual listening
    int dayMinutes = 0;
    int weekMinutes = 0;
    int monthMinutes = 0;
    int yearMinutes = 0;

    for (var session in history) {
      final timestamp = session['timestamp'] as Timestamp?;
      if (timestamp == null) continue;

      final sessionDate = timestamp.toDate();
      final status = session['status'] as String?;

      int duration = 0;
      if (status == 'completed') {
        duration = session['duration'] as int? ?? 0;
      } else if (status == 'playing' || status == 'paused') {
        duration = session['accumulatedDuration'] as int? ?? 0;
      }

      // Today
      if (sessionDate.day == now.day &&
          sessionDate.month == now.month &&
          sessionDate.year == now.year) {
        dayMinutes += duration;
      }

      if (duration == 0) continue;

      // This week
      if (sessionDate.isAfter(now.subtract(const Duration(days: 7)))) {
        weekMinutes += duration;
      }

      // This month
      if (sessionDate.month == now.month && sessionDate.year == now.year) {
        monthMinutes += duration;
      }

      // This year
      if (sessionDate.year == now.year) {
        yearMinutes += duration;
      }
    }

    return {
      'Day': (dayMinutes / dailyGoal).clamp(0.0, 1.0),
      'Week': (weekMinutes / weeklyGoal).clamp(0.0, 1.0),
      'Month': (monthMinutes / monthlyGoal).clamp(0.0, 1.0),
      'Year': (yearMinutes / yearlyGoal).clamp(0.0, 1.0),
    };
  }

  // Calculate top 3 most listened sessions
  static List<Map<String, dynamic>> calculateTopSessions(
      List<Map<String, dynamic>> history) {
    final sessionStats = <String, Map<String, dynamic>>{};

    for (var session in history) {
      final status = session['status'] as String?;
      final sessionId = session['sessionId'] as String? ?? '';
      if (sessionId.isEmpty) continue;

      int duration = 0;
      if (status == 'completed') {
        duration = session['duration'] as int? ?? 0;
      } else if (status == 'playing' || status == 'paused') {
        duration = session['accumulatedDuration'] as int? ?? 0;
      }

      final title = session['sessionTitle'] as String? ?? 'Unknown Session';

      if (sessionStats.containsKey(sessionId)) {
        sessionStats[sessionId]!['totalMinutes'] =
            (sessionStats[sessionId]!['totalMinutes'] as int) + duration;
        sessionStats[sessionId]!['count'] =
            (sessionStats[sessionId]!['count'] as int) + 1;
      } else {
        sessionStats[sessionId] = {
          'sessionId': sessionId,
          'title': title,
          'totalMinutes': duration,
          'count': 1,
        };
      }
    }

    // Sort by total minutes and get top 3
    final sorted = sessionStats.values.toList()
      ..sort((a, b) =>
          (b['totalMinutes'] as int).compareTo(a['totalMinutes'] as int));

    return sorted.take(3).toList();
  }

  // Get day name from weekday number
  static String getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return '';
    }
  }

  // Get minutes for selected period
  static int getPeriodMinutes(
      List<Map<String, dynamic>> history, ProgressPeriod period) {
    final now = DateTime.now();
    int totalMinutes = 0;

    for (var session in history) {
      final timestamp = session['timestamp'] as Timestamp?;
      if (timestamp == null) continue;

      final sessionDate = timestamp.toDate();
      final status = session['status'] as String?;

      int duration = 0;
      if (status == 'completed') {
        duration = session['duration'] as int? ?? 0;
      } else if (status == 'playing' || status == 'paused') {
        duration = session['accumulatedDuration'] as int? ?? 0;
      }

      if (duration == 0) continue;

      bool includeSession = false;
      switch (period) {
        case ProgressPeriod.day:
          includeSession = sessionDate.day == now.day &&
              sessionDate.month == now.month &&
              sessionDate.year == now.year;
          break;
        case ProgressPeriod.week:
          includeSession =
              sessionDate.isAfter(now.subtract(const Duration(days: 7)));
          break;
        case ProgressPeriod.month:
          includeSession =
              sessionDate.month == now.month && sessionDate.year == now.year;
          break;
        case ProgressPeriod.year:
          includeSession = sessionDate.year == now.year;
          break;
        case ProgressPeriod.analytics:
          includeSession = true; // All time
          break;
      }

      if (includeSession) {
        totalMinutes += duration;
      }
    }

    return totalMinutes;
  }

// Get goal for selected period
  static int getGoalForPeriod(ProgressPeriod period) {
    switch (period) {
      case ProgressPeriod.day:
        return dailyGoal;
      case ProgressPeriod.week:
        return weeklyGoal;
      case ProgressPeriod.month:
        return monthlyGoal;
      case ProgressPeriod.year:
        return yearlyGoal;
      case ProgressPeriod.analytics:
        return yearlyGoal; // Use yearly goal for all-time view
    }
  }

// Get chart data for selected period
  static Map<String, int> getChartDataForPeriod(
    List<Map<String, dynamic>> history,
    ProgressPeriod period,
  ) {
    final now = DateTime.now();
    final chartData = <String, int>{};

    switch (period) {
      case ProgressPeriod.day:
        // Hourly breakdown (last 24 hours)
        for (int i = 0; i < 24; i++) {
          chartData['${i.toString().padLeft(2, '0')}:00'] = 0;
        }
        for (var session in history) {
          final timestamp = session['timestamp'] as Timestamp?;
          if (timestamp == null) continue;
          final sessionDate = timestamp.toDate();
          if (sessionDate.day == now.day &&
              sessionDate.month == now.month &&
              sessionDate.year == now.year) {
            final hour = '${sessionDate.hour.toString().padLeft(2, '0')}:00';
            final duration = _getSessionDuration(session);
            chartData[hour] = (chartData[hour] ?? 0) + duration;
          }
        }
        break;

      case ProgressPeriod.week:
        // Daily breakdown (last 7 days)
        for (int i = 6; i >= 0; i--) {
          final date = now.subtract(Duration(days: i));
          final dayName = getDayName(date.weekday);
          chartData[dayName] = 0;
        }
        for (var session in history) {
          final timestamp = session['timestamp'] as Timestamp?;
          if (timestamp == null) continue;
          final sessionDate = timestamp.toDate();
          if (sessionDate.isAfter(now.subtract(const Duration(days: 7)))) {
            final dayName = getDayName(sessionDate.weekday);
            final duration = _getSessionDuration(session);
            chartData[dayName] = (chartData[dayName] ?? 0) + duration;
          }
        }
        break;

      case ProgressPeriod.month:
        // Weekly breakdown (4 weeks)
        for (int i = 1; i <= 4; i++) {
          chartData['W$i'] = 0;
        }
        for (var session in history) {
          final timestamp = session['timestamp'] as Timestamp?;
          if (timestamp == null) continue;
          final sessionDate = timestamp.toDate();
          if (sessionDate.month == now.month && sessionDate.year == now.year) {
            final weekOfMonth = ((sessionDate.day - 1) ~/ 7) + 1;
            final weekKey = 'W${weekOfMonth.clamp(1, 4)}';
            final duration = _getSessionDuration(session);
            chartData[weekKey] = (chartData[weekKey] ?? 0) + duration;
          }
        }
        break;

      case ProgressPeriod.year:
        // Monthly breakdown (12 months)
        const months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec'
        ];
        for (var month in months) {
          chartData[month] = 0;
        }
        for (var session in history) {
          final timestamp = session['timestamp'] as Timestamp?;
          if (timestamp == null) continue;
          final sessionDate = timestamp.toDate();
          if (sessionDate.year == now.year) {
            final monthName = months[sessionDate.month - 1];
            final duration = _getSessionDuration(session);
            chartData[monthName] = (chartData[monthName] ?? 0) + duration;
          }
        }
        break;

      case ProgressPeriod.analytics:
        // Same as week for overview
        for (int i = 6; i >= 0; i--) {
          final date = now.subtract(Duration(days: i));
          final dayName = getDayName(date.weekday);
          chartData[dayName] = 0;
        }
        for (var session in history) {
          final timestamp = session['timestamp'] as Timestamp?;
          if (timestamp == null) continue;
          final sessionDate = timestamp.toDate();
          if (sessionDate.isAfter(now.subtract(const Duration(days: 7)))) {
            final dayName = getDayName(sessionDate.weekday);
            final duration = _getSessionDuration(session);
            chartData[dayName] = (chartData[dayName] ?? 0) + duration;
          }
        }
        break;
    }

    return chartData;
  }

// Helper to get session duration
  static int _getSessionDuration(Map<String, dynamic> session) {
    final status = session['status'] as String?;
    if (status == 'completed') {
      return session['duration'] as int? ?? 0;
    } else if (status == 'playing' || status == 'paused') {
      return session['accumulatedDuration'] as int? ?? 0;
    }
    return 0;
  }

// Calculate top sessions for a specific period
  static List<Map<String, dynamic>> calculateTopSessionsForPeriod(
    List<Map<String, dynamic>> history,
    ProgressPeriod period,
  ) {
    final now = DateTime.now();
    final sessionStats = <String, Map<String, dynamic>>{};

    for (var session in history) {
      final timestamp = session['timestamp'] as Timestamp?;
      if (timestamp == null) continue;

      final sessionDate = timestamp.toDate();
      final sessionId = session['sessionId'] as String? ?? '';
      if (sessionId.isEmpty) continue;

      // Check if session is in period
      bool includeSession = false;
      switch (period) {
        case ProgressPeriod.day:
          includeSession = sessionDate.day == now.day &&
              sessionDate.month == now.month &&
              sessionDate.year == now.year;
          break;
        case ProgressPeriod.week:
          includeSession =
              sessionDate.isAfter(now.subtract(const Duration(days: 7)));
          break;
        case ProgressPeriod.month:
          includeSession =
              sessionDate.month == now.month && sessionDate.year == now.year;
          break;
        case ProgressPeriod.year:
          includeSession = sessionDate.year == now.year;
          break;
        case ProgressPeriod.analytics:
          includeSession = true;
          break;
      }

      if (!includeSession) continue;

      final duration = _getSessionDuration(session);
      final title = session['sessionTitle'] as String? ?? 'Unknown Session';

      if (sessionStats.containsKey(sessionId)) {
        sessionStats[sessionId]!['totalMinutes'] =
            (sessionStats[sessionId]!['totalMinutes'] as int) + duration;
        sessionStats[sessionId]!['count'] =
            (sessionStats[sessionId]!['count'] as int) + 1;
      } else {
        sessionStats[sessionId] = {
          'sessionId': sessionId,
          'title': title,
          'totalMinutes': duration,
          'count': 1,
        };
      }
    }

    final sorted = sessionStats.values.toList()
      ..sort((a, b) =>
          (b['totalMinutes'] as int).compareTo(a['totalMinutes'] as int));

    return sorted.take(3).toList();
  }

  /// Recalculate analytics for a different period using cached history
  /// This enables instant tab switching without Firebase calls
  static Map<String, dynamic> recalculateForPeriod(
    Map<String, dynamic> cachedData,
    ProgressPeriod period,
  ) {
    // Get the cached history from the base data
    final history =
        cachedData['_rawHistory'] as List<Map<String, dynamic>>? ?? [];

    // Recalculate period-specific values
    final periodMinutes = getPeriodMinutes(history, period);
    final periodGoal = getGoalForPeriod(period);
    final chartData = getChartDataForPeriod(history, period);
    final periodTopSessions = calculateTopSessionsForPeriod(history, period);
    final allTimeTopSessions = calculateTopSessions(history);

    // Return updated data with new period calculations
    return {
      ...cachedData,
      'periodMinutes': periodMinutes,
      'periodGoal': periodGoal,
      'chartData': chartData,
      'topSessions': period == ProgressPeriod.analytics
          ? allTimeTopSessions
          : periodTopSessions,
      'period': period,
    };
  }
}
