// lib/services/subscription/subscription_service.dart

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/subscription_model.dart';
import '../../models/subscription_package.dart';
import '../../core/constants/subscription_constants.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service for handling subscription operations
///
/// Currently uses mock data for development.
/// Will integrate with RevenueCat when SDK is added.
///
/// Responsibilities:
/// - Fetch available packages from store
/// - Handle purchase flow
/// - Verify receipts
/// - Restore purchases
class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isInitialized = false;
  String? _currentUserId;

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  // ============================================================
  // INITIALIZATION
  // ============================================================

  /// Initialize service for a user
  Future<void> initialize(String userId) async {
    if (_isInitialized && _currentUserId == userId) return;

    debugPrint('🔧 [SubscriptionService] Initializing for user: $userId');

    _currentUserId = userId;

    // TODO: Initialize RevenueCat here when SDK is added
    // await Purchases.configure(PurchasesConfiguration(apiKey));
    // await Purchases.logIn(userId);

    _isInitialized = true;
    debugPrint('✅ [SubscriptionService] Initialized');
  }

  /// Reset service state
  Future<void> reset() async {
    debugPrint('🔄 [SubscriptionService] Resetting');

    // TODO: Logout from RevenueCat
    // await Purchases.logOut();

    _isInitialized = false;
    _currentUserId = null;
  }

  // ============================================================
  // PACKAGES
  // ============================================================

  /// Get available subscription packages
  /// Returns packages from RevenueCat offerings or mock data
  Future<List<SubscriptionPackage>> getAvailablePackages() async {
    debugPrint('📦 [SubscriptionService] Fetching available packages');

    // TODO: Fetch from RevenueCat when SDK is added
    // final offerings = await Purchases.getOfferings();
    // final current = offerings.current;
    // if (current != null) {
    //   return current.availablePackages.map((p) => _mapPackage(p)).toList();
    // }

    // Return mock packages for now
    return _getMockPackages();
  }

  /// Get mock packages for development
  List<SubscriptionPackage> _getMockPackages() {
    return [
      SubscriptionPackage.liteMonthly(),
      SubscriptionPackage.standardMonthly(),
      SubscriptionPackage.standardYearly(),
    ];
  }

  // ============================================================
  // PURCHASE
  // ============================================================

  /// Purchase a subscription package
  /// Returns true if successful
  Future<bool> purchase(SubscriptionPackage package) async {
    debugPrint('💳 [SubscriptionService] Purchasing: ${package.productId}');

    final userId = _currentUserId ?? FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      debugPrint('❌ [SubscriptionService] No user ID');
      return false;
    }

    // TODO: Implement actual purchase with RevenueCat
    // try {
    //   final customerInfo = await Purchases.purchasePackage(package);
    //   return customerInfo.entitlements.active.isNotEmpty;
    // } catch (e) {
    //   debugPrint('❌ Purchase error: $e');
    //   return false;
    // }
    _currentUserId = userId;
    // Mock purchase for development
    return _mockPurchase(package);
  }

  /// Mock purchase for development/testing
  Future<bool> _mockPurchase(SubscriptionPackage package) async {
    debugPrint('🧪 [SubscriptionService] Mock purchase: ${package.productId}');

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    final now = DateTime.now();
    final trialEnd =
        now.add(Duration(days: SubscriptionConstants.trialDurationDays));

    // Calculate expiry based on period
    final Duration subscriptionDuration;
    if (package.period == SubscriptionPeriod.yearly) {
      subscriptionDuration = const Duration(days: 365);
    } else {
      subscriptionDuration = const Duration(days: 30);
    }

    final expiryDate = trialEnd.add(subscriptionDuration);

    final subscription = SubscriptionModel(
      tier: package.tier,
      period: package.period,
      status: package.hasTrial
          ? SubscriptionStatus.trial
          : SubscriptionStatus.active,
      source: SubscriptionSource.revenuecat,
      startDate: now,
      expiryDate: expiryDate,
      trialEndDate: package.hasTrial ? trialEnd : null,
      trialUsed: true,
      autoRenew: true,
      productId: package.productId,
      lastVerifiedAt: now,
    );

    // Save to Firestore
    try {
      await _firestore.collection('users').doc(_currentUserId).update({
        'subscription': subscription.toMap(),
      });

      debugPrint('✅ [SubscriptionService] Mock purchase saved');
      return true;
    } catch (e) {
      debugPrint('❌ [SubscriptionService] Error saving subscription: $e');
      return false;
    }
  }

  // ============================================================
  // RESTORE
  // ============================================================

  /// Restore previous purchases
  Future<bool> restorePurchases() async {
    debugPrint('🔄 [SubscriptionService] Restoring purchases');

    if (_currentUserId == null) {
      debugPrint('❌ [SubscriptionService] No user ID');
      return false;
    }

    // TODO: Implement with RevenueCat
    // try {
    //   final customerInfo = await Purchases.restorePurchases();
    //   return customerInfo.entitlements.active.isNotEmpty;
    // } catch (e) {
    //   debugPrint('❌ Restore error: $e');
    //   return false;
    // }

    // Mock restore - just return current state
    debugPrint('🧪 [SubscriptionService] Mock restore completed');
    return true;
  }

  // ============================================================
  // VERIFICATION
  // ============================================================

  /// Verify current subscription status with store
  Future<SubscriptionModel?> verifySubscription() async {
    debugPrint('🔍 [SubscriptionService] Verifying subscription');

    if (_currentUserId == null) return null;

    // TODO: Implement with RevenueCat
    // final customerInfo = await Purchases.getCustomerInfo();
    // return _mapCustomerInfo(customerInfo);

    // For now, return from Firestore
    try {
      final doc =
          await _firestore.collection('users').doc(_currentUserId).get();
      final data = doc.data()?['subscription'] as Map<String, dynamic>?;
      return SubscriptionModel.fromMap(data);
    } catch (e) {
      debugPrint('❌ [SubscriptionService] Verify error: $e');
      return null;
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  /// Check if a product ID grants a specific entitlement
  SubscriptionTier getTierForProduct(String productId) {
    switch (productId) {
      case SubscriptionConstants.productLiteMonthly:
        return SubscriptionTier.lite;
      case SubscriptionConstants.productStandardMonthly:
      case SubscriptionConstants.productStandardYearly:
        return SubscriptionTier.standard;
      default:
        return SubscriptionTier.free;
    }
  }
}
