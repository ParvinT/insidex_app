// lib/services/email_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EmailService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // =================== EMAIL VERIFICATION ===================

  /// Resend verification email with rate limiting
  static DateTime? _lastVerificationEmailSent;
  static const Duration _emailCooldown = Duration(minutes: 1);

  /// Send email verification to current user
  static Future<Map<String, dynamic>> sendEmailVerification() async {
    try {
      // Rate limiting check
      if (_lastVerificationEmailSent != null) {
        final timeSinceLastEmail =
            DateTime.now().difference(_lastVerificationEmailSent!);
        if (timeSinceLastEmail < _emailCooldown) {
          final remainingSeconds =
              (_emailCooldown - timeSinceLastEmail).inSeconds;
          return {
            'success': false,
            'error':
                'Please wait $remainingSeconds seconds before requesting another email',
          };
        }
      }

      final user = _auth.currentUser;

      if (user == null) {
        return {
          'success': false,
          'error': 'No user is currently signed in',
        };
      }

      if (user.emailVerified) {
        return {
          'success': false,
          'error': 'Email is already verified',
        };
      }

      await user.sendEmailVerification();
      _lastVerificationEmailSent = DateTime.now();

      // Log verification request
      await _logEmailActivity(
        userId: user.uid,
        emailType: 'verification',
        email: user.email ?? '',
      );

      return {
        'success': true,
        'message': 'Verification email sent successfully',
      };
    } catch (e) {
      debugPrint('Error sending verification email: $e');
      return {
        'success': false,
        'error': 'Failed to send verification email. Please try again.',
      };
    }
  }

  /// Check if user's email is verified
  static Future<bool> isEmailVerified() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Reload user to get latest verification status
      await user.reload();
      return _auth.currentUser?.emailVerified ?? false;
    } catch (e) {
      debugPrint('Error checking email verification: $e');
      return false;
    }
  }

  /// Continuously check for email verification
  static Stream<bool> emailVerificationStream() {
    return Stream.periodic(const Duration(seconds: 3), (_) async {
      await _auth.currentUser?.reload();
      return _auth.currentUser?.emailVerified ?? false;
    }).asyncMap((event) async => await event);
  }

  // =================== WELCOME EMAIL ===================

  /// Queue welcome email for sending (will be processed by Cloud Function)
  static Future<bool> queueWelcomeEmail({
    required String userId,
    required String email,
    required String name,
  }) async {
    try {
      // Store email request in Firestore for Cloud Function to process
      await _firestore.collection('mail_queue').add({
        'to': email,
        'template': {
          'name': 'welcome',
          'data': {
            'userName': name,
            'userEmail': email,
            'appName': 'INSIDEX',
            'supportEmail': 'support@insidex.app',
            'currentYear': DateTime.now().year.toString(),
          },
        },
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
        'type': 'welcome',
      });

      // Log email queue
      await _logEmailActivity(
        userId: userId,
        emailType: 'welcome',
        email: email,
      );

      return true;
    } catch (e) {
      debugPrint('Error queuing welcome email: $e');
      return false;
    }
  }

  // =================== PASSWORD RESET ===================

  /// Send password reset email with custom handling
  static Future<Map<String, dynamic>> sendPasswordResetEmail(
      String email) async {
    try {
      // Send password reset email directly
      // Firebase will handle if user exists or not
      await _auth.sendPasswordResetEmail(email: email);

      // Log password reset request if we can find the user
      try {
        final user = await _getUserByEmail(email);
        if (user != null) {
          await _logEmailActivity(
            userId: user['uid'],
            emailType: 'password_reset',
            email: email,
          );
        }
      } catch (e) {
        // Log error silently, don't break the flow
        debugPrint('Could not log password reset: $e');
      }

      return {
        'success': true,
        'message':
            'If an account exists with this email, a password reset link has been sent.',
      };
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase Auth errors
      if (e.code == 'user-not-found') {
        // Don't reveal if user exists or not for security
        return {
          'success': true,
          'message':
              'If an account exists with this email, a password reset link has been sent.',
        };
      }
      return {
        'success': false,
        'error': _getAuthErrorMessage(e.code),
      };
    } catch (e) {
      debugPrint('Error sending password reset email: $e');
      return {
        'success': false,
        'error': 'Failed to send reset email. Please try again.',
      };
    }
  }

  // =================== EMAIL CHANGE ===================

  /// Update user's email address
  static Future<Map<String, dynamic>> updateEmail(String newEmail) async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        return {
          'success': false,
          'error': 'No user is currently signed in',
        };
      }

      // Send verification to new email
      await user.verifyBeforeUpdateEmail(newEmail);

      // Update Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'email': newEmail,
        'emailVerified': false,
        'emailUpdatedAt': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'message': 'Email updated. Please verify your new email address.',
      };
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'error': _getAuthErrorMessage(e.code),
      };
    } catch (e) {
      debugPrint('Error updating email: $e');
      return {
        'success': false,
        'error': 'Failed to update email. Please try again.',
      };
    }
  }

  // =================== HELPER METHODS ===================

  /// Log email activities for analytics
  static Future<void> _logEmailActivity({
    required String userId,
    required String emailType,
    required String email,
  }) async {
    try {
      await _firestore.collection('email_logs').add({
        'userId': userId,
        'email': email,
        'type': emailType,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'sent',
      });
    } catch (e) {
      debugPrint('Error logging email activity: $e');
    }
  }

  /// Get user by email from Firestore
  static Future<Map<String, dynamic>?> _getUserByEmail(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data();
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user by email: $e');
      return null;
    }
  }

  /// Get error message for auth exceptions
  static String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'requires-recent-login':
        return 'Please sign in again to complete this action.';
      case 'email-already-in-use':
        return 'This email is already associated with another account.';
      default:
        return 'An error occurred. Please try again.';
    }
  }

  // =================== EMAIL TEMPLATES ===================

  /// Get welcome email HTML template
  static String getWelcomeEmailTemplate({
    required String userName,
    required String userEmail,
  }) {
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Welcome to INSIDEX</title>
    <style>
        body { font-family: 'Arial', sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
        .content { background: white; padding: 30px; border: 1px solid #e0e0e0; border-radius: 0 0 10px 10px; }
        .button { display: inline-block; padding: 12px 30px; background: #667eea; color: white; text-decoration: none; border-radius: 5px; margin: 20px 0; }
        .feature { padding: 10px 0; border-bottom: 1px solid #f0f0f0; }
        .footer { text-align: center; padding: 20px; color: #888; font-size: 14px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Welcome to INSIDEX! 🎉</h1>
            <p>Your Journey to Inner Peace Begins Here</p>
        </div>
        
        <div class="content">
            <h2>Hello $userName! 👋</h2>
            
            <p>Thank you for joining INSIDEX. We're thrilled to have you as part of our community dedicated to mental wellness and personal growth.</p>
            
            <p><strong>Your account has been successfully created with:</strong></p>
            <p>Email: $userEmail</p>
            
            <h3>What You Can Do Now:</h3>
            <div class="feature">✨ Access 200+ subliminal audio sessions</div>
            <div class="feature">🧘 Personalized healing programs</div>
            <div class="feature">🎵 Custom frequency combinations</div>
            <div class="feature">💬 AI Psychologist support</div>
            <div class="feature">📊 Track your progress</div>
            
            <center>
                <a href="https://insidex.app/login" class="button">Start Your Journey</a>
            </center>
            
            <h3>Getting Started Tips:</h3>
            <ol>
                <li>Complete your profile to get personalized recommendations</li>
                <li>Set your first wellness goal</li>
                <li>Try our most popular "Deep Sleep" session tonight</li>
                <li>Enable notifications for daily mindfulness reminders</li>
            </ol>
            
            <p><strong>Need Help?</strong><br>
            Our support team is here for you. Feel free to reach out at support@insidex.app</p>
            
            <p>We're excited to support you on your wellness journey!</p>
            
            <p>With peace and positivity,<br>
            <strong>The INSIDEX Team</strong></p>
        </div>
        
        <div class="footer">
            <p>© 2025 INSIDEX. All rights reserved.</p>
            <p>This email was sent to $userEmail</p>
            <p><a href="https://insidex.app/unsubscribe">Unsubscribe</a> | <a href="https://insidex.app/privacy">Privacy Policy</a></p>
        </div>
    </div>
</body>
</html>
    ''';
  }
}
