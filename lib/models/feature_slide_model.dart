// lib/models/feature_slide_model.dart

/// Model for feature slideshow pages
class FeatureSlidePageModel {
  final String id;
  final Map<String, String> title;
  final Map<String, String> subtitle;
  final int order;
  final bool isActive;

  const FeatureSlidePageModel({
    required this.id,
    required this.title,
    required this.subtitle,
    this.order = 0,
    this.isActive = true,
  });

  String getTitle(String locale) {
    return title[locale] ?? title['en'] ?? '';
  }

  String getSubtitle(String locale) {
    return subtitle[locale] ?? subtitle['en'] ?? '';
  }

  factory FeatureSlidePageModel.fromMap(Map<String, dynamic> map) {
    return FeatureSlidePageModel(
      id: map['id'] ?? '',
      title: Map<String, String>.from(map['title'] ?? {}),
      subtitle: Map<String, String>.from(map['subtitle'] ?? {}),
      order: map['order'] ?? 0,
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'order': order,
      'isActive': isActive,
    };
  }

  FeatureSlidePageModel copyWith({
    String? id,
    Map<String, String>? title,
    Map<String, String>? subtitle,
    int? order,
    bool? isActive,
  }) {
    return FeatureSlidePageModel(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      order: order ?? this.order,
      isActive: isActive ?? this.isActive,
    );
  }
}

/// Complete feature slides data
class FeatureSlidesData {
  final int version;
  final List<String> images; // Image pool
  final List<FeatureSlidePageModel> pages;

  const FeatureSlidesData({
    this.version = 1,
    this.images = const [],
    this.pages = const [],
  });

  factory FeatureSlidesData.fromMap(Map<String, dynamic> map) {
    return FeatureSlidesData(
      version: map['version'] ?? 1,
      images: List<String>.from(map['images'] ?? []),
      pages: (map['pages'] as List<dynamic>?)
              ?.map((p) => FeatureSlidePageModel.fromMap(p))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'version': version,
      'images': images,
      'pages': pages.map((p) => p.toMap()).toList(),
    };
  }

  /// Get active pages sorted by order
  List<FeatureSlidePageModel> get activePages {
    return pages.where((p) => p.isActive).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }
}