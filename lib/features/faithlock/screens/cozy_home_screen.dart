import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:faithlock/core/navigation/app_route_observer.dart';
import 'package:faithlock/features/faithlock/controllers/stats_controller.dart';
import 'package:faithlock/features/faithlock/models/user_stats_model.dart';
import 'package:faithlock/features/faithlock/screens/cozy_prayer_selector.dart';
import 'package:faithlock/features/garden/controllers/garden_controller.dart';
import 'package:faithlock/features/paywall/widgets/promo_gift_card.dart';
import 'package:faithlock/features/garden/screens/garden_pot_fullscreen_screen.dart';
import 'package:faithlock/features/garden/widgets/realistic_tree_pot.dart';
import 'package:faithlock/features/onboarding/feature_tour/tour_keys.dart';
import 'package:faithlock/shared/widgets/cozy/cozy.dart';

/// Cozy "Today" home screen — chunky, warm rebuild of the stats dashboard.
/// Wired to the existing [StatsController]; illustration is a placeholder
/// emoji until the hand-drawn asset is added. Hosted inside the navigation
/// shell, which provides the bottom nav.
class CozyHomeScreen extends StatefulWidget {
  const CozyHomeScreen({super.key});

  @override
  State<CozyHomeScreen> createState() => _CozyHomeScreenState();
}

