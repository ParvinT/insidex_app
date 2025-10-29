// lib/core/navigation/main_navigation_wrapper.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/mini_player_provider.dart';
import '../../shared/widgets/mini_player_widget.dart';

/// Main Navigation Wrapper
/// Wraps all app pages and overlays mini player at the bottom
/// This ensures mini player appears on all screens without adding it to each page
class MainNavigationWrapper extends StatelessWidget {
  final Widget child;

  const MainNavigationWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Check current route
    final currentRoute = ModalRoute.of(context)?.settings.name;

    // Routes where mini player should NOT be shown
    final hiddenRoutes = [
      '/', // Splash
      '/auth/welcome',
      '/auth/login',
      '/auth/register',
      '/auth/forgot-password',
      '/onboarding/goals',
      '/onboarding/gender',
      '/onboarding/birthdate',
      '/player', // Full audio player screen
    ];

    final shouldHideMiniPlayer = hiddenRoutes.contains(currentRoute);

    return Stack(
      children: [
        // Main content (current page)
        child,

        // Mini player overlay (positioned at bottom)
        if (!shouldHideMiniPlayer)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Consumer<MiniPlayerProvider>(
              builder: (context, miniPlayer, _) {
                // Only show mini player if visible
                if (!miniPlayer.isVisible) {
                  return const SizedBox.shrink();
                }

                return const MiniPlayerWidget();
              },
            ),
          ),
      ],
    );
  }
}
