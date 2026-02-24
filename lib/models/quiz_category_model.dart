// lib/models/quiz_category_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// Quiz Category Model with multi-language support
/// Categories are filtered by gender (male/female/both)
class QuizCategoryModel {
  final String id;
  final String gender; // 'male', 'female', or 'both'
  final Map<String, String> names; // {en, tr, ru, hi}
  final DateTime? createdAt;
  final DateTime? updatedAt;

  QuizCategoryModel({
    required this.id,
    required this.gender,
    this.names = const {},
    this.createdAt,
    this.updatedAt,
  });

  /// Get localized name
  String getName(String locale) {
    return names[locale] ??
        names['en'] ??
        names.values.firstOrNull ??
        'Untitled';
  }

  /// Check which languages are available
  List<String> get availableLanguages => names.keys.toList();

  /// Check if category has name for specific language
  bool hasLanguage(String locale) => names.containsKey(locale);

  /// Check if category is visible for given gender
  bool isVisibleForGender(String userGender) {
    return gender == 'both' || gender == userGender;
  }

  /// From Firestore document
  factory QuizCategoryModel.fromMap(String id, Map<String, dynamic> map) {
    return QuizCategoryModel(
      id: id,
      gender: map['gender'] ?? 'both',
      names: map['names'] is Map ? Map<String, String>.from(map['names']) : {},
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// To Firestore document
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'gender': gender,
      'names': names,
    };

    if (createdAt != null) {
      map['createdAt'] = Timestamp.fromDate(createdAt!);
    }
    if (updatedAt != null) {
      map['updatedAt'] = Timestamp.fromDate(updatedAt!);
    }

    return map;
  }

  /// Create a copy with updated fields
  QuizCategoryModel copyWith({
    String? id,
    String? gender,
    Map<String, String>? names,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return QuizCategoryModel(
      id: id ?? this.id,
      gender: gender ?? this.gender,
      names: names ?? this.names,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'QuizCategoryModel(id: $id, gender: $gender)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QuizCategoryModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
