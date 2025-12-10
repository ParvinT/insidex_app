// lib/models/subscription_package.dart

import '../core/constants/subscription_constants.dart';

/// Represents a purchasable subscription package
/// Used in paywall UI to display available options
class SubscriptionPackage {
  /// Unique product identifier
  final String productId;

  /// Subscription tier this package unlocks
  final SubscriptionTier tier;

  /// Billing period
  final SubscriptionPeriod period;

  /// Price in user's currency (from store)
  final double price;

  /// Currency code (USD, TRY, etc.)
  final String currencyCode;

  /// Localized price string from store (e.g., "$39.00")
  final String localizedPrice;

  /// Whether this package offers free trial
  final bool hasTrial;

  /// Trial duration in days
  final int trialDays;

  /// Whether this is the recommended/highlighted package
  final bool isHighlighted;

  /// Savings percentage compared to monthly (for yearly)
  final int? savingsPercent;

  /// Price per month (for yearly packages)
  final double? monthlyEquivalent;

  const SubscriptionPackage({
    required this.productId,
    required this.tier,
    required this.period,
    required this.price,
    required this.currencyCode,
    required this.localizedPrice,
    this.hasTrial = false,
    this.trialDays = 0,
    this.isHighlighted = false,
    this.savingsPercent,
    this.monthlyEquivalent,
  });

  /// Create Lite Monthly package
  factory SubscriptionPackage.liteMonthly({
    double? price,
    String? localizedPrice,
    String currencyCode = 'USD',
  }) {
    return SubscriptionPackage(
      productId: SubscriptionConstants.productLiteMonthly,
      tier: SubscriptionTier.lite,
      period: SubscriptionPeriod.monthly,
      price: price ?? SubscriptionConstants.priceLiteMonthly,
      currencyCode: currencyCode,
      localizedPrice: localizedPrice ??
          '\$${SubscriptionConstants.priceLiteMonthly.toStringAsFixed(0)}',
      hasTrial: true,
      trialDays: SubscriptionConstants.trialDurationDays,
      isHighlighted: false,
    );
  }

  /// Create Standard Monthly package
  factory SubscriptionPackage.standardMonthly({
    double? price,
    String? localizedPrice,
    String currencyCode = 'USD',
  }) {
    return SubscriptionPackage(
      productId: SubscriptionConstants.productStandardMonthly,
      tier: SubscriptionTier.standard,
      period: SubscriptionPeriod.monthly,
      price: price ?? SubscriptionConstants.priceStandardMonthly,
      currencyCode: currencyCode,
      localizedPrice: localizedPrice ??
          '\$${SubscriptionConstants.priceStandardMonthly.toStringAsFixed(0)}',
      hasTrial: true,
      trialDays: SubscriptionConstants.trialDurationDays,
      isHighlighted: true, // Most popular
    );
  }

  /// Create Standard Yearly package
  factory SubscriptionPackage.standardYearly({
    double? price,
    String? localizedPrice,
    String currencyCode = 'USD',
  }) {
    final yearlyPrice = price ?? SubscriptionConstants.priceStandardYearly;
    final monthlyEquivalent = yearlyPrice / 12;

    return SubscriptionPackage(
      productId: SubscriptionConstants.productStandardYearly,
      tier: SubscriptionTier.standard,
      period: SubscriptionPeriod.yearly,
      price: yearlyPrice,
      currencyCode: currencyCode,
      localizedPrice: localizedPrice ?? '\$${yearlyPrice.toStringAsFixed(0)}',
      hasTrial: true,
      trialDays: SubscriptionConstants.trialDurationDays,
      isHighlighted: false,
      savingsPercent: SubscriptionConstants.yearlySavingsPercent,
      monthlyEquivalent: monthlyEquivalent,
    );
  }

  /// Get default packages (for mock/testing)
  static List<SubscriptionPackage> getDefaultPackages() {
    return [
      SubscriptionPackage.liteMonthly(),
      SubscriptionPackage.standardMonthly(),
      SubscriptionPackage.standardYearly(),
    ];
  }

  // ============================================================
  // DISPLAY HELPERS
  // ============================================================

  /// Get package title for UI
  String get displayTitle {
    switch (tier) {
      case SubscriptionTier.lite:
        return 'Lite';
      case SubscriptionTier.standard:
        return period == SubscriptionPeriod.yearly
            ? 'Yearly Standard'
            : 'Standard';
      case SubscriptionTier.free:
        return 'Free';
    }
  }

  /// Get period suffix for display
  String get periodSuffix {
    switch (period) {
      case SubscriptionPeriod.monthly:
        return '/month';
      case SubscriptionPeriod.yearly:
        return '/year';
    }
  }

  /// Get monthly equivalent display (for yearly)
  String? get monthlyEquivalentDisplay {
    if (monthlyEquivalent == null) return null;
    return '\$${monthlyEquivalent!.toStringAsFixed(0)}/month';
  }

  /// Get features list for this package
  List<PackageFeature> get features {
    final List<PackageFeature> result = [];

    // Audio access
    if (tier.canPlayAudio) {
      result.add(const PackageFeature(
        title: 'All audio sessions',
        isIncluded: true,
      ));
    }

    // Offline download
    result.add(PackageFeature(
      title: 'Offline download',
      isIncluded: tier.canDownload,
    ));

    // Personalized recommendations (always included for paid)
    if (tier != SubscriptionTier.free) {
      result.add(const PackageFeature(
        title: 'Personalized recommendations',
        isIncluded: true,
      ));
    }

    return result;
  }

  @override
  String toString() {
    return 'SubscriptionPackage(productId: $productId, tier: $tier, '
        'period: $period, price: $localizedPrice)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SubscriptionPackage && other.productId == productId;
  }

  @override
  int get hashCode => productId.hashCode;
}

/// Feature item for package comparison
class PackageFeature {
  final String title;
  final bool isIncluded;

  const PackageFeature({
    required this.title,
    required this.isIncluded,
  });
}
