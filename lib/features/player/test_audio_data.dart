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
        // Free relaxation music from Bensound
        'audioUrl':
            'https://www.bensound.com/bensound-music/bensound-relaxing.mp3',
      },
      'subliminal': {
        'title': 'Deep Sleep Subliminals',
        'description':
            'Powerful subliminal affirmations for deep healing sleep',
        // Free meditation music from Bensound
        'audioUrl':
            'https://www.bensound.com/bensound-music/bensound-slowmotion.mp3',
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
        // Sample from Internet Archive (public domain)
        'audioUrl':
            'https://ia800102.us.archive.org/14/items/MeditationMusic/Meditation1.mp3',
      },
      'subliminal': {
        'title': 'Deep Meditation',
        'description': 'Enter a state of deep relaxation',
        // Sample from Internet Archive (public domain)
        'audioUrl':
            'https://ia800102.us.archive.org/14/items/MeditationMusic/Meditation2.mp3',
      },
    };
  }
}
