import '../../faithlock/models/bible_verse_model.dart' show VerseCategory;
import '../../faithlock/models/user_stats_model.dart';
import '../controllers/grace_garden_controller.dart';
import '../domain/garden_engine.dart' hide VerseCategory;

/// Seeds the garden from a user's REAL history (read-only on [UserStats]) so an
/// existing user opens onto a tree that reflects their journey — not a seedling.
///
/// The DB stores verses read per [VerseCategory] (temptation, fearAnxiety,
/// pride, lust, anger) + streak. We map those onto the Fruits via the same
/// attribution as the live engine:
///   fearAnxiety → Peace · temptation/lust → Self-control · pride → Gentleness ·
///   anger → Gentleness (0.7) + Self-control (0.3) · streak → Faithfulness.
/// The categories the DB doesn't track (gratitude/love/service/perseverance →
/// Joy/Love/Kindness/Goodness/Patience) start young and grow with future
/// practice. Nothing here writes to the DB.
class GardenBackfill {
  GardenBackfill._();

  static const int _perVerse = 8; // growth added per verse read in a category
  static const int _splashCap = 60; // whole-tree lift from total reading
  static const int _faithCap = 140; // Faithfulness ceiling from streak

  /// The per-fruit starting growth derived from [stats].
  static Map<FruitKey, int> growthFrom(UserStats stats) {
    final g = {for (final f in kFruits) f.key: 5};
    final cat = stats.versesByCategory;
    int n(VerseCategory k) => cat[k] ?? 0;

    g[FruitKey.peace] = g[FruitKey.peace]! + n(VerseCategory.fearAnxiety) * _perVerse;
    g[FruitKey.selfcontrol] = g[FruitKey.selfcontrol]! +
        (n(VerseCategory.temptation) + n(VerseCategory.lust)) * _perVerse +
        (n(VerseCategory.anger) * _perVerse * 0.3).round();
    g[FruitKey.gentleness] = g[FruitKey.gentleness]! +
        n(VerseCategory.pride) * _perVerse +
        (n(VerseCategory.anger) * _perVerse * 0.7).round();

    // Splash: the whole tree lifts a little with total reading volume.
    final totalVerses = cat.values.fold<int>(0, (s, v) => s + v);
    final splash = totalVerses.clamp(0, _splashCap);
    for (final f in kFruits) {
      g[f.key] = g[f.key]! + splash;
    }

    // Faithfulness grows from returning (the streak).
    g[FruitKey.faithfulness] =
        g[FruitKey.faithfulness]! + (stats.currentStreak * 3).clamp(0, _faithCap);

    return g;
  }

  /// Vitality from recent presence: lush today, gently lower the longer it's been.
  static int healthFrom(UserStats stats) {
    if (stats.hasStreakToday) return 100;
    final daysSince = DateTime.now().difference(stats.lastUnlockDate).inDays;
    return (100 - daysSince * 6).clamp(20, 100);
  }

  /// Apply the backfill to a fresh controller (call before showing the tree).
  static void seed(GraceGardenController c, UserStats stats) {
    final g = growthFrom(stats);
    g.forEach((fruit, growth) {
      c.setGrowth(fruit, growth);
      if (growth >= 80) c.setHarvest(fruit, true);
    });
    c.setHealthValue(healthFrom(stats));
    c.activeDaysWindow.value = stats.currentStreak.clamp(0, 7);
    c.activeToday.value = stats.hasStreakToday;
  }
}
