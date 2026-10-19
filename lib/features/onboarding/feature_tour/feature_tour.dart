import 'dart:math' as math;

import 'package:faithlock/features/faithlock/screens/cozy_streak_intro_screen.dart';
import 'package:faithlock/features/faithlock/services/stats_service.dart';
import 'package:faithlock/features/garden/controllers/garden_controller.dart';
import 'package:faithlock/features/garden/widgets/toby_mascot.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';

import 'feature_tour_controller.dart';
import 'tour_keys.dart';
import 'tour_step.dart';

export 'feature_tour_controller.dart';
export 'simple_spotlight.dart';
export 'spotlight_overlay.dart';
export 'tour_keys.dart';
export 'tour_step.dart';

/// The first-day tour, in two acts.
///
/// **Act 1 — do the thing, then feel the payoff.** We hand the newcomer straight
/// to prayer: spotlight the pray button, let them tap through, choose a real
/// prayer, and we wait for them to finish. Actually praying is the first "wow".
/// The instant they return home we cash it in: the garden visibly sprouts from
/// the prayer they just completed ("the more you pray, the more it grows"), and
/// then their streak ignites — reward before explanation.
///
/// **Act 2 — now here's the rest.** With the payoff felt, we explain the
/// supporting cast: locking distracting apps (sealed until you pray, just like
/// you just did), the Bible, and the companion. The "chosen for you" beat lives
/// in-context on the curated prayer pick during Act 1, so it isn't repeated here.
List<TourStep> buildFirstDayTour() => [
      // 0 · Warm, very short welcome (centered, no spotlight).
      const TourStep(
        id: 'welcome',
        titleKey: 'tour_welcome_title',
        bodyKey: 'tour_welcome_body',
        icon: HugeIcons.strokeRoundedSparkles,
        anchor: TourCardAnchor.center,
      ),

      // 1 · ACT 1 — pray for real. Interactive: tap through, choose a prayer,
      // finish. The tour waits and resumes when you return home.
      TourStep(
        id: 'pray',
        titleKey: 'tour_pray_title',
        bodyKey: 'tour_pray_body',
        hintKey: 'tour_pray_hint',
        icon: HugeIcons.strokeRoundedHandPrayer,
        targetKey: TourKeys.prayButton,
        navIndex: 0, // Today tab
        interactive: true,
        cutoutRadius: 26,
        anchor: TourCardAnchor.above,
      ),

      // 2 · The payoff, the instant they're back home: the prayer they just
      // finished makes the garden grow — live, on screen. Plants the core loop
      // ("the more you pray, the more it grows") before any explanation. Growth
      // is nudged on reveal so the hero visibly sprouts while they read.
      TourStep(
        id: 'garden',
        titleKey: 'tour_garden_title',
        bodyKey: 'tour_garden_body',
        icon: HugeIcons.strokeRoundedPlant02,
        targetKey: TourKeys.garden,
        navIndex: 0,
        cutoutRadius: 40,
        onReveal: () async {
          if (Get.isRegistered<GardenController>()) {
            await Get.find<GardenController>().nurture();
          }
        },
        spotlightBuilder: _gardenToby,
        cutoutTransform: _gardenCutout,
      ),

      // 3 · …and the second half of the reward: their streak ignites. The same
      // full-screen celebration the home screen plays on later launches, pushed
      // on reveal (it covers the would-be card). The tour auto-advances once the
      // celebration finishes and pops.
      TourStep(
        id: 'streak',
        titleKey: 'tour_streak_title',
        bodyKey: 'tour_streak_body',
        icon: HugeIcons.strokeRoundedFire,
        navIndex: 0,
        anchor: TourCardAnchor.center,
        onReveal: () async {
          await _celebrateStreakForTour();
          // Move on once the celebration is done — guarded so a skip mid-streak
          // (or a failed push) can't double-advance or strand the tour.
          if (Get.isRegistered<FeatureTourController>()) {
            final c = Get.find<FeatureTourController>();
            if (c.active.value && c.current.id == 'streak') c.next();
          }
        },
      ),

      // 4 · ACT 2 — lock the apps that pull you away. Sealed until you pray,
      // exactly like the moment they just lived. Lives on the Profile tab.
      TourStep(
        id: 'lock_apps',
        titleKey: 'tour_lock_title',
        bodyKey: 'tour_lock_body',
        icon: HugeIcons.strokeRoundedSquareLock02,
        targetKey: TourKeys.lockApps,
        navIndex: 3, // Profile tab
        interactive: true,
        cutoutRadius: 22,
      ),

      // 5 · Scripture is always one tap away.
      TourStep(
        id: 'bible',
        titleKey: 'tour_bible_title',
        bodyKey: 'tour_bible_body',
        icon: HugeIcons.strokeRoundedBookOpen01,
        targetKey: TourKeys.bibleTab,
        navIndex: 0,
        cutoutRadius: 18,
        anchor: TourCardAnchor.above,
      ),

      // 6 · You're never alone — chat with the Bible companion.
      TourStep(
        id: 'companion',
        titleKey: 'tour_companion_title',
        bodyKey: 'tour_companion_body',
        icon: HugeIcons.strokeRoundedBubbleChatSpark,
        targetKey: TourKeys.companionFab,
        navIndex: 0,
        cutoutRadius: 20,
        cutoutPadding: 10,
        shape: TourCutoutShape.circle,
        anchor: TourCardAnchor.above,
      ),

      // 7 · Send-off (centered, celebrated with confetti by the host).
      const TourStep(
        id: 'finish',
        titleKey: 'tour_finish_title',
        bodyKey: 'tour_finish_body',
        icon: HugeIcons.strokeRoundedCheckmarkBadge01,
        anchor: TourCardAnchor.center,
      ),
    ];

