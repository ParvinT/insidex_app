// lib/services/firebase_service.dart
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import 'language_helper_service.dart';

class FirebaseService {
  FirebaseService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- Convenience getters/streams
  static User? get currentUser => _auth.currentUser;
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // =========================
  // SIGN UP - Only creates OTP record, NOT Firebase Auth account
  // =========================
  static Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      debugPrint('=== Starting signUp process ===');
      debugPrint('Email: $email');
      debugPrint('Name: $name');

      debugPrint('Checking if email exists via Cloud Function...');
      try {
        final callable =
            FirebaseFunctions.instance.httpsCallable('checkEmailExists');
        final result = await callable.call({'email': email});

        if (result.data['exists'] == true) {
          debugPrint('Email already registered: ${result.data['location']}');
          return {
            'success': false,
            'code': 'email-already-exists',
          };
        }
        debugPrint('Email is available');
      } catch (e) {
        debugPrint('Error checking email via Cloud Function: $e');
        // Devam et, en kötü duplicate error alırız
      }

      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        return {
          'success': false,
          'code': 'invalid-email-address',
        };
      }

      // ✅ YENİ EKLENDİ - Name validation
      if (name.isEmpty || name.length < 2) {
        return {
          'success': false,
          'code': 'name-too-short',
        };
      }

      // Generate 6-digit OTP code
      String genCode() =>
          List.generate(6, (_) => Random.secure().nextInt(10)).join();
      final code = genCode();
      debugPrint('Generated OTP: $code');

      // Store OTP and user data temporarily (NOT creating Firebase Auth account yet)
      debugPrint('Attempting to write to otp_verifications collection...');
      await _firestore.collection('otp_verifications').doc(email).set({
        'email': email,
        'name': name,
        'password': password, // Store encrypted in production!
        'code': code,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(minutes: 10)),
        ),
        'attempts': 0,
        'verified': false,
      });
      debugPrint('Successfully wrote to otp_verifications');

      // Queue OTP email
      debugPrint('Attempting to write to mail_queue collection...');
      await _firestore.collection('mail_queue').add({
        'to': email,
        'type': 'otp',
        'userName': name,
        'code': code,
        'lang': await LanguageHelperService.getCurrentLanguage(),
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
      debugPrint('Successfully wrote to mail_queue');

      return {
        'success': true,
        'email': email,
        'message': 'Verification code sent to your email.',
      };
    } on FirebaseAuthException catch (e) {
      // Firebase Auth errors shouldn't occur here since we're not creating account yet
      debugPrint(
        'Firebase Auth Error in signUp (unexpected): ${e.code} - ${e.message}',
      );
      return {'success': false, 'code': e.code};
    } on FirebaseException catch (e) {
      debugPrint('Firebase Exception in signUp: ${e.code} - ${e.message}');
      return {'success': false, 'code': e.code};
    } catch (e) {
      debugPrint('Unexpected error during sign up: $e');
      debugPrint('Error type: ${e.runtimeType}');
      return {
        'success': false,
        'code': 'unknown',
      };
    }
  }

  // =========================
  // VERIFY OTP AND CREATE ACCOUNT
  // =========================
  static Future<Map<String, dynamic>> verifyOTPAndCreateAccount({
    required String email,
    required String code,
  }) async {
    try {
      // Get OTP document
      final otpDoc =
          await _firestore.collection('otp_verifications').doc(email).get();

      if (!otpDoc.exists) {
        return {
          'success': false,
          'code': 'verification-code-not-found',
        };
      }

      final data = otpDoc.data()!;

      // Check if already verified
      if (data['verified'] == true) {
        return {
          'success': false,
          'code': 'verification-code-already-used',
        };
      }

      // Check expiration
      final expiresAt = (data['expiresAt'] as Timestamp).toDate();
      if (DateTime.now().isAfter(expiresAt)) {
        return {
          'success': false,
          'code': 'verification-code-expired',
        };
      }

      // Check attempts
      final attempts = data['attempts'] ?? 0;
      if (attempts >= 5) {
        return {
          'success': false,
          'code': 'too-many-verification-attempts',
        };
      }

      // Verify code
      if (data['code'] != code) {
        // Increment attempts
        await otpDoc.reference.update({'attempts': FieldValue.increment(1)});
        return {
          'success': false,
          'code': 'invalid-verification-code',
        };
      }

      // Code is correct! Now create the Firebase Auth account
      final password = data['password'];
      final name = data['name'] ?? '';

      // Create Firebase Auth account
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw Exception('Failed to create user account');
      }

      // Update display name
      await user.updateDisplayName(name);

      // Create user profile in Firestore
      final currentLang = await LanguageHelperService.getCurrentLanguage();

      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': email,
        'name': name,
        'createdAt': FieldValue.serverTimestamp(),
        'lastActiveAt': FieldValue.serverTimestamp(),
        'isPremium': false,
        'favoriteSessionIds': [],
        'completedSessionIds': [],
        'totalListeningMinutes': 0,
        'emailVerified': true,
        'emailVerifiedAt': FieldValue.serverTimestamp(),
        'profileCompleted': false,
        'avatarEmoji': 'turtle',
        'onboardingCompleted': false,
        'playlistSessionIds': [],
        'recentSessionIds': [],
        'preferredLanguage': currentLang,
      });

      // Delete OTP document (cleanup)
      await otpDoc.reference.delete();

      // Queue welcome email
      await _firestore.collection('mail_queue').add({
        'to': email,
        'type': 'welcome',
        'userName': name,
        'lang': currentLang,
        'userId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      return {
        'success': true,
        'user': user,
        'message': 'Account created successfully!',
      };
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase Auth errors
      return {'success': false, 'code': e.code};
    } catch (e) {
      debugPrint('Error verifying OTP: $e');
      return {
        'success': false,
        'code': 'unknown',
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
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        // Update last active timestamp
        await _firestore.collection('users').doc(user.uid).update({
          'lastActiveAt': FieldValue.serverTimestamp(),
        });
      }

      return {
        'success': true,
        'user': user,
        'message': 'Signed in successfully',
      };
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'code': e.code};
    } catch (e) {
      debugPrint('Unexpected error during sign in: $e');
      return {
        'success': false,
        'code': 'unknown',
      };
    }
  }

  // =========================
  // RESET PASSWORD
  // =========================

  static Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      final callable =
          FirebaseFunctions.instance.httpsCallable('customPasswordReset');

      final lang = await LanguageHelperService.getCurrentLanguage();
      await callable.call({'email': email, 'lang': lang});

      return {
        'success': true,
        'message': 'Password reset email sent successfully!',
      };
    } on FirebaseFunctionsException catch (e) {
      debugPrint('Cloud Function Error: ${e.code} - ${e.message}');

      if (e.code == 'not-found') {
        return {
          'success': false,
          'error': 'No account found with this email address.',
          'code': 'user-not-found',
        };
      }

      return {
        'success': false,
        'error': e.message ?? 'Failed to send reset email',
        'code': e.code,
      };
    } catch (e) {
      debugPrint('Unexpected error: $e');
      return {
        'success': false,
        'code': 'unknown',
      };
    }
  }

  // =========================
  // CHANGE PASSWORD
  // =========================
  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      if (currentPassword == newPassword) {
        return {
          'success': false,
          'code': 'same-password',
        };
      }
      final user = _auth.currentUser;

      if (user == null) {
        return {
          'success': false,
          'code': 'no-user',
        };
      }

      // Step 1: Reauthenticate user
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      try {
        await user.reauthenticateWithCredential(credential);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          return {
            'success': false,
            'code': 'wrong-password',
          };
        } else {
          return {
            'success': false,
            'code': 'auth-failed',
          };
        }
      }

      // Step 2: Update password
      await user.updatePassword(newPassword);

      // Step 3: Log in Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'passwordLastChangedAt': FieldValue.serverTimestamp(),
        'lastModifiedAt': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'message': 'Password changed successfully',
      };
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'code': e.code,
      };
    } catch (e) {
      debugPrint('Unexpected error changing password: $e');
      return {
        'success': false,
        'code': 'unknown',
      };
    }
  }

  // =========================
  // SIGN OUT
  // =========================
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }

  // =========================
  // RESEND OTP
  // =========================
  static Future<Map<String, dynamic>> resendOTP(String email) async {
    try {
      // Check if OTP record exists
      final otpDoc =
          await _firestore.collection('otp_verifications').doc(email).get();

      if (!otpDoc.exists) {
        return {
          'success': false,
          'code': 'no-pending-verification',
        };
      }

      final data = otpDoc.data()!;

      // Generate new code
      String genCode() =>
          List.generate(6, (_) => Random.secure().nextInt(10)).join();
      final newCode = genCode();

      // Update OTP document
      await otpDoc.reference.update({
        'code': newCode,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(minutes: 10)),
        ),
        'attempts': 0,
      });

      // Queue new OTP email
      await _firestore.collection('mail_queue').add({
        'to': email,
        'type': 'otp',
        'userName': data['name'] ?? 'User',
        'code': newCode,
        'lang': await LanguageHelperService.getCurrentLanguage(),
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      return {
        'success': true,
        'message': 'New verification code sent to your email.',
      };
    } catch (e) {
      debugPrint('Error resending OTP: $e');
      return {
        'success': false,
        'code': 'failed-to-resend',
      };
    }
  }
}
