// lib/services/download/download_database.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../models/downloaded_session.dart';

/// SQLite database service for managing downloaded sessions
/// Production-grade implementation with proper error handling and migrations
class DownloadDatabase {
  static final DownloadDatabase _instance = DownloadDatabase._internal();
  factory DownloadDatabase() => _instance;
  DownloadDatabase._internal();

  static Database? _database;
  static const String _databaseName = 'insidex_downloads.db';
  static const int _databaseVersion = 2;

  // Table names
  static const String _tableDownloads = 'downloads';

  /// Get database instance (lazy initialization)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize database
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    debugPrint('📂 [DownloadDB] Initializing database at: $path');

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: (db) {
        debugPrint('✅ [DownloadDB] Database opened successfully');
      },
    );
  }

  /// Create database tables
  Future<void> _onCreate(Database db, int version) async {
    debugPrint('🔨 [DownloadDB] Creating tables (version $version)');

    await db.execute('''
      CREATE TABLE $_tableDownloads (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        language TEXT NOT NULL,
        encrypted_audio_path TEXT NOT NULL,
        image_path TEXT NOT NULL,
        title TEXT NOT NULL,
        artist TEXT NOT NULL DEFAULT 'INSIDEX',
        duration_seconds INTEGER NOT NULL,
        file_size_bytes INTEGER NOT NULL,
        downloaded_at INTEGER NOT NULL,
        last_played_at INTEGER NOT NULL,
        status TEXT NOT NULL DEFAULT 'completed',
        progress REAL NOT NULL DEFAULT 1.0,
        category_id TEXT,
        category_name TEXT,
        session_number INTEGER,
        description TEXT,
        intro_title TEXT,
        intro_content TEXT,
        UNIQUE(session_id, language)
      )
    ''');

    // Create indexes for faster queries
    await db.execute('''
      CREATE INDEX idx_downloads_session_id ON $_tableDownloads(session_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_downloads_language ON $_tableDownloads(language)
    ''');

    await db.execute('''
      CREATE INDEX idx_downloads_status ON $_tableDownloads(status)
    ''');

    await db.execute('''
      CREATE INDEX idx_downloads_downloaded_at ON $_tableDownloads(downloaded_at DESC)
    ''');

    debugPrint('✅ [DownloadDB] Tables created successfully');
  }

  /// Handle database migrations
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('⬆️ [DownloadDB] Upgrading from v$oldVersion to v$newVersion');

    // Migration v1 -> v2: Add introduction fields
    if (oldVersion < 2) {
      debugPrint(
          '📦 [DownloadDB] Adding intro_title and intro_content columns');
      await db
          .execute('ALTER TABLE $_tableDownloads ADD COLUMN intro_title TEXT');
      await db.execute(
          'ALTER TABLE $_tableDownloads ADD COLUMN intro_content TEXT');
    }
  }

  // =================== CRUD OPERATIONS ===================

  /// Insert a new download
  Future<bool> insertDownload(DownloadedSession download) async {
    try {
      final db = await database;
      await db.insert(
        _tableDownloads,
        download.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint('✅ [DownloadDB] Inserted: ${download.id}');
      return true;
    } catch (e) {
      debugPrint('❌ [DownloadDB] Insert error: $e');
      return false;
    }
  }

  /// Update an existing download
  Future<bool> updateDownload(DownloadedSession download) async {
    try {
      final db = await database;
      final count = await db.update(
        _tableDownloads,
        download.toMap(),
        where: 'id = ?',
        whereArgs: [download.id],
      );
      debugPrint('✅ [DownloadDB] Updated: ${download.id} (rows: $count)');
      return count > 0;
    } catch (e) {
      debugPrint('❌ [DownloadDB] Update error: $e');
      return false;
    }
  }

  /// Delete a download by ID
  Future<bool> deleteDownload(String id) async {
    try {
      final db = await database;
      final count = await db.delete(
        _tableDownloads,
        where: 'id = ?',
        whereArgs: [id],
      );
      debugPrint('🗑️ [DownloadDB] Deleted: $id (rows: $count)');
      return count > 0;
    } catch (e) {
      debugPrint('❌ [DownloadDB] Delete error: $e');
      return false;
    }
  }

  /// Delete download by session ID and language
  Future<bool> deleteBySessionAndLanguage(
      String sessionId, String language) async {
    try {
      final db = await database;
      final count = await db.delete(
        _tableDownloads,
        where: 'session_id = ? AND language = ?',
        whereArgs: [sessionId, language],
      );
      debugPrint('🗑️ [DownloadDB] Deleted session: $sessionId ($language)');
      return count > 0;
    } catch (e) {
      debugPrint('❌ [DownloadDB] Delete error: $e');
      return false;
    }
  }

  /// Delete all downloads for a session (all languages)
  Future<int> deleteAllForSession(String sessionId) async {
    try {
      final db = await database;
      final count = await db.delete(
        _tableDownloads,
        where: 'session_id = ?',
        whereArgs: [sessionId],
      );
      debugPrint(
          '🗑️ [DownloadDB] Deleted all for session: $sessionId (rows: $count)');
      return count;
    } catch (e) {
      debugPrint('❌ [DownloadDB] Delete all error: $e');
      return 0;
    }
  }

  // =================== QUERY OPERATIONS ===================

  /// Get download by ID
  Future<DownloadedSession?> getDownload(String id) async {
    try {
      final db = await database;
      final maps = await db.query(
        _tableDownloads,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return DownloadedSession.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      debugPrint('❌ [DownloadDB] Get error: $e');
      return null;
    }
  }

  /// Get download by session ID and language
  Future<DownloadedSession?> getBySessionAndLanguage(
    String sessionId,
    String language,
  ) async {
    try {
      final db = await database;
      final maps = await db.query(
        _tableDownloads,
        where: 'session_id = ? AND language = ?',
        whereArgs: [sessionId, language],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return DownloadedSession.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      debugPrint('❌ [DownloadDB] Get by session error: $e');
      return null;
    }
  }

  /// Check if a session is downloaded for a specific language
  Future<bool> isDownloaded(String sessionId, String language) async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM $_tableDownloads WHERE session_id = ? AND language = ? AND status = ?',
        [sessionId, language, DownloadStatus.completed.value],
      );
      final count = Sqflite.firstIntValue(result) ?? 0;
      return count > 0;
    } catch (e) {
      debugPrint('❌ [DownloadDB] isDownloaded error: $e');
      return false;
    }
  }

  /// Check if session is downloaded in ANY language
  Future<bool> isDownloadedAnyLanguage(String sessionId) async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM $_tableDownloads WHERE session_id = ? AND status = ?',
        [sessionId, DownloadStatus.completed.value],
      );
      final count = Sqflite.firstIntValue(result) ?? 0;
      return count > 0;
    } catch (e) {
      debugPrint('❌ [DownloadDB] isDownloadedAny error: $e');
      return false;
    }
  }

  /// Get all completed downloads
  Future<List<DownloadedSession>> getAllDownloads() async {
    try {
      final db = await database;
      final maps = await db.query(
        _tableDownloads,
        where: 'status = ?',
        whereArgs: [DownloadStatus.completed.value],
        orderBy: 'downloaded_at DESC',
      );

      return maps.map((map) => DownloadedSession.fromMap(map)).toList();
    } catch (e) {
      debugPrint('❌ [DownloadDB] Get all error: $e');
      return [];
    }
  }

  /// Get downloads for a specific language
  Future<List<DownloadedSession>> getDownloadsByLanguage(
      String language) async {
    try {
      final db = await database;
      final maps = await db.query(
        _tableDownloads,
        where: 'language = ? AND status = ?',
        whereArgs: [language, DownloadStatus.completed.value],
        orderBy: 'downloaded_at DESC',
      );

      return maps.map((map) => DownloadedSession.fromMap(map)).toList();
    } catch (e) {
      debugPrint('❌ [DownloadDB] Get by language error: $e');
      return [];
    }
  }

  /// Get downloads by category
  Future<List<DownloadedSession>> getDownloadsByCategory(
      String categoryId) async {
    try {
      final db = await database;
      final maps = await db.query(
        _tableDownloads,
        where: 'category_id = ? AND status = ?',
        whereArgs: [categoryId, DownloadStatus.completed.value],
        orderBy: 'downloaded_at DESC',
      );

      return maps.map((map) => DownloadedSession.fromMap(map)).toList();
    } catch (e) {
      debugPrint('❌ [DownloadDB] Get by category error: $e');
      return [];
    }
  }

  /// Get recently played downloads
  Future<List<DownloadedSession>> getRecentlyPlayed({int limit = 10}) async {
    try {
      final db = await database;
      final maps = await db.query(
        _tableDownloads,
        where: 'status = ?',
        whereArgs: [DownloadStatus.completed.value],
        orderBy: 'last_played_at DESC',
        limit: limit,
      );

      return maps.map((map) => DownloadedSession.fromMap(map)).toList();
    } catch (e) {
      debugPrint('❌ [DownloadDB] Get recent error: $e');
      return [];
    }
  }

  /// Update last played timestamp
  Future<bool> updateLastPlayed(String id) async {
    try {
      final db = await database;
      final count = await db.update(
        _tableDownloads,
        {'last_played_at': DateTime.now().millisecondsSinceEpoch},
        where: 'id = ?',
        whereArgs: [id],
      );
      return count > 0;
    } catch (e) {
      debugPrint('❌ [DownloadDB] Update last played error: $e');
      return false;
    }
  }

  /// Update download status and progress
  Future<bool> updateStatus(
    String id,
    DownloadStatus status, {
    double? progress,
  }) async {
    try {
      final db = await database;
      final Map<String, dynamic> values = {'status': status.value};
      if (progress != null) {
        values['progress'] = progress;
      }

      final count = await db.update(
        _tableDownloads,
        values,
        where: 'id = ?',
        whereArgs: [id],
      );
      return count > 0;
    } catch (e) {
      debugPrint('❌ [DownloadDB] Update status error: $e');
      return false;
    }
  }

  // =================== STATISTICS ===================

  /// Get total download count
  Future<int> getDownloadCount() async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM $_tableDownloads WHERE status = ?',
        [DownloadStatus.completed.value],
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      debugPrint('❌ [DownloadDB] Count error: $e');
      return 0;
    }
  }

  /// Get total download size in bytes
  Future<int> getTotalDownloadSize() async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        'SELECT SUM(file_size_bytes) as total FROM $_tableDownloads WHERE status = ?',
        [DownloadStatus.completed.value],
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      debugPrint('❌ [DownloadDB] Size error: $e');
      return 0;
    }
  }

  /// Get download statistics
  Future<DownloadStats> getStats() async {
    final count = await getDownloadCount();
    final totalSize = await getTotalDownloadSize();

    return DownloadStats(
      totalCount: count,
      totalSizeBytes: totalSize,
    );
  }

  // =================== CLEANUP ===================

  /// Delete all downloads
  Future<int> deleteAllDownloads() async {
    try {
      final db = await database;
      final count = await db.delete(_tableDownloads);
      debugPrint('🗑️ [DownloadDB] Deleted all downloads (rows: $count)');
      return count;
    } catch (e) {
      debugPrint('❌ [DownloadDB] Delete all error: $e');
      return 0;
    }
  }

  /// Delete failed downloads
  Future<int> deleteFailedDownloads() async {
    try {
      final db = await database;
      final count = await db.delete(
        _tableDownloads,
        where: 'status = ?',
        whereArgs: [DownloadStatus.failed.value],
      );
      debugPrint('🗑️ [DownloadDB] Deleted failed downloads (rows: $count)');
      return count;
    } catch (e) {
      debugPrint('❌ [DownloadDB] Delete failed error: $e');
      return 0;
    }
  }

  /// Close database connection
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      debugPrint('🔒 [DownloadDB] Database closed');
    }
  }
}

/// Download statistics
class DownloadStats {
  final int totalCount;
  final int totalSizeBytes;

  const DownloadStats({
    required this.totalCount,
    required this.totalSizeBytes,
  });

  /// Get formatted total size
  String get formattedSize {
    if (totalSizeBytes < 1024) {
      return '$totalSizeBytes B';
    } else if (totalSizeBytes < 1024 * 1024) {
      return '${(totalSizeBytes / 1024).toStringAsFixed(1)} KB';
    } else if (totalSizeBytes < 1024 * 1024 * 1024) {
      return '${(totalSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(totalSizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  @override
  String toString() {
    return 'DownloadStats(count: $totalCount, size: $formattedSize)';
  }
}
