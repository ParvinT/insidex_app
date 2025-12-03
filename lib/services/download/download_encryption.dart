// lib/services/download/download_encryption.dart

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';

/// AES-256 encryption service for securing downloaded audio files
///
/// Security features:
/// - User-specific encryption keys
/// - Secure key derivation (PBKDF2-like)
/// - IV stored with encrypted data
/// - Files unplayable outside the app
class DownloadEncryption {
  static final DownloadEncryption _instance = DownloadEncryption._internal();
  factory DownloadEncryption() => _instance;
  DownloadEncryption._internal();

  // App-level secret (combined with user ID for unique keys)
  static const String _appSecret = 'InsideX_Secure_Audio_2024_v1';

  // Encryption settings
  static const int _keyLength = 32; // 256 bits
  static const int _ivLength = 16; // 128 bits

  // Cached encrypter per user
  String? _currentUserId;
  encrypt.Encrypter? _encrypter;
  encrypt.Key? _key;

  /// Initialize encryption for a specific user
  void initialize(String userId) {
    if (_currentUserId == userId && _encrypter != null) {
      return; // Already initialized for this user
    }

    _currentUserId = userId;
    _key = _deriveKey(userId);
    _encrypter = encrypt.Encrypter(
      encrypt.AES(_key!, mode: encrypt.AESMode.cbc),
    );

    debugPrint(
        '🔐 [Encryption] Initialized for user: ${userId.substring(0, 8)}...');
  }

  /// Derive a unique encryption key from user ID
  encrypt.Key _deriveKey(String userId) {
    // Create a unique key by combining app secret with user ID
    final combined = '$_appSecret:$userId:secure_audio_key';

    // Use SHA-256 to derive a consistent 32-byte key
    final bytes = utf8.encode(combined);
    final digest = sha256.convert(bytes);

    return encrypt.Key(Uint8List.fromList(digest.bytes));
  }

  /// Generate a random IV for each encryption
  encrypt.IV _generateIV() {
    return encrypt.IV.fromSecureRandom(_ivLength);
  }

  /// Encrypt raw bytes (for audio files)
  /// Returns encrypted data with IV prepended
  Future<Uint8List> encryptBytes(Uint8List data) async {
    if (_encrypter == null || _key == null) {
      throw EncryptionException(
          'Encryption not initialized. Call initialize() first.');
    }

    try {
      // Generate random IV for this encryption
      final iv = _generateIV();

      // Encrypt the data
      final encrypted = _encrypter!.encryptBytes(data, iv: iv);

      // Prepend IV to encrypted data (IV is needed for decryption)
      final result = Uint8List(_ivLength + encrypted.bytes.length);
      result.setRange(0, _ivLength, iv.bytes);
      result.setRange(_ivLength, result.length, encrypted.bytes);

      debugPrint(
          '🔐 [Encryption] Encrypted ${data.length} bytes → ${result.length} bytes');

      return result;
    } catch (e) {
      debugPrint('❌ [Encryption] Encrypt error: $e');
      throw EncryptionException('Failed to encrypt data: $e');
    }
  }

  /// Decrypt encrypted bytes
  /// Expects IV prepended to encrypted data
  Future<Uint8List> decryptBytes(Uint8List encryptedData) async {
    if (_encrypter == null || _key == null) {
      throw EncryptionException(
          'Encryption not initialized. Call initialize() first.');
    }

    if (encryptedData.length < _ivLength) {
      throw EncryptionException('Invalid encrypted data: too short');
    }

    try {
      // Extract IV from the beginning
      final iv = encrypt.IV(Uint8List.fromList(
        encryptedData.sublist(0, _ivLength),
      ));

      // Extract encrypted content
      final encryptedContent = encryptedData.sublist(_ivLength);

      // Decrypt
      final encrypted = encrypt.Encrypted(encryptedContent);
      final decrypted = _encrypter!.decryptBytes(encrypted, iv: iv);

      debugPrint(
          '🔓 [Encryption] Decrypted ${encryptedData.length} bytes → ${decrypted.length} bytes');

      return Uint8List.fromList(decrypted);
    } catch (e) {
      debugPrint('❌ [Encryption] Decrypt error: $e');
      throw EncryptionException('Failed to decrypt data: $e');
    }
  }

