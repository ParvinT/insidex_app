// lib/providers/user_provider.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProvider extends ChangeNotifier {
  User? _firebaseUser;
  Map<String, dynamic>? _userData;
  bool _isLoading = false;
  bool _isAdmin = false; // Admin flag

  // Getters
  User? get firebaseUser => _firebaseUser;
  Map<String, dynamic>? get userData => _userData;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _firebaseUser != null;
  bool get isAdmin => _isAdmin; // Admin getter
  bool get isPremium => _userData?['isPremium'] ?? false;
  String get userName => _userData?['name'] ?? 'User';
  String get userEmail => _userData?['email'] ?? '';
  String get userId => _firebaseUser?.uid ?? '';

  // Auth state listener
  void initAuthListener() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      _firebaseUser = user;
      if (user != null) {
        loadUserData(user.uid);
      } else {
        _userData = null;
        _isAdmin = false;
        notifyListeners();
      }
    });
  }

  // Load user data from Firestore
  Future<void> loadUserData(String uid) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Load user data
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (userDoc.exists) {
        _userData = userDoc.data();
      } else {
        // Create user document if doesn't exist
        await createUserDocument();
      }

      // Check admin status separately
      await checkAdminStatus(uid);
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Check if user is admin
  Future<void> checkAdminStatus(String uid) async {
    try {
      // Check in admins collection
      final adminDoc =
          await FirebaseFirestore.instance.collection('admins').doc(uid).get();

      _isAdmin = adminDoc.exists;

      // Also check isAdmin field in users collection as fallback
      if (!_isAdmin && _userData != null) {
        _isAdmin = _userData!['isAdmin'] ?? false;
      }

      print('Admin status for $uid: $_isAdmin');
      notifyListeners();
    } catch (e) {
      print('Error checking admin status: $e');
      _isAdmin = false;
    }
  }

  // Create new user document
  Future<void> createUserDocument() async {
    if (_firebaseUser == null) return;

    final userData = {
      'uid': _firebaseUser!.uid,
      'email': _firebaseUser!.email,
      'name': _firebaseUser!.displayName ?? 'User',
      'photoUrl': _firebaseUser!.photoURL,
      'isAdmin': false,
      'isPremium': false,
      'createdAt': FieldValue.serverTimestamp(),
      'lastActiveAt': FieldValue.serverTimestamp(),
      'favoriteSessionIds': [],
      'completedSessionIds': [],
      'totalListeningMinutes': 0,
    };

    await FirebaseFirestore.instance
        .collection('users')
        .doc(_firebaseUser!.uid)
        .set(userData);

    _userData = userData;
    notifyListeners();
  }

  // Update profile
  Future<bool> updateProfile({
    String? name,
    String? photoUrl,
  }) async {
    if (_firebaseUser == null) return false;

    try {
      final updates = <String, dynamic>{
        'lastActiveAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updates['name'] = name;
      if (photoUrl != null) updates['photoUrl'] = photoUrl;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_firebaseUser!.uid)
          .update(updates);

      // Update local data
      if (name != null) _userData!['name'] = name;
      if (photoUrl != null) _userData!['photoUrl'] = photoUrl;

      notifyListeners();
      return true;
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    _firebaseUser = null;
    _userData = null;
    _isAdmin = false;
    notifyListeners();
  }

  // Update premium status
  Future<void> updatePremiumStatus(bool isPremium) async {
    if (_firebaseUser == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_firebaseUser!.uid)
          .update({'isPremium': isPremium});

      _userData!['isPremium'] = isPremium;
      notifyListeners();
    } catch (e) {
      print('Error updating premium status: $e');
    }
  }
}
