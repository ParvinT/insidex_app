// lib/services/cache_manager_service.dart

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

class AppCacheManager {
  static const key = 'insidexImageCache';

  static CacheManager? _instance;

  static CacheManager get instance {
    _instance ??= CacheManager(
      Config(
        key,
        stalePeriod: const Duration(days: 20),
        maxNrOfCacheObjects: 300,
        repo: JsonCacheInfoRepository(databaseName: key),
        fileService: HttpFileService(),
      ),
    );
    return _instance!;
  }

  /// Tek bir image'ı cache'e al
  static Future<void> precacheImage(String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty) return;

    try {
      await instance.downloadFile(imageUrl);
    } catch (e) {
      debugPrint('❌ Error precaching image: $e');
    }
  }

  /// Multiple image'ları cache'e al
  static Future<void> precacheImages(List<String> imageUrls) async {
    for (final url in imageUrls) {
      if (url.isNotEmpty) {
        try {
          await instance.downloadFile(url);
        } catch (e) {
          debugPrint('❌ Error precaching $url: $e');
        }
      }
    }
  }

  /// Cache'i temizle
  static Future<void> clearCache() async {
    try {
      await instance.emptyCache();
      debugPrint('✅ Cache cleared successfully');
    } catch (e) {
      debugPrint('❌ Error clearing cache: $e');
    }
  }

  /// Cache boyutunu al
  static Future<String> getCacheSize() async {
    try {
      final directory = await getTemporaryDirectory();
      final cacheDir = Directory('${directory.path}/$key');

      if (!await cacheDir.exists()) return '0 MB';

      int totalSize = 0;
      await for (final file in cacheDir.list(recursive: true)) {
        if (file is File) {
          totalSize += await file.length();
        }
      }

      final sizeInMB = totalSize / (1024 * 1024);
      return '${sizeInMB.toStringAsFixed(2)} MB';
    } catch (e) {
      return '0 MB';
    }
  }
}
