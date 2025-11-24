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

  // UI Animations Path
  static const String uiAnimationPath = 'assets/animations/ui/';

// UI Icons
  static const List<Map<String, dynamic>> uiIcons = [
    {
      'name': 'information',
      'label': 'Help/Info',
      'path': 'information.json',
    },
    {
      'name': 'heartbeat',
      'label': 'Heartbeat',
      'path': 'heartbeat.json',
    },
  ];

  /// Get full UI animation path
  static String getUiAnimationPath(String fileName) {
    return '$uiAnimationPath$fileName';
  }

  /// Get UI icon data by name
  static Map<String, dynamic>? getUiIconByName(String name) {
    try {
      return uiIcons.firstWhere((icon) => icon['name'] == name);
    } catch (e) {
      return null;
    }
  }
}
