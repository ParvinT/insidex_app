// lib/models/disease_model.dart

class DiseaseModel {
  final String id;
  final String gender;
  final Map<String, String> translations;
  final DateTime? createdAt;
  final String? categoryId;

  DiseaseModel({
    required this.id,
    required this.gender,
    required this.translations,
    this.createdAt,
    this.categoryId,
  });

  /// Create from Firestore document
  factory DiseaseModel.fromMap(Map<String, dynamic> map, String documentId) {
    return DiseaseModel(
      id: documentId,
      gender: map['gender'] ?? 'male',
      translations: Map<String, String>.from(map['translations'] ?? {}),
      createdAt: map['createdAt']?.toDate(),
      categoryId: map['categoryId'],
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'gender': gender,
      'translations': translations,
      'createdAt': createdAt,
      'categoryId': categoryId,
    };
  }

  /// Get localized name
  String getLocalizedName(String locale) {
    return translations[locale] ?? translations['en'] ?? id;
  }

  /// Copy with
  DiseaseModel copyWith({
    String? id,
    String? gender,
    Map<String, String>? translations,
    DateTime? createdAt,
    String? categoryId,
  }) {
    return DiseaseModel(
      id: id ?? this.id,
      gender: gender ?? this.gender,
      translations: translations ?? this.translations,
      createdAt: createdAt ?? this.createdAt,
      categoryId: categoryId ?? this.categoryId,
    );
  }
}
