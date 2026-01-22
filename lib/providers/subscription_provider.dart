// lib/providers/subscription_provider.dart
//
// Production-Ready Subscription Provider
// Uses RevenueCat Firebase Extension as the single source of truth
//
// Architecture:
// ┌─────────────────────────────────────────────────────────────────┐
// │  Google Play / App Store                                        │
// │            │                                                    │
// │            ▼                                                    │
// │      RevenueCat Server                                          │
// │            │                                                    │
// │            ▼ (Webhook - works even when app is closed)          │
// │  revenuecat_customers/{userId}  ◄── Firestore Real-time Stream  │
// │            │                                                    │
// │            ▼                                                    │
// │    SubscriptionProvider (this file)                             │
// │            │                                                    │
// │            ▼                                                    │
// │         UI Updates                                              │
// └─────────────────────────────────────────────────────────────────┘
//
// Benefits:
// - Server-side sync (works even when app is closed)
// - No polling needed (Firestore real-time listeners)
// - Automatic deferred downgrade handling via webhook
// - Race condition free (single source of truth)
// - Graceful degradation (SDK fallback if Extension fails)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'dart:async';

import '../models/subscription_model.dart';
import '../models/subscription_package.dart';
import '../core/constants/subscription_constants.dart';
import '../services/subscription/subscription_service.dart';

/// Provider for managing subscription state across the app
///
/// Uses RevenueCat Firebase Extension for real-time subscription data.
/// The extension syncs data via webhooks, so it works even when app is closed.
///
/// Usage:
/// ```dart
/// final provider = context.read<SubscriptionProvider>();
/// if (provider.canPlayAudio) {
///   // Play audio
/// }
/// ```
class SubscriptionProvider extends ChangeNotifier with WidgetsBindingObserver {
  // ============================================================
  // DEPENDENCIES
  // ============================================================

  final SubscriptionService _subscriptionService = SubscriptionService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ============================================================
  // STATE
  // ============================================================

  SubscriptionModel _subscription = SubscriptionModel.free();
  List<SubscriptionPackage> _availablePackages = [];

  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<DocumentSnapshot>? _extensionSubscription;
  String? _currentUserId;
  Completer<void>? _initCompleter;

  // Fallback refresh for edge cases (Extension webhook delays)
  Timer? _fallbackTimer;
  static const _fallbackInterval = Duration(minutes: 5);

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  SubscriptionProvider() {
    debugPrint('🏗️ [SubscriptionProvider] Initializing');
    WidgetsBinding.instance.addObserver(this);
    _initAuthListener();
  }

  // ============================================================
  // GETTERS - Subscription Data
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
  // GETTERS - Convenience Accessors (Spotify-style API)
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

  /// Whether user can use background playback
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

  /// Check if there's a pending subscription change
  bool get hasPendingChange => _subscription.hasPendingChange;

  /// Check if pending change is a downgrade
  bool get hasPendingDowngrade => _subscription.hasPendingDowngrade;

  // ============================================================
  // INITIALIZATION
  // ============================================================

  /// Wait until subscription data is loaded
  /// Use this before accessing subscription data in async contexts
  Future<void> waitForInitialization() async {
    if (_isInitialized) return;

    _initCompleter ??= Completer<void>();
    return _initCompleter!.future;
  }

