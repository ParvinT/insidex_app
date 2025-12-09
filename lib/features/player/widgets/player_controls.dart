// lib/features/player/widgets/player_controls.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../l10n/app_localizations.dart';

class PlayerControls extends StatelessWidget {
  final bool isPlaying;
  final bool isShuffled;
  final bool isLooping;
  final VoidCallback onTogglePlayPause;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToggleShuffle;
  final VoidCallback onToggleLoop;

  const PlayerControls({
    super.key,
    required this.isPlaying,
    required this.isShuffled,
    required this.isLooping,
    required this.onTogglePlayPause,
    required this.onPrevious,
    required this.onNext,
    required this.onToggleShuffle,
    required this.onToggleLoop,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 40.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Shuffle
          IconButton(
            icon: Icon(
              Icons.shuffle,
              color: isShuffled ? Colors.greenAccent : Colors.white54,
              size: 24.sp,
            ),
            onPressed: () {
              onToggleShuffle();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isShuffled
                      ? AppLocalizations.of(context).shuffleOff
                      : AppLocalizations.of(context).shuffleOn),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),

          // Previous
          IconButton(
            icon: Icon(Icons.skip_previous, color: Colors.white, size: 36.sp),
            onPressed: onPrevious,
          ),

          // Play/Pause
          GestureDetector(
            onTap: onTogglePlayPause,
            child: Container(
              width: 72.w,
              height: 72.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Colors.white, Colors.white70],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                size: 36.sp,
                color: Colors.black87,
              ),
            ),
          ),

          // Next
          IconButton(
            icon: Icon(Icons.skip_next, color: Colors.white, size: 36.sp),
            onPressed: onNext,
          ),

          // Loop
          IconButton(
            icon: Icon(
              Icons.repeat,
              color: isLooping ? Colors.greenAccent : Colors.white54,
              size: 24.sp,
            ),
            onPressed: () {
              onToggleLoop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isLooping
                      ? AppLocalizations.of(context).loopDisabled
                      : AppLocalizations.of(context).loopEnabled),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
