import 'package:faithlock/features/bible/data/bible_repository.dart';
import 'package:faithlock/features/bible/models/bible_book.dart';
import 'package:faithlock/features/bible/models/bible_book_list.dart';
import 'package:faithlock/features/bible/models/bible_version.dart';
import 'package:faithlock/services/storage/preferences_service.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// Controller for the Bible feature.
///
/// ## Public API
///
/// ### Books
/// ```dart
/// final BibleController c = Get.find();
/// c.books                    // RxList<BibleBook> — full 66 books
/// c.oldTestamentBooks        // computed — OT only
/// c.newTestamentBooks        // computed — NT only
/// c.searchQuery              // RxString — drives filteredBooks
/// c.filteredBooks            // computed — subset by current testament + query
/// ```
///
/// ### Versions
/// ```dart
/// c.versions                 // List<BibleVersion> (constant)
/// c.selectedVersion          // Rx<BibleVersion>
/// c.selectVersion(v)         // persists choice, updates selectedVersion
/// ```
///
/// ### Verses
/// ```dart
/// final verses = await c.versesFor(bookName: 'Genesis', chapter: 1);
/// // → List<({int number, String text})>
/// ```
///
/// ### Verse of the Day
/// ```dart
/// c.verseOfDay          // Rx<({String text, String reference})?>
/// ```
///
/// ## Data approach
/// Full BSB Bible text is bundled at [assets/databases/bible_bsb.db].
/// No internet required. Other listed versions share the same database until
/// individual translations are added.
class BibleController extends GetxController {
  BibleController({
    BibleRepository? repository,
    PreferencesService? prefs,
  })  : _repo = repository ?? BibleRepository(),
        _prefs = prefs ?? PreferencesService();

  final BibleRepository _repo;
  final PreferencesService _prefs;

  // ── Storage key ────────────────────────────────────────────────────────
  static const String _versionKey = 'bible_selected_version';

  // ── Observable state ──────────────────────────────────────────────────

  /// All 66 canonical books (always populated from the static list — no DB
  /// query needed since book metadata is baked in).
  final RxList<BibleBook> books = RxList<BibleBook>(kBibleBooks);

  /// The list of available Bible versions.
  final List<BibleVersion> versions = kBibleVersions;

  /// The currently selected version, persisted across app launches.
  late final Rx<BibleVersion> selectedVersion;

  /// Verse of the Day — null while loading or if the DB is not ready.
  final Rx<({String text, String reference})?> verseOfDay =
      Rx<({String text, String reference})?>(null);

  /// Current search query (empty = no filter).
  final RxString searchQuery = ''.obs;

  /// Whether the verse-of-day is still being loaded.
  final RxBool isVerseLoading = true.obs;

  // ── Computed helpers ──────────────────────────────────────────────────

  List<BibleBook> get oldTestamentBooks =>
      books.where((b) => b.testament == Testament.old).toList();

  List<BibleBook> get newTestamentBooks =>
      books.where((b) => b.testament == Testament.newTestament).toList();

  /// Books filtered by [searchQuery].
  /// Pass [testament] to further narrow to OT or NT.
  List<BibleBook> filteredBooks({Testament? testament}) {
    final query = searchQuery.value.trim().toLowerCase();
    final source = testament == null
        ? books
        : testament == Testament.old
            ? oldTestamentBooks
            : newTestamentBooks;

    if (query.isEmpty) return source;
    return source
        .where((b) =>
            b.name.toLowerCase().contains(query) ||
            b.abbreviation.toLowerCase().contains(query))
        .toList();
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────

  @override
  Future<void> onInit() async {
    super.onInit();
    await _restoreVersion();
    _loadVerseOfDay();
  }

  // ── Version management ────────────────────────────────────────────────

  Future<void> _restoreVersion() async {
    final saved = await _prefs.readString(_versionKey);
    // With no explicit choice yet, default to the version that matches the
    // app language (French → Louis Segond, otherwise BSB).
    final localeDefault = bibleVersionForLocale(Get.locale?.languageCode);
    final candidate = saved != null
        ? kBibleVersions.firstWhere(
            (v) => v.abbr == saved,
            orElse: () => localeDefault,
          )
        : localeDefault;
    // Fall back to the locale default if the persisted choice is no longer
    // available (e.g. user picked KJV before we shipped the disabled
    // marker, and we now refuse to lie about which translation is loaded).
    final version = candidate.isAvailable ? candidate : localeDefault;
    selectedVersion = version.obs;
  }

  /// Selects a version and persists the choice.
  /// Silently no-ops on an unavailable version — the UI should never reach
  /// this path (taps are disabled) but the guard keeps the controller honest.
  Future<void> selectVersion(BibleVersion version) async {
    if (!version.isAvailable) return;
    selectedVersion.value = version;
    await _prefs.writeString(_versionKey, version.abbr);
  }

  // ── Verse loading ─────────────────────────────────────────────────────

  Future<void> _loadVerseOfDay() async {
    isVerseLoading.value = true;
    try {
      final result = await _repo.verseOfDay();
      verseOfDay.value = result;
    } catch (_) {
      verseOfDay.value = null;
    } finally {
      isVerseLoading.value = false;
    }
  }

  /// Returns all verses for the given [bookName] and [chapter] using the
  /// currently selected version.
  ///
  /// Returns an empty list if the chapter is empty or if the DB query fails.
  Future<List<({int number, String text})>> versesFor({
    required String bookName,
    required int chapter,
  }) async {
    try {
      return await _repo.versesFor(
        bookName: bookName,
        chapter: chapter,
        versionAbbr: selectedVersion.value.abbr,
      );
    } catch (e, stack) {
      // Don't swallow silently — a returned empty list looks identical to
      // a legitimately empty chapter, which previously masked an 18-book
      // name-mismatch bug. Log so failures surface in dev/release logs.
      debugPrint(
          '⚠️ [BibleController] versesFor failed for "$bookName" ch.$chapter '
          '(${selectedVersion.value.abbr}): $e');
      debugPrintStack(stackTrace: stack);
      return [];
    }
  }

  /// The display name of [bookName] in the currently selected version — e.g.
  /// "Genèse" under LSG, "Revelation of John" under BSB. Falls back to the
  /// canonical [bookName] on any error. Use this for the reader title; keep
  /// the canonical name for engagement/bookmark keys so they stay version-
  /// stable.
  Future<String> localizedBookName(String bookName) async {
    try {
      return await _repo.localizedBookName(
        bookName: bookName,
        versionAbbr: selectedVersion.value.abbr,
      );
    } catch (_) {
      return bookName;
    }
  }

  // ── Search ────────────────────────────────────────────────────────────

  void updateSearch(String query) {
    searchQuery.value = query;
  }

  void clearSearch() {
    searchQuery.value = '';
  }
}
