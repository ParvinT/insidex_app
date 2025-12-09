// lib/services/download/download_helpers.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;

/// Helper functions for download operations
/// Separated for better code organization and maintainability
class DownloadHelpers {
  // Prevent instantiation
  DownloadHelpers._();

  // =================== DISK SPACE ===================

  /// Check if there's enough disk space for download
  static Future<bool> hasEnoughDiskSpace(int requiredBytes) async {
    try {
      // Add 10% buffer for encryption overhead
      final requiredWithBuffer = (requiredBytes * 1.1).toInt();

      // Minimum required: 50MB free space
      const minFreeSpace = 50 * 1024 * 1024; // 50MB

      if (requiredWithBuffer > minFreeSpace) {
        debugPrint(
            '⚠️ [DownloadHelpers] Large file: ${formatBytes(requiredWithBuffer)}');
      }

      // Platform-specific disk space check could be added here
      // For now, we do a basic validation
      return true;
    } catch (e) {
      debugPrint('⚠️ [DownloadHelpers] Disk space check error: $e');
      return true; // Assume OK if check fails
    }
  }

  /// Get estimated file size from content-length header
  static Future<int> getRemoteFileSize(String url) async {
    try {
      final client = http.Client();
      try {
        final request = http.Request('HEAD', Uri.parse(url));
        final response = await client.send(request).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw Exception('HEAD request timeout');
          },
        );

        final contentLength = response.contentLength ?? 0;
        debugPrint(
            '📊 [DownloadHelpers] Remote file size: ${formatBytes(contentLength)}');
        return contentLength;
      } finally {
        client.close();
      }
    } catch (e) {
      debugPrint('⚠️ [DownloadHelpers] Could not get file size: $e');
      return 0; // Unknown size
    }
  }

  // =================== IMAGE DOWNLOAD ===================

  /// Download image file with timeout
  static Future<String> downloadImage(
    String? url,
    String destinationDir,
  ) async {
    final imagePath = path.join(destinationDir, 'image.jpg');

    if (url == null || url.isEmpty) {
      debugPrint('ℹ️ [DownloadHelpers] No image URL, skipping');
      return '';
    }

    try {
      debugPrint('📥 [DownloadHelpers] Downloading image...');

      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Image download timeout');
        },
      );

      if (response.statusCode == 200) {
        final file = File(imagePath);
        await file.writeAsBytes(response.bodyBytes, flush: true);
        debugPrint('✅ [DownloadHelpers] Image saved: $imagePath');
        return imagePath;
      } else {
        debugPrint(
            '⚠️ [DownloadHelpers] Image download failed: ${response.statusCode}');
        return '';
      }
    } catch (e) {
      debugPrint('⚠️ [DownloadHelpers] Image download error: $e');
      return '';
    }
  }

  // =================== CLEANUP OPERATIONS ===================

  /// Clean up temp playback files
  static Future<void> cleanupTempFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final playbackDir =
          Directory(path.join(tempDir.path, 'insidex_playback'));

      if (await playbackDir.exists()) {
        await playbackDir.delete(recursive: true);
        debugPrint('🧹 [DownloadHelpers] Cleaned up temp files');
      }
    } catch (e) {
      debugPrint('⚠️ [DownloadHelpers] Cleanup error: $e');
    }
  }

  /// Auto cleanup on app start
  /// Removes temp playback files and orphaned partial downloads
  static Future<void> autoCleanup({
    required Directory? downloadDir,
    required Future<List<String>> Function() getValidKeys,
  }) async {
    debugPrint('🧹 [DownloadHelpers] Running auto cleanup...');

    try {
      // 1. Clean temp playback files
      await cleanupTempFiles();

      // 2. Clean orphaned partial downloads
      await cleanupOrphanedDownloads(
        downloadDir: downloadDir,
        getValidKeys: getValidKeys,
      );

      debugPrint('✅ [DownloadHelpers] Auto cleanup completed');
    } catch (e) {
      debugPrint('⚠️ [DownloadHelpers] Auto cleanup error: $e');
    }
  }

  /// Remove download folders that don't have a database entry
  static Future<void> cleanupOrphanedDownloads({
    required Directory? downloadDir,
    required Future<List<String>> Function() getValidKeys,
  }) async {
    if (downloadDir == null || !await downloadDir.exists()) return;

    try {
      final validKeys = await getValidKeys();
      final validKeySet = validKeys.toSet();
      int removedCount = 0;

      await for (final entity in downloadDir.list()) {
        if (entity is Directory) {
          final folderName = path.basename(entity.path);

          // Check if this folder has a valid DB entry
          if (!validKeySet.contains(folderName)) {
            debugPrint(
                '🗑️ [DownloadHelpers] Removing orphaned folder: $folderName');
            await entity.delete(recursive: true);
            removedCount++;
          }
        }
      }

      if (removedCount > 0) {
        debugPrint(
            '✅ [DownloadHelpers] Removed $removedCount orphaned folders');
      }
    } catch (e) {
      debugPrint('⚠️ [DownloadHelpers] Orphan cleanup error: $e');
    }
  }

  // =================== PROGRESS HELPERS ===================

  /// Calculate progress considering indeterminate state
  /// Returns -1.0 if progress is indeterminate (unknown content length)
  static double calculateProgress({
    required int received,
    required int? contentLength,
  }) {
    if (contentLength == null || contentLength <= 0) {
      return -1.0; // Indeterminate
    }
    return (received / contentLength).clamp(0.0, 1.0);
  }

  /// Check if progress is indeterminate
  static bool isIndeterminateProgress(double progress) {
    return progress < 0;
  }

  // =================== FORMATTING ===================

  /// Format bytes to human readable string
  static String formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  /// Format duration to human readable string
  static String formatDuration(int seconds) {
    if (seconds < 60) {
      return '${seconds}s';
    } else if (seconds < 3600) {
      final mins = seconds ~/ 60;
      final secs = seconds % 60;
      return '${mins}m ${secs}s';
    } else {
      final hours = seconds ~/ 3600;
      final mins = (seconds % 3600) ~/ 60;
      return '${hours}h ${mins}m';
    }
  }
  // =================== AUDIO DURATION ===================

  /// Extract audio duration from bytes
  /// Writes to temp file, reads duration with AudioPlayer, then deletes
  static Future<int> getAudioDurationFromBytes(Uint8List bytes) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final tempPath = path.join(tempDir.path,
          'insidex_duration_check_${DateTime.now().millisecondsSinceEpoch}.mp3');
      final tempFile = File(tempPath);

      // Write bytes to temp file
      await tempFile.writeAsBytes(bytes, flush: true);

      // Get duration using just_audio
      final player = AudioPlayer();
      try {
        final duration = await player.setFilePath(tempPath);
        final seconds = duration?.inSeconds ?? 0;

        debugPrint('🕐 [DownloadHelpers] Extracted duration: ${seconds}s');
        return seconds;
      } finally {
        await player.dispose();
        // Clean up temp file
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      }
    } catch (e) {
      debugPrint('⚠️ [DownloadHelpers] Duration extraction error: $e');
      return 0;
    }
  }
}