  /// Initialize provider for a user
  Future<void> initialize(String userId) async {
    debugPrint('📦 [SubscriptionProvider] initialize() for: $userId');

    if (_isInitialized && _currentUserId == userId) {
      debugPrint('📦 [SubscriptionProvider] Already initialized, skipping');
      return;
    }

    // Different user - reset first
    if (_currentUserId != null && _currentUserId != userId) {
      debugPrint('📦 [SubscriptionProvider] Different user, resetting');
      await reset();
    }

    _currentUserId = userId;
    _setLoading(true);
    _error = null;

    try {
      // Step 1: Initialize RevenueCat SDK (for purchases only)
      await _subscriptionService.initialize(userId);
      debugPrint('✅ [SubscriptionProvider] RevenueCat SDK ready');

      // Step 2: Load initial data from Extension
      await _loadFromExtension(userId);
      debugPrint('✅ [SubscriptionProvider] Initial data loaded');

      // Step 3: Start real-time listener on Extension data
      _startExtensionListener(userId);
      debugPrint('✅ [SubscriptionProvider] Real-time listener active');

      // Step 4: Load available packages
      await _loadPackages();
      debugPrint('✅ [SubscriptionProvider] Packages loaded');

      // Step 5: Start fallback refresh (for edge cases)
      _startFallbackTimer();

      _isInitialized = true;

      if (_initCompleter != null && !_initCompleter!.isCompleted) {
        _initCompleter!.complete();
      }

      debugPrint(
          '🎉 [SubscriptionProvider] Ready - tier: ${_subscription.tier}, '
          'active: ${_subscription.isActive}, product: ${_subscription.productId}');
    } catch (e, stackTrace) {
      _error = e.toString();
      debugPrint('❌ [SubscriptionProvider] Init error: $e');
      debugPrint('❌ Stack: $stackTrace');

      // Graceful degradation - use free tier on error
      _subscription = SubscriptionModel.free();
    } finally {
      _setLoading(false);
    }
  }

  /// Listen to auth state changes
  void _initAuthListener() {
    final currentUser = _auth.currentUser;
    debugPrint(
        '👤 [SubscriptionProvider] Current user: ${currentUser?.uid ?? 'null'}');

    if (currentUser != null) {
      Future.microtask(() => initialize(currentUser.uid));
    }

    _authSubscription = _auth.authStateChanges().listen(
      (user) {
        debugPrint(
            '🔄 [SubscriptionProvider] Auth changed: ${user?.uid ?? 'null'}');

        if (user != null) {
          if (!_isInitialized || _currentUserId != user.uid) {
            initialize(user.uid);
          }
        } else {
          if (_isInitialized) {
            reset();
          }
        }
      },
      onError: (error) {
        debugPrint('❌ [SubscriptionProvider] Auth error: $error');
      },
    );
  }

  /// Reset provider state (call on logout)
  Future<void> reset() async {
    debugPrint('🔄 [SubscriptionProvider] Resetting');

    _stopExtensionListener();
    _stopFallbackTimer();

    _subscription = SubscriptionModel.free();
    _availablePackages = [];
    _isInitialized = false;
    _currentUserId = null;
    _initCompleter = null;
    _error = null;

    notifyListeners();
  }

  // ============================================================
  // EXTENSION DATA LOADING (Primary Source)
  // ============================================================

  /// Load subscription from RevenueCat Firebase Extension
  /// This is the PRIMARY data source - webhook updated, always fresh
  Future<void> _loadFromExtension(String userId) async {
    try {
      final doc =
          await _firestore.collection('revenuecat_customers').doc(userId).get();

      if (doc.exists && doc.data() != null) {
        _subscription = _parseExtensionData(doc.data()!, userId);
        debugPrint(
            '📦 [SubscriptionProvider] Extension: ${_subscription.tier}');
      } else {
        debugPrint('📦 [SubscriptionProvider] No Extension data, using SDK');
        await _loadFromSDK(userId);
      }
    } catch (e) {
      debugPrint('⚠️ [SubscriptionProvider] Extension error: $e');
      await _loadFromSDK(userId);
    }
  }

  /// Fallback: Load from RevenueCat SDK directly
  Future<void> _loadFromSDK(String userId) async {
    try {
      final verified =
          await _subscriptionService.verifySubscription(forceRefresh: true);

      if (verified != null) {
        _subscription = verified;
        debugPrint('📦 [SubscriptionProvider] SDK: ${_subscription.tier}');
      } else {
        _subscription = await _buildFreeWithTrialStatus(userId);
        debugPrint('📦 [SubscriptionProvider] Using FREE tier');
      }
    } catch (e) {
      debugPrint('⚠️ [SubscriptionProvider] SDK error: $e');
      _subscription = SubscriptionModel.free();
    }
  }

