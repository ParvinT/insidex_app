// lib/providers/notification_provider.dart

import 'dart:async';
import 'package:flutter/material.dart';
import '../features/notifications/notification_models.dart';
import '../services/notifications/notification_service.dart';
import '../services/notifications/daily_reminder_service.dart';
import '../services/notifications/notification_sync_service.dart';

class NotificationProvider extends ChangeNotifier {
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
  bool get streakNotificationsEnabled => _settings.streakNotificationsEnabled;
  DailyReminder get dailyReminder => _settings.dailyReminder;

  /// Initialize provider
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Load settings from Firebase FIRST
      final loadedSettings = await _syncService.loadSettingsFromFirebase();
      if (loadedSettings != null) {
        _settings = loadedSettings;
        debugPrint(
            '📱 Loaded settings from Firebase: allNotificationsEnabled=${_settings.allNotificationsEnabled}');
      }

      // Check permissions (but DON'T auto-disable settings)
      await checkPermissions();

      // Listen to Firebase changes
      _listenToSettingsChanges();

      // Schedule daily reminder if enabled AND has permission
      if (_settings.dailyReminder.enabled && _hasPermission) {
        await _dailyReminderService
            .scheduleDailyReminder(_settings.dailyReminder);
        debugPrint('✅ Daily reminder scheduled');
      }

      debugPrint('✅ NotificationProvider initialized');
    } catch (e) {
      debugPrint('❌ Error initializing NotificationProvider: $e');
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
  /// IMPORTANT: This method ONLY updates permission status
  /// It does NOT auto-disable user's settings anymore
  Future<void> checkPermissions() async {
    try {
      _hasPermission = await NotificationService().hasPermission();
      _systemNotificationsEnabled =
          await NotificationService().areSystemNotificationsEnabled();

      debugPrint('🔔 Permission Check Results:');
      debugPrint('   - hasPermission: $_hasPermission');
      debugPrint(
          '   - systemNotificationsEnabled: $_systemNotificationsEnabled');
      debugPrint(
          '   - settings.allNotificationsEnabled: ${_settings.allNotificationsEnabled}');

      // ⚠️ REMOVED: Auto-disable logic
      // Artık kullanıcının ayarlarını zorla değiştirmiyoruz!
      // Sadece UI'da uyarı gösteriyoruz (notification_settings_screen.dart'ta)

      // Eğer izin yoksa ve bildirimler açıksa, sadece local notification'ları iptal et
      // Ama Firebase'deki settings'i DEĞİŞTİRME!
      if (!_hasPermission && _settings.dailyReminder.enabled) {
        await _dailyReminderService.cancelDailyReminder();
        debugPrint(
            '⚠️ Permission not granted - daily reminder cancelled (settings preserved)');
      }

      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error checking permissions: $e');
      // Hata durumunda mevcut değerleri koru
    }
  }

  /// Request notification permission
  Future<bool> requestPermission() async {
    final granted = await NotificationService().requestPermission();
    _hasPermission = granted;

    debugPrint('🔔 Permission request result: $granted');

    if (granted) {
      _systemNotificationsEnabled = true;

      // İzin verildi, eğer settings zaten açıksa daily reminder'ı schedule et
      if (_settings.allNotificationsEnabled &&
          _settings.dailyReminder.enabled) {
        await _dailyReminderService
            .scheduleDailyReminder(_settings.dailyReminder);
      }
    }

    notifyListeners();
    return granted;
  }

  /// Toggle all notifications
  Future<void> toggleAllNotifications(bool enabled) async {
    debugPrint('🔔 toggleAllNotifications: $enabled');

    // Check permission first if enabling
    if (enabled && !_hasPermission) {
      final granted = await requestPermission();
      if (!granted) {
        debugPrint('⚠️ Permission not granted, cannot enable notifications');
        return;
      }
    }

    // Update settings
    _settings = _settings.copyWith(
      allNotificationsEnabled: enabled,
      dailyReminder: _settings.dailyReminder.copyWith(
        enabled: enabled ? _settings.dailyReminder.enabled : false,
      ),
      streakNotificationsEnabled:
          enabled ? _settings.streakNotificationsEnabled : false,
    );
    notifyListeners();

    // Save to Firebase
    await _syncService.saveSettingsToFirebase(_settings);
    debugPrint(
        '💾 Settings saved to Firebase: allNotificationsEnabled=$enabled');

    // Handle local notifications
    if (!enabled) {
      await _dailyReminderService.cancelDailyReminder();
    } else if (_settings.dailyReminder.enabled && _hasPermission) {
      await _dailyReminderService
          .scheduleDailyReminder(_settings.dailyReminder);
    }
  }

  /// Toggle streak notifications
  Future<void> toggleStreakNotifications(bool enabled) async {
    if (enabled && !_settings.allNotificationsEnabled) {
      debugPrint(
          'Cannot enable streak notifications when all notifications are disabled');
      return;
    }

    _settings = _settings.copyWith(streakNotificationsEnabled: enabled);
    notifyListeners();

    await _syncService.saveSettingsToFirebase(_settings);
    debugPrint('💾 Streak notifications ${enabled ? "enabled" : "disabled"}');
  }

  /// Toggle daily reminder
  Future<void> toggleDailyReminder(bool enabled) async {
    debugPrint('🔔 toggleDailyReminder: $enabled');

    if (enabled && !_settings.allNotificationsEnabled) {
      debugPrint(
          'Cannot enable daily reminder when all notifications are disabled');
      return;
    }

    final updatedReminder = _settings.dailyReminder.copyWith(enabled: enabled);
    _settings = _settings.copyWith(dailyReminder: updatedReminder);
    notifyListeners();

    await _syncService.updateDailyReminder(updatedReminder);

    if (enabled && _hasPermission) {
      await _dailyReminderService.scheduleDailyReminder(updatedReminder);
      debugPrint('✅ Daily reminder scheduled');
    } else {
      await _dailyReminderService.cancelDailyReminder();
      debugPrint('🚫 Daily reminder cancelled');
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

    final updatedReminder = _settings.dailyReminder.copyWith(
      scheduledTime: newScheduledTime,
    );
    _settings = _settings.copyWith(dailyReminder: updatedReminder);
    notifyListeners();

    await _syncService.updateDailyReminder(updatedReminder);

    if (updatedReminder.enabled && _hasPermission) {
      await _dailyReminderService.scheduleDailyReminder(updatedReminder);
    }
  }

  /// Open system notification settings
  Future<void> openSystemSettings() async {
    await NotificationService.openAppSettings();
    // Check permissions again after returning (with delay for iOS)
    Future.delayed(const Duration(seconds: 1), () async {
      await checkPermissions();
      // İzin verildiyse ve settings açıksa, schedule et
      if (_hasPermission && _settings.dailyReminder.enabled) {
        await _dailyReminderService
            .scheduleDailyReminder(_settings.dailyReminder);
      }
    });
  }

  /// Send test notification
  Future<void> sendTestNotification() async {
    await _dailyReminderService.sendTestNotification();
  }

  /// Migrate settings after login
  Future<void> migrateSettingsOnLogin() async {
    await _syncService.migrateSettingsOnLogin();
    await initialize();
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
