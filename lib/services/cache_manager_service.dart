// lib/services/cache_manager_service.dart

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

class AppCacheManager {
  static const key = 'insidexCacheKey';

  static CacheManager? _instance;

  static CacheManager get instance {
    _instance ??= CacheManager(
      Config(
        key,
        stalePeriod: const Duration(days: 30),
        maxNrOfCacheObjects: 100,
        repo: JsonCacheInfoRepository(databaseName: key),
        fileService: HttpFileService(),
      ),
    );
    return _instance!;
  }

  // Precache specific image
  static Future<void> precacheImage(String? imageUrl) async {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      try {
        // Path provider'ı kontrol et
        await _ensureInitialized();
        await instance.downloadFile(imageUrl);
      } catch (e) {
        print('Error precaching image: $e');
      }
    }
  }

  // Path provider'ın hazır olduğundan emin ol
  static Future<void> _ensureInitialized() async {
    try {
      final directory = await getTemporaryDirectory();
      print('Cache directory: ${directory.path}');
    } catch (e) {
      print('Path provider error: $e');
    }
  }
}
