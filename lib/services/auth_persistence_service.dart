import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthPersistenceService {
  static const _secureStorage = FlutterSecureStorage();
  static const String _tokenKey = 'fb_auth_token';
  static const String _emailKey = 'user_email';
  static const String _uidKey = 'user_uid';
  static const String _timestampKey = 'token_timestamp';
  static const String _securePasswordKey = 'secure_password';

  // Token'ı ve kullanıcı bilgilerini kaydet
  static Future<void> saveAuthSession(User user, {String? password}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = await user.getIdToken();

      // Normal bilgileri SharedPreferences'a kaydet
      await prefs.setString(_tokenKey, token ?? '');
      await prefs.setString(_emailKey, user.email ?? '');
      await prefs.setString(_uidKey, user.uid);
      await prefs.setInt(_timestampKey, DateTime.now().millisecondsSinceEpoch);

      // Şifreyi SECURE STORAGE'a kaydet
      if (password != null && user.email != null) {
        await _savePassword(user.email!, password);
      }

      print('Auth session saved for: ${user.email}');
    } catch (e) {
      print('Error saving auth session: $e');
    }
  }

  // Session'ı kontrol et
  static Future<bool> hasValidSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Token var mı?
      final token = prefs.getString(_tokenKey);
      if (token == null || token.isEmpty) return false;

      // Token yaşı kontrolü (24 saat)
      final timestamp = prefs.getInt(_timestampKey) ?? 0;
      final age = DateTime.now().millisecondsSinceEpoch - timestamp;
      final maxAge = 24 * 60 * 60 * 1000; // 24 saat

      if (age > maxAge) {
        print('Token expired (age: ${age ~/ 1000 / 60} minutes)');
        return false;
      }

      return true;
    } catch (e) {
      print('Error checking session: $e');
      return false;
    }
  }

  // Otomatik giriş yap
  static Future<User?> autoSignIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString(_emailKey);

      if (email == null) {
        print('No saved email found');
        return null;
      }

      // Şifreyi SECURE STORAGE'dan al
      final password = await _getPassword(email);

      if (password == null) {
        print('No saved password found');
        return null;
      }

      print('Attempting auto sign-in for: $email');

      final userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Yeni token'ı kaydet
      if (userCredential.user != null) {
        await saveAuthSession(userCredential.user!, password: password);
      }

      return userCredential.user;
    } catch (e) {
      print('Auto sign-in failed: $e');
      return null;
    }
  }

  // Session'ı temizle
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_emailKey);

    // SharedPreferences temizle
    await prefs.remove(_tokenKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_uidKey);
    await prefs.remove(_timestampKey);

    // Secure storage temizle
    if (email != null) {
      await _secureStorage.delete(key: '${_securePasswordKey}_$email');
    }

    print('Auth session cleared');
  }

  // Basit şifreleme (production'da daha güçlü kullan)
  static Future<void> _savePassword(String email, String password) async {
    // Email'i key olarak kullan, her kullanıcı için ayrı şifre
    await _secureStorage.write(
      key: '${_securePasswordKey}_$email',
      value: password,
    );
  }

  static Future<String?> _getPassword(String email) async {
    return await _secureStorage.read(
      key: '${_securePasswordKey}_$email',
    );
  }

  // Token'ı yenile
  static Future<bool> refreshToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      await user.reload();
      final token = await user.getIdToken(true); // Force refresh

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token ?? '');
      await prefs.setInt(_timestampKey, DateTime.now().millisecondsSinceEpoch);

      print('Token refreshed successfully');
      return true;
    } catch (e) {
      print('Token refresh failed: $e');
      return false;
    }
  }
}
