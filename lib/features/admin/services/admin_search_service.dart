// lib/features/admin/services/admin_search_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Admin Search Service
///
/// Provides search functionality for admin panel across different collections.
/// Unlike user-facing search, this service:
/// - Does NOT filter by language (admin sees all languages)
/// - Does NOT filter by gender (admin sees all content)
/// - Searches in session number and title only (NOT intro texts)
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

  // Cache for search optimization
  List<Map<String, dynamic>>? _sessionCache;
  DateTime? _sessionCacheTime;
  static const _cacheDuration = Duration(minutes: 3);

  void clearCache() {
    _sessionCache = null;
    _sessionCacheTime = null;
  }

  // ============================================================
  // SESSION SEARCH
  // ============================================================

  /// Search sessions by title or session number
  /// Only searches lightweight fields (NOT intro/description texts)
  Future<List<Map<String, dynamic>>> searchSessions(String query) async {
    if (query.trim().isEmpty) return [];

    final normalizedQuery = query.toLowerCase().trim();

    try {
      // Use cache if available and fresh
      List<Map<String, dynamic>> allSessions;

      if (_sessionCache != null &&
          _sessionCacheTime != null &&
          DateTime.now().difference(_sessionCacheTime!) < _cacheDuration) {
        allSessions = _sessionCache!;
        debugPrint(
            '🔍 [AdminSearch] Using cached sessions (${allSessions.length})');
      } else {
        // Fetch only needed fields using select() is not available in Flutter,
        // but we limit the search scope in matching logic
        final snapshot = await _firestore
            .collection('sessions')
            .orderBy('sessionNumber')
            .get();

        allSessions = snapshot.docs.map((doc) {
          final data = doc.data();
          return {'id': doc.id, ...data};
        }).toList();

        // Cache results
        _sessionCache = allSessions;
        _sessionCacheTime = DateTime.now();
        debugPrint(
            '🔍 [AdminSearch] Fetched & cached ${allSessions.length} sessions');
      }

      // Filter locally
      final results = allSessions
          .where((s) => _sessionMatchesQuery(s, normalizedQuery))
          .toList();

      debugPrint(
          '🔍 [AdminSearch] Sessions: found ${results.length} results for "$query"');
      return results;
    } catch (e) {
      debugPrint('❌ [AdminSearch] Session search error: $e');
      return [];
    }
  }

  /// Clear session cache (call after add/edit/delete)
  void clearSessionCache() {
    _sessionCache = null;
    _sessionCacheTime = null;
  }

  /// Check if session matches search query
  /// Only checks sessionNumber and title fields (lightweight)
  bool _sessionMatchesQuery(Map<String, dynamic> session, String query) {
    // Search in session number
    final sessionNumber = session['sessionNumber']?.toString() ?? '';
    if (sessionNumber == query) return true; // Exact number match
    if (sessionNumber.contains(query)) return true;

    // Search in multi-language titles only
    if (session['content'] is Map) {
      final content = session['content'] as Map<String, dynamic>;

      for (final langContent in content.values) {
        if (langContent is Map) {
          final title = (langContent['title'] ?? '').toString().toLowerCase();
          if (title.contains(query)) return true;
        }
      }
    }

    // Backward compatibility: old structure title
    final oldTitle = (session['title'] ?? '').toString().toLowerCase();
    if (oldTitle.contains(query)) return true;

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

      debugPrint(
          '🔍 [AdminSearch] Categories: found ${results.length} results for "$query"');
      return results;
    } catch (e) {
      debugPrint('❌ [AdminSearch] Category search error: $e');
      return [];
    }
  }

  /// Check if category matches search query
  bool _categoryMatchesQuery(Map<String, dynamic> category, String query) {
    final iconName = (category['iconName'] ?? '').toString().toLowerCase();
    if (iconName.contains(query)) return true;

    if (category['names'] is Map) {
      final names = category['names'] as Map<String, dynamic>;
      for (final name in names.values) {
        if (name.toString().toLowerCase().contains(query)) return true;
      }
    }

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

      debugPrint(
          '🔍 [AdminSearch] Users: found ${results.length} results for "$query"');
      return results;
    } catch (e) {
      debugPrint('❌ [AdminSearch] User search error: $e');
      return [];
    }
  }

  /// Check if user matches search query
  bool _userMatchesQuery(Map<String, dynamic> user, String query) {
    final userId = (user['id'] ?? '').toString().toLowerCase();
    if (userId.contains(query)) return true;

    final email = (user['email'] ?? '').toString().toLowerCase();
    if (email.contains(query)) return true;

    final displayName = (user['displayName'] ?? '').toString().toLowerCase();
    if (displayName.contains(query)) return true;

    final firstName = (user['firstName'] ?? '').toString().toLowerCase();
    final lastName = (user['lastName'] ?? '').toString().toLowerCase();
    if (firstName.contains(query) || lastName.contains(query)) return true;
    if ('$firstName $lastName'.contains(query)) return true;

    return false;
  }

  // ============================================================
  // HOME CARDS SEARCH
  // ============================================================

  /// Search home cards
  Future<List<Map<String, dynamic>>> searchHomeCards(String query) async {
    if (query.trim().isEmpty) return [];

    final normalizedQuery = query.toLowerCase().trim();

    try {
      final snapshot = await _firestore.collection('home_cards').get();

      final results = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final cardData = {'id': doc.id, ...data};

        if (_homeCardMatchesQuery(cardData, normalizedQuery)) {
          results.add(cardData);
        }
      }

      return results;
    } catch (e) {
      debugPrint('❌ [AdminSearch] Home cards search error: $e');
      return [];
    }
  }

  bool _homeCardMatchesQuery(Map<String, dynamic> card, String query) {
    final title = (card['title'] ?? '').toString().toLowerCase();
    if (title.contains(query)) return true;

    final cardType = (card['type'] ?? '').toString().toLowerCase();
    if (cardType.contains(query)) return true;

    return false;
  }

  // ============================================================
  // GENERIC LOCAL FILTERS (kept for backward compatibility)
  // ============================================================

  List<T> filterLocally<T>({
    required List<T> items,
    required String query,
    required bool Function(T item, String normalizedQuery) matcher,
  }) {
    if (query.trim().isEmpty) return items;
    final normalizedQuery = query.toLowerCase().trim();
    return items.where((item) => matcher(item, normalizedQuery)).toList();
  }

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
