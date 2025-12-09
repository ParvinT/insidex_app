// lib/services/image_prefetch_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'cache_manager_service.dart';

class ImagePrefetchService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> prefetchPopularSessions({int limit = 50}) async {
    try {
      debugPrint('🔄 Starting image prefetch...');

      final snapshot = await _firestore
          .collection('sessions')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      final imageUrls = <String>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final backgroundImages = data['backgroundImages'];
        if (backgroundImages is Map) {
          for (final url in backgroundImages.values) {
            if (url != null && url.toString().isNotEmpty) {
              imageUrls.add(url.toString());
            }
          }
        }

        final singleImage = data['backgroundImage'];
        if (singleImage != null && singleImage.toString().isNotEmpty) {
          imageUrls.add(singleImage.toString());
        }
      }

      debugPrint('📥 Prefetching ${imageUrls.length} images...');

      _prefetchInBackground(imageUrls);

      debugPrint('✅ Prefetch started in background');
    } catch (e) {
      debugPrint('❌ Error in prefetch: $e');
    }
  }

  static void _prefetchInBackground(List<String> urls) {
    Future.delayed(Duration.zero, () async {
      for (final url in urls) {
        try {
          await AppCacheManager.precacheImage(url);

          await Future.delayed(const Duration(milliseconds: 100));
        } catch (e) {
          continue;
        }
      }
      debugPrint('🎉 All images prefetched successfully!');
    });
  }

  static Future<void> prefetchCategoryImages(String categoryTitle) async {
    try {
      final snapshot = await _firestore
          .collection('sessions')
          .where('category', isEqualTo: categoryTitle)
          .limit(30)
          .get();

      final imageUrls = snapshot.docs
          .map((doc) => doc.data()['backgroundImage']?.toString() ?? '')
          .where((url) => url.isNotEmpty)
          .toList();

      _prefetchInBackground(imageUrls);
    } catch (e) {
      debugPrint('❌ Error prefetching category images: $e');
    }
  }

  static Future<void> prefetchSessionImages(List<String> sessionIds) async {
    try {
      for (final sessionId in sessionIds) {
        final doc =
            await _firestore.collection('sessions').doc(sessionId).get();

        if (doc.exists) {
          final data = doc.data();
          final imageUrl = data?['backgroundImage']?.toString();

          if (imageUrl != null && imageUrl.isNotEmpty) {
            await AppCacheManager.precacheImage(imageUrl);
          }
        }
      }
      debugPrint('✅ Session images prefetched');
    } catch (e) {
      debugPrint('❌ Error prefetching session images: $e');
    }
  }

  static Future<void> clearImageCache() async {
    try {
      await AppCacheManager.clearCache();
      debugPrint('✅ Image cache cleared');
    } catch (e) {
      debugPrint('❌ Error clearing cache: $e');
    }
  }

  static Future<String> getCacheSize() async {
    try {
      return await AppCacheManager.getCacheSize();
    } catch (e) {
      debugPrint('❌ Error getting cache size: $e');
      return '0 MB';
    }
  }
}
