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
import 'subscription_provider.dart';

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
  bool get isAdmin => _isAdmin;
  bool _skipInitialSnapshot = false;
  String get userName => _userData?['name'] ?? 'User';
  String get userEmail => _userData?['email'] ?? '';
  String get userId => _firebaseUser?.uid ?? '';
  String get avatarEmoji => _userData?['avatarEmoji'] ?? 'turtle';

  // Marketing consent
  bool get marketingConsent => _userData?['marketingConsent'] ?? false;
  bool get privacyConsent => _userData?['privacyConsent'] ?? true;

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

    // ⭐ Mark that we should skip the initial snapshot
    _skipInitialSnapshot = true;

    // Biraz gecikme ekle ki saveActiveDevice tamamlansın
    Future.delayed(const Duration(milliseconds: 2000), () {
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

        // ⭐ Skip the FIRST snapshot after login (it might have stale data)
        if (_skipInitialSnapshot) {
          _skipInitialSnapshot = false;
          debugPrint('⏭️ Skipping initial snapshot (just logged in)');
          return;
        }

        final activeDevice = data['activeDevice'] as Map<String, dynamic>?;
        if (activeDevice == null) {
          debugPrint('⚠️ No activeDevice field found');
          return;
        }

        debugPrint(
            '🔑 Active device token: ${activeDevice['token']?.toString().substring(0, 20)}...');

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

    MiniPlayerProvider? miniPlayerProvider;
    final navigatorState = InsidexApp.navigatorKey.currentState;
    if (navigatorState != null) {
      try {
        miniPlayerProvider = Provider.of<MiniPlayerProvider>(
          navigatorState.context,
          listen: false,
        );
      } catch (e) {
        debugPrint('⚠️ Could not get MiniPlayerProvider: $e');
      }
    }

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
    if (navigatorState != null) {
      navigatorState.pushNamedAndRemoveUntil(
        '/auth/welcome',
        (route) => false,
      );
      Future.delayed(const Duration(milliseconds: 100), () {
        try {
          miniPlayerProvider?.dismiss();
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

    // ✅ Capture context-dependent values BEFORE any async
    final navContext = InsidexApp.navigatorKey.currentContext;
    final subscriptionProvider = navContext != null
        ? Provider.of<SubscriptionProvider>(navContext, listen: false)
        : null;

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

      // Initialize SubscriptionProvider
      if (subscriptionProvider != null) {
        try {
          await subscriptionProvider.initialize(uid);
          debugPrint('✅ SubscriptionProvider initialized');
        } catch (e) {
          debugPrint('⚠️ Could not initialize SubscriptionProvider: $e');
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
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

      debugPrint('Admin status for $uid: $_isAdmin');
      notifyListeners();
    } catch (e) {
      debugPrint('Error checking admin status: $e');
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
      'avatarEmoji': 'turtle',
      'isAdmin': false,
      // New subscription system
      'subscription': {
        'tier': 'free',
        'status': 'none',
        'trialUsed': false,
      },
      'createdAt': FieldValue.serverTimestamp(),
      'lastActiveAt': FieldValue.serverTimestamp(),
      'favoriteSessionIds': [],
      'completedSessionIds': [],
      'totalListeningMinutes': 0,
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
      debugPrint('Error updating marketing consent: $e');
    }
  }

  @override
  void dispose() {
    _stopDeviceSessionMonitoring();
    super.dispose();
  }
}
