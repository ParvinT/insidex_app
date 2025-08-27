// lib/services/analytics_service.dart

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  static FirebaseAnalyticsObserver observer =
      FirebaseAnalyticsObserver(analytics: _analytics);

  // Onboarding Events
  static Future<void> logOnboardingStart() async {
    try {
      await _analytics.logEvent(
        name: 'onboarding_start',
        parameters: {
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      debugPrint('Analytics: Onboarding started');
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }

  static Future<void> logGoalsSelected(List<String> goals) async {
    try {
      await _analytics.logEvent(
        name: 'goals_selected',
        parameters: {
          'goals_count': goals.length,
          'goals': goals.join(','),
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      debugPrint('Analytics: Goals selected - ${goals.join(', ')}');
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }

  static Future<void> logGenderSelected(String gender) async {
    try {
      await _analytics.logEvent(
        name: 'gender_selected',
        parameters: {
          'gender': gender,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      debugPrint('Analytics: Gender selected - $gender');
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }

  static Future<void> logBirthDateSelected(int age, bool ageRestricted) async {
    try {
      await _analytics.logEvent(
        name: 'birthdate_selected',
        parameters: {
          'age': age,
          'age_restricted': ageRestricted,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      debugPrint('Analytics: Birth date selected - Age: $age');
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }

  static Future<void> logOnboardingComplete() async {
    try {
      await _analytics.logEvent(
        name: 'onboarding_complete',
        parameters: {
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      debugPrint('Analytics: Onboarding completed');
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }

  // User Registration & Login Events
  static Future<void> logSignUp(String method) async {
    try {
      await _analytics.logSignUp(signUpMethod: method);
      debugPrint('Analytics: User signed up - Method: $method');
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }

  static Future<void> logLogin(String method) async {
    try {
      await _analytics.logLogin(loginMethod: method);
      debugPrint('Analytics: User logged in - Method: $method');
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }

  // Set User Properties (after login)
  static Future<void> setUserProperties({
    required String userId,
    List<String>? goals,
    String? gender,
    int? age,
  }) async {
    try {
      await _analytics.setUserId(id: userId);

      if (goals != null) {
        await _analytics.setUserProperty(
          name: 'user_goals',
          value: goals.join(','),
        );
      }

      if (gender != null) {
        await _analytics.setUserProperty(
          name: 'user_gender',
          value: gender,
        );
      }

      if (age != null) {
        await _analytics.setUserProperty(
          name: 'user_age_group',
          value: _getAgeGroup(age),
        );
      }

      debugPrint('Analytics: User properties set for $userId');
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }

  // Helper function to categorize age groups
  static String _getAgeGroup(int age) {
    if (age < 18) return '13-17';
    if (age < 25) return '18-24';
    if (age < 35) return '25-34';
    if (age < 45) return '35-44';
    if (age < 55) return '45-54';
    return '55+';
  }

  // Screen View Events
  static Future<void> logScreenView(String screenName) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenName,
      );
      debugPrint('Analytics: Screen viewed - $screenName');
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }
}
