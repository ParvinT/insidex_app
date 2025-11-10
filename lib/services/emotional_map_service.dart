// lib/services/emotional_map_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/emotional_map_model.dart';

class EmotionalMapService {
  static final EmotionalMapService _instance =
      EmotionalMapService._internal();
  factory EmotionalMapService() => _instance;
  EmotionalMapService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'emotional_maps';

  // Cache
  Map<String, EmotionalMapModel>? _cachedMaps; // symptomId -> EmotionalMap
  DateTime? _lastFetchTime;
  static const _cacheDuration = Duration(hours: 1);

  /// Get all emotional maps (with cache)
  Future<List<EmotionalMapModel>> getAllEmotionalMaps({
    bool forceRefresh = false,
  }) async {
    try {
      // Return cached if valid
      if (!forceRefresh &&
          _cachedMaps != null &&
          _lastFetchTime != null &&
          DateTime.now().difference(_lastFetchTime!) < _cacheDuration) {
        debugPrint(
            '✅ [EmotionalMapService] Returning cached maps (${_cachedMaps!.length})');
        return _cachedMaps!.values.toList();
      }

      debugPrint('🔄 [EmotionalMapService] Fetching emotional maps from Firestore...');

      final snapshot = await _firestore.collection(_collectionName).get();

      final maps = <String, EmotionalMapModel>{};
      for (var doc in snapshot.docs) {
        final map = EmotionalMapModel.fromMap(doc.data(), doc.id);
        maps[map.symptomId] = map;
      }

      // Update cache
      _cachedMaps = maps;
      _lastFetchTime = DateTime.now();

      debugPrint('✅ [EmotionalMapService] Fetched ${maps.length} emotional maps');
      return maps.values.toList();
    } catch (e) {
      debugPrint('❌ [EmotionalMapService] Error fetching emotional maps: $e');
      return _cachedMaps?.values.toList() ?? [];
    }
  }

  /// Get emotional map by symptom ID
  Future<EmotionalMapModel?> getEmotionalMapBySymptomId(
    String symptomId,
  ) async {
    try {
      // Check cache first
      if (_cachedMaps != null && _cachedMaps!.containsKey(symptomId)) {
        debugPrint('✅ [EmotionalMapService] Returning cached map for: $symptomId');
        return _cachedMaps![symptomId];
      }

      debugPrint('🔄 [EmotionalMapService] Fetching map for symptom: $symptomId');

      final snapshot = await _firestore
          .collection(_collectionName)
          .where('symptomId', isEqualTo: symptomId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        debugPrint('⚠️ [EmotionalMapService] No emotional map found for: $symptomId');
        return null;
      }

      final doc = snapshot.docs.first;
      final map = EmotionalMapModel.fromMap(doc.data(), doc.id);

      // Update cache
      _cachedMaps ??= {};
      _cachedMaps![symptomId] = map;

      return map;
    } catch (e) {
      debugPrint('❌ [EmotionalMapService] Error fetching emotional map: $e');
      return null;
    }
  }

  /// Get emotional maps for multiple symptoms
  Future<Map<String, EmotionalMapModel>> getEmotionalMapsForSymptoms(
    List<String> symptomIds,
  ) async {
    try {
      debugPrint('🔄 [EmotionalMapService] Fetching maps for ${symptomIds.length} symptoms');

      final result = <String, EmotionalMapModel>{};

      for (final symptomId in symptomIds) {
        final map = await getEmotionalMapBySymptomId(symptomId);
        if (map != null) {
          result[symptomId] = map;
        }
      }

      debugPrint('✅ [EmotionalMapService] Found ${result.length} emotional maps');
      return result;
    } catch (e) {
      debugPrint('❌ [EmotionalMapService] Error fetching emotional maps: $e');
      return {};
    }
  }

  /// Get recommended session ID for a symptom
  Future<String?> getRecommendedSessionId(String symptomId) async {
    try {
      final map = await getEmotionalMapBySymptomId(symptomId);
      return map?.recommendedSessionId;
    } catch (e) {
      debugPrint('❌ [EmotionalMapService] Error getting recommended session: $e');
      return null;
    }
  }

  /// Get all recommended sessions for selected symptoms
  /// Returns Map: symptomId -> sessionId
  Future<Map<String, String>> getRecommendedSessions(
    List<String> symptomIds,
  ) async {
    try {
      final maps = await getEmotionalMapsForSymptoms(symptomIds);
      final recommendations = <String, String>{};

      maps.forEach((symptomId, map) {
        recommendations[symptomId] = map.recommendedSessionId;
      });

      return recommendations;
    } catch (e) {
      debugPrint('❌ [EmotionalMapService] Error getting recommendations: $e');
      return {};
    }
  }

  /// Clear cache
  void clearCache() {
    _cachedMaps = null;
    _lastFetchTime = null;
    debugPrint('🗑️ [EmotionalMapService] Cache cleared');
  }

  // =================== ADMIN OPERATIONS ===================

  /// Add new emotional map (Admin only)
  Future<String?> addEmotionalMap(EmotionalMapModel map) async {
    try {
      final docRef = await _firestore.collection(_collectionName).add(
            map.toMap(),
          );

      debugPrint('✅ [EmotionalMapService] Emotional map added: ${docRef.id}');
      clearCache();
      return docRef.id;
    } catch (e) {
      debugPrint('❌ [EmotionalMapService] Error adding emotional map: $e');
      return null;
    }
  }

  /// Update emotional map (Admin only)
  Future<bool> updateEmotionalMap(String mapId, EmotionalMapModel map) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(mapId)
          .update(map.toMap());

      debugPrint('✅ [EmotionalMapService] Emotional map updated: $mapId');
      clearCache();
      return true;
    } catch (e) {
      debugPrint('❌ [EmotionalMapService] Error updating emotional map: $e');
      return false;
    }
  }

  /// Delete emotional map (Admin only)
  Future<bool> deleteEmotionalMap(String mapId) async {
    try {
      await _firestore.collection(_collectionName).doc(mapId).delete();

      debugPrint('✅ [EmotionalMapService] Emotional map deleted: $mapId');
      clearCache();
      return true;
    } catch (e) {
      debugPrint('❌ [EmotionalMapService] Error deleting emotional map: $e');
      return false;
    }
  }
}