// lib/providers/locale_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en'); // Varsayılan İngilizce

  Locale get locale => _locale;

  // Desteklenen diller
  static const List<Locale> supportedLocales = [
    Locale('en'), // İngilizce
    Locale('ru'), // Rusça
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
    // Platform locale'i alınacak (şimdilik varsayılan İngilizce)
    // Gerçek implementasyon main.dart'ta olacak
    return const Locale('en');
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

    debugPrint('✅ Language changed: ${locale.languageCode}');
    notifyListeners();
  }

  // Dil adını al (UI'da göstermek için)
  String getLanguageName(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'English';
      case 'ru':
        return 'Русский';
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
      default:
        return '🌍';
    }
  }
}
