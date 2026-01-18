// lib/core/constants/app_icons.dart

class AppIcons {
  // =================== CATEGORY ANIMATIONS ===================
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
      'name': 'skin',
      'label': 'Allergy & Skin',
      'path': 'skin.json',
    },
    {
      'name': 'woman',
      'label': "Women's Health",
      'path': 'woman.json',
    },
    {
      'name': 'man',
      'label': "Men's Health",
      'path': 'man.json',
    },
    {
      'name': 'addiction',
      'label': 'Addictions',
      'path': 'addiction.json',
    },
    {
      'name': 'child_health',
      'label': "Children's Health",
      'path': 'child_health.json',
    },
    {
      'name': 'child_dev',
      'label': 'Child Development',
      'path': 'child_dev.json',
    },
    {
      'name': 'digestive',
      'label': 'Digestive System',
      'path': 'digestive.json',
    },
    {
      'name': 'heart',
      'label': 'Heart & Blood',
      'path': 'heart.json',
    },
    {
      'name': 'bones',
      'label': 'Bones & Muscles',
      'path': 'bones.json',
    },
    {
      'name': 'lungs',
      'label': 'Respiratory & ENT',
      'path': 'lungs.json',
    },
    {
      'name': 'eye',
      'label': 'Vision',
      'path': 'eye.json',
    },
    {
      'name': 'teeth',
      'label': 'Teeth & Oral',
      'path': 'teeth.json',
    },
    {
      'name': 'kidney',
      'label': 'Kidneys & Excretory',
      'path': 'kidney.json',
    },
    {
      'name': 'medical',
      'label': 'Serious Diagnoses',
      'path': 'medical.json',
    },
    {
      'name': 'weight',
      'label': 'Weight & Body',
      'path': 'weight.json',
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

  // =================== UI ANIMATIONS ===================
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

  // =================== AVATAR ANIMATIONS ===================

  static const String avatarAnimationPath = 'assets/animations/avatars/';

  static const List<Map<String, dynamic>> avatarIcons = [
    {
      'name': 'turtle',
      'label': 'Zen Turtle',
      'path': 'meditating_turtle.json',
    },
    {
      'name': 'tiger',
      'label': 'Calm Tiger',
      'path': 'meditating_tiger.json',
    },
    {
      'name': 'koala',
      'label': 'Peaceful Koala',
      'path': 'meditating_koala.json',
    },
    {
      'name': 'brain',
      'label': 'Mindful Brain',
      'path': 'meditating_brain.json',
    },
    {
      'name': 'sloth',
      'label': 'Relaxed Sloth',
      'path': 'sloth_meditate.json',
    },
  ];

  /// Get full avatar animation path
  static String getAvatarAnimationPath(String fileName) {
    return '$avatarAnimationPath$fileName';
  }

  /// Get avatar icon data by name
  static Map<String, dynamic>? getAvatarByName(String name) {
    try {
      return avatarIcons.firstWhere((icon) => icon['name'] == name);
    } catch (e) {
      return null;
    }
  }

  /// Get avatar path by name (shortcut)
  static String getAvatarPath(String name) {
    final avatar = getAvatarByName(name);
    if (avatar != null) {
      return getAvatarAnimationPath(avatar['path']);
    }
    return getAvatarAnimationPath('meditating_turtle.json');
  }
}
