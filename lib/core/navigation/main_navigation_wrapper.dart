// lib/core/navigation/main_navigation_wrapper.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/mini_player_provider.dart';
import '../../shared/widgets/mini_player_widget.dart';

class MainNavigationWrapper extends StatelessWidget {
  final Widget child;

  const MainNavigationWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name;

    final hiddenRoutes = [
      '/',
      '/auth/welcome',
      '/auth/login',
      '/auth/register',
      '/auth/forgot-password',
      '/onboarding/goals',
      '/onboarding/gender',
      '/onboarding/birthdate',
      '/player',
    ];

    final shouldHideMiniPlayer = hiddenRoutes.contains(currentRoute);

    return Stack(
      children: [
        child,

        // ✅ YENİ: Dynamic positioning
        if (!shouldHideMiniPlayer)
          Consumer<MiniPlayerProvider>(
            builder: (context, miniPlayer, _) {
              if (!miniPlayer.isVisible) {
                return const SizedBox.shrink();
              }

              return Positioned(
                left: 0,
                right: 0,
                top: miniPlayer.isAtTop ? 0 : null,
                bottom: miniPlayer.isAtTop ? null : 0,
                child: const MiniPlayerWidget(),
              );
            },
          ),
      ],
    );
  }
}
