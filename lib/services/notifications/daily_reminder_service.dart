// lib/services/notifications/daily_reminder_service.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../features/notifications/notification_models.dart';
import 'notification_service.dart';
import 'notification_reliability_service.dart';
import 'notification_localization_helper.dart';

class DailyReminderService {
  static final DailyReminderService _instance =
      DailyReminderService._internal();
  factory DailyReminderService() => _instance;
  DailyReminderService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  /// Schedule a daily reminder
  Future<void> scheduleDailyReminder(DailyReminder reminder) async {
    if (!reminder.enabled) {
      await cancelDailyReminder();
      await NotificationReliabilityService.saveSettings(reminder);
      return;
    }

    try {
      final hasPermission =
          await NotificationService().checkAndRequestExactAlarmPermission();
      if (!hasPermission) {
        debugPrint('❌ Exact alarm permission denied - cannot schedule');
        return;
      }

      final localizedTexts =
          await NotificationLocalizationHelper.getDailyReminderTexts();
      final localizedTitle = localizedTexts['title']!;
      final localizedMessage = localizedTexts['message']!;
      // Cancel existing reminder first
      await cancelDailyReminder();

      // Calculate next scheduled time
      final scheduledDate = _calculateNextScheduledTime(reminder.scheduledTime);

      final now = tz.TZDateTime.now(tz.local);
      debugPrint('');
      debugPrint('🔔 ===== SCHEDULING DAILY REMINDER =====');
      debugPrint('📍 Device Timezone: ${tz.local.name}');
      debugPrint('🕐 Current Local Time: ${now.toString()}');
      debugPrint('⏰ User Selected Time: ${reminder.formattedTime12Hour}');
      debugPrint('📅 Next Notification: ${scheduledDate.toString()}');
      debugPrint(
          '⏱️ Time Until Notification: ${scheduledDate.difference(now).inMinutes} minutes');
      debugPrint(
          '🔁 Repeat: Daily at ${reminder.scheduledTime.hour}:${reminder.scheduledTime.minute.toString().padLeft(2, '0')}');
      debugPrint('========================================');
      debugPrint('');

      // Android notification details
      const androidDetails = AndroidNotificationDetails(
        NotificationConstants.dailyReminderChannelId,
        NotificationConstants.dailyReminderChannelName,
        channelDescription: NotificationConstants.dailyReminderChannelDesc,
        importance: Importance.high,
        priority: Priority.high,
        icon: 'ic_notification',
        largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        showWhen: true,
        enableVibration: true,
        playSound: true,
        autoCancel: true,
        ongoing: false,
        enableLights: true,
        category: AndroidNotificationCategory.reminder,
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
      if (Platform.isAndroid) {
        await _notifications.zonedSchedule(
          NotificationConstants.dailyReminderId,
          localizedTitle,
          localizedMessage,
          scheduledDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } else {
        // iOS için normal schedule
        await _notifications.zonedSchedule(
          NotificationConstants.dailyReminderId,
          localizedTitle,
          localizedMessage,
          scheduledDate,
          notificationDetails,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      }

      // WorkManager için local storage'a kaydet
      await NotificationReliabilityService.saveSettings(reminder);

      debugPrint('Will repeat daily at: ${reminder.formattedTime12Hour}');
    } catch (e) {
      debugPrint('Error scheduling daily reminder: $e');
      await _tryAlternativeScheduling(reminder);
    }
  }

  Future<void> _tryAlternativeScheduling(DailyReminder reminder) async {
    try {
      debugPrint('🔄 Trying alternative scheduling method...');

      // periodicallyShow kullanarak günlük tekrar
      await _notifications.periodicallyShow(
        reminder.notificationId,
        reminder.title,
        reminder.message,
        RepeatInterval.daily,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_reminder_backup',
            'Daily Reminder Backup',
            channelDescription: 'Backup channel for daily reminders',
            importance: Importance.max,
            priority: Priority.max,
            playSound: true,
            enableVibration: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );

      debugPrint('✅ Alternative scheduling successful');
    } catch (e) {
      debugPrint('❌ Alternative scheduling also failed: $e');
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
    final pendingNotifications =
        await _notifications.pendingNotificationRequests();
    return pendingNotifications.any(
      (notification) =>
          notification.id == NotificationConstants.dailyReminderId,
    );
  }

  /// Get scheduled time of daily reminder (for debugging)
  Future<String?> getScheduledReminderInfo() async {
    final pendingNotifications =
        await _notifications.pendingNotificationRequests();
    final dailyReminder = pendingNotifications.firstWhere(
      (notification) =>
          notification.id == NotificationConstants.dailyReminderId,
      orElse: () => const PendingNotificationRequest(
        0,
        null,
        null,
        null,
      ),
    );

    if (dailyReminder.id == 0) {
      return null;
    }

    return 'Daily reminder scheduled: ${dailyReminder.title}';
  }

  /// Update reminder time only (keeps enabled state)
  Future<void> updateReminderTime(
      DateTime newTime, DailyReminder currentReminder) async {
    if (!currentReminder.enabled) return;

    final updatedReminder = currentReminder.copyWith(scheduledTime: newTime);
    await scheduleDailyReminder(updatedReminder);
  }

  /// Test notification (for debugging)
  /// Test notification (for debugging)
  Future<void> sendTestNotification() async {
    debugPrint('🧪 ===== TEST NOTIFICATION START =====');

    // 1. Permission check
    final hasPermission = await NotificationService().hasPermission();
    debugPrint('🔐 Has Permission: $hasPermission');

    if (!hasPermission) {
      debugPrint('❌ No permission! Requesting...');
      final granted = await NotificationService().requestPermission();
      debugPrint('📝 Permission request result: $granted');
      if (!granted) {
        debugPrint('❌ Permission denied, cannot show notification');
        return;
      }
    }

    // 2. Show notification
    debugPrint('📤 Sending test notification...');
    try {
      await NotificationService().showNotification(
        id: 9998,
        title: 'Test Reminder 🔔',
        body: 'This is how your daily reminder will look!',
        channelId: NotificationConstants.dailyReminderChannelId,
      );
      debugPrint('✅ Test notification sent successfully!');
    } catch (e) {
      debugPrint('❌ Error sending notification: $e');
    }

    // 3. Check pending
    final pending = await NotificationService().getPendingNotifications();
    debugPrint('📋 Pending notifications: ${pending.length}');

    debugPrint('🧪 ===== TEST NOTIFICATION END =====');
  }
}
