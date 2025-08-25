// lib/features/player/test_audio_data.dart

class TestAudioData {
  // Test with public MP3 files that work on mobile
  static Map<String, dynamic> getTestSession() {
    return {
      'id': 'test_session',
      'title': 'Deep Sleep Healing',
      'category': 'Sleep',
      'emoji': '🌙',
      'intro': {
        'title': 'Relaxation Introduction',
        'description': 'A gentle introduction to prepare your mind',
        'audioUrl':
            'https://www.bensound.com/bensound-music/bensound-relaxing.mp3',
        'duration': 155, // 2:35 dakika (gerçek süre)
      },
      'subliminal': {
        'title': 'Deep Sleep Subliminals',
        'description':
            'Powerful subliminal affirmations for deep healing sleep',
        'audioUrl':
            'https://www.bensound.com/bensound-music/bensound-slowmotion.mp3',
        'duration': 7200, // 2 saat (Firebase'den gelecek gerçek değer)
      },
    };
  }

  // Alternative test URLs if above don't work
  static Map<String, dynamic> getAlternativeTestSession() {
    return {
      'id': 'test_session_2',
      'title': 'Meditation Session',
      'category': 'Meditation',
      'emoji': '🧘',
      'intro': {
        'title': 'Breathing Exercise',
        'description': 'Focus on your breath',
        'audioUrl':
            'https://ia800102.us.archive.org/14/items/MeditationMusic/Meditation1.mp3',
        'duration': 180, // 3 dakika
      },
      'subliminal': {
        'title': 'Deep Meditation',
        'description': 'Enter a state of deep relaxation',
        'audioUrl':
            'https://ia800102.us.archive.org/14/items/MeditationMusic/Meditation2.mp3',
        'duration': 5400, // 1.5 saat
      },
    };
  }

  // Firebase'den gelen gerçek session için duration hesaplama
  static int calculateDuration(String? audioUrl) {
    // Firebase Storage URL'lerinde duration bilgisi yoksa
    // Admin panel'den girilen değeri kullanın
    // Varsayılan değerler:
    // - Intro: 120 saniye (2 dakika)
    // - Subliminal: 7200 saniye (2 saat)

    if (audioUrl == null || audioUrl.isEmpty) {
      return 120; // Default 2 dakika
    }

    // URL'de "intro" geçiyorsa kısa, "subliminal" geçiyorsa uzun
    if (audioUrl.contains('intro')) {
      return 120; // 2 dakika
    } else if (audioUrl.contains('subliminal')) {
      return 7200; // 2 saat
    }

    return 3600; // Default 1 saat
  }
}
