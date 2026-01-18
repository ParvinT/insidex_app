// lib/services/session_filter_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'language_helper_service.dart';

class SessionFilterService {
  /// Filter sessions by user's current language
  /// Only returns sessions that have audio for the user's language
  static Future<List<Map<String, dynamic>>> filterSessionsByLanguage(
    List<QueryDocumentSnapshot> docs,
  ) async {
    final userLanguage = await LanguageHelperService.getCurrentLanguage();

    final filteredSessions = <Map<String, dynamic>>[];

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;

      // Check if session has audio for user's language
      final audioUrls = data['subliminal']?['audioUrls'];

      if (audioUrls is Map && audioUrls.containsKey(userLanguage)) {
        // Has audio for this language
        filteredSessions.add({
          'id': doc.id,
          ...data,
        });
      }
      // Else: Skip this session (no compatible audio)
    }

    return filteredSessions;
  }

  /// Check if a single session has audio for user's language
  static Future<bool> hasAudioForUserLanguage(
      Map<String, dynamic> session) async {
    final userLanguage = await LanguageHelperService.getCurrentLanguage();

    final audioUrls = session['subliminal']?['audioUrls'];

    if (audioUrls is Map) {
      return audioUrls.containsKey(userLanguage);
    }

    return false;
  }

  /// Filter already fetched session data (not QueryDocumentSnapshot)
  static Future<List<Map<String, dynamic>>> filterFetchedSessions(
    List<Map<String, dynamic>> sessions,
  ) async {
    final userLanguage = await LanguageHelperService.getCurrentLanguage();

    final filteredSessions = <Map<String, dynamic>>[];

    for (final session in sessions) {
      // Check if session has audio for user's language
      final audioUrls = session['subliminal']?['audioUrls'];

      if (audioUrls is Map && audioUrls.containsKey(userLanguage)) {
        // Has audio for this language
        filteredSessions.add(session);
      }
      // Else: Skip this session (no compatible audio)
    }

    return filteredSessions;
  }
  // =================== GENDER FILTERING ===================

  /// Get user's gender from Firestore
  static Future<String?> getUserGender() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      return userDoc.data()?['gender'] as String?;
    } catch (e) {
      debugPrint('Error getting user gender: $e');
      return null;
    }
  }

  /// Filter sessions by gender
  /// Shows sessions that match the filter OR are marked as 'both'
  /// filterGender: 'all' = show everything, 'male'/'female' = show specific + both
  static List<Map<String, dynamic>> filterByGender(
    List<Map<String, dynamic>> sessions,
    String filterGender,
  ) {
    if (filterGender == 'all') return sessions;

    return sessions.where((session) {
      final sessionGender = session['gender'] as String? ?? 'both';
      return sessionGender == 'both' || sessionGender == filterGender;
    }).toList();
  }

  /// Filter QueryDocumentSnapshot list by gender
  static List<QueryDocumentSnapshot> filterDocsByGender(
    List<QueryDocumentSnapshot> docs,
    String filterGender,
  ) {
    if (filterGender == 'all') return docs;

    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final sessionGender = data['gender'] as String? ?? 'both';
      return sessionGender == 'both' || sessionGender == filterGender;
    }).toList();
  }

  /// Combined filter: Language + Gender
  static Future<List<Map<String, dynamic>>> filterSessionsByLanguageAndGender(
    List<QueryDocumentSnapshot> docs,
    String genderFilter,
  ) async {
    final userLanguage = await LanguageHelperService.getCurrentLanguage();

    final filteredSessions = <Map<String, dynamic>>[];

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;

      // 1. Check language
      final audioUrls = data['subliminal']?['audioUrls'];
      if (audioUrls is! Map || !audioUrls.containsKey(userLanguage)) {
        continue; // Skip - no audio for user's language
      }

      // 2. Check gender
      if (genderFilter != 'all') {
        final sessionGender = data['gender'] as String? ?? 'both';
        if (sessionGender != 'both' && sessionGender != genderFilter) {
          continue; // Skip - doesn't match gender filter
        }
      }

      // Passed both filters
      filteredSessions.add({
        'id': doc.id,
        ...data,
      });
    }

    return filteredSessions;
  }
}
