// lib/services/notifications/streak_notification_service.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';
import '../../features/notifications/notification_models.dart';

class StreakNotificationService {
  static final StreakNotificationService _instance =
      StreakNotificationService._internal();
  factory StreakNotificationService() => _instance;
  StreakNotificationService._internal();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Milestone tanımları
  static const List<int> _milestones = [3, 7, 14, 21, 30, 50, 100];

  // Son gösterilen milestone'u cache'le (spam önleme)
  static const String _lastMilestoneKey = 'last_streak_milestone_shown';

  /// Streak kontrolü ve bildirim gönderme
  static Future<void> checkAndNotifyStreak({
    required int currentStreak,
    required int previousStreak,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final settingsDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .doc('notifications')
          .get();

      if (settingsDoc.exists) {
        final settings = settingsDoc.data()!;
        final streakEnabled = settings['streakNotificationsEnabled'] ?? true;

        if (!streakEnabled) {
          debugPrint('Streak notifications disabled, skipping');
          return;
        }
      }
      // Milestone kontrolü
      for (int milestone in _milestones) {
        // Yeni milestone'a ulaştık mı?
        if (currentStreak >= milestone && previousStreak < milestone) {
          await _showMilestoneNotification(milestone);
          await _saveLastMilestone(milestone);
          break; // Tek seferde bir bildirim
        }
      }

      // Streak kaybı kontrolü
      if (previousStreak > 0 && currentStreak == 0) {
        await _showStreakLostNotification(previousStreak);
      }

      debugPrint('Streak checked: $previousStreak -> $currentStreak');
    } catch (e) {
      debugPrint('Error checking streak: $e');
    }
  }

  /// Milestone bildirimi göster
  static Future<void> _showMilestoneNotification(int milestone) async {
    String title = '🎉 Congratulations!';
    String body = '';

    switch (milestone) {
      case 3:
        body = '🔥 3 day streak! Great start!';
        break;
      case 7:
        title = '🎯 One Week Achievement!';
        body = '7 days in a row! You\'re doing amazing!';
        break;
      case 14:
        title = '💪 Two Weeks Strong!';
        body = '14 day streak! The habit is forming.';
        break;
      case 21:
        title = '🌟 21 Days - Habit Formed!';
        body = 'Science says you\'ve built a new habit!';
        break;
      case 30:
        title = '🏆 30 Day Legend!';
        body = 'One full month! Incredible dedication!';
        break;
      case 50:
        title = '💎 50 Day Diamond Streak!';
        body = 'Half a century! You\'re a true INSIDEX master!';
        break;
      case 100:
        title = '👑 100 Day Champion!';
        body = 'One hundred days! You\'re absolutely legendary! 🎊';
        break;
    }

    // Bildirimi göster
    await NotificationService().showNotification(
      id: 5000 + milestone, // Unique ID for each milestone
      title: title,
      body: body,
      channelId: NotificationConstants.generalChannelId,
    );
  }

  /// Streak kaybı bildirimi
  static Future<void> _showStreakLostNotification(int lostStreak) async {
    await NotificationService().showNotification(
      id: 5999,
      title: '😔 Streak Ended',
      body:
          'Your $lostStreak day streak has ended. But don\'t worry, you can start fresh today!',
      channelId: NotificationConstants.generalChannelId,
    );
  }

  /// Son gösterilen milestone'u kaydet
  static Future<void> _saveLastMilestone(int milestone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastMilestoneKey, milestone);
  }

  /// Firebase'de streak bilgilerini güncelle
  static Future<void> updateStreakInFirebase(int newStreak) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final userDoc = _firestore.collection('users').doc(user.uid);
      final userData = await userDoc.get();

      if (userData.exists) {
        final data = userData.data()!;
        final longestStreak = data['longestStreak'] ?? 0;

        Map<String, dynamic> updates = {
          'currentStreak': newStreak,
          'lastStreakUpdate': FieldValue.serverTimestamp(),
        };

        // En uzun streak güncellemesi
        if (newStreak > longestStreak) {
          updates['longestStreak'] = newStreak;
          updates['longestStreakDate'] = FieldValue.serverTimestamp();
        }

        await userDoc.update(updates);
        debugPrint('Streak updated in Firebase: $newStreak');
      }
    } catch (e) {
      debugPrint('Error updating streak in Firebase: $e');
    }
  }
}
