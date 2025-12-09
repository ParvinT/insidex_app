// lib/services/category/category_service.dart

import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/category_model.dart';
import '../language_helper_service.dart';
import '../cache_manager_service.dart';

/// Service for managing categories with multi-language support
class CategoryService {
  static final CategoryService _instance = CategoryService._internal();
  factory CategoryService() => _instance;
  CategoryService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final Random _random = Random();

  // Cache
  List<CategoryModel>? _cachedCategories;
  DateTime? _cacheTime;
  static const _cacheDuration = Duration(minutes: 5);

  /// Get all categories
  Future<List<CategoryModel>> getAllCategories({
    bool forceRefresh = false,
  }) async {
    // Return cached if available and not expired
    if (!forceRefresh &&
        _cachedCategories != null &&
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < _cacheDuration) {
      return _cachedCategories!;
    }

    try {
      final snapshot = await _firestore.collection('categories').get();

      final categories = snapshot.docs.map((doc) {
        return CategoryModel.fromMap(doc.id, doc.data());
      }).toList();

      // Update cache
      _cachedCategories = categories;
      _cacheTime = DateTime.now();

      debugPrint('✅ Loaded ${categories.length} categories');
      return categories;
    } catch (e) {
      debugPrint('❌ Error loading categories: $e');
      return _cachedCategories ?? [];
    }
  }

  /// Get categories filtered by user's current language
  /// Only returns categories that have name in user's language
  Future<List<CategoryModel>> getCategoriesByLanguage([String? locale]) async {
    final categories = await getAllCategories();

    locale ??= await LanguageHelperService.getCurrentLanguage();

    final filtered = categories.where((cat) {
      return cat.hasLanguage(locale!);
    }).toList();

    debugPrint(
        '🌍 Filtered categories by language ($locale): ${filtered.length}/${categories.length}');
    return filtered;
  }

  /// Get single category by ID
  Future<CategoryModel?> getCategoryById(String id) async {
    try {
      final doc = await _firestore.collection('categories').doc(id).get();

      if (!doc.exists) {
        debugPrint('⚠️ Category not found: $id');
        return null;
      }

      return CategoryModel.fromMap(doc.id, doc.data()!);
    } catch (e) {
      debugPrint('❌ Error getting category: $e');
      return null;
    }
  }

  /// Add new category
  Future<String?> addCategory(CategoryModel category) async {
    try {
      // Validate: must have at least one name
      if (category.names.isEmpty) {
        debugPrint('❌ Cannot add category without any names');
        return null;
      }

      final docRef = await _firestore.collection('categories').add({
        ...category.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Category added: ${docRef.id}');

      // Clear cache
      _clearCache();

      return docRef.id;
    } catch (e) {
      debugPrint('❌ Error adding category: $e');
      return null;
    }
  }

  /// Update existing category
  Future<bool> updateCategory(String id, CategoryModel category) async {
    try {
      // Validate: must have at least one name
      if (category.names.isEmpty) {
        debugPrint('❌ Cannot update category without any names');
        return false;
      }

      await _firestore.collection('categories').doc(id).update({
        ...category.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Category updated: $id');

      // Clear cache
      _clearCache();

      return true;
    } catch (e) {
      debugPrint('❌ Error updating category: $e');
      return false;
    }
  }

  /// Delete category
  Future<bool> deleteCategory(String id) async {
    try {
      await _firestore.collection('categories').doc(id).delete();

      debugPrint('✅ Category deleted: $id');

      // Clear cache
      _clearCache();

      return true;
    } catch (e) {
      debugPrint('❌ Error deleting category: $e');
      return false;
    }
  }

  /// Check if category name exists (for any language)
  Future<bool> categoryNameExists(String name, {String? excludeId}) async {
    try {
      final categories = await getAllCategories(forceRefresh: true);

      for (final category in categories) {
        // Skip if this is the category being edited
        if (excludeId != null && category.id == excludeId) continue;

        // Check if name exists in any language
        if (category.names.values
            .any((n) => n.toLowerCase() == name.toLowerCase())) {
          return true;
        }
      }

      return false;
    } catch (e) {
      debugPrint('❌ Error checking category name: $e');
      return false;
    }
  }

  /// Update session count for a category
  Future<void> updateSessionCount(String categoryId, int count) async {
    try {
      await _firestore.collection('categories').doc(categoryId).update({
        'sessionCount': count,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Updated session count for category $categoryId: $count');

      // Clear cache
      _clearCache();
    } catch (e) {
      debugPrint('❌ Error updating session count: $e');
    }
  }

  /// Clear cache
  void _clearCache() {
    _cachedCategories = null;
    _cacheTime = null;
  }

  /// Force refresh cache
  Future<void> refreshCache() async {
    await getAllCategories(forceRefresh: true);
  }

  /// Get random background image for a category
  /// Returns null if category has no images
  String? getRandomBackgroundImage(CategoryModel category) {
    if (category.backgroundImages.isEmpty) {
      debugPrint('⚠️ No background images for category: ${category.id}');
      return null;
    }

    final index = _random.nextInt(category.backgroundImages.length);
    final selectedImage = category.backgroundImages[index];

    debugPrint(
        '🎲 Random image for ${category.id}: Image ${index + 1}/${category.backgroundImages.length}');
    return selectedImage;
  }

  /// Prefetch all background images for a category
  Future<void> prefetchCategoryImages(CategoryModel category) async {
    if (category.backgroundImages.isEmpty) return;

    try {
      debugPrint(
          '📥 Prefetching ${category.backgroundImages.length} images for ${category.id}...');

      for (final imageUrl in category.backgroundImages) {
        await AppCacheManager.precacheImage(imageUrl);
      }

      debugPrint('✅ Prefetched all images for ${category.id}');
    } catch (e) {
      debugPrint('❌ Error prefetching images for ${category.id}: $e');
    }
  }

  /// Prefetch images for all categories (background task)
  Future<void> prefetchAllCategoryImages() async {
    try {
      debugPrint('🚀 Starting background prefetch for all category images...');

      final categories = await getAllCategories();

      int totalImages = 0;
      for (final category in categories) {
        totalImages += category.backgroundImages.length;
        await prefetchCategoryImages(category);
      }

      debugPrint(
          '✅ Prefetched $totalImages images for ${categories.length} categories');
    } catch (e) {
      debugPrint('❌ Error in prefetchAllCategoryImages: $e');
    }
  }

  /// Smart prefetch - Called after app launch
  /// Waits 2 seconds then prefetches in background
  Future<void> smartPrefetchCategoryImages() async {
    Future.delayed(const Duration(seconds: 2), () async {
      await prefetchAllCategoryImages();
    });
  }
}
