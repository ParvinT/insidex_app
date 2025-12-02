// lib/features/search/search_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/session_filter_service.dart';
import '../../services/language_helper_service.dart';
import '../../services/category/category_service.dart';

class SearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Search results container
  Map<String, dynamic> searchResults = {
    'categories': <Map<String, dynamic>>[],
    'sessions': <Map<String, dynamic>>[],
  };

  /// Main search function
  /// Searches in: session names, descriptions, and category names
  Future<Map<String, dynamic>> search(String query) async {
    if (query.trim().isEmpty) {
      return {
        'categories': <Map<String, dynamic>>[],
        'sessions': <Map<String, dynamic>>[],
      };
    }

    final lowercaseQuery = query.toLowerCase().trim();

    // Search in parallel
    final results = await Future.wait([
      _searchCategories(lowercaseQuery),
      _searchSessions(lowercaseQuery),
    ]);

    return {
      'categories': results[0],
      'sessions': results[1],
    };
  }

  /// Search categories by name
  Future<List<Map<String, dynamic>>> _searchCategories(String query) async {
    try {
      final categoryService = CategoryService();
      final userLanguage = await LanguageHelperService.getCurrentLanguage();
      final categories =
          await categoryService.getCategoriesByLanguage(userLanguage);

      final matches = categories.where((category) {
        final name = category.getName(userLanguage).toLowerCase();
        return name.contains(query);
      }).map((category) {
        return {
          'id': category.id,
          'name': category.getName(userLanguage),
          'iconName': category.iconName,
          'color': '0xFF6B5B95', // Default color
        };
      }).toList();

      return matches;
    } catch (e) {
      // Silent fail - return empty list
      return [];
    }
  }

  /// Search sessions by title and description
  /// Searches ONLY in current app language content
  Future<List<Map<String, dynamic>>> _searchSessions(String query) async {
    try {
      // 🆕 TEMPORARY PATCH: Limit to 50 sessions for cost control
      // TODO: Migrate to Algolia when search volume > 3K/day (3-6 months)
      final snapshot = await _firestore
          .collection('sessions')
          .limit(50) // Max 50 sessions to prevent excessive reads
          .get();

      // ✅ LANGUAGE FILTER - Apply FIRST to get only sessions with current language
      final languageFilteredSessions =
          await SessionFilterService.filterSessionsByLanguage(snapshot.docs);

      // 🆕 Get current app language ONCE
      final currentLanguage = await LanguageHelperService.getCurrentLanguage();

      // Then filter by search query in CURRENT LANGUAGE ONLY
      final searchMatches = languageFilteredSessions.where((session) {
        final data = session;

        String title = '';
        String description = '';
        String introTitle = '';
        String introContent = '';

        // Try NEW structure first (content.{lang})
        if (data['content'] is Map) {
          final content = data['content'] as Map;

          // 🆕 ONLY search in CURRENT language
          if (content[currentLanguage] is Map) {
            final langContent = content[currentLanguage] as Map;
            title = (langContent['title'] ?? '').toString().toLowerCase();
            description =
                (langContent['description'] ?? '').toString().toLowerCase();

            if (langContent['introduction'] is Map) {
              final intro = langContent['introduction'] as Map;
              introTitle = (intro['title'] ?? '').toString().toLowerCase();
              introContent = (intro['content'] ?? '').toString().toLowerCase();
            }
          }
        }

        // ✅ Backward compatibility: OLD structure
        if (title.isEmpty) {
          title = (data['title'] ?? '').toString().toLowerCase();
        }
        if (description.isEmpty) {
          description = (data['description'] ?? '').toString().toLowerCase();
        }

        final oldIntroTitle = data['intro'] is Map
            ? ((data['intro'] as Map)['title'] ?? '').toString().toLowerCase()
            : '';

        final oldIntroContent = data['introduction'] is Map
            ? ((data['introduction'] as Map)['content'] ?? '')
                .toString()
                .toLowerCase()
            : '';

        // Search in subliminal affirmations
        final affirmations = data['subliminal'] is Map &&
                (data['subliminal'] as Map)['affirmations'] is List
            ? (data['subliminal'] as Map)['affirmations']
                .map((a) => a.toString().toLowerCase())
                .join(' ')
            : '';

        // ✅ Match ONLY in current language content
        return title.contains(query) ||
            description.contains(query) ||
            introTitle.contains(query) ||
            introContent.contains(query) ||
            oldIntroTitle.contains(query) ||
            oldIntroContent.contains(query) ||
            affirmations.contains(query);
      }).toList();

      return searchMatches;
    } catch (e) {
      // Silent fail - return empty list
      return [];
    }
  }

  /// Get total result count
  int getTotalResultCount(Map<String, dynamic> results) {
    final categoryCount = (results['categories'] as List).length;
    final sessionCount = (results['sessions'] as List).length;
    return categoryCount + sessionCount;
  }
}
