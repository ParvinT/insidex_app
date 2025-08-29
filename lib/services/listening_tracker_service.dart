// lib/services/listening_tracker_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ListeningTrackerService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Track session state
  static DateTime? _sessionStartTime;
  static DateTime? _lastResumeTime;
  static String? _currentSessionId;
  static String? _currentDocId; // Firestore document ID

  /// Start tracking a listening session
  static Future<void> startSession({
    required String sessionId,
    required String sessionTitle,
    String? categoryId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      _sessionStartTime = DateTime.now();
      _lastResumeTime = _sessionStartTime;
      _currentSessionId = sessionId;

      // Create a new listening session document
      final docRef = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('listening_history')
          .add({
        'sessionId': sessionId,
        'sessionTitle': sessionTitle,
        'categoryId': categoryId,
        'startTime': FieldValue.serverTimestamp(),
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'playing',
        'date': DateTime.now().toIso8601String().split('T')[0],
        'accumulatedDuration': 0,
      });

      _currentDocId = docRef.id;
      print('Started tracking session: $sessionTitle');
    } catch (e) {
      print('Error starting session tracking: $e');
    }
  }

  /// Pause session tracking
  static Future<void> pauseSession() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final query = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('listening_history')
          .where('status', isEqualTo: 'playing')
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        final docData = doc.data();

        // Get current accumulated duration
        final accumulatedDuration = docData['accumulatedDuration'] ?? 0;

        // Calculate time since last resume
        final sessionDuration = _lastResumeTime != null
            ? DateTime.now().difference(_lastResumeTime!).inSeconds
            : 0;

        // Convert to minutes and update total
        final sessionMinutes = (sessionDuration / 60).round();
        final totalDuration = accumulatedDuration + sessionMinutes;

        await doc.reference.update({
          'pausedAt': FieldValue.serverTimestamp(),
          'accumulatedDuration': totalDuration,
          'status': 'paused',
        });

        print(
            'Session paused after $sessionMinutes minutes. Total: $totalDuration minutes');
      }
    } catch (e) {
      print('Error pausing session: $e');
    }
  }

  /// Resume session tracking
  static Future<void> resumeSession() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final query = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('listening_history')
          .where('status', isEqualTo: 'paused')
          .get();

      if (query.docs.isNotEmpty) {
        _lastResumeTime = DateTime.now();

        await query.docs.first.reference.update({
          'resumedAt': FieldValue.serverTimestamp(),
          'status': 'playing',
        });

        print('Session resumed');
      }
    } catch (e) {
      print('Error resuming session: $e');
    }
  }

  /// End tracking and save duration
  static Future<void> endSession() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Try to find playing session first
      var query = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('listening_history')
          .where('status', isEqualTo: 'playing')
          .get();

      // If no playing session, check for paused
      if (query.docs.isEmpty) {
        query = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('listening_history')
            .where('status', isEqualTo: 'paused')
            .get();
      }

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        final docData = doc.data();
        final status = docData['status'];

        // Get accumulated duration
        final accumulatedDuration = docData['accumulatedDuration'] ?? 0;

        // If currently playing, add time since last resume
        int finalDuration = accumulatedDuration;
        if (status == 'playing' && _lastResumeTime != null) {
          final sessionDuration =
              DateTime.now().difference(_lastResumeTime!).inSeconds;
          final sessionMinutes = (sessionDuration / 60).round();
          finalDuration = accumulatedDuration + sessionMinutes;
        }

        await doc.reference.update({
          'endTime': FieldValue.serverTimestamp(),
          'duration': finalDuration,
          'status': 'completed',
        });

        // Update user stats
        await updateUserStats(finalDuration);

        print('Session ended. Duration: $finalDuration minutes');
      }

      // Reset tracking variables
      _sessionStartTime = null;
      _currentSessionId = null;
      _lastResumeTime = null;
      _currentDocId = null;
    } catch (e) {
      print('Error ending session: $e');
    }
  }

  /// Update user statistics
  static Future<void> updateUserStats(int minutesListened) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final userDoc = _firestore.collection('users').doc(user.uid);

      // Get current stats
      final userData = await userDoc.get();
      final currentTotal = userData.data()?['totalListeningMinutes'] ?? 0;
      final completedSessions =
          List<String>.from(userData.data()?['completedSessionIds'] ?? []);

      // Add current session if not already in list
      if (_currentSessionId != null &&
          !completedSessions.contains(_currentSessionId)) {
        completedSessions.add(_currentSessionId!);
      }

      // Update stats
      await userDoc.update({
        'totalListeningMinutes': currentTotal + minutesListened,
        'completedSessionIds': completedSessions,
        'lastActiveAt': FieldValue.serverTimestamp(),
        'lastListeningDate': DateTime.now().toIso8601String().split('T')[0],
      });

      print('Updated user stats: +$minutesListened minutes');
    } catch (e) {
      print('Error updating user stats: $e');
    }
  }

  /// Get listening history for analytics
  static Future<List<Map<String, dynamic>>> getListeningHistory({
    int days = 30,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final startDate = DateTime.now().subtract(Duration(days: days));

      final query = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('listening_history')
          .where('timestamp', isGreaterThan: Timestamp.fromDate(startDate))
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting listening history: $e');
      return [];
    }
  }

  /// Calculate current streak
  static Future<int> calculateStreak() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 0;

      // Get completed sessions
      final query = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('listening_history')
          .where('status', isEqualTo: 'completed')
          .get();

      if (query.docs.isEmpty) return 0;

      // Collect unique dates
      final dates = <String>{};
      for (var doc in query.docs) {
        final date = doc.data()['date'] as String?;
        if (date != null) dates.add(date);
      }

      if (dates.isEmpty) return 0;

      // Sort dates in descending order
      final sortedDates = dates.toList()..sort((a, b) => b.compareTo(a));

      // Calculate streak
      int streak = 0;
      final today = DateTime.now();
      final todayStr = today.toIso8601String().split('T')[0];
      final yesterdayStr =
          today.subtract(Duration(days: 1)).toIso8601String().split('T')[0];

      // Check if user has listened today or yesterday
      bool hasRecentActivity =
          sortedDates.contains(todayStr) || sortedDates.contains(yesterdayStr);

      if (!hasRecentActivity) {
        return 0; // Streak is broken
      }

      // Count consecutive days
      for (int i = 0; i <= sortedDates.length; i++) {
        final checkDate = today.subtract(Duration(days: i));
        final checkDateStr = checkDate.toIso8601String().split('T')[0];

        if (sortedDates.contains(checkDateStr)) {
          streak = i + 1;
        } else if (i > 1) {
          // Allow one day gap only for yesterday
          break;
        }
      }

      return streak;
    } catch (e) {
      print('Error calculating streak: $e');
      return 0;
    }
  }

  /// Get weekly statistics
  static Future<Map<String, int>> getWeeklyStats() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      final weekAgo = DateTime.now().subtract(const Duration(days: 7));

      final query = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('listening_history')
          .where('status', isEqualTo: 'completed')
          .get();

      final weeklyData = <String, int>{};

      // Initialize all days with 0
      for (int i = 0; i < 7; i++) {
        final date = DateTime.now().subtract(Duration(days: i));
        final dayName = _getDayName(date.weekday);
        weeklyData[dayName] = 0;
      }

      // Add actual data
      for (var doc in query.docs) {
        final data = doc.data();
        final timestamp = (data['timestamp'] as Timestamp?)?.toDate();

        if (timestamp != null && timestamp.isAfter(weekAgo)) {
          final dayName = _getDayName(timestamp.weekday);
          final duration = data['duration'] as int? ?? 0;
          weeklyData[dayName] = (weeklyData[dayName] ?? 0) + duration;
        }
      }

      return weeklyData;
    } catch (e) {
      print('Error getting weekly stats: $e');
      return {};
    }
  }

  static String _getDayName(int weekday) {
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