/// Toby's on-screen rect for the `garden` step, derived purely from the pot's
/// measured [treeRect]. Single source of truth shared by the mascot painter
/// ([_gardenToby]) and the cutout grower ([_gardenCutout]) so the lit hole and
/// the drawn lion always agree. Toby sits to the *right* of the pot (his can and
/// spout are on the art's lower left, so he pours leftward into the soil),
/// overlapping the pot's right edge just enough for the water to reach it
/// without burying the sprout.
Rect _gardenTobyRect(BuildContext context, Rect treeRect) {
  final media = MediaQuery.of(context);
  // ~half the pot reads clearly without hiding the plant.
  final w = (treeRect.width * 0.5).clamp(96.0, 180.0).toDouble();
  // Overlap ~40% of Toby onto the pot's right edge so his spout reaches in.
  final left = (treeRect.right - w * 0.4)
      .clamp(8.0, media.size.width - w - 8.0)
      .toDouble();
  // Raise Toby so he stands taller beside the pot (spout still reaches the soil).
  final top = (treeRect.center.dy - w * 0.72)
      .clamp(media.padding.top + 8.0, media.size.height - w - 8.0)
      .toDouble();
  return Rect.fromLTWH(left, top, w, w);
}

/// Draws Toby (watering) anchored to the pot for the `garden` step, wrapped in
/// [IgnorePointer] so he never eats taps or the tour card.
Widget _gardenToby(BuildContext context, Rect treeRect) {
  final r = _gardenTobyRect(context, treeRect);
  return Positioned(
    left: r.left,
    top: r.top,
    child: IgnorePointer(
      child: TobyMascot(mood: TobyMood.watering, size: r.width),
    ),
  );
}

/// Minimum symmetric breathing room between the garden cutout and the screen
/// edges, so the lit hole never sits flush against either side.
const double _gardenSideMargin = 16;

/// Grows the `garden` cutout from the bare pot to the union of the pot + Toby,
/// so both the plant and the lion sit inside the lit area (Toby is drawn only in
/// the tour overlay, never on the home, so the hole must be widened to reach
/// him). Then balances the horizontal margins: Toby pushes the right edge in,
/// leaving the pot flush against the left screen edge, so we inset both sides to
/// the larger gap (never below [_gardenSideMargin]) → the gap on the left equals
/// the gap on the right and neither touches the edge.
Rect _gardenCutout(BuildContext context, Rect treeRect) {
  final media = MediaQuery.of(context);
  final cutout = treeRect.expandToInclude(_gardenTobyRect(context, treeRect));
  final leftGap = cutout.left;
  final rightGap = media.size.width - cutout.right;
  final gap = math.max(_gardenSideMargin, math.max(leftGap, rightGap));
  final right = media.size.width - gap;
  // Guard against an inverted rect on very narrow screens.
  if (right <= gap) return cutout;
  return Rect.fromLTRB(gap, cutout.top, right, cutout.bottom);
}

/// Plays the streak celebration as the first-day tour's reward beat — right
/// after the user watches their tree take its first growth. It's the same
/// full-screen intro the home screen shows on later launches; failures are
/// swallowed so the tour never stalls on eye candy.
Future<void> _celebrateStreakForTour() async {
  final ctx = Get.context;
  if (ctx == null) return;
  // First day: they just prayed, so it's a one-day streak. Use the real value
  // whenever stats already report one.
  int streak = 1;
  try {
    final stats = await StatsService().getUserStats();
    if (stats.currentStreak > 0) streak = stats.currentStreak;
  } catch (_) {
    // ignore — fall back to a 1-day streak.
  }
  if (!ctx.mounted) return;
  await Navigator.of(ctx).push<void>(
    PageRouteBuilder<void>(
      opaque: true,
      pageBuilder: (_, __, ___) => CozyStreakIntroScreen(streak: streak),
      transitionDuration: Duration.zero,
      reverseTransitionDuration: const Duration(milliseconds: 220),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
    ),
  );
}