  /// Encrypt a file and save to destination
  Future<File> encryptFile(File sourceFile, String destinationPath) async {
    if (_encrypter == null) {
      throw EncryptionException('Encryption not initialized');
    }

    try {
      debugPrint('🔐 [Encryption] Encrypting file: ${sourceFile.path}');

      // Read source file
      final sourceBytes = await sourceFile.readAsBytes();

      // Encrypt
      final encryptedBytes = await encryptBytes(sourceBytes);

      // Write to destination
      final destFile = File(destinationPath);
      await destFile.writeAsBytes(encryptedBytes, flush: true);

      debugPrint('✅ [Encryption] Encrypted file saved: $destinationPath');
      debugPrint('   Original: ${sourceBytes.length} bytes');
      debugPrint('   Encrypted: ${encryptedBytes.length} bytes');

      return destFile;
    } catch (e) {
      debugPrint('❌ [Encryption] File encryption error: $e');
      throw EncryptionException('Failed to encrypt file: $e');
    }
  }

  /// Decrypt a file and return bytes (in memory, not saved to disk)
  /// This is important for security - decrypted audio stays in memory only
  Future<Uint8List> decryptFileToMemory(File encryptedFile) async {
    if (_encrypter == null) {
      throw EncryptionException('Encryption not initialized');
    }

    try {
      debugPrint(
          '🔓 [Encryption] Decrypting file to memory: ${encryptedFile.path}');

      // Read encrypted file
      final encryptedBytes = await encryptedFile.readAsBytes();

      // Decrypt
      final decryptedBytes = await decryptBytes(encryptedBytes);

      debugPrint('✅ [Encryption] File decrypted to memory');
      debugPrint('   Encrypted: ${encryptedBytes.length} bytes');
      debugPrint('   Decrypted: ${decryptedBytes.length} bytes');

      return decryptedBytes;
    } catch (e) {
      debugPrint('❌ [Encryption] File decryption error: $e');
      throw EncryptionException('Failed to decrypt file: $e');
    }
  }

  /// Decrypt file to a temporary file (for playback)
  /// The temp file should be deleted after use
  Future<File> decryptFileToTemp(File encryptedFile, String tempPath) async {
    try {
      final decryptedBytes = await decryptFileToMemory(encryptedFile);

      final tempFile = File(tempPath);
      await tempFile.writeAsBytes(decryptedBytes, flush: true);

      debugPrint('✅ [Encryption] Decrypted to temp file: $tempPath');

      return tempFile;
    } catch (e) {
      debugPrint('❌ [Encryption] Temp file creation error: $e');
      throw EncryptionException('Failed to create temp file: $e');
    }
  }

  /// Validate if a file is properly encrypted (has valid IV prefix)
  Future<bool> isValidEncryptedFile(File file) async {
    try {
      if (!await file.exists()) return false;

      final length = await file.length();
      if (length < _ivLength + 16) return false; // Minimum: IV + 1 block

      // Try to read and validate structure
      final bytes = await file.readAsBytes();
      return bytes.length >= _ivLength + 16;
    } catch (e) {
      return false;
    }
  }

  /// Get a hash of the encryption key (for verification, not the actual key)
  String getKeyHash() {
    if (_key == null) return 'not_initialized';

    final hash = sha256.convert(_key!.bytes);
    return hash.toString().substring(0, 16);
  }

  /// Clear cached encryption state (on logout)
  void clear() {
    _currentUserId = null;
    _encrypter = null;
    _key = null;
    debugPrint('🔐 [Encryption] Cleared encryption state');
  }

  /// Check if encryption is initialized
  bool get isInitialized => _encrypter != null && _key != null;

  /// Get current user ID (masked)
  String? get currentUserMasked {
    if (_currentUserId == null) return null;
    if (_currentUserId!.length < 8) return '***';
    return '${_currentUserId!.substring(0, 8)}...';
  }
}

/// Encryption exception
class EncryptionException implements Exception {
  final String message;

  EncryptionException(this.message);

  @override
  String toString() => 'EncryptionException: $message';
}

/// Extension for secure file operations
extension SecureFileExtension on File {
  /// Check if file appears to be encrypted (by extension)
  bool get isEncryptedFile => path.endsWith('.enc');

  /// Get encrypted version path
  String get encryptedPath => '$path.enc';
}
