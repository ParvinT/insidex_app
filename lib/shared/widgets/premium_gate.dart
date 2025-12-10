// lib/shared/widgets/premium_gate.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/user_provider.dart';
import '../../features/subscription/paywall_screen.dart';

/// Widget that gates content behind a subscription check
///
/// Usage:
/// ```dart
/// PremiumGate(
///   feature: 'download',
///   child: DownloadButton(),
/// )
/// ```
class PremiumGate extends StatelessWidget {
  /// The child widget to show if user has access
  final Widget child;

  /// The feature being gated (for analytics and messaging)
  final String feature;

  /// Optional: Custom widget to show instead of child when locked
  final Widget? lockedWidget;

  /// Optional: Custom callback when locked content is tapped
  final VoidCallback? onLocked;

  /// Whether to check for download permission specifically
  final bool requiresDownload;

  /// Whether to show the paywall automatically when tapped while locked
  final bool showPaywallOnTap;

  const PremiumGate({
    super.key,
    required this.child,
    required this.feature,
    this.lockedWidget,
    this.onLocked,
    this.requiresDownload = false,
    this.showPaywallOnTap = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        final hasAccess = requiresDownload
            ? userProvider.canDownloadSessions
            : userProvider.canPlayAudio;

        if (hasAccess) {
          return child;
        }

        // User doesn't have access
        if (lockedWidget != null) {
          return GestureDetector(
            onTap: () => _handleLockedTap(context),
            child: lockedWidget,
          );
        }

        // Default: wrap child with tap handler
        return GestureDetector(
          onTap: () => _handleLockedTap(context),
          child: child,
        );
      },
    );
  }

  void _handleLockedTap(BuildContext context) {
    if (onLocked != null) {
      onLocked!();
    } else if (showPaywallOnTap) {
      showPaywall(context, feature: feature);
    }
  }
}

/// Widget that shows a lock icon overlay on locked content
class PremiumLockOverlay extends StatelessWidget {
  final Widget child;
  final String feature;
  final bool isLocked;

  const PremiumLockOverlay({
    super.key,
    required this.child,
    required this.feature,
    required this.isLocked,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLocked) return child;

    return Stack(
      children: [
        // Dimmed child
        Opacity(
          opacity: 0.5,
          child: child,
        ),

        // Lock overlay
        Positioned.fill(
          child: GestureDetector(
            onTap: () => showPaywall(context, feature: feature),
            child: Container(
              color: Colors.transparent,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
