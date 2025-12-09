// lib/services/session_filter_service.dart

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
}
