import 'dart:math' as math;

import 'package:get/get.dart';

import '../domain/garden_engine.dart';

/// Reactive state + actions for the full-screen Garden of Grace experience.
/// Faithful GetX port of the zustand store in
/// `apps/garden-web/src/engine/garden.ts`.
///
/// NOTE: this is a SEPARATE controller from the legacy [GardenController]
/// (which drives the small pot hero on the home screen). Do not merge them.
class GraceGardenController extends GetxController {
  // ── Reactive state ─────────────────────────────────────────────────────────
  final RxInt day = 1.obs;
  final RxInt health = 100.obs; // 0..100
  final RxInt activeDaysWindow = 1.obs; // 0..7 rolling presence
  final RxBool activeToday = true.obs;
  final RxBool wasAway = false.obs;
  final RxInt fruitShared = 0.obs;
  final Rx<Season> season = Season.spring.obs;
  final RxDouble timeOfDay = 0.5.obs; // 0 night · 0.5 noon · 1 night

  final RxMap<FruitKey, Plot> plots = <FruitKey, Plot>{}.obs;
  final Rxn<FruitKey> selected = Rxn<FruitKey>();
  final RxBool tappedPlant = false.obs; // true after first plant tap
  final RxMap<FruitKey, int> popSignal = <FruitKey, int>{}.obs; // grow-anim ticks
  final RxList<LogEntry> log = <LogEntry>[].obs;
  final Rxn<Recap> recap = Rxn<Recap>();
  final Rxn<String> toast = Rxn<String>();

  // onboarding cinematic: drives camera focus + element isolation
  final RxBool introActive = false.obs;
  final Rxn<FruitKey> introFocus = Rxn<FruitKey>();
  final RxBool introSolo = false.obs;

  static const int _rand = 3; // deterministic verse cursor seed (web parity)
  int _verseCursor = _rand;

  @override
  void onInit() {
    super.onInit();
    _seedInitial();
  }

  void _seedInitial() {
    plots.assignAll(initialPlots());
    popSignal.assignAll({for (final f in kFruits) f.key: 0});
  }

  // ── Derived ─────────────────────────────────────────────────────────────────
  double rhythm() => math.min(1.28, 1 + 0.04 * activeDaysWindow.value);

  Plot plot(FruitKey f) => plots[f]!;

  FruitKey _lowestGrowth() {
    var lo = kFruits.first.key;
    for (final f in kFruits) {
      if (plots[f.key]!.growth < plots[lo]!.growth) lo = f.key;
    }
    return lo;
  }

  // ── Actions ──────────────────────────────────────────────────────────────────
  void readVerse([String? forceId]) {
    final v = forceId != null
        ? (verseById(forceId) ?? kVerses[0])
        : kVerses[_verseCursor++ % kVerses.length];
    final mult = rhythm();
    final logs = <LogEntry>[];

    for (final a in v.awards) {
      final p = plots[a.fruit]!;
      final before = p.growth;
      p.growth += (10 * a.weight * mult).round();
      popSignal[a.fruit] = (popSignal[a.fruit] ?? 0) + 1;
      _checkMilestone(before, p.growth, a.fruit, logs);
    }
    // splash: the whole garden drinks a little
    for (final f in kFruits) {
      plots[f.key]!.growth += (2 * mult).round();
    }
    logs.insert(
      0,
      LogEntry(
        day: day.value,
        icon: '📖',
        text:
            '${v.sample} → your ${fruitLabel(v.awards.first.fruit)} deepened',
        fruit: v.awards.first.fruit,
      ),
    );

    _applyActive();
    plots.refresh();
    popSignal.refresh();
    _pushLogs(logs);
  }

  void pray() {
    final mult = rhythm();
    const minutes = 3;
    for (final f in kFruits) {
      plots[f.key]!.growth += (1 * minutes * mult).round();
    }
    _applyActive();
    plots.refresh();
    _pushLogs([
      LogEntry(
        day: day.value,
        icon: '🙏',
        text: 'A few quiet minutes of prayer → everything drank a little',
        splash: true,
      ),
    ]);
  }

  void talk() {
    final mult = rhythm();
    final target = selected.value ?? _lowestGrowth();
    final logs = <LogEntry>[];
    final p = plots[target]!;
    final before = p.growth;
    p.growth += (15 * mult).round();
    popSignal[target] = (popSignal[target] ?? 0) + 1;
    _checkMilestone(before, p.growth, target, logs);
    logs.insert(
      0,
      LogEntry(
        day: day.value,
        icon: '💬',
        text: 'You talked it through with Judah',
        fruit: target,
      ),
    );
    _applyActive();
    plots.refresh();
    popSignal.refresh();
    _pushLogs(logs);
  }

