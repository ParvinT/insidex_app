// lib/features/search/quiz_search_service.dart

import 'package:flutter/foundation.dart';
import '../../models/disease_model.dart';
import '../../models/quiz_category_model.dart';
import '../quiz/services/quiz_service.dart';
import '../quiz/services/quiz_category_service.dart';
import '../../services/language_helper_service.dart';
import '../../services/disease/disease_cause_service.dart';

/// Search result model for quiz categories
class QuizCategorySearchResult {
  final QuizCategoryModel category;
  final int maleCount;
  final int femaleCount;

  QuizCategorySearchResult({
    required this.category,
    required this.maleCount,
    required this.femaleCount,
  });

  int get totalCount => maleCount + femaleCount;
}

/// Search result model for diseases
class DiseaseSearchResult {
  final DiseaseModel disease;
  final QuizCategoryModel? category;
  final bool hasSession;

  DiseaseSearchResult({
    required this.disease,
    this.category,
    this.hasSession = false,
  });
}

/// Service for searching quiz-related content
/// Uses cached data from QuizService and QuizCategoryService
class QuizSearchService {
  static final QuizSearchService _instance = QuizSearchService._internal();
  factory QuizSearchService() => _instance;
  QuizSearchService._internal();

  final QuizService _quizService = QuizService();
  final QuizCategoryService _categoryService = QuizCategoryService();
  final DiseaseCauseService _causeService = DiseaseCauseService();

  // Cache for disease counts per category
  Map<String, int>? _maleCounts;
  Map<String, int>? _femaleCounts;

  /// Search quiz categories by name
  /// Returns categories matching the query with disease counts
  Future<List<QuizCategorySearchResult>> searchQuizCategories(
    String query,
  ) async {
    try {
      if (query.trim().isEmpty) {
        return [];
      }

      final lowercaseQuery = query.toLowerCase().trim();
      final currentLang = await LanguageHelperService.getCurrentLanguage();

      // Get all categories from cache
      final categories = await _categoryService.getAllCategories();

      // Load disease counts if not cached
      await _loadDiseaseCounts();

      // Filter categories by query
      final results = categories.where((category) {
        // Search in all language names
        final matchesCurrentLang = category
            .getName(currentLang)
            .toLowerCase()
            .contains(lowercaseQuery);

        // Also search in English as fallback
        final matchesEnglish =
            category.getName('en').toLowerCase().contains(lowercaseQuery);

        return matchesCurrentLang || matchesEnglish;
      }).map((category) {
        return QuizCategorySearchResult(
          category: category,
          maleCount: _maleCounts?[category.id] ?? 0,
          femaleCount: _femaleCounts?[category.id] ?? 0,
        );
      }).toList();

      // Sort by total count (most diseases first)
      results.sort((a, b) => b.totalCount.compareTo(a.totalCount));

      debugPrint(
          '🔍 [QuizSearchService] Categories search "$query": ${results.length} results');
      return results;
    } catch (e) {
      debugPrint('❌ [QuizSearchService] Error searching categories: $e');
      return [];
    }
  }

  /// Search diseases by name
  /// Returns diseases matching the query with category info
  Future<List<DiseaseSearchResult>> searchDiseases(
    String query, {
    String? genderFilter,
  }) async {
    try {
      if (query.trim().isEmpty) {
        return [];
      }

      final lowercaseQuery = query.toLowerCase().trim();
      final currentLang = await LanguageHelperService.getCurrentLanguage();

      // Get all diseases from cache
      final diseases = await _quizService.getAllDiseases();

      // Get all categories for mapping
      final categories = await _categoryService.getAllCategories();
      final categoryMap = {for (var c in categories) c.id: c};

      // 🆕 Get all disease causes to check session availability
      final allCauses = await _causeService.getAllDiseaseCauses();
      final causeMap = {for (var c in allCauses) c.diseaseId: c};

      // Filter diseases by query and optional gender
      final filteredDiseases = diseases.where((disease) {
        // Gender filter
        if (genderFilter != null && disease.gender != genderFilter) {
          return false;
        }

        // Search in current language name
        final name = disease.getLocalizedName(currentLang).toLowerCase();
        if (name.contains(lowercaseQuery)) {
          return true;
        }

        // Also search in English
        final englishName = disease.getLocalizedName('en').toLowerCase();
        return englishName.contains(lowercaseQuery);
      }).toList();

      // Map to search results with category info
      final results = filteredDiseases.map((disease) {
        final category =
            disease.categoryId != null ? categoryMap[disease.categoryId] : null;

        // 🆕 Check if disease has a recommended session
        final cause = causeMap[disease.id];
        final hasSession = cause != null && cause.hasRecommendedSession;

        return DiseaseSearchResult(
          disease: disease,
          category: category,
          hasSession: hasSession, // 🆕 Artık gerçek değer!
        );
      }).toList();

      // Sort alphabetically by current language
      results.sort((a, b) {
        final nameA = a.disease.getLocalizedName(currentLang).toLowerCase();
        final nameB = b.disease.getLocalizedName(currentLang).toLowerCase();
        return nameA.compareTo(nameB);
      });

      debugPrint(
          '🔍 [QuizSearchService] Diseases search "$query": ${results.length} results');
      return results;
    } catch (e) {
      debugPrint('❌ [QuizSearchService] Error searching diseases: $e');
      return [];
    }
  }

  /// Combined search for both categories and diseases
  Future<Map<String, dynamic>> searchAll(String query) async {
    if (query.trim().isEmpty) {
      return {
        'quizCategories': <QuizCategorySearchResult>[],
        'diseases': <DiseaseSearchResult>[],
      };
    }

    // Search in parallel
    final results = await Future.wait([
      searchQuizCategories(query),
      searchDiseases(query),
    ]);

    return {
      'quizCategories': results[0] as List<QuizCategorySearchResult>,
      'diseases': results[1] as List<DiseaseSearchResult>,
    };
  }

  /// Load disease counts per category
  Future<void> _loadDiseaseCounts() async {
    if (_maleCounts != null && _femaleCounts != null) {
      return;
    }

    try {
      _maleCounts = await _categoryService.getCategoryDiseaseCounts('male');
      _femaleCounts = await _categoryService.getCategoryDiseaseCounts('female');
    } catch (e) {
      debugPrint('❌ [QuizSearchService] Error loading disease counts: $e');
      _maleCounts = {};
      _femaleCounts = {};
    }
  }

  /// Get total result count
  int getTotalQuizResultCount(Map<String, dynamic> results) {
    final categoryCount =
        (results['quizCategories'] as List<QuizCategorySearchResult>).length;
    final diseaseCount =
        (results['diseases'] as List<DiseaseSearchResult>).length;
    return categoryCount + diseaseCount;
  }

  /// Clear cache
  void clearCache() {
    _maleCounts = null;
    _femaleCounts = null;
    debugPrint('🗑️ [QuizSearchService] Cache cleared');
  }
}
