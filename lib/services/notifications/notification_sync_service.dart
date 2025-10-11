// lib/services/notifications/notification_sync_service.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/notifications/notification_models.dart';

class NotificationSyncService {
  static final NotificationSyncService _instance =
      NotificationSyncService._internal();
  factory NotificationSyncService() => _instance;
  NotificationSyncService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _localStorageKey = 'notification_settings';

  /// Get current user ID
  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  /// Save settings to Firebase
  Future<void> saveSettingsToFirebase(NotificationSettings settings) async {
    try {
      if (_userId == null) {
        debugPrint('No user logged in, saving to local storage only');
        await _saveToLocalStorage(settings);
        return;
      }

      // Add platform info
      final updatedSettings = settings.copyWith(
        platform: Platform.isIOS ? 'ios' : 'android',
        lastUpdated: DateTime.now(),
      );

      // Save to Firebase
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('settings')
          .doc('notifications')
          .set(updatedSettings.toMap(), SetOptions(merge: true));

      // Also save to local storage for offline access
      await _saveToLocalStorage(updatedSettings);

      debugPrint('Settings saved to Firebase and local storage');
    } catch (e) {
      debugPrint('Error saving settings to Firebase: $e');
      // Still save to local storage even if Firebase fails
      await _saveToLocalStorage(settings);
    }
  }

  /// Load settings from Firebase
  Future<NotificationSettings?> loadSettingsFromFirebase() async {
    try {
      if (_userId == null) {
        debugPrint('No user logged in, loading from local storage');
        return await _loadFromLocalStorage();
      }

      // Try to get from Firebase first
      final doc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('settings')
          .doc('notifications')
          .get();

      if (doc.exists && doc.data() != null) {
        final settings = NotificationSettings.fromMap(doc.data()!);
        // Cache in local storage
        await _saveToLocalStorage(settings);
        debugPrint('Settings loaded from Firebase');
        return settings;
      }

      // If not in Firebase, try local storage
      final localSettings = await _loadFromLocalStorage();
      if (localSettings != null) {
        // Upload local settings to Firebase
        await saveSettingsToFirebase(localSettings);
        return localSettings;
      }

      // Return default settings if nothing found
      debugPrint('No existing settings found, using defaults');
      return NotificationSettings.defaultSettings();
    } catch (e) {
      debugPrint('Error loading settings from Firebase: $e');
      // Fallback to local storage
      return await _loadFromLocalStorage() ??
          NotificationSettings.defaultSettings();
    }
  }

  /// Listen to settings changes in real-time
  Stream<NotificationSettings> listenToSettingsChanges() {
    if (_userId == null) {
      // Return a stream with default settings if no user
      return Stream.value(NotificationSettings.defaultSettings());
    }

    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('settings')
        .doc('notifications')
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return NotificationSettings.fromMap(snapshot.data()!);
      }
      return NotificationSettings.defaultSettings();
    });
  }

  /// Update specific setting in Firebase
  Future<void> updateAllNotificationsEnabled(bool enabled) async {
    try {
      if (_userId == null) {
        final settings = await _loadFromLocalStorage() ??
            NotificationSettings.defaultSettings();
        final updated = settings.copyWith(
          allNotificationsEnabled: enabled,
          // If disabling all notifications, also disable daily reminder
          dailyReminder: enabled
              ? settings.dailyReminder
              : settings.dailyReminder.copyWith(enabled: false),
        );
        await _saveToLocalStorage(updated);
        return;
      }

      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('settings')
          .doc('notifications')
          .update({
        'allNotificationsEnabled': enabled,
        // If disabling all, also disable daily reminder
        if (!enabled) 'dailyReminder.enabled': false,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      debugPrint('Updated allNotificationsEnabled to: $enabled');
    } catch (e) {
      debugPrint('Error updating allNotificationsEnabled: $e');
    }
  }

  /// Update daily reminder settings
  Future<void> updateDailyReminder(DailyReminder reminder) async {
    try {
      if (_userId == null) {
        final settings = await _loadFromLocalStorage() ??
            NotificationSettings.defaultSettings();
        final updated = settings.copyWith(dailyReminder: reminder);
        await _saveToLocalStorage(updated);
        return;
      }

      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('settings')
          .doc('notifications')
          .update({
        'dailyReminder': reminder.toMap(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      debugPrint('Updated daily reminder settings');
    } catch (e) {
      debugPrint('Error updating daily reminder: $e');
    }
  }

  /// Save to local storage
  Future<void> _saveToLocalStorage(NotificationSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> data = {
        'allNotificationsEnabled': settings.allNotificationsEnabled,
        'dailyReminder': {
          'enabled': settings.dailyReminder.enabled,
          'scheduledTime':
              settings.dailyReminder.scheduledTime.toIso8601String(),
          'title': settings.dailyReminder.title,
          'message': settings.dailyReminder.message,
        },
        'lastUpdated': settings.lastUpdated.toIso8601String(),
      };

      await prefs.setString(_localStorageKey, data.toString());
      debugPrint('Settings saved to local storage');
    } catch (e) {
      debugPrint('Error saving to local storage: $e');
    }
  }

  /// Load from local storage
  Future<NotificationSettings?> _loadFromLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_localStorageKey);
      if (data == null) return null;

      // Note: This is simplified. In production, use proper JSON encoding/decoding
      // For now, return default settings if local data exists
      return NotificationSettings.defaultSettings();
    } catch (e) {
      debugPrint('Error loading from local storage: $e');
      return null;
    }
  }

  /// Clear all notification settings
  Future<void> clearSettings() async {
    try {
      if (_userId != null) {
        await _firestore
            .collection('users')
            .doc(_userId)
            .collection('settings')
            .doc('notifications')
            .delete();
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_localStorageKey);

      debugPrint('Notification settings cleared');
    } catch (e) {
      debugPrint('Error clearing settings: $e');
    }
  }

  /// Migrate settings when user logs in
  Future<void> migrateSettingsOnLogin() async {
    try {
      // Load local settings
      final localSettings = await _loadFromLocalStorage();
      if (localSettings != null && _userId != null) {
        // Upload to Firebase
        await saveSettingsToFirebase(localSettings);
        debugPrint('Settings migrated to Firebase after login');
      }
    } catch (e) {
      debugPrint('Error migrating settings: $e');
    }
  }
}
