// lib/services/category/category_filter_service.dart

import 'package:flutter/foundation.dart';
import '../../models/category_model.dart';
import '../language_helper_service.dart';

/// Service for filtering categories based on language availability
class CategoryFilterService {
  /// Filter categories by user's current language
  /// Only returns categories that have name for the user's language
  static Future<List<CategoryModel>> filterCategoriesByLanguage(
    List<CategoryModel> categories,
  ) async {
    final userLanguage = await LanguageHelperService.getCurrentLanguage();

    final filteredCategories = categories.where((category) {
      return category.hasLanguage(userLanguage);
    }).toList();

    debugPrint(
        '🔍 Filtered ${filteredCategories.length}/${categories.length} categories for language: $userLanguage');

    return filteredCategories;
  }

  /// Check if a single category has name for user's language
  static Future<bool> hasNameForUserLanguage(CategoryModel category) async {
    final userLanguage = await LanguageHelperService.getCurrentLanguage();
    return category.hasLanguage(userLanguage);
  }

  /// Filter categories by specific language
  static List<CategoryModel> filterByLanguage(
    List<CategoryModel> categories,
    String locale,
  ) {
    return categories.where((category) {
      return category.hasLanguage(locale);
    }).toList();
  }

  /// Get categories that are missing content for a specific language
  static List<CategoryModel> getMissingLanguageCategories(
    List<CategoryModel> categories,
    String locale,
  ) {
    return categories.where((category) {
      return !category.hasLanguage(locale);
    }).toList();
  }

  /// Get language coverage statistics
  static Map<String, dynamic> getLanguageCoverage(
    List<CategoryModel> categories,
  ) {
    if (categories.isEmpty) {
      return {
        'total': 0,
        'en': 0,
        'tr': 0,
        'ru': 0,
        'hi': 0,
      };
    }

    final coverage = <String, int>{
      'total': categories.length,
      'en': 0,
      'tr': 0,
      'ru': 0,
      'hi': 0,
    };

    for (final category in categories) {
      if (category.hasLanguage('en')) coverage['en'] = coverage['en']! + 1;
      if (category.hasLanguage('tr')) coverage['tr'] = coverage['tr']! + 1;
      if (category.hasLanguage('ru')) coverage['ru'] = coverage['ru']! + 1;
      if (category.hasLanguage('hi')) coverage['hi'] = coverage['hi']! + 1;
    }

    return coverage;
  }

  /// Get categories with incomplete translations (missing at least one language)
  static List<CategoryModel> getIncompleteCategories(
    List<CategoryModel> categories,
  ) {
    const supportedLanguages = ['en', 'tr', 'ru', 'hi'];

    return categories.where((category) {
      // Check if any language is missing
      return supportedLanguages.any((lang) => !category.hasLanguage(lang));
    }).toList();
  }

  /// Get categories with complete translations (all 4 languages)
  static List<CategoryModel> getCompleteCategories(
    List<CategoryModel> categories,
  ) {
    const supportedLanguages = ['en', 'tr', 'ru', 'hi'];

    return categories.where((category) {
      // Check if all languages exist
      return supportedLanguages.every((lang) => category.hasLanguage(lang));
    }).toList();
  }

  /// Debug: Print language statistics
  static void debugPrintLanguageStats(List<CategoryModel> categories) {
    final coverage = getLanguageCoverage(categories);
    final incomplete = getIncompleteCategories(categories);
    final complete = getCompleteCategories(categories);

    debugPrint('📊 Category Language Statistics:');
    debugPrint('   Total: ${coverage['total']}');
    debugPrint('   English: ${coverage['en']} (${(coverage['en']! / coverage['total']! * 100).toStringAsFixed(1)}%)');
    debugPrint('   Turkish: ${coverage['tr']} (${(coverage['tr']! / coverage['total']! * 100).toStringAsFixed(1)}%)');
    debugPrint('   Russian: ${coverage['ru']} (${(coverage['ru']! / coverage['total']! * 100).toStringAsFixed(1)}%)');
    debugPrint('   Hindi: ${coverage['hi']} (${(coverage['hi']! / coverage['total']! * 100).toStringAsFixed(1)}%)');
    debugPrint('   Complete: ${complete.length}');
    debugPrint('   Incomplete: ${incomplete.length}');
  }
}