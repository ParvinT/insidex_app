// lib/models/subscription_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/subscription_constants.dart';

/// User's subscription data model
/// Represents the current subscription state of a user
///
/// Stored in Firestore: users/{uid}/subscription (as nested object)
class SubscriptionModel {
  /// Current subscription tier
  final SubscriptionTier tier;

  /// Billing period (monthly/yearly)
  final SubscriptionPeriod? period;

  /// Current status
  final SubscriptionStatus status;

  /// Source of subscription
  final SubscriptionSource source;

  /// When subscription started
  final DateTime? startDate;

  /// When subscription expires/renews
  final DateTime? expiryDate;

  /// When trial ends (if in trial)
  final DateTime? trialEndDate;

  /// Whether user has used their trial
  final bool trialUsed;

  /// Whether auto-renew is enabled
  final bool autoRenew;

  /// Original transaction ID (for restore)
  final String? originalTransactionId;

  /// Last time subscription was verified with store
  final DateTime? lastVerifiedAt;

  /// Product ID currently subscribed to
  final String? productId;

  const SubscriptionModel({
    this.tier = SubscriptionTier.free,
    this.period,
    this.status = SubscriptionStatus.none,
    this.source = SubscriptionSource.revenuecat,
    this.startDate,
    this.expiryDate,
    this.trialEndDate,
    this.trialUsed = false,
    this.autoRenew = true,
    this.originalTransactionId,
    this.lastVerifiedAt,
    this.productId,
  });

  /// Default free subscription
  factory SubscriptionModel.free() {
    return const SubscriptionModel(
      tier: SubscriptionTier.free,
      status: SubscriptionStatus.none,
    );
  }

  /// Create from Firestore data
  factory SubscriptionModel.fromMap(Map<String, dynamic>? map) {
    if (map == null || map.isEmpty) {
      return SubscriptionModel.free();
    }

    return SubscriptionModel(
      tier: SubscriptionTier.fromString(map['tier'] as String?),
      period: map['period'] != null
          ? SubscriptionPeriod.fromString(map['period'] as String?)
          : null,
      status: SubscriptionStatus.fromString(map['status'] as String?),
      source: SubscriptionSource.fromString(map['source'] as String?),
      startDate: _parseTimestamp(map['startDate']),
      expiryDate: _parseTimestamp(map['expiryDate']),
      trialEndDate: _parseTimestamp(map['trialEndDate']),
      trialUsed: map['trialUsed'] as bool? ?? false,
      autoRenew: map['autoRenew'] as bool? ?? true,
      originalTransactionId: map['originalTransactionId'] as String?,
      lastVerifiedAt: _parseTimestamp(map['lastVerifiedAt']),
      productId: map['productId'] as String?,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'tier': tier.value,
      'period': period?.value,
      'status': status.value,
      'source': source.value,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
      'trialEndDate':
          trialEndDate != null ? Timestamp.fromDate(trialEndDate!) : null,
      'trialUsed': trialUsed,
      'autoRenew': autoRenew,
      'originalTransactionId': originalTransactionId,
      'lastVerifiedAt':
          lastVerifiedAt != null ? Timestamp.fromDate(lastVerifiedAt!) : null,
      'productId': productId,
    };
  }

  /// Helper to parse Firestore timestamp
  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  // ============================================================
  // COMPUTED PROPERTIES
  // ============================================================

  /// Check if subscription is currently active (paid or trial)
  bool get isActive => status.isValid && !isExpired;

  /// Check if currently in trial period
  bool get isInTrial {
    if (status != SubscriptionStatus.trial) return false;
    if (trialEndDate == null) return false;
    return DateTime.now().isBefore(trialEndDate!);
  }

  /// Check if subscription has expired
  bool get isExpired {
    if (expiryDate == null) return false;
    return DateTime.now().isAfter(expiryDate!);
  }

  /// Check if user can start a trial
  bool get canStartTrial => !trialUsed;

  /// Days remaining in subscription
  int get daysRemaining {
    if (expiryDate == null) return 0;
    final difference = expiryDate!.difference(DateTime.now()).inDays;
    return difference > 0 ? difference : 0;
  }

  /// Days remaining in trial
  int get trialDaysRemaining {
    if (trialEndDate == null) return 0;
    final difference = trialEndDate!.difference(DateTime.now()).inDays;
    return difference > 0 ? difference : 0;
  }

  /// Check if user can play audio (non-demo)
  bool get canPlayAudio => isActive && tier.canPlayAudio;

  /// Check if user can download
  bool get canDownload => isActive && tier.canDownload;

  /// Check if user can use background playback & lock screen controls
  bool get canUseBackgroundPlayback =>
      isActive && tier.canUseBackgroundPlayback;

  // ============================================================
  // COPY WITH
  // ============================================================

  SubscriptionModel copyWith({
    SubscriptionTier? tier,
    SubscriptionPeriod? period,
    SubscriptionStatus? status,
    SubscriptionSource? source,
    DateTime? startDate,
    DateTime? expiryDate,
    DateTime? trialEndDate,
    bool? trialUsed,
    bool? autoRenew,
    String? originalTransactionId,
    DateTime? lastVerifiedAt,
    String? productId,
  }) {
    return SubscriptionModel(
      tier: tier ?? this.tier,
      period: period ?? this.period,
      status: status ?? this.status,
      source: source ?? this.source,
      startDate: startDate ?? this.startDate,
      expiryDate: expiryDate ?? this.expiryDate,
      trialEndDate: trialEndDate ?? this.trialEndDate,
      trialUsed: trialUsed ?? this.trialUsed,
      autoRenew: autoRenew ?? this.autoRenew,
      originalTransactionId:
          originalTransactionId ?? this.originalTransactionId,
      lastVerifiedAt: lastVerifiedAt ?? this.lastVerifiedAt,
      productId: productId ?? this.productId,
    );
  }

  @override
  String toString() {
    return 'SubscriptionModel(tier: $tier, status: $status, period: $period, '
        'isActive: $isActive, daysRemaining: $daysRemaining)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SubscriptionModel &&
        other.tier == tier &&
        other.status == status &&
        other.productId == productId;
  }

  @override
  int get hashCode => Object.hash(tier, status, productId);
}
