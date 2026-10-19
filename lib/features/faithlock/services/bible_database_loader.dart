import 'package:faithlock/features/bible/data/bible_repository.dart';
import 'package:faithlock/features/faithlock/models/export.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';

/// Loads Bible verses from the asset database (bible_bsb.db)
/// into the app's internal database
class BibleDatabaseLoader {
  static const String _assetDbPath = 'assets/databases/bible_bsb.db';
  static const String _bibleDbName = 'bible_bsb.db';

  /// Load the ~280 categorized curriculum verses from asset database
  /// Covers 12 weeks of progressive learning across 5 categories
  static Future<List<BibleVerse>> loadCurriculumVerses() async {
    // Copy asset database to temporary location
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _bibleDbName);

    // Always check if database structure is up-to-date
    bool needsUpdate = false;

    if (!await File(path).exists()) {
      needsUpdate = true;
    } else {
      // Verify database has curriculum_week column
      try {
        final testDb = await openDatabase(path, readOnly: true);
        final result = await testDb.rawQuery("PRAGMA table_info(BSB_verses)");
        final hasColumn = result.any((col) => col['name'] == 'curriculum_week');
        await testDb.close();

        if (!hasColumn) {
          needsUpdate = true;
          print('⚠️ Bible database missing curriculum_week column - updating...');
        }
      } catch (e) {
        needsUpdate = true;
        print('⚠️ Error checking Bible database structure: $e');
      }
    }

    // Copy/update database if needed
    if (needsUpdate) {
      print('📚 Updating Bible database from assets...');
      final ByteData data = await rootBundle.load(_assetDbPath);
      final List<int> bytes = data.buffer.asUint8List();
      await File(path).writeAsBytes(bytes, flush: true);
      print('✅ Bible database updated successfully');
    }

    // Open the Bible database
    final db = await openDatabase(path, readOnly: true);

