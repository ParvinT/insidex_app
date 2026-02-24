// lib/services/disease_cause_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/disease_cause_model.dart';

class DiseaseCauseService {
  static final DiseaseCauseService _instance = DiseaseCauseService._internal();
  factory DiseaseCauseService() => _instance;
  DiseaseCauseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'disease_causes';

  // Cache
  Map<String, DiseaseCauseModel>? _cachedCauses; // diseaseId -> DiseaseCause
  DateTime? _lastFetchTime;
  static const _cacheDuration = Duration(hours: 1);

  /// Get all disease causes (with cache)
  Future<List<DiseaseCauseModel>> getAllDiseaseCauses({
    bool forceRefresh = false,
  }) async {
    try {
      // Return cached if valid
      if (!forceRefresh &&
          _cachedCauses != null &&
          _lastFetchTime != null &&
          DateTime.now().difference(_lastFetchTime!) < _cacheDuration) {
        debugPrint(
            '✅ [DiseaseCauseService] Returning cached causes (${_cachedCauses!.length})');
        return _cachedCauses!.values.toList();
      }

      debugPrint(
          '🔄 [DiseaseCauseService] Fetching disease causes from Firestore...');

      final snapshot = await _firestore.collection(_collectionName).get();

      final causes = <String, DiseaseCauseModel>{};
      for (var doc in snapshot.docs) {
        final cause = DiseaseCauseModel.fromMap(doc.data(), doc.id);
        causes[cause.diseaseId] = cause;
      }

      // Update cache
      _cachedCauses = causes;
      _lastFetchTime = DateTime.now();

      debugPrint(
          '✅ [DiseaseCauseService] Fetched ${causes.length} disease causes');
      return causes.values.toList();
    } catch (e) {
      debugPrint('❌ [DiseaseCauseService] Error fetching disease causes: $e');
      return _cachedCauses?.values.toList() ?? [];
    }
  }

  /// Get disease cause by disease ID
  Future<DiseaseCauseModel?> getDiseaseCauseByDiseaseId(
    String diseaseId,
  ) async {
    try {
      // Check cache first
      if (_cachedCauses != null && _cachedCauses!.containsKey(diseaseId)) {
        debugPrint(
            '✅ [DiseaseCauseService] Returning cached cause for: $diseaseId');
        return _cachedCauses![diseaseId];
      }

      debugPrint(
          '🔄 [DiseaseCauseService] Fetching cause for disease: $diseaseId');

      final snapshot = await _firestore
          .collection(_collectionName)
          .where('diseaseId', isEqualTo: diseaseId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        debugPrint(
            '⚠️ [DiseaseCauseService] No disease cause found for: $diseaseId');
        return null;
      }

      final doc = snapshot.docs.first;
      final cause = DiseaseCauseModel.fromMap(doc.data(), doc.id);

      // Update cache
      _cachedCauses ??= {};
      _cachedCauses![diseaseId] = cause;

      return cause;
    } catch (e) {
      debugPrint('❌ [DiseaseCauseService] Error fetching disease cause: $e');
      return null;
    }
  }

  /// Get disease causes for multiple diseases
  Future<Map<String, DiseaseCauseModel>> getDiseaseCausesForDiseases(
    List<String> diseaseIds,
  ) async {
    try {
      debugPrint(
          '🔄 [DiseaseCauseService] Fetching causes for ${diseaseIds.length} diseases');

      final result = <String, DiseaseCauseModel>{};

      for (final diseaseId in diseaseIds) {
        final cause = await getDiseaseCauseByDiseaseId(diseaseId);
        if (cause != null) {
          result[diseaseId] = cause;
        }
      }

      debugPrint(
          '✅ [DiseaseCauseService] Found ${result.length} disease causes');
      return result;
    } catch (e) {
      debugPrint('❌ [DiseaseCauseService] Error fetching disease causes: $e');
      return {};
    }
  }

  /// Get recommended session ID for a disease
  Future<String?> getRecommendedSessionId(String diseaseId) async {
    try {
      final cause = await getDiseaseCauseByDiseaseId(diseaseId);
      return cause?.recommendedSessionId;
    } catch (e) {
      debugPrint(
          '❌ [DiseaseCauseService] Error getting recommended session: $e');
      return null;
    }
  }

  /// Get all recommended sessions for selected diseases
  /// Returns Map: diseaseId -> sessionId
  Future<Map<String, String>> getRecommendedSessions(
    List<String> diseaseIds,
  ) async {
    try {
      final causes = await getDiseaseCausesForDiseases(diseaseIds);
      final recommendations = <String, String>{};

      causes.forEach((diseaseId, cause) {
        if (cause.recommendedSessionId != null) {
          recommendations[diseaseId] = cause.recommendedSessionId!;
        }
      });

      return recommendations;
    } catch (e) {
      debugPrint('❌ [DiseaseCauseService] Error getting recommendations: $e');
      return {};
    }
  }

  /// Clear cache
  void clearCache() {
    _cachedCauses = null;
    _lastFetchTime = null;
    debugPrint('🗑️ [DiseaseCauseService] Cache cleared');
  }

  // =================== ADMIN OPERATIONS ===================

  /// Add new disease cause (Admin only)
  Future<String?> addDiseaseCause(DiseaseCauseModel cause) async {
    try {
      final docRef = await _firestore.collection(_collectionName).add(
            cause.toMap(),
          );

      debugPrint('✅ [DiseaseCauseService] Disease cause added: ${docRef.id}');
      clearCache();
      return docRef.id;
    } catch (e) {
      debugPrint('❌ [DiseaseCauseService] Error adding disease cause: $e');
      return null;
    }
  }

  /// Update disease cause (Admin only)
  Future<bool> updateDiseaseCause(
      String causeId, DiseaseCauseModel cause) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(causeId)
          .update(cause.toMap());

      debugPrint('✅ [DiseaseCauseService] Disease cause updated: $causeId');
      clearCache();
      return true;
    } catch (e) {
      debugPrint('❌ [DiseaseCauseService] Error updating disease cause: $e');
      return false;
    }
  }

  /// Delete disease cause (Admin only)
  Future<bool> deleteDiseaseCause(String causeId) async {
    try {
      await _firestore.collection(_collectionName).doc(causeId).delete();

      debugPrint('✅ [DiseaseCauseService] Disease cause deleted: $causeId');
      clearCache();
      return true;
    } catch (e) {
      debugPrint('❌ [DiseaseCauseService] Error deleting disease cause: $e');
      return false;
    }
  }
}
