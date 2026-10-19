import 'dart:io';

import 'package:faithlock/features/bible/models/bible_book_list.dart';
import 'package:faithlock/features/faithlock/services/bible_database_loader.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

/// Record type returned by [BibleRepository.versesFor].
typedef BibleVerseRecord = ({int number, String text});

/// Thin data-access layer over the bundled Bible SQLite databases.
///
/// Three full translations ship as assets, all sharing the SAME schema
/// (`<PREFIX>_books(id,name)` + `<PREFIX>_verses(id,book_id,chapter,verse,text)`)
/// and — crucially — the SAME canonical `book_id` ordering 1..66:
///   • BSB → assets/databases/bible_bsb.db (English)
///   • KJV → assets/databases/bible_kjv.db (English)
///   • LSG → assets/databases/bible_lsg.db (Louis Segond 1910, French)
///
/// Because `book_id` is identical across versions, every read goes BY book_id —
/// never by name (names differ per version: "Revelation" / "Revelation of
/// John" / "Apocalypse"). Navigation stays shared; only the verse text and the
/// book names swap with the selected version.
class BibleRepository {
  /// Per-version asset path, on-device filename, and table prefix.
  static const Map<String, ({String asset, String file, String prefix})>
      _versions = {
    'BSB': (
      asset: 'assets/databases/bible_bsb.db',
      file: 'bible_bsb.db',
      prefix: 'BSB',
    ),
    'KJV': (
      asset: 'assets/databases/bible_kjv.db',
      file: 'bible_kjv.db',
      prefix: 'KJV',
    ),
    'LSG': (
      asset: 'assets/databases/bible_lsg.db',
      file: 'bible_lsg.db',
      prefix: 'LSG',
    ),
  };

  /// Resolves a version config, falling back to BSB for anything unknown so a
  /// stray abbreviation can never crash a read.
  static ({String asset, String file, String prefix}) _cfg(String abbr) =>
      _versions[abbr] ?? _versions['BSB']!;

  /// Canonical book_id (1..66) for a UI book name, via the [kBibleBooks] order.
  /// Returns null when the name isn't in the canonical list.
  static int? _bookId(String bookName) {
    final i = kBibleBooks.indexWhere((b) => b.name == bookName);
    return i < 0 ? null : i + 1;
  }

  // ── BSB name normalization ────────────────────────────────────────────────
  //
  // The bundled BSB DB stores numbered books with Roman numerals (`I Samuel`,
  // `II Kings`) and Revelation as `Revelation of John`, while [kBibleBooks]
  // uses Arabic numerals and `Revelation`. Verse reads no longer need this
  // (they go by book_id), but [BibleDatabaseLoader] still queries the BSB DB
  // by name for curriculum/search, so these helpers stay.
  static const Map<String, String> _displayToDbBookName = {
    '1 Samuel': 'I Samuel',
    '2 Samuel': 'II Samuel',
    '1 Kings': 'I Kings',
    '2 Kings': 'II Kings',
    '1 Chronicles': 'I Chronicles',
    '2 Chronicles': 'II Chronicles',
    '1 Corinthians': 'I Corinthians',
    '2 Corinthians': 'II Corinthians',
    '1 Thessalonians': 'I Thessalonians',
    '2 Thessalonians': 'II Thessalonians',
    '1 Timothy': 'I Timothy',
    '2 Timothy': 'II Timothy',
    '1 Peter': 'I Peter',
    '2 Peter': 'II Peter',
    '1 John': 'I John',
    '2 John': 'II John',
    '3 John': 'III John',
    'Revelation': 'Revelation of John',
  };

  /// Reverse of [_displayToDbBookName] for normalizing DB rows back to UI.
  static final Map<String, String> _dbToDisplayBookName = {
    for (final e in _displayToDbBookName.entries) e.value: e.key,
  };

  /// Resolves a Dart display name to its BSB DB equivalent.
  static String dbBookName(String displayName) =>
      _displayToDbBookName[displayName] ?? displayName;

  /// Resolves a BSB DB book name back to the Dart display name.
  static String displayBookName(String dbName) =>
      _dbToDisplayBookName[dbName] ?? dbName;

  /// Rewrites a free-text search query so a leading "1 / 2 / 3 " Arabic
  /// numeral matches the BSB DB's Roman-numeral book names.
  static String dbSearchPattern(String query) {
    if (query.startsWith('1 ')) return 'I ${query.substring(2)}';
    if (query.startsWith('2 ')) return 'II ${query.substring(2)}';
    if (query.startsWith('3 ')) return 'III ${query.substring(2)}';
    return query;
  }

