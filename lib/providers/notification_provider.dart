// lib/providers/notification_provider.dart

import 'dart:async';
import 'package:flutter/material.dart';
import '../features/notifications/notification_models.dart';
import '../services/notifications/notification_service.dart';
import '../services/notifications/daily_reminder_service.dart';
import '../services/notifications/notification_sync_service.dart';

class NotificationProvider extends ChangeNotifier {
  // Services are initialized directly, no instance needed for static methods
  final DailyReminderService _dailyReminderService = DailyReminderService();
  final NotificationSyncService _syncService = NotificationSyncService();

  NotificationSettings _settings = NotificationSettings.defaultSettings();
  bool _isLoading = false;
  bool _hasPermission = false;
  bool _systemNotificationsEnabled = true;
  StreamSubscription? _settingsSubscription;

  // Getters
  NotificationSettings get settings => _settings;
  bool get isLoading => _isLoading;
  bool get hasPermission => _hasPermission;
  bool get systemNotificationsEnabled => _systemNotificationsEnabled;
  bool get allNotificationsEnabled => _settings.allNotificationsEnabled;
  DailyReminder get dailyReminder => _settings.dailyReminder;

  /// Initialize provider
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Initialize notification service is already done in main.dart
      // Just load settings from Firebase
      final loadedSettings = await _syncService.loadSettingsFromFirebase();
      if (loadedSettings != null) {
        _settings = loadedSettings;
      }

      // Check permissions
      await checkPermissions();

      // Listen to Firebase changes
      _listenToSettingsChanges();

      // Schedule daily reminder if enabled
      if (_settings.dailyReminder.enabled && _hasPermission) {
        await _dailyReminderService
            .scheduleDailyReminder(_settings.dailyReminder);
      }

      debugPrint('NotificationProvider initialized');
    } catch (e) {
      debugPrint('Error initializing NotificationProvider: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Listen to settings changes from Firebase
  void _listenToSettingsChanges() {
    _settingsSubscription?.cancel();
    _settingsSubscription = _syncService.listenToSettingsChanges().listen(
      (settings) {
        if (settings.lastUpdated != _settings.lastUpdated) {
          _settings = settings;
          notifyListeners();

          // Update local notifications based on new settings
          if (_settings.dailyReminder.enabled && _hasPermission) {
            _dailyReminderService
                .scheduleDailyReminder(_settings.dailyReminder);
          } else {
            _dailyReminderService.cancelDailyReminder();
          }
        }
      },
      onError: (error) {
        debugPrint('Error listening to settings changes: $error');
      },
    );
  }

  /// Check notification permissions
  Future<void> checkPermissions() async {
    _hasPermission = await NotificationService().hasPermission();
    _systemNotificationsEnabled =
        await NotificationService().areSystemNotificationsEnabled();

    
    if (!_systemNotificationsEnabled || !_hasPermission) {
      
      if (_settings.allNotificationsEnabled ||
          _settings.dailyReminder.enabled) {
        _settings = _settings.copyWith(
          allNotificationsEnabled: false,
          dailyReminder: _settings.dailyReminder.copyWith(enabled: false),
        );

        // Daily reminder'ı iptal et
        await _dailyReminderService.cancelDailyReminder();

        // Firebase'e kaydet
        await _syncService.saveSettingsToFirebase(_settings);

        debugPrint('⚠️ System notifications disabled - app settings synced');
      }
    }

    notifyListeners();
  }

  /// Request notification permission
  Future<bool> requestPermission() async {
    final granted = await NotificationService().requestPermission();
    _hasPermission = granted;
    notifyListeners();

    if (granted) {
      // Enable notifications in settings
      await toggleAllNotifications(true);
    }

    return granted;
  }

  /// Toggle all notifications
  Future<void> toggleAllNotifications(bool enabled) async {
    // Check permission first if enabling
    if (enabled && !_hasPermission) {
      final granted = await requestPermission();
      if (!granted) return;
    }

    // Update settings
    _settings = _settings.copyWith(
      allNotificationsEnabled: enabled,
      dailyReminder: _settings.dailyReminder.copyWith(
        enabled: enabled ? _settings.dailyReminder.enabled : false,
      ),
    );
    notifyListeners();

    // Save to Firebase
    await _syncService.saveSettingsToFirebase(_settings);

    // Cancel all notifications if disabling
    if (!enabled) {
      await _dailyReminderService.cancelDailyReminder();
    } else if (_settings.dailyReminder.enabled) {
      // Reschedule if enabling and daily reminder was enabled
      await _dailyReminderService
          .scheduleDailyReminder(_settings.dailyReminder);
    }
  }

  /// Toggle daily reminder
  Future<void> toggleDailyReminder(bool enabled) async {
    // Can't enable if all notifications are disabled
    if (enabled && !_settings.allNotificationsEnabled) {
      debugPrint(
          'Cannot enable daily reminder when all notifications are disabled');
      return;
    }

    // Update settings
    final updatedReminder = _settings.dailyReminder.copyWith(enabled: enabled);
    _settings = _settings.copyWith(dailyReminder: updatedReminder);
    notifyListeners();

    // Save to Firebase
    await _syncService.updateDailyReminder(updatedReminder);

    // Update local notifications
    if (enabled) {
      await _dailyReminderService.scheduleDailyReminder(updatedReminder);
    } else {
      await _dailyReminderService.cancelDailyReminder();
    }
  }

  /// Update daily reminder time
  Future<void> updateDailyReminderTime(TimeOfDay time) async {
    final now = DateTime.now();
    final newScheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // Update settings
    final updatedReminder = _settings.dailyReminder.copyWith(
      scheduledTime: newScheduledTime,
    );
    _settings = _settings.copyWith(dailyReminder: updatedReminder);
    notifyListeners();

    // Save to Firebase
    await _syncService.updateDailyReminder(updatedReminder);

    // Reschedule if enabled
    if (updatedReminder.enabled && _hasPermission) {
      await _dailyReminderService.scheduleDailyReminder(updatedReminder);
    }
  }

  /// Open system notification settings
  Future<void> openSystemSettings() async {
    await NotificationService.openAppSettings();
    // Check permissions again after returning
    Future.delayed(const Duration(seconds: 1), checkPermissions);
  }

  /// Send test notification
  Future<void> sendTestNotification() async {
    await _dailyReminderService.sendTestNotification();
  }

  /// Migrate settings after login
  Future<void> migrateSettingsOnLogin() async {
    await _syncService.migrateSettingsOnLogin();
    await initialize(); // Reinitialize with new user
  }

  /// Clear settings on logout
  Future<void> clearSettingsOnLogout() async {
    await _dailyReminderService.cancelDailyReminder();
    _settings = NotificationSettings.defaultSettings();
    notifyListeners();
  }

  @override
  void dispose() {
    _settingsSubscription?.cancel();
    super.dispose();
  }
}
