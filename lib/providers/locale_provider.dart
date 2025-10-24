// lib/providers/locale_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui' as ui;

import '../services/notifications/daily_reminder_service.dart';
import '../services/notifications/notification_sync_service.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en'); // Varsayılan İngilizce

  Locale get locale => _locale;

  // Desteklenen diller
  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('ru'),
    Locale('tr'),
  ];

  // Provider başlatıldığında kaydedilmiş dili yükle
  LocaleProvider() {
    _loadSavedLocale();
  }

  // Kaydedilmiş dili yükle
  Future<void> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('language_code');

    if (languageCode != null) {
      // Kaydedilmiş dil varsa onu kullan
      _locale = Locale(languageCode);
    } else {
      // Yoksa sistem dilini kontrol et
      _locale = _getDeviceLocale();
    }

    notifyListeners();
  }

  // Cihazın dilini al (destekleniyorsa)
  Locale _getDeviceLocale() {
    // Platformun dilini al
    final deviceLocale = ui.PlatformDispatcher.instance.locale;

    // Desteklenen diller arasında var mı kontrol et
    final isSupported = supportedLocales.any(
      (locale) => locale.languageCode == deviceLocale.languageCode,
    );

    // Destekleniyorsa cihaz dilini, yoksa İngilizce kullan
    return isSupported ? Locale(deviceLocale.languageCode) : const Locale('en');
  }

  // Dil değiştir ve kaydet
  Future<void> setLocale(Locale locale) async {
    // Desteklenen bir dil mi kontrol et
    if (!supportedLocales.contains(locale)) {
      debugPrint('⚠️ Unsupported Language: ${locale.languageCode}');
      return;
    }

    _locale = locale;

    // SharedPreferences'a kaydet
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', locale.languageCode);

    await Future.delayed(const Duration(seconds: 1));

    debugPrint('✅ Language changed: ${locale.languageCode}');
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

  // Dil adını al (UI'da göstermek için)
  String getLanguageName(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'English';
      case 'ru':
        return 'Русский';
      case 'tr':
        return 'Türkçe';
      default:
        return languageCode.toUpperCase();
    }
  }

  // Dil emoji'si al (UI'da göstermek için)
  String getLanguageFlag(String languageCode) {
    switch (languageCode) {
      case 'en':
        return '🇬🇧';
      case 'ru':
        return '🇷🇺';
      case 'tr':
        return '🇹🇷';
      default:
        return '🌍';
    }
  }
}
