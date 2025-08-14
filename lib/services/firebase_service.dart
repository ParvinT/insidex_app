// lib/services/firebase_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Auth State Stream
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Current User
  static User? get currentUser => _auth.currentUser;

  // =================== AUTH METHODS ===================

  // Sign Up
  static Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // Create user with email and password
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await credential.user?.updateDisplayName(name);

      // Create user document in Firestore

      await _firestore.collection('users').doc(credential.user!.uid).set({
        'uid': credential.user!.uid,
        'email': email,
        'name': name,
        'createdAt': DateTime.now(),
        'isPremium': false,
        'favoriteSessionIds': [],
        'completedSessionIds': [],
        'totalListeningMinutes': 0,
        'lastActiveAt': DateTime.now(),
      });

      return {
        'success': true,
        'user': credential.user,
      };
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'error': _getAuthErrorMessage(e.code),
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'An unexpected error occurred. Please try again.',
      };
    }
  }

  // Sign In
  static Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update last active
      await _firestore.collection('users').doc(credential.user!.uid).update({
        'lastActiveAt': DateTime.now(),
      });

      return {
        'success': true,
        'user': credential.user,
      };
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'error': _getAuthErrorMessage(e.code),
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'An unexpected error occurred. Please try again.',
      };
    }
  }

  // Sign Out
  static Future<void> signOut() async {
    await _auth.signOut();
  }

  // Reset Password
  static Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return {
        'success': true,
        'message': 'Password reset email sent to $email',
      };
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'error': _getAuthErrorMessage(e.code),
      };
    }
  }

  // =================== USER DATA METHODS ===================

  // Get User Data
  static Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Update User Profile
  static Future<bool> updateUserProfile({
    required String uid,
    String? name,
    String? photoUrl,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (photoUrl != null) updates['photoUrl'] = photoUrl;
      updates['updatedAt'] = DateTime.now();

      await _firestore.collection('users').doc(uid).update(updates);

      // Update Firebase Auth profile
      if (name != null) {
        await currentUser?.updateDisplayName(name);
      }
      if (photoUrl != null) {
        await currentUser?.updatePhotoURL(photoUrl);
      }

      return true;
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    }
  }

  // =================== SESSION METHODS ===================

  // Get All Sessions
  static Future<List<Map<String, dynamic>>> getAllSessions() async {
    try {
      final snapshot = await _firestore
          .collection('sessions')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting sessions: $e');
      return [];
    }
  }

  // Get Sessions by Category
  static Future<List<Map<String, dynamic>>> getSessionsByCategory(
      String category) async {
    try {
      final snapshot = await _firestore
          .collection('sessions')
          .where('category', isEqualTo: category)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting sessions by category: $e');
      return [];
    }
  }

  // Add Session to Favorites
  static Future<bool> toggleFavorite(String sessionId) async {
    try {
      final uid = currentUser?.uid;
      if (uid == null) return false;

      final userDoc = _firestore.collection('users').doc(uid);
      final userData = await userDoc.get();

      List<dynamic> favorites = userData.data()?['favoriteSessionIds'] ?? [];

      if (favorites.contains(sessionId)) {
        favorites.remove(sessionId);
      } else {
        favorites.add(sessionId);
      }

      await userDoc.update({'favoriteSessionIds': favorites});
      return true;
    } catch (e) {
      print('Error toggling favorite: $e');
      return false;
    }
  }

  // Track Session Play
  static Future<void> trackSessionPlay(
      String sessionId, int durationMinutes) async {
    try {
      final uid = currentUser?.uid;
      if (uid == null) return;

      // Update user's total listening time
      await _firestore.collection('users').doc(uid).update({
        'totalListeningMinutes': FieldValue.increment(durationMinutes),
        'lastActiveAt': DateTime.now(),
      });

      // Update session play count
      await _firestore.collection('sessions').doc(sessionId).update({
        'playCount': FieldValue.increment(1),
      });

      // Add to user's history
      await _firestore.collection('users').doc(uid).collection('history').add({
        'sessionId': sessionId,
        'playedAt': DateTime.now(),
        'durationMinutes': durationMinutes,
      });
    } catch (e) {
      print('Error tracking session play: $e');
    }
  }

  // =================== HELPER METHODS ===================

  static String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'weak-password':
        return 'The password is too weak. Use at least 6 characters.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}
