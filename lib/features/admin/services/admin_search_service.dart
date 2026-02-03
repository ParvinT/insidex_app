// lib/features/admin/services/admin_search_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Admin Search Service
/// 
/// Provides search functionality for admin panel across different collections.
/// Unlike user-facing search, this service:
/// - Does NOT filter by language (admin sees all languages)
/// - Does NOT filter by gender (admin sees all content)
/// - Has NO limits (admin has full access)
/// - Searches in ALL relevant fields
/// 
/// Usage:
/// ```dart
/// final service = AdminSearchService();
/// final results = await service.searchSessions('meditation');
/// ```
class AdminSearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Singleton pattern for efficiency
  static final AdminSearchService _instance = AdminSearchService._internal();
  factory AdminSearchService() => _instance;
  AdminSearchService._internal();

  // ============================================================
  // SESSION SEARCH
  // ============================================================

  /// Search sessions by title, description, or session number
  /// Searches across ALL languages (en, tr, ru, hi)
  Future<List<Map<String, dynamic>>> searchSessions(String query) async {
    if (query.trim().isEmpty) return [];

    final normalizedQuery = query.toLowerCase().trim();

    try {
      // Fetch all sessions (admin has full access)
      final snapshot = await _firestore
          .collection('sessions')
          .orderBy('createdAt', descending: true)
          .get();

      final results = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final sessionData = {'id': doc.id, ...data};

        if (_sessionMatchesQuery(sessionData, normalizedQuery)) {
          results.add(sessionData);
        }
      }

      debugPrint('🔍 [AdminSearch] Sessions: found ${results.length} results for "$query"');
      return results;
    } catch (e) {
      debugPrint('❌ [AdminSearch] Session search error: $e');
      return [];
    }
  }

  /// Check if session matches search query
  bool _sessionMatchesQuery(Map<String, dynamic> session, String query) {
    // Search in session number
    final sessionNumber = session['sessionNumber']?.toString() ?? '';
    if (sessionNumber.contains(query)) return true;

    // Search in NEW structure (multi-language content)
    if (session['content'] is Map) {
      final content = session['content'] as Map<String, dynamic>;
      
      for (final langContent in content.values) {
        if (langContent is Map) {
          // Title
          final title = (langContent['title'] ?? '').toString().toLowerCase();
          if (title.contains(query)) return true;

          // Description
          final description = (langContent['description'] ?? '').toString().toLowerCase();
          if (description.contains(query)) return true;

          // Introduction
          if (langContent['introduction'] is Map) {
            final intro = langContent['introduction'] as Map;
            final introTitle = (intro['title'] ?? '').toString().toLowerCase();
            final introContent = (intro['content'] ?? '').toString().toLowerCase();
            if (introTitle.contains(query) || introContent.contains(query)) return true;
          }
        }
      }
    }

    // Search in OLD structure (backward compatibility)
    final oldTitle = (session['title'] ?? '').toString().toLowerCase();
    if (oldTitle.contains(query)) return true;

    final oldDescription = (session['description'] ?? '').toString().toLowerCase();
    if (oldDescription.contains(query)) return true;

    return false;
  }

  // ============================================================
  // CATEGORY SEARCH
  // ============================================================

  /// Search categories by name across all languages
  Future<List<Map<String, dynamic>>> searchCategories(String query) async {
    if (query.trim().isEmpty) return [];

    final normalizedQuery = query.toLowerCase().trim();

    try {
      final snapshot = await _firestore
          .collection('categories')
          .orderBy('createdAt', descending: true)
          .get();

      final results = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final categoryData = {'id': doc.id, ...data};

        if (_categoryMatchesQuery(categoryData, normalizedQuery)) {
          results.add(categoryData);
        }
      }

      debugPrint('🔍 [AdminSearch] Categories: found ${results.length} results for "$query"');
      return results;
    } catch (e) {
      debugPrint('❌ [AdminSearch] Category search error: $e');
      return [];
    }
  }

  /// Check if category matches search query
  bool _categoryMatchesQuery(Map<String, dynamic> category, String query) {
    // Search in icon name
    final iconName = (category['iconName'] ?? '').toString().toLowerCase();
    if (iconName.contains(query)) return true;

    // Search in NEW structure (multi-language names)
    if (category['names'] is Map) {
      final names = category['names'] as Map<String, dynamic>;
      
      for (final name in names.values) {
        if (name.toString().toLowerCase().contains(query)) return true;
      }
    }

    // Search in OLD structure (single title)
    final oldTitle = (category['title'] ?? '').toString().toLowerCase();
    if (oldTitle.contains(query)) return true;

    return false;
  }

  // ============================================================
  // USER SEARCH
  // ============================================================

  /// Search users by email, display name, or user ID
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];

    final normalizedQuery = query.toLowerCase().trim();

    try {
      final snapshot = await _firestore
          .collection('users')
          .orderBy('createdAt', descending: true)
          .get();

      final results = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final userData = {'id': doc.id, ...data};

        if (_userMatchesQuery(userData, normalizedQuery)) {
          results.add(userData);
        }
      }

      debugPrint('🔍 [AdminSearch] Users: found ${results.length} results for "$query"');
      return results;
    } catch (e) {
      debugPrint('❌ [AdminSearch] User search error: $e');
      return [];
    }
  }

  /// Check if user matches search query
  bool _userMatchesQuery(Map<String, dynamic> user, String query) {
    // Search by user ID
    final userId = (user['id'] ?? '').toString().toLowerCase();
    if (userId.contains(query)) return true;

    // Search by email
    final email = (user['email'] ?? '').toString().toLowerCase();
    if (email.contains(query)) return true;

    // Search by display name
    final displayName = (user['displayName'] ?? '').toString().toLowerCase();
    if (displayName.contains(query)) return true;

    // Search by full name (firstName + lastName)
    final firstName = (user['firstName'] ?? '').toString().toLowerCase();
    final lastName = (user['lastName'] ?? '').toString().toLowerCase();
    final fullName = '$firstName $lastName'.trim();
    if (fullName.contains(query)) return true;

    return false;
  }

  // ============================================================
  // HOME CARDS SEARCH (Optional - for future use)
  // ============================================================

  /// Search home cards by title across all languages
  Future<List<Map<String, dynamic>>> searchHomeCards(String query) async {
    if (query.trim().isEmpty) return [];

    final normalizedQuery = query.toLowerCase().trim();

    try {
      final snapshot = await _firestore
          .collection('home_cards')
          .orderBy('order')
          .get();

      final results = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final cardData = {'id': doc.id, ...data};

        if (_homeCardMatchesQuery(cardData, normalizedQuery)) {
          results.add(cardData);
        }
      }

      debugPrint('🔍 [AdminSearch] HomeCards: found ${results.length} results for "$query"');
      return results;
    } catch (e) {
      debugPrint('❌ [AdminSearch] HomeCard search error: $e');
      return [];
    }
  }

  /// Check if home card matches search query
  bool _homeCardMatchesQuery(Map<String, dynamic> card, String query) {
    // Search in titles (multi-language)
    if (card['titles'] is Map) {
      final titles = card['titles'] as Map<String, dynamic>;
      for (final title in titles.values) {
        if (title.toString().toLowerCase().contains(query)) return true;
      }
    }

    // Search in subtitles (multi-language)
    if (card['subtitles'] is Map) {
      final subtitles = card['subtitles'] as Map<String, dynamic>;
      for (final subtitle in subtitles.values) {
        if (subtitle.toString().toLowerCase().contains(query)) return true;
      }
    }

    // Search by card type
    final cardType = (card['type'] ?? '').toString().toLowerCase();
    if (cardType.contains(query)) return true;

    return false;
  }

  // ============================================================
  // GENERIC FILTER FOR LOCAL DATA
  // ============================================================

  /// Filter already-loaded documents locally (for StreamBuilder data)
  /// This is useful when you have data from a stream and want to filter without re-fetching
  List<T> filterLocally<T>({
    required List<T> items,
    required String query,
    required bool Function(T item, String normalizedQuery) matcher,
  }) {
    if (query.trim().isEmpty) return items;

    final normalizedQuery = query.toLowerCase().trim();
    return items.where((item) => matcher(item, normalizedQuery)).toList();
  }

  /// Filter session documents locally
  List<QueryDocumentSnapshot> filterSessionsLocally(
    List<QueryDocumentSnapshot> docs,
    String query,
  ) {
    if (query.trim().isEmpty) return docs;

    final normalizedQuery = query.toLowerCase().trim();

    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return _sessionMatchesQuery({'id': doc.id, ...data}, normalizedQuery);
    }).toList();
  }

  /// Filter category documents locally
  List<QueryDocumentSnapshot> filterCategoriesLocally(
    List<QueryDocumentSnapshot> docs,
    String query,
  ) {
    if (query.trim().isEmpty) return docs;

    final normalizedQuery = query.toLowerCase().trim();

    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return _categoryMatchesQuery({'id': doc.id, ...data}, normalizedQuery);
    }).toList();
  }

  /// Filter user documents locally
  List<QueryDocumentSnapshot> filterUsersLocally(
    List<QueryDocumentSnapshot> docs,
    String query,
  ) {
    if (query.trim().isEmpty) return docs;

    final normalizedQuery = query.toLowerCase().trim();

    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return _userMatchesQuery({'id': doc.id, ...data}, normalizedQuery);
    }).toList();
  }
}