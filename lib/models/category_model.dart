// lib/models/category_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// Category model with multi-language support
/// Each category has names in multiple languages (en, tr, ru, hi)
class CategoryModel {
  final String id;
  final String iconName;
  final String gender;
  final Map<String, String> names;
  final List<String> backgroundImages;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int sessionCount;

  CategoryModel({
    required this.id,
    required this.iconName,
    this.gender = 'both',
    required this.names,
    this.backgroundImages = const [],
    this.createdAt,
    this.updatedAt,
    this.sessionCount = 0,
  });

  /// Get localized name with fallback
  /// Priority: requested locale → en → first available → 'Untitled'
  String getName(String locale) {
    return names[locale] ?? names['en'] ?? names.values.first;
  }

  /// Check which languages are available for this category
  List<String> get availableLanguages => names.keys.toList();

  /// Check if category has name for specific language
  bool hasLanguage(String locale) => names.containsKey(locale);

  /// Check if category has at least one name
  bool get hasAnyName => names.isNotEmpty;

  /// From Firestore document
  factory CategoryModel.fromMap(String id, Map<String, dynamic> map) {
    // NEW STRUCTURE: Multi-language
    if (map['names'] is Map) {
      return CategoryModel(
        id: id,
        iconName: map['iconName'] ?? 'meditation',
        gender: map['gender'] as String? ?? 'both',
        names: Map<String, String>.from(map['names'] ?? {}),
        backgroundImages: map['backgroundImages'] is List
            ? List<String>.from(map['backgroundImages'])
            : [],
        createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
        updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
        sessionCount: map['sessionCount'] ?? 0,
      );
    }

    // OLD STRUCTURE: Backward compatibility
    // Convert single 'title' field to multi-language format (English only)
    return CategoryModel(
      id: id,
      iconName: map['iconName'] ?? 'meditation',
      gender: map['gender'] as String? ?? 'both',
      names: {'en': map['title'] ?? 'Untitled'},
      backgroundImages: map['backgroundImages'] is List
          ? List<String>.from(map['backgroundImages'])
          : [],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      sessionCount: map['sessionCount'] ?? 0,
    );
  }

  /// To Firestore document
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'iconName': iconName,
      'gender': gender,
      'names': names,
      'backgroundImages': backgroundImages,
      'sessionCount': sessionCount,
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
  CategoryModel copyWith({
    String? id,
    String? iconName,
    String? gender,
    Map<String, String>? names,
    List<String>? backgroundImages,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? sessionCount,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      iconName: iconName ?? this.iconName,
      gender: gender ?? this.gender,
      names: names ?? this.names,
      backgroundImages: backgroundImages ?? this.backgroundImages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sessionCount: sessionCount ?? this.sessionCount,
    );
  }

  @override
  String toString() {
    return 'CategoryModel(id: $id,iconName: $iconName, names: $names,  images: ${backgroundImages.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CategoryModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
