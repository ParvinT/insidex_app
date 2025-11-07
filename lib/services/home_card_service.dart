// lib/services/home_card_service.dart

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'cache_manager_service.dart';
import '../../l10n/app_localizations.dart';

/// Service for managing home screen card data
/// Fetches card information from Firestore and handles random image selection
class HomeCardService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final Random _random = Random();

  /// Fetch all enabled home cards
  static Future<List<Map<String, dynamic>>> fetchHomeCards() async {
    try {
      debugPrint('🔄 Fetching home cards from Firestore...');

      final snapshot = await _firestore
          .collection('home_cards')
          .where('enabled', isEqualTo: true)
          .orderBy('order')
          .get();

      if (snapshot.docs.isEmpty) {
        debugPrint('⚠️ No home cards found in Firestore');
        return [];
      }

      final cards = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();

        // Get random image from the images array
        final images = data['images'] as List<dynamic>?;
        final randomImage = _getRandomImage(images);

        cards.add({
          'id': doc.id,
          'cardType': data['cardType'] ?? '',
          'enabled': data['enabled'] ?? true,
          'order': data['order'] ?? 0,
          'randomImage': randomImage,
          'allImages': images ?? [],
          'icon': data['icon'] ?? 'music_note',
          'navigateTo': data['navigateTo'] ?? '',
        });

        // Prefetch the selected image in background
        if (randomImage != null && randomImage.isNotEmpty) {
          _prefetchImage(randomImage);
        }
      }

      debugPrint('✅ Fetched ${cards.length} home cards');
      return cards;
    } catch (e) {
      debugPrint('❌ Error fetching home cards: $e');
      return [];
    }
  }

  /// Fetch a specific home card by ID
  static Future<Map<String, dynamic>?> fetchCardById(String cardId) async {
    try {
      final doc = await _firestore.collection('home_cards').doc(cardId).get();

      if (!doc.exists) {
        debugPrint('⚠️ Card not found: $cardId');
        return null;
      }

      final data = doc.data()!;
      final images = data['images'] as List<dynamic>?;
      final randomImage = _getRandomImage(images);

      return {
        'id': doc.id,
        'title': data['title'] ?? {},
        'enabled': data['enabled'] ?? true,
        'order': data['order'] ?? 0,
        'randomImage': randomImage,
        'allImages': images ?? [],
        'icon': data['icon'] ?? 'music_note',
        'navigateTo': data['navigateTo'] ?? '',
      };
    } catch (e) {
      debugPrint('❌ Error fetching card $cardId: $e');
      return null;
    }
  }

  /// Get a random image from the list
  static String? _getRandomImage(List<dynamic>? images) {
    if (images == null || images.isEmpty) {
      debugPrint('⚠️ No images available for card');
      return null;
    }

    final validImages = images
        .where((img) => img != null && img.toString().isNotEmpty)
        .map((img) => img.toString())
        .toList();

    if (validImages.isEmpty) return null;

    // Return random image
    final randomIndex = _random.nextInt(validImages.length);
    final selectedImage = validImages[randomIndex];

    debugPrint(
        '🎲 Selected random image: ${selectedImage.substring(0, 50)}...');
    return selectedImage;
  }

  /// Prefetch image in background for better performance
  static void _prefetchImage(String imageUrl) {
    Future.delayed(Duration.zero, () async {
      try {
        await AppCacheManager.precacheImage(imageUrl);
        debugPrint('✅ Prefetched image successfully');
      } catch (e) {
        debugPrint('⚠️ Error prefetching image: $e');
      }
    });
  }

  /// Prefetch all images for a card (for smoother transitions)
  static Future<void> prefetchAllCardImages(String cardId) async {
    try {
      final card = await fetchCardById(cardId);
      if (card == null) return;

      final images = card['allImages'] as List<dynamic>?;
      if (images == null || images.isEmpty) return;

      for (final image in images) {
        if (image != null && image.toString().isNotEmpty) {
          await AppCacheManager.precacheImage(image.toString());
        }
      }

      debugPrint('✅ Prefetched all images for card: $cardId');
    } catch (e) {
      debugPrint('❌ Error prefetching card images: $e');
    }
  }

  /// Get localized title based on current language
  static String getLocalizedTitle(
    Map<String, dynamic> titleMap,
    String languageCode,
  ) {
    if (titleMap.isEmpty) return 'Untitled';

    // Try to get the title in the requested language
    final localizedTitle = titleMap[languageCode];
    if (localizedTitle != null && localizedTitle.toString().isNotEmpty) {
      return localizedTitle.toString();
    }

    // Fallback to English
    final englishTitle = titleMap['en'];
    if (englishTitle != null && englishTitle.toString().isNotEmpty) {
      return englishTitle.toString();
    }

    // Last resort: return first available title
    return titleMap.values.first?.toString() ?? 'Untitled';
  }

  /// Refresh random images for all cards
  /// Useful for implementing "refresh" functionality
  static Future<List<Map<String, dynamic>>> refreshRandomImages() async {
    debugPrint('🔄 Refreshing random images for home cards...');
    return await fetchHomeCards();
  }

  /// Check if a specific card exists and is enabled
  static Future<bool> isCardEnabled(String cardId) async {
    try {
      final doc = await _firestore.collection('home_cards').doc(cardId).get();

      if (!doc.exists) return false;

      final data = doc.data();
      return data?['enabled'] ?? false;
    } catch (e) {
      debugPrint('❌ Error checking card status: $e');
      return false;
    }
  }

  static String getLocalizedTitleFromKey(
    BuildContext context,
    String? cardType,
  ) {
    if (cardType == null || cardType.isEmpty) {
      return 'Untitled';
    }

    final l10n = AppLocalizations.of(context);

    switch (cardType) {
      case 'all_subliminals':
        return l10n.allSubliminals;
      case 'your_playlist':
        return l10n.playlist;
      default:
        return 'Untitled';
    }
  }

  /// Smart prefetch - First load current, then all others in background
  static Future<void> smartPrefetch() async {
    try {
      debugPrint('🧠 Smart prefetch started...');

      // 2 saniye bekle (user ekrana bakıyor, fark etmez)
      await Future.delayed(const Duration(seconds: 2));

      debugPrint('📥 Background prefetch starting...');

      // Tüm kartların TÜM fotoğraflarını arka planda yükle
      final snapshot = await _firestore
          .collection('home_cards')
          .where('enabled', isEqualTo: true)
          .get();

      int prefetchCount = 0;

      for (final doc in snapshot.docs) {
        final images = doc.data()['images'] as List<dynamic>?;
        if (images != null && images.isNotEmpty) {
          for (final img in images) {
            if (img != null && img.toString().isNotEmpty) {
              try {
                await AppCacheManager.precacheImage(img.toString());
                prefetchCount++;
              } catch (e) {
                debugPrint('⚠️ Error prefetching $img: $e');
              }
            }
          }
        }
      }

      debugPrint('✅ Smart prefetch completed! Cached $prefetchCount images');
    } catch (e) {
      debugPrint('❌ Error in smart prefetch: $e');
    }
  }
}
