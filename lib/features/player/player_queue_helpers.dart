import 'player_state_mixin.dart';
import 'package:flutter/material.dart';

/// Queue image URL helpers for previous/next session peek.
mixin PlayerQueueHelpersMixin<T extends StatefulWidget> on State<T>
    implements PlayerStateAccessor {
  String? getNextSessionImageUrl() {
    final next = miniPlayerProvider?.nextSession;
    if (next == null) return null;
    if (next['_isOffline'] == true) return null;

    final bgImages = next['backgroundImages'];
    if (bgImages is Map) {
      return bgImages[currentLanguage] ??
          bgImages['en'] ??
          (bgImages.isNotEmpty ? bgImages.values.first : null);
    }
    return null;
  }

  String? getNextSessionLocalImagePath() {
    final next = miniPlayerProvider?.nextSession;
    if (next == null) return null;
    return next['_localImagePath'] as String?;
  }

  String? getPreviousSessionImageUrl() {
    final prev = miniPlayerProvider?.playContext?.previousSession;
    if (prev == null) return null;
    if (prev['_isOffline'] == true) return null;

    final bgImages = prev['backgroundImages'];
    if (bgImages is Map) {
      return bgImages[currentLanguage] ??
          bgImages['en'] ??
          (bgImages.isNotEmpty ? bgImages.values.first : null);
    }
    return null;
  }

  String? getPreviousSessionLocalImagePath() {
    final prev = miniPlayerProvider?.playContext?.previousSession;
    if (prev == null) return null;
    return prev['_localImagePath'] as String?;
  }
}
