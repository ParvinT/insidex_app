// lib/providers/subscription_provider.dart

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

import '../models/subscription_model.dart';
import '../models/subscription_package.dart';
import '../core/constants/subscription_constants.dart';
import '../services/subscription/subscription_service.dart';

/// Provider for managing subscription state across the app
///
/// Responsibilities:
/// - Track current subscription status
/// - Provide access control helpers
/// - Handle subscription changes
/// - Cache subscription data locally
class SubscriptionProvider extends ChangeNotifier {
  // ============================================================
  // PRIVATE STATE
  // ============================================================

  final SubscriptionService _subscriptionService = SubscriptionService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  SubscriptionModel _subscription = SubscriptionModel.free();
  List<SubscriptionPackage> _availablePackages = [];

  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;

  StreamSubscription<User?>? _authSubscription;
  String? _currentUserId;
  Completer<void>? _initCompleter;

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  SubscriptionProvider() {
    _initAuthListener();
  }

  // ============================================================
  // GETTERS
  // ============================================================

  /// Current subscription data
  SubscriptionModel get subscription => _subscription;

  /// Available packages for purchase
  List<SubscriptionPackage> get availablePackages => _availablePackages;

  /// Loading state
  bool get isLoading => _isLoading;

  /// Whether provider has been initialized
  bool get isInitialized => _isInitialized;

  /// Last error message
  String? get error => _error;

  // ============================================================
  // CONVENIENCE GETTERS
  // ============================================================

  /// Current subscription tier
  SubscriptionTier get tier => _subscription.tier;

  /// Current subscription status
  SubscriptionStatus get status => _subscription.status;

  /// Whether user has an active subscription (paid or trial)
  bool get isActive => _subscription.isActive;

  /// Whether user is currently in trial
  bool get isInTrial => _subscription.isInTrial;

  /// Whether user can start a free trial
  bool get canStartTrial => _subscription.canStartTrial;

  /// Whether user can play audio sessions (non-demo)
  bool get canPlayAudio => _subscription.canPlayAudio;

  /// Whether user can download for offline
  bool get canDownload => _subscription.canDownload;

  /// Whether user can use background playback & lock screen controls
  bool get canUseBackgroundPlayback => _subscription.canUseBackgroundPlayback;

  /// Days remaining in subscription
  int get daysRemaining => _subscription.daysRemaining;

  /// Days remaining in trial
  int get trialDaysRemaining => _subscription.trialDaysRemaining;

  /// Whether subscription will auto-renew
  bool get willAutoRenew => _subscription.autoRenew;

  /// Check if user is free tier
  bool get isFree => tier == SubscriptionTier.free;

  /// Check if user is lite tier
  bool get isLite => tier == SubscriptionTier.lite;

  /// Check if user is standard tier
  bool get isStandard => tier == SubscriptionTier.standard;

  // ============================================================
  // INITIALIZATION
  // ============================================================

  /// Wait until subscription data is loaded
  /// Use this before checking subscription status
  Future<void> waitForInitialization() async {
    if (_isInitialized) return;

    _initCompleter ??= Completer<void>();
    return _initCompleter!.future;
  }

