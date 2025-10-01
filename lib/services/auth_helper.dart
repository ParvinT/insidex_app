// lib/services/auth_helper.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class AuthHelper {
  static Future<void> logout(BuildContext context) async {
    try {
      // Firebase'den çıkış yap
      await FirebaseAuth.instance.signOut();

      // SharedPreferences'ı temizle
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('has_logged_in');
      await prefs.remove('cached_user_id');
      await prefs.remove('cached_user_email');

      debugPrint('✅ User logged out and cache cleared');

      // Login sayfasına yönlendir
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/auth/welcome',
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('❌ Error during logout: $e');
      // Hata olsa bile login'e yönlendir
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/auth/welcome',
          (route) => false,
        );
      }
    }
  }
}