  void shareHarvest(FruitKey f) {
    plots[f]!.harvestReady = false;
    fruitShared.value += 1;
    plots.refresh();
    _pushLogs([
      LogEntry(
        day: day.value,
        icon: '🍎',
        text: 'You shared a harvest of ${fruitLabel(f)} with someone.',
        fruit: f,
        milestone: true,
      ),
    ]);
  }

  void select(FruitKey? f) {
    selected.value = f;
    if (f != null) tappedPlant.value = true;
  }

  void goAway() {
    day.value += 1;
    activeToday.value = false;
    wasAway.value = true;
    health.value = math.max(20, health.value - 6);
    activeDaysWindow.value = math.max(0, activeDaysWindow.value - 1);
  }

  void newMorning() {
    final away = wasAway.value;
    final lines = <String>[];
    if (away) {
      lines.add(
          'Nothing was lost while you were away — the leaves just waited for you. 🤍');
      lines.add(
          'The garden is resting and ready. Everything you grew is still here.');
    } else {
      lines.add('Morning. There’s fresh dew on everything. 🌤️');
    }
    for (final f in kFruits) {
      final p = plots[f.key]!;
      if (p.growth >= 80 && !p.harvestReady) p.harvestReady = true;
    }
    timeOfDay.value = 0.25;
    recap.value = Recap(away ? 'Welcome home.' : 'A new morning', lines);
    plots.refresh();
  }

  // ── Setters (used by onboarding cinematic + dev controls) ─────────────────────
  void setTime(double t) => timeOfDay.value = t;
  void setSeason(Season s) => season.value = s;
  void setToast(String? m) => toast.value = m;
  void setRecap(Recap? r) => recap.value = r;

  void setIntro({bool? active, FruitKey? focus, bool? solo, bool clearFocus = false}) {
    if (active != null) introActive.value = active;
    if (clearFocus) {
      introFocus.value = null;
    } else if (focus != null) {
      introFocus.value = focus;
    }
    if (solo != null) introSolo.value = solo;
  }

  void setGrowth(FruitKey f, int v) {
    plots[f]!.growth = v;
    plots.refresh();
  }

  void setHealthValue(int v) => health.value = v;

  void setHarvest(FruitKey f, bool v) {
    plots[f]!.harvestReady = v;
    plots.refresh();
  }

  void reset() {
    _verseCursor = _rand;
    day.value = 1;
    health.value = 100;
    activeDaysWindow.value = 1;
    activeToday.value = true;
    wasAway.value = false;
    fruitShared.value = 0;
    season.value = Season.spring;
    timeOfDay.value = 0.5;
    selected.value = null;
    tappedPlant.value = false;
    log.clear();
    recap.value = null;
    toast.value = null;
    introActive.value = false;
    introFocus.value = null;
    introSolo.value = false;
    _seedInitial();
  }

  // ── Internals ─────────────────────────────────────────────────────────────────

  /// First practice of the day: Faithfulness +3 ("the discipline of showing
  /// up"), health +10 (+12 if coming back), rhythm window +1. No-op on later
  /// practices the same day. Mirrors `markActive` in the web engine.
  void _applyActive() {
    if (activeToday.value) return;
    final comingBack = wasAway.value;
    plots[FruitKey.faithfulness]!.growth += 3;
    activeToday.value = true;
    wasAway.value = false;
    health.value = math.min(100, health.value + (comingBack ? 12 : 10));
    activeDaysWindow.value = math.min(7, activeDaysWindow.value + 1);
  }

  void _checkMilestone(
      int before, int after, FruitKey fruit, List<LogEntry> logs) {
    final b = derive(before);
    final a = derive(after);
    if (a.tier > b.tier) {
      plots[fruit]!.bloomedTiers.add(a.tier);
      logs.insert(
        0,
        LogEntry(
          day: day.value,
          icon: '🌸',
          text: 'Your ${fruitLabel(fruit)} reached ${a.name}. I remember this one.',
          fruit: fruit,
          milestone: true,
        ),
      );
    }
  }

