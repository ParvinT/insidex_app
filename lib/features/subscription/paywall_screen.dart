// lib/features/subscription/paywall_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/responsive/breakpoints.dart';
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

  const PaywallScreen({
    super.key,
    this.triggeredByFeature,
    this.onPurchaseSuccess,
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
    // Pre-select the highlighted (popular) package
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<SubscriptionProvider>();

      if (provider.availablePackages.isEmpty) {
        debugPrint('⚠️ [Paywall] No packages loaded, using defaults');
      }

      final packages = provider.availablePackages.isNotEmpty
          ? provider.availablePackages
          : SubscriptionPackage.getDefaultPackages();

      final highlighted = packages.firstWhere(
        (p) => p.isHighlighted,
        orElse: () => packages.first,
      );

      setState(() {
        _selectedProductId = highlighted.productId;
      });
    });
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

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
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
                            _buildHeader(context, isTablet),

                            SizedBox(height: 24.h),

                            // Package cards
                            ...packages.map((package) => Padding(
                                  padding: EdgeInsets.only(bottom: 16.h),
                                  child: PackageCard(
                                    package: package,
                                    isSelected:
                                        _selectedProductId == package.productId,
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
              color: AppColors.textPrimary,
              size: isTablet ? 28.sp : 24.sp,
            ),
          ),

          const Spacer(),

          // Logo
          SvgPicture.asset(
            'assets/images/logo.svg',
            width: isTablet ? 100.w : 80.w,
            height: isTablet ? 33.h : 27.h,
            colorFilter: const ColorFilter.mode(
              AppColors.textPrimary,
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

  Widget _buildHeader(BuildContext context, bool isTablet) {
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
                AppColors.textPrimary.withValues(alpha: 0.1),
                AppColors.textPrimary.withValues(alpha: 0.05),
              ],
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.workspace_premium,
            size: isTablet ? 40.sp : 35.sp,
            color: AppColors.textPrimary,
          ),
        ),

        SizedBox(height: 16.h),

        // Title
        Text(
          'Unlock Your Full Potential',
          style: GoogleFonts.inter(
            fontSize: isTablet ? 26.sp : 22.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),

        SizedBox(height: 8.h),

        // Subtitle
        Text(
          'Choose the plan that works best for you',
          style: GoogleFonts.inter(
            fontSize: isTablet ? 16.sp : 14.sp,
            color: AppColors.textSecondary,
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
          color: AppColors.textSecondary,
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
          color: AppColors.textSecondary.withValues(alpha: 0.7),
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

    final buttonText = selectedPackage.hasTrial
        ? 'Start ${selectedPackage.trialDays}-Day Free Trial'
        : 'Subscribe Now';

    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
            onPressed: _isProcessing ? null : () => _handlePurchase(provider),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.textPrimary,
              foregroundColor: Colors.white,
              disabledBackgroundColor:
                  AppColors.textPrimary.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
              elevation: 0,
            ),
            child: _isProcessing
                ? SizedBox(
                    width: 24.w,
                    height: 24.w,
                    child: const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    buttonText,
                    style: GoogleFonts.inter(
                      fontSize: isTablet ? 17.sp : 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _handlePurchase(SubscriptionProvider provider) async {
    if (_selectedProductId == null) return;

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

        // Show success dialog first
        await showPurchaseSuccessDialog(
          context,
          planName: package.tier.displayName,
          isTrialStarted: package.hasTrial,
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
}) {
  return Navigator.of(context).push<bool>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (context) => PaywallScreen(
        triggeredByFeature: feature,
        onPurchaseSuccess: onSuccess,
      ),
    ),
  );
}
