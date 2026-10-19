import 'package:flutter/material.dart';

/// The garden ENGINE (spec v2) — pure Dart, framework-agnostic. This is the
/// faithful port of `apps/garden-web/src/engine/garden.ts`. The rendering reads
/// from it; it never reads the rendering.
///
/// Guardrails baked in: growth is monotonic & unbounded (never lost), no
/// user-facing numbers (the engine keeps growth internally — UI shows named
/// stages only), prayer is rain (splash, no Faithfulness award), Faithfulness
/// grows from *returning*, rhythm is an uncliffable rolling ratio, harvest is
/// *given* not hoarded.

// ─────────────────────────────────────────────────────────────────────────────
// Fruits
// ─────────────────────────────────────────────────────────────────────────────

enum FruitKey {
  love,
  joy,
  peace,
  patience,
  kindness,
  goodness,
  faithfulness,
  gentleness,
  selfcontrol,
}

/// Botanical archetype used by the renderer to pick a species silhouette
/// (spec §11). Placeholder rendering keys off this.
enum PlantArchetype { flower, tree, pine, willow, bush, vine }

class FruitMeta {
  final FruitKey key;
  final String label;
  final PlantArchetype archetype;

  /// Base foliage/bloom color seed for placeholder rendering.
  final Color seed;

  /// Evergreens stay green through winter dormancy (spec §11).
  final bool evergreen;

  const FruitMeta(this.key, this.label, this.archetype, this.seed,
      {this.evergreen = false});
}

/// The nine Fruits of the Spirit, in canonical order (Gal 5:22-23).
const List<FruitMeta> kFruits = [
  FruitMeta(FruitKey.love, 'Love', PlantArchetype.flower, Color(0xFFE26D8A)),
  FruitMeta(FruitKey.joy, 'Joy', PlantArchetype.flower, Color(0xFFF2B33D)),
  FruitMeta(FruitKey.peace, 'Peace', PlantArchetype.tree, Color(0xFF7FA68A),
      evergreen: true),
  FruitMeta(FruitKey.patience, 'Patience', PlantArchetype.tree,
      Color(0xFF6E8B4E)),
  FruitMeta(FruitKey.kindness, 'Kindness', PlantArchetype.bush,
      Color(0xFFD79AC2)),
  FruitMeta(FruitKey.goodness, 'Goodness', PlantArchetype.tree,
      Color(0xFFC85A3E)),
  FruitMeta(FruitKey.faithfulness, 'Faithfulness', PlantArchetype.pine,
      Color(0xFF3F6B53),
      evergreen: true),
  FruitMeta(FruitKey.gentleness, 'Gentleness', PlantArchetype.willow,
      Color(0xFFA9C6B0)),
  FruitMeta(FruitKey.selfcontrol, 'Self-control', PlantArchetype.vine,
      Color(0xFF8E6FB0)),
];

final Map<FruitKey, FruitMeta> kFruitByKey = {
  for (final f in kFruits) f.key: f,
};

String fruitLabel(FruitKey k) => kFruitByKey[k]!.label;

// ─────────────────────────────────────────────────────────────────────────────
// Verse categories → fruit (spec §5)
// ─────────────────────────────────────────────────────────────────────────────

class Award {
  final FruitKey fruit;
  final double weight;
  const Award(this.fruit, this.weight);
}

class VerseCategory {
  final String id;
  final String theme;
  final String sample;
  final List<Award> awards;
  const VerseCategory(this.id, this.theme, this.sample, this.awards);
}

