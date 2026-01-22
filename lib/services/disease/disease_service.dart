// lib/services/disease_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/disease_model.dart';

class DiseaseService {
  static final DiseaseService _instance = DiseaseService._internal();
  factory DiseaseService() => _instance;
  DiseaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'diseases_catalog';

  // Cache
  List<DiseaseModel>? _cachedDiseases;
  DateTime? _lastFetchTime;
  static const _cacheDuration = Duration(hours: 1);

  /// Get all diseases (with cache)
  Future<List<DiseaseModel>> getAllDiseases({bool forceRefresh = false}) async {
    try {
      // Return cached if valid
      if (!forceRefresh &&
          _cachedDiseases != null &&
          _lastFetchTime != null &&
          DateTime.now().difference(_lastFetchTime!) < _cacheDuration) {
        debugPrint(
            '✅ [DiseaseService] Returning cached diseases (${_cachedDiseases!.length})');
        return _cachedDiseases!;
      }

      debugPrint('🔄 [DiseaseService] Fetching diseases from Firestore...');

      final snapshot = await _firestore.collection(_collectionName).get();

      final diseases = snapshot.docs
          .map((doc) => DiseaseModel.fromMap(doc.data(), doc.id))
          .toList();

      // Update cache
      _cachedDiseases = diseases;
      _lastFetchTime = DateTime.now();

      debugPrint('✅ [DiseaseService] Fetched ${diseases.length} diseases');
      return diseases;
    } catch (e) {
      debugPrint('❌ [DiseaseService] Error fetching diseases: $e');
      return _cachedDiseases ?? [];
    }
  }

  /// Get diseases by gender
  Future<List<DiseaseModel>> getDiseasesByGender(String gender) async {
    try {
      final allDiseases = await getAllDiseases();
      return allDiseases.where((s) => s.gender == gender).toList();
    } catch (e) {
      debugPrint('❌ [DiseaseService] Error filtering by gender: $e');
      return [];
    }
  }

  /// Get disease by ID
  Future<DiseaseModel?> getDiseaseById(String diseaseId) async {
    try {
      final doc =
          await _firestore.collection(_collectionName).doc(diseaseId).get();

      if (!doc.exists) {
        debugPrint('⚠️ [DiseaseService] Disease not found: $diseaseId');
        return null;
      }

      return DiseaseModel.fromMap(doc.data()!, doc.id);
    } catch (e) {
      debugPrint('❌ [DiseaseService] Error fetching disease: $e');
      return null;
    }
  }

  /// Get diseases by category and gender
  Future<List<DiseaseModel>> getDiseasesByCategoryAndGender(
    String? categoryId,
    String gender,
  ) async {
    try {
      final allDiseases = await getAllDiseases();

      return allDiseases.where((disease) {
        // Filter by gender
        if (disease.gender != gender) return false;

        // Filter by category (if specified)
        if (categoryId != null && disease.categoryId != categoryId) {
          return false;
        }

        return true;
      }).toList();
    } catch (e) {
      debugPrint(
          '❌ [DiseaseService] Error filtering by category and gender: $e');
      return [];
    }
  }

  /// Get diseases by category
  Future<List<DiseaseModel>> getDiseasesByCategory(String categoryId) async {
    try {
      final allDiseases = await getAllDiseases();
      return allDiseases.where((d) => d.categoryId == categoryId).toList();
    } catch (e) {
      debugPrint('❌ [DiseaseService] Error filtering by category: $e');
      return [];
    }
  }

  /// Search diseases by name (localized)
  Future<List<DiseaseModel>> searchDiseases(
    String query,
    String locale,
  ) async {
    try {
      if (query.isEmpty) return await getAllDiseases();

      final allDiseases = await getAllDiseases();
      final lowerQuery = query.toLowerCase();

      return allDiseases.where((disease) {
        final localizedName = disease.getLocalizedName(locale).toLowerCase();
        return localizedName.contains(lowerQuery);
      }).toList();
    } catch (e) {
      debugPrint('❌ [DiseaseService] Error searching diseases: $e');
      return [];
    }
  }

  /// Get diseases by multiple IDs
  Future<List<DiseaseModel>> getDiseasesByIds(List<String> diseaseIds) async {
    try {
      final allDiseases = await getAllDiseases();
      return allDiseases.where((s) => diseaseIds.contains(s.id)).toList();
    } catch (e) {
      debugPrint('❌ [DiseaseService] Error fetching diseases by IDs: $e');
      return [];
    }
  }

  /// Clear cache
  void clearCache() {
    _cachedDiseases = null;
    _lastFetchTime = null;
    debugPrint('🗑️ [DiseaseService] Cache cleared');
  }

  // =================== ADMIN OPERATIONS ===================

  /// Add new disease (Admin only)
  Future<String?> addDisease(DiseaseModel disease) async {
    try {
      final docRef = await _firestore.collection(_collectionName).add(
            disease.toMap(),
          );

      debugPrint('✅ [DiseaseService] Disease added: ${docRef.id}');
      clearCache();
      return docRef.id;
    } catch (e) {
      debugPrint('❌ [DiseaseService] Error adding disease: $e');
      return null;
    }
  }

  /// Update disease (Admin only)
  Future<bool> updateDisease(String diseaseId, DiseaseModel disease) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(diseaseId)
          .update(disease.toMap());

      debugPrint('✅ [DiseaseService] Disease updated: $diseaseId');
      clearCache();
      return true;
    } catch (e) {
      debugPrint('❌ [DiseaseService] Error updating disease: $e');
      return false;
    }
  }

  /// Delete disease (Admin only)
  Future<bool> deleteDisease(String diseaseId) async {
    try {
      await _firestore.collection(_collectionName).doc(diseaseId).delete();

      debugPrint('✅ [DiseaseService] Disease deleted: $diseaseId');
      clearCache();
      return true;
    } catch (e) {
      debugPrint('❌ [DiseaseService] Error deleting disease: $e');
      return false;
    }
  }
}
