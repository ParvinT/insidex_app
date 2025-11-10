// lib/services/symptom_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/symptom_model.dart';

class SymptomService {
  static final SymptomService _instance = SymptomService._internal();
  factory SymptomService() => _instance;
  SymptomService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'symptoms_catalog';

  // Cache
  List<SymptomModel>? _cachedSymptoms;
  DateTime? _lastFetchTime;
  static const _cacheDuration = Duration(hours: 1);

  /// Get all symptoms (with cache)
  Future<List<SymptomModel>> getAllSymptoms({bool forceRefresh = false}) async {
    try {
      // Return cached if valid
      if (!forceRefresh &&
          _cachedSymptoms != null &&
          _lastFetchTime != null &&
          DateTime.now().difference(_lastFetchTime!) < _cacheDuration) {
        debugPrint(
            '✅ [SymptomService] Returning cached symptoms (${_cachedSymptoms!.length})');
        return _cachedSymptoms!;
      }

      debugPrint('🔄 [SymptomService] Fetching symptoms from Firestore...');

      final snapshot =
          await _firestore.collection(_collectionName).orderBy('order').get();

      final symptoms = snapshot.docs
          .map((doc) => SymptomModel.fromMap(doc.data(), doc.id))
          .toList();

      // Update cache
      _cachedSymptoms = symptoms;
      _lastFetchTime = DateTime.now();

      debugPrint('✅ [SymptomService] Fetched ${symptoms.length} symptoms');
      return symptoms;
    } catch (e) {
      debugPrint('❌ [SymptomService] Error fetching symptoms: $e');
      return _cachedSymptoms ?? [];
    }
  }

  /// Get symptoms by category
  Future<List<SymptomModel>> getSymptomsByCategory(String category) async {
    try {
      final allSymptoms = await getAllSymptoms();
      return allSymptoms.where((s) => s.category == category).toList();
    } catch (e) {
      debugPrint('❌ [SymptomService] Error filtering by category: $e');
      return [];
    }
  }

  /// Get symptom by ID
  Future<SymptomModel?> getSymptomById(String symptomId) async {
    try {
      final doc =
          await _firestore.collection(_collectionName).doc(symptomId).get();

      if (!doc.exists) {
        debugPrint('⚠️ [SymptomService] Symptom not found: $symptomId');
        return null;
      }

      return SymptomModel.fromMap(doc.data()!, doc.id);
    } catch (e) {
      debugPrint('❌ [SymptomService] Error fetching symptom: $e');
      return null;
    }
  }

  /// Search symptoms by name (localized)
  Future<List<SymptomModel>> searchSymptoms(
    String query,
    String locale,
  ) async {
    try {
      if (query.isEmpty) return await getAllSymptoms();

      final allSymptoms = await getAllSymptoms();
      final lowerQuery = query.toLowerCase();

      return allSymptoms.where((symptom) {
        final localizedName = symptom.getLocalizedName(locale).toLowerCase();
        return localizedName.contains(lowerQuery);
      }).toList();
    } catch (e) {
      debugPrint('❌ [SymptomService] Error searching symptoms: $e');
      return [];
    }
  }

  /// Get symptoms by multiple IDs
  Future<List<SymptomModel>> getSymptomsByIds(List<String> symptomIds) async {
    try {
      final allSymptoms = await getAllSymptoms();
      return allSymptoms.where((s) => symptomIds.contains(s.id)).toList();
    } catch (e) {
      debugPrint('❌ [SymptomService] Error fetching symptoms by IDs: $e');
      return [];
    }
  }

  /// Clear cache
  void clearCache() {
    _cachedSymptoms = null;
    _lastFetchTime = null;
    debugPrint('🗑️ [SymptomService] Cache cleared');
  }

  // =================== ADMIN OPERATIONS ===================

  /// Add new symptom (Admin only)
  Future<String?> addSymptom(SymptomModel symptom) async {
    try {
      final docRef = await _firestore.collection(_collectionName).add(
            symptom.toMap(),
          );

      debugPrint('✅ [SymptomService] Symptom added: ${docRef.id}');
      clearCache();
      return docRef.id;
    } catch (e) {
      debugPrint('❌ [SymptomService] Error adding symptom: $e');
      return null;
    }
  }

  /// Update symptom (Admin only)
  Future<bool> updateSymptom(String symptomId, SymptomModel symptom) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(symptomId)
          .update(symptom.toMap());

      debugPrint('✅ [SymptomService] Symptom updated: $symptomId');
      clearCache();
      return true;
    } catch (e) {
      debugPrint('❌ [SymptomService] Error updating symptom: $e');
      return false;
    }
  }

  /// Delete symptom (Admin only)
  Future<bool> deleteSymptom(String symptomId) async {
    try {
      await _firestore.collection(_collectionName).doc(symptomId).delete();

      debugPrint('✅ [SymptomService] Symptom deleted: $symptomId');
      clearCache();
      return true;
    } catch (e) {
      debugPrint('❌ [SymptomService] Error deleting symptom: $e');
      return false;
    }
  }
}
