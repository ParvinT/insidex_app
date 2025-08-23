// lib/services/storage_service.dart

import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';

class StorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload audio file
  static Future<String?> uploadAudio({
    required String sessionId,
    required PlatformFile file,
  }) async {
    try {
      final String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final String path = 'sessions/audio/$sessionId/$fileName';

      Reference ref = _storage.ref().child(path);

      // Upload file
      late UploadTask uploadTask;

      if (kIsWeb) {
        // Web platform
        uploadTask = ref.putData(file.bytes!);
      } else {
        // Mobile platform
        File fileToUpload = File(file.path!);
        uploadTask = ref.putFile(fileToUpload);
      }

      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        double progress =
            (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        debugPrint('Upload progress: ${progress.toStringAsFixed(2)}%');
      });

      // Wait for upload to complete
      TaskSnapshot snapshot = await uploadTask;

      // Get download URL
      String downloadUrl = await snapshot.ref.getDownloadURL();
      debugPrint('Audio uploaded successfully: $downloadUrl');

      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading audio: $e');
      return null;
    }
  }

  // Upload image file
  static Future<String?> uploadImage({
    required String folder,
    required PlatformFile file,
  }) async {
    try {
      final String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final String path = 'sessions/images/$folder/$fileName';

      Reference ref = _storage.ref().child(path);

      // Upload file
      late UploadTask uploadTask;

      if (kIsWeb) {
        // Web platform
        uploadTask = ref.putData(file.bytes!);
      } else {
        // Mobile platform
        File fileToUpload = File(file.path!);
        uploadTask = ref.putFile(fileToUpload);
      }

      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        double progress =
            (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        debugPrint('Upload progress: ${progress.toStringAsFixed(2)}%');
      });

      // Wait for upload to complete
      TaskSnapshot snapshot = await uploadTask;

      // Get download URL
      String downloadUrl = await snapshot.ref.getDownloadURL();
      debugPrint('Image uploaded successfully: $downloadUrl');

      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  // Delete file from storage
  static Future<bool> deleteFile(String fileUrl) async {
    try {
      // Get reference from URL
      Reference ref = _storage.refFromURL(fileUrl);

      // Delete file
      await ref.delete();
      debugPrint('File deleted successfully');
      return true;
    } catch (e) {
      debugPrint('Error deleting file: $e');
      return false;
    }
  }

  // Get storage usage statistics
  static Future<Map<String, dynamic>> getStorageStats() async {
    try {
      // Get all files in sessions folder
      final ListResult result = await _storage.ref('sessions').listAll();

      int totalFiles = 0;
      int totalSize = 0;

      // Count audio files
      final audioResult = await _storage.ref('sessions/audio').listAll();
      totalFiles += audioResult.items.length;

      // Count image files
      final imageResult = await _storage.ref('sessions/images').listAll();
      totalFiles += imageResult.items.length;

      // Note: Getting actual file sizes requires downloading metadata for each file
      // This can be expensive for many files

      return {
        'totalFiles': totalFiles,
        'audioFiles': audioResult.items.length,
        'imageFiles': imageResult.items.length,
        'totalSizeBytes': totalSize,
        'totalSizeMB': (totalSize / (1024 * 1024)).toStringAsFixed(2),
      };
    } catch (e) {
      debugPrint('Error getting storage stats: $e');
      return {
        'totalFiles': 0,
        'audioFiles': 0,
        'imageFiles': 0,
        'totalSizeBytes': 0,
        'totalSizeMB': '0',
      };
    }
  }

  // Pick audio file
  static Future<PlatformFile?> pickAudioFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        PlatformFile file = result.files.first;

        // Validate file size (max 50MB for audio)
        if (file.size > 50 * 1024 * 1024) {
          throw Exception('Audio file size must be less than 50MB');
        }

        debugPrint(
            'Audio file selected: ${file.name}, Size: ${file.size} bytes');
        return file;
      }

      return null;
    } catch (e) {
      debugPrint('Error picking audio file: $e');
      rethrow;
    }
  }

  // Pick image file
  static Future<PlatformFile?> pickImageFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        PlatformFile file = result.files.first;

        // Validate file size (max 5MB for images)
        if (file.size > 5 * 1024 * 1024) {
          throw Exception('Image file size must be less than 5MB');
        }

        debugPrint(
            'Image file selected: ${file.name}, Size: ${file.size} bytes');
        return file;
      }

      return null;
    } catch (e) {
      debugPrint('Error picking image file: $e');
      rethrow;
    }
  }
}