  /// Build free subscription preserving trial status
  Future<SubscriptionModel> _buildFreeWithTrialStatus(String userId) async {
    try {
      // Check if user has trial history in Extension
      final doc =
          await _firestore.collection('revenuecat_customers').doc(userId).get();

      bool trialUsed = false;
      if (doc.exists) {
        final data = doc.data();
        final subscriptions = data?['subscriptions'] as Map<String, dynamic>?;
        trialUsed = subscriptions != null && subscriptions.isNotEmpty;
      }

      return SubscriptionModel.free().copyWith(trialUsed: trialUsed);
    } catch (_) {
      return SubscriptionModel.free();
    }
  }

  // ============================================================
  // EXTENSION DATA PARSING
  // ============================================================

  /// Parse Extension document into SubscriptionModel
  SubscriptionModel _parseExtensionData(
      Map<String, dynamic> data, String userId) {
    final entitlements = data['entitlements'] as Map<String, dynamic>?;
    final subscriptions = data['subscriptions'] as Map<String, dynamic>?;

    if (entitlements == null || entitlements.isEmpty) {
      debugPrint('📋 [SubscriptionProvider] No entitlements');
      return _buildFreeFromData(data);
    }

    // Find active entitlement (priority: standard > lite)
    Map<String, dynamic>? activeEntitlement;
    SubscriptionTier tier = SubscriptionTier.free;

    // Check standard first (higher priority)
    if (entitlements.containsKey('standard')) {
      final standard = entitlements['standard'] as Map<String, dynamic>?;
      if (standard != null && _isEntitlementActive(standard)) {
        activeEntitlement = standard;
        tier = SubscriptionTier.standard;
      }
    }

    // Check lite if no standard
    if (activeEntitlement == null && entitlements.containsKey('lite')) {
      final lite = entitlements['lite'] as Map<String, dynamic>?;
      if (lite != null && _isEntitlementActive(lite)) {
        activeEntitlement = lite;
        tier = SubscriptionTier.lite;
      }
    }

    if (activeEntitlement == null) {
      debugPrint('📋 [SubscriptionProvider] No active entitlements');
      return _buildFreeFromData(data);
    }

    // Parse entitlement details
    final productId = activeEntitlement['product_identifier'] as String?;
    final expiresStr = activeEntitlement['expires_date'] as String?;
    final purchaseStr = activeEntitlement['purchase_date'] as String?;
    final gracePeriodStr =
        activeEntitlement['grace_period_expires_date'] as String?;

    final expiryDate = _parseDate(expiresStr);
    final startDate = _parseDate(purchaseStr);
    final gracePeriodExpires = _parseDate(gracePeriodStr);

    // Determine period
    final period = (productId?.contains('yearly') ?? false)
        ? SubscriptionPeriod.yearly
        : SubscriptionPeriod.monthly;

    // Determine status
    final status = _determineStatus(
      expiryDate: expiryDate,
      gracePeriodExpires: gracePeriodExpires,
      subscriptions: subscriptions,
      productId: productId,
    );

    // Check for pending changes (deferred downgrades)
    final pending = _detectPendingChanges(
      entitlements: entitlements,
      subscriptions: subscriptions,
      currentProductId: productId,
    );

    // Trial info
    final trialInfo = _extractTrialInfo(subscriptions, productId);

    debugPrint('📋 [SubscriptionProvider] Parsed: tier=$tier, status=$status, '
        'product=$productId, pending=${pending['tier']}');

    return SubscriptionModel(
      tier: tier,
      period: period,
      status: status,
      source: SubscriptionSource.revenuecat,
      startDate: startDate,
      expiryDate: expiryDate,
      trialEndDate: trialInfo['trialEndDate'] as DateTime?,
      trialUsed: trialInfo['trialUsed'] as bool? ?? false,
      autoRenew: _checkAutoRenew(subscriptions, productId),
      productId: productId,
      lastVerifiedAt: DateTime.now(),
      pendingTier: pending['tier'] as SubscriptionTier?,
      pendingProductId: pending['productId'] as String?,
    );
  }

