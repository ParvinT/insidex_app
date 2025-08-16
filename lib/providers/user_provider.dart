// lib/providers/user_provider.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProvider extends ChangeNotifier {
  User? _firebaseUser;
  Map<String, dynamic>? _userData;
  bool _isLoading = false;

  // Getters
  User? get firebaseUser => _firebaseUser;
  Map<String, dynamic>? get userData => _userData;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _firebaseUser != null;
  bool get isAdmin => _userData?['isAdmin'] ?? false;
  bool get isPremium => _userData?['isPremium'] ?? false;
  String get userName => _userData?['name'] ?? 'User';
  String get userEmail => _userData?['email'] ?? '';

  // Auth state listener
  void initAuthListener() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      _firebaseUser = user;
      if (user != null) {
        loadUserData(user.uid);
      } else {
        _userData = null;
        notifyListeners();
      }
    });
  }

  // Firestore'dan kullanıcı verisini yükle
  Future<void> loadUserData(String uid) async {
    _isLoading = true;
    notifyListeners();

    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (doc.exists) {
        _userData = doc.data();
      } else {
        // Eğer Firestore'da yoksa oluştur
        await createUserDocument();
      }
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Yeni kullanıcı için Firestore document oluştur
  Future<void> createUserDocument() async {
    if (_firebaseUser == null) return;

    final userData = {
      'uid': _firebaseUser!.uid,
      'email': _firebaseUser!.email,
      'name': _firebaseUser!.displayName ?? 'User',
      'photoUrl': _firebaseUser!.photoURL,
      'isAdmin': false, // Admin email kontrolü yapılabilir
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

  // Profil güncelleme
  Future<bool> updateProfile({
    String? name,
    String? photoUrl,
  }) async {
    if (_firebaseUser == null) return false;

    try {
      final updates = <String, dynamic>{};

      if (name != null && name.isNotEmpty) {
        updates['name'] = name;
        await _firebaseUser!.updateDisplayName(name);
      }

      if (photoUrl != null) {
        updates['photoUrl'] = photoUrl;
        await _firebaseUser!.updatePhotoURL(photoUrl);
      }

      if (updates.isNotEmpty) {
        updates['updatedAt'] = FieldValue.serverTimestamp();

        await FirebaseFirestore.instance
            .collection('users')
            .doc(_firebaseUser!.uid)
            .update(updates);

        // Local state'i güncelle
        _userData?.addAll(updates);
        notifyListeners();
      }

      return true;
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    }
  }

  // Çıkış yap
  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    _firebaseUser = null;
    _userData = null;
    notifyListeners();
  }
}
