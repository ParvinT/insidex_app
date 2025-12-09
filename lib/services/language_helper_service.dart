// lib/services/language_helper_service.dart

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui' as ui;

/// Centralized service for language-aware resource management
/// Handles audio and image URL selection based on user's current language
class LanguageHelperService {
  // Supported languages - same as LocaleProvider
  static const List<String> supportedLanguages = ['en', 'tr', 'ru', 'hi'];
  static const String defaultLanguage = 'en';

  static String? _cachedLanguage;
  static DateTime? _cacheTime;
  static const _cacheDuration = Duration(minutes: 5);

  /// Get user's current language code
  /// Priority: 1) Saved preference 2) Device language 3) Default (en)
  static Future<String> getCurrentLanguage() async {
    if (_cachedLanguage != null &&
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < _cacheDuration) {
      return _cachedLanguage!; // Return cached (no log spam!)
    }
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Check saved language preference (same key as LocaleProvider)
      final savedLanguage = prefs.getString('language_code');
      if (savedLanguage != null && supportedLanguages.contains(savedLanguage)) {
        debugPrint('🌐 [LanguageHelper] Using saved language: $savedLanguage');
        _cachedLanguage = savedLanguage;
        _cacheTime = DateTime.now();
        return savedLanguage;
      }

      // 2. Check device language
      final deviceLocale = ui.PlatformDispatcher.instance.locale;
      final deviceLanguageCode = deviceLocale.languageCode;

      if (supportedLanguages.contains(deviceLanguageCode)) {
        debugPrint(
            '🌐 [LanguageHelper] Using device language: $deviceLanguageCode');
        _cachedLanguage = deviceLanguageCode;
        _cacheTime = DateTime.now();
        return deviceLanguageCode;
      }

      // 3. Fallback to default
      debugPrint(
          '🌐 [LanguageHelper] Using default language: $defaultLanguage');
      _cachedLanguage = defaultLanguage;
      _cacheTime = DateTime.now();
      return defaultLanguage;
    } catch (e) {
      debugPrint('⚠️ [LanguageHelper] Error getting language: $e');
      return defaultLanguage;
    }
  }

  /// Get audio URL for current language with fallback
  /// Returns the audio URL for user's language, or English if not available
  static String getAudioUrl(
    Map<String, dynamic>? audioUrls,
    String currentLanguage,
  ) {
    if (audioUrls == null || audioUrls.isEmpty) {
      debugPrint('⚠️ [LanguageHelper] No audio URLs provided');
      return '';
    }

    // Try current language
    final url = audioUrls[currentLanguage];
    if (url != null && url.toString().isNotEmpty) {
      debugPrint('🎵 [LanguageHelper] Audio URL found for: $currentLanguage');
      return url.toString();
    }

    // Fallback to English
    final fallbackUrl = audioUrls[defaultLanguage];
    if (fallbackUrl != null && fallbackUrl.toString().isNotEmpty) {
      debugPrint('🎵 [LanguageHelper] Using fallback audio URL (en)');
      return fallbackUrl.toString();
    }

    // Last resort: return first available
    final firstUrl = audioUrls.values.firstWhere(
      (url) => url != null && url.toString().isNotEmpty,
      orElse: () => '',
    );

    if (firstUrl.toString().isNotEmpty) {
      debugPrint('🎵 [LanguageHelper] Using first available audio URL');
    }

    return firstUrl.toString();
  }

  /// Get image URL for current language with fallback
  /// Returns the image URL for user's language, or English if not available
  static String getImageUrl(
    Map<String, dynamic>? imageUrls,
    String currentLanguage,
  ) {
    if (imageUrls == null || imageUrls.isEmpty) {
      debugPrint('⚠️ [LanguageHelper] No image URLs provided');
      return '';
    }

    // Try current language
    final url = imageUrls[currentLanguage];
    if (url != null && url.toString().isNotEmpty) {
      debugPrint('🖼️ [LanguageHelper] Image URL found for: $currentLanguage');
      return url.toString();
    }

    // Fallback to English
    final fallbackUrl = imageUrls[defaultLanguage];
    if (fallbackUrl != null && fallbackUrl.toString().isNotEmpty) {
      debugPrint('🖼️ [LanguageHelper] Using fallback image URL (en)');
      return fallbackUrl.toString();
    }

    // Last resort: return first available
    final firstUrl = imageUrls.values.firstWhere(
      (url) => url != null && url.toString().isNotEmpty,
      orElse: () => '',
    );

    if (firstUrl.toString().isNotEmpty) {
      debugPrint('🖼️ [LanguageHelper] Using first available image URL');
    }

    return firstUrl.toString();
  }

  /// Get duration for current language with fallback
  /// Returns the duration in seconds for user's language audio
  static int getDuration(
    Map<String, dynamic>? durations,
    String currentLanguage,
  ) {
    if (durations == null || durations.isEmpty) {
      return 0;
    }

    // Try current language
    final duration = durations[currentLanguage];
    if (duration != null && duration is int && duration > 0) {
      return duration;
    }

    // Fallback to English
    final fallbackDuration = durations[defaultLanguage];
    if (fallbackDuration != null &&
        fallbackDuration is int &&
        fallbackDuration > 0) {
      return fallbackDuration;
    }

    // Last resort: return first available
    final firstDuration = durations.values.firstWhere(
      (d) => d != null && d is int && d > 0,
      orElse: () => 0,
    );

    return firstDuration is int ? firstDuration : 0;
  }

  /// Check if a language is supported
  static bool isLanguageSupported(String languageCode) {
    return supportedLanguages.contains(languageCode);
  }

  /// Get language name for display
  static String getLanguageName(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'English';
      case 'tr':
        return 'Türkçe';
      case 'ru':
        return 'Русский';
      case 'hi':
        return 'हिन्दी';
      default:
        return languageCode.toUpperCase();
    }
  }

  /// Get language flag emoji
  static String getLanguageFlag(String languageCode) {
    switch (languageCode) {
      case 'en':
        return '🇬🇧';
      case 'tr':
        return '🇹🇷';
      case 'ru':
        return '🇷🇺';
      case 'hi':
        return '🇮🇳';
      default:
        return '🌍';
    }
  }

  /// Debug helper: Print all available languages for a resource
  static void debugPrintAvailableLanguages(
    Map<String, dynamic>? resources,
    String resourceType,
  ) {
    if (resources == null || resources.isEmpty) {
      debugPrint('⚠️ [$resourceType] No resources available');
      return;
    }

    final available = resources.keys
        .where((key) =>
            resources[key] != null && resources[key].toString().isNotEmpty)
        .toList();

    debugPrint('📋 [$resourceType] Available languages: $available');
  }

  static void clearCache() {
    _cachedLanguage = null;
    _cacheTime = null;
    debugPrint('🗑️ [LanguageHelper] Cache cleared');
  }
}
