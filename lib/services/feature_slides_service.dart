// lib/services/feature_slides_service.dart

import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/feature_slide_model.dart';

/// Service for managing feature slides on home screen
/// Uses cache-first strategy like other services
class FeatureSlidesService {
  static final FeatureSlidesService _instance =
      FeatureSlidesService._internal();
  factory FeatureSlidesService() => _instance;
  FeatureSlidesService._internal();

  // Cache keys
  static const String _cacheKey = 'feature_slides_cache';
  static const String _cacheTimestampKey = 'feature_slides_timestamp';
  static const String _randomImagesKey = 'feature_slides_random_images';
  static const String _randomDateKey = 'feature_slides_random_date';

  // Cache duration: 24 hours
  static const int _cacheDurationHours = 24;

  // In-memory cache
  FeatureSlidesData? _dataCache;
  List<String>? _randomizedImages;

  // =================== PUBLIC API ===================

  /// Get feature slides data (cache-first)
  Future<FeatureSlidesData?> getData({bool forceRefresh = false}) async {
    // Return in-memory cache if available
    if (!forceRefresh && _dataCache != null) {
      debugPrint('📦 [FeatureSlides] Using in-memory cache');
      return _dataCache;
    }

    final prefs = await SharedPreferences.getInstance();

    // Check local cache validity
    if (!forceRefresh && _isCacheValid(prefs)) {
      final cachedData = prefs.getString(_cacheKey);
      if (cachedData != null && cachedData.isNotEmpty) {
        debugPrint('📦 [FeatureSlides] Using SharedPreferences cache');
        _dataCache = _parseData(cachedData);
        return _dataCache;
      }
    }

    // Fetch from Firebase
    try {
      final data = await _fetchFromFirebase();

      if (data != null) {
        await _saveToCache(prefs, data);
        _dataCache = data;
        debugPrint('☁️ [FeatureSlides] Fetched from Firebase');
        return data;
      }
    } catch (e) {
      debugPrint('⚠️ [FeatureSlides] Firebase fetch failed: $e');
    }

    // Fallback to expired cache
    final cachedData = prefs.getString(_cacheKey);
    if (cachedData != null && cachedData.isNotEmpty) {
      debugPrint('⚠️ [FeatureSlides] Using expired cache as fallback');
      _dataCache = _parseData(cachedData);
      return _dataCache;
    }

    debugPrint('❌ [FeatureSlides] No data available');
    return null;
  }

  /// Get randomized images for pages (consistent per session/day)
  Future<List<String>> getRandomizedImagesForPages({
    required int pageCount,
    bool forceNewRandom = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getTodayString();

    // Check if we already have randomized images for today
    if (!forceNewRandom) {
      final savedDate = prefs.getString(_randomDateKey);
      if (savedDate == today && _randomizedImages != null) {
        debugPrint('📦 [FeatureSlides] Using cached random images');
        return _randomizedImages!;
      }

      // Try to load from SharedPreferences
      final savedImages = prefs.getString(_randomImagesKey);
      if (savedDate == today && savedImages != null) {
        _randomizedImages = List<String>.from(jsonDecode(savedImages));
        debugPrint('📦 [FeatureSlides] Loaded random images from prefs');
        return _randomizedImages!;
      }
    }

    // Get data and generate new random selection
    final data = await getData();
    if (data == null || data.images.isEmpty) {
      debugPrint('⚠️ [FeatureSlides] No images available');
      return [];
    }

    // Shuffle and select images for each page
    final random = Random();
    final shuffled = List<String>.from(data.images)..shuffle(random);

    // If we have fewer images than pages, repeat
    _randomizedImages = [];
    for (int i = 0; i < pageCount; i++) {
      _randomizedImages!.add(shuffled[i % shuffled.length]);
    }

    // Save for today
    await prefs.setString(_randomDateKey, today);
    await prefs.setString(_randomImagesKey, jsonEncode(_randomizedImages));

    debugPrint(
        '✨ [FeatureSlides] Generated ${_randomizedImages!.length} random images');
    return _randomizedImages!;
  }

  /// Force refresh data from Firebase
  Future<void> refresh() async {
    await getData(forceRefresh: true);
  }

  /// Clear all cache
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    await prefs.remove(_cacheTimestampKey);
    await prefs.remove(_randomImagesKey);
    await prefs.remove(_randomDateKey);
    _dataCache = null;
    _randomizedImages = null;
    debugPrint('🧹 [FeatureSlides] Cache cleared');
  }

  // =================== CACHE MANAGEMENT ===================

  bool _isCacheValid(SharedPreferences prefs) {
    final timestamp = prefs.getInt(_cacheTimestampKey);
    if (timestamp == null) return false;

    final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;
    const maxAge = _cacheDurationHours * 60 * 60 * 1000;

    return cacheAge < maxAge;
  }

  Future<void> _saveToCache(
      SharedPreferences prefs, FeatureSlidesData data) async {
    try {
      await prefs.setString(_cacheKey, jsonEncode(data.toMap()));
      await prefs.setInt(
          _cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
      debugPrint('💾 [FeatureSlides] Saved to cache');
    } catch (e) {
      debugPrint('❌ [FeatureSlides] Error saving to cache: $e');
    }
  }

  FeatureSlidesData? _parseData(String jsonString) {
    try {
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      return FeatureSlidesData.fromMap(decoded);
    } catch (e) {
      debugPrint('❌ [FeatureSlides] Error parsing data: $e');
      return null;
    }
  }

  // =================== FIREBASE ===================

  Future<FeatureSlidesData?> _fetchFromFirebase() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('app_config')
          .doc('feature_slides')
          .get();

      if (!doc.exists || doc.data() == null) {
        debugPrint('⚠️ [FeatureSlides] No document in Firebase');
        return null;
      }

      return FeatureSlidesData.fromMap(doc.data()!);
    } catch (e) {
      debugPrint('❌ [FeatureSlides] Firebase fetch error: $e');
      return null;
    }
  }

  // =================== HELPERS ===================

  String _getTodayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
