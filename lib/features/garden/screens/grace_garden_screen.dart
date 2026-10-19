import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:faithlock/features/faithlock/controllers/stats_controller.dart';
import 'package:faithlock/services/analytics/posthog/export.dart';
import '../controllers/grace_garden_controller.dart';
import '../data/garden_backfill.dart';
import '../sim/garden_sim.dart';
import '../widgets/garden_tree_3d.dart';
import '../widgets/garden_hud.dart';
import '../widgets/garden_journal_sheet.dart';
import '../widgets/garden_onboarding.dart';
import '../widgets/garden_recap.dart';
import '../widgets/garden_toast.dart';
import '../widgets/judah_companion.dart';

/// OWNER: Tech Lead (integration). Full-screen Garden of Grace.
///
/// The garden itself is a REAL navigable 3D scene ([GardenCube3D] — drag to
/// orbit, pinch to zoom), with the Flutter overlays (HUD / toast / Judah /
/// recap / onboarding) composited on top.
///
/// Flow: first run → onboarding cinematic → 30-day simulation → live garden.
class GraceGardenScreen extends StatefulWidget {
  const GraceGardenScreen({super.key});

  @override
  State<GraceGardenScreen> createState() => _GraceGardenScreenState();
}

class _GraceGardenScreenState extends State<GraceGardenScreen> {
  late final GraceGardenController c;
  late final GardenSim _sim;
  bool _onboarding = true;

  final PostHogService _analytics = PostHogService.instance;

  void _track(String event, [Map<String, dynamic> props = const {}]) {
    if (_analytics.isReady) _analytics.events.trackCustom(event, props);
  }

  @override
  void initState() {
    super.initState();
    c = Get.isRegistered<GraceGardenController>()
        ? Get.find<GraceGardenController>()
        : Get.put(GraceGardenController());
    _sim = GardenSim(c);
    _track('garden_viewed');
  }

  @override
  void dispose() {
    _sim.stop();
    super.dispose();
  }

  void _onboardingDone() {
    _track('garden_onboarding_completed');
    setState(() => _onboarding = false);
    final stats = Get.isRegistered<StatsController>()
        ? Get.find<StatsController>().userStats.value
        : null;
    if (stats != null) {
      // Existing user: grow the tree from their REAL history (read-only).
      GardenBackfill.seed(c, stats);
    } else {
      // No data yet: show a realistic first 30 days.
      _sim.start(build30Days());
    }
  }

  void _replay() {
    _track('garden_replayed');
    _sim.stop();
    c.reset();
    setState(() => _onboarding = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // The navigable 3D tree — orbit / zoom built in.
          GardenTree3D(c: c),
          GardenHud(
            c: c,
            onJournal: () {
              _track('garden_journal_opened');
              showGardenJournal(context, c);
            },
            onReplay: _replay,
          ),
          GardenToast(c: c),
          // Judah — humble companion. Hidden during the onboarding cinematic.
          Obx(() => c.introActive.value
              ? const SizedBox.shrink()
              : JudahCompanion(c: c)),
          GardenRecapModal(c: c),
          if (_onboarding) GardenOnboarding(c: c, onDone: _onboardingDone),
        ],
      ),
    );
  }
}
