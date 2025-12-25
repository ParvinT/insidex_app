// lib/features/quiz/services/quiz_service.dart

import 'package:flutter/foundation.dart';
import '../../../models/disease_model.dart';
import '../../../models/quiz_category_model.dart';
import '../../../services/disease/disease_service.dart';
import '../../../services/disease/disease_cause_service.dart';
import '../../../services/language_helper_service.dart';
import 'quiz_category_service.dart';

/// Quiz Service - Facade pattern for disease quiz functionality
/// Wraps DiseaseService and DiseaseCauseService for cleaner API
class QuizService {
  static final QuizService _instance = QuizService._internal();
  factory QuizService() => _instance;
  QuizService._internal();

  final DiseaseService _diseaseService = DiseaseService();
  final DiseaseCauseService _causeService = DiseaseCauseService();
  final QuizCategoryService _categoryService = QuizCategoryService();

  // =================== PUBLIC API ===================

  /// Get all diseases sorted alphabetically by current language
  Future<List<DiseaseModel>> getAllDiseases({
    bool forceRefresh = false,
  }) async {
    try {
      final diseases = await _diseaseService.getAllDiseases(
        forceRefresh: forceRefresh,
      );

      // Sort alphabetically by current language
      final currentLanguage = await LanguageHelperService.getCurrentLanguage();
      diseases.sort((a, b) {
        final nameA = a.getLocalizedName(currentLanguage).toLowerCase();
        final nameB = b.getLocalizedName(currentLanguage).toLowerCase();
        return nameA.compareTo(nameB);
      });

      debugPrint('✅ [QuizService] Loaded ${diseases.length} diseases');
      return diseases;
    } catch (e) {
      debugPrint('❌ [QuizService] Error loading diseases: $e');
      return [];
    }
  }

  /// Get diseases by gender, sorted alphabetically
  Future<List<DiseaseModel>> getDiseasesByGender(
    String gender, {
    bool forceRefresh = false,
  }) async {
    try {
      // ✅ Force refresh all diseases first
      final allDiseases = await _diseaseService.getAllDiseases(
        forceRefresh: forceRefresh,
      );

      // Filter by gender
      final diseases = gender == 'all'
          ? allDiseases
          : allDiseases.where((d) => d.gender == gender).toList();

      // Sort alphabetically by current language
      final currentLanguage = await LanguageHelperService.getCurrentLanguage();
      diseases.sort((a, b) {
        final nameA = a.getLocalizedName(currentLanguage).toLowerCase();
        final nameB = b.getLocalizedName(currentLanguage).toLowerCase();
        return nameA.compareTo(nameB);
      });

      debugPrint(
          '✅ [QuizService] Loaded ${diseases.length} diseases for gender: $gender');
      return diseases;
    } catch (e) {
      debugPrint('❌ [QuizService] Error loading diseases by gender: $e');
      return [];
    }
  }

  // =================== CATEGORY METHODS ===================

  /// Get all quiz categories
  Future<List<QuizCategoryModel>> getCategoriesByGender(
    String gender,
    String locale, {
    bool forceRefresh = false,
  }) async {
    try {
      final categories = await _categoryService.getCategoriesByGender(
        gender,
        locale,
        forceRefresh: forceRefresh,
      );

      debugPrint(
          '✅ [QuizService] Loaded ${categories.length} categories for gender: $gender');
      return categories;
    } catch (e) {
      debugPrint('❌ [QuizService] Error loading categories: $e');
      return [];
    }
  }

  /// Get diseases by category and gender, sorted alphabetically
  Future<List<DiseaseModel>> getDiseasesByCategoryAndGender(
    String? categoryId,
    String gender, {
    bool forceRefresh = false,
  }) async {
    try {
      final allDiseases = await _diseaseService.getAllDiseases(
        forceRefresh: forceRefresh,
      );

      // Filter by gender and category
      final diseases = allDiseases.where((d) {
        // Filter by gender
        if (d.gender != gender) return false;

        // Filter by category (null means "all categories")
        if (categoryId != null && d.categoryId != categoryId) return false;

        return true;
      }).toList();

      // Sort alphabetically by current language
      final currentLanguage = await LanguageHelperService.getCurrentLanguage();
      diseases.sort((a, b) {
        final nameA = a.getLocalizedName(currentLanguage).toLowerCase();
        final nameB = b.getLocalizedName(currentLanguage).toLowerCase();
        return nameA.compareTo(nameB);
      });

      debugPrint(
          '✅ [QuizService] Loaded ${diseases.length} diseases for category: ${categoryId ?? "all"}, gender: $gender');
      return diseases;
    } catch (e) {
      debugPrint('❌ [QuizService] Error loading diseases by category: $e');
      return [];
    }
  }

