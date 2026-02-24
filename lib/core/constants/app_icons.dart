// lib/core/constants/app_icons.dart

class AppIcons {
  AppIcons._();

  // =================== CATEGORY ICONS (PNG) ===================
  static const String categoryIconPath = 'assets/icons/categories/';

  static const List<Map<String, String>> categoryIcons = [
    // Primary set (thick circle)
    {'name': 'brain', 'label': 'Brain/Focus', 'file': 'brain.png'},
    {'name': 'meditation', 'label': 'Meditation', 'file': 'meditation.png'},
    {'name': 'skin', 'label': 'Allergy & Skin', 'file': 'skin.png'},
    {'name': 'woman', 'label': "Women's Health", 'file': 'woman.png'},
    {'name': 'man', 'label': "Men's Health", 'file': 'man.png'},
    {'name': 'addiction', 'label': 'Addictions', 'file': 'addiction.png'},
    {
      'name': 'child_health',
      'label': "Children's Health",
      'file': 'child_health.png'
    },
    {
      'name': 'child_dev',
      'label': 'Child Development',
      'file': 'child_dev.png'
    },
    {'name': 'digestive', 'label': 'Digestive System', 'file': 'digestive.png'},
    {'name': 'heart', 'label': 'Heart & Blood', 'file': 'heart.png'},
    {'name': 'bones', 'label': 'Bones & Muscles', 'file': 'bones.png'},
    {'name': 'lungs', 'label': 'Respiratory & ENT', 'file': 'lungs.png'},
    {'name': 'eye', 'label': 'Vision', 'file': 'eye.png'},
    {'name': 'teeth', 'label': 'Teeth & Oral', 'file': 'teeth.png'},
    {'name': 'kidney', 'label': 'Kidneys & Excretory', 'file': 'kidney.png'},
    {'name': 'medical', 'label': 'Serious Diagnoses', 'file': 'medical.png'},
    {'name': 'weight', 'label': 'Weight & Body', 'file': 'weight.png'},
    {'name': 'mind', 'label': 'Mind & AI', 'file': 'mind.png'},
    {
      'name': 'man_shield',
      'label': "Men's Protection",
      'file': 'man_shield.png'
    },
    {
      'name': 'woman_shield',
      'label': "Women's Protection",
      'file': 'woman_shield.png'
    },
    {'name': 'immunity', 'label': 'Immunity', 'file': 'immunity.png'},
    {'name': 'man_body', 'label': 'Man Body', 'file': 'man_body.png'},

    // Alternative set (thin circle)
    {
      'name': 'addiction_alt',
      'label': 'Addictions (Alt)',
      'file': 'addiction_alt.png'
    },
    {'name': 'bones_alt', 'label': 'Bones (Alt)', 'file': 'bones_alt.png'},
    {
      'name': 'child_health_alt',
      'label': "Children's Health (Alt)",
      'file': 'child_health_alt.png'
    },
    {
      'name': 'child_dev_alt',
      'label': 'Child Dev (Alt)',
      'file': 'child_dev_alt.png'
    },
    {
      'name': 'digestive_alt',
      'label': 'Digestive (Alt)',
      'file': 'digestive_alt.png'
    },
    {'name': 'eye_alt', 'label': 'Vision (Alt)', 'file': 'eye_alt.png'},
    {'name': 'heart_alt', 'label': 'Heart (Alt)', 'file': 'heart_alt.png'},
    {'name': 'kidney_alt', 'label': 'Kidneys (Alt)', 'file': 'kidney_alt.png'},
    {
      'name': 'lungs_alt',
      'label': 'Respiratory (Alt)',
      'file': 'lungs_alt.png'
    },
    {'name': 'teeth_alt', 'label': 'Teeth (Alt)', 'file': 'teeth_alt.png'},
  ];

  /// Get full icon asset path by filename
  static String getIconPath(String fileName) {
    return '$categoryIconPath$fileName';
  }

  /// Get icon data by name
  static Map<String, String>? getIconByName(String name) {
    try {
      return categoryIcons.firstWhere((icon) => icon['name'] == name);
    } catch (e) {
      return null;
    }
  }

  /// Get full asset path by icon name (shortcut)
  static String getIconAssetPath(String iconName) {
    final icon = getIconByName(iconName);
    return getIconPath(icon?['file'] ?? 'meditation.png');
  }

  // =================== LEGACY SUPPORT ===================
  // These methods maintain backward compatibility during migration.
  // They map old Lottie calls to new PNG paths.

  /// @deprecated Use getIconPath instead
  static String getAnimationPath(String fileName) {
    // Convert .json reference to .png
    final pngName = fileName.replaceAll('.json', '.png');
    return getIconPath(pngName);
  }

  // =================== UI ANIMATIONS (Lottie - unchanged) ===================
  static const String uiAnimationPath = 'assets/animations/ui/';

  static const List<Map<String, dynamic>> uiIcons = [
    {'name': 'information', 'label': 'Help/Info', 'path': 'information.json'},
    {'name': 'heartbeat', 'label': 'Heartbeat', 'path': 'heartbeat.json'},
  ];

  static String getUiAnimationPath(String fileName) {
    return '$uiAnimationPath$fileName';
  }

  static Map<String, dynamic>? getUiIconByName(String name) {
    try {
      return uiIcons.firstWhere((icon) => icon['name'] == name);
    } catch (e) {
      return null;
    }
  }

  // =================== AVATAR ANIMATIONS (Lottie - unchanged) ===================
  static const String avatarAnimationPath = 'assets/animations/avatars/';

  static const List<Map<String, dynamic>> avatarIcons = [
    {'name': 'turtle', 'label': 'Zen Turtle', 'path': 'meditating_turtle.json'},
    {'name': 'tiger', 'label': 'Calm Tiger', 'path': 'meditating_tiger.json'},
    {
      'name': 'koala',
      'label': 'Peaceful Koala',
      'path': 'meditating_koala.json'
    },
    {
      'name': 'brain',
      'label': 'Mindful Brain',
      'path': 'meditating_brain.json'
    },
    {'name': 'sloth', 'label': 'Relaxed Sloth', 'path': 'sloth_meditate.json'},
  ];

  static String getAvatarAnimationPath(String fileName) {
    return '$avatarAnimationPath$fileName';
  }

  static Map<String, dynamic>? getAvatarByName(String name) {
    try {
      return avatarIcons.firstWhere((icon) => icon['name'] == name);
    } catch (e) {
      return null;
    }
  }

  static String getAvatarPath(String name) {
    final avatar = getAvatarByName(name);
    if (avatar != null) {
      return getAvatarAnimationPath(avatar['path']);
    }
    return getAvatarAnimationPath('meditating_turtle.json');
  }
}