  void _pushLogs(List<LogEntry> entries) {
    if (entries.isEmpty) return;
    log.insertAll(0, entries);
    if (log.length > 60) log.removeRange(60, log.length);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Auto-journey scripts (spec §13) — live here because they drive the controller.
// ─────────────────────────────────────────────────────────────────────────────

/// A realistic FIRST 30 DAYS: eager start, a few slips, a short break, a gentle
/// comeback, then a steadier rhythm. Plays right after onboarding.
List<JourneyStep> build30Days() {
  final steps = <JourneyStep>[];
  var dayNo = 0;

  void read(String id, String toast) => steps.add(
      JourneyStep((g) => (g as GraceGardenController).readVerse(id), toast,
          day: dayNo));
  void pray(String toast) => steps.add(
      JourneyStep((g) => (g as GraceGardenController).pray(), toast, day: dayNo));
  void talk(String toast) => steps.add(
      JourneyStep((g) => (g as GraceGardenController).talk(), toast, day: dayNo));
  void away(String toast) => steps.add(
      JourneyStep((g) => (g as GraceGardenController).goAway(), toast, day: dayNo));
  void morning(String toast) => steps.add(JourneyStep(
      (g) => (g as GraceGardenController).newMorning(), toast,
      day: dayNo));

  // 30 day-types: 0=away, 1=light, 2=active.
  const pattern = [
    2, 2, 1, 2, 0, 1, 2, 1, 0, 0, 1, 2, 1, 2, 0, //
    1, 2, 1, 0, 1, 2, 1, 2, 2, 1, 2, 1, 2, 1, 2,
  ];
  var prevAway = false;
  for (final v in pattern) {
    dayNo++;
    if (v == 0) {
      away('Day $dayNo · a day slips by 🌙');
      prevAway = true;
      continue;
    }
    if (prevAway) {
      morning('Day $dayNo · welcome back — nothing was lost 🤍');
      prevAway = false;
    }
    read('fearAnxiety', 'Day $dayNo · a verse on anxiety → Peace deepens');
    if (v == 2) {
      final pick = dayNo % 3;
      if (pick == 0) {
        pray('Day $dayNo · a few minutes of prayer → the whole garden drinks');
      } else if (pick == 1) {
        talk('Day $dayNo · a talk with Judah');
      } else {
        read('gratitude', 'Day $dayNo · a verse of gratitude → Joy stirs');
      }
    }
  }
  steps.add(JourneyStep(
    (g) => (g as GraceGardenController).newMorning(),
    '30 days in — look what grew. You tended; God gave the growth. 🌿',
    day: 30,
  ));
  return steps;
}

/// A scripted ~8-week journey (anxiety → Peace) with breaks, misses, and gentle
/// comebacks across the seasons. Steps play one per tick.
List<JourneyStep> buildJourney() {
  final steps = <JourneyStep>[];
  void read(String id, String toast) => steps
      .add(JourneyStep((g) => (g as GraceGardenController).readVerse(id), toast));
  void pray(String toast) =>
      steps.add(JourneyStep((g) => (g as GraceGardenController).pray(), toast));
  void talk(String toast) =>
      steps.add(JourneyStep((g) => (g as GraceGardenController).talk(), toast));
  void away(String toast) =>
      steps.add(JourneyStep((g) => (g as GraceGardenController).goAway(), toast));
  void morning(String toast) => steps
      .add(JourneyStep((g) => (g as GraceGardenController).newMorning(), toast));
  void setSeason(Season s, String toast) => steps.add(
      JourneyStep((g) => (g as GraceGardenController).setSeason(s), toast));

  const week = [
    [2, 2, 1, 2, 0, 1, 2], // eager start
    [1, 2, 0, 0, 1, 2, 1], // first slips
    [0, 0, 1, 2, 1, 0, 1], // a rough week
    [2, 1, 2, 0, 1, 1, 2], // steadier
    [0, 0, 0, 1, 0, 1, 0], // a hard, dry season
    [1, 2, 2, 1, 2, 0, 1], // the comeback
    [2, 1, 0, 1, 2, 1, 2],
    [1, 0, 1, 2, 1, 2, 2], // it has become a rhythm
  ];
  var prevAway = false;
  for (var w = 0; w < week.length; w++) {
    if (w == 3) setSeason(Season.autumn, '🍂 Autumn settles in.');
    if (w == 4) {
      setSeason(Season.winter,
          '❄️ Winter — the garden rests. Even bare, the roots keep working.');
    }
    if (w == 5) setSeason(Season.spring, '🌸 Spring returns — new growth.');
    if (w == 7) setSeason(Season.summer, '☀️ High summer — lush and full.');
    for (var d = 0; d < 7; d++) {
      final v = week[w][d];
      if (v == 0) {
        away('🌙 A day slips by…');
        prevAway = true;
        continue;
      }
      if (prevAway) {
        morning('☀️ Coming back — "Nothing was lost while you were away. 🤍"');
        prevAway = false;
      } else if (d == 0) {
        morning('🌤️ A new morning — fresh dew.');
      }
      read('fearAnxiety', '📖 A verse on anxiety → Peace deepens');
      if (v == 2) {
        final pick = (w + d) % 3;
        if (pick == 0) {
          pray('🙏 A few quiet minutes → the whole garden drinks');
        } else if (pick == 1) {
          talk('💬 A talk with Judah');
        } else {
          read('gratitude', '📖 A verse of gratitude → Joy stirs');
        }
      }
    }
  }
  morning(
      '🌇 Weeks later — the garden has grown into a little grove. Look what God grew.');
  return steps;
}
