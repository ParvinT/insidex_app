// lib/services/notification_service.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Instances
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  // Notification IDs
  static const int dailyReminderId = 100;
  static const int sessionCompleteId = 200;
  static const int achievementId = 300;

  // Initialization status
  bool _isInitialized = false;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize timezone for scheduled notifications
      tz.initializeTimeZones();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Initialize FCM
      await _initializeFCM();

      _isInitialized = true;
      print('NotificationService initialized successfully');
    } catch (e) {
      print('Error initializing NotificationService: $e');
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    // Android settings
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings
    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // We'll request manually
      requestBadgePermission: false,
      requestSoundPermission: false,
      onDidReceiveLocalNotification: (id, title, body, payload) async {
        // Handle iOS foreground notification
      },
    );

    // Initialize
    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels for Android
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await _createNotificationChannels();
    }
  }

  /// Create Android notification channels
  Future<void> _createNotificationChannels() async {
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return;

    // Daily reminder channel
    const dailyChannel = AndroidNotificationChannel(
      'daily_reminder',
      'Daily Reminders',
      description: 'Daily session reminders',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    // Session channel
    const sessionChannel = AndroidNotificationChannel(
      'session_notifications',
      'Session Notifications',
      description: 'Session related notifications',
      importance: Importance.high,
    );

    // Achievement channel
    const achievementChannel = AndroidNotificationChannel(
      'achievements',
      'Achievements',
      description: 'Achievement notifications',
      importance: Importance.high,
      playSound: true,
    );

    await androidPlugin.createNotificationChannel(dailyChannel);
    await androidPlugin.createNotificationChannel(sessionChannel);
    await androidPlugin.createNotificationChannel(achievementChannel);
  }

  /// Initialize Firebase Cloud Messaging
  Future<void> _initializeFCM() async {
    // Get FCM token
    final token = await _fcm.getToken();
    if (token != null) {
      await _saveTokenToFirestore(token);
      print('FCM Token: $token');
    }

    // Listen for token refresh
    _fcm.onTokenRefresh.listen(_saveTokenToFirestore);

    // Configure message handlers
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  /// Save FCM token to Firestore
  Future<void> _saveTokenToFirestore(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        // If update fails, user document might not exist yet
        print('Error saving FCM token: $e');
      }
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    // TODO: Navigate based on payload
  }

  /// Handle foreground FCM message
  void _handleForegroundMessage(RemoteMessage message) {
    print('Foreground message: ${message.notification?.title}');

    // Show local notification
    if (message.notification != null) {
      showNotification(
        title: message.notification!.title ?? 'INSIDEX',
        body: message.notification!.body ?? '',
        payload: message.data.toString(),
      );
    }
  }

  /// Handle message when app is opened from notification
  void _handleMessageOpenedApp(RemoteMessage message) {
    print('Message opened app: ${message.notification?.title}');
    // TODO: Navigate based on message
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    if (kIsWeb) {
      print('Notifications not supported on web');
      return false;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      // iOS permissions
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      // Android permissions (Android 13+)
      final status = await Permission.notification.request();
      return status.isGranted;
    }

    return false;
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    if (kIsWeb) {
      return false;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final settings = await _fcm.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return await Permission.notification.isGranted;
    }

    return false;
  }

  /// Show a simple notification
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'default',
      'Default',
      channelDescription: 'Default notification channel',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Schedule daily reminder
  Future<void> scheduleDailyReminder({
    required TimeOfDay time,
    required String title,
    required String body,
  }) async {
    // Cancel existing daily reminder
    await _localNotifications.cancel(dailyReminderId);

    // Calculate next occurrence
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'daily_reminder',
      'Daily Reminders',
      channelDescription: 'Daily session reminders',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.zonedSchedule(
      dailyReminderId,
      title,
      body,
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
    );

    print('Daily reminder scheduled for ${time.hour}:${time.minute}');
  }

  /// Cancel daily reminder
  Future<void> cancelDailyReminder() async {
    await _localNotifications.cancel(dailyReminderId);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// Show session complete notification
  Future<void> showSessionCompleteNotification({
    required String sessionTitle,
    required int durationMinutes,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'session_notifications',
      'Session Notifications',
      channelDescription: 'Session related notifications',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      sessionCompleteId,
      'Session Complete! 🎉',
      'Great job! You completed "$sessionTitle" (${durationMinutes} min)',
      details,
      payload: 'session_complete',
    );
  }

  /// Show achievement notification
  Future<void> showAchievementNotification({
    required String achievement,
    required String description,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'achievements',
      'Achievements',
      channelDescription: 'Achievement notifications',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      achievementId,
      achievement,
      description,
      details,
      payload: 'achievement',
    );
  }

  /// Show streak notification
  Future<void> showStreakNotification({
    required int streakDays,
  }) async {
    String title = '🔥 $streakDays Day Streak!';
    String body = 'Keep it up! You\'re doing amazing!';

    if (streakDays == 7) {
      title = '🏆 One Week Streak!';
      body = 'Incredible! You\'ve maintained a 7-day streak!';
    } else if (streakDays == 30) {
      title = '🌟 30 Day Streak!';
      body = 'WOW! A whole month of consistency!';
    }

    await showAchievementNotification(
      achievement: title,
      description: body,
    );
  }

  /// Get notification settings for display
  Future<Map<String, dynamic>> getNotificationSettings() async {
    final enabled = await areNotificationsEnabled();

    // Get from user preferences (Firestore)
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        final data = doc.data();
        return {
          'enabled': enabled,
          'dailyReminder':
              data?['notificationSettings']?['dailyReminder'] ?? true,
          'reminderTime':
              data?['notificationSettings']?['reminderTime'] ?? '20:00',
          'sessionNotifications':
              data?['notificationSettings']?['sessionNotifications'] ?? true,
          'achievementNotifications': data?['notificationSettings']
                  ?['achievementNotifications'] ??
              true,
        };
      } catch (e) {
        print('Error getting notification settings: $e');
      }
    }

    return {
      'enabled': enabled,
      'dailyReminder': true,
      'reminderTime': '20:00',
      'sessionNotifications': true,
      'achievementNotifications': true,
    };
  }

  /// Save notification settings
  Future<void> saveNotificationSettings(Map<String, dynamic> settings) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'notificationSettings': settings,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        print('Error saving notification settings: $e');
      }
    }
  }
}

// Top-level function for background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase if needed
  // await Firebase.initializeApp();

  print('Background message: ${message.notification?.title}');

  // You can show a local notification here if needed
  // But usually FCM handles showing the notification automatically
}
