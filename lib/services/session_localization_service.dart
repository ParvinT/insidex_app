// lib/services/session_localization_service.dart

import 'package:flutter/material.dart';
import '../models/session_content_model.dart';
import 'language_helper_service.dart';

class SessionLocalizationService {
  /// Get localized content for a session
  /// Automatically falls back to English if user's language is not available
  static SessionContentModel getLocalizedContent(
    Map<String, dynamic> session,
    String locale,
  ) {
    try {
      // Parse multi-language content
      final contentMap = session['content'] as Map<String, dynamic>?;

      if (contentMap == null || contentMap.isEmpty) {
        // Fallback: Old structure (single language)
        debugPrint('⚠️ Session ${session['id']}: Using old structure');
        return SessionContentModel(
          title: session['title'] ?? 'Untitled',
          introduction: IntroductionContent(
            content: session['introduction']?['content'] ?? '',
          ),
        );
      }

      final multiLangContent = MultiLanguageContent.fromMap(contentMap);
      return multiLangContent.getContent(locale);
    } catch (e) {
      debugPrint('❌ Error getting localized content: $e');

      // Return safe fallback
      return SessionContentModel(
        title: 'Untitled Session',
        introduction: IntroductionContent(content: ''),
      );
    }
  }

  /// Get localized content using current app locale
  static Future<SessionContentModel> getLocalizedContentAuto(
    Map<String, dynamic> session,
  ) async {
    final locale = await LanguageHelperService.getCurrentLanguage();
    return getLocalizedContent(session, locale);
  }

  /// Get session number display (with №)
  static String getSessionNumberDisplay(Map<String, dynamic> session) {
    final number = session['sessionNumber'];
    if (number == null) return '';
    return '№$number';
  }

  /// Check if session has content for specific language
  static bool hasLanguage(Map<String, dynamic> session, String locale) {
    try {
      final contentMap = session['content'] as Map<String, dynamic>?;
      if (contentMap == null) return false;

      final multiLangContent = MultiLanguageContent.fromMap(contentMap);
      return multiLangContent.hasLanguage(locale);
    } catch (e) {
      return false;
    }
  }

  /// Get list of available languages for a session
  static List<String> getAvailableLanguages(Map<String, dynamic> session) {
    try {
      final contentMap = session['content'] as Map<String, dynamic>?;
      if (contentMap == null) return [];

      final multiLangContent = MultiLanguageContent.fromMap(contentMap);
      return multiLangContent.availableLanguages;
    } catch (e) {
      return [];
    }
  }

  /// Get language display name (delegates to LanguageHelperService)
  static String getLanguageDisplayName(String locale) {
    return LanguageHelperService.getLanguageName(locale);
  }

  /// Get language flag emoji (delegates to LanguageHelperService)
  static String getLanguageFlag(String locale) {
    return LanguageHelperService.getLanguageFlag(locale);
  }

  /// Check if session is missing content for user's language
  /// Returns true if fallback is being used
  static Future<bool> isUsingFallback(Map<String, dynamic> session) async {
    final userLocale = await LanguageHelperService.getCurrentLanguage();
    return !hasLanguage(session, userLocale);
  }

  /// Get complete session data with localized title for navigation
  /// Adds '_displayTitle' key with formatted title (includes session number)
  static Map<String, dynamic> prepareSessionForNavigation(
    Map<String, dynamic> sessionData,
    String languageCode,
  ) {
    final completeData = Map<String, dynamic>.from(sessionData);

    // Get localized content
    final localizedContent = getLocalizedContent(sessionData, languageCode);

    // Build display title
    final baseTitle = localizedContent.title.isNotEmpty
        ? localizedContent.title
        : (sessionData['title'] ?? 'Untitled Session');

    final displayTitle = baseTitle;

    // Add localized fields to session data
    completeData['_displayTitle'] = displayTitle;
    completeData['_localizedTitle'] = baseTitle;
    completeData['_localizedIntroContent'] =
        localizedContent.introduction.content;

    debugPrint('✅ [SessionLocalization] Prepared: $displayTitle');

    return completeData;
  }
}
