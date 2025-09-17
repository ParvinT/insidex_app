// lib/services/firebase_service.dart
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
      print('=== Starting signUp process ===');
      print('Email: $email');
      print('Name: $name');

      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        return {
          'success': false,
          'error': 'Please enter a valid email address',
        };
      }

      // ✅ YENİ EKLENDİ - Name validation
      if (name.isEmpty || name.length < 2) {
        return {
          'success': false,
          'error': 'Name must be at least 2 characters',
        };
      }

      // Generate 6-digit OTP code
      String genCode() =>
          List.generate(6, (_) => Random.secure().nextInt(10)).join();
      final code = genCode();
      print('Generated OTP: $code');

      // Store OTP and user data temporarily (NOT creating Firebase Auth account yet)
      print('Attempting to write to otp_verifications collection...');
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
      print('Successfully wrote to otp_verifications');

      // Queue OTP email
      print('Attempting to write to mail_queue collection...');
      await _firestore.collection('mail_queue').add({
        'to': email,
        'type': 'otp',
        'subject': 'Your INSIDEX Verification Code',
        'text': 'Your verification code: $code',
        'html': _getOTPEmailHTML(name, code),
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
      print('Successfully wrote to mail_queue');

      return {
        'success': true,
        'email': email,
        'message': 'Verification code sent to your email.',
      };
    } on FirebaseAuthException catch (e) {
      // Firebase Auth errors shouldn't occur here since we're not creating account yet
      print(
        'Firebase Auth Error in signUp (unexpected): ${e.code} - ${e.message}',
      );
      return {'success': false, 'error': _getAuthErrorMessage(e.code)};
    } on FirebaseException catch (e) {
      // Firestore permission errors
      print('Firebase Exception in signUp: ${e.code} - ${e.message}');
      String errorMessage = 'Failed to send verification code.';

      if (e.code == 'permission-denied') {
        errorMessage = 'Permission denied. Please check Firestore rules.';
      } else if (e.code == 'unavailable') {
        errorMessage = 'Service unavailable. Please try again.';
      }

      return {'success': false, 'error': errorMessage, 'details': e.message};
    } catch (e) {
      print('Unexpected error during sign up: $e');
      print('Error type: ${e.runtimeType}');
      return {
        'success': false,
        'error': 'Failed to send verification code. Please try again.',
        'details': e.toString(),
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
          'error': 'Verification code not found. Please sign up again.',
        };
      }

      final data = otpDoc.data()!;

      // Check if already verified
      if (data['verified'] == true) {
        return {'success': false, 'error': 'This code has already been used.'};
      }

      // Check expiration
      final expiresAt = (data['expiresAt'] as Timestamp).toDate();
      if (DateTime.now().isAfter(expiresAt)) {
        return {
          'success': false,
          'error': 'Verification code has expired. Please sign up again.',
        };
      }

      // Check attempts
      final attempts = data['attempts'] ?? 0;
      if (attempts >= 5) {
        return {
          'success': false,
          'error': 'Too many failed attempts. Please sign up again.',
        };
      }

      // Verify code
      if (data['code'] != code) {
        // Increment attempts
        await otpDoc.reference.update({'attempts': FieldValue.increment(1)});
        return {
          'success': false,
          'error': 'Invalid verification code. Please try again.',
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
        'avatarEmoji': '👤',
        'onboardingCompleted': false,
        'playlistSessionIds': [],
        'recentSessionIds': [],
      });

      // Delete OTP document (cleanup)
      await otpDoc.reference.delete();

      // Queue welcome email
      await _firestore.collection('mail_queue').add({
        'to': email,
        'type': 'welcome',
        'subject': 'Welcome to INSIDEX!',
        'html': _getWelcomeEmailHTML(name),
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
      String errorMessage = _getAuthErrorMessage(e.code);
      return {'success': false, 'error': errorMessage, 'code': e.code};
    } catch (e) {
      print('Error verifying OTP: $e');
      return {
        'success': false,
        'error': 'Verification failed. Please try again.',
        'details': e.toString(),
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
      String errorMessage = _getAuthErrorMessage(e.code);
      return {'success': false, 'error': errorMessage, 'code': e.code};
    } catch (e) {
      print('Unexpected error during sign in: $e');
      return {
        'success': false,
        'error': 'An unexpected error occurred. Please try again.',
        'details': e.toString(),
      };
    }
  }

  // =========================
  // RESET PASSWORD
  // =========================
  static Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return {
        'success': true,
        'message': 'Password reset email sent successfully',
      };
    } on FirebaseAuthException catch (e) {
      String errorMessage = _getAuthErrorMessage(e.code);
      return {'success': false, 'error': errorMessage, 'code': e.code};
    } catch (e) {
      print('Unexpected error during password reset: $e');
      return {
        'success': false,
        'error': 'Failed to send password reset email. Please try again.',
        'details': e.toString(),
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
      print('Error signing out: $e');
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
          'error': 'No pending verification found. Please sign up again.',
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
        'subject': 'Your INSIDEX Verification Code',
        'text': 'Your new verification code: $newCode',
        'html': _getOTPEmailHTML(data['name'] ?? 'User', newCode),
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      return {
        'success': true,
        'message': 'New verification code sent to your email.',
      };
    } catch (e) {
      print('Error resending OTP: $e');
      return {
        'success': false,
        'error': 'Failed to resend code. Please try again.',
      };
    }
  }

  // =========================
  // Helper: Get readable error messages
  // =========================
  static String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered. Please sign in instead.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'weak-password':
        return 'The password is too weak. Please use at least 6 characters.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled. Please contact support.';
      default:
        return 'An error occurred. Please try again.';
    }
  }

  // =========================
  // Helper: OTP Email HTML Template
  // =========================
  static String _getOTPEmailHTML(String userName, String otpCode) {
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .container {
            background: white;
            border-radius: 8px;
            overflow: hidden;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
        }
        .header {
            background: #000;
            padding: 30px;
            text-align: center;
            color: white;
        }
        .content {
            padding: 30px;
        }
        .otp-box {
            background: #f9f9f9;
            border: 2px solid #000;
            border-radius: 8px;
            padding: 20px;
            text-align: center;
            margin: 20px 0;
        }
        .otp-code {
            font-size: 32px;
            font-weight: bold;
            letter-spacing: 5px;
            color: #000;
        }
        .footer {
            text-align: center;
            padding: 20px;
            color: #666;
            font-size: 12px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>INSIDEX</h1>
        </div>
        <div class="content">
            <p>Hello $userName,</p>
            <p>Your verification code is:</p>
            <div class="otp-box">
                <div class="otp-code">$otpCode</div>
            </div>
            <p>This code expires in 10 minutes.</p>
            <p>If you didn't request this code, please ignore this email.</p>
        </div>
        <div class="footer">
            © 2025 INSIDEX. All rights reserved.
        </div>
    </div>
</body>
</html>
    ''';
  }

  // =========================
  // Helper: Welcome Email HTML Template
  // =========================
  static String _getWelcomeEmailHTML(String userName) {
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .container {
            background: white;
            border-radius: 8px;
            overflow: hidden;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
        }
        .header {
            background: #000;
            padding: 30px;
            text-align: center;
            color: white;
        }
        .content {
            padding: 30px;
        }
        .footer {
            text-align: center;
            padding: 20px;
            color: #666;
            font-size: 12px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Welcome to INSIDEX!</h1>
        </div>
        <div class="content">
            <p>Hello $userName,</p>
            <p>Thank you for joining INSIDEX. Your account has been successfully created and verified.</p>
            <p>You can now enjoy all the features of our app.</p>
            <p>Best regards,<br>The INSIDEX Team</p>
        </div>
        <div class="footer">
            © 2025 INSIDEX. All rights reserved.
        </div>
    </div>
</body>
</html>
    ''';
  }
}
