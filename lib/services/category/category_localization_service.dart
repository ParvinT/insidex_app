// lib/services/category/category_localization_service.dart

import 'package:flutter/foundation.dart';
import '../../models/category_model.dart';
import '../language_helper_service.dart';

/// Service for getting localized category content
class CategoryLocalizationService {
  /// Get localized category name
  /// Automatically falls back to English if user's language is not available
  static String getLocalizedName(CategoryModel category, String locale) {
    return category.getName(locale);
  }

  /// Get localized name using current app locale
  static Future<String> getLocalizedNameAuto(CategoryModel category) async {
    final locale = await LanguageHelperService.getCurrentLanguage();
    return category.getName(locale);
  }

  /// Check if category has name for specific language
  static bool hasLanguage(CategoryModel category, String locale) {
    return category.hasLanguage(locale);
  }

  /// Get list of available languages for a category
  static List<String> getAvailableLanguages(CategoryModel category) {
    return category.availableLanguages;
  }

  /// Get language display name
  static String getLanguageDisplayName(String locale) {
    return LanguageHelperService.getLanguageName(locale);
  }

  /// Get language flag emoji
  static String getLanguageFlag(String locale) {
    return LanguageHelperService.getLanguageFlag(locale);
  }

  /// Check if category is missing content for user's language
  /// Returns true if fallback is being used
  static Future<bool> isUsingFallback(CategoryModel category) async {
    final userLocale = await LanguageHelperService.getCurrentLanguage();
    return !category.hasLanguage(userLocale);
  }

  /// Get category name map for all languages with validation
  /// Returns only non-empty names
  static Map<String, String> getValidatedNames(Map<String, String> names) {
    final validatedNames = <String, String>{};

    names.forEach((lang, name) {
      final trimmedName = name.trim();
      if (trimmedName.isNotEmpty) {
        validatedNames[lang] = trimmedName;
      }
    });

    return validatedNames;
  }

  /// Check if at least one language has a name
  static bool hasAtLeastOneName(Map<String, String> names) {
    return names.values.any((name) => name.trim().isNotEmpty);
  }

  /// Get fallback name (first available)
  static String getFallbackName(CategoryModel category) {
    if (category.names.isEmpty) return 'Untitled';

    // Try English first
    if (category.names['en']?.isNotEmpty ?? false) {
      return category.names['en']!;
    }

    // Return first available
    final firstAvailable = category.names.values
        .firstWhere((name) => name.isNotEmpty, orElse: () => 'Untitled');

    return firstAvailable;
  }

  /// Debug: Print all names for a category
  static void debugPrintCategoryNames(CategoryModel category) {
    debugPrint('📁 Category: ${category.id}');
    debugPrint('   Icon: ${category.iconName}');
    category.names.forEach((lang, name) {
      debugPrint('   $lang: $name');
    });
    debugPrint(
        '   Available languages: ${category.availableLanguages.join(", ")}');
  }
}