  /// Initialize provider for a user
  /// Call this after user login
  Future<void> initialize(String userId) async {
    if (_isInitialized && _currentUserId == userId) return;

    // Different user - reset first
    if (_currentUserId != null && _currentUserId != userId) {
      await reset();
    }

    _currentUserId = userId;
    _setLoading(true);
    _error = null;

    try {
      debugPrint('📦 [SubscriptionProvider] Initializing for user: $userId');

      // Initialize subscription service
      await _subscriptionService.initialize(userId);

      // Set up RevenueCat listener (real-time updates)
      _subscriptionService.setSubscriptionListener(_onRevenueCatUpdate);

      // Load current subscription
      await _loadSubscription(userId);

      // Load available packages
      await _loadPackages();

      _isInitialized = true;

      if (_initCompleter != null && !_initCompleter!.isCompleted) {
        _initCompleter!.complete();
      }
      debugPrint('✅ [SubscriptionProvider] Initialized successfully');
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ [SubscriptionProvider] Initialization error: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Listen to auth state changes and auto-initialize/reset
  void _initAuthListener() {
    _authSubscription = _auth.authStateChanges().listen((user) {
      if (user != null) {
        debugPrint('🔐 [SubscriptionProvider] User logged in: ${user.uid}');
        initialize(user.uid);
      } else {
        debugPrint('🔐 [SubscriptionProvider] User logged out');
        reset();
      }
    });
  }

  /// Reset provider state (call on logout)
  Future<void> reset() async {
    debugPrint('🔄 [SubscriptionProvider] Resetting state');

    // Remove RevenueCat listener
    _subscriptionService.setSubscriptionListener(null);

    _subscription = SubscriptionModel.free();
    _availablePackages = [];
    _isInitialized = false;
    _currentUserId = null;
    _initCompleter = null;
    _error = null;

    notifyListeners();
  }

  // ============================================================
  // SUBSCRIPTION LOADING
  // ============================================================

  /// Load subscription - RevenueCat is the source of truth
  Future<void> _loadSubscription(String userId) async {
    try {
      // Get trialUsed from Firestore (we need to preserve this)
      bool firestoreTrialUsed = false;
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data();
        final subscriptionData = data?['subscription'] as Map<String, dynamic>?;
        firestoreTrialUsed = subscriptionData?['trialUsed'] as bool? ?? false;
      }

      // RevenueCat is the source of truth
      final verifiedSubscription =
          await _subscriptionService.verifySubscription();

      if (verifiedSubscription != null) {
        // Use RevenueCat data, but preserve trialUsed from Firestore
        _subscription = verifiedSubscription.copyWith(
          trialUsed: verifiedSubscription.trialUsed || firestoreTrialUsed,
        );

        debugPrint(
            '📦 [SubscriptionProvider] Loaded from RevenueCat: $_subscription');

        // Sync to Firestore (as cache)
        await _syncToFirestore(userId, _subscription);
      } else {
        // No data from RevenueCat, use free
        _subscription = SubscriptionModel.free().copyWith(
          trialUsed: firestoreTrialUsed,
        );
        debugPrint(
            '📦 [SubscriptionProvider] No subscription, using free tier');
      }

      notifyListeners();
    } catch (e) {
      debugPrint('❌ [SubscriptionProvider] Error loading subscription: $e');
      _subscription = SubscriptionModel.free();
      notifyListeners();
    }
  }

  /// Sync subscription to Firestore
  Future<void> _syncToFirestore(
      String userId, SubscriptionModel subscription) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'subscription': subscription.toMap(),
      });
      debugPrint(
          '✅ [SubscriptionProvider] Synced to Firestore: ${subscription.tier}');
    } catch (e) {
      debugPrint('❌ [SubscriptionProvider] Sync error: $e');
    }
  }

  /// Called when RevenueCat detects subscription changes (real-time)
  void _onRevenueCatUpdate(SubscriptionModel newSubscription) {
    debugPrint(
        '🔔 [SubscriptionProvider] RevenueCat update received: ${newSubscription.tier}');

    // Update local state
    _subscription = newSubscription;

    // Sync to Firestore
    if (_currentUserId != null) {
      _syncToFirestore(_currentUserId!, newSubscription);
    }

    // Notify UI
    notifyListeners();
  }

  /// Load available packages from RevenueCat/store
  Future<void> _loadPackages() async {
    try {
      _availablePackages = await _subscriptionService.getAvailablePackages();
      debugPrint(
          '📦 [SubscriptionProvider] Loaded ${_availablePackages.length} packages');
    } catch (e) {
      debugPrint('❌ [SubscriptionProvider] Error loading packages: $e');
      // Fallback to default packages
      _availablePackages = SubscriptionPackage.getDefaultPackages();
    }
  }

  // ============================================================
  // PURCHASE METHODS
  // ============================================================

  /// Purchase a subscription package
  /// Returns true if successful
  Future<bool> purchase(SubscriptionPackage package) async {
    _setLoading(true);
    _error = null;

    try {
      debugPrint('💳 [SubscriptionProvider] Purchasing: ${package.productId}');

      final success = await _subscriptionService.purchase(package);

      if (success) {
        // Refresh subscription data
        final userId = _auth.currentUser?.uid;
        if (userId != null) {
          await _loadSubscription(userId);
        }
        debugPrint('✅ [SubscriptionProvider] Purchase successful');
      }

      return success;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ [SubscriptionProvider] Purchase error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Restore previous purchases
  Future<bool> restorePurchases() async {
    _setLoading(true);
    _error = null;

    try {
      debugPrint('🔄 [SubscriptionProvider] Restoring purchases');

      final success = await _subscriptionService.restorePurchases();

      if (success) {
        final userId = _auth.currentUser?.uid;
        if (userId != null) {
          await _loadSubscription(userId);
        }
        debugPrint('✅ [SubscriptionProvider] Restore successful');
      }

      return success;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ [SubscriptionProvider] Restore error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // ACCESS CONTROL HELPERS
  // ============================================================

  /// Check if user can play a specific session
  /// Returns true if session is demo OR user has active subscription
  bool canPlaySession(Map<String, dynamic> sessionData) {
    // Demo sessions are always playable
    final isDemo = sessionData['isDemo'] as bool? ?? false;
    if (isDemo) return true;

    // Check subscription
    return canPlayAudio;
  }

  /// Check if user can download a specific session
  bool canDownloadSession(Map<String, dynamic> sessionData) {
    // Must be standard tier with active subscription
    return canDownload;
  }

  /// Get the reason why user can't access a feature
  String? getAccessDeniedReason(String feature) {
    if (!isActive) {
      return 'Subscribe to access $feature';
    }

    if (feature == 'download' && !canDownload) {
      return 'Upgrade to Standard to download sessions';
    }

    return null;
  }

  // ============================================================
  // ADMIN METHODS (for testing/admin use)
  // ============================================================

  /// Grant subscription manually (admin only)
  Future<bool> grantSubscription({
    required String userId,
    required SubscriptionTier tier,
    required int durationDays,
    SubscriptionPeriod period = SubscriptionPeriod.monthly,
  }) async {
    try {
      debugPrint(
          '👑 [SubscriptionProvider] Granting $tier to $userId for $durationDays days');

      final now = DateTime.now();
      final expiryDate = now.add(Duration(days: durationDays));

      final subscription = SubscriptionModel(
        tier: tier,
        period: period,
        status: SubscriptionStatus.active,
        source: SubscriptionSource.admin,
        startDate: now,
        expiryDate: expiryDate,
        trialUsed: true,
        autoRenew: false,
      );

      await _firestore.collection('users').doc(userId).update({
        'subscription': subscription.toMap(),
      });

      // Reload if this is current user
      if (userId == _auth.currentUser?.uid) {
        await _loadSubscription(userId);
      }

      return true;
    } catch (e) {
      debugPrint('❌ [SubscriptionProvider] Grant error: $e');
      return false;
    }
  }

  /// Revoke subscription (admin only)
  Future<bool> revokeSubscription(String userId) async {
    try {
      debugPrint('🚫 [SubscriptionProvider] Revoking subscription for $userId');

      // Keep trialUsed info, just reset to free
      await _firestore.collection('users').doc(userId).update({
        'subscription.tier': 'free',
        'subscription.status': 'none',
        'subscription.period': FieldValue.delete(),
        'subscription.startDate': FieldValue.delete(),
        'subscription.expiryDate': FieldValue.delete(),
        'subscription.trialEndDate': FieldValue.delete(),
        'subscription.productId': FieldValue.delete(),
        'subscription.autoRenew': false,
        // trialUsed KORUNUYOR - silmiyoruz
      });

      // Reload if this is current user
      if (userId == _auth.currentUser?.uid) {
        await _loadSubscription(userId);
      }

      return true;
    } catch (e) {
      debugPrint('❌ [SubscriptionProvider] Revoke error: $e');
      return false;
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Refresh subscription data
  Future<void> refresh() async {
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      await _loadSubscription(userId);
      await _loadPackages();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _subscriptionService.setSubscriptionListener(null);
    super.dispose();
  }
}
