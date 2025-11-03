// lib/services/notifications/notification_localization_helper.dart

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui' as ui;

/// Helper for returning notification texts based on user's language
/// Does not touch existing notification system, only provides texts
class NotificationLocalizationHelper {
  /// Get user's saved language
  static Future<String> _getUserLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Same key used by LocaleProvider
      final languageCode = prefs.getString('language_code');
      if (languageCode != null) {
        return languageCode;
      }
      final deviceLocale = ui.PlatformDispatcher.instance.locale;
      final deviceLanguageCode = deviceLocale.languageCode;
      const supportedLanguages = ['en', 'tr', 'ru', 'hi'];
      if (supportedLanguages.contains(deviceLanguageCode)) {
        return deviceLanguageCode;
      }
      return 'en'; // Default: English
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
      'tr': {
        'title': 'Günlük Seans Zamanı 🎧',
        'message':
            'INSIDEX ile rahatlamak ve iyileşmek için bir dakikanızı ayırın',
      },
      'hi': {
        'title': 'आपके दैनिक सत्र का समय 🎧',
        'message': 'INSIDEX के साथ आराम करने और ठीक होने के लिए एक पल लें',
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

    //Turkish texts
    final tr = _getTurkishStreakTexts(days);

    // Hindi texts
    final hi = _getHindiStreakTexts(days);

    final allTexts = {
      'en': en,
      'ru': ru,
      'tr': tr,
      'hi': hi,
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
      'tr': {
        'title': '😔 Seri Sona Erdi',
        'message':
            '$lostDays günlük seriniz sona erdi. Ama endişelenmeyin, bugün yeniden başlayabilirsiniz!',
      },
      'hi': {
        'title': '😔 स्ट्रीक समाप्त',
        'message':
            'आपकी $lostDays दिन की स्ट्रीक समाप्त हो गई है। लेकिन चिंता न करें, आप आज से नई शुरुआत कर सकते हैं!',
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

  /// Turkish streak milestone texts
  static Map<String, String> _getTurkishStreakTexts(int days) {
    switch (days) {
      case 3:
        return {
          'title': '🎉 Tebrikler!',
          'message': '🔥 3 günlük seri! Harika bir başlangıç!',
        };
      case 7:
        return {
          'title': '🎯 Bir Haftalık Başarı!',
          'message': '7 gün üst üste! Harika gidiyorsun!',
        };
      case 14:
        return {
          'title': '💪 İki Hafta Güçlü!',
          'message': '14 günlük seri! Alışkanlık oluşuyor.',
        };
      case 21:
        return {
          'title': '🌟 21 Gün - Alışkanlık Oluştu!',
          'message': 'Bilim yeni bir alışkanlık oluşturduğunuzu söylüyor!',
        };
      case 30:
        return {
          'title': '🏆 30 Günlük Efsane!',
          'message': 'Tam bir ay! İnanılmaz bir bağlılık!',
        };
      case 50:
        return {
          'title': '💎 50 Günlük Elmas Seri!',
          'message': 'Yarım yüzyıl! Gerçek bir INSIDEX ustasısın!',
        };
      case 100:
        return {
          'title': '👑 100 Günlük Şampiyon!',
          'message': 'Yüz gün! Kesinlikle efsanesin! 🎊',
        };
      default:
        return {
          'title': '🎉 Tebrikler!',
          'message': '$days günlük harika bir seri!',
        };
    }
  }

  // =================== HINDI TEXTS - 🇮🇳 YENİ! ===================
  static Map<String, String> _getHindiStreakTexts(int days) {
    String title;
    String message;

    if (days == 3) {
      title = '🔥 3 दिन की स्ट्रीक!';
      message = 'बढ़िया शुरुआत! आप बहुत अच्छा कर रहे हैं!';
    } else if (days == 7) {
      title = '🔥 7 दिन की स्ट्रीक!';
      message = 'एक सप्ताह पूरा! आप अद्भुत हैं!';
    } else if (days == 14) {
      title = '🔥 14 दिन की स्ट्रीक!';
      message = 'दो सप्ताह! आपकी समर्पण प्रेरणादायक है!';
    } else if (days == 21) {
      title = '🔥 21 दिन की स्ट्रीक!';
      message = '3 सप्ताह! आपने एक नई आदत बना ली है!';
    } else if (days == 30) {
      title = '🔥 30 दिन की स्ट्रीक!';
      message = 'एक महीना! आप अविश्वसनीय हैं!';
    } else if (days == 50) {
      title = '🔥 50 दिन की स्ट्रीक!';
      message = 'आधी शताब्दी! आप एक किंवदंती हैं!';
    } else if (days == 100) {
      title = '🔥 100 दिन की स्ट्रीक!';
      message = 'शतक! आपने इतिहास रच दिया है!';
    } else {
      title = '🔥 $days दिन की स्ट्रीक!';
      message = 'अद्भुत! आपने $days दिन पूरे किए हैं!';
    }

    return {'title': title, 'message': message};
  }
}
