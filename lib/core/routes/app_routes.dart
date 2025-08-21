import 'package:flutter/material.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/onboarding/goals_screen.dart';
import '../../features/onboarding/gender_screen.dart';
import '../../features/auth/welcome_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/player/audio_player_screen.dart';
import '../../features/library/session_detail_screen.dart';
import '../../features/admin/admin_dashboard_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String goalsScreen = '/onboarding/goals';
  static const String genderScreen = '/onboarding/gender';
  static const String birthDateScreen = '/onboarding/birthdate';
  static const String welcome = '/auth/welcome';
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String home = '/home';
  static const String settings = '/settings';
  static const String profile = '/profile';
  static const String player = '/player';
  static const String sessionDetail = '/session-detail';
  static const String adminDashboard = '/admin/dashboard';

  static Map<String, WidgetBuilder> get routes => {
        splash: (context) => const SplashScreen(),
        goalsScreen: (context) => const GoalsScreen(),
        welcome: (context) => const WelcomeScreen(),
        login: (context) => const LoginScreen(),
        register: (context) => const RegisterScreen(),
        home: (context) => const HomeScreen(),
        settings: (context) => const SettingsScreen(),
        profile: (context) => const ProfileScreen(),
        adminDashboard: (context) => const AdminDashboardScreen(),
        player: (context) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;
          return AudioPlayerScreen(sessionData: args);
        },
        sessionDetail: (context) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;
          return SessionDetailScreen(sessionData: args ?? {});
        },
      };
}
