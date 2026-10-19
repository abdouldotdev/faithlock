import 'dart:convert';

// ── Highlight ────────────────────────────────────────────────────────────────

/// Identifies a single highlighted verse by its canonical coordinates.
/// [bookAbbr] + [chapter] + [verseNumber] form the unique key.
class BibleHighlight {
  final String bookAbbr;
  final int chapter;
  final int verseNumber;
  final DateTime createdAt;

  const BibleHighlight({
    required this.bookAbbr,
    required this.chapter,
    required this.verseNumber,
    required this.createdAt,
  });

  /// Stable string key used for deduplication in the highlights Set.
  String get key => '${bookAbbr}_${chapter}_$verseNumber';

  Map<String, dynamic> toJson() => {
        'bookAbbr': bookAbbr,
        'chapter': chapter,
        'verseNumber': verseNumber,
        'createdAt': createdAt.toIso8601String(),
      };

  factory BibleHighlight.fromJson(Map<String, dynamic> json) => BibleHighlight(
        bookAbbr: json['bookAbbr'] as String,
        chapter: json['chapter'] as int,
        verseNumber: json['verseNumber'] as int,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  @override
  bool operator ==(Object other) =>
      other is BibleHighlight && other.key == key;

  @override
  int get hashCode => key.hashCode;
}

// ── Bookmark ─────────────────────────────────────────────────────────────────

/// Bookmarks a passage / chapter for quick return.
/// [reference] is a human-readable string, e.g. "Genesis 1".
class BibleBookmark {
  final String reference;
  final DateTime createdAt;

  const BibleBookmark({
    required this.reference,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'reference': reference,
        'createdAt': createdAt.toIso8601String(),
      };

  factory BibleBookmark.fromJson(Map<String, dynamic> json) => BibleBookmark(
        reference: json['reference'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  @override
  bool operator ==(Object other) =>
      other is BibleBookmark && other.reference == reference;

  @override
  int get hashCode => reference.hashCode;
}

// ── Reflection ───────────────────────────────────────────────────────────────

/// A personal reflection note tied to a passage.
class BibleReflection {
  /// Auto-generated stable ID (epoch ms at creation time).
  final String id;
  final String passageReference;
  final String title;
  final String note;
  final DateTime createdAt;

  const BibleReflection({
    required this.id,
    required this.passageReference,
    required this.title,
    required this.note,
    required this.createdAt,
  });

  factory BibleReflection.create({
    required String passageReference,
    required String title,
    required String note,
  }) {
    final now = DateTime.now();
    return BibleReflection(
      id: now.millisecondsSinceEpoch.toString(),
      passageReference: passageReference,
      title: title,
      note: note,
      createdAt: now,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'passageReference': passageReference,
        'title': title,
        'note': note,
        'createdAt': createdAt.toIso8601String(),
      };

  factory BibleReflection.fromJson(Map<String, dynamic> json) =>
      BibleReflection(
        id: json['id'] as String,
        passageReference: json['passageReference'] as String,
        title: json['title'] as String,
        note: json['note'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

// ── JSON helpers ─────────────────────────────────────────────────────────────

extension BibleHighlightList on List<BibleHighlight> {
  String toJsonString() =>
      jsonEncode(map((h) => h.toJson()).toList());
}

extension BibleBookmarkList on List<BibleBookmark> {
  String toJsonString() =>
      jsonEncode(map((b) => b.toJson()).toList());
}

extension BibleReflectionList on List<BibleReflection> {
  String toJsonString() =>
      jsonEncode(map((r) => r.toJson()).toList());
}
