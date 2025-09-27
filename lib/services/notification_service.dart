// lib/services/notification_service.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Instances
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  // Notification ID for daily reminder
  static const int dailyReminderId = 100;

  // Initialization status
  bool _isInitialized = false;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize timezone
      tz.initializeTimeZones();

      // Set local timezone (önemli!)
      final String timeZoneName = await _findLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Initialize FCM
      await _initializeFCM();

      _isInitialized = true;
      debugPrint('NotificationService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing NotificationService: $e');
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    // Android settings
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings
    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
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

    // Create Android notification channel
    if (!kIsWeb && Platform.isAndroid) {
      await _createNotificationChannel();
    }
  }

  /// Create Android notification channel
  Future<void> _createNotificationChannel() async {
    final androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return;

    const dailyChannel = AndroidNotificationChannel(
      'daily_reminder',
      'Daily Reminders',
      description: 'Daily session reminders from INSIDEX',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await androidPlugin.createNotificationChannel(dailyChannel);
  }

  /// Initialize Firebase Cloud Messaging
  Future<void> _initializeFCM() async {
    // Get FCM token
    final token = await _fcm.getToken();
    if (token != null) {
      await _saveTokenToFirestore(token);
      debugPrint('FCM Token saved');
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
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Error saving FCM token: $e');
      }
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // TODO: Navigate based on payload if needed
  }

  /// Handle foreground FCM message
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message: ${message.notification?.title}');

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
    debugPrint('Message opened app: ${message.notification?.title}');
    // TODO: Navigate based on message if needed
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    if (kIsWeb) {
      debugPrint('Notifications not supported on web');
      return false;
    }

    if (Platform.isIOS) {
      // iOS permissions
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } else if (Platform.isAndroid) {
      // Android permissions
      final status = await Permission.notification.request();

      // Android 12+ için exact alarm izni
      // scheduleExactAlarm izni Android 12+ için otomatik kontrol edilir
      try {
        final exactAlarmStatus = await Permission.scheduleExactAlarm.status;
        if (!exactAlarmStatus.isGranted) {
          debugPrint(
              'Exact alarm permission not granted, will use inexact alarms');
          // Kullanıcıya bilgi verilebilir ama zorunlu değil
        }
      } catch (e) {
        debugPrint('Exact alarm permission check skipped: $e');
      }

      return status.isGranted;
    }

    return false;
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    if (kIsWeb) return false;

    if (Platform.isIOS) {
      final settings = await _fcm.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } else if (Platform.isAndroid) {
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
      'daily_reminder',
      'Daily Reminders',
      channelDescription: 'Daily session reminders from INSIDEX',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
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

  /// Find local timezone
  Future<String> _findLocalTimezone() async {
    // Default to UTC if we can't find the timezone
    String timeZoneName = 'UTC';

    try {
      // Try to get the local timezone
      timeZoneName = DateTime.now().timeZoneName;

      // Common timezone mappings
      final tzMap = {
        'CST': 'America/Chicago',
        'EST': 'America/New_York',
        'PST': 'America/Los_Angeles',
        'GMT': 'Europe/London',
        'CET': 'Europe/Berlin',
        'EET': 'Europe/Istanbul',
        'JST': 'Asia/Tokyo',
        'IST': 'Asia/Kolkata',
      };

      if (tzMap.containsKey(timeZoneName)) {
        timeZoneName = tzMap[timeZoneName]!;
      } else if (timeZoneName.length <= 3) {
        // If it's a short timezone code, default to Istanbul for Turkey
        timeZoneName = 'Europe/Istanbul';
      }
    } catch (e) {
      debugPrint('Error finding timezone: $e');
      timeZoneName = 'Europe/Istanbul'; // Default for Turkey
    }

    debugPrint('Using timezone: $timeZoneName');
    return timeZoneName;
  }

  /// Schedule daily reminder
  Future<void> scheduleDailyReminder({
    required TimeOfDay time,
    required String title,
    required String body,
  }) async {
    // Check if notifications are enabled at all
    final settings = await getNotificationSettings();
    if (settings['enabled'] != true || settings['dailyReminder'] != true) {
      debugPrint(
          'Cannot schedule daily reminder: notifications or daily reminder disabled');
      return;
    }

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

    // If the time has passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
      debugPrint('Time has passed today, scheduling for tomorrow');
    }

    const androidDetails = AndroidNotificationDetails(
      'daily_reminder',
      'Daily Reminders',
      channelDescription: 'Daily session reminders from INSIDEX',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      // Try exact alarm first
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

      debugPrint('=== Daily Reminder Scheduled (EXACT) ===');
    } catch (e) {
      if (e.toString().contains('exact_alarms_not_permitted')) {
        // Fallback to inexact alarm
        debugPrint('Exact alarm failed, trying inexact alarm...');

        await _localNotifications.zonedSchedule(
          dailyReminderId,
          title,
          body,
          scheduledDate,
          details,
          androidScheduleMode:
              AndroidScheduleMode.inexactAllowWhileIdle, // INEXACT
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
        );

        debugPrint('=== Daily Reminder Scheduled (INEXACT) ===');
        debugPrint(
            'Note: Notification may arrive within 15 minutes of scheduled time');
      } else {
        // Re-throw other errors
        throw e;
      }
    }

    debugPrint('Current time: ${now.hour}:${now.minute}');
    debugPrint(
        'Scheduled for: ${scheduledDate.hour}:${scheduledDate.minute} on ${scheduledDate.day}/${scheduledDate.month}');
    debugPrint('Will repeat daily at ${time.hour}:${time.minute}');
    debugPrint('================================');
  }

  /// Cancel daily reminder
  Future<void> cancelDailyReminder() async {
    await _localNotifications.cancel(dailyReminderId);
    debugPrint('Daily reminder cancelled');
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
    debugPrint('All notifications cancelled');
  }

  /// Get notification settings from Firestore
  Future<Map<String, dynamic>> getNotificationSettings() async {
    // System permission check
    final systemEnabled = await areNotificationsEnabled();

    // Default settings
    Map<String, dynamic> settings = {
      'enabled': false,
      'dailyReminder': false,
      'reminderTime': '20:00',
    };

    // Get from Firestore if user is logged in
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          if (data['notificationSettings'] != null) {
            final savedSettings = data['notificationSettings'];

            // User preference for notifications
            final userWantsNotifications = savedSettings['enabled'] ?? false;

            settings = {
              // Only enabled if BOTH system allows AND user wants
              'enabled': systemEnabled && userWantsNotifications,
              'dailyReminder': savedSettings['dailyReminder'] ?? false,
              'reminderTime': savedSettings['reminderTime'] ?? '20:00',
              'systemEnabled': systemEnabled, // Add this for debugging
            };

            debugPrint('Loaded settings from Firebase: $settings');
          }
        }
      } catch (e) {
        debugPrint('Error getting notification settings: $e');
      }
    }

    return settings;
  }

  /// Save notification settings to Firestore
  Future<void> saveNotificationSettings(Map<String, dynamic> settings) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'notificationSettings': {
            'enabled': settings['enabled'] ?? false,
            'dailyReminder': settings['dailyReminder'] ?? false,
            'reminderTime': settings['reminderTime'] ?? '20:00',
          },
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        debugPrint('Notification settings saved: ${settings}');
      } catch (e) {
        debugPrint('Error saving notification settings: $e');
      }
    }
  }

  /// Test notification
  Future<void> showTestNotification() async {
    await showNotification(
      title: 'Test Notification 🔔',
      body: 'This is a test notification from INSIDEX',
    );
  }
}

// Top-level function for background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message: ${message.notification?.title}');
  // FCM usually handles showing the notification automatically
}
