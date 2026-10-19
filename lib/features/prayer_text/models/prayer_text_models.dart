/// Models for the textual prayer experience: a 5-level mood scale + a
/// completed session record (mood-before / mood-after / optional note).
///
/// The mood scale is intentionally small (1 tap, no text) so the check-in
/// stays under the friction threshold for a 60–90s prayer.
library;

// ─── Mood ────────────────────────────────────────────────────────────────────

/// Five discrete states the user can self-report before and after a prayer.
///
/// Order is monotonic (heavier → lighter); the integer [MoodLevelX.score] is
/// what we diff to produce the post-prayer delta.
enum MoodLevel {
  heavy,
  unsettled,
  steady,
  light,
  radiant,
}

extension MoodLevelX on MoodLevel {
  /// 1..5 — used for the after/before delta and aggregate stats.
  int get score => switch (this) {
        MoodLevel.heavy => 1,
        MoodLevel.unsettled => 2,
        MoodLevel.steady => 3,
        MoodLevel.light => 4,
        MoodLevel.radiant => 5,
      };

  /// The single glyph rendered in the picker and the delta card.
  String get emoji => switch (this) {
        MoodLevel.heavy => '😟',
        MoodLevel.unsettled => '😐',
        MoodLevel.steady => '🙂',
        MoodLevel.light => '😊',
        MoodLevel.radiant => '✨',
      };

  /// Short, neutral label shown under the selected emoji.
  String get label => switch (this) {
        MoodLevel.heavy => 'Heavy',
        MoodLevel.unsettled => 'Unsettled',
        MoodLevel.steady => 'Steady',
        MoodLevel.light => 'Light',
        MoodLevel.radiant => 'Radiant',
      };

  static MoodLevel? fromName(String? value) {
    if (value == null) return null;
    for (final m in MoodLevel.values) {
      if (m.name == value) return m;
    }
    return null;
  }
}

// ─── Session record ──────────────────────────────────────────────────────────

/// One completed textual-prayer session. Persisted via
/// `PrayerSessionRepository` so the user can see their delta history on the
/// profile (the rétention loop — see [moodDelta] / [improved]).
class PrayerSession {
  const PrayerSession({
    required this.id,
    required this.prayerId,
    required this.prayerTitle,
    required this.startedAt,
    required this.completedAt,
    required this.moodBefore,
    required this.moodAfter,
    this.note,
  });

  final String id;
  final String prayerId;
  final String prayerTitle;
  final DateTime startedAt;
  final DateTime completedAt;
  final MoodLevel moodBefore;
  final MoodLevel moodAfter;

  /// Optional, free-form, kept short by the UI. Null when the user skipped.
  final String? note;

  /// Signed delta: positive = mood lifted, 0 = unchanged, negative = heavier.
  int get moodDelta => moodAfter.score - moodBefore.score;

  /// True when the prayer left the user in a lighter mood than they arrived.
  bool get improved => moodDelta > 0;

  Duration get duration => completedAt.difference(startedAt);

  Map<String, dynamic> toMap() => {
        'id': id,
        'prayer_id': prayerId,
        'prayer_title': prayerTitle,
        'started_at': startedAt.toIso8601String(),
        'completed_at': completedAt.toIso8601String(),
        'mood_before': moodBefore.name,
        'mood_after': moodAfter.name,
        if (note != null) 'note': note,
      };

  factory PrayerSession.fromMap(Map<String, dynamic> map) {
    return PrayerSession(
      id: (map['id'] ?? '').toString(),
      prayerId: (map['prayer_id'] ?? '').toString(),
      prayerTitle: (map['prayer_title'] ?? '').toString(),
      startedAt: DateTime.tryParse(map['started_at']?.toString() ?? '') ??
          DateTime.now(),
      completedAt: DateTime.tryParse(map['completed_at']?.toString() ?? '') ??
          DateTime.now(),
      moodBefore: MoodLevelX.fromName(map['mood_before']?.toString()) ??
          MoodLevel.steady,
      moodAfter: MoodLevelX.fromName(map['mood_after']?.toString()) ??
          MoodLevel.steady,
      note: map['note']?.toString(),
    );
  }
}
