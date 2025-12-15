// lib/features/profile/services/progress_analytics_service.dart

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/listening_tracker_service.dart';

class ProgressAnalyticsService {
  // Default analytics data
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
    };
  }

  // Load all analytics data from Firebase
  static Future<Map<String, dynamic>> loadAnalyticsData() async {
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

      return {
        'totalMinutes': userDoc.data()?['totalListeningMinutes'] ?? 0,
        'totalSessions':
            (userDoc.data()?['completedSessionIds'] as List?)?.length ?? 0,
        'currentStreak': streak,
        'weeklyData': weeklyStats,
        'weeklyTotal': weeklyTotal,
        'monthlyProgress': monthlyProgress,
        'topSessions': topSessions,
        'todayMinutes': getTodayMinutes(history),
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
}