// lib/core/routes/player_route.dart

import 'package:flutter/material.dart';
import '../../features/player/audio_player_screen.dart';
import '../../models/play_context.dart';

/// Transparent route for the audio player screen.
///
/// Uses [opaque: false] so the previous screen remains visible behind
/// the player during swipe-to-dismiss, eliminating the black background
/// flash. This is the same approach used by Spotify and Apple Music.
class PlayerRoute extends PageRouteBuilder {
  PlayerRoute({
    required Map<String, dynamic> sessionData,
    PlayContext? playContext,
  }) : super(
          opaque: false,
          barrierColor: Colors.black54,
          barrierDismissible: false,
          settings: const RouteSettings(name: '/player'),
          transitionDuration: const Duration(milliseconds: 350),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (context, animation, secondaryAnimation) {
            return AudioPlayerScreen(
              sessionData: sessionData,
              playContext: playContext,
            );
          },
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final slideAnimation = Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            ));

            final fadeAnimation = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
            ));

            return SlideTransition(
              position: slideAnimation,
              child: FadeTransition(
                opacity: fadeAnimation,
                child: child,
              ),
            );
          },
        );
}
