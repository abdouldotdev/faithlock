import 'package:faithlock/features/faithlock/services/mood_service.dart';
import 'package:faithlock/services/analytics/posthog/export.dart';
import 'package:faithlock/services/storage/preferences_service.dart';
import 'package:get/get.dart';

import 'tour_step.dart';

/// Drives the first-day feature tour: which step is showing, advancing /
/// rewinding, and the once-per-install "seen it" flag.
///
/// The controller owns *state only* — the [SpotlightOverlay] widget reads
/// [index] reactively and handles measuring targets, tab switching and the
/// spotlight animation. Keeping geometry out of here means the controller has
/// no opinion on the render tree and stays trivially testable.
class FeatureTourController extends GetxController {
  final PreferencesService _prefs = PreferencesService();
  final PostHogService _analytics = PostHogService.instance;

  /// How this run was launched ('auto' first-day, or 'replay' from Profile).
  String _source = 'auto';

  /// Persisted in PreferencesService (cleared on uninstall, like the rest of
  /// onboarding) so the tour auto-plays exactly once after onboarding.
  static const String _keyTourComplete = 'first_day_feature_tour_complete';

  /// The current run's steps. Empty when the tour is not active.
  final RxList<TourStep> steps = <TourStep>[].obs;

  /// Index into [steps] of the visible beat.
  final RxInt index = 0.obs;

  /// True while the overlay is mounted.
  final RxBool active = false.obs;

  /// Fires once when the user reaches the very end and dismisses — the host
  /// listens to this to pop confetti for the "wow" finish.
  final RxBool celebrate = false.obs;

  /// Localized mood label (e.g. "effondré") the user picked during the
  /// interactive prayer step, used to personalize the "Chosen for you" step.
  /// Empty when no mood has been recorded yet → the step shows generic copy.
  final RxString curatedMood = ''.obs;

  /// Pull the most recent mood check-in and resolve it to a localized,
  /// lowercase label. Called when the curated step is revealed (by which point
  /// the interactive prayer step has saved a mood, if the user picked one).
  Future<void> loadCuratedMood() async {
    final mood = await MoodService().lastMood();
    curatedMood.value =
        mood != null ? ('mood_${mood.name}'.tr).toLowerCase() : '';
  }

  TourStep get current => steps[index.value];
  bool get isFirst => index.value == 0;
  bool get isLast => index.value >= steps.length - 1;
  int get total => steps.length;

  Future<bool> hasSeenTour() async =>
      await _prefs.readBool(_keyTourComplete) ?? false;

  Future<void> _markSeen() => _prefs.writeBool(_keyTourComplete, true);

  /// Debug / "replay tour" helper: clears the seen flag so it auto-plays again.
  Future<void> resetSeen() => _prefs.writeBool(_keyTourComplete, false);

  /// Begin a run. [tourSteps] are measured & spotlit in order. [source] tags
  /// every event of this run as 'auto' (first-day) or 'replay' (from Profile).
  void begin(List<TourStep> tourSteps, {String source = 'auto'}) {
    if (active.value) return;
    _source = source;
    steps.assignAll(tourSteps);
    index.value = 0;
    celebrate.value = false;
    active.value = true;
    _track('tour_started', {'source': source, 'step_count': total});
    _trackStep('tour_step_initiated');
  }

  void next() {
    // An interactive step (the real prayer) auto-advances on completion — log
    // that the action was actually done before moving on.
    if (steps.isNotEmpty && current.interactive) {
      _track('tour_interactive_completed', {
        'step_id': current.id,
        'step_index': index.value,
      });
    }
    // The step the user is leaving is now done — fire it for every advance,
    // including the final step that triggers finish().
    _trackStep('tour_step_completed');
    if (isLast) {
      finish(completed: true);
    } else {
      index.value += 1;
      _trackStep('tour_step_initiated');
    }
  }

  /// Advance an interactive step only when its real action reports completion.
  ///
  /// This avoids treating a dismissed pushed route as success. For example, if
  /// the user opens the prayer library and closes it before finishing a prayer,
  /// the tour stays on the Pray step and can continue from the home screen.
  void completeInteractiveStep(String stepId) {
    if (!active.value || steps.isEmpty) return;
    if (!current.interactive || current.id != stepId) return;
    next();
  }

  void back() {
    if (!isFirst) {
      index.value -= 1;
      _trackStep('tour_step_initiated');
    }
  }

  /// Tear the tour down. [completed] true → reached the end (celebrate);
  /// false → user skipped. Either way we mark it seen so it won't re-nag.
  Future<void> finish({required bool completed}) async {
    if (!active.value) return;
    if (completed) {
      _track('tour_completed', {'step_count': total, 'source': _source});
      celebrate.value = true;
    } else {
      // Bailed out mid-step — record which step was interrupted.
      _trackStep('tour_step_interrupted');
      _track('tour_skipped', {
        'step_id': steps.isNotEmpty ? current.id : null,
        'step_index': index.value,
        'source': _source,
      });
    }
    active.value = false;
    await _markSeen();
  }

  /// Emit a per-step lifecycle event (`tour_step_initiated` /
  /// `tour_step_completed` / `tour_step_interrupted`) for the current step.
  void _trackStep(String event) {
    if (steps.isEmpty) return;
    _track(event, {
      'step_id': current.id,
      'step_index': index.value,
      'step_count': total,
      'source': _source,
    });
  }

  void _track(String event, Map<String, dynamic> props) {
    if (_analytics.isReady) _analytics.events.trackCustom(event, props);
  }
}
