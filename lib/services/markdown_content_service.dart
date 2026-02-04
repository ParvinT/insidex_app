// lib/services/markdown_content_service.dart

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Service for loading multilanguage markdown content from assets/content/
class MarkdownContentService {
  static const List<String> supportedContent = [
    'how_it_works',
  ];

  /// Load markdown content for a specific document and language
  static Future<String> loadContent({
    required String contentName,
    required String languageCode,
  }) async {
    try {
      // 1. Try to load in selected language
      final content = await rootBundle.loadString(
        'assets/content/$languageCode/$contentName.md',
      );
      debugPrint('✅ Content loaded: $contentName ($languageCode)');
      return content;
    } catch (e) {
      debugPrint(
          '⚠️ Content not found in $languageCode, falling back to English');

      try {
        // 2. Fallback: English
        final content = await rootBundle.loadString(
          'assets/content/en/$contentName.md',
        );
        debugPrint('✅ Content loaded (fallback): $contentName (en)');
        return content;
      } catch (e) {
        debugPrint('❌ Content not found: $contentName');
        return _getErrorMessage(contentName);
      }
    }
  }

  /// Get error message when content not found
  static String _getErrorMessage(String contentName) {
    return '''
# Error

The content "$contentName" could not be loaded.

Please try again later or contact support at support@insidexapp.com
''';
  }

  /// Load plain text content for a specific document and language
  static Future<String> loadTextContent({
    required String contentName,
    required String languageCode,
  }) async {
    try {
      final content = await rootBundle.loadString(
        'assets/content/$languageCode/$contentName.txt',
      );
      debugPrint('✅ Text content loaded: $contentName ($languageCode)');
      return content;
    } catch (e) {
      debugPrint(
          '⚠️ Text content not found in $languageCode, falling back to English');

      try {
        final content = await rootBundle.loadString(
          'assets/content/en/$contentName.txt',
        );
        debugPrint('✅ Text content loaded (fallback): $contentName (en)');
        return content;
      } catch (e) {
        debugPrint('❌ Text content not found: $contentName');
        return '';
      }
    }
  }
}
