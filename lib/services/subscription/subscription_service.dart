// lib/services/subscription/subscription_service.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io' show Platform;
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../models/subscription_model.dart';
import '../../models/subscription_package.dart';
import '../../core/constants/subscription_constants.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service for handling subscription operations
///
/// Integrates with RevenueCat for in-app purchases.
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

  // Callback for subscription changes
  void Function(SubscriptionModel)? _onSubscriptionChanged;
  bool _listenerActive = false;

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

    // Configure RevenueCat
    final apiKey = Platform.isIOS
        ? SubscriptionConstants.revenueCatApiKeyIOS
        : SubscriptionConstants.revenueCatApiKeyAndroid;

    final configuration = PurchasesConfiguration(apiKey)..appUserID = userId;

    await Purchases.configure(configuration);

    // Enable debug logs in development
    if (kDebugMode) {
      await Purchases.setLogLevel(LogLevel.debug);
    }

    debugPrint(
        '✅ [SubscriptionService] RevenueCat configured for user: $userId');

    _setupCustomerInfoListener();

    _isInitialized = true;
  }

  /// Reset service state
  Future<void> reset() async {
    debugPrint('🔄 [SubscriptionService] Resetting');

    _removeCustomerInfoListener();

    try {
      await Purchases.logOut();
    } catch (e) {
      debugPrint('⚠️ [SubscriptionService] RevenueCat logout error: $e');
    }

    _isInitialized = false;
    _currentUserId = null;
    _onSubscriptionChanged = null;
  }

  // ============================================================
  // LISTENER MANAGEMENT
  // ============================================================

  /// Set callback for subscription changes (called by Provider)
  void setSubscriptionListener(void Function(SubscriptionModel)? callback) {
    _onSubscriptionChanged = callback;
    debugPrint(
        '🎧 [SubscriptionService] Subscription listener ${callback != null ? "set" : "removed"}');
  }

  /// Setup RevenueCat CustomerInfo listener
  void _setupCustomerInfoListener() {
    if (_listenerActive) return;

    Purchases.addCustomerInfoUpdateListener(_onCustomerInfoUpdated);
    _listenerActive = true;
    debugPrint('🎧 [SubscriptionService] CustomerInfo listener activated');
  }

  /// Remove RevenueCat CustomerInfo listener
  void _removeCustomerInfoListener() {
    if (!_listenerActive) return;

    Purchases.removeCustomerInfoUpdateListener(_onCustomerInfoUpdated);
    _listenerActive = false;
    debugPrint('🎧 [SubscriptionService] CustomerInfo listener removed');
  }

  /// Called when RevenueCat detects subscription changes
  void _onCustomerInfoUpdated(CustomerInfo customerInfo) {
    debugPrint('🔔 [SubscriptionService] CustomerInfo updated from RevenueCat');

    final subscription = _mapCustomerInfoToSubscription(customerInfo);

    debugPrint(
        '🔔 [SubscriptionService] New subscription state: ${subscription.tier} - ${subscription.status}');

    // Sync to Firestore
    _syncSubscriptionToFirestore(customerInfo);

    // Notify provider
    if (_onSubscriptionChanged != null) {
      _onSubscriptionChanged!(subscription);
    }
  }

  // ============================================================
  // PACKAGES
  // ============================================================

  /// Get available subscription packages
  /// Returns packages from RevenueCat offerings or mock data
  Future<List<SubscriptionPackage>> getAvailablePackages() async {
    debugPrint('📦 [SubscriptionService] Fetching available packages');

    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;

      if (current != null && current.availablePackages.isNotEmpty) {
        debugPrint(
            '✅ [SubscriptionService] Found ${current.availablePackages.length} packages');
        return current.availablePackages
            .map((p) => _mapRevenueCatPackage(p))
            .toList();
      }

      debugPrint('⚠️ [SubscriptionService] No offerings found, using defaults');
      return _getMockPackages();
    } catch (e) {
      debugPrint('❌ [SubscriptionService] Error fetching packages: $e');
      return _getMockPackages();
    }
  }

  /// Get mock packages for development
  List<SubscriptionPackage> _getMockPackages() {
    return [
      SubscriptionPackage.liteMonthly(),
      SubscriptionPackage.standardMonthly(),
      SubscriptionPackage.standardYearly(),
    ];
  }

  /// Map RevenueCat package to our SubscriptionPackage model
  SubscriptionPackage _mapRevenueCatPackage(Package rcPackage) {
    final product = rcPackage.storeProduct;
    final productId = product.identifier;

    // Determine tier from product ID
    SubscriptionTier tier;
    if (productId.contains('lite')) {
      tier = SubscriptionTier.lite;
    } else if (productId.contains('standard')) {
      tier = SubscriptionTier.standard;
    } else {
      tier = SubscriptionTier.free;
    }

    // Determine period from package type or product ID
    SubscriptionPeriod period;
    if (productId.contains('yearly') ||
        rcPackage.packageType == PackageType.annual) {
      period = SubscriptionPeriod.yearly;
    } else {
      period = SubscriptionPeriod.monthly;
    }

    // Check for introductory offer (free trial)
    final hasFreeTrial = product.introductoryPrice != null &&
        product.introductoryPrice!.price == 0;

    final trialDays =
        hasFreeTrial ? _getTrialDays(product.introductoryPrice!) : 0;

    // Calculate savings for yearly
    int? savingsPercent;
    double? monthlyEquivalent;
    if (period == SubscriptionPeriod.yearly) {
      savingsPercent = SubscriptionConstants.yearlySavingsPercent;
      monthlyEquivalent = product.price / 12;
    }

    return SubscriptionPackage(
      productId: productId,
      tier: tier,
      period: period,
      price: product.price,
      currencyCode: product.currencyCode,
      localizedPrice: product.priceString,
      hasTrial: hasFreeTrial,
      trialDays: trialDays,
      isHighlighted: productId == SubscriptionConstants.productStandardMonthly,
      savingsPercent: savingsPercent,
      monthlyEquivalent: monthlyEquivalent,
    );
  }

  /// Extract trial days from introductory price
  int _getTrialDays(IntroductoryPrice introPrice) {
    final periodUnit = introPrice.periodUnit;
    final periodCount = introPrice.periodNumberOfUnits;

    switch (periodUnit) {
      case PeriodUnit.day:
        return periodCount;
      case PeriodUnit.week:
        return periodCount * 7;
      case PeriodUnit.month:
        return periodCount * 30;
      case PeriodUnit.year:
        return periodCount * 365;
      default:
        return 7;
    }
  }

  // ============================================================
  // PURCHASE
  // ============================================================

  /// Purchase a subscription package
  /// Handles new purchases, upgrades, and downgrades
  Future<bool> purchase(SubscriptionPackage package) async {
    debugPrint('💳 [SubscriptionService] Purchasing: ${package.productId}');

    final userId = _currentUserId ?? FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      debugPrint('❌ [SubscriptionService] No user ID');
      return false;
    }

    _currentUserId = userId;

    try {
      // Get current subscription to check if this is an upgrade/downgrade
      final currentSubscription = await verifySubscription();

      // Get the RevenueCat package
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;

      if (current == null) {
        debugPrint('❌ [SubscriptionService] No offerings available');
        return false;
      }

      // Find matching package
      final rcPackage = current.availablePackages.firstWhere(
        (p) => p.storeProduct.identifier == package.productId,
        orElse: () =>
            throw Exception('Package not found: ${package.productId}'),
      );

      CustomerInfo customerInfo;

      // Check if user has active subscription (upgrade/downgrade scenario)
      if (currentSubscription != null &&
          currentSubscription.isActive &&
          currentSubscription.productId != null) {
        final currentProductId = currentSubscription.productId!;

        // Don't allow purchasing the exact same product
        if (currentProductId == package.productId) {
          debugPrint(
              '⚠️ [SubscriptionService] Already subscribed to this plan');
          return false;
        }

        debugPrint(
            '🔄 [SubscriptionService] Upgrading/Downgrading from $currentProductId to ${package.productId}');

        // Determine proration mode based on upgrade vs downgrade
        final prorationMode = _getProrationMode(
          currentTier: currentSubscription.tier,
          currentPeriod: currentSubscription.period,
          newTier: package.tier,
          newPeriod: package.period,
        );

        debugPrint(
            '📊 [SubscriptionService] Using proration mode: $prorationMode');

        // For Android: Use GoogleProductChangeInfo for upgrade/downgrade
        if (Platform.isAndroid) {
          final googleProductChangeInfo = GoogleProductChangeInfo(
            currentProductId,
            prorationMode: prorationMode,
          );

          final purchaseParams = PurchaseParams.package(
            rcPackage,
            googleProductChangeInfo: googleProductChangeInfo,
          );

          final purchaseResult = await Purchases.purchase(purchaseParams);
          customerInfo = purchaseResult.customerInfo;
        } else {
          // iOS handles upgrades/downgrades automatically
          final purchaseParams = PurchaseParams.package(rcPackage);
          final purchaseResult = await Purchases.purchase(purchaseParams);
          customerInfo = purchaseResult.customerInfo;
        }
      } else {
        // New purchase (no active subscription)
        debugPrint('🆕 [SubscriptionService] New subscription purchase');

        final purchaseParams = PurchaseParams.package(rcPackage);
        final purchaseResult = await Purchases.purchase(purchaseParams);
        customerInfo = purchaseResult.customerInfo;
      }

      // Check if purchase was successful
      final hasLite = customerInfo.entitlements.active.containsKey(
        SubscriptionConstants.entitlementLite,
      );
      final hasStandard = customerInfo.entitlements.active.containsKey(
        SubscriptionConstants.entitlementStandard,
      );

      if (hasLite || hasStandard) {
        debugPrint('✅ [SubscriptionService] Purchase successful');
        await _syncSubscriptionToFirestore(customerInfo);
        return true;
      }

      debugPrint(
          '⚠️ [SubscriptionService] Purchase completed but no entitlements');
      return false;
    } on PlatformException catch (e) {
      // Handle user cancellation and other errors
      final errorCode = e.code;
      if (errorCode == '1' ||
          e.message?.toLowerCase().contains('cancel') == true ||
          e.message?.toLowerCase().contains('cancelled') == true) {
        debugPrint('ℹ️ [SubscriptionService] Purchase cancelled by user');
      } else {
        debugPrint('❌ [SubscriptionService] Purchase error: $e');
      }
      return false;
    } catch (e) {
      debugPrint('❌ [SubscriptionService] Purchase error: $e');
      return false;
    }
  }

  /// Determine the appropriate proration mode for upgrade/downgrade
  GoogleProrationMode _getProrationMode({
    required SubscriptionTier currentTier,
    required SubscriptionPeriod? currentPeriod,
    required SubscriptionTier newTier,
    required SubscriptionPeriod newPeriod,
  }) {
    // Upgrade: Lite → Standard, or Monthly → Yearly (same tier)
    final isUpgrade = _isUpgrade(
      currentTier: currentTier,
      currentPeriod: currentPeriod,
      newTier: newTier,
      newPeriod: newPeriod,
    );

    if (isUpgrade) {
      // Immediate upgrade with time proration (credit for unused time)
      return GoogleProrationMode.immediateWithTimeProration;
    } else {
      // Downgrade: takes effect at end of current billing period
      return GoogleProrationMode.deferred;
    }
  }

  /// Check if the plan change is an upgrade
  bool _isUpgrade({
    required SubscriptionTier currentTier,
    required SubscriptionPeriod? currentPeriod,
    required SubscriptionTier newTier,
    required SubscriptionPeriod newPeriod,
  }) {
    // Tier upgrade: Lite → Standard
    if (newTier == SubscriptionTier.standard &&
        currentTier == SubscriptionTier.lite) {
      return true;
    }

    // Period upgrade: Monthly → Yearly (same tier)
    if (newTier == currentTier &&
        newPeriod == SubscriptionPeriod.yearly &&
        currentPeriod == SubscriptionPeriod.monthly) {
      return true;
    }

    return false;
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

    try {
      final customerInfo = await Purchases.restorePurchases();

      final hasLite = customerInfo.entitlements.active.containsKey(
        SubscriptionConstants.entitlementLite,
      );
      final hasStandard = customerInfo.entitlements.active.containsKey(
        SubscriptionConstants.entitlementStandard,
      );

      if (hasLite || hasStandard) {
        debugPrint('✅ [SubscriptionService] Restore successful');
        await _syncSubscriptionToFirestore(customerInfo);
        return true;
      }

      debugPrint('ℹ️ [SubscriptionService] No purchases to restore');
      return false;
    } catch (e) {
      debugPrint('❌ [SubscriptionService] Restore error: $e');
      return false;
    }
  }

  // ============================================================
  // VERIFICATION
  // ============================================================

  /// Verify current subscription status with store
  Future<SubscriptionModel?> verifySubscription() async {
    debugPrint('🔍 [SubscriptionService] Verifying subscription');

    if (_currentUserId == null) return null;

    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return _mapCustomerInfoToSubscription(customerInfo);
    } catch (e) {
      debugPrint('❌ [SubscriptionService] Verify error: $e');
      // Fallback to Firestore
      try {
        final doc =
            await _firestore.collection('users').doc(_currentUserId).get();
        final data = doc.data()?['subscription'] as Map<String, dynamic>?;
        return SubscriptionModel.fromMap(data);
      } catch (_) {
        return null;
      }
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

  // ============================================================
  // REVENUECAT HELPERS
  // ============================================================

  /// Map RevenueCat CustomerInfo to our SubscriptionModel
  SubscriptionModel _mapCustomerInfoToSubscription(CustomerInfo customerInfo) {
    final entitlements = customerInfo.entitlements.active;

    // Check for pending (deferred) subscription changes
    SubscriptionTier? pendingTier;
    String? pendingProductId;

    // Parse ALL entitlements to detect pending changes
    final allEntitlements = customerInfo.entitlements.all;
    for (final entry in allEntitlements.entries) {
      final entitlement = entry.value;
      // If entitlement is not active but has a product pending
      if (!entitlement.isActive && entitlement.productIdentifier.isNotEmpty) {
        pendingProductId = entitlement.productIdentifier;
        pendingTier = getTierForProduct(pendingProductId);
        debugPrint(
            '📋 [SubscriptionService] Found pending subscription: $pendingProductId → $pendingTier');
      }
    }

    if (entitlements.isEmpty) {
      // No active subscription, but might have pending
      return SubscriptionModel.free().copyWith(
        pendingTier: pendingTier,
        pendingProductId: pendingProductId,
      );
    }

    // Check which entitlement is active
    SubscriptionTier tier;
    EntitlementInfo? activeEntitlement;

    if (entitlements.containsKey(SubscriptionConstants.entitlementStandard)) {
      tier = SubscriptionTier.standard;
      activeEntitlement =
          entitlements[SubscriptionConstants.entitlementStandard];
    } else if (entitlements
        .containsKey(SubscriptionConstants.entitlementLite)) {
      tier = SubscriptionTier.lite;
      activeEntitlement = entitlements[SubscriptionConstants.entitlementLite];
    } else {
      return SubscriptionModel.free().copyWith(
        pendingTier: pendingTier,
        pendingProductId: pendingProductId,
      );
    }

    if (activeEntitlement == null) {
      return SubscriptionModel.free().copyWith(
        pendingTier: pendingTier,
        pendingProductId: pendingProductId,
      );
    }

    // Determine period from product ID
    final productId = activeEntitlement.productIdentifier;
    final period = productId.contains('yearly')
        ? SubscriptionPeriod.yearly
        : SubscriptionPeriod.monthly;

    // Determine status
    SubscriptionStatus status;
    if (activeEntitlement.periodType == PeriodType.trial) {
      status = SubscriptionStatus.trial;
    } else if (activeEntitlement.willRenew) {
      status = SubscriptionStatus.active;
    } else {
      status = SubscriptionStatus.cancelled;
    }

    // Parse dates safely
    DateTime? startDate;
    DateTime? expiryDate;
    DateTime? trialEndDate;

    final originalPurchaseDateStr = activeEntitlement.originalPurchaseDate;
    final expirationDateStr = activeEntitlement.expirationDate;

    if (originalPurchaseDateStr.isNotEmpty) {
      try {
        startDate = DateTime.parse(originalPurchaseDateStr);
      } catch (_) {
        startDate = DateTime.now();
      }
    } else {
      startDate = DateTime.now();
    }

    if (expirationDateStr != null && expirationDateStr.isNotEmpty) {
      try {
        expiryDate = DateTime.parse(expirationDateStr);
      } catch (_) {
        expiryDate = null;
      }
    }

    if (activeEntitlement.periodType == PeriodType.trial &&
        expirationDateStr != null &&
        expirationDateStr.isNotEmpty) {
      try {
        trialEndDate = DateTime.parse(expirationDateStr);
      } catch (_) {
        trialEndDate = null;
      }
    }

    return SubscriptionModel(
      tier: tier,
      period: period,
      status: status,
      source: SubscriptionSource.revenuecat,
      startDate: startDate,
      expiryDate: expiryDate,
      trialEndDate: trialEndDate,
      trialUsed: customerInfo.nonSubscriptionTransactions.isNotEmpty ||
          activeEntitlement.periodType != PeriodType.trial,
      autoRenew: activeEntitlement.willRenew,
      originalTransactionId: originalPurchaseDateStr,
      lastVerifiedAt: DateTime.now(),
      productId: productId,
      pendingTier: pendingTier,
      pendingProductId: pendingProductId,
    );
  }

  /// Sync RevenueCat subscription data to Firestore
  Future<void> _syncSubscriptionToFirestore(CustomerInfo customerInfo) async {
    if (_currentUserId == null) return;

    try {
      final subscription = _mapCustomerInfoToSubscription(customerInfo);

      await _firestore.collection('users').doc(_currentUserId).update({
        'subscription': subscription.toMap(),
      });

      debugPrint('✅ [SubscriptionService] Subscription synced to Firestore');
    } catch (e) {
      debugPrint('❌ [SubscriptionService] Error syncing to Firestore: $e');
    }
  }
}
