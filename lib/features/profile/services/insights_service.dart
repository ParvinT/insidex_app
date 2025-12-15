// lib/features/profile/services/insights_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class InsightsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Load user data from Firestore
  static Future<Map<String, dynamic>?> loadUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        return userDoc.data();
      }
      return null;
    } catch (e) {
      debugPrint('Error loading user data: $e');
      return null;
    }
  }

  /// Get weekly activity data
  static Future<Map<String, int>> getWeeklyActivity() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return _getEmptyWeeklyData();

      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));

      final history = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('listening_history')
          .where('timestamp', isGreaterThan: Timestamp.fromDate(weekStart))
          .get();

      if (history.docs.isEmpty) {
        return _getEmptyWeeklyData();
      }

      Map<String, int> weeklyData = {
        'Mon': 0,
        'Tue': 0,
        'Wed': 0,
        'Thu': 0,
        'Fri': 0,
        'Sat': 0,
        'Sun': 0
      };

      for (var doc in history.docs) {
        final data = doc.data();
        final timestamp = (data['timestamp'] as Timestamp).toDate();
        final duration = data['duration'] ?? 0;

        final dayName = _getDayNameFromWeekday(timestamp.weekday);
        weeklyData[dayName] = (weeklyData[dayName] ?? 0) + duration as int;
      }

      return weeklyData;
    } catch (e) {
      debugPrint('Error getting weekly activity: $e');
      return _getEmptyWeeklyData();
    }
  }

  /// Get longest session duration
  static Future<String> getLongestSession() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return '0 min';

      final history = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('listening_history')
          .orderBy('duration', descending: true)
          .limit(1)
          .get();

      if (history.docs.isEmpty) return '0 min';

      final longestDuration = history.docs.first.data()['duration'] ?? 0;
      return '$longestDuration min';
    } catch (e) {
      debugPrint('Error getting longest session: $e');
      return '0 min';
    }
  }

  /// Get favorite listening time slot
  static Future<String> getFavoriteTimeSlot() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'Evening';

      final history = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('listening_history')
          .get();

      if (history.docs.isEmpty) return 'Evening';

      Map<String, int> timeSlots = {
        'Morning': 0,
        'Afternoon': 0,
        'Evening': 0,
        'Night': 0,
      };

      for (var doc in history.docs) {
        final timestamp = (doc.data()['timestamp'] as Timestamp?)?.toDate();
        if (timestamp != null) {
          final hour = timestamp.hour;

          if (hour >= 6 && hour < 12) {
            timeSlots['Morning'] = timeSlots['Morning']! + 1;
          } else if (hour >= 12 && hour < 17) {
            timeSlots['Afternoon'] = timeSlots['Afternoon']! + 1;
          } else if (hour >= 17 && hour < 22) {
            timeSlots['Evening'] = timeSlots['Evening']! + 1;
          } else {
            timeSlots['Night'] = timeSlots['Night']! + 1;
          }
        }
      }

      String favoriteTime = 'Evening';
      int maxCount = 0;

      timeSlots.forEach((time, value) {
        if (value > maxCount) {
          maxCount = value;
          favoriteTime = time;
        }
      });

      return favoriteTime;
    } catch (e) {
      debugPrint('Error getting favorite time: $e');
      return 'Evening';
    }
  }

  // Helper methods
  static Map<String, int> _getEmptyWeeklyData() {
    return {
      'Mon': 0,
      'Tue': 0,
      'Wed': 0,
      'Thu': 0,
      'Fri': 0,
      'Sat': 0,
      'Sun': 0,
    };
  }

  static String _getDayNameFromWeekday(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }
}