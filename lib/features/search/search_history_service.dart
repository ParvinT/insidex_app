// lib/features/search/search_history_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SearchHistoryService {
  static const String _localStorageKey = 'search_history';
  static const int _maxHistoryItems = 20;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get current user ID
  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  /// Save search query to history
  Future<void> saveSearchQuery(String query) async {
    if (query.trim().isEmpty) return;

    try {
      final history = await getSearchHistory();

      // Remove if already exists (to move it to top)
      history.removeWhere((item) =>
          item['query'].toString().toLowerCase() == query.toLowerCase());

      // Add to beginning
      history.insert(0, {
        'query': query.trim(),
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Keep only max items
      if (history.length > _maxHistoryItems) {
        history.removeRange(_maxHistoryItems, history.length);
      }

      // Save to both local and Firebase
      await _saveToLocal(history);
      await _saveToFirebase(history);

      debugPrint('Search query saved: $query');
    } catch (e) {
      debugPrint('Error saving search query: $e');
    }
  }

  /// Get search history
  Future<List<Map<String, dynamic>>> getSearchHistory() async {
    try {
      // Try Firebase first if user is logged in
      if (_userId != null) {
        final firebaseHistory = await _getFromFirebase();
        if (firebaseHistory.isNotEmpty) {
          // Also cache locally
          await _saveToLocal(firebaseHistory);
          return firebaseHistory;
        }
      }

      // Fallback to local storage
      return await _getFromLocal();
    } catch (e) {
      debugPrint('Error getting search history: $e');
      return [];
    }
  }

  /// Clear all search history
  Future<void> clearHistory() async {
    try {
      // Clear local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_localStorageKey);

      // Clear Firebase if user is logged in
      if (_userId != null) {
        await _firestore
            .collection('users')
            .doc(_userId)
            .collection('settings')
            .doc('search_history')
            .delete();
      }

      debugPrint('Search history cleared');
    } catch (e) {
      debugPrint('Error clearing search history: $e');
    }
  }

  /// Remove specific search query from history
  Future<void> removeSearchQuery(String query) async {
    try {
      final history = await getSearchHistory();

      history.removeWhere((item) =>
          item['query'].toString().toLowerCase() == query.toLowerCase());

      await _saveToLocal(history);
      await _saveToFirebase(history);

      debugPrint('Search query removed: $query');
    } catch (e) {
      debugPrint('Error removing search query: $e');
    }
  }

  /// Save to local storage
  Future<void> _saveToLocal(List<Map<String, dynamic>> history) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(history);
      await prefs.setString(_localStorageKey, jsonString);
    } catch (e) {
      debugPrint('Error saving to local storage: $e');
    }
  }

  /// Get from local storage
  Future<List<Map<String, dynamic>>> _getFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_localStorageKey);

      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> decoded = json.decode(jsonString);
      return decoded.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      debugPrint('Error getting from local storage: $e');
      return [];
    }
  }

  /// Save to Firebase
  Future<void> _saveToFirebase(List<Map<String, dynamic>> history) async {
    if (_userId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('settings')
          .doc('search_history')
          .set({
        'queries': history,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('Search history synced to Firebase');
    } catch (e) {
      debugPrint('Error saving to Firebase: $e');
    }
  }

  /// Get from Firebase
  Future<List<Map<String, dynamic>>> _getFromFirebase() async {
    if (_userId == null) return [];

    try {
      final doc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('settings')
          .doc('search_history')
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final List<dynamic> queries = data['queries'] ?? [];
        return queries.map((item) => Map<String, dynamic>.from(item)).toList();
      }

      return [];
    } catch (e) {
      debugPrint('Error getting from Firebase: $e');
      return [];
    }
  }

  /// Sync local history to Firebase when user logs in
  Future<void> syncOnLogin() async {
    if (_userId == null) return;

    try {
      // Get local history
      final localHistory = await _getFromLocal();

      if (localHistory.isEmpty) return;

      // Get Firebase history
      final firebaseHistory = await _getFromFirebase();

      // Merge histories (local takes priority for newer items)
      final mergedHistory = <Map<String, dynamic>>[];
      final seenQueries = <String>{};

      // Add local history first
      for (var item in localHistory) {
        final query = item['query'].toString().toLowerCase();
        if (!seenQueries.contains(query)) {
          mergedHistory.add(item);
          seenQueries.add(query);
        }
      }

      // Add Firebase history items that are not in local
      for (var item in firebaseHistory) {
        final query = item['query'].toString().toLowerCase();
        if (!seenQueries.contains(query)) {
          mergedHistory.add(item);
          seenQueries.add(query);
        }
      }

      // Keep only max items
      if (mergedHistory.length > _maxHistoryItems) {
        mergedHistory.removeRange(_maxHistoryItems, mergedHistory.length);
      }

      // Save merged history
      await _saveToLocal(mergedHistory);
      await _saveToFirebase(mergedHistory);

      debugPrint(
          'Search history synced on login: ${mergedHistory.length} items');
    } catch (e) {
      debugPrint('Error syncing search history: $e');
    }
  }

  /// Get popular searches (most frequent)
  Future<List<String>> getPopularSearches({int limit = 5}) async {
    try {
      final history = await getSearchHistory();

      // Count query frequency
      final queryCount = <String, int>{};
      for (var item in history) {
        final query = item['query'].toString().toLowerCase();
        queryCount[query] = (queryCount[query] ?? 0) + 1;
      }

      // Sort by frequency
      final sorted = queryCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sorted.take(limit).map((e) => e.key).toList();
    } catch (e) {
      debugPrint('Error getting popular searches: $e');
      return [];
    }
  }

  /// Get recent searches (without duplicates)
  Future<List<String>> getRecentSearches({int limit = 10}) async {
    try {
      final history = await getSearchHistory();
      final seen = <String>{};
      final recent = <String>[];

      for (var item in history) {
        final query = item['query'].toString().toLowerCase();
        if (!seen.contains(query)) {
          recent.add(item['query'].toString());
          seen.add(query);

          if (recent.length >= limit) break;
        }
      }

      return recent;
    } catch (e) {
      debugPrint('Error getting recent searches: $e');
      return [];
    }
  }
}
