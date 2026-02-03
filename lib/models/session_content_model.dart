// lib/models/session_content_model.dart

class SessionContentModel {
  final String title;
  final String description;
  final IntroductionContent introduction;

  SessionContentModel({
    required this.title,
    required this.description,
    required this.introduction,
  });

  // From Firestore
  factory SessionContentModel.fromMap(Map<String, dynamic> map) {
    return SessionContentModel(
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      introduction: IntroductionContent.fromMap(
        map['introduction'] ?? {},
      ),
    );
  }

  // To Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'introduction': introduction.toMap(),
    };
  }

  // Check if content is empty
  bool get isEmpty =>
      title.trim().isEmpty &&
      description.trim().isEmpty &&
      introduction.isEmpty;
}

class IntroductionContent {
  final String title;
  final String content;

  IntroductionContent({
    required this.title,
    required this.content,
  });

  factory IntroductionContent.fromMap(Map<String, dynamic> map) {
    return IntroductionContent(
      title: map['title'] ?? '',
      content: map['content'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
    };
  }

  bool get isEmpty => title.trim().isEmpty && content.trim().isEmpty;
}

class MultiLanguageContent {
  final SessionContentModel? en;
  final SessionContentModel? tr;
  final SessionContentModel? ru;
  final SessionContentModel? hi;

  MultiLanguageContent({
    this.en,
    this.tr,
    this.ru,
    this.hi,
  });

  // From Firestore
  factory MultiLanguageContent.fromMap(Map<String, dynamic> map) {
    return MultiLanguageContent(
      en: map['en'] != null ? SessionContentModel.fromMap(map['en']) : null,
      tr: map['tr'] != null ? SessionContentModel.fromMap(map['tr']) : null,
      ru: map['ru'] != null ? SessionContentModel.fromMap(map['ru']) : null,
      hi: map['hi'] != null ? SessionContentModel.fromMap(map['hi']) : null,
    );
  }

  // To Firestore
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};

    if (en != null && !en!.isEmpty) map['en'] = en!.toMap();
    if (tr != null && !tr!.isEmpty) map['tr'] = tr!.toMap();
    if (ru != null && !ru!.isEmpty) map['ru'] = ru!.toMap();
    if (hi != null && !hi!.isEmpty) map['hi'] = hi!.toMap();

    return map;
  }

  // Get content for specific language with fallback
  SessionContentModel getContent(String locale) {
    switch (locale) {
      case 'tr':
        return _getNonEmpty(tr) ?? _getNonEmpty(en) ?? _getFirstAvailable();
      case 'ru':
        return _getNonEmpty(ru) ?? _getNonEmpty(en) ?? _getFirstAvailable();
      case 'hi':
        return _getNonEmpty(hi) ?? _getNonEmpty(en) ?? _getFirstAvailable();
      default:
        return _getNonEmpty(en) ?? _getFirstAvailable();
    }
  }

// Helper: Returns content only if it has a non-empty title
  SessionContentModel? _getNonEmpty(SessionContentModel? content) {
    if (content != null && content.title.trim().isNotEmpty) {
      return content;
    }
    return null;
  }

  SessionContentModel _getFirstAvailable() {
    return en ??
        tr ??
        ru ??
        hi ??
        SessionContentModel(
          title: 'Untitled',
          description: '',
          introduction: IntroductionContent(title: '', content: ''),
        );
  }

  // Check which languages are available
  List<String> get availableLanguages {
    final languages = <String>[];
    if (en != null && !en!.isEmpty) languages.add('en');
    if (tr != null && !tr!.isEmpty) languages.add('tr');
    if (ru != null && !ru!.isEmpty) languages.add('ru');
    if (hi != null && !hi!.isEmpty) languages.add('hi');
    return languages;
  }

  bool hasLanguage(String locale) {
    return availableLanguages.contains(locale);
  }
}
