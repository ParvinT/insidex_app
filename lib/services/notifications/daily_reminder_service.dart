// lib/services/notifications/daily_reminder_service.dart

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../features/notifications/notification_models.dart';
import 'notification_service.dart';

class DailyReminderService {
  static final DailyReminderService _instance = DailyReminderService._internal();
  factory DailyReminderService() => _instance;
  DailyReminderService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  /// Schedule a daily reminder
  Future<void> scheduleDailyReminder(DailyReminder reminder) async {
    if (!reminder.enabled) {
      await cancelDailyReminder();
      return;
    }

    try {
      // Cancel existing reminder first
      await cancelDailyReminder();

      // Calculate next scheduled time
      final scheduledDate = _calculateNextScheduledTime(reminder.scheduledTime);

      // Android notification details
      const androidDetails = AndroidNotificationDetails(
        NotificationConstants.dailyReminderChannelId,
        NotificationConstants.dailyReminderChannelName,
        channelDescription: NotificationConstants.dailyReminderChannelDesc,
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );

      // iOS notification details
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Schedule the notification
      await _notifications.zonedSchedule(
        reminder.notificationId,
        reminder.title,
        reminder.message,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // Daily repeat
      );

      debugPrint('Daily reminder scheduled for: ${scheduledDate.toString()}');
      debugPrint('Will repeat daily at: ${reminder.formattedTime12Hour}');
    } catch (e) {
      debugPrint('Error scheduling daily reminder: $e');
      rethrow;
    }
  }

  /// Calculate the next scheduled time for the reminder
  tz.TZDateTime _calculateNextScheduledTime(DateTime scheduledTime) {
    final now = tz.TZDateTime.now(tz.local);
    
    // Create scheduled time for today
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      scheduledTime.hour,
      scheduledTime.minute,
    );

    // If the scheduled time has already passed today, schedule for tomorrow
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
      debugPrint('Scheduled time has passed today, scheduling for tomorrow');
    } else {
      debugPrint('Scheduling for today');
    }

    return scheduled;
  }

  /// Cancel daily reminder
  Future<void> cancelDailyReminder() async {
    try {
      await _notifications.cancel(NotificationConstants.dailyReminderId);
      debugPrint('Daily reminder cancelled');
    } catch (e) {
      debugPrint('Error cancelling daily reminder: $e');
    }
  }

  /// Reschedule daily reminder (useful after time change)
  Future<void> rescheduleDailyReminder(DailyReminder reminder) async {
    if (!reminder.enabled) {
      await cancelDailyReminder();
      return;
    }

    // Simply call schedule again, it will cancel and reschedule
    await scheduleDailyReminder(reminder);
  }

  /// Check if daily reminder is scheduled
  Future<bool> isDailyReminderScheduled() async {
    final pendingNotifications = await _notifications.pendingNotificationRequests();
    return pendingNotifications.any(
      (notification) => notification.id == NotificationConstants.dailyReminderId,
    );
  }

  /// Get scheduled time of daily reminder (for debugging)
  Future<String?> getScheduledReminderInfo() async {
    final pendingNotifications = await _notifications.pendingNotificationRequests();
    final dailyReminder = pendingNotifications.firstWhere(
      (notification) => notification.id == NotificationConstants.dailyReminderId,
      orElse: () => PendingNotificationRequest(
        0, null, null, null,
      ),
    );

    if (dailyReminder.id == 0) {
      return null;
    }

    return 'Daily reminder scheduled: ${dailyReminder.title}';
  }

  /// Update reminder time only (keeps enabled state)
  Future<void> updateReminderTime(DateTime newTime, DailyReminder currentReminder) async {
    if (!currentReminder.enabled) return;

    final updatedReminder = currentReminder.copyWith(scheduledTime: newTime);
    await scheduleDailyReminder(updatedReminder);
  }

  /// Test notification (for debugging)
  Future<void> sendTestNotification() async {
    await NotificationService().showNotification(
      id: 9998,
      title: 'Test Reminder 🔔',
      body: 'This is how your daily reminder will look!',
      channelId: NotificationConstants.dailyReminderChannelId,
    );
  }
}