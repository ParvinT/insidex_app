// lib/providers/user_provider.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../app.dart';
import '../services/device_session_service.dart';
import '../shared/widgets/device_logout_dialog.dart';
import '../services/auth_persistence_service.dart';
import '../services/audio/audio_player_service.dart';
import '../services/download/decryption_preloader.dart';
import 'mini_player_provider.dart';

class UserProvider extends ChangeNotifier {
  User? _firebaseUser;
  Map<String, dynamic>? _userData;
  bool _isLoading = false;
  bool _isAdmin = false; // Admin flag

  StreamSubscription<DocumentSnapshot>? _deviceSessionSubscription;
  bool _isShowingLogoutDialog = false;
  // Getters
  User? get firebaseUser => _firebaseUser;
  Map<String, dynamic>? get userData => _userData;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _firebaseUser != null;
  bool get isAdmin => _isAdmin; // Admin getter
  String get userName => _userData?['name'] ?? 'User';
  String get userEmail => _userData?['email'] ?? '';
  String get userId => _firebaseUser?.uid ?? '';
  String get avatarEmoji => _userData?['avatarEmoji'] ?? 'turtle';

  // Premium related getters
  bool get isPremium => _userData?['isPremium'] ?? false;
  String get accountType => _userData?['accountType'] ?? 'free';
  DateTime? get premiumExpiryDate {
    final expiry = _userData?['premiumExpiryDate'];
    return expiry != null ? (expiry as Timestamp).toDate() : null;
  }

  // Session limits
  int get dailySessionsPlayed => _userData?['dailySessionsPlayed'] ?? 0;
  String? get lastSessionDate => _userData?['lastSessionDate'];
  int get dailySessionLimit => isPremium ? 999 : 3;

  // Marketing consent
  bool get marketingConsent => _userData?['marketingConsent'] ?? false;
  bool get privacyConsent => _userData?['privacyConsent'] ?? true;

  // Check if user can play another session today
  bool canPlaySession() {
    if (isPremium) return true;

    final today = DateTime.now().toIso8601String().split('T')[0];

    // If it's a new day, reset the counter
    if (lastSessionDate != today) {
      return true;
    }

    // Check if under the daily limit
    return dailySessionsPlayed < dailySessionLimit;
  }

  // Check if premium is active
  bool get isPremiumActive {
    if (!isPremium) return false;
    if (premiumExpiryDate == null) return true; // Lifetime premium
    return premiumExpiryDate!.isAfter(DateTime.now());
  }

  // Days left in premium
  int get premiumDaysLeft {
    if (!isPremium || premiumExpiryDate == null) return 0;
    final difference = premiumExpiryDate!.difference(DateTime.now()).inDays;
    return difference > 0 ? difference : 0;
  }

