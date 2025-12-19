// lib/core/constants/app_languages.dart

/// Central language management for the app
/// This is the SINGLE SOURCE OF TRUTH for supported languages
///
/// To add a new language:
/// 1. Add language code to [supportedLanguages]
/// 2. Add language info to [languageInfo]
/// 3. Create lib/l10n/app_{code}.arb file
/// 4. Run: flutter gen-l10n
/// 5. Add content for that language in admin panel
class AppLanguages {
  /// Supported languages in the app
  /// MUST match with l10n .arb files
  static const List<String> supportedLanguages = [
    'en',
    'tr',
    'ru',
    'hi',
  ];

  /// Language information (name + flag)
  static const Map<String, Map<String, String>> languageInfo = {
    'en': {'name': 'English', 'flag': '🇬🇧', 'countryCode': 'GB'},
    'tr': {'name': 'Türkçe', 'flag': '🇹🇷', 'countryCode': 'TR'},
    'ru': {'name': 'Русский', 'flag': '🇷🇺', 'countryCode': 'RU'},
    'hi': {'name': 'हिन्दी', 'flag': '🇮🇳', 'countryCode': 'IN'},
  };

  /// Default fallback language
  static const String defaultLanguage = 'en';

  // =================== HELPER METHODS ===================

  /// Get language display name
  /// Example: 'en' → 'English'
  static String getName(String code) {
    return languageInfo[code]?['name'] ?? code.toUpperCase();
  }

  /// Get language flag emoji
  /// Example: 'en' → '🇬🇧'
  static String getFlag(String code) {
    return languageInfo[code]?['flag'] ?? '🌐';
  }

  /// Get country code for flag widget
  /// Example: 'en' → 'GB'
  static String getCountryCode(String code) {
    return languageInfo[code]?['countryCode'] ?? 'GB';
  }

  /// Get language label (flag + code)
  /// Example: 'en' → '🇬🇧 EN'
  static String getLabel(String code) {
    return '${getFlag(code)} ${code.toUpperCase()}';
  }

  /// Get language full label (flag + name)
  /// Example: 'en' → '🇬🇧 English'
  static String getFullLabel(String code) {
    return '${getFlag(code)} ${getName(code)}';
  }

  /// Check if language is supported
  static bool isSupported(String code) {
    return supportedLanguages.contains(code);
  }

  /// Get language code with fallback
  /// If code is not supported, returns default language
  static String getSafeLanguageCode(String code) {
    return isSupported(code) ? code : defaultLanguage;
  }
}
