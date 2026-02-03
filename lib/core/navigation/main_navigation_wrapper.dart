// lib/core/navigation/main_navigation_wrapper.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/mini_player_provider.dart';
import '../../shared/widgets/mini_player_widget.dart';
import '../../services/audio/audio_player_service.dart';

class MainNavigationWrapper extends StatefulWidget {
  final Widget child;

  const MainNavigationWrapper({
    super.key,
    required this.child,
  });

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper>
    with WidgetsBindingObserver {
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
    '/profile/change-password',
  ];

  String? _lastRoute;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    debugPrint('🟢 [NavigationWrapper] INITIALIZED');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    debugPrint('🔴 [NavigationWrapper] DISPOSED');
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkRoute();
    });
  }

  void _checkRoute() {
    if (!mounted) return;

    final currentRoute = ModalRoute.of(context)?.settings.name;

    // Route değişti mi kontrol et
    if (currentRoute != _lastRoute) {
      debugPrint(
          '🔄 [NavigationWrapper] Route changed: $_lastRoute -> $currentRoute');
      _lastRoute = currentRoute;

      final shouldHideMiniPlayer = hiddenRoutes.contains(currentRoute);

      if (shouldHideMiniPlayer) {
        debugPrint(
            '🛑 [NavigationWrapper] HIDDEN ROUTE DETECTED: $currentRoute');
        _stopAudioAndDismiss();
      } else {
        debugPrint(
            '✅ [NavigationWrapper] Normal route: $currentRoute (mini player allowed)');
      }
    }
  }

  void _stopAudioAndDismiss() {
    if (!mounted) return;

    try {
      debugPrint('🎵 [NavigationWrapper] Stopping audio...');
      final audioService = AudioPlayerService();
      audioService.stop();
      debugPrint('✅ [NavigationWrapper] Audio STOPPED');

      debugPrint('🎵 [NavigationWrapper] Dismissing mini player...');
      final miniPlayerProvider = Provider.of<MiniPlayerProvider>(
        context,
        listen: false,
      );
      miniPlayerProvider.dismiss();
      debugPrint('✅ [NavigationWrapper] Mini player DISMISSED');
    } catch (e) {
      debugPrint('❌ [NavigationWrapper] ERROR: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    final shouldHideMiniPlayer = hiddenRoutes.contains(currentRoute);

    return Overlay(
      initialEntries: [
        OverlayEntry(
          builder: (context) => Stack(
            children: [
              widget.child,
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
                      child: const Material(
                        type: MaterialType.transparency,
                        child: MiniPlayerWidget(),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }
}
