import 'package:flutter_test/flutter_test.dart';

import 'package:faithlock/features/garden/domain/garden_engine.dart';
import 'package:faithlock/features/garden/controllers/grace_garden_controller.dart';

/// Unit tests for the pure engine (spec v2). No GetX, no rendering.
void main() {
  group('derive() — youth stages (<100)', () {
    test('19 → stage 1 (Seed), tier 1, boost 1', () {
      final d = derive(19);
      expect(d.stage, 1);
      expect(d.tier, 1);
      expect(d.name, 'Seed');
      expect(d.boost, 1);
    });

    test('20 → stage 2 (Sprouting)', () {
      final d = derive(20);
      expect(d.stage, 2);
      expect(d.tier, 2);
      expect(d.name, 'Sprouting');
      expect(d.boost, 1);
    });

    test('80 → stage 5 (Bearing fruit), tier 5, boost 1.0', () {
      final d = derive(80);
      expect(d.stage, 5);
      expect(d.tier, 5);
      expect(d.name, 'Bearing fruit');
      expect(d.boost, 1.0);
    });

    test('99 → still tier 5 (just under endless)', () {
      final d = derive(99);
      expect(d.stage, 5);
      expect(d.tier, 5);
    });
  });

  group('derive() — endless tiers (>=100)', () {
    test('100 → tier 6 "Young tree", boost 1.25', () {
      final d = derive(100);
      expect(d.stage, 5);
      expect(d.tier, 6);
      expect(d.name, 'Young tree');
      expect(d.boost, 1.25);
    });

    test('160 → tier 7 "Established"', () {
      final d = derive(160);
      expect(d.tier, 7);
      expect(d.name, 'Established');
      expect(d.boost, 1.45);
    });

    test('256 → tier 8 "Flourishing"', () {
      final d = derive(256);
      expect(d.tier, 8);
      expect(d.name, 'Flourishing');
      expect(d.boost, 1.65);
    });

    test('410 → tier 9 "Ancient"', () {
      final d = derive(410);
      expect(d.tier, 9);
      expect(d.name, 'Ancient');
      expect(d.boost, 1.95);
    });

    test('656 → tier 10 "Grove", boost 2.25', () {
      final d = derive(656);
      expect(d.tier, 10);
      expect(d.name, 'Grove');
      expect(d.boost, 2.25);
    });

    test('boundary minus one stays on the lower tier', () {
      expect(derive(159).tier, 6);
      expect(derive(255).tier, 7);
      expect(derive(409).tier, 8);
      expect(derive(655).tier, 9);
    });

    test('above the top tier stays at Grove', () {
      final d = derive(2000);
      expect(d.tier, 10);
      expect(d.name, 'Grove');
      expect(d.boost, 2.25);
    });
  });

  group('fruit catalogue', () {
    test('there are exactly 9 fruits', () {
      expect(kFruits.length, 9);
    });

    test('fruits are in canonical Galatians order', () {
      expect(kFruits.map((f) => f.key).toList(), [
        FruitKey.love,
        FruitKey.joy,
        FruitKey.peace,
        FruitKey.patience,
        FruitKey.kindness,
        FruitKey.goodness,
        FruitKey.faithfulness,
        FruitKey.gentleness,
        FruitKey.selfcontrol,
      ]);
    });

    test('evergreens are exactly Peace & Faithfulness', () {
      final evergreens =
          kFruits.where((f) => f.evergreen).map((f) => f.key).toSet();
      expect(evergreens, {FruitKey.peace, FruitKey.faithfulness});
    });

    test('kFruitByKey indexes every fruit', () {
      expect(kFruitByKey.length, 9);
      for (final f in kFruits) {
        expect(kFruitByKey[f.key], same(f));
      }
    });
  });

  group('verse attribution (spec §5)', () {
    test('fearAnxiety → Peace 1.0', () {
      final v = verseById('fearAnxiety')!;
      expect(v.awards.length, 1);
      expect(v.awards.single.fruit, FruitKey.peace);
      expect(v.awards.single.weight, 1);
    });

    test('anger → Gentleness 0.7 + Self-control 0.3 (sum 1.0)', () {
      final v = verseById('anger')!;
      final byFruit = {for (final a in v.awards) a.fruit: a.weight};
      expect(byFruit[FruitKey.gentleness], 0.7);
      expect(byFruit[FruitKey.selfcontrol], 0.3);
      expect(byFruit.values.reduce((a, b) => a + b), closeTo(1.0, 1e-9));
    });

    test('perseverance → Patience 0.7 + Faithfulness 0.3', () {
      final v = verseById('perseverance')!;
      final byFruit = {for (final a in v.awards) a.fruit: a.weight};
      expect(byFruit[FruitKey.patience], 0.7);
      expect(byFruit[FruitKey.faithfulness], 0.3);
    });

    test('service → Goodness 0.7 + Kindness 0.3', () {
      final v = verseById('service')!;
      final byFruit = {for (final a in v.awards) a.fruit: a.weight};
      expect(byFruit[FruitKey.goodness], 0.7);
      expect(byFruit[FruitKey.kindness], 0.3);
    });

    test('every verse category weights sum to 1.0', () {
      for (final v in kVerses) {
        final sum = v.awards.fold<double>(0, (s, a) => s + a.weight);
        expect(sum, closeTo(1.0, 1e-9), reason: 'category ${v.id}');
      }
    });

    test('pride maps to Gentleness (not Kindness)', () {
      final v = verseById('pride')!;
      expect(v.awards.single.fruit, FruitKey.gentleness);
    });

    test('verseById returns null for unknown id', () {
      expect(verseById('nope'), isNull);
    });
  });

  group('initialPlots()', () {
    test('seeds all 9 plots at growth 5', () {
      final plots = initialPlots();
      expect(plots.length, 9);
      for (final f in kFruits) {
        expect(plots[f.key]!.growth, 5);
        expect(plots[f.key]!.harvestReady, isFalse);
        expect(plots[f.key]!.bloomedTiers, isEmpty);
      }
    });

    test('Plot.copy() is a deep copy', () {
      final p = Plot(fruit: FruitKey.peace, growth: 42, bloomedTiers: [6]);
      final c = p.copy();
      c.growth = 99;
      c.bloomedTiers.add(7);
      expect(p.growth, 42);
      expect(p.bloomedTiers, [6]);
    });
  });

  group('build30Days() / buildJourney()', () {
    test('build30Days() is non-empty', () {
      expect(build30Days(), isNotEmpty);
    });

    test('build30Days() ends with a newMorning stamped day 30', () {
      final steps = build30Days();
      final last = steps.last;
      expect(last.day, 30);
      // The final step is the day-30 recap morning.
      final g = GraceGardenController();
      g.onInit();
      last.run(g);
      expect(g.recap.value, isNotNull);
    });

    test('buildJourney() is deterministic in length', () {
      expect(buildJourney().length, buildJourney().length);
    });

    test('build30Days() is deterministic in length', () {
      expect(build30Days().length, build30Days().length);
    });
  });
}
