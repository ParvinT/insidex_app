// lib/services/download/download_database.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../models/downloaded_session.dart';

/// SQLite database service for managing downloaded sessions
/// Production-grade implementation with proper error handling and migrations
///
/// v3: Added user_id column for multi-user isolation on same device
class DownloadDatabase {
  static final DownloadDatabase _instance = DownloadDatabase._internal();
  factory DownloadDatabase() => _instance;
  DownloadDatabase._internal();

  static Database? _database;
  static const String _databaseName = 'insidex_downloads.db';
  static const int _databaseVersion = 3;

  // Table names
  static const String _tableDownloads = 'downloads';

  // Current user scope - all queries are filtered by this
  String? _currentUserId;

  /// Set the current user for scoped queries
  void setCurrentUser(String userId) {
    _currentUserId = userId;
    debugPrint('📂 [DownloadDB] User scope set: ${userId.substring(0, 8)}...');
  }

  /// Clear user scope (on logout)
  void clearCurrentUser() {
    _currentUserId = null;
    debugPrint('📂 [DownloadDB] User scope cleared');
  }

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
        user_id TEXT NOT NULL DEFAULT '',
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
        UNIQUE(session_id, language, user_id)
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

    await db.execute('''
      CREATE INDEX idx_downloads_user_id ON $_tableDownloads(user_id)
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

    // Migration v2 -> v3: Add user_id for multi-user isolation
    if (oldVersion < 3) {
      debugPrint('📦 [DownloadDB] Adding user_id column for user isolation');
      await db.execute(
          "ALTER TABLE $_tableDownloads ADD COLUMN user_id TEXT NOT NULL DEFAULT ''");
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_downloads_user_id ON $_tableDownloads(user_id)');
      debugPrint('✅ [DownloadDB] Migration v3 complete');
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

  /// Delete download by session ID and language (scoped to current user)
  Future<bool> deleteBySessionAndLanguage(
      String sessionId, String language) async {
    try {
      final db = await database;

      String where;
      List<dynamic> whereArgs;

      if (_currentUserId != null) {
        where = 'session_id = ? AND language = ? AND user_id = ?';
        whereArgs = [sessionId, language, _currentUserId];
      } else {
        where = 'session_id = ? AND language = ?';
        whereArgs = [sessionId, language];
      }

      final count = await db.delete(
        _tableDownloads,
        where: where,
        whereArgs: whereArgs,
      );
      debugPrint('🗑️ [DownloadDB] Deleted session: $sessionId ($language)');
      return count > 0;
    } catch (e) {
      debugPrint('❌ [DownloadDB] Delete error: $e');
      return false;
    }
  }

  /// Delete all downloads for a session (all languages, scoped to current user)
  Future<int> deleteAllForSession(String sessionId) async {
    try {
      final db = await database;

      String where;
      List<dynamic> whereArgs;

      if (_currentUserId != null) {
        where = 'session_id = ? AND user_id = ?';
        whereArgs = [sessionId, _currentUserId];
      } else {
        where = 'session_id = ?';
        whereArgs = [sessionId];
      }

      final count = await db.delete(
        _tableDownloads,
        where: where,
        whereArgs: whereArgs,
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

  /// Get download by session ID and language (scoped to current user)
  Future<DownloadedSession?> getBySessionAndLanguage(
    String sessionId,
    String language,
  ) async {
    try {
      final db = await database;

      String where;
      List<dynamic> whereArgs;

      if (_currentUserId != null) {
        where = 'session_id = ? AND language = ? AND user_id = ?';
        whereArgs = [sessionId, language, _currentUserId];
      } else {
        where = 'session_id = ? AND language = ?';
        whereArgs = [sessionId, language];
      }

      final maps = await db.query(
        _tableDownloads,
        where: where,
        whereArgs: whereArgs,
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

  /// Check if a session is downloaded for a specific language (scoped to current user)
  Future<bool> isDownloaded(String sessionId, String language) async {
    try {
      final db = await database;

      String query;
      List<dynamic> args;

      if (_currentUserId != null) {
        query =
            'SELECT COUNT(*) as count FROM $_tableDownloads WHERE session_id = ? AND language = ? AND status = ? AND user_id = ?';
        args = [
          sessionId,
          language,
          DownloadStatus.completed.value,
          _currentUserId
        ];
      } else {
        query =
            'SELECT COUNT(*) as count FROM $_tableDownloads WHERE session_id = ? AND language = ? AND status = ?';
        args = [sessionId, language, DownloadStatus.completed.value];
      }

      final result = await db.rawQuery(query, args);
      final count = Sqflite.firstIntValue(result) ?? 0;
      return count > 0;
    } catch (e) {
      debugPrint('❌ [DownloadDB] isDownloaded error: $e');
      return false;
    }
  }

  /// Check if session is downloaded in ANY language (scoped to current user)
  Future<bool> isDownloadedAnyLanguage(String sessionId) async {
    try {
      final db = await database;

      String query;
      List<dynamic> args;

      if (_currentUserId != null) {
        query =
            'SELECT COUNT(*) as count FROM $_tableDownloads WHERE session_id = ? AND status = ? AND user_id = ?';
        args = [sessionId, DownloadStatus.completed.value, _currentUserId];
      } else {
        query =
            'SELECT COUNT(*) as count FROM $_tableDownloads WHERE session_id = ? AND status = ?';
        args = [sessionId, DownloadStatus.completed.value];
      }

      final result = await db.rawQuery(query, args);
      final count = Sqflite.firstIntValue(result) ?? 0;
      return count > 0;
    } catch (e) {
      debugPrint('❌ [DownloadDB] isDownloadedAny error: $e');
      return false;
    }
  }

  /// Get all completed downloads (scoped to current user)
  Future<List<DownloadedSession>> getAllDownloads() async {
    try {
      final db = await database;

      String where;
      List<dynamic> whereArgs;

      if (_currentUserId != null) {
        where = 'status = ? AND user_id = ?';
        whereArgs = [DownloadStatus.completed.value, _currentUserId];
      } else {
        where = 'status = ?';
        whereArgs = [DownloadStatus.completed.value];
      }

      final maps = await db.query(
        _tableDownloads,
        where: where,
        whereArgs: whereArgs,
        orderBy: 'downloaded_at DESC',
      );

      return maps.map((map) => DownloadedSession.fromMap(map)).toList();
    } catch (e) {
      debugPrint('❌ [DownloadDB] Get all error: $e');
      return [];
    }
  }

  /// Get downloads for a specific language (scoped to current user)
  Future<List<DownloadedSession>> getDownloadsByLanguage(
      String language) async {
    try {
      final db = await database;

      String where;
      List<dynamic> whereArgs;

      if (_currentUserId != null) {
        where = 'language = ? AND status = ? AND user_id = ?';
        whereArgs = [language, DownloadStatus.completed.value, _currentUserId];
      } else {
        where = 'language = ? AND status = ?';
        whereArgs = [language, DownloadStatus.completed.value];
      }

      final maps = await db.query(
        _tableDownloads,
        where: where,
        whereArgs: whereArgs,
        orderBy: 'downloaded_at DESC',
      );

      return maps.map((map) => DownloadedSession.fromMap(map)).toList();
    } catch (e) {
      debugPrint('❌ [DownloadDB] Get by language error: $e');
      return [];
    }
  }

  /// Get downloads by category (scoped to current user)
  Future<List<DownloadedSession>> getDownloadsByCategory(
      String categoryId) async {
    try {
      final db = await database;

      String where;
      List<dynamic> whereArgs;

      if (_currentUserId != null) {
        where = 'category_id = ? AND status = ? AND user_id = ?';
        whereArgs = [
          categoryId,
          DownloadStatus.completed.value,
          _currentUserId
        ];
      } else {
        where = 'category_id = ? AND status = ?';
        whereArgs = [categoryId, DownloadStatus.completed.value];
      }

      final maps = await db.query(
        _tableDownloads,
        where: where,
        whereArgs: whereArgs,
        orderBy: 'downloaded_at DESC',
      );

      return maps.map((map) => DownloadedSession.fromMap(map)).toList();
    } catch (e) {
      debugPrint('❌ [DownloadDB] Get by category error: $e');
      return [];
    }
  }

  /// Get recently played downloads (scoped to current user)
  Future<List<DownloadedSession>> getRecentlyPlayed({int limit = 10}) async {
    try {
      final db = await database;

      String where;
      List<dynamic> whereArgs;

      if (_currentUserId != null) {
        where = 'status = ? AND user_id = ?';
        whereArgs = [DownloadStatus.completed.value, _currentUserId];
      } else {
        where = 'status = ?';
        whereArgs = [DownloadStatus.completed.value];
      }

      final maps = await db.query(
        _tableDownloads,
        where: where,
        whereArgs: whereArgs,
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

  /// Get total download count (scoped to current user)
  Future<int> getDownloadCount() async {
    try {
      final db = await database;

      String query;
      List<dynamic> args;

      if (_currentUserId != null) {
        query =
            'SELECT COUNT(*) as count FROM $_tableDownloads WHERE status = ? AND user_id = ?';
        args = [DownloadStatus.completed.value, _currentUserId];
      } else {
        query =
            'SELECT COUNT(*) as count FROM $_tableDownloads WHERE status = ?';
        args = [DownloadStatus.completed.value];
      }

      final result = await db.rawQuery(query, args);
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      debugPrint('❌ [DownloadDB] Count error: $e');
      return 0;
    }
  }

  /// Get total download size in bytes (scoped to current user)
  Future<int> getTotalDownloadSize() async {
    try {
      final db = await database;

      String query;
      List<dynamic> args;

      if (_currentUserId != null) {
        query =
            'SELECT SUM(file_size_bytes) as total FROM $_tableDownloads WHERE status = ? AND user_id = ?';
        args = [DownloadStatus.completed.value, _currentUserId];
      } else {
        query =
            'SELECT SUM(file_size_bytes) as total FROM $_tableDownloads WHERE status = ?';
        args = [DownloadStatus.completed.value];
      }

      final result = await db.rawQuery(query, args);
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

  /// Delete all downloads (scoped to current user)
  Future<int> deleteAllDownloads() async {
    try {
      final db = await database;

      int count;
      if (_currentUserId != null) {
        count = await db.delete(
          _tableDownloads,
          where: 'user_id = ?',
          whereArgs: [_currentUserId],
        );
      } else {
        count = await db.delete(_tableDownloads);
      }

      debugPrint('🗑️ [DownloadDB] Deleted all downloads (rows: $count)');
      return count;
    } catch (e) {
      debugPrint('❌ [DownloadDB] Delete all error: $e');
      return 0;
    }
  }

  /// Get ALL downloads regardless of user (for cleanup validation only)
  Future<List<DownloadedSession>> getAllDownloadsAllUsers() async {
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
      debugPrint('❌ [DownloadDB] Get all (all users) error: $e');
      return [];
    }
  }

  /// Delete failed downloads (scoped to current user)
  Future<int> deleteFailedDownloads() async {
    try {
      final db = await database;

      String where;
      List<dynamic> whereArgs;

      if (_currentUserId != null) {
        where = 'status = ? AND user_id = ?';
        whereArgs = [DownloadStatus.failed.value, _currentUserId];
      } else {
        where = 'status = ?';
        whereArgs = [DownloadStatus.failed.value];
      }

      final count = await db.delete(
        _tableDownloads,
        where: where,
        whereArgs: whereArgs,
      );
      debugPrint('🗑️ [DownloadDB] Deleted failed downloads (rows: $count)');
      return count;
    } catch (e) {
      debugPrint('❌ [DownloadDB] Delete failed error: $e');
      return 0;
    }
  }

  /// Claim orphaned downloads for current user
  /// Called on first login after migration - assigns unowned downloads to this user
  Future<int> claimOrphanedDownloads(String userId) async {
    try {
      final db = await database;
      final count = await db.update(
        _tableDownloads,
        {'user_id': userId},
        where: "user_id = '' OR user_id IS NULL",
      );

      if (count > 0) {
        debugPrint(
            '📦 [DownloadDB] Claimed $count orphaned downloads for ${userId.substring(0, 8)}...');
      }
      return count;
    } catch (e) {
      debugPrint('❌ [DownloadDB] Claim orphaned error: $e');
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