  // ── Database lifecycle ──────────────────────────────────────────────────

  /// Opens the read-only DB for [versionAbbr], copying its bundled asset to the
  /// device databases dir on first use (each version is a separate file).
  Future<Database> _openDb(String versionAbbr) async {
    final cfg = _cfg(versionAbbr);
    final dbDir = await getDatabasesPath();
    final path = p.join(dbDir, cfg.file);

    if (!await File(path).exists()) {
      final data = await rootBundle.load(cfg.asset);
      await File(path).writeAsBytes(data.buffer.asUint8List(), flush: true);
    }

    return openDatabase(path, readOnly: true);
  }

  // ── Public API ───────────────────────────────────────────────────────────

  /// Returns all verses for [bookName] / [chapter] in [versionAbbr].
  ///
  /// Resolves the canonical book_id from [bookName] (shared across versions)
  /// and reads from that version's `<PREFIX>_verses` table.
  Future<List<BibleVerseRecord>> versesFor({
    required String bookName,
    required int chapter,
    String versionAbbr = 'BSB',
  }) async {
    final cfg = _cfg(versionAbbr);
    final bookId = _bookId(bookName);
    if (bookId == null) {
      throw StateError(
          'Book "$bookName" is not in the canonical kBibleBooks list.');
    }

    final db = await _openDb(versionAbbr);
    try {
      final rows = await db.rawQuery('''
        SELECT verse, text
        FROM ${cfg.prefix}_verses
        WHERE book_id = ? AND chapter = ?
        ORDER BY verse
      ''', [bookId, chapter]);

      return rows
          .map((r) => (
                number: r['verse'] as int,
                text: (r['text'] as String).trim(),
              ))
          .toList();
    } finally {
      await db.close();
    }
  }

  /// The book's name AS WRITTEN in [versionAbbr]'s DB — e.g. "Genèse" for LSG,
  /// "Revelation of John" for BSB. Falls back to the canonical [bookName] on
  /// any miss so the UI always has something to show.
  Future<String> localizedBookName({
    required String bookName,
    required String versionAbbr,
  }) async {
    final cfg = _cfg(versionAbbr);
    final bookId = _bookId(bookName);
    if (bookId == null) return bookName;

    final db = await _openDb(versionAbbr);
    try {
      final rows = await db.rawQuery(
        'SELECT name FROM ${cfg.prefix}_books WHERE id = ?',
        [bookId],
      );
      if (rows.isEmpty) return bookName;
      return (rows.first['name'] as String?) ?? bookName;
    } finally {
      await db.close();
    }
  }

  /// Returns a single verse suitable as the Verse of the Day.
  ///
  /// The PICK comes from the BSB curriculum set via [BibleDatabaseLoader]
  /// (higher-quality, date-seeded so it's stable for the whole day). The TEXT
  /// is then rendered in the app's language — French → Louis Segond (with a
  /// French reference like "Genèse 1:20"), otherwise the BSB text/reference.
  Future<({String text, String reference})?> verseOfDay() async {
    try {
      final verses = await BibleDatabaseLoader.loadCurriculumVerses();
      if (verses.isEmpty) return null;

      final today = DateTime.now();
      final seed = today.year * 10000 + today.month * 100 + today.day;
      final v = verses[seed % verses.length];

      // English (or any non-French locale): the BSB curriculum row as-is.
      if (Get.locale?.languageCode != 'fr') {
        return (text: v.text, reference: v.reference);
      }

      // French: pull the SAME reference's text + French book name from LSG.
      try {
        final rows = await versesFor(
          bookName: v.book,
          chapter: v.chapter,
          versionAbbr: 'LSG',
        );
        final match = rows.where((r) => r.number == v.verse);
        if (match.isNotEmpty) {
          final frBook =
              await localizedBookName(bookName: v.book, versionAbbr: 'LSG');
          return (
            text: match.first.text,
            reference: '$frBook ${v.chapter}:${v.verse}',
          );
        }
      } catch (_) {
        // Fall through to BSB if the LSG lookup fails for any reason.
      }
      return (text: v.text, reference: v.reference);
    } catch (_) {
      return null;
    }
  }

  /// Distinct BSB book names (canonical order). Existence guard used in dev.
  Future<Set<String>> availableBookNames() async {
    final db = await _openDb('BSB');
    try {
      final rows = await db.rawQuery('SELECT name FROM BSB_books ORDER BY id');
      return rows.map((r) => r['name'] as String).toSet();
    } finally {
      await db.close();
    }
  }
}
