// lib/services/firebase_service.dart
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  FirebaseService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- Convenience getters/streams (başka yerlerde kullanılıyor olabilir)
  static User? get currentUser => _auth.currentUser;
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // =========================
  // SIGN UP (Yeni Akış)
  // =========================
  // Hemen Firebase Auth'ta user oluşturmaz; sadece OTP kaydı + mail kuyruğu.
  static Future<Map<String, dynamic>> signUp({
    required String email,
    required String name,
    String? password, // imza uyumu için; kullanılmıyor
  }) async {
    try {
      String genCode() =>
          List.generate(6, (_) => Random.secure().nextInt(10)).join();
      final code = genCode();

      // OTP/pending kayıt
      await _firestore.collection('otp_verifications').doc(email).set({
        'email': email,
        'name': name,
        'code': code,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(minutes: 10)),
        ),
        'attempts': 0,
      }, SetOptions(merge: true));

      // Mail kuyruğu (Cloud Functions bunu gönderir)
      await _firestore.collection('mail_queue').add({
        'to': email,
        'subject': 'Your INSIDEX password',
        'text': 'Your password: $code',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return {'success': true, 'email': email};
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'error': e.code,
        'message': e.message ?? 'Auth error',
      };
    } catch (_) {
      return {
        'success': false,
        'error': 'unknown',
        'message': 'An unexpected error occurred. Please try again.',
      };
    }
  }

  // =========================
  // SIGN IN
  // =========================
  static Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return {'success': true, 'user': cred.user};
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'error': e.code,
        'message': e.message ?? 'Auth error',
      };
    } catch (_) {
      return {
        'success': false,
        'error': 'unknown',
        'message': 'An unexpected error occurred.',
      };
    }
  }

  // =========================
  // RESET PASSWORD
  // =========================
  // Login ekranındaki çağrı ile birebir aynı isim.
  static Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return {'success': true};
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'error': e.code,
        'message': e.message ?? 'Auth error',
      };
    } catch (_) {
      return {
        'success': false,
        'error': 'unknown',
        'message': 'An unexpected error occurred.',
      };
    }
  }

  // (opsiyonel) Alias — başka yerlerde kullanılıyorsa kalsın
  static Future<Map<String, dynamic>> sendPasswordReset(String email) =>
      resetPassword(email);

  // =========================
  // SIGN OUT
  // =========================
  static Future<void> signOut() => _auth.signOut();

  // =========================
  // PROFIL MERGE (OTP sonrası)
  // =========================
  static Future<void> createOrMergeUserProfile({
    required String uid,
    required String email,
    String? name,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'uid': uid,
      'email': email,
      if (name != null && name.isNotEmpty) 'name': name,
      'createdAt': FieldValue.serverTimestamp(),
      'lastActiveAt': FieldValue.serverTimestamp(),
      'isPremium': false,
      'favoriteSessionIds': [],
      'completedSessionIds': [],
      'totalListeningMinutes': 0,
      'emailVerified': true,
      'emailVerifiedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
