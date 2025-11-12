// lib/models/disease_model.dart

class DiseaseModel {
  final String id;
  final String category; // physical, mental, emotional
  final int order; // Display order
  final String icon; // Emoji
  final Map<String, String> translations; // Multi-language names
  final DateTime? createdAt;

  DiseaseModel({
    required this.id,
    required this.category,
    required this.order,
    required this.icon,
    required this.translations,
    this.createdAt,
  });

  /// Create from Firestore document
  factory DiseaseModel.fromMap(Map<String, dynamic> map, String documentId) {
    return DiseaseModel(
      id: documentId,
      category: map['category'] ?? 'physical',
      order: map['order'] ?? 0,
      icon: map['icon'] ?? '❓',
      translations: Map<String, String>.from(map['translations'] ?? {}),
      createdAt: map['createdAt']?.toDate(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'order': order,
      'icon': icon,
      'translations': translations,
      'createdAt': createdAt,
    };
  }

  /// Get localized name
  String getLocalizedName(String locale) {
    return translations[locale] ?? translations['en'] ?? id;
  }

  /// Copy with
  DiseaseModel copyWith({
    String? id,
    String? category,
    int? order,
    String? icon,
    Map<String, String>? translations,
    DateTime? createdAt,
  }) {
    return DiseaseModel(
      id: id ?? this.id,
      category: category ?? this.category,
      order: order ?? this.order,
      icon: icon ?? this.icon,
      translations: translations ?? this.translations,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}