// lib/models/quote_model.dart


/// Quote model for daily motivational quotes
/// Supports multi-language text
class QuoteModel {
  final String id;
  final Map<String, String> text; // {en: "...", tr: "...", ru: "...", hi: "..."}
  final String? author;
  final List<String> categories; // ["motivation", "morning", "sleep", ...]
  final List<String> targetGoals; // ["Health", "Confidence", ...] - matches user goals

  const QuoteModel({
    required this.id,
    required this.text,
    this.author,
    this.categories = const [],
    this.targetGoals = const [],
  });

  /// Get localized text
  String getText(String locale) {
    return text[locale] ?? text['en'] ?? '';
  }

  /// Check if quote matches any user goal
  bool matchesGoals(List<String> userGoals) {
    if (targetGoals.isEmpty) return true; // General quotes match all
    return userGoals.any((goal) => targetGoals.contains(goal));
  }

  /// Check if quote matches time category
  bool matchesTimeCategory(String timeCategory) {
    if (categories.isEmpty) return true;
    return categories.contains(timeCategory) || categories.contains('general');
  }

  factory QuoteModel.fromMap(Map<String, dynamic> map) {
    return QuoteModel(
      id: map['id'] ?? '',
      text: Map<String, String>.from(map['text'] ?? {}),
      author: map['author'],
      categories: List<String>.from(map['categories'] ?? []),
      targetGoals: List<String>.from(map['targetGoals'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'author': author,
      'categories': categories,
      'targetGoals': targetGoals,
    };
  }

  @override
  String toString() {
    return 'QuoteModel(id: $id, categories: $categories)';
  }
}