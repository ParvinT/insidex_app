// lib/providers/auto_play_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages auto-play settings for the audio player.
///
/// Controls whether sessions automatically advance to the next
/// session in the queue when playback completes.
/// Persists the setting via SharedPreferences.
class AutoPlayProvider extends ChangeNotifier {
  static const String _autoPlayKey = 'auto_play_enabled';

  bool _isEnabled = true;
  bool _isInitialized = false;

  bool get isEnabled => _isEnabled;
  bool get isInitialized => _isInitialized;

  AutoPlayProvider() {
    _loadSetting();
  }

  Future<void> _loadSetting() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isEnabled = prefs.getBool(_autoPlayKey) ?? true;
      _isInitialized = true;
      debugPrint('⚙️ [AutoPlay] Loaded setting: $_isEnabled');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ [AutoPlay] Error loading setting: $e');
      _isEnabled = true;
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> setEnabled(bool value) async {
    if (_isEnabled == value) return;

    _isEnabled = value;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_autoPlayKey, value);
      debugPrint('⚙️ [AutoPlay] Setting saved: $value');
    } catch (e) {
      debugPrint('❌ [AutoPlay] Error saving setting: $e');
    }
  }

  Future<void> toggle() async {
    await setEnabled(!_isEnabled);
  }
}
