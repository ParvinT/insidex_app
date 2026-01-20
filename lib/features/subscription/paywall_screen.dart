// lib/features/subscription/paywall_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/themes/app_theme_extension.dart';
import '../../core/responsive/breakpoints.dart';
import '../../core/constants/subscription_constants.dart';
import '../../models/subscription_package.dart';
import '../../providers/subscription_provider.dart';
import 'widgets/package_card.dart';
import 'widgets/success_dialog.dart';

/// Paywall screen for displaying subscription options
/// Shows available packages and handles purchase flow
class PaywallScreen extends StatefulWidget {
  /// Optional: Feature that triggered the paywall (for analytics)
  final String? triggeredByFeature;

  /// Optional: Callback when purchase completes successfully
  final VoidCallback? onPurchaseSuccess;

  /// If true, highlights the user's current plan and shows "Current Plan" badge
  final bool showCurrentPlan;

  const PaywallScreen({
    super.key,
    this.triggeredByFeature,
    this.onPurchaseSuccess,
    this.showCurrentPlan = false,
  });

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  String? _selectedProductId;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<SubscriptionProvider>();

      if (provider.availablePackages.isEmpty) {
        debugPrint('⚠️ [Paywall] No packages loaded, using defaults');
      }

      final packages = provider.availablePackages.isNotEmpty
          ? provider.availablePackages
          : SubscriptionPackage.getDefaultPackages();

