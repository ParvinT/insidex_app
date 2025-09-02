// lib/core/routes/app_routes.dart

import 'package:flutter/material.dart';

// --- Feature imports (relative, alias'sız) ---
import '../../features/splash/splash_screen.dart';
import '../../features/onboarding/goals_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/player/audio_player_screen.dart';
import '../../features/library/session_detail_screen.dart';
import '../../features/admin/admin_dashboard_screen.dart';
import '../../features/admin/add_session_screen.dart';
import '../../features/admin/category_management_screen.dart';
import '../../features/admin/session_management_screen.dart';
import '../../features/admin/user_management_screen.dart';
import '../../features/admin/admin_settings_screen.dart';
import '../../features/legal/privacy_policy_screen.dart';
import '../../features/legal/terms_of_service_screen.dart';
import '../../features/premium/premium_waitlist_screen.dart';
import '../../features/legal/about_screen.dart';
import '../../features/legal/disclaimer_screen.dart';

import 'package:insidex_app/features/auth/register_screen.dart'
    as auth_register;
import 'package:insidex_app/features/auth/login_screen.dart' as auth_login;
import 'package:insidex_app/features/auth/welcome_screen.dart' as auth_welcome;
import 'package:insidex_app/features/home/home_screen.dart' as home_screen;
import '../../features/profile/my_insights_screen.dart';

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
  static const String myInsights = '/profile/my-insights';
  static const String player = '/player';
  static const String sessionDetail = '/session-detail';
  static const String adminDashboard = '/admin/dashboard';

  static const String privacyPolicy = '/legal/privacy-policy';
  static const String termsOfService = '/legal/terms-of-service';
  static const String premiumWaitlist = '/premium/waitlist';
  static const String about = '/legal/about';
  static const String disclaimer = '/legal/disclaimer';

  static Map<String, WidgetBuilder> get routes => {
        splash: (_) => const SplashScreen(),
        goalsScreen: (_) => const GoalsScreen(),

        // auth (aliased)
        welcome: (_) => const auth_welcome.WelcomeScreen(),
        login: (_) => const auth_login.LoginScreen(),
        register: (_) => const auth_register.RegisterScreen(),

        // home (aliased, alias adı home DEĞİL!)
        home: (_) => const home_screen.HomeScreen(),

        // others
        settings: (_) => const SettingsScreen(),
        profile: (_) => const ProfileScreen(),
        myInsights: (_) => const MyInsightsScreen(),
        adminDashboard: (_) => const AdminDashboardScreen(),
        '/admin/add-session': (_) => const AddSessionScreen(),
        '/admin/categories': (_) => const CategoryManagementScreen(),
        '/admin/sessions': (_) => const SessionManagementScreen(),
        '/admin/users': (_) => const UserManagementScreen(),
        '/admin/settings': (_) => const AdminSettingsScreen(),

        // legal pages
        privacyPolicy: (_) => const PrivacyPolicyScreen(),
        termsOfService: (_) => const TermsOfServiceScreen(),
        about: (_) => const AboutScreen(),
        disclaimer: (_) => const DisclaimerScreen(),

        // premium
        premiumWaitlist: (_) => const PremiumWaitlistScreen(),

        // routes with arguments
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
