// lib/core/constants/app_icons.dart

class AppIcons {
  static const String animationPath = 'assets/animations/categories/';

  static const List<Map<String, dynamic>> categoryIcons = [
    {
      'name': 'brain',
      'label': 'Brain/Focus',
      'path': 'brain.json',
    },
    {
      'name': 'meditation',
      'label': 'Meditation',
      'path': 'meditation.json',
    },
    {
      'name': 'heartbeat',
      'label': 'Health/Healing',
      'path': 'heartbeat.json',
    },
  ];

  /// Get full animation path
  static String getAnimationPath(String fileName) {
    return '$animationPath$fileName';
  }

  /// Get icon data by name
  static Map<String, dynamic>? getIconByName(String name) {
    try {
      return categoryIcons.firstWhere((icon) => icon['name'] == name);
    } catch (e) {
      return null;
    }
  }
}