  /// Get disease counts per category for a gender
  Future<Map<String, int>> getCategoryDiseaseCounts(String gender) async {
    try {
      return await _categoryService.getCategoryDiseaseCounts(gender);
    } catch (e) {
      debugPrint('❌ [QuizService] Error getting category counts: $e');
      return {};
    }
  }

  /// Get disease recommendation (cause + session info)
  /// Returns: {
  ///   'disease': DiseaseModel,
  ///   'cause': DiseaseCauseModel?,
  ///   'hasRecommendation': bool,
  ///   'sessionId': String?,
  ///   'sessionNumber': int?
  /// }
  Future<Map<String, dynamic>> getDiseaseRecommendation(
    String diseaseId,
  ) async {
    try {
      // Get disease
      final disease = await _diseaseService.getDiseaseById(diseaseId);

      if (disease == null) {
        debugPrint('⚠️ [QuizService] Disease not found: $diseaseId');
        return {
          'disease': null,
          'cause': null,
          'hasRecommendation': false,
          'sessionId': null,
          'sessionNumber': null,
        };
      }

      // Get disease cause
      final cause = await _causeService.getDiseaseCauseByDiseaseId(diseaseId);

      if (cause == null) {
        debugPrint('⚠️ [QuizService] No cause found for disease: $diseaseId');
        return {
          'disease': disease,
          'cause': null,
          'hasRecommendation': false,
          'sessionId': null,
          'sessionNumber': null,
        };
      }

      debugPrint(
          '✅ [QuizService] Found recommendation for disease: ${disease.getLocalizedName('en')}');
      debugPrint('   → Session: ${cause.sessionNumber}');

      return {
        'disease': disease,
        'cause': cause,
        'hasRecommendation': true,
        'sessionId': cause.recommendedSessionId,
        'sessionNumber': cause.sessionNumber,
      };
    } catch (e) {
      debugPrint('❌ [QuizService] Error getting recommendation: $e');
      return {
        'disease': null,
        'cause': null,
        'hasRecommendation': false,
        'sessionId': null,
        'sessionNumber': null,
      };
    }
  }

  /// Get session by ID (for navigation)
  Future<Map<String, dynamic>?> getSessionById(String sessionId) async {
    try {
      // This will be used to navigate to session player
      // For now, we'll fetch from Firestore directly
      // In the future, you might want to add this to SessionService
      debugPrint('📍 [QuizService] Fetching session: $sessionId');
      return null; // Implement if needed
    } catch (e) {
      debugPrint('❌ [QuizService] Error fetching session: $e');
      return null;
    }
  }

  /// Search diseases by name
  Future<List<DiseaseModel>> searchDiseases(String query) async {
    try {
      if (query.trim().isEmpty) {
        return await getAllDiseases();
      }

      final allDiseases = await getAllDiseases();
      final currentLanguage = await LanguageHelperService.getCurrentLanguage();
      final lowercaseQuery = query.toLowerCase().trim();

      final results = allDiseases.where((disease) {
        final name = disease.getLocalizedName(currentLanguage).toLowerCase();
        return name.contains(lowercaseQuery);
      }).toList();

      debugPrint('🔍 [QuizService] Search "$query": ${results.length} results');
      return results;
    } catch (e) {
      debugPrint('❌ [QuizService] Error searching diseases: $e');
      return [];
    }
  }

  Future<Map<String, int>> getDiseaseCounts() async {
    try {
      final allDiseases = await getAllDiseases();

      final counts = <String, int>{
        'male': 0,
        'female': 0,
      };

      for (final disease in allDiseases) {
        counts[disease.gender] = (counts[disease.gender] ?? 0) + 1;
      }

      debugPrint('📊 [QuizService] Disease counts: $counts');
      return counts;
    } catch (e) {
      debugPrint('❌ [QuizService] Error getting disease counts: $e');
      return {'all': 0, 'male': 0, 'female': 0};
    }
  }

  /// Clear all caches
  void clearCache() {
    _diseaseService.clearCache();
    _causeService.clearCache();
    _categoryService.clearCache();
    debugPrint('🗑️ [QuizService] Cache cleared');
  }
}