    try {
      // Query only categorized verses (~280 curriculum verses across 12 weeks)
      final List<Map<String, dynamic>> results = await db.rawQuery('''
        SELECT
          b.name as book_name,
          v.chapter,
          v.verse,
          v.text,
          v.category,
          v.curriculum_week,
          v.difficulty,
          v.keyword
        FROM BSB_verses v
        JOIN BSB_books b ON v.book_id = b.id
        WHERE v.category IS NOT NULL
        ORDER BY v.category, v.curriculum_week, v.chapter, v.verse
      ''');

      // Convert to BibleVerse objects
      final List<BibleVerse> verses = [];
      for (var i = 0; i < results.length; i++) {
        final row = results[i];
        // Normalize DB-side Roman / "Revelation of John" back to display
        // form so the UI sees "1 Samuel" instead of "I Samuel".
        final bookDisplay =
            BibleRepository.displayBookName(row['book_name'] as String);
        final reference = '$bookDisplay ${row['chapter']}:${row['verse']}';

        verses.add(BibleVerse(
          id: 'verse_${i + 1}',
          text: row['text'] as String,
          reference: reference,
          book: bookDisplay,
          chapter: row['chapter'] as int,
          verse: row['verse'] as int,
          category: VerseCategoryExtension.fromString(row['category'] as String),
          translation: 'BSB',
          curriculumWeek: row['curriculum_week'] as int?,
          difficulty: row['difficulty'] as int?,
          keyword: row['keyword'] as String?,
        ));
      }

      return verses;
    } finally {
      await db.close();
    }
  }

  /// Load ALL verses from the complete BSB Bible with pagination
  /// Returns a page of verses from the full 31,102 verse Bible
  /// Use limit and offset for pagination (e.g., page 1: offset=0, page 2: offset=100)
  static Future<List<BibleVerse>> loadAllBibleVerses({
    int limit = 100,
    int offset = 0,
    VerseCategory? categoryFilter,
    String? searchQuery,
  }) async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _bibleDbName);

    // Ensure database exists
    if (!await File(path).exists()) {
      final ByteData data = await rootBundle.load(_assetDbPath);
      final List<int> bytes = data.buffer.asUint8List();
      await File(path).writeAsBytes(bytes, flush: true);
    }

    final db = await openDatabase(path, readOnly: true);

    try {
      // Build WHERE clause for filters
      String whereClause = '';
      List<dynamic> whereArgs = [];

      if (categoryFilter != null) {
        whereClause = 'WHERE v.category = ?';
        whereArgs.add(categoryFilter.value);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        if (whereClause.isEmpty) {
          whereClause = 'WHERE ';
        } else {
          whereClause += ' AND ';
        }
        // The third LIKE handles "1 Sam" → "I Sam" so Arabic-numeral
        // searches still find Roman-named books in the BSB DB.
        final normalized = BibleRepository.dbSearchPattern(searchQuery);
        whereClause += '(v.text LIKE ? OR b.name LIKE ? OR b.name LIKE ?)';
        whereArgs.add('%$searchQuery%');
        whereArgs.add('%$searchQuery%');
        whereArgs.add('%$normalized%');
      }

      // Query with pagination
      final List<Map<String, dynamic>> results = await db.rawQuery('''
        SELECT
          b.name as book_name,
          v.chapter,
          v.verse,
          v.text,
          v.category,
          v.curriculum_week,
          v.difficulty,
          v.keyword
        FROM BSB_verses v
        JOIN BSB_books b ON v.book_id = b.id
        $whereClause
        ORDER BY v.book_id, v.chapter, v.verse
        LIMIT ? OFFSET ?
      ''', [...whereArgs, limit, offset]);

      // Convert to BibleVerse objects
      final List<BibleVerse> verses = [];
      for (var i = 0; i < results.length; i++) {
        final row = results[i];
        final bookDisplay =
            BibleRepository.displayBookName(row['book_name'] as String);
        final reference = '$bookDisplay ${row['chapter']}:${row['verse']}';

        verses.add(BibleVerse(
          id: 'verse_${bookDisplay}_${row['chapter']}_${row['verse']}',
          text: row['text'] as String,
          reference: reference,
          book: bookDisplay,
          chapter: row['chapter'] as int,
          verse: row['verse'] as int,
          category: row['category'] != null
              ? VerseCategoryExtension.fromString(row['category'] as String)
              : VerseCategory.temptation, // Default for uncategorized verses
          translation: 'BSB',
          curriculumWeek: row['curriculum_week'] as int?,
          difficulty: row['difficulty'] as int?,
          keyword: row['keyword'] as String?,
        ));
      }

      return verses;
    } finally {
      await db.close();
    }
  }

  /// Get total count of verses in the complete Bible
  /// Useful for pagination calculations
  static Future<int> getTotalVersesCount({
    VerseCategory? categoryFilter,
    String? searchQuery,
  }) async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _bibleDbName);

    if (!await File(path).exists()) {
      return 0;
    }

    final db = await openDatabase(path, readOnly: true);

    try {
      // Build WHERE clause for filters
      String whereClause = '';
      List<dynamic> whereArgs = [];

      if (categoryFilter != null) {
        whereClause = 'WHERE v.category = ?';
        whereArgs.add(categoryFilter.value);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        if (whereClause.isEmpty) {
          whereClause = 'WHERE ';
        } else {
          whereClause += ' AND ';
        }
        // Same trick as the paginated query so COUNT() stays in sync with
        // the rows that will actually be returned.
        final normalized = BibleRepository.dbSearchPattern(searchQuery);
        whereClause += '(v.text LIKE ? OR b.name LIKE ? OR b.name LIKE ?)';
        whereArgs.add('%$searchQuery%');
        whereArgs.add('%$searchQuery%');
        whereArgs.add('%$normalized%');
      }

      final result = await db.rawQuery('''
        SELECT COUNT(*) as count
        FROM BSB_verses v
        JOIN BSB_books b ON v.book_id = b.id
        $whereClause
      ''', whereArgs);

      return Sqflite.firstIntValue(result) ?? 0;
    } finally {
      await db.close();
    }
  }

  /// Get a specific verse from the Bible database
  static Future<BibleVerse?> getVerse({
    required String bookName,
    required int chapter,
    required int verse,
  }) async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _bibleDbName);

    if (!await File(path).exists()) {
      // Copy database if it doesn't exist
      final ByteData data = await rootBundle.load(_assetDbPath);
      final List<int> bytes = data.buffer.asUint8List();
      await File(path).writeAsBytes(bytes, flush: true);
    }

    final db = await openDatabase(path, readOnly: true);

    try {
      final List<Map<String, dynamic>> results = await db.rawQuery('''
        SELECT
          b.name as book_name,
          v.chapter,
          v.verse,
          v.text,
          v.category,
          v.curriculum_week,
          v.difficulty,
          v.keyword
        FROM BSB_verses v
        JOIN BSB_books b ON v.book_id = b.id
        WHERE b.name = ? AND v.chapter = ? AND v.verse = ?
        LIMIT 1
      ''', [BibleRepository.dbBookName(bookName), chapter, verse]);

      if (results.isEmpty) return null;

      final row = results.first;
      final bookDisplay =
          BibleRepository.displayBookName(row['book_name'] as String);
      final reference = '$bookDisplay $chapter:$verse';

      return BibleVerse(
        id: 'verse_${bookDisplay}_${row['chapter']}_${row['verse']}',
        text: row['text'] as String,
        reference: reference,
        book: bookDisplay,
        chapter: row['chapter'] as int,
        verse: row['verse'] as int,
        category: row['category'] != null
            ? VerseCategoryExtension.fromString(row['category'] as String)
            : VerseCategory.temptation, // Default fallback
        translation: 'BSB',
        curriculumWeek: row['curriculum_week'] as int?,
        difficulty: row['difficulty'] as int?,
        keyword: row['keyword'] as String?,
      );
    } finally {
      await db.close();
    }
  }
}
