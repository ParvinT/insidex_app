// lib/providers/locale_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui' as ui;

import '../services/notifications/daily_reminder_service.dart';
import '../services/notifications/notification_sync_service.dart';
import '../services/notifications/topic_management_service.dart';
import '../services/language_helper_service.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('ru'),
    Locale('tr'),
    Locale('hi'),
  ];

  LocaleProvider._internal();
  static Future<LocaleProvider> initialize() async {
    final provider = LocaleProvider._internal();
    await provider._loadSavedLocale();
    debugPrint(
        '✅ LocaleProvider initialized with locale: ${provider.locale.languageCode}');
    return provider;
  }

  Future<void> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('language_code');

    if (languageCode != null) {
      _locale = Locale(languageCode);
      debugPrint('🔵 Loaded saved language: $languageCode');
    } else {
      _locale = _getDeviceLocale();
      debugPrint('🔵 Using device language: ${_locale.languageCode}');
    }

    notifyListeners();
  }

  Locale _getDeviceLocale() {
    final deviceLocale = ui.PlatformDispatcher.instance.locale;

    final isSupported = supportedLocales.any(
      (locale) => locale.languageCode == deviceLocale.languageCode,
    );

    return isSupported ? Locale(deviceLocale.languageCode) : const Locale('en');
  }

  Future<void> setLocale(Locale locale) async {
    debugPrint('🟡 setLocale called with: ${locale.languageCode}');
    if (!supportedLocales.contains(locale)) {
      debugPrint('⚠️ Unsupported Language: ${locale.languageCode}');
      return;
    }

    _locale = locale;
    debugPrint('🟢 _locale set to: ${_locale.languageCode}');

    // Step 1: Save to SharedPreferences (fast, critical for UI)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', locale.languageCode);

    // Step 2: Clear cache & update UI immediately
    LanguageHelperService.clearCache();
    debugPrint('✅ Language changed: ${locale.languageCode}');
    notifyListeners();

    // Step 3: Background tasks (fire-and-forget, UI doesn't wait)
    _syncLanguageInBackground(locale.languageCode);
  }

  /// Syncs language change to Firestore, FCM topics, and notifications.
  /// Runs in background without blocking UI.
  void _syncLanguageInBackground(String languageCode) {
    // Firestore update
    Future(() async {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({'preferredLanguage': languageCode});
          debugPrint('🟢 [Background] Saved to Firestore: $languageCode');
        }
      } catch (e) {
        debugPrint('⚠️ [Background] Firestore language sync error: $e');
      }
    });

    // FCM topic update
    Future(() async {
      try {
        await TopicManagementService().updateLanguageTopic(languageCode);
        debugPrint('🟢 [Background] FCM topic updated: $languageCode');
      } catch (e) {
        debugPrint('⚠️ [Background] FCM topic update error: $e');
      }
    });

    // Reschedule notifications with new language
    Future(() async {
      await _rescheduleNotifications();
    });
  }

  Future<void> _rescheduleNotifications() async {
    try {
      // Load current notification settings
      final settings =
          await NotificationSyncService().loadSettingsFromFirebase();

      if (settings != null && settings.dailyReminder.enabled) {
        // Reschedule with new language
        await DailyReminderService()
            .scheduleDailyReminder(settings.dailyReminder);
        debugPrint('✅ Daily reminder rescheduled with new language');
      }
    } catch (e) {
      debugPrint('⚠️ Error rescheduling notifications: $e');
      // Don't throw - language change should still work
    }
  }

  String getLanguageName(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'English';
      case 'ru':
        return 'Русский';
      case 'tr':
        return 'Türkçe';
      case 'hi':
        return 'हिन्दी';
      default:
        return languageCode.toUpperCase();
    }
  }

  String getCountryCode(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'GB';
      case 'ru':
        return 'RU';
      case 'tr':
        return 'TR';
      case 'hi':
        return 'IN';
      default:
        return 'GB';
    }
  }
}