      // If showing current plan mode, pre-select user's current plan
      if (widget.showCurrentPlan && provider.isActive) {
        final currentTier = provider.tier;
        final currentPeriod = provider.subscription.period;

        // Find the package that matches user's current subscription
        final currentPackage = packages.firstWhere(
          (p) => p.tier == currentTier && p.period == currentPeriod,
          orElse: () => packages.firstWhere(
            (p) => p.tier == currentTier,
            orElse: () => packages.first,
          ),
        );

        setState(() {
          _selectedProductId = currentPackage.productId;
        });

        debugPrint(
            '📦 [Paywall] Current plan mode - selected: ${currentPackage.productId}');
      } else {
        // Default: select highlighted (popular) package
        final highlighted = packages.firstWhere(
          (p) => p.isHighlighted,
          orElse: () => packages.first,
        );

        setState(() {
          _selectedProductId = highlighted.productId;
        });
      }
    });
  }

  /// Check if the selected package is user's current plan
  bool _isCurrentPlan(
      SubscriptionPackage package, SubscriptionProvider provider) {
    if (!provider.isActive) return false;

    final currentTier = provider.tier;
    final currentPeriod = provider.subscription.period;

    // Match by tier and period
    return package.tier == currentTier && package.period == currentPeriod;
  }

  /// Check if selected package is same as current plan
  bool _isSelectedCurrentPlan(SubscriptionProvider provider) {
    if (!provider.isActive || _selectedProductId == null) return false;

    final packages = provider.availablePackages.isNotEmpty
        ? provider.availablePackages
        : SubscriptionPackage.getDefaultPackages();

    final selectedPackage = packages.firstWhere(
      (p) => p.productId == _selectedProductId,
      orElse: () => packages.first,
    );

    return _isCurrentPlan(selectedPackage, provider);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isTablet =
        width >= Breakpoints.tabletMin && width < Breakpoints.desktopMin;
    final isDesktop = width >= Breakpoints.desktopMin;

    final horizontalPadding = isDesktop ? 40.w : (isTablet ? 30.w : 20.w);
    final maxContentWidth =
        isDesktop ? 600.0 : (isTablet ? 500.0 : double.infinity);

    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Consumer<SubscriptionProvider>(
          builder: (context, subscriptionProvider, _) {
            // ✅ Fallback to default packages if empty
            final packages = subscriptionProvider.availablePackages.isNotEmpty
                ? subscriptionProvider.availablePackages
                : SubscriptionPackage.getDefaultPackages();

            // 🔍 DEBUG
            debugPrint('📦 [Paywall] Packages count: ${packages.length}');
            for (final p in packages) {
              debugPrint('  - ${p.productId}: ${p.displayTitle}');
            }

            return Column(
              children: [
                // App bar
                _buildAppBar(context, isTablet),

                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    padding:
                        EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxContentWidth),
                        child: Column(
                          children: [
                            SizedBox(height: 20.h),

                            // Header
                            _buildHeader(
                                context, isTablet, subscriptionProvider),

                            SizedBox(height: 24.h),

                            // Package cards
                            ...packages.map((package) => Padding(
                                  padding: EdgeInsets.only(bottom: 16.h),
                                  child: PackageCard(
                                    package: package,
                                    isSelected:
                                        _selectedProductId == package.productId,
                                    isCurrentPlan: widget.showCurrentPlan &&
                                        _isCurrentPlan(
                                            package, subscriptionProvider),
                                    onTap: () {
                                      setState(() {
                                        _selectedProductId = package.productId;
                                      });
                                    },
                                  ),
                                )),

                            SizedBox(height: 8.h),

                            // Restore purchases
                            _buildRestoreButton(context, subscriptionProvider),

                            SizedBox(height: 24.h),

                            // Legal text
                            _buildLegalText(context, isTablet),

                            SizedBox(height: 100.h), // Space for button
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Bottom purchase button
                _buildPurchaseButton(context, subscriptionProvider, isTablet),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isTablet) {
    final colors = context.colors;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 16.w,
        vertical: 12.h,
      ),
      child: Row(
        children: [
          // Close button
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.close,
              color: colors.textPrimary,
              size: isTablet ? 28.sp : 24.sp,
            ),
          ),

          const Spacer(),

          // Logo
          SvgPicture.asset(
            'assets/images/logo.svg',
            width: isTablet ? 100.w : 80.w,
            height: isTablet ? 33.h : 27.h,
            colorFilter: ColorFilter.mode(
              colors.textPrimary,
              BlendMode.srcIn,
            ),
          ),

          const Spacer(),

          // Placeholder for balance
          SizedBox(width: isTablet ? 52.w : 48.w),
        ],
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, bool isTablet, SubscriptionProvider provider) {
    final colors = context.colors;

    // Dynamic title based on mode
    final title = widget.showCurrentPlan && provider.isActive
        ? 'Manage Your Plan'
        : 'Unlock Your Full Potential';

    final subtitle = widget.showCurrentPlan && provider.isActive
        ? 'Switch plans or keep your current subscription'
        : 'Choose the plan that works best for you';

    return Column(
      children: [
        // Premium icon
        Container(
          width: isTablet ? 80.w : 70.w,
          height: isTablet ? 80.w : 70.w,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colors.textPrimary.withValues(alpha: 0.1),
                colors.textPrimary.withValues(alpha: 0.05),
              ],
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            widget.showCurrentPlan ? Icons.swap_horiz : Icons.workspace_premium,
            size: isTablet ? 40.sp : 35.sp,
            color: colors.textPrimary,
          ),
        ),

        SizedBox(height: 16.h),

        // Title
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: isTablet ? 26.sp : 22.sp,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),

        SizedBox(height: 8.h),

        // Subtitle
        Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: isTablet ? 16.sp : 14.sp,
            color: colors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRestoreButton(
      BuildContext context, SubscriptionProvider provider) {
    return TextButton(
      onPressed: provider.isLoading ? null : () => _handleRestore(provider),
      child: Text(
        'Restore purchases',
        style: GoogleFonts.inter(
          fontSize: 14.sp,
          color: context.colors.textSecondary,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  Widget _buildLegalText(BuildContext context, bool isTablet) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Text(
        'Subscription automatically renews unless auto-renew is turned off at least 24 hours before the end of the current period. '
        'You can manage and cancel your subscription in your App Store or Google Play account settings.',
        style: GoogleFonts.inter(
          fontSize: isTablet ? 12.sp : 11.sp,
          color: context.colors.textSecondary.withValues(alpha: 0.7),
          height: 1.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildPurchaseButton(
    BuildContext context,
    SubscriptionProvider provider,
    bool isTablet,
  ) {
    final packages = provider.availablePackages.isNotEmpty
        ? provider.availablePackages
        : SubscriptionPackage.getDefaultPackages();
    final selectedPackage = packages.firstWhere(
      (p) => p.productId == _selectedProductId,
      orElse: () => packages.first,
    );

    final isCurrentPlan = _isSelectedCurrentPlan(provider);
    final colors = context.colors;

    // Dynamic button text
    String buttonText;
    if (isCurrentPlan) {
      buttonText = 'Current Plan';
    } else if (widget.showCurrentPlan && provider.isActive) {
      // User is switching plans
      final isUpgrade = _isUpgrade(selectedPackage, provider);
      if (isUpgrade) {
        buttonText = 'Upgrade to ${selectedPackage.tier.displayName}';
      } else {
        buttonText = 'Switch to ${selectedPackage.tier.displayName}';
      }
    } else if (selectedPackage.hasTrial) {
      buttonText = 'Start ${selectedPackage.trialDays}-Day Free Trial';
    } else {
      buttonText = 'Subscribe Now';
    }

    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
      decoration: BoxDecoration(
        color: colors.backgroundElevated,
        boxShadow: [
          BoxShadow(
            color: colors.textPrimary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: isTablet ? 56.h : 52.h,
          child: ElevatedButton(
            onPressed: _isProcessing || isCurrentPlan
                ? null
                : () => _handlePurchase(provider),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isCurrentPlan ? Colors.green : colors.textPrimary,
              foregroundColor: colors.textOnPrimary,
              disabledBackgroundColor: isCurrentPlan
                  ? Colors.green.withValues(alpha: 0.7)
                  : colors.textPrimary.withValues(alpha: 0.5),
              disabledForegroundColor: colors.textOnPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
              elevation: 0,
            ),
            child: _isProcessing
                ? SizedBox(
                    width: 24.w,
                    height: 24.w,
                    child: CircularProgressIndicator(
                      color: colors.textOnPrimary,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isCurrentPlan) ...[
                        Icon(
                          Icons.check_circle,
                          size: isTablet ? 22.sp : 20.sp,
                        ),
                        SizedBox(width: 8.w),
                      ],
                      Text(
                        buttonText,
                        style: GoogleFonts.inter(
                          fontSize: isTablet ? 17.sp : 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  /// Check if selected package is an upgrade from current plan
  bool _isUpgrade(SubscriptionPackage selected, SubscriptionProvider provider) {
    final currentTier = provider.tier;

    // Standard is higher than Lite
    if (selected.tier == SubscriptionTier.standard &&
        currentTier == SubscriptionTier.lite) {
      return true;
    }

    // Yearly is considered upgrade from monthly (same tier)
    if (selected.tier == currentTier &&
        selected.period == SubscriptionPeriod.yearly &&
        provider.subscription.period == SubscriptionPeriod.monthly) {
      return true;
    }

    return false;
  }

  Future<void> _handlePurchase(SubscriptionProvider provider) async {
    if (_selectedProductId == null) return;

    // Check if trying to purchase current plan
    if (_isSelectedCurrentPlan(provider)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You are already subscribed to this plan'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final packages = provider.availablePackages.isNotEmpty
          ? provider.availablePackages
          : SubscriptionPackage.getDefaultPackages();

      final package = packages.firstWhere(
        (p) => p.productId == _selectedProductId,
        orElse: () => packages.first,
      );

      final success = await provider.purchase(package);

      if (success && mounted) {
        widget.onPurchaseSuccess?.call();

        // Determine if this was an upgrade/switch
        final wasSwitch = widget.showCurrentPlan && provider.isActive;

        // Show success dialog
        await showPurchaseSuccessDialog(
          context,
          planName: package.tier.displayName,
          isTrialStarted: package.hasTrial && !wasSwitch,
        );

        // Then close paywall
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else if (mounted && provider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error!),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _handleRestore(SubscriptionProvider provider) async {
    setState(() => _isProcessing = true);

    try {
      final success = await provider.restorePurchases();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Purchases restored successfully!'
                  : 'No purchases found to restore',
            ),
            backgroundColor: success ? Colors.green : Colors.orange,
          ),
        );

        if (success && provider.isActive) {
          Navigator.of(context).pop(true);
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}

/// Helper function to show paywall as modal
Future<bool?> showPaywall(
  BuildContext context, {
  String? feature,
  VoidCallback? onSuccess,
  bool showCurrentPlan = false,
}) {
  return Navigator.of(context).push<bool>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (context) => PaywallScreen(
        triggeredByFeature: feature,
        onPurchaseSuccess: onSuccess,
        showCurrentPlan: showCurrentPlan,
      ),
    ),
  );
}