class _CozyHomeScreenState extends State<CozyHomeScreen> with RouteAware {
  late final StatsController controller;
  late final GardenController garden;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<StatsController>()
        ? Get.find<StatsController>()
        : Get.put(StatsController());
    garden = Get.isRegistered<GardenController>()
        ? Get.find<GardenController>()
        : Get.put(GardenController());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) appRouteObserver.subscribe(this, route);
  }

  /// Revealed again after a pushed route (prayer, feature tour, …) popped —
  /// pull fresh stats so "prayed today" / "verses read" reflect what just
  /// happened. The Obx in [build] reacts to the refreshed observables.
  @override
  void didPopNext() {
    controller.loadStats();
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CozyColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Streak+pot anchored to the top, stats anchored to the bottom; the
            // free space breathes in the garden area between them.
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Obx(() {
                  final stats = controller.userStats.value;
                  final timeSaved = stats?.prayedTodayFormatted ?? '0 min';
                  final versesRead = '${stats?.versesReadToday ?? 0}';
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _streakCard(stats),
                      const SizedBox(height: 20),
                      _statRow(timeSaved, versesRead),
                      // Welcome offer. Collapses to zero height for subscribers
                      // and for anyone who already used their one reservation,
                      // so the garden keeps its space in the common case.
                      const PromoGiftCard(),
                      // The garden hero fills the remaining space below the stats
                      // so there's no dead gap; the plant grows upward.
                      Expanded(child: _gardenHero()),
                    ],
                  );
                }),
              ),
            ),
            // "Let's Pray Now" pinned to the bottom (footer) — consistent margin.
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 22),
              child: CozyButton(
                key: TourKeys.prayButton,
                text: 'home_letsPrayNow'.tr,
                height: 64,
                borderRadius: 26,
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedHandPrayer,
                  color: CozyColors.onPrimary,
                  size: 22,
                ),
                onTap: () => startCozyPrayerFlow(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The streak counter card only: flame + "X day streak" + the 7 days of the
  /// week. (The pot is rendered separately, over this card — see [_streakAndPot].)
  Widget _streakCard(UserStats? stats) {
    final streak = stats?.currentStreak ?? 0;
    final best = stats?.longestStreak ?? 0;
    final lastUnlock = stats?.lastUnlockDate;
    final hasToday = stats?.hasStreakToday ?? false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));

    DateTime? streakStart;
    DateTime? streakEnd;
    if (lastUnlock != null && streak > 0) {
      streakEnd = DateTime(lastUnlock.year, lastUnlock.month, lastUnlock.day);
      streakStart = streakEnd.subtract(Duration(days: streak - 1));
    }

    bool isActive(DateTime day) {
      if (streakStart == null || streakEnd == null) return false;
      if (day.isAfter(today)) return false;
      return !day.isBefore(streakStart) && !day.isAfter(streakEnd);
    }

    final labels = 'home_weekdayInitials'.tr.split(',');

    return CozyCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: ShapeDecoration(
                  color: CozyColors.peach,
                  shape: CozyTokens.smooth(
                    CozyTokens.radiusMd,
                    side: const BorderSide(
                      color: CozyColors.outline,
                      width: CozyTokens.borderWidth,
                    ),
                  ),
                ),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedFire,
                  color: streak > 0 ? CozyColors.primary : CozyColors.inkMuted,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'home_dayStreak'.trParams({'count': '$streak'}),
                      style: CozyText.heading.copyWith(fontSize: 17),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'home_personalBest'.trParams({'best': '$best'}),
                      style: CozyText.label.copyWith(fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (streak > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: ShapeDecoration(
                    color: CozyColors.primary,
                    shape: CozyTokens.smooth(
                      CozyTokens.radiusPill,
                      side: const BorderSide(
                        color: CozyColors.outline,
                        width: CozyTokens.borderWidthThin,
                      ),
                    ),
                  ),
                  child: Text(
                    _streakLabel(streak, best),
                    style: CozyText.label.copyWith(
                      color: CozyColors.onPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final day = monday.add(Duration(days: i));
              final isToday = day.year == today.year &&
                  day.month == today.month &&
                  day.day == today.day;
              final active = isToday ? hasToday : isActive(day);
              return _DayChip(
                label: labels[i],
                active: active,
                isToday: isToday,
              );
            }),
          ),
        ],
      ),
    );
  }

  /// The garden scene as the home hero — just the pot/tree, CENTRED (Toby only
  /// appears during the onboarding spotlight, not here). Hero-morphs to the
  /// fullscreen view on tap; the tour key wraps it for the spotlight.
  Widget _gardenHero() {
    return KeyedSubtree(
      key: TourKeys.garden,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Get.to(
          () => const GardenPotFullscreenScreen(),
          transition: Transition.fadeIn,
          duration: CozyTokens.base,
        ),
        child: Obx(
          () => Hero(
            tag: kGardenPotHeroTag,
            child: FittedBox(
              fit: BoxFit.contain,
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                width: 300,
                height: 300 / RealisticTreePot.aspectRatio,
                child: RealisticTreePot(
                  progress: garden.progress.value,
                  health: garden.health.value,
                  embedded: true,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Short pill label tuned to streak length. Hidden when streak == 0.
  String _streakLabel(int streak, int best) {
    if (best > 0 && streak >= best) return 'home_streakBest'.tr;
    if (streak >= 14) return 'home_streakEpic'.tr;
    if (streak >= 7) return 'home_streakAwesome'.tr;
    if (streak >= 3) return 'home_streakGreat'.tr;
    return 'home_streakNice'.tr;
  }

  Widget _statRow(String timeSaved, String versesRead) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: CozyStatCard(
            iconChild: const HugeIcon(
              icon: HugeIcons.strokeRoundedHandPrayer,
              color: CozyColors.ink,
              size: 22,
            ),
            iconBackground: CozyColors.peach,
            iconCircle: false,
            iconBordered: true,
            value: timeSaved,
            label: 'home_prayedToday'.tr,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: CozyStatCard(
            icon: HugeIcons.strokeRoundedBookOpen01,
            iconColor: CozyColors.ink,
            iconBackground: CozyColors.sage,
            iconCircle: false,
            iconBordered: true,
            value: versesRead,
            label: 'home_versesRead'.tr,
          ),
        ),
      ],
    );
  }
}

/// Single day cell in the streak strip — small chunky chip with a flame and
/// the day letter below. Today's chip carries a thicker terracotta outline so
/// you can always tell where "now" sits on the row.
class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.label,
    required this.active,
    required this.isToday,
  });

  final String label;
  final bool active;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = isToday ? CozyColors.primary : CozyColors.outline;
    final double borderWidth =
        isToday ? CozyTokens.borderWidth : CozyTokens.borderWidthThin;
    final Color fill = active ? CozyColors.peach : CozyColors.surfaceMuted;
    final Color flameColor = active
        ? CozyColors.primary
        : CozyColors.inkMuted.withValues(alpha: 0.6);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 36,
          alignment: Alignment.center,
          decoration: ShapeDecoration(
            color: fill,
            shape: CozyTokens.smooth(
              10,
              side: BorderSide(color: borderColor, width: borderWidth),
            ),
          ),
          child: HugeIcon(
            icon: HugeIcons.strokeRoundedFire,
            color: flameColor,
            size: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: CozyText.label.copyWith(
            fontSize: 11,
            color: isToday ? CozyColors.primary : CozyColors.inkMuted,
            fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