const List<VerseCategory> kVerses = [
  VerseCategory('fearAnxiety', 'anxiety',
      '"Do not be anxious about anything…" — Phil 4:6',
      [Award(FruitKey.peace, 1)]),
  VerseCategory('anger', 'anger',
      '"A gentle answer turns away wrath." — Prov 15:1',
      [Award(FruitKey.gentleness, 0.7), Award(FruitKey.selfcontrol, 0.3)]),
  VerseCategory('temptation', 'temptation',
      '"God will also provide a way out." — 1 Cor 10:13',
      [Award(FruitKey.selfcontrol, 1)]),
  VerseCategory('pride', 'pride',
      '"Clothe yourselves with humility." — 1 Pet 5:5',
      [Award(FruitKey.gentleness, 1)]),
  VerseCategory('gratitude', 'gratitude',
      '"Give thanks in all circumstances." — 1 Thess 5:18',
      [Award(FruitKey.joy, 1)]),
  VerseCategory('love', 'love', '"Love is patient, love is kind." — 1 Cor 13:4',
      [Award(FruitKey.love, 1)]),
  VerseCategory('perseverance', 'trials',
      '"Let perseverance finish its work." — James 1:4',
      [Award(FruitKey.patience, 0.7), Award(FruitKey.faithfulness, 0.3)]),
  VerseCategory('service', 'service',
      '"Serve one another humbly in love." — Gal 5:13',
      [Award(FruitKey.goodness, 0.7), Award(FruitKey.kindness, 0.3)]),
];

VerseCategory? verseById(String id) {
  for (final v in kVerses) {
    if (v.id == id) return v;
  }
  return null;
}

// ─────────────────────────────────────────────────────────────────────────────
// Named life-stages (qualitative) + endless tiers (spec §6/§17)
// ─────────────────────────────────────────────────────────────────────────────

const List<String> kYouthNames = [
  'Seed',
  'Sprouting',
  'Growing',
  'Blossoming',
  'Bearing fruit',
];

class _EndlessTier {
  final int min;
  final int tier;
  final String name;
  final double boost;
  const _EndlessTier(this.min, this.tier, this.name, this.boost);
}

const List<_EndlessTier> _endless = [
  _EndlessTier(100, 6, 'Young tree', 1.25),
  _EndlessTier(160, 7, 'Established', 1.45),
  _EndlessTier(256, 8, 'Flourishing', 1.65),
  _EndlessTier(410, 9, 'Ancient', 1.95),
  _EndlessTier(656, 10, 'Grove', 2.25),
];

class Derived {
  /// 1..5 youth stage.
  final int stage;
  final int tier;
  final String name;
  final double boost;
  const Derived(this.stage, this.tier, this.name, this.boost);
}

/// Maps an internal growth value to a named, qualitative stage + endless tier.
/// Identical math to the web engine.
Derived derive(num growth) {
  if (growth < 100) {
    final stage = ((growth ~/ 20) + 1).clamp(1, 5);
    return Derived(stage, stage, kYouthNames[stage - 1], 1);
  }
  var cur = _endless[0];
  for (final e in _endless) {
    if (growth >= e.min) cur = e;
  }
  return Derived(5, cur.tier, cur.name, cur.boost);
}

// ─────────────────────────────────────────────────────────────────────────────
// State model
// ─────────────────────────────────────────────────────────────────────────────

class Plot {
  FruitKey fruit;
  int growth;
  List<int> bloomedTiers;
  bool harvestReady;

  Plot({
    required this.fruit,
    this.growth = 5,
    List<int>? bloomedTiers,
    this.harvestReady = false,
  }) : bloomedTiers = bloomedTiers ?? <int>[];

  Plot copy() => Plot(
        fruit: fruit,
        growth: growth,
        bloomedTiers: List<int>.from(bloomedTiers),
        harvestReady: harvestReady,
      );
}

class LogEntry {
  final int day;
  final String icon;
  final String text;
  final FruitKey? fruit;
  final bool splash;
  final bool milestone;
  const LogEntry({
    required this.day,
    required this.icon,
    required this.text,
    this.fruit,
    this.splash = false,
    this.milestone = false,
  });
}

enum Season { spring, summer, autumn, winter }

class Recap {
  final String message;
  final List<String> lines;
  const Recap(this.message, this.lines);
}

Map<FruitKey, Plot> initialPlots() => {
      for (final f in kFruits) f.key: Plot(fruit: f.key, growth: 5),
    };

// ─────────────────────────────────────────────────────────────────────────────
// Auto-journey scripts (spec §13)
// ─────────────────────────────────────────────────────────────────────────────

/// A single scripted step. [run] mutates the controller; [toast] is the message
/// surfaced as it plays.
class JourneyStep {
  final void Function(dynamic g) run;
  final String toast;
  final int? day;
  const JourneyStep(this.run, this.toast, {this.day});
}
