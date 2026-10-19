import 'package:get/get.dart';

import 'package:faithlock/services/storage/preferences_service.dart';

/// Drives the Garden hero (the photoreal pot). [progress] (0→1) is overall
/// growth, [health] (0→1) is vitality (low = resting).
///
/// The model is **presence-driven** (see docs/garden-gamification-spec.md
/// §0/§6/§7/§8): growth is a function of how many distinct days the user has
/// shown up over the plant's lifetime — each day of presence is one step
/// forward, and that count never decreases, so SIZE/stage is MONOTONIC and is
/// never lost. Absence only lowers [health] (the plant rests/wilts visibly),
/// floored at 0.20 so it never dies. No user-facing numbers are exposed.
///   - growth  = [activeDaysToProgress] over cumulative lifetime active days.
///   - health  = (100 − daysSinceActive·6) clamped to [20,100], /100.
class GardenController extends GetxController {
  GardenController({PreferencesService? prefs})
      : _prefs = prefs ?? PreferencesService();

  final PreferencesService _prefs;

  /// SharedPreferences keys (cleared on uninstall, like the rest of the app).
  static const String _kActiveDays = 'garden_active_days';
  static const String _kLastActive = 'garden_last_active';

  final RxDouble progress = 0.0.obs;
  final RxDouble health = 1.0.obs;

  /// Cumulative lifetime days of presence (monotonic).
  int _activeDays = 0;

  /// ISO `yyyy-MM-dd` of the last day the user showed up, or null for a brand
  /// new user who has never opened the app before.
  String? _lastActive;

  bool _running = false;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  // ── Presence model ─────────────────────────────────────────────────────────

  /// Active-days → progress breakpoints, `[activeDays, progress]`, monotonic.
  /// A log-ish curve: growth is brisk in the first weeks and tapers as the tree
  /// matures. Calibrated to the spec — day 0 → seed, ~day 7 → ~0.30, ~day 25 →
  /// ~0.78 (first fruit ≈ 0.85), ~day 60 → ~0.92, ~day 120 → ~0.97, day 150+ →
  /// fully grown. Covers every case: <0 clamps to 0, ≥150 clamps to 1.
  static const List<List<double>> _daysToProgress = [
    [0, 0.0], // Seed
    [3, 0.16], // germination
    [7, 0.30], // young shrub
    [14, 0.55], // canopy fills
    [25, 0.78], // flowering → first fruit nears
    [40, 0.86], // fruit set
    [60, 0.92], // young tree
    [120, 0.97], // established
    [150, 1.0], // grand mature tree
  ];

  /// Maps cumulative lifetime active days onto a 0→1 growth value via
  /// [_daysToProgress] (piecewise-linear, clamped). Pure + static so it's
  /// trivially testable and monotonic by construction.
  static double activeDaysToProgress(int days) {
    final t = days.toDouble();
    final pts = _daysToProgress;
    if (t <= pts.first[0]) return pts.first[1];
    if (t >= pts.last[0]) return pts.last[1];
    for (var i = 0; i < pts.length - 1; i++) {
      final a = pts[i];
      final b = pts[i + 1];
      if (t >= a[0] && t <= b[0]) {
        final f = (t - a[0]) / (b[0] - a[0]);
        return a[1] + (b[1] - a[1]) * f;
      }
    }
    return pts.last[1];
  }

  /// health from days since the user was last active — recent rhythm keeps the
  /// plant vibrant; absence makes it rest/wilt, floored at 0.20 (never dies).
  static double healthFromAbsence(int daysSinceActive) =>
      (100 - daysSinceActive * 6).clamp(20, 100) / 100.0;

  /// `yyyy-MM-dd` for a date (date-only, used as the day identity).
  static String _dateKey(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  /// Whole-day gap between two `yyyy-MM-dd` keys (b − a), clamped at 0.
  static int _daysBetween(String a, String b) {
    final da = DateTime.parse(a);
    final db = DateTime.parse(b);
    return db.difference(da).inDays.clamp(0, 1 << 30);
  }

  /// Recompute [progress] / [health] from the in-memory presence state.
  void _recompute({required int daysSinceActive}) {
    if (_running) return; // don't fight an in-flight animation
    progress.value = activeDaysToProgress(_activeDays);
    health.value = healthFromAbsence(daysSinceActive);
  }

  /// Loads persisted presence, then registers today's visit so opening the app
  /// counts as showing up and refreshes the tree.
  Future<void> _load() async {
    _activeDays = await _prefs.readInt(_kActiveDays) ?? 0;
    _lastActive = await _prefs.readString(_kLastActive);
    await registerVisitToday();
  }

  /// Counts today as a day of presence (once per calendar day) and refreshes
  /// the tree. Health reflects how long the user had been away *before* this
  /// visit (the gap from the previous active day), so a return after an absence
  /// shows the plant resting/wilting — it recovers as the daily rhythm resumes.
  /// New users (no stored data) start fresh: a seed at full health.
  Future<void> registerVisitToday() async {
    final today = _dateKey(DateTime.now());
    if (_lastActive == null) {
      // Brand-new user: first ever visit. Begin the lifetime at day one of
      // presence so the tree shows a fresh, healthy seed.
      _activeDays = _activeDays > 0 ? _activeDays : 1;
      _lastActive = today;
      await _persist();
      _recompute(daysSinceActive: 0);
      return;
    }
    // Gap from the previous active day — drives the visible resting/wilt.
    final daysSinceActive = _daysBetween(_lastActive!, today);
    if (_lastActive != today) {
      _activeDays += 1;
      _lastActive = today;
      await _persist();
    }
    _recompute(daysSinceActive: daysSinceActive);
  }

  Future<void> _persist() async {
    await _prefs.writeInt(_kActiveDays, _activeDays);
    await _prefs.writeString(_kLastActive, _lastActive!);
  }

  /// One prayer's worth of growth — a gentle, animated bump used when the user
  /// actually prays (e.g. the first-day tour's "watch it grow" payoff). Health
  /// is restored to full; progress eases up by [amount] over a short beat so the
  /// hero visibly sprouts rather than jumping. Visual only — the persisted
  /// presence model is the source of truth on the next refresh.
  Future<void> nurture({double amount = 0.14}) async {
    if (_running) return;
    _running = true;
    final start = progress.value;
    final target = (start + amount).clamp(0.0, 1.0);
    health.value = 1.0;
    const steps = 20;
    for (var i = 1; i <= steps; i++) {
      progress.value = start + (target - start) * (i / steps);
      await Future<void>.delayed(const Duration(milliseconds: 26));
    }
    progress.value = target;
    _running = false;
  }

  /// Debug-only: preview an arbitrary presence scenario WITHOUT persisting.
  /// Sets the in-memory active-day count + absence and recomputes the tree, so
  /// the debug panel can simulate reopening the app after [daysSinceActive]
  /// days away with [activeDays] of lifetime presence.
  void debugApply({required int activeDays, required int daysSinceActive}) {
    _activeDays = activeDays;
    _recompute(daysSinceActive: daysSinceActive);
  }
}
