// lib/features/quiz/services/quiz_category_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../models/quiz_category_model.dart';

/// Service for managing quiz categories
/// Handles CRUD operations and caching
class QuizCategoryService {
  static final QuizCategoryService _instance = QuizCategoryService._internal();
  factory QuizCategoryService() => _instance;
  QuizCategoryService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'quiz_categories';

  // Cache
  List<QuizCategoryModel>? _cachedCategories;
  DateTime? _lastFetchTime;
  static const _cacheDuration = Duration(hours: 1);

  // =================== READ OPERATIONS ===================

  /// Get all categories
  Future<List<QuizCategoryModel>> getAllCategories({
    bool forceRefresh = false,
  }) async {
    try {
      // Return cached if valid
      if (!forceRefresh &&
          _cachedCategories != null &&
          _lastFetchTime != null &&
          DateTime.now().difference(_lastFetchTime!) < _cacheDuration) {
        debugPrint(
            '✅ [QuizCategoryService] Returning cached categories (${_cachedCategories!.length})');
        return _cachedCategories!;
      }

      debugPrint(
          '🔄 [QuizCategoryService] Fetching categories from Firestore...');

      final snapshot = await _firestore.collection(_collectionName).get();

      final categories = snapshot.docs
          .map((doc) => QuizCategoryModel.fromMap(doc.id, doc.data()))
          .toList();

      // Update cache
      _cachedCategories = categories;
      _lastFetchTime = DateTime.now();

      debugPrint(
          '✅ [QuizCategoryService] Fetched ${categories.length} categories');
      return categories;
    } catch (e) {
      debugPrint('❌ [QuizCategoryService] Error fetching categories: $e');
      return _cachedCategories ?? [];
    }
  }

  /// Get categories filtered by gender (includes 'both')
  /// Returns categories sorted alphabetically by locale
  Future<List<QuizCategoryModel>> getCategoriesByGender(
    String gender,
    String locale, {
    bool forceRefresh = false,
  }) async {
    try {
      final allCategories = await getAllCategories(forceRefresh: forceRefresh);

      // Filter: show categories that match gender OR are 'both'
      final filtered = allCategories
          .where((c) => c.gender == gender || c.gender == 'both')
          .toList();

      // Sort alphabetically by locale
      filtered.sort((a, b) {
        final nameA = a.getName(locale).toLowerCase();
        final nameB = b.getName(locale).toLowerCase();
        return nameA.compareTo(nameB);
      });

      debugPrint(
          '✅ [QuizCategoryService] Filtered ${filtered.length} categories for gender: $gender');
      return filtered;
    } catch (e) {
      debugPrint(
          '❌ [QuizCategoryService] Error filtering categories by gender: $e');
      return [];
    }
  }

  /// Get category by ID
  Future<QuizCategoryModel?> getCategoryById(String categoryId) async {
    try {
      // First check cache
      if (_cachedCategories != null) {
        final cached =
            _cachedCategories!.where((c) => c.id == categoryId).firstOrNull;
        if (cached != null) {
          debugPrint(
              '✅ [QuizCategoryService] Found category in cache: $categoryId');
          return cached;
        }
      }

      // Fetch from Firestore
      final doc =
          await _firestore.collection(_collectionName).doc(categoryId).get();

      if (!doc.exists) {
        debugPrint('⚠️ [QuizCategoryService] Category not found: $categoryId');
        return null;
      }

      return QuizCategoryModel.fromMap(doc.id, doc.data()!);
    } catch (e) {
      debugPrint('❌ [QuizCategoryService] Error fetching category: $e');
      return null;
    }
  }

  // =================== WRITE OPERATIONS ===================

  /// Add new category
  Future<String?> addCategory(QuizCategoryModel category) async {
    try {
      final data = category.toMap();
      data['createdAt'] = FieldValue.serverTimestamp();
      data['updatedAt'] = FieldValue.serverTimestamp();

      final docRef = await _firestore.collection(_collectionName).add(data);

      debugPrint('✅ [QuizCategoryService] Added category: ${docRef.id}');

      // Invalidate cache
      clearCache();

      return docRef.id;
    } catch (e) {
      debugPrint('❌ [QuizCategoryService] Error adding category: $e');
      return null;
    }
  }

  /// Update existing category
  Future<bool> updateCategory(
      String categoryId, QuizCategoryModel category) async {
    try {
      final data = category.toMap();
      data['updatedAt'] = FieldValue.serverTimestamp();
      // Don't overwrite createdAt
      data.remove('createdAt');

      await _firestore.collection(_collectionName).doc(categoryId).update(data);

      debugPrint('✅ [QuizCategoryService] Updated category: $categoryId');

      // Invalidate cache
      clearCache();

      return true;
    } catch (e) {
      debugPrint('❌ [QuizCategoryService] Error updating category: $e');
      return false;
    }
  }

  /// Delete category
  Future<bool> deleteCategory(String categoryId) async {
    try {
      await _firestore.collection(_collectionName).doc(categoryId).delete();

      debugPrint('✅ [QuizCategoryService] Deleted category: $categoryId');

      // Invalidate cache
      clearCache();

      return true;
    } catch (e) {
      debugPrint('❌ [QuizCategoryService] Error deleting category: $e');
      return false;
    }
  }

  // =================== UTILITY ===================

  /// Clear cache
  void clearCache() {
    _cachedCategories = null;
    _lastFetchTime = null;
    debugPrint('🗑️ [QuizCategoryService] Cache cleared');
  }

  /// Get disease count per category
  Future<Map<String, int>> getCategoryDiseaseCounts(String gender) async {
    try {
      final snapshot = await _firestore
          .collection('diseases_catalog')
          .where('gender', isEqualTo: gender)
          .get();

      final counts = <String, int>{};

      for (final doc in snapshot.docs) {
        final categoryId = doc.data()['categoryId'] as String?;
        if (categoryId != null) {
          counts[categoryId] = (counts[categoryId] ?? 0) + 1;
        }
      }

      debugPrint(
          '📊 [QuizCategoryService] Disease counts for $gender: $counts');
      return counts;
    } catch (e) {
      debugPrint('❌ [QuizCategoryService] Error getting disease counts: $e');
      return {};
    }
  }
}
