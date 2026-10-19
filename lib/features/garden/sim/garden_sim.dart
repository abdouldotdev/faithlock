import 'dart:async';

import '../controllers/grace_garden_controller.dart';
import '../domain/garden_engine.dart';

/// OWNER: Dev2 (Experience & Flow).
///
/// Drives a scripted [JourneyStep] list one tick at a time so the toast messages
/// surface progressively (spec §13). Used for the post-onboarding 30-day sim and
/// the full auto-journey.
///
/// Pacing: steps that simply slip a day away play a touch quicker than active
/// days so the rhythm reads as "life moving" rather than a metronome. A short
/// settle pause at the end lets the final recap/toast breathe before [onDone].
class GardenSim {
  final GraceGardenController c;
  Timer? _timer;
  bool get running => _timer != null;

  GardenSim(this.c);

  /// Play the realistic first-30-days script. Convenience over [start].
  void start30Days({void Function()? onDone}) =>
      start(build30Days(), onDone: onDone);

  /// Play the full ~8-week seasonal journey. Convenience over [start].
  void startJourney({void Function()? onDone}) =>
      start(buildJourney(), interval: const Duration(milliseconds: 540), onDone: onDone);

  void start(
    List<JourneyStep> steps, {
    Duration interval = const Duration(milliseconds: 620),
    void Function()? onDone,
  }) {
    stop();
    var i = 0;
    void tick() {
      if (i >= steps.length) {
        stop();
        onDone?.call();
        return;
      }
      final step = steps[i++];
      step.run(c);
      c.setToast(step.toast);
      // "Away" days pass a little faster; active days linger so the growth is
      // legible. We reschedule per-step rather than using a fixed periodic timer.
      final isAway = step.toast.contains('slips') || step.toast.contains('🌙');
      final next = isAway
          ? interval * 0.7
          : (step.day == 30 || i >= steps.length)
              ? interval * 2.2 // let the closing beat settle
              : interval;
      _timer = Timer(next, tick);
    }

    _timer = Timer(interval, tick);
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}
