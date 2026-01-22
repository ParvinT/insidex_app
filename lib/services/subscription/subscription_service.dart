// lib/services/subscription/subscription_service.dart
//
// Simplified Subscription Service
// Only handles purchase operations - RevenueCat Firebase Extension handles data sync
//
// Responsibilities:
// - Initialize RevenueCat SDK
// - Fetch available packages
// - Handle purchase flow (including upgrade/downgrade) for iOS & Android
// - Restore purchases
// - Verify subscription from SDK (fallback only)
//
// NOT responsible for (Extension handles these):
// - Firestore sync
// - Pending subscription tracking
// - Real-time updates

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../models/subscription_model.dart';
import '../../models/subscription_package.dart';
import '../../core/constants/subscription_constants.dart';

/// Service for handling subscription purchase operations
///
/// This is a simplified service that only handles RevenueCat SDK operations.
/// All data sync is handled automatically by RevenueCat Firebase Extension.
class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  bool _isInitialized = false;
  String? _currentUserId;

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  // ============================================================
  // INITIALIZATION
  // ============================================================

  /// Initialize RevenueCat SDK for a user
  Future<void> initialize(String userId) async {
    if (_isInitialized && _currentUserId == userId) return;

    debugPrint('🔧 [SubscriptionService] Initializing for: $userId');

    _currentUserId = userId;

    // Get platform-specific API key
    final apiKey = Platform.isIOS
        ? SubscriptionConstants.revenueCatApiKeyIOS
        : SubscriptionConstants.revenueCatApiKeyAndroid;

    // Configure RevenueCat
    final configuration = PurchasesConfiguration(apiKey)..appUserID = userId;

    await Purchases.configure(configuration);

    // Enable debug logs in development
    if (kDebugMode) {
      await Purchases.setLogLevel(LogLevel.debug);
    }

    _isInitialized = true;
    debugPrint('✅ [SubscriptionService] RevenueCat SDK ready');
  }

  /// Reset service state
  Future<void> reset() async {
    debugPrint('🔄 [SubscriptionService] Resetting');

    try {
      await Purchases.logOut();
    } catch (e) {
      debugPrint('⚠️ [SubscriptionService] Logout warning: $e');
    }

    _isInitialized = false;
    _currentUserId = null;
  }

  // ============================================================
  // PACKAGES
  // ============================================================

  /// Get available subscription packages from RevenueCat
  Future<List<SubscriptionPackage>> getAvailablePackages() async {
    debugPrint('📦 [SubscriptionService] Fetching packages');

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

      debugPrint('⚠️ [SubscriptionService] No offerings, using defaults');
      return SubscriptionPackage.getDefaultPackages();
    } catch (e) {
      debugPrint('❌ [SubscriptionService] Package error: $e');
      return SubscriptionPackage.getDefaultPackages();
    }
  }

  /// Map RevenueCat package to our model
  SubscriptionPackage _mapRevenueCatPackage(Package rcPackage) {
    final product = rcPackage.storeProduct;
    final productId = product.identifier;

    // Determine tier
    SubscriptionTier tier;
    if (productId.contains('lite')) {
      tier = SubscriptionTier.lite;
    } else if (productId.contains('standard')) {
      tier = SubscriptionTier.standard;
    } else {
      tier = SubscriptionTier.free;
    }

    // Determine period
    SubscriptionPeriod period;
    if (productId.contains('yearly') ||
        rcPackage.packageType == PackageType.annual) {
      period = SubscriptionPeriod.yearly;
    } else {
      period = SubscriptionPeriod.monthly;
    }

    // Check for free trial
    final hasTrial = product.introductoryPrice != null &&
        product.introductoryPrice!.price == 0;

    final trialDays = hasTrial ? _getTrialDays(product.introductoryPrice!) : 0;

    // Calculate savings for yearly
    int? savingsPercent;
    double? monthlyEquivalent;

    if (period == SubscriptionPeriod.yearly) {
      monthlyEquivalent = product.price / 12;
      if (tier == SubscriptionTier.standard) {
        const monthlyPrice = SubscriptionConstants.priceStandardMonthly;
        final yearlyMonthly = product.price / 12;
        savingsPercent =
            (((monthlyPrice - yearlyMonthly) / monthlyPrice) * 100).round();
      }
    }

    return SubscriptionPackage(
      productId: productId,
      tier: tier,
      period: period,
      price: product.price,
      localizedPrice: product.priceString,
      currencyCode: product.currencyCode,
      hasTrial: hasTrial,
      trialDays: trialDays,
      isHighlighted: productId == SubscriptionConstants.productStandardMonthly,
      savingsPercent: savingsPercent,
      monthlyEquivalent: monthlyEquivalent,
    );
  }

  /// Get trial days from introductory price
  int _getTrialDays(IntroductoryPrice intro) {
    final periodUnit = intro.periodUnit;
    final periodCount = intro.periodNumberOfUnits;

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
  // PURCHASE (iOS & Android)
  // ============================================================

  /// Purchase a subscription package
  /// Handles both new purchases and upgrades/downgrades for iOS & Android
  Future<bool> purchase(SubscriptionPackage package, {SubscriptionModel? currentSubscription}) async {
    debugPrint('💳 [SubscriptionService] Purchasing: ${package.productId}');

    if (_currentUserId == null) {
      debugPrint('❌ [SubscriptionService] No user ID');
      return false;
    }

    try {
      // Get current subscription to determine upgrade/downgrade
      //final currentSubscription = await verifySubscription();

      // Get RevenueCat offerings
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;

      if (current == null) {
        debugPrint('❌ [SubscriptionService] No offerings');
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

        // Don't allow purchasing the same product
        if (currentProductId == package.productId) {
          debugPrint(
              '⚠️ [SubscriptionService] Already subscribed to this plan');
          return false;
        }

        debugPrint(
            '🔄 [SubscriptionService] Plan change: $currentProductId → ${package.productId}');

        // Determine if this is an upgrade or downgrade
        final isUpgrade = _isUpgrade(
          currentTier: currentSubscription.tier,
          currentPeriod: currentSubscription.period,
          newTier: package.tier,
          newPeriod: package.period,
        );

        // Platform-specific handling
        if (Platform.isAndroid) {
          // Android: Use GoogleProductChangeInfo with proration mode
          final prorationMode = isUpgrade
              ? GoogleProrationMode.immediateWithTimeProration
              : GoogleProrationMode.deferred;

          debugPrint(
              '📊 [SubscriptionService] Android proration: ${prorationMode.name} (isUpgrade: $isUpgrade)');

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
          // iOS: Handles upgrades/downgrades automatically
          debugPrint('📊 [SubscriptionService] iOS automatic plan change');

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

      // Check if entitlements are active
      final hasLite = customerInfo.entitlements.active
          .containsKey(SubscriptionConstants.entitlementLite);
      final hasStandard = customerInfo.entitlements.active
          .containsKey(SubscriptionConstants.entitlementStandard);

      if (hasLite || hasStandard) {
        debugPrint('✅ [SubscriptionService] Purchase successful');
        return true;
      }

      debugPrint(
          '⚠️ [SubscriptionService] Purchase completed but no entitlements');
      return false;
    } on PlatformException catch (e) {
      if (_isPurchaseCancelled(e)) {
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

  /// Check if plan change is an upgrade
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

  /// Check if error is purchase cancellation
  bool _isPurchaseCancelled(PlatformException e) {
    return e.code == '1' ||
        e.message?.toLowerCase().contains('cancel') == true ||
        e.message?.toLowerCase().contains('cancelled') == true;
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

      final hasEntitlements = customerInfo.entitlements.active.isNotEmpty;

      if (hasEntitlements) {
        debugPrint('✅ [SubscriptionService] Restore successful');
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
  // VERIFICATION (Fallback - Primary source is Extension)
  // ============================================================

  /// Verify current subscription from RevenueCat SDK
  /// This is a FALLBACK - primary data comes from Firebase Extension
  Future<SubscriptionModel?> verifySubscription(
      {bool forceRefresh = false}) async {
    debugPrint('🔍 [SubscriptionService] Verifying (fallback)');

    if (_currentUserId == null) return null;

    try {
      if (forceRefresh) {
        await Purchases.invalidateCustomerInfoCache();
      }

      final customerInfo = await Purchases.getCustomerInfo();
      return _mapCustomerInfoToSubscription(customerInfo);
    } catch (e) {
      debugPrint('❌ [SubscriptionService] Verify error: $e');
      return null;
    }
  }

  /// Map RevenueCat CustomerInfo to SubscriptionModel
  SubscriptionModel _mapCustomerInfoToSubscription(CustomerInfo customerInfo) {
    final entitlements = customerInfo.entitlements.active;

    if (entitlements.isEmpty) {
      debugPrint('📋 [SubscriptionService] No active entitlements');
      return SubscriptionModel.free();
    }

    // Determine tier (priority: standard > lite)
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
      debugPrint('📋 [SubscriptionService] Unknown entitlement');
      return SubscriptionModel.free();
    }

    if (activeEntitlement == null) {
      return SubscriptionModel.free();
    }

    // Parse details
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

    // Parse dates
    DateTime? startDate;
    DateTime? expiryDate;
    DateTime? trialEndDate;

    final originalPurchaseDateStr = activeEntitlement.originalPurchaseDate;
    final expirationDateStr = activeEntitlement.expirationDate;

    if (originalPurchaseDateStr.isNotEmpty) {
      startDate = DateTime.tryParse(originalPurchaseDateStr) ?? DateTime.now();
    }

    if (expirationDateStr != null && expirationDateStr.isNotEmpty) {
      expiryDate = DateTime.tryParse(expirationDateStr);
    }

    if (activeEntitlement.periodType == PeriodType.trial &&
        expirationDateStr != null) {
      trialEndDate = DateTime.tryParse(expirationDateStr);
    }

    debugPrint('📋 [SubscriptionService] Mapped: tier=$tier, status=$status');

    return SubscriptionModel(
      tier: tier,
      period: period,
      status: status,
      source: SubscriptionSource.revenuecat,
      startDate: startDate,
      expiryDate: expiryDate,
      trialEndDate: trialEndDate,
      trialUsed: activeEntitlement.periodType != PeriodType.trial,
      autoRenew: activeEntitlement.willRenew,
      productId: productId,
      lastVerifiedAt: DateTime.now(),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  /// Get tier for a product ID
  SubscriptionTier getTierForProduct(String productId) {
    if (productId.contains('lite')) {
      return SubscriptionTier.lite;
    } else if (productId.contains('standard')) {
      return SubscriptionTier.standard;
    }
    return SubscriptionTier.free;
  }
}
