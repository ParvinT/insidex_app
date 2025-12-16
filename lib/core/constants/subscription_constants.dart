// lib/core/constants/subscription_constants.dart

/// Subscription system constants
/// Contains all product IDs, entitlements, and configuration values
///
/// Usage:
/// - Product IDs are used for RevenueCat and App Store/Play Store
/// - Entitlement IDs are used for access control
/// - Trial duration and other limits are centralized here
abstract class SubscriptionConstants {
  // ============================================================
  // PRODUCT IDs (Must match App Store Connect & Google Play Console)
  // ============================================================

  /// Lite monthly subscription - Basic audio access
  static const String productLiteMonthly = 'insidex_lite_monthly';

  /// Standard monthly subscription - Full access with offline
  static const String productStandardMonthly = 'insidex_standard_monthly';

  /// Standard yearly subscription - Best value
  static const String productStandardYearly = 'insidex_standard_yearly';

  /// All available product IDs
  static const List<String> allProductIds = [
    productLiteMonthly,
    productStandardMonthly,
    productStandardYearly,
  ];

  // ============================================================
  // ENTITLEMENT IDs (RevenueCat entitlements)
  // ============================================================

  /// Lite tier entitlement - Audio playback only
  static const String entitlementLite = 'lite';

  /// Standard tier entitlement - Audio + Offline download
  static const String entitlementStandard = 'standard';

  // ============================================================
  // TRIAL CONFIGURATION
  // ============================================================

  /// Free trial duration in days
  static const int trialDurationDays = 7;

  /// Products that offer free trial
  static const List<String> trialEligibleProducts = [
    productLiteMonthly,
    productStandardMonthly,
    productStandardYearly,
  ];

  // ============================================================
  // PRICING (Display only - actual prices from store)
  // ============================================================

  /// Lite monthly price in USD
  static const double priceLiteMonthly = 39.0;

  /// Standard monthly price in USD
  static const double priceStandardMonthly = 79.0;

  /// Standard yearly price in USD
  static const double priceStandardYearly = 590.0;

  /// Yearly savings percentage
  static const int yearlySavingsPercent = 38;

  // ============================================================
  // REVENUECAT CONFIGURATION
  // ============================================================

  /// RevenueCat API key for iOS
  /// TODO: Replace with actual key from RevenueCat dashboard
  static const String revenueCatApiKeyIOS = 'appl_XXXXXXXXXXXXXXXX';

  /// RevenueCat API key for Android
  /// TODO: Replace with actual key from RevenueCat dashboard
  static const String revenueCatApiKeyAndroid = 'goog_XXXXXXXXXXXXXXXX';

  /// Default offering identifier
  static const String defaultOfferingId = 'default';

  // ============================================================
  // FEATURE FLAGS
  // ============================================================

  /// Whether to show yearly plan prominently
  static const bool highlightYearlyPlan = true;

  /// Whether to show trial badge on eligible products
  static const bool showTrialBadge = true;

  /// Minimum app version required for subscriptions
  static const String minSubscriptionVersion = '1.0.0';
}

/// Subscription tier enum
/// Defines access levels in the app
enum SubscriptionTier {
  /// Free tier - Limited access, demo sessions only
  free('free'),

  /// Lite tier - All audio sessions, no offline
  lite('lite'),

  /// Standard tier - Full access including offline
  standard('standard');

  final String value;
  const SubscriptionTier(this.value);

  /// Create from string value
  factory SubscriptionTier.fromString(String? value) {
    return SubscriptionTier.values.firstWhere(
      (tier) => tier.value == value,
      orElse: () => SubscriptionTier.free,
    );
  }

  /// Check if user can play audio (non-demo sessions)
  bool get canPlayAudio => this != free;

  /// Check if user can download for offline
  bool get canDownload => this == standard;

  /// Check if user can use background playback & lock screen controls
  bool get canUseBackgroundPlayback => this != free;

  /// Check if tier has trial option
  bool get hasTrialOption => this != free;

  /// Get display name for UI
  String get displayName {
    switch (this) {
      case free:
        return 'Free';
      case lite:
        return 'Lite';
      case standard:
        return 'Standard';
    }
  }

  /// Get tier priority (higher = better)
  int get priority {
    switch (this) {
      case free:
        return 0;
      case lite:
        return 1;
      case standard:
        return 2;
    }
  }

  /// Check if this tier is better than another
  bool isBetterThan(SubscriptionTier other) => priority > other.priority;
}

/// Subscription period enum
enum SubscriptionPeriod {
  /// Monthly billing
  monthly('monthly'),

  /// Yearly billing
  yearly('yearly');

  final String value;
  const SubscriptionPeriod(this.value);

  /// Create from string value
  factory SubscriptionPeriod.fromString(String? value) {
    return SubscriptionPeriod.values.firstWhere(
      (period) => period.value == value,
      orElse: () => SubscriptionPeriod.monthly,
    );
  }

  /// Get display name
  String get displayName {
    switch (this) {
      case monthly:
        return 'Monthly';
      case yearly:
        return 'Yearly';
    }
  }
}

/// Subscription status enum
enum SubscriptionStatus {
  /// No active subscription
  none('none'),

  /// In free trial period
  trial('trial'),

  /// Active paid subscription
  active('active'),

  /// Subscription expired
  expired('expired'),

  /// User cancelled but still has access until period ends
  cancelled('cancelled'),

  /// Payment failed, grace period
  gracePeriod('grace_period');

  final String value;
  const SubscriptionStatus(this.value);

  /// Create from string value
  factory SubscriptionStatus.fromString(String? value) {
    return SubscriptionStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => SubscriptionStatus.none,
    );
  }

  /// Check if subscription is currently valid
  bool get isValid =>
      this == trial ||
      this == active ||
      this == cancelled ||
      this == gracePeriod;

  /// Check if in trial
  bool get isTrial => this == trial;

  /// Check if user should see renewal prompts
  bool get shouldPromptRenewal => this == cancelled || this == gracePeriod;
}

/// Subscription source - where the subscription came from
enum SubscriptionSource {
  /// RevenueCat (App Store / Play Store)
  revenuecat('revenuecat'),

  /// Admin granted (manual)
  admin('admin'),

  /// Promo code
  promo('promo'),

  /// CloudPayments (Russia)
  cloudpayments('cloudpayments');

  final String value;
  const SubscriptionSource(this.value);

  /// Create from string value
  factory SubscriptionSource.fromString(String? value) {
    return SubscriptionSource.values.firstWhere(
      (source) => source.value == value,
      orElse: () => SubscriptionSource.revenuecat,
    );
  }
}