  /// Check if an entitlement is currently active
  bool _isEntitlementActive(Map<String, dynamic> entitlement) {
    final expiresStr = entitlement['expires_date'] as String?;
    if (expiresStr == null) return false;

    final expiresDate = _parseDate(expiresStr);
    if (expiresDate == null) return false;

    final now = DateTime.now();

    // Check if not expired
    if (now.isBefore(expiresDate)) {
      return true;
    }

    // Check grace period
    final gracePeriodStr = entitlement['grace_period_expires_date'] as String?;
    if (gracePeriodStr != null) {
      final gracePeriod = _parseDate(gracePeriodStr);
      if (gracePeriod != null && now.isBefore(gracePeriod)) {
        return true;
      }
    }

    return false;
  }

  /// Determine subscription status
  SubscriptionStatus _determineStatus({
    required DateTime? expiryDate,
    required DateTime? gracePeriodExpires,
    required Map<String, dynamic>? subscriptions,
    required String? productId,
  }) {
    if (expiryDate == null) return SubscriptionStatus.none;

    final now = DateTime.now();

    // Check grace period
    if (now.isAfter(expiryDate)) {
      if (gracePeriodExpires != null && now.isBefore(gracePeriodExpires)) {
        return SubscriptionStatus.gracePeriod;
      }
      return SubscriptionStatus.expired;
    }

    // Check trial
    if (_isInTrial(subscriptions, productId)) {
      return SubscriptionStatus.trial;
    }

    // Check auto-renew
    if (!_checkAutoRenew(subscriptions, productId)) {
      return SubscriptionStatus.cancelled;
    }

    return SubscriptionStatus.active;
  }

  /// Check if currently in trial
  bool _isInTrial(Map<String, dynamic>? subscriptions, String? productId) {
    if (subscriptions == null || productId == null) return false;

    for (final entry in subscriptions.entries) {
      final sub = entry.value as Map<String, dynamic>?;
      if (sub == null) continue;

      final subProductId = sub['product_identifier'] as String?;
      if (subProductId == productId) {
        return sub['period_type'] == 'trial';
      }
    }

    return false;
  }

  /// Check if subscription will auto-renew
  bool _checkAutoRenew(Map<String, dynamic>? subscriptions, String? productId) {
    if (subscriptions == null || productId == null) return true;

    for (final entry in subscriptions.entries) {
      final sub = entry.value as Map<String, dynamic>?;
      if (sub == null) continue;

      final subProductId = sub['product_identifier'] as String?;
      if (subProductId == productId) {
        // If unsubscribe_detected_at exists, auto-renew is off
        return sub['unsubscribe_detected_at'] == null;
      }
    }

    return true;
  }

  /// Detect pending subscription changes (deferred downgrades)
  Map<String, dynamic> _detectPendingChanges({
    required Map<String, dynamic>? entitlements,
    required Map<String, dynamic>? subscriptions,
    required String? currentProductId,
  }) {
    if (subscriptions == null || currentProductId == null) {
      return {'tier': null, 'productId': null};
    }

    // Look for subscription entries that are different from current
    // and will become active in the future
    for (final entry in subscriptions.entries) {
      final sub = entry.value as Map<String, dynamic>?;
      if (sub == null) continue;

      final subProductId = sub['product_identifier'] as String?;

      // Skip current product
      if (subProductId == currentProductId) continue;
      if (subProductId == null) continue;

      // Check if this subscription is pending (has future purchase date)
      // Or check entitlements for this product
      final litePending = entitlements?['lite'] as Map<String, dynamic>?;
      final standardPending =
          entitlements?['standard'] as Map<String, dynamic>?;

      // If there's an entitlement for a different product, it might be pending
      if (subProductId.contains('lite') && litePending != null) {
        final liteProductId = litePending['product_identifier'] as String?;
        if (liteProductId != currentProductId) {
          return {
            'tier': SubscriptionTier.lite,
            'productId': liteProductId,
          };
        }
      }

      if (subProductId.contains('standard') && standardPending != null) {
        final standardProductId =
            standardPending['product_identifier'] as String?;
        if (standardProductId != currentProductId) {
          return {
            'tier': SubscriptionTier.standard,
            'productId': standardProductId,
          };
        }
      }
    }

    return {'tier': null, 'productId': null};
  }

