// lib/models/emotional_map_model.dart

class EmotionalMapModel {
  final String id;
  final String symptomId; // Hangi semptom için
  final Map<String, String> content; // Multi-language emotional map text
  final String recommendedSessionId; // Yönlendirilecek session
  final int? sessionNumber; // Display için (№13)
  final DateTime? createdAt;

  EmotionalMapModel({
    required this.id,
    required this.symptomId,
    required this.content,
    required this.recommendedSessionId,
    this.sessionNumber,
    this.createdAt,
  });

  /// Create from Firestore document
  factory EmotionalMapModel.fromMap(
      Map<String, dynamic> map, String documentId) {
    return EmotionalMapModel(
      id: documentId,
      symptomId: map['symptomId'] ?? '',
      content: Map<String, String>.from(map['content'] ?? {}),
      recommendedSessionId: map['recommendedSessionId'] ?? '',
      sessionNumber: map['sessionNumber'],
      createdAt: map['createdAt']?.toDate(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'symptomId': symptomId,
      'content': content,
      'recommendedSessionId': recommendedSessionId,
      'sessionNumber': sessionNumber,
      'createdAt': createdAt,
    };
  }

  /// Get localized content
  String getLocalizedContent(String locale) {
    return content[locale] ?? content['en'] ?? 'No content available';
  }

  /// Copy with
  EmotionalMapModel copyWith({
    String? id,
    String? symptomId,
    Map<String, String>? content,
    String? recommendedSessionId,
    int? sessionNumber,
    DateTime? createdAt,
  }) {
    return EmotionalMapModel(
      id: id ?? this.id,
      symptomId: symptomId ?? this.symptomId,
      content: content ?? this.content,
      recommendedSessionId: recommendedSessionId ?? this.recommendedSessionId,
      sessionNumber: sessionNumber ?? this.sessionNumber,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}