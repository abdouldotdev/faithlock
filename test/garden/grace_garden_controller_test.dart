import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:faithlock/features/garden/domain/garden_engine.dart';
import 'package:faithlock/features/garden/controllers/grace_garden_controller.dart';

/// Controller transition tests. We instantiate the controller and drive its
/// public actions, asserting the exact engine deltas from the spec.
void main() {
  late GraceGardenController g;

  setUp(() {
    g = GraceGardenController();
    g.onInit(); // seeds initial plots + popSignal
  });

  tearDown(() {
    Get.reset();
  });

  int growth(FruitKey f) => g.plot(f).growth;

  group('readVerse — day 1, first practice', () {
    test('peace deepens, garden splashes, faithfulness rewards returning', () {
      // rhythm at window 1 = 1 + 0.04*1 = 1.04
      const rhythm = 1.04;
      final award = (10 * 1 * rhythm).round(); // 10
      final splash = (2 * rhythm).round(); // 2

      // Pre-conditions: all start at 5, window 1, active (day 1 default).
      // activeToday defaults true, so the FIRST readVerse will NOT trigger
      // _applyActive (the day-1 "showing up" is already counted at seed).
      // To exercise the first-practice bonus we mirror a real day: the
      // controller is born with activeToday=true. Start a fresh day instead.
      g.goAway(); // day 2, activeToday=false, window 1->0, health 100->94
      // Drop health well below the 100 cap so the +12 comeback bump is visible
      // (health is clamped at 100 — see spec §8).
      g.setHealthValue(50);
      final winBefore = g.activeDaysWindow.value; // 0
      final healthBefore = g.health.value; // 50
      final faithBefore = growth(FruitKey.faithfulness);
      final peaceBefore = growth(FruitKey.peace);
      final loveBefore = growth(FruitKey.love);

      // rhythm now reflects window 0 → 1.0
      g.readVerse('fearAnxiety');

      // window 0 → readVerse uses rhythm 1.0 BEFORE _applyActive bumps it.
      final r0 = 1.0;
      final award0 = (10 * 1 * r0).round(); // 10
      final splash0 = (2 * r0).round(); // 2

      // peace = award + splash
      expect(growth(FruitKey.peace) - peaceBefore, award0 + splash0);
      // every other fruit got the splash
      expect(growth(FruitKey.love) - loveBefore, splash0);
      // faithfulness: splash + the +3 returning bonus
      expect(growth(FruitKey.faithfulness) - faithBefore, splash0 + 3);
      // window advanced (comeback): 0 -> 1
      expect(g.activeDaysWindow.value, winBefore + 1);
      // health bumped (+12 comeback because wasAway was true)
      expect(g.health.value, healthBefore + 12);
      expect(g.activeToday.value, isTrue);

      // suppress unused warnings for the documented expected values
      expect(award, 10);
      expect(splash, 2);
    });

    test('+10 health on a normal (non-comeback) first practice', () {
      // Make a fresh non-away day: advance the day manually without goAway's
      // wasAway flag by simulating a clean morning sequence.
      g.day.value = 2;
      g.activeToday.value = false;
      g.wasAway.value = false; // not coming back from an absence
      g.setHealthValue(50); // below the 100 cap so the +10 is visible
      final healthBefore = g.health.value;
      g.readVerse('fearAnxiety');
      expect(g.health.value, healthBefore + 10);
    });
  });

  group('readVerse — second practice same day (activeToday guard)', () {
    test('no extra faithfulness +3 and no extra health on the 2nd read', () {
      // First practice of a fresh day.
      g.day.value = 2;
      g.activeToday.value = false;
      g.wasAway.value = false;
      g.readVerse('fearAnxiety');

      final faithAfter1 = growth(FruitKey.faithfulness);
      final healthAfter1 = g.health.value;
      final windowAfter1 = g.activeDaysWindow.value;

      // Second practice, same day.
      g.readVerse('fearAnxiety');

      // Only the splash + award changed faithfulness, NOT another +3 bonus,
      // and health/window did not move again.
      // rhythm is now windowAfter1 → multiplier.
      final r = 1 + 0.04 * windowAfter1;
      final splash = (2 * r).round();
      expect(growth(FruitKey.faithfulness) - faithAfter1, splash);
      expect(g.health.value, healthAfter1);
      expect(g.activeDaysWindow.value, windowAfter1);
    });
  });

  group('pray()', () {
    test('every fruit grows by round(3 * rhythm)', () {
      // window 1 → rhythm 1.04 → round(1*3*1.04)=round(3.12)=3
      final before = {for (final f in kFruits) f.key: growth(f.key)};
      final r = g.rhythm();
      final delta = (1 * 3 * r).round();
      g.pray();
      for (final f in kFruits) {
        expect(growth(f.key) - before[f.key]!, delta,
            reason: 'fruit ${f.key}');
      }
    });

    test('pray does not award the faithfulness +3 bonus separately', () {
      // pray on day 1 with activeToday=true → no _applyActive bonus.
      final before = growth(FruitKey.faithfulness);
      final r = g.rhythm();
      final delta = (1 * 3 * r).round();
      g.pray();
      expect(growth(FruitKey.faithfulness) - before, delta);
    });
  });

  group('talk()', () {
    test('grows the selected plot by round(15 * rhythm)', () {
      g.select(FruitKey.joy);
      final before = growth(FruitKey.joy);
      final r = g.rhythm();
      final delta = (15 * r).round();
      g.talk();
      expect(growth(FruitKey.joy) - before, delta);
    });

    test('with no selection, grows the lowest plot', () {
      // Make one plot clearly the lowest.
      g.setGrowth(FruitKey.kindness, 1);
      g.select(null);
      final before = growth(FruitKey.kindness);
      final r = g.rhythm();
      final delta = (15 * r).round();
      g.talk();
      expect(growth(FruitKey.kindness) - before, delta);
    });
  });

  group('goAway()', () {
    test('health -6, window -1, day +1, flags set', () {
      final healthBefore = g.health.value; // 100
      final dayBefore = g.day.value; // 1
      final windowBefore = g.activeDaysWindow.value; // 1
      g.goAway();
      expect(g.health.value, healthBefore - 6);
      expect(g.activeDaysWindow.value, windowBefore - 1);
      expect(g.day.value, dayBefore + 1);
      expect(g.activeToday.value, isFalse);
      expect(g.wasAway.value, isTrue);
    });

    test('health floors at 20', () {
      g.setHealthValue(22);
      g.goAway();
      g.goAway();
      g.goAway();
      expect(g.health.value, 20);
    });
  });

  group('newMorning()', () {
    test('a plot >= 80 becomes harvestReady and a recap is set', () {
      g.setGrowth(FruitKey.peace, 85);
      expect(g.plot(FruitKey.peace).harvestReady, isFalse);
      g.newMorning();
      expect(g.plot(FruitKey.peace).harvestReady, isTrue);
      expect(g.recap.value, isNotNull);
    });

    test('a plot < 80 does not become harvestReady', () {
      g.setGrowth(FruitKey.love, 79);
      g.newMorning();
      expect(g.plot(FruitKey.love).harvestReady, isFalse);
    });
  });

  group('rhythm() cap', () {
    test('window driven to 7 clamps rhythm at 1.28', () {
      g.activeDaysWindow.value = 7;
      expect(g.rhythm(), closeTo(1.28, 1e-9));
    });

    test('window beyond 7 stays clamped at 1.28', () {
      g.activeDaysWindow.value = 99;
      expect(g.rhythm(), 1.28);
    });

    test('window 0 → rhythm 1.0', () {
      g.activeDaysWindow.value = 0;
      expect(g.rhythm(), closeTo(1.0, 1e-9));
    });
  });

  group('milestones', () {
    test('crossing a tier boundary logs a milestone entry', () {
      // Put Peace just below the tier-6 boundary (100) and read enough to
      // cross it. At window 1, readVerse('fearAnxiety') adds peace
      // round(10*1.04)=10 + splash 2 = 12.
      g.setGrowth(FruitKey.peace, 95); // tier 5
      final beforeMilestones =
          g.log.where((e) => e.milestone).length;
      g.readVerse('fearAnxiety'); // -> 95 + 12 = 107 → tier 6
      expect(derive(growth(FruitKey.peace)).tier, 6);
      final afterMilestones = g.log.where((e) => e.milestone).length;
      expect(afterMilestones, greaterThan(beforeMilestones));
      // The crossed tier is recorded on the plot.
      expect(g.plot(FruitKey.peace).bloomedTiers, contains(6));
    });

    test('no milestone when staying within the same tier', () {
      g.setGrowth(FruitKey.peace, 30); // tier 2
      final before = g.log.where((e) => e.milestone).length;
      g.readVerse('fearAnxiety'); // -> ~42, still well under tier 3? 30->42
      // 42 → stage 3, tier 3 — actually crosses. Use a tighter case.
      // Reset and use a value that stays in-tier.
      g.setGrowth(FruitKey.peace, 22); // tier 2 (20..39)
      final mid = g.log.where((e) => e.milestone).length;
      g.readVerse('fearAnxiety'); // -> ~34, still tier 2
      expect(derive(growth(FruitKey.peace)).tier, 2);
      final after = g.log.where((e) => e.milestone).length;
      expect(after, mid);
      expect(mid, greaterThanOrEqualTo(before));
    });
  });

  group('shareHarvest()', () {
    test('clears harvestReady and increments fruitShared', () {
      g.setHarvest(FruitKey.peace, true);
      final before = g.fruitShared.value;
      g.shareHarvest(FruitKey.peace);
      expect(g.plot(FruitKey.peace).harvestReady, isFalse);
      expect(g.fruitShared.value, before + 1);
    });
  });

  group('reset()', () {
    test('returns the controller to its seeded initial state', () {
      g.setGrowth(FruitKey.peace, 500);
      g.goAway();
      g.reset();
      expect(g.day.value, 1);
      expect(g.health.value, 100);
      expect(g.activeDaysWindow.value, 1);
      expect(g.activeToday.value, isTrue);
      expect(g.wasAway.value, isFalse);
      expect(growth(FruitKey.peace), 5);
      expect(g.log, isEmpty);
    });
  });
}
