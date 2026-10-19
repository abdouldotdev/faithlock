import 'dart:math';

import 'package:faithlock/features/prayer_audio/models/prayer.dart';
import 'package:faithlock/shared/widgets/cozy/cozy_mood_slider.dart';

/// Maps a [MoodLevel] to the [PrayerDomain] most likely to meet the user where
/// they are, and picks the best-matched prayer from a loaded list.
///
/// Mapping:
/// - crushed / heavy / weary → Spiritual Battles (`struggles`)
/// - okay                    → Daily Rhythm (`dailyRhythm`)
/// - peaceful / grateful     → Drawing Near (`drawingNear`)
/// - joyful                  → The Word (`scripture`)
class MoodPrayerMatch {
  MoodPrayerMatch._();

  static PrayerDomain domainFor(MoodLevel mood) {
    switch (mood) {
      case MoodLevel.crushed:
      case MoodLevel.heavy:
      case MoodLevel.weary:
        return PrayerDomain.struggles;
      case MoodLevel.okay:
        return PrayerDomain.dailyRhythm;
      case MoodLevel.peaceful:
      case MoodLevel.grateful:
        return PrayerDomain.drawingNear;
      case MoodLevel.joyful:
        return PrayerDomain.scripture;
    }
  }

  static final Random _rng = Random();

  /// Picks a prayer for the mood's domain — chosen at RANDOM among the matches
  /// so the same suggestion doesn't surface every time. [excludeId] (typically
  /// the previous suggestion) is skipped when an alternative exists. Falls back
  /// to the whole catalog when the domain is empty. Null only when [prayers]
  /// is empty.
  static Prayer? recommend(
    MoodLevel? mood,
    List<Prayer> prayers, {
    String? excludeId,
    Random? random,
  }) {
    if (prayers.isEmpty) return null;
    final rng = random ?? _rng;

    var pool = <Prayer>[];
    if (mood != null) {
      final domain = domainFor(mood);
      pool = prayers.where((p) => p.domain == domain).toList();
    }
    if (pool.isEmpty) pool = List<Prayer>.of(prayers);

    if (excludeId != null && pool.length > 1) {
      final trimmed = pool.where((p) => p.id != excludeId).toList();
      if (trimmed.isNotEmpty) pool = trimmed;
    }
    return pool[rng.nextInt(pool.length)];
  }
}
