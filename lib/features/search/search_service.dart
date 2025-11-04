// lib/features/search/search_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/session_filter_service.dart';

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
      final snapshot = await _firestore.collection('categories').get();

      final matches = snapshot.docs.where((doc) {
        final data = doc.data();
        final title = (data['title'] ?? '').toString().toLowerCase();
        return title.contains(query);
      }).map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'title': data['title'] ?? 'Untitled',
          'emoji': data['emoji'] ?? '🎵',
          'color': data['color'] ?? '0xFF6B5B95',
          'description': data['description'] ?? '',
        };
      }).toList();

      return matches;
    } catch (e) {
      // Silent fail - return empty list
      return [];
    }
  }

  /// Search sessions by title and description
  /// Search sessions by title and description
  Future<List<Map<String, dynamic>>> _searchSessions(String query) async {
    try {
      final snapshot = await _firestore.collection('sessions').get();

      // First, filter by search query
      final searchMatches = snapshot.docs.where((doc) {
        final data = doc.data();

        // Search in main title
        final title = (data['title'] ?? '').toString().toLowerCase();

        // Search in description
        final description =
            (data['description'] ?? '').toString().toLowerCase();

        // Search in intro title (old structure for backward compatibility)
        final introTitle = data['intro'] is Map
            ? ((data['intro'] as Map)['title'] ?? '').toString().toLowerCase()
            : '';

        // Search in introduction content (new structure)
        final introContent = data['introduction'] is Map
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

        // Match if any field contains the query
        return title.contains(query) ||
            description.contains(query) ||
            introTitle.contains(query) ||
            introContent.contains(query) ||
            affirmations.contains(query);
      }).toList();

      // ✅ LANGUAGE FILTER - Apply after search
      final filteredMatches =
          await SessionFilterService.filterSessionsByLanguage(searchMatches);

      return filteredMatches;
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