  /// Extract trial information
  Map<String, dynamic> _extractTrialInfo(
      Map<String, dynamic>? subscriptions, String? productId) {
    bool trialUsed = false;
    DateTime? trialEndDate;

    if (subscriptions != null) {
      for (final entry in subscriptions.entries) {
        final sub = entry.value as Map<String, dynamic>?;
        if (sub == null) continue;

        // Any subscription history means trial was used
        if (sub['original_purchase_date'] != null) {
          trialUsed = true;
        }

        // Check if currently in trial
        final subProductId = sub['product_identifier'] as String?;
        if (subProductId == productId && sub['period_type'] == 'trial') {
          trialEndDate = _parseDate(sub['expires_date'] as String?);
        }
      }
    }

    return {
      'trialUsed': trialUsed,
      'trialEndDate': trialEndDate,
    };
  }

  /// Build free subscription from Extension data
  SubscriptionModel _buildFreeFromData(Map<String, dynamic> data) {
    final subscriptions = data['subscriptions'] as Map<String, dynamic>?;
    final trialUsed = subscriptions != null && subscriptions.isNotEmpty;

    return SubscriptionModel.free().copyWith(trialUsed: trialUsed);
  }

  /// Parse ISO date string
  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    return DateTime.tryParse(dateStr);
  }

  // ============================================================
  // REAL-TIME LISTENER (Extension Stream)
  // ============================================================

  /// Start listening to Extension data changes
  void _startExtensionListener(String userId) {
    _stopExtensionListener();

    _extensionSubscription = _firestore
        .collection('revenuecat_customers')
        .doc(userId)
        .snapshots()
        .listen(
      (snapshot) {
        if (!snapshot.exists || snapshot.data() == null) {
          return;
        }

        final newSubscription = _parseExtensionData(snapshot.data()!, userId);

        // Only update if something meaningful changed
        if (_hasSubscriptionChanged(newSubscription)) {
          debugPrint(
              '🔔 [SubscriptionProvider] Real-time update: ${newSubscription.tier}');

          _subscription = newSubscription;
          notifyListeners();
        }
      },
      onError: (error) {
        debugPrint('❌ [SubscriptionProvider] Stream error: $error');
      },
    );

    debugPrint('🎧 [SubscriptionProvider] Extension listener started');
  }

  /// Stop Extension listener
  void _stopExtensionListener() {
    _extensionSubscription?.cancel();
    _extensionSubscription = null;
  }

  /// Check if subscription has meaningfully changed
  bool _hasSubscriptionChanged(SubscriptionModel newSub) {
    return _subscription.tier != newSub.tier ||
        _subscription.status != newSub.status ||
        _subscription.productId != newSub.productId ||
        _subscription.isActive != newSub.isActive ||
        _subscription.pendingTier != newSub.pendingTier ||
        _subscription.autoRenew != newSub.autoRenew;
  }

  // ============================================================
  // FALLBACK TIMER (Edge Case Handling)
  // ============================================================

  void _startFallbackTimer() {
    _stopFallbackTimer();

    _fallbackTimer = Timer.periodic(_fallbackInterval, (_) {
      if (_isInitialized && _currentUserId != null) {
        _fallbackRefresh();
      }
    });
  }

  void _stopFallbackTimer() {
    _fallbackTimer?.cancel();
    _fallbackTimer = null;
  }

  /// Fallback refresh from SDK (for edge cases)
  Future<void> _fallbackRefresh() async {
    if (_currentUserId == null) return;

    try {
      final verified =
          await _subscriptionService.verifySubscription(forceRefresh: true);

      if (verified != null && _hasSubscriptionChanged(verified)) {
        debugPrint('🔄 [SubscriptionProvider] Fallback detected change');

        // Preserve pending info from current state
        _subscription = verified.copyWith(
          pendingTier: _subscription.pendingTier,
          pendingProductId: _subscription.pendingProductId,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('⚠️ [SubscriptionProvider] Fallback error: $e');
    }
  }

  // ============================================================
  // PACKAGES
  // ============================================================

  /// Load available packages
  Future<void> _loadPackages() async {
    try {
      _availablePackages = await _subscriptionService.getAvailablePackages();
      debugPrint(
          '📦 [SubscriptionProvider] ${_availablePackages.length} packages');
    } catch (e) {
      debugPrint('❌ [SubscriptionProvider] Package error: $e');
      _availablePackages = SubscriptionPackage.getDefaultPackages();
    }
  }

  // ============================================================
  // PURCHASE METHODS
  // ============================================================

  /// Purchase a subscription package
  Future<bool> purchase(SubscriptionPackage package) async {
    _setLoading(true);
    _error = null;

    try {
      debugPrint('💳 [SubscriptionProvider] Purchasing: ${package.productId}');
      debugPrint(
          '📋 [SubscriptionProvider] Current subscription: ${_subscription.tier}, productId: ${_subscription.productId}');

      final success = await _subscriptionService.purchase(
        package,
        currentSubscription:
            _subscription.productId != null ? _subscription : null,
      );

      if (success) {
        debugPrint('✅ [SubscriptionProvider] Purchase successful');

        // Extension will update via webhook
        // Also do immediate SDK refresh for instant feedback
        await Future.delayed(const Duration(milliseconds: 500));
        await _fallbackRefresh();
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
        debugPrint('✅ [SubscriptionProvider] Restore successful');
        await _fallbackRefresh();
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
  bool canPlaySession(Map<String, dynamic> sessionData) {
    final isDemo = sessionData['isDemo'] as bool? ?? false;
    if (isDemo) return true;
    return canPlayAudio;
  }

  /// Check if user can download a specific session
  bool canDownloadSession(Map<String, dynamic> sessionData) {
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
  // ADMIN METHODS
  // ============================================================

  /// Grant subscription manually (admin only)
  Future<bool> grantSubscription({
    required String userId,
    required SubscriptionTier tier,
    required int durationDays,
    SubscriptionPeriod period = SubscriptionPeriod.monthly,
  }) async {
    try {
      debugPrint('👑 [SubscriptionProvider] Granting $tier to $userId');

      final now = DateTime.now();
      final expiryDate = now.add(Duration(days: durationDays));

      await _firestore.collection('users').doc(userId).update({
        'subscription': {
          'tier': tier.value,
          'period': period.value,
          'status': 'active',
          'source': 'admin',
          'startDate': Timestamp.fromDate(now),
          'expiryDate': Timestamp.fromDate(expiryDate),
          'trialUsed': true,
          'autoRenew': false,
        },
      });

      if (userId == _auth.currentUser?.uid) {
        await _loadFromExtension(userId);
        notifyListeners();
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
      debugPrint('🚫 [SubscriptionProvider] Revoking for $userId');

      await _firestore.collection('users').doc(userId).update({
        'subscription.tier': 'free',
        'subscription.status': 'none',
        'subscription.autoRenew': false,
      });

      if (userId == _auth.currentUser?.uid) {
        _subscription = SubscriptionModel.free();
        notifyListeners();
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

  /// Manual refresh
  Future<void> refresh() async {
    if (_currentUserId == null) return;

    await _loadFromExtension(_currentUserId!);
    await _loadPackages();
    notifyListeners();
  }

  // ============================================================
  // LIFECYCLE
  // ============================================================

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isInitialized) {
      debugPrint('📱 [SubscriptionProvider] App resumed');
      _fallbackRefresh();
    }
  }

  @override
  void dispose() {
    _stopExtensionListener();
    _stopFallbackTimer();
    WidgetsBinding.instance.removeObserver(this);
    _authSubscription?.cancel();
    super.dispose();
  }
}
