// lib/services/admin_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AdminService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Admin olup olmadığını kontrol et
  static Future<bool> isAdmin() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Method 1: Firestore'dan kontrol
      final adminDoc =
          await _firestore.collection('admins').doc(user.uid).get();

      return adminDoc.exists;
    } catch (e) {
      debugPrint('Error checking admin status: $e');
      return false;
    }
  }

  // Kullanıcıyı admin yap
  static Future<bool> makeUserAdmin({
    required String userId,
    required String email,
    String role = 'admin',
  }) async {
    try {
      // Sadece super admin yapabilir
      final isCurrentUserAdmin = await isAdmin();
      if (!isCurrentUserAdmin) return false;

      await _firestore.collection('admins').doc(userId).set({
        'email': email,
        'role': role,
        'addedAt': FieldValue.serverTimestamp(),
        'addedBy': _auth.currentUser?.email,
      });

      // User document'ını da güncelle
      await _firestore.collection('users').doc(userId).update({
        'isAdmin': true,
        'adminRole': role,
      });

      return true;
    } catch (e) {
      debugPrint('Error making user admin: $e');
      return false;
    }
  }

  // Admin listesini getir
  static Future<List<Map<String, dynamic>>> getAdminList() async {
    try {
      final snapshot = await _firestore
          .collection('admins')
          .orderBy('addedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('Error getting admin list: $e');
      return [];
    }
  }

  // Admin yetkisini kaldır
  static Future<bool> removeAdminAccess(String userId) async {
    try {
      final isCurrentUserAdmin = await isAdmin();
      if (!isCurrentUserAdmin) return false;

      // Admin document'ını sil
      await _firestore.collection('admins').doc(userId).delete();

      // User document'ını güncelle
      await _firestore.collection('users').doc(userId).update({
        'isAdmin': false,
        'adminRole': FieldValue.delete(),
      });

      return true;
    } catch (e) {
      debugPrint('Error removing admin access: $e');
      return false;
    }
  }
}
