// lib/models/disease_cause_model.dart

class DiseaseCauseModel {
  final String id;
  final String diseaseId;
  final Map<String, String> content;
  final String? recommendedSessionId;
  final int? sessionNumber;
  final DateTime? createdAt;

  DiseaseCauseModel({
    required this.id,
    required this.diseaseId,
    required this.content,
    this.recommendedSessionId,
    this.sessionNumber,
    this.createdAt,
  });

  /// Create from Firestore document
  factory DiseaseCauseModel.fromMap(
      Map<String, dynamic> map, String documentId) {
    final sessionId = map['recommendedSessionId'] as String?;
    return DiseaseCauseModel(
      id: documentId,
      diseaseId: map['diseaseId'] ?? '',
      content: Map<String, String>.from(map['content'] ?? {}),
      recommendedSessionId:
          (sessionId != null && sessionId.isNotEmpty) ? sessionId : null,
      sessionNumber: map['sessionNumber'],
      createdAt: map['createdAt']?.toDate(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'diseaseId': diseaseId,
      'content': content,
      if (recommendedSessionId != null && recommendedSessionId!.isNotEmpty)
        'recommendedSessionId': recommendedSessionId,
      if (sessionNumber != null) 'sessionNumber': sessionNumber,
      'createdAt': createdAt,
    };
  }

  /// Get localized content
  String getLocalizedContent(String locale) {
    return content[locale] ?? content['en'] ?? 'No content available';
  }

  /// Check if has recommended session
  bool get hasRecommendedSession =>
      recommendedSessionId != null && recommendedSessionId!.isNotEmpty;

  /// Copy with
  DiseaseCauseModel copyWith({
    String? id,
    String? diseaseId,
    Map<String, String>? content,
    String? recommendedSessionId,
    int? sessionNumber,
    DateTime? createdAt,
  }) {
    return DiseaseCauseModel(
      id: id ?? this.id,
      diseaseId: diseaseId ?? this.diseaseId,
      content: content ?? this.content,
      recommendedSessionId: recommendedSessionId ?? this.recommendedSessionId,
      sessionNumber: sessionNumber ?? this.sessionNumber,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
