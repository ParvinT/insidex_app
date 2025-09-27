import 'package:flutter/material.dart';
import 'notification_service.dart';

class AppLifecycleService extends WidgetsBindingObserver {
  static final AppLifecycleService _instance = AppLifecycleService._internal();
  factory AppLifecycleService() => _instance;
  AppLifecycleService._internal();

  DateTime? _pausedTime;

  // Initialize 
  void initialize() {
    WidgetsBinding.instance.addObserver(this);
    debugPrint('AppLifecycleService initialized');
  }

  // Dispose
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused) {
      _pausedTime = DateTime.now();
      debugPrint('App went to background');
    } else if (state == AppLifecycleState.resumed) {
      debugPrint('App resumed');

      if (_pausedTime != null) {
        final difference = DateTime.now().difference(_pausedTime!);
        if (difference.inSeconds > 2) {
          _checkPermissionSync();
        }
      }
    }
  }

  Future<void> _checkPermissionSync() async {
    debugPrint('🔄 Checking notification permission sync...');

    try {
      final service = NotificationService();

      final systemEnabled = await service.areNotificationsEnabled();
      final savedSettings = await service.getNotificationSettings();
      final firebaseEnabled = savedSettings['enabled'] ?? false;

      if (!systemEnabled && firebaseEnabled) {
        debugPrint('⚠️ Permission mismatch detected! Syncing...');

        await service.saveNotificationSettings({
          'enabled': false,
          'dailyReminder': false,
          'reminderTime': savedSettings['reminderTime'] ?? '20:00',
        });

        await service.cancelAllNotifications();

        debugPrint('✅ Permissions synced: Notifications disabled');
      } else {
        debugPrint('✅ Permissions already in sync');
      }
    } catch (e) {
      debugPrint('Error checking permission sync: $e');
    }
  }
}
