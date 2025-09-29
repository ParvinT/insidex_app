// lib/features/notifications/notification_models.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// Notification settings model that syncs with Firebase
class NotificationSettings {
  final bool allNotificationsEnabled;
  final DailyReminder dailyReminder;
  final DateTime lastUpdated;
  final String? deviceToken;
  final String? platform; // 'ios' or 'android'

  NotificationSettings({
    required this.allNotificationsEnabled,
    required this.dailyReminder,
    required this.lastUpdated,
    this.deviceToken,
    this.platform,
  });

  factory NotificationSettings.defaultSettings() {
    return NotificationSettings(
      allNotificationsEnabled: false,
      dailyReminder: DailyReminder.defaultReminder(),
      lastUpdated: DateTime.now(),
    );
  }

  factory NotificationSettings.fromMap(Map<String, dynamic> map) {
    return NotificationSettings(
      allNotificationsEnabled: map['allNotificationsEnabled'] ?? false,
      dailyReminder: DailyReminder.fromMap(
        map['dailyReminder'] ?? {},
      ),
      lastUpdated:
          (map['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
      deviceToken: map['deviceToken'],
      platform: map['platform'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'allNotificationsEnabled': allNotificationsEnabled,
      'dailyReminder': dailyReminder.toMap(),
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'deviceToken': deviceToken,
      'platform': platform,
    };
  }

  NotificationSettings copyWith({
    bool? allNotificationsEnabled,
    DailyReminder? dailyReminder,
    DateTime? lastUpdated,
    String? deviceToken,
    String? platform,
  }) {
    return NotificationSettings(
      allNotificationsEnabled:
          allNotificationsEnabled ?? this.allNotificationsEnabled,
      dailyReminder: dailyReminder ?? this.dailyReminder,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      deviceToken: deviceToken ?? this.deviceToken,
      platform: platform ?? this.platform,
    );
  }
}

/// Daily reminder model
class DailyReminder {
  final bool enabled;
  final DateTime scheduledTime; // Only time part is used
  final String title;
  final String message;
  final int notificationId;

  DailyReminder({
    required this.enabled,
    required this.scheduledTime,
    required this.title,
    required this.message,
    this.notificationId = 1001, // Fixed ID for daily reminder
  });

  factory DailyReminder.defaultReminder() {
    // Default to 9:00 PM
    final now = DateTime.now();
    return DailyReminder(
      enabled: false,
      scheduledTime: DateTime(now.year, now.month, now.day, 21, 0),
      title: 'Time for Your Daily Session 🎧',
      message: 'Take a moment to relax and heal with INSIDEX',
    );
  }

  factory DailyReminder.fromMap(Map<String, dynamic> map) {
    return DailyReminder(
      enabled: map['enabled'] ?? false,
      scheduledTime: (map['scheduledTime'] as Timestamp?)?.toDate() ??
          DailyReminder.defaultReminder().scheduledTime,
      title: map['title'] ?? DailyReminder.defaultReminder().title,
      message: map['message'] ?? DailyReminder.defaultReminder().message,
      notificationId: map['notificationId'] ?? 1001,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'scheduledTime': Timestamp.fromDate(scheduledTime),
      'title': title,
      'message': message,
      'notificationId': notificationId,
    };
  }

  DailyReminder copyWith({
    bool? enabled,
    DateTime? scheduledTime,
    String? title,
    String? message,
    int? notificationId,
  }) {
    return DailyReminder(
      enabled: enabled ?? this.enabled,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      title: title ?? this.title,
      message: message ?? this.message,
      notificationId: notificationId ?? this.notificationId,
    );
  }

  /// Get the hour and minute for display
  String get formattedTime {
    final hour = scheduledTime.hour.toString().padLeft(2, '0');
    final minute = scheduledTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Get 12-hour format with AM/PM
  String get formattedTime12Hour {
    final hour = scheduledTime.hour;
    final minute = scheduledTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}

/// Notification constants
class NotificationConstants {
  // Channel IDs
  static const String dailyReminderChannelId = 'insidex_daily_reminder';
  static const String generalChannelId = 'insidex_general';

  // Channel Names
  static const String dailyReminderChannelName = 'Daily Reminders';
  static const String generalChannelName = 'General Notifications';

  // Channel Descriptions
  static const String dailyReminderChannelDesc =
      'Daily session reminders from INSIDEX';
  static const String generalChannelDesc = 'General notifications from INSIDEX';

  // Notification IDs
  static const int dailyReminderId = 1001;
  static const int permissionRequestId = 9999;

  // Default Messages
  static const String defaultDailyTitle = 'Time for Your Daily Session 🎧';
  static const String defaultDailyMessage =
      'Take a moment to relax and heal with INSIDEX';

  // Permission Messages
  static const String permissionTitle = 'Enable Notifications';
  static const String permissionMessage =
      'Get daily reminders to maintain your wellness routine';
  static const String permissionDeniedMessage =
      'You can enable notifications later in Settings';

  // Settings Messages
  static const String notificationsDisabledInSystem =
      'Notifications are disabled in system settings';
  static const String enableInSystemSettings = 'Open Settings';
}