  // Auth state listener
  void initAuthListener() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      _firebaseUser = user;
      if (user != null) {
        loadUserData(user.uid);
      } else {
        _userData = null;
        _isAdmin = false;
        _stopDeviceSessionMonitoring();
      }
      notifyListeners();
    });
  }

  void _startDeviceSessionMonitoring(String userId) {
    _stopDeviceSessionMonitoring();

    debugPrint('🔍 Starting device session monitoring for: $userId');

    // 🔧 FIX: Biraz gecikme ekle ki context hazır olsun
    Future.delayed(const Duration(milliseconds: 1500), () {
      _deviceSessionSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots()
          .listen((snapshot) async {
        if (!snapshot.exists) {
          debugPrint('❌ User document does not exist');
          return;
        }

        final data = snapshot.data();
        if (data == null) {
          debugPrint('❌ User data is null');
          return;
        }

        debugPrint('📡 Firestore snapshot received');

        final activeDevice = data['activeDevice'] as Map<String, dynamic>?;
        if (activeDevice == null) {
          debugPrint('⚠️ No activeDevice field found');
          return;
        }

        debugPrint(
            '🔑 Active device token: ${activeDevice['token']?.substring(0, 20)}...');

        // Check if current device is still the active one
        final isActive =
            await DeviceSessionService().isCurrentDeviceActive(userId);

        debugPrint('🔍 Is current device active? $isActive');

        if (!isActive && !_isShowingLogoutDialog) {
          debugPrint(
              '⚠️ This device is no longer active! Starting logout countdown...');
          _showDeviceLogoutDialog();
        }
      }, onError: (error) {
        debugPrint('❌ Firestore listener error: $error');
      });

      debugPrint('✅ Device session monitoring started');
    });
  }

  // ⭐ NEW: Stop monitoring device session
  void _stopDeviceSessionMonitoring() {
    _deviceSessionSubscription?.cancel();
    _deviceSessionSubscription = null;
    debugPrint('🛑 Stopped device session monitoring');
  }

  // ⭐ NEW: Show logout dialog
  void _showDeviceLogoutDialog() {
    if (_isShowingLogoutDialog) return;

    // Use GlobalKey from InsidexApp
    final navigatorState = InsidexApp.navigatorKey.currentState;

    if (navigatorState == null) {
      debugPrint('❌ Navigator state is null! Cannot show dialog');
      return;
    }

    final context = navigatorState.context;

    _isShowingLogoutDialog = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DeviceLogoutDialog(
        onLogout: () {
          Navigator.of(context).pop();
          _performLogout(forcedByOtherDevice: true);
        },
        countdownSeconds: 30,
      ),
    );
  }

  // ⭐ NEW: Perform actual logout
  Future<void> _performLogout({bool forcedByOtherDevice = false}) async {
    _isShowingLogoutDialog = false;

    debugPrint('🎵 [UserProvider] Stopping audio before logout...');
    try {
      final audioService = AudioPlayerService();
      await audioService.stop();
      debugPrint('✅ [UserProvider] Audio stopped');
    } catch (e) {
      debugPrint('⚠️ [UserProvider] Audio stop error: $e');
    }

    try {
      await DecryptionPreloader().clear();
      debugPrint('✅ [UserProvider] Preloader cache cleared');
    } catch (e) {
      debugPrint('⚠️ [UserProvider] Preloader clear error: $e');
    }

    // Clear device session
    if (_firebaseUser != null && !forcedByOtherDevice) {
      debugPrint('🧹 Clearing active device (user initiated logout)');
      await DeviceSessionService().clearActiveDevice(_firebaseUser!.uid);
    } else if (forcedByOtherDevice) {
      debugPrint('⏭️ Skipping clearActiveDevice (forced by other device)');
    }

    // Sign out
    await signOut();

    // ✅ Navigate using GlobalKey
    final navigatorState = InsidexApp.navigatorKey.currentState;

    if (navigatorState != null) {
      navigatorState.pushNamedAndRemoveUntil(
        '/auth/welcome',
        (route) => false,
      );
      Future.delayed(const Duration(milliseconds: 100), () {
        try {
          final context = navigatorState.context;
          final miniPlayerProvider = Provider.of<MiniPlayerProvider>(
            context,
            listen: false,
          );
          miniPlayerProvider.dismiss();
          debugPrint('✅ [UserProvider] Mini player dismissed after logout');
        } catch (e) {
          debugPrint('⚠️ [UserProvider] Mini player dismiss error: $e');
        }
      });
    } else {
      debugPrint('❌ Cannot navigate to login - Navigator state is null');
    }
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

        bool needsUpdate = false;
        Map<String, dynamic> updates = {};

        if (!_userData!.containsKey('playlistSessionIds')) {
          updates['playlistSessionIds'] = [];
          needsUpdate = true;
        }

        if (!_userData!.containsKey('recentSessionIds')) {
          updates['recentSessionIds'] = [];
          needsUpdate = true;
        }

        if (needsUpdate) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .update(updates);

          // Local data'yı güncelle
          _userData!.addAll(updates);
        }

        // Check if it's a new day and reset session counter
        await _checkAndResetDailyLimit();
      } else {
        // Create user document if doesn't exist
        await createUserDocument();
      }

      // Check admin status separately
      await checkAdminStatus(uid);

      debugPrint('🔄 Checking for pending device updates...');
      await DeviceSessionService().processPendingDeviceUpdates();

      debugPrint('🎯 User data loaded, starting monitoring...');
      _startDeviceSessionMonitoring(uid);
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Check and reset daily session limit
  Future<void> _checkAndResetDailyLimit() async {
    if (_firebaseUser == null || isPremium) return;

    final today = DateTime.now().toIso8601String().split('T')[0];

    if (lastSessionDate != today) {
      // Reset daily counter
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_firebaseUser!.uid)
          .update({'dailySessionsPlayed': 0, 'lastSessionDate': today});

      _userData!['dailySessionsPlayed'] = 0;
      _userData!['lastSessionDate'] = today;
      notifyListeners();
    }
  }

  // Increment session play count
  Future<void> incrementSessionCount() async {
    if (_firebaseUser == null || isPremium) return;

    final newCount = dailySessionsPlayed + 1;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(_firebaseUser!.uid)
        .update({
      'dailySessionsPlayed': newCount,
      'lastActiveAt': FieldValue.serverTimestamp(),
    });

    _userData!['dailySessionsPlayed'] = newCount;
    notifyListeners();
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

    final today = DateTime.now().toIso8601String().split('T')[0];

    final userData = {
      'uid': _firebaseUser!.uid,
      'email': _firebaseUser!.email,
      'name': _firebaseUser!.displayName ?? 'User',
      'photoUrl': _firebaseUser!.photoURL,
      'avatarEmoji': 'turtle',
      'isAdmin': false,
      'isPremium': false,
      'accountType': 'free',
      'createdAt': FieldValue.serverTimestamp(),
      'lastActiveAt': FieldValue.serverTimestamp(),
      'favoriteSessionIds': [],
      'completedSessionIds': [],
      'totalListeningMinutes': 0,
      'dailySessionsPlayed': 0,
      'lastSessionDate': today,
      'marketingConsent': false,
      'privacyConsent': true,
      'consentDate': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('users')
        .doc(_firebaseUser!.uid)
        .set(userData);

    _userData = userData;
    notifyListeners();
  }

  // Update profile
  Future<bool> updateProfile(
      {String? name, String? photoUrl, String? avatarEmoji}) async {
    if (_firebaseUser == null) return false;

    try {
      final updates = <String, dynamic>{
        'lastActiveAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updates['name'] = name;
      if (photoUrl != null) updates['photoUrl'] = photoUrl;
      if (avatarEmoji != null) updates['avatarEmoji'] = avatarEmoji;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_firebaseUser!.uid)
          .update(updates);

      // Update local data
      if (name != null) _userData!['name'] = name;
      if (photoUrl != null) _userData!['photoUrl'] = photoUrl;
      if (avatarEmoji != null) _userData!['avatarEmoji'] = avatarEmoji;

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating profile: $e');
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    if (_firebaseUser != null) {
      await DeviceSessionService().clearActiveDevice(_firebaseUser!.uid);
    }
    await AuthPersistenceService.clearSession();
    await FirebaseAuth.instance.signOut();
    _firebaseUser = null;
    _userData = null;
    _isAdmin = false;
    _stopDeviceSessionMonitoring();
    notifyListeners();
  }

  // Update premium status (for admin use)
  Future<void> updatePremiumStatus({
    required bool isPremium,
    DateTime? expiryDate,
  }) async {
    if (_firebaseUser == null) return;

    try {
      final updates = {
        'isPremium': isPremium,
        'accountType': isPremium ? 'premium' : 'free',
        'premiumExpiryDate':
            expiryDate != null ? Timestamp.fromDate(expiryDate) : null,
        'premiumUpdatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_firebaseUser!.uid)
          .update(updates);

      _userData!['isPremium'] = isPremium;
      _userData!['accountType'] = isPremium ? 'premium' : 'free';
      _userData!['premiumExpiryDate'] =
          expiryDate != null ? Timestamp.fromDate(expiryDate) : null;

      notifyListeners();
    } catch (e) {
      print('Error updating premium status: $e');
    }
  }

  // Update marketing consent
  Future<void> updateMarketingConsent(bool consent) async {
    if (_firebaseUser == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_firebaseUser!.uid)
          .update({
        'marketingConsent': consent,
        'consentUpdatedAt': FieldValue.serverTimestamp(),
      });

      _userData!['marketingConsent'] = consent;
      notifyListeners();
    } catch (e) {
      print('Error updating marketing consent: $e');
    }
  }

  @override
  void dispose() {
    _stopDeviceSessionMonitoring();
    super.dispose();
  }
}
