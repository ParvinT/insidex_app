// lib/services/notifications/notification_localization_helper.dart

import 'package:shared_preferences/shared_preferences.dart';

/// Helper for returning notification texts based on user's language
/// Does not touch existing notification system, only provides texts
class NotificationLocalizationHelper {
  /// Get user's saved language
  static Future<String> _getUserLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Same key used by LocaleProvider
      final languageCode = prefs.getString('language_code');
      return languageCode ?? 'en'; // Default: English
    } catch (e) {
      return 'en'; // Fallback to English on error
    }
  }

  /// Get daily reminder texts
  static Future<Map<String, String>> getDailyReminderTexts() async {
    final lang = await _getUserLanguage();

    final texts = {
      'en': {
        'title': 'Time for Your Daily Session 🎧',
        'message': 'Take a moment to relax and heal with INSIDEX',
      },
      'ru': {
        'title': 'Время для вашей сессии 🎧',
        'message': 'Найдите минутку расслабиться и исцелиться с INSIDEX',
      },
    };

    return texts[lang] ?? texts['en']!;
  }

  /// Get streak milestone texts
  static Future<Map<String, String>> getStreakMilestoneTexts(int days) async {
    final lang = await _getUserLanguage();

    // English texts
    final en = _getEnglishStreakTexts(days);

    // Russian texts
    final ru = _getRussianStreakTexts(days);

    final allTexts = {
      'en': en,
      'ru': ru,
    };

    return allTexts[lang] ?? en;
  }

  /// Get streak lost texts
  static Future<Map<String, String>> getStreakLostTexts(int lostDays) async {
    final lang = await _getUserLanguage();

    final texts = {
      'en': {
        'title': '😔 Streak Ended',
        'message':
            'Your $lostDays day streak has ended. But don\'t worry, you can start fresh today!',
      },
      'ru': {
        'title': '😔 Серия прервана',
        'message':
            'Ваша серия в $lostDays дней прервана. Но не волнуйтесь, вы можете начать заново сегодня!',
      },
    };

    return texts[lang] ?? texts['en']!;
  }

  // PRIVATE HELPERS

  /// English streak milestone texts
  static Map<String, String> _getEnglishStreakTexts(int days) {
    switch (days) {
      case 3:
        return {
          'title': '🎉 Congratulations!',
          'message': '🔥 3 day streak! Great start!',
        };
      case 7:
        return {
          'title': '🎯 One Week Achievement!',
          'message': '7 days in a row! You\'re doing amazing!',
        };
      case 14:
        return {
          'title': '💪 Two Weeks Strong!',
          'message': '14 day streak! The habit is forming.',
        };
      case 21:
        return {
          'title': '🌟 21 Days - Habit Formed!',
          'message': 'Science says you\'ve built a new habit!',
        };
      case 30:
        return {
          'title': '🏆 30 Day Legend!',
          'message': 'One full month! Incredible dedication!',
        };
      case 50:
        return {
          'title': '💎 50 Day Diamond Streak!',
          'message': 'Half a century! You\'re a true INSIDEX master!',
        };
      case 100:
        return {
          'title': '👑 100 Day Champion!',
          'message': 'One hundred days! You\'re absolutely legendary! 🎊',
        };
      default:
        return {
          'title': '🎉 Congratulations!',
          'message': '$days day streak! Keep it up!',
        };
    }
  }

  /// Russian streak milestone texts
  static Map<String, String> _getRussianStreakTexts(int days) {
    switch (days) {
      case 3:
        return {
          'title': '🎉 Поздравляем!',
          'message': '🔥 3 дня подряд! Отличное начало!',
        };
      case 7:
        return {
          'title': '🎯 Достижение недели!',
          'message': '7 дней подряд! Вы великолепны!',
        };
      case 14:
        return {
          'title': '💪 Две недели силы!',
          'message': '14 дней подряд! Привычка формируется.',
        };
      case 21:
        return {
          'title': '🌟 21 День - Привычка сформирована!',
          'message': 'Наука говорит, что вы создали новую привычку!',
        };
      case 30:
        return {
          'title': '🏆 Легенда 30 дней!',
          'message': 'Целый месяц! Невероятная преданность!',
        };
      case 50:
        return {
          'title': '💎 Алмазная серия 50 дней!',
          'message': 'Полвека! Вы настоящий мастер INSIDEX!',
        };
      case 100:
        return {
          'title': '👑 Чемпион 100 дней!',
          'message': 'Сто дней! Вы абсолютно легендарны! 🎊',
        };
      default:
        return {
          'title': '🎉 Поздравляем!',
          'message': 'Серия $days дней! Продолжайте!',
        };
    }
  }
}
