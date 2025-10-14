// lib/core/routes/app_routes.dart

import 'package:flutter/material.dart';

// --- Feature imports (relative, alias'sız) ---
import '../../features/splash/splash_screen.dart';
import '../../features/onboarding/goals_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/player/audio_player_screen.dart';
import '../../features/admin/admin_dashboard_screen.dart';
import '../../features/admin/add_session_screen.dart';
import '../../features/admin/category_management_screen.dart';
import '../../features/admin/session_management_screen.dart';
import '../../features/admin/user_management_screen.dart';
import '../../features/admin/admin_settings_screen.dart';
import '../../features/premium/premium_waitlist_screen.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../../features/profile/change_password_screen.dart';
import '../../features/legal/legal_document_screen.dart';
import '../../l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  static const String forgotPassword = '/auth/forgot-password';
  static const String changePassword = '/profile/change-password';

  static const String home = '/home';
  static const String settings = '/settings';
  static const String profile = '/profile';
  static const String myInsights = '/profile/my-insights';
  static const String player = '/player';
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
        forgotPassword: (context) => const ForgotPasswordScreen(),
        changePassword: (context) => const ChangePasswordScreen(),

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

        // legal pages - Markdown-based
        privacyPolicy: (context) => LegalDocumentScreen(
              documentName: 'privacy_policy',
              title: AppLocalizations.of(context).privacyPolicy,
            ),
        termsOfService: (context) => LegalDocumentScreen(
              documentName: 'terms_of_service',
              title: AppLocalizations.of(context).termsOfService,
            ),
        disclaimer: (context) => LegalDocumentScreen(
              documentName: 'disclaimer',
              title: AppLocalizations.of(context).disclaimer,
            ),
        about: (context) => LegalDocumentScreen(
              documentName: 'about',
              title: AppLocalizations.of(context).aboutApp,
            ),

        // premium
        premiumWaitlist: (_) => const PremiumWaitlistScreen(),

        // routes with arguments
        player: (context) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;
          return AudioPlayerScreen(sessionData: args);
        },
      };

  // Profile navigation helper method
  static Future<void> navigateToProfile(BuildContext context) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      // Kullanıcı giriş yapmamış, onboarding kontrolü yap
      final prefs = await SharedPreferences.getInstance();
      final goals = prefs.getStringList('goals');
      final gender = prefs.getString('gender');
      final birthDate = prefs.getString('birthDate');

      if (goals == null ||
          goals.isEmpty ||
          gender == null ||
          gender.isEmpty ||
          birthDate == null ||
          birthDate.isEmpty) {
        // Onboarding eksik, oraya yönlendir
        Navigator.pushNamed(context, goalsScreen);
      } else {
        // Onboarding tam ama giriş yapmamış, login'e yönlendir
        Navigator.pushNamed(context, login);
      }
    } else {
      // Kullanıcı giriş yapmış, profile'a git
      Navigator.pushNamed(context, profile);
    }
  }
}
