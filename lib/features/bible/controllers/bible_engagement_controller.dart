import 'dart:convert';

import 'package:faithlock/config/logger.dart';
import 'package:faithlock/features/bible/models/bible_engagement_models.dart';
import 'package:faithlock/services/storage/preferences_service.dart';
import 'package:get/get.dart';

/// Manages persistence for Bible reading engagement:
/// highlights, bookmarks, and reflection notes.
///
/// Storage: [PreferencesService] (SharedPreferences / JSON-encoded lists).
/// Keys are prefixed with `bible_engagement_` to avoid collisions.
///
/// Usage:
/// ```dart
/// // Register once (e.g. in GetMaterialApp bindings or first use):
/// Get.lazyPut(() => BibleEngagementController());
///
/// // Access:
/// final ctrl = Get.find<BibleEngagementController>();
/// ctrl.toggleHighlight('Gen', 1, 3);
/// ctrl.addReflection(passageReference: 'Genesis 1:1', title: '...', note: '...');
/// ```
class BibleEngagementController extends GetxController {
  final PreferencesService _prefs = PreferencesService();

  // ── Storage keys ──────────────────────────────────────────────────────────
  static const String _highlightsKey = 'bible_engagement_highlights';
  static const String _bookmarksKey = 'bible_engagement_bookmarks';
  static const String _reflectionsKey = 'bible_engagement_reflections';

  // ── Reactive state ────────────────────────────────────────────────────────
  final RxList<BibleHighlight> highlights = <BibleHighlight>[].obs;
  final RxList<BibleBookmark> bookmarks = <BibleBookmark>[].obs;
  final RxList<BibleReflection> reflections = <BibleReflection>[].obs;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    _loadAll();
  }

  // ── Highlights ────────────────────────────────────────────────────────────

  /// Returns `true` if the verse at [bookAbbr]/[chapter]/[verseNumber]
  /// is currently highlighted.
  bool isHighlighted(String bookAbbr, int chapter, int verseNumber) {
    final key = '${bookAbbr}_${chapter}_$verseNumber';
    return highlights.any((h) => h.key == key);
  }

  /// Adds a highlight if absent; removes it if already present.
  /// Returns `true` when the resulting state is highlighted.
  Future<bool> toggleHighlight(
    String bookAbbr,
    int chapter,
    int verseNumber,
  ) async {
    final existing = highlights.firstWhereOrNull(
      (h) => h.key == '${bookAbbr}_${chapter}_$verseNumber',
    );

    if (existing != null) {
      highlights.remove(existing);
      await _persistHighlights();
      return false;
    } else {
      highlights.add(BibleHighlight(
        bookAbbr: bookAbbr,
        chapter: chapter,
        verseNumber: verseNumber,
        createdAt: DateTime.now(),
      ));
      await _persistHighlights();
      return true;
    }
  }

  /// All highlights for a given chapter, sorted by verse number.
  List<BibleHighlight> highlightsForChapter(String bookAbbr, int chapter) {
    return highlights
        .where((h) => h.bookAbbr == bookAbbr && h.chapter == chapter)
        .toList()
      ..sort((a, b) => a.verseNumber.compareTo(b.verseNumber));
  }

  // ── Bookmarks ─────────────────────────────────────────────────────────────

  /// Returns `true` if [reference] is bookmarked.
  bool isBookmarked(String reference) =>
      bookmarks.any((b) => b.reference == reference);

  /// Adds a bookmark if absent; removes it if present.
  /// Returns `true` when the resulting state is bookmarked.
  Future<bool> toggleBookmark(String reference) async {
    final existing =
        bookmarks.firstWhereOrNull((b) => b.reference == reference);

    if (existing != null) {
      bookmarks.remove(existing);
      await _persistBookmarks();
      return false;
    } else {
      bookmarks.add(BibleBookmark(
        reference: reference,
        createdAt: DateTime.now(),
      ));
      await _persistBookmarks();
      return true;
    }
  }

  /// Removes a bookmark unconditionally.
  Future<void> removeBookmark(String reference) async {
    bookmarks.removeWhere((b) => b.reference == reference);
    await _persistBookmarks();
  }

  // ── Reflections ───────────────────────────────────────────────────────────

  /// All reflections for a specific [passageReference].
  List<BibleReflection> reflectionsFor(String passageReference) =>
      reflections.where((r) => r.passageReference == passageReference).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  /// Adds and persists a new reflection.
  Future<BibleReflection> addReflection({
    required String passageReference,
    required String title,
    required String note,
  }) async {
    final reflection = BibleReflection.create(
      passageReference: passageReference,
      title: title,
      note: note,
    );
    reflections.insert(0, reflection); // newest first
    await _persistReflections();
    return reflection;
  }

  /// Removes the reflection with [id].
  Future<void> removeReflection(String id) async {
    reflections.removeWhere((r) => r.id == id);
    await _persistReflections();
  }

  // ── Persistence ───────────────────────────────────────────────────────────

  Future<void> _loadAll() async {
    await Future.wait([
      _loadHighlights(),
      _loadBookmarks(),
      _loadReflections(),
    ]);
  }

  Future<void> _loadHighlights() async {
    try {
      final raw = await _prefs.readString(_highlightsKey);
      if (raw == null || raw.isEmpty) return;
      final list = jsonDecode(raw) as List<dynamic>;
      highlights.value = list
          .map((e) => BibleHighlight.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      logger.error('BibleEngagementController: load highlights failed', e, st);
    }
  }

  Future<void> _loadBookmarks() async {
    try {
      final raw = await _prefs.readString(_bookmarksKey);
      if (raw == null || raw.isEmpty) return;
      final list = jsonDecode(raw) as List<dynamic>;
      bookmarks.value = list
          .map((e) => BibleBookmark.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      logger.error('BibleEngagementController: load bookmarks failed', e, st);
    }
  }

  Future<void> _loadReflections() async {
    try {
      final raw = await _prefs.readString(_reflectionsKey);
      if (raw == null || raw.isEmpty) return;
      final list = jsonDecode(raw) as List<dynamic>;
      reflections.value = list
          .map((e) => BibleReflection.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      logger.error(
          'BibleEngagementController: load reflections failed', e, st);
    }
  }

  Future<void> _persistHighlights() async {
    try {
      await _prefs.writeString(
          _highlightsKey, highlights.toJsonString());
    } catch (e, st) {
      logger.error(
          'BibleEngagementController: persist highlights failed', e, st);
    }
  }

  Future<void> _persistBookmarks() async {
    try {
      await _prefs.writeString(
          _bookmarksKey, bookmarks.toJsonString());
    } catch (e, st) {
      logger.error(
          'BibleEngagementController: persist bookmarks failed', e, st);
    }
  }

  Future<void> _persistReflections() async {
    try {
      await _prefs.writeString(
          _reflectionsKey, reflections.toJsonString());
    } catch (e, st) {
      logger.error(
          'BibleEngagementController: persist reflections failed', e, st);
    }
  }
}

// ── List extension helpers ────────────────────────────────────────────────────

extension _HighlightListExt on RxList<BibleHighlight> {
  String toJsonString() =>
      jsonEncode(map((h) => h.toJson()).toList());
}

extension _BookmarkListExt on RxList<BibleBookmark> {
  String toJsonString() =>
      jsonEncode(map((b) => b.toJson()).toList());
}

extension _ReflectionListExt on RxList<BibleReflection> {
  String toJsonString() =>
      jsonEncode(map((r) => r.toJson()).toList());
}
