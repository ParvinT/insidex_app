// lib/providers/locale_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui' as ui;

import '../services/notifications/daily_reminder_service.dart';
import '../services/notifications/notification_sync_service.dart';
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

  LocaleProvider() {
    _loadSavedLocale();
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

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', locale.languageCode);
    debugPrint('🟢 Saved to SharedPreferences: ${locale.languageCode}');

    LanguageHelperService.clearCache();

    await Future.delayed(const Duration(seconds: 1));

    debugPrint('✅ Language changed: ${locale.languageCode}');
    debugPrint('🔔 Calling notifyListeners()...');
    await _rescheduleNotifications();
    notifyListeners();
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

  String getLanguageFlag(String languageCode) {
    switch (languageCode) {
      case 'en':
        return '🇬🇧';
      case 'ru':
        return '🇷🇺';
      case 'tr':
        return '🇹🇷';
      case 'hi':
        return '🇮🇳';
      default:
        return '🌍';
    }
  }
}
