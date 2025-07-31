import 'package:flutter/material.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/onboarding/goals_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String goalsScreen = '/onboarding/goals';
  static const String genderScreen = '/onboarding/gender';
  static const String birthDateScreen = '/onboarding/birthdate';
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String home = '/home';

  static Map<String, WidgetBuilder> get routes => {
        splash: (context) => const SplashScreen(),
        goalsScreen: (context) => const GoalsScreen(),
        // Diğer route'lar sonra eklenecek
      };
}
