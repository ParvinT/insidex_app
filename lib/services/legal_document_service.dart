// lib/services/legal_document_service.dart

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class LegalDocumentService {
  // Desteklenen dökümanlar
  static const List<String> supportedDocuments = [
    'privacy_policy',
    'terms_of_service',
    'disclaimer',
    'about',
  ];

  /// Yasal döküman yükle
  ///
  /// [documentName]: Döküman adı (örn: 'privacy_policy')
  /// [languageCode]: Dil kodu (örn: 'en', 'ru')
  ///
  /// Returns: Markdown içeriği string olarak
  static Future<String> loadDocument({
    required String documentName,
    required String languageCode,
  }) async {
    try {
      // 1. Seçili dilde dene
      final content = await rootBundle.loadString(
        'assets/legal/$languageCode/$documentName.md',
      );
      debugPrint('✅ Document loaded: $documentName ($languageCode)');
      return content;
    } catch (e) {
      debugPrint(
          '⚠️ Document not found in $languageCode, falling back to English');

      try {
        // 2. Fallback: İngilizce
        final content = await rootBundle.loadString(
          'assets/legal/en/$documentName.md',
        );
        debugPrint('✅ Document loaded (fallback): $documentName (en)');
        return content;
      } catch (e) {
        debugPrint('❌ Document not found: $documentName');
        return _getErrorMessage(documentName);
      }
    }
  }

  /// Döküman var mı kontrol et
  static Future<bool> documentExists({
    required String documentName,
    required String languageCode,
  }) async {
    try {
      await rootBundle.loadString(
        'assets/legal/$languageCode/$documentName.md',
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Hata mesajı döndür
  static String _getErrorMessage(String documentName) {
    return '''
# Error

## Document Not Found

The document "$documentName" could not be loaded.

Please try again later or contact support at support@insidexapp.com
''';
  }
}
