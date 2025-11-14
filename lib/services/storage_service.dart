// lib/services/storage_service.dart

import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';

class StorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload audio file with language support
  /// New path structure: sessions/audio/{sessionId}/{languageCode}/subliminal.mp3
  static Future<String?> uploadAudioWithLanguage({
    required String sessionId,
    required String languageCode, // 'en', 'tr', 'ru', 'hi'
    required PlatformFile file,
    Function(double)? onProgress,
  }) async {
    try {
      // Validate language code
      const supportedLanguages = ['en', 'tr', 'ru', 'hi'];
      if (!supportedLanguages.contains(languageCode)) {
        debugPrint('⚠️ Unsupported language code: $languageCode');
        return null;
      }

      // Create filename with timestamp for uniqueness
      final String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${file.name}';

      // NEW PATH STRUCTURE: sessions/audio/{sessionId}/{languageCode}/filename
      final String path = 'sessions/audio/$sessionId/$languageCode/$fileName';

      debugPrint('====== AUDIO UPLOAD (MULTI-LANG) ======');
      debugPrint('Session ID: $sessionId');
      debugPrint('Language: $languageCode');
      debugPrint('File name: $fileName');
      debugPrint('Full path: $path');
      debugPrint('=======================================');

      Reference ref = _storage.ref().child(path);

      // Upload file
      late UploadTask uploadTask;

      if (kIsWeb) {
        // Web platform
        if (file.bytes == null) {
          debugPrint('Error: File bytes are null for web platform');
          return null;
        }
        uploadTask = ref.putData(file.bytes!);
      } else {
        // Mobile platform
        if (file.path == null) {
          debugPrint('Error: File path is null for mobile platform');
          return null;
        }
        File fileToUpload = File(file.path!);
        uploadTask = ref.putFile(fileToUpload);
      }

      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        double progress =
            (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        debugPrint('Upload progress: ${progress.toStringAsFixed(2)}%');

        // Call progress callback if provided
        if (onProgress != null) {
          onProgress(progress / 100); // Convert to 0-1 range
        }
      });

      // Wait for upload to complete
      TaskSnapshot snapshot = await uploadTask;

      // Get download URL
      String downloadUrl = await snapshot.ref.getDownloadURL();
      debugPrint(
          '✅ Audio uploaded successfully for $languageCode: $downloadUrl');

      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Error uploading audio: $e');
      return null;
    }
  }

  /// Upload image file with language support
  /// New path structure: sessions/images/{sessionId}/{languageCode}/background.jpg
  static Future<String?> uploadImageWithLanguage({
    required String sessionId,
    required String languageCode, // 'en', 'tr', 'ru', 'hi'
    required PlatformFile file,
    Function(double)? onProgress,
  }) async {
    try {
      // Validate language code
      const supportedLanguages = ['en', 'tr', 'ru', 'hi'];
      if (!supportedLanguages.contains(languageCode)) {
        debugPrint('⚠️ Unsupported language code: $languageCode');
        return null;
      }

      // Create filename with timestamp
      final String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${file.name}';

      // NEW PATH STRUCTURE: sessions/images/{sessionId}/{languageCode}/filename
      final String path = 'sessions/images/$sessionId/$languageCode/$fileName';

      debugPrint('====== IMAGE UPLOAD (MULTI-LANG) ======');
      debugPrint('Session ID: $sessionId');
      debugPrint('Language: $languageCode');
      debugPrint('File name: $fileName');
      debugPrint('Full path: $path');
      debugPrint('======================================');

      Reference ref = _storage.ref().child(path);

      // Upload file
      late UploadTask uploadTask;

      if (kIsWeb) {
        // Web platform
        if (file.bytes == null) {
          debugPrint('Error: File bytes are null for web platform');
          return null;
        }
        uploadTask = ref.putData(file.bytes!);
      } else {
        // Mobile platform
        if (file.path == null) {
          debugPrint('Error: File path is null for mobile platform');
          return null;
        }
        File fileToUpload = File(file.path!);
        uploadTask = ref.putFile(fileToUpload);
      }

      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        double progress =
            (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        debugPrint('Upload progress: ${progress.toStringAsFixed(2)}%');

        // Call progress callback if provided
        if (onProgress != null) {
          onProgress(progress / 100); // Convert to 0-1 range
        }
      });

      // Wait for upload to complete
      TaskSnapshot snapshot = await uploadTask;

      // Get download URL
      String downloadUrl = await snapshot.ref.getDownloadURL();
      debugPrint(
          '✅ Image uploaded successfully for $languageCode: $downloadUrl');

      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Error uploading image: $e');
      return null;
    }
  }

  /// LEGACY: Upload audio file (kept for backward compatibility)
  /// @deprecated Use uploadAudioWithLanguage instead
  static Future<String?> uploadAudio({
    required String sessionId,
    required PlatformFile file,
    Function(double)? onProgress,
  }) async {
    debugPrint(
        '⚠️ Using legacy uploadAudio method - consider using uploadAudioWithLanguage');

    // Default to English for legacy uploads
    return uploadAudioWithLanguage(
      sessionId: sessionId,
      languageCode: 'en',
      file: file,
      onProgress: onProgress,
    );
  }

  /// LEGACY: Upload image file (kept for backward compatibility)
  /// @deprecated Use uploadImageWithLanguage instead
  static Future<String?> uploadImage({
    required String folder,
    required PlatformFile file,
    Function(double)? onProgress,
  }) async {
    debugPrint(
        '⚠️ Using legacy uploadImage method - consider using uploadImageWithLanguage');

    // Default to English for legacy uploads
    return uploadImageWithLanguage(
      sessionId: folder,
      languageCode: 'en',
      file: file,
      onProgress: onProgress,
    );
  }

  /// Delete file from storage
  static Future<bool> deleteFile(String fileUrl) async {
    try {
      // Get reference from URL
      Reference ref = _storage.refFromURL(fileUrl);

      // Delete file
      await ref.delete();
      debugPrint('✅ File deleted successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting file: $e');
      return false;
    }
  }

  /// Delete all language variants for a session
  static Future<void> deleteSessionFiles(String sessionId) async {
    try {
      const languages = ['en', 'tr', 'ru', 'hi'];

      for (final lang in languages) {
        try {
          // Delete audio files for this language
          final audioRef = _storage.ref('sessions/audio/$sessionId/$lang');
          final audioList = await audioRef.listAll();
          for (final item in audioList.items) {
            await item.delete();
            debugPrint('Deleted audio: ${item.fullPath}');
          }

          // Delete image files for this language
          final imageRef = _storage.ref('sessions/images/$sessionId/$lang');
          final imageList = await imageRef.listAll();
          for (final item in imageList.items) {
            await item.delete();
            debugPrint('Deleted image: ${item.fullPath}');
          }
        } catch (e) {
          debugPrint('Error deleting files for $lang: $e');
          // Continue with other languages
        }
      }

      debugPrint('✅ Deleted all files for session: $sessionId');
    } catch (e) {
      debugPrint('❌ Error in deleteSessionFiles: $e');
    }
  }

  /// Get storage usage statistics
  static Future<Map<String, dynamic>> getStorageStats() async {
    try {
      // Get all files in sessions folder

      int totalFiles = 0;

      // Count audio files
      final audioResult = await _storage.ref('sessions/audio').listAll();
      totalFiles += audioResult.items.length;

      // Count image files
      final imageResult = await _storage.ref('sessions/images').listAll();
      totalFiles += imageResult.items.length;

      return {
        'totalFiles': totalFiles,
        'audioFiles': audioResult.items.length,
        'imageFiles': imageResult.items.length,
      };
    } catch (e) {
      debugPrint('❌ Error getting storage stats: $e');
      return {
        'totalFiles': 0,
        'audioFiles': 0,
        'imageFiles': 0,
      };
    }
  }

  /// Pick audio file
  static Future<PlatformFile?> pickAudioFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        return result.files.first;
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error picking audio file: $e');
      return null;
    }
  }

  /// Pick image file
  static Future<PlatformFile?> pickImageFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        return result.files.first;
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error picking image file: $e');
      return null;
    }
  }

  /// Validate file size (in MB)
  static bool validateFileSize(PlatformFile file, int maxSizeMB) {
    final maxSizeBytes = maxSizeMB * 1024 * 1024;
    return file.size <= maxSizeBytes;
  }

  /// Get audio duration from metadata (if available)
  /// Returns duration in seconds
  static Future<int> getAudioDuration(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      final metadata = await ref.getMetadata();

      // Try to get duration from custom metadata
      final durationStr = metadata.customMetadata?['duration'];
      if (durationStr != null) {
        return int.tryParse(durationStr) ?? 0;
      }

      // If not available, return 0 (will be calculated by audio player)
      return 0;
    } catch (e) {
      debugPrint('⚠️ Error getting audio duration: $e');
      return 0;
    }
  }

  static Future<String?> uploadHomeCardImage({
    required String cardId,
    required PlatformFile file,
    Function(double)? onProgress,
  }) async {
    try {
      // Create filename with timestamp
      final String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${file.name}';

      // Path: home_cards/{cardId}/filename
      final String path = 'home_cards/$cardId/$fileName';

      debugPrint('====== HOME CARD IMAGE UPLOAD ======');
      debugPrint('Card ID: $cardId');
      debugPrint('File name: $fileName');
      debugPrint('Full path: $path');
      debugPrint('===================================');

      Reference ref = _storage.ref().child(path);

      // Upload file
      late UploadTask uploadTask;

      if (kIsWeb) {
        // Web platform
        if (file.bytes == null) {
          debugPrint('Error: File bytes are null for web platform');
          return null;
        }
        uploadTask = ref.putData(file.bytes!);
      } else {
        // Mobile platform
        if (file.path == null) {
          debugPrint('Error: File path is null for mobile platform');
          return null;
        }
        File fileToUpload = File(file.path!);
        uploadTask = ref.putFile(fileToUpload);
      }

      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        double progress =
            (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        debugPrint('Upload progress: ${progress.toStringAsFixed(2)}%');

        // Call progress callback if provided
        if (onProgress != null) {
          onProgress(progress / 100); // Convert to 0-1 range
        }
      });

      // Wait for upload to complete
      TaskSnapshot snapshot = await uploadTask;

      // Get download URL
      String downloadUrl = await snapshot.ref.getDownloadURL();
      debugPrint('✅ Home card image uploaded successfully: $downloadUrl');

      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Error uploading home card image: $e');
      return null;
    }
  }

  /// Delete home card image
  static Future<bool> deleteHomeCardImage(String imageUrl) async {
    try {
      Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      debugPrint('✅ Home card image deleted successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting home card image: $e');
      return false;
    }
  }

  /// Upload category background image
  /// Returns download URL on success, null on failure
  static Future<String?> uploadCategoryImage({
    required String categoryId,
    required PlatformFile file,
    Function(double)? onProgress,
  }) async {
    try {
      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = file.extension ?? 'jpg';
      final fileName = 'category_${categoryId}_$timestamp.$extension';

      // Create reference
      Reference ref = _storage.ref().child('categories/$categoryId/$fileName');

      debugPrint('📤 Uploading category image: $fileName');

      // Upload file
      UploadTask uploadTask;

      if (kIsWeb) {
        // Web platform
        if (file.bytes == null) {
          debugPrint('Error: File bytes are null for web platform');
          return null;
        }
        uploadTask = ref.putData(file.bytes!);
      } else {
        // Mobile platform
        if (file.path == null) {
          debugPrint('Error: File path is null for mobile platform');
          return null;
        }
        File fileToUpload = File(file.path!);
        uploadTask = ref.putFile(fileToUpload);
      }

      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        double progress =
            (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        debugPrint('Upload progress: ${progress.toStringAsFixed(2)}%');

        // Call progress callback if provided
        if (onProgress != null) {
          onProgress(progress / 100); // Convert to 0-1 range
        }
      });

      // Wait for upload to complete
      TaskSnapshot snapshot = await uploadTask;

      // Get download URL
      String downloadUrl = await snapshot.ref.getDownloadURL();
      debugPrint('✅ Category image uploaded successfully: $downloadUrl');

      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Error uploading category image: $e');
      return null;
    }
  }

  /// Delete category background image
  static Future<bool> deleteCategoryImage(String imageUrl) async {
    try {
      Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      debugPrint('✅ Category image deleted successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting category image: $e');
      return false;
    }
  }
}
