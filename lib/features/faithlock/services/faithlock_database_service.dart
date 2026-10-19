import 'dart:io';
import 'package:faithlock/features/faithlock/models/export.dart';
import 'package:faithlock/features/faithlock/services/bible_database_loader.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/material.dart';

class FaithLockDatabaseService {
  static final FaithLockDatabaseService _instance = FaithLockDatabaseService._internal();
  factory FaithLockDatabaseService() => _instance;
  FaithLockDatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'faithlock.db');

    // Check if database exists and has verses
    final dbFile = File(path);
    if (await dbFile.exists()) {
      try {
        final testDb = await openDatabase(path, readOnly: true);
        final result = await testDb.rawQuery('SELECT COUNT(*) as count FROM verses');
        final count = result.first['count'] as int;
        await testDb.close();

        if (count == 0) {
          await deleteDatabase(path);
        }
      } catch (e) {
        await deleteDatabase(path);
      }
    }

    return await openDatabase(
      path,
      version: 5,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Verses table with curriculum support
    await db.execute('''
      CREATE TABLE verses (
        id TEXT PRIMARY KEY,
        text TEXT NOT NULL,
        reference TEXT NOT NULL,
        book TEXT NOT NULL,
        chapter INTEGER NOT NULL,
        verse INTEGER NOT NULL,
        category TEXT NOT NULL,
        translation TEXT DEFAULT 'BSB',
        curriculum_week INTEGER,
        difficulty INTEGER,
        keyword TEXT
      )
    ''');

    // Lock schedules table
    await db.execute('''
      CREATE TABLE lock_schedules (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        days TEXT NOT NULL,
        is_enabled INTEGER DEFAULT 1,
        type TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // User stats table
    await db.execute('''
      CREATE TABLE user_stats (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL UNIQUE,
        verses_read INTEGER DEFAULT 0,
        successful_unlocks INTEGER DEFAULT 0,
        failed_attempts INTEGER DEFAULT 0,
        screen_time_minutes INTEGER DEFAULT 0
      )
    ''');

    // Unlock history table
    await db.execute('''
      CREATE TABLE unlock_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        verse_id TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        was_successful INTEGER NOT NULL,
        attempt_count INTEGER DEFAULT 1,
        time_to_unlock INTEGER,
        unlock_duration_minutes INTEGER,
        unlock_method TEXT,
        FOREIGN KEY (verse_id) REFERENCES verses(id)
      )
    ''');

    // Favorite verses table
    await db.execute('''
      CREATE TABLE favorite_verses (
        user_id TEXT DEFAULT 'default',
        verse_id TEXT,
        created_at TEXT NOT NULL,
        PRIMARY KEY (user_id, verse_id),
        FOREIGN KEY (verse_id) REFERENCES verses(id)
      )
    ''');

    // Earned badges table
    await db.execute('''
      CREATE TABLE earned_badges (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        badge_id TEXT NOT NULL UNIQUE,
        earned_at TEXT NOT NULL
      )
    ''');

    // Seed initial verses
    await _seedInitialVerses(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      await db.execute('''
        ALTER TABLE unlock_history
        ADD COLUMN unlock_duration_minutes INTEGER
      ''');
      debugPrint('✅ Database upgraded to version 3: Added unlock_duration_minutes column');
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS earned_badges (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          badge_id TEXT NOT NULL UNIQUE,
          earned_at TEXT NOT NULL
        )
      ''');
      debugPrint('✅ Database upgraded to version 4: Added earned_badges table');
    }
    if (oldVersion < 5) {
      await db.execute('''
        ALTER TABLE unlock_history
        ADD COLUMN unlock_method TEXT
      ''');
      debugPrint('✅ Database upgraded to version 5: Added unlock_method column');
    }
  }

  // ==================== VERSE OPERATIONS ====================

  Future<int> insertVerse(BibleVerse verse) async {
    final db = await database;
    return await db.insert('verses', verse.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<BibleVerse>> getAllVerses() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('verses');
    return List.generate(maps.length, (i) => BibleVerse.fromJson(maps[i]));
  }

  Future<BibleVerse?> getVerseById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'verses',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return BibleVerse.fromJson(maps.first);
  }

  Future<List<BibleVerse>> getVersesByCategory(VerseCategory category) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'verses',
      where: 'category = ?',
      whereArgs: [category.value],
    );
    return List.generate(maps.length, (i) => BibleVerse.fromJson(maps[i]));
  }

  /// Get verses by category and curriculum week (for structured learning)
  Future<List<BibleVerse>> getVersesByCurriculumWeek({
    required VerseCategory category,
    required int week,
  }) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'verses',
      where: 'category = ? AND curriculum_week = ?',
      whereArgs: [category.value, week],
    );
    return List.generate(maps.length, (i) => BibleVerse.fromJson(maps[i]));
  }

  /// Get verses by difficulty level
  Future<List<BibleVerse>> getVersesByDifficulty(int difficulty) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'verses',
      where: 'difficulty = ?',
      whereArgs: [difficulty],
    );
    return List.generate(maps.length, (i) => BibleVerse.fromJson(maps[i]));
  }

  Future<List<BibleVerse>> searchVerses(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'verses',
      where: 'text LIKE ? OR reference LIKE ? OR book LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
    );
    return List.generate(maps.length, (i) => BibleVerse.fromJson(maps[i]));
  }

  Future<BibleVerse?> getRandomVerse({VerseCategory? category}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = category != null
        ? await db.query('verses', where: 'category = ?', whereArgs: [category.value])
        : await db.query('verses');

    if (maps.isEmpty) return null;

    maps.shuffle();
    return BibleVerse.fromJson(maps.first);
  }

  // ==================== SCHEDULE OPERATIONS ====================

  Future<int> insertSchedule(LockSchedule schedule) async {
    final db = await database;
    return await db.insert('lock_schedules', schedule.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateSchedule(LockSchedule schedule) async {
    final db = await database;
    return await db.update(
      'lock_schedules',
      schedule.toJson(),
      where: 'id = ?',
      whereArgs: [schedule.id],
    );
  }

  Future<int> deleteSchedule(String id) async {
    final db = await database;
    return await db.delete('lock_schedules', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<LockSchedule>> getAllSchedules() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('lock_schedules');
    return List.generate(maps.length, (i) => LockSchedule.fromJson(maps[i]));
  }

  Future<List<LockSchedule>> getActiveSchedules() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'lock_schedules',
      where: 'is_enabled = ?',
      whereArgs: [1],
    );
    return List.generate(maps.length, (i) => LockSchedule.fromJson(maps[i]));
  }

  // ==================== STATS OPERATIONS ====================

  Future<int> insertDailyStats(DailyStats stats) async {
    final db = await database;
    return await db.insert('user_stats', stats.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<DailyStats> getDailyStats(DateTime date) async {
    final db = await database;
    final dateStr = date.toIso8601String().split('T')[0];
    final List<Map<String, dynamic>> maps = await db.query(
      'user_stats',
      where: 'date = ?',
      whereArgs: [dateStr],
    );

    if (maps.isEmpty) {
      return DailyStats.empty(date);
    }
    return DailyStats.fromJson(maps.first);
  }

  Future<List<DailyStats>> getStatsRange(DateTime start, DateTime end) async {
    final db = await database;
    final startStr = start.toIso8601String().split('T')[0];
    final endStr = end.toIso8601String().split('T')[0];

    final List<Map<String, dynamic>> maps = await db.query(
      'user_stats',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startStr, endStr],
      orderBy: 'date ASC',
    );

    return List.generate(maps.length, (i) => DailyStats.fromJson(maps[i]));
  }

  // ==================== UNLOCK HISTORY OPERATIONS ====================

  Future<int> insertUnlockAttempt(UnlockAttempt attempt) async {
    final db = await database;
    return await db.insert('unlock_history', attempt.toJson());
  }

  Future<List<UnlockAttempt>> getUnlockHistory({int limit = 100}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'unlock_history',
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return List.generate(maps.length, (i) => UnlockAttempt.fromJson(maps[i]));
  }

  Future<List<UnlockAttempt>> getTodayUnlocks() async {
    final db = await database;
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    final List<Map<String, dynamic>> maps = await db.query(
      'unlock_history',
      where: 'timestamp >= ?',
      whereArgs: [startOfDay.toIso8601String()],
      orderBy: 'timestamp DESC',
    );

    return List.generate(maps.length, (i) => UnlockAttempt.fromJson(maps[i]));
  }

  // ==================== FAVORITE VERSES ====================

  Future<int> addFavorite(String verseId) async {
    final db = await database;
    return await db.insert(
      'favorite_verses',
      {
        'user_id': 'default',
        'verse_id': verseId,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> removeFavorite(String verseId) async {
    final db = await database;
    return await db.delete(
      'favorite_verses',
      where: 'verse_id = ? AND user_id = ?',
      whereArgs: [verseId, 'default'],
    );
  }

  Future<bool> isFavorite(String verseId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'favorite_verses',
      where: 'verse_id = ? AND user_id = ?',
      whereArgs: [verseId, 'default'],
    );
    return maps.isNotEmpty;
  }

  Future<List<BibleVerse>> getFavoriteVerses() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT v.* FROM verses v
      INNER JOIN favorite_verses fv ON v.id = fv.verse_id
      WHERE fv.user_id = ?
      ORDER BY fv.created_at DESC
    ''', ['default']);

    return List.generate(maps.length, (i) => BibleVerse.fromJson(maps[i]));
  }

  // ==================== SEED DATA ====================

  Future<void> _seedInitialVerses(Database db) async {
    try {
      final verses = await BibleDatabaseLoader.loadCurriculumVerses();
      for (final verse in verses) {
        await db.insert('verses', verse.toJson());
      }
      debugPrint('✅ Loaded ${verses.length} curriculum verses');
    } catch (e) {
      debugPrint('❌ Failed to load curriculum verses: $e');
      rethrow;
    }
  }

  // ==================== BADGE OPERATIONS ====================

  Future<int> insertEarnedBadge(Map<String, dynamic> badge) async {
    final db = await database;
    return await db.insert(
      'earned_badges',
      badge,
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<List<Map<String, dynamic>>> getEarnedBadges() async {
    final db = await database;
    return await db.query('earned_badges', orderBy: 'earned_at DESC');
  }

  Future<bool> isBadgeEarned(String badgeId) async {
    final db = await database;
    final result = await db.query(
      'earned_badges',
      where: 'badge_id = ?',
      whereArgs: [badgeId],
    );
    return result.isNotEmpty;
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
