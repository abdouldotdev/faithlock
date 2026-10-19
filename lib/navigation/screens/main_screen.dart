import 'dart:async';

import 'package:confetti/confetti.dart';
import 'package:faithlock/features/companion/screens/companion_chat_screen.dart';
import 'package:faithlock/features/faithlock/screens/cozy_prayer_selector.dart';
import 'package:faithlock/features/faithlock/screens/cozy_streak_intro_screen.dart';
import 'package:faithlock/features/faithlock/services/stats_service.dart';
import 'package:faithlock/features/onboarding/controllers/scripture_onboarding_controller.dart';
import 'package:faithlock/features/onboarding/feature_tour/feature_tour.dart';
import 'package:faithlock/features/prayer_audio/data/prayer_repository.dart';
import 'package:faithlock/navigation/controllers/navigation_controller.dart';
import 'package:faithlock/services/rate_app_service.dart';
import 'package:faithlock/services/startup_check_service.dart';
import 'package:faithlock/services/subscription/paywall_guard_service.dart';
import 'package:faithlock/shared/widgets/cozy/cozy.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final NavigationController controller = Get.put(NavigationController());

  /// First-day coach-mark tour. Act 1: pray for real (interactive). Act 2:
  /// lock → bible → companion → garden grows.
  final FeatureTourController tour = Get.put(FeatureTourController());

  /// Fires the celebratory burst when the tour reaches its final step.
  final ConfettiController _confetti =
      ConfettiController(duration: const Duration(seconds: 1));

  /// Debug-only: counts taps on the replay FAB so successive previews show
  /// "1 Day", "2 Day", "3 Day"... — lets you eyeball how the card looks at
  /// different streak magnitudes without touching prefs or real stats.
  int _debugStreakCounter = 0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Check subscription first (paywall guard)
      final hasSubscription = await PaywallGuardService()
          .checkSubscriptionAccess(placementId: 'main_screen_guard');

      if (!hasSubscription) {
        return;
      }

      // Mark that user has accessed app features (with active subscription)
      final onboardingController = Get.find<ScriptureOnboardingController>();
      final hasAccessedBefore =
          await onboardingController.hasAccessedFeatures();

      if (!hasAccessedBefore) {
        await onboardingController.markFeaturesAccessed();
        debugPrint('🎉 [MainScreen] First time accessing features - marked!');
      }

      // Perform startup checks only if subscribed
      StartupCheckService().performStartupChecks(context);

      // ── Daily streak intro ────────────────────────────────────────────
      // Plays once per calendar day, AFTER subscription + startup checks
      // pass. The card animates in, the date flips from yesterday to today,
      // the flame ignites, then the card slides up to reveal the home that
      // has already been painted underneath this overlay route.
      await _maybeShowStreakIntro();

      // ── First-day feature tour ─────────────────────────────────────────
      // Once, right after the streak intro clears, walk the newcomer through
      // the day-one essentials. Skipped on every later launch.
      await _maybeStartFeatureTour();

      // ── Check for pending rating prompt ──────────────────────────────────
      // Show native rating prompt if scheduled from previous session
      // (when user had < 3 prayers and hasn't rated yet)
      await _maybeShowPendingRatingPrompt();
    });

    // Pop confetti and show native rating prompt after tour completion.
    tour.celebrate.listen((on) {
      if (on && mounted) {
        _confetti.play();
        // Show native in-app review prompt after onboarding tour completes
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (mounted) {
            await RateAppService().showNativeRatingPrompt();
          }
        });
      }
    });
  }

  Future<void> _maybeStartFeatureTour() async {
    if (!mounted) return;
    try {
      if (await tour.hasSeenTour()) return;
      if (!mounted) return;
      // Warm the prayer cache now so the interactive "pray" step's selector →
      // reading transition is instant — that keeps the flow-return detection
      // from mistaking a slow network fetch for "the user finished praying".
      unawaited(PrayerRepository().fetchPrayers());
      // Begin on the Today tab so the opening steps measure cleanly.
      controller.changePage(0);
      tour.begin(buildFirstDayTour());
    } catch (e) {
      debugPrint('⚠️ [FeatureTour] skipped: $e');
    }
  }

  Future<void> _maybeShowPendingRatingPrompt() async {
    if (!mounted) return;
    try {
      final rateAppService = RateAppService();
      if (await rateAppService.hasPendingRatingPrompt()) {
        await rateAppService.showNativeRatingPrompt(source: 'app_launch');
      }
    } catch (e) {
      debugPrint('⚠️ [RatingPrompt] Error checking pending: $e');
    }
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  Future<void> _maybeShowStreakIntro({bool force = false}) async {
    if (!mounted) return;
    // Let home paint a frame first so the route reveal underneath is ready.
    await Future.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;

    try {
      final stats = await StatsService().getUserStats();
      final streak = stats.currentStreak;
      final shouldShow = await StreakIntroService.shouldShow(streak);
      debugPrint(
          '🔥 [StreakIntro] streak=$streak shouldShow=$shouldShow force=$force');

      if (!force && !shouldShow) return;
      if (!mounted) return;

      // In force mode each tap bumps the displayed streak so we can preview
      // 1 Day → 2 Day → … without re-running the app. Real streak is shown
      // verbatim when ≥ 1, otherwise the debug counter takes over.
      final int displayStreak;
      if (force) {
        _debugStreakCounter += 1;
        displayStreak = _debugStreakCounter;
      } else {
        displayStreak = streak > 0 ? streak : 1;
      }

      await Navigator.of(context).push<void>(
        PageRouteBuilder<void>(
          opaque: true,
          pageBuilder: (_, __, ___) =>
              CozyStreakIntroScreen(streak: displayStreak),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: const Duration(milliseconds: 220),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      );
      await StreakIntroService.markShown();
    } catch (e, stack) {
      // Non-critical eye candy — never let it block the home from showing.
      debugPrint('⚠️ [StreakIntro] skipped: $e');
      debugPrintStack(stackTrace: stack);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildShell(context),
        // Coach-mark spotlight — sits above the whole shell so it can dim the
        // nav bar + FAB and read any tab's geometry. Positioned.fill forces it
        // to cover the screen (a Stack of only Positioned children is sizeless).
        Positioned.fill(child: SpotlightOverlay(controller: tour)),
        // Celebratory burst for the tour's final step.
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confetti,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            numberOfParticles: 24,
            maxBlastForce: 18,
            minBlastForce: 8,
            gravity: 0.25,
            colors: const [
              CozyColors.primary,
              CozyColors.gold,
              CozyColors.sage,
              CozyColors.peach,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShell(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        controller.onWillPop();
      },
      child: Obx(
        () => Scaffold(
          backgroundColor: CozyColors.background,
          // Floating "Companion" entry — the sparkle-bible button that opens the
          // AI Bible companion. Shown ONLY on the Today tab (index 0); hidden on
          // Bible/Pray/Profile so it doesn't hover over unrelated screens. Its
          // step in the first-day tour runs on tab 0, so gating here is safe.
          // Lifted above the "Let's Pray Now" footer button (see location) and
          // gently animated so it feels alive and invites a tap.
          floatingActionButton: controller.currentIndex == 0
              ? _CompanionFab(
                  onPressed: () => Get.to(() => const CompanionChatScreen()),
                  // In debug, long-press replays the streak intro animation.
                  onLongPress: kDebugMode
                      ? () => _maybeShowStreakIntro(force: true)
                      : null,
                )
              : null,
          floatingActionButtonLocation: const _AboveFooterFabLocation(74),
          body: IndexedStack(
            index: controller.currentIndex,
            children:
                controller.navigationItems.map((item) => item.page).toList(),
          ),
          bottomNavigationBar: CozyBottomNav(
            currentIndex: controller.currentIndex,
            onTap: (index) {
              // "Pray" (index 2) is an action, not a page: always offer both
              // prayer modes instead of switching tabs.
              if (index == 2) {
                startCozyPrayerFlow(context);
              } else {
                controller.changePage(index);
              }
            },
            items: [
              CozyNavItem(
                label: 'nav_today'.tr,
                iconBuilder: (active, color, size) => CozyNavIcon(
                  icon: HugeIcons.strokeRoundedHome01,
                  color: color,
                  size: size,
                ),
              ),
              CozyNavItem(
                label: 'nav_bible'.tr,
                itemKey: TourKeys.bibleTab,
                iconBuilder: (active, color, size) => CozyNavIcon(
                  icon: HugeIcons.strokeRoundedBookOpen01,
                  color: color,
                  size: size,
                ),
              ),
              CozyNavItem(
                // "Pray" is an action (opens a modal), so it never becomes the
                // active tab — kept as the HugeIcons outline prayer glyph.
                label: 'nav_pray'.tr,
                iconBuilder: (active, color, size) => CozyNavIcon(
                  icon: HugeIcons.strokeRoundedHandPrayer,
                  color: color,
                  size: size,
                ),
              ),
              CozyNavItem(
                label: 'nav_profile'.tr,
                iconBuilder: (active, color, size) => CozyNavIcon(
                  icon: HugeIcons.strokeRoundedUserCircle,
                  color: color,
                  size: size,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The companion entry button — a slow "breathing" bob + gentle scale pulse so
/// it reads as alive and taps-worthy without being noisy. Keeps
/// [TourKeys.companionFab] so the first-day tour can still spotlight it.
class _CompanionFab extends StatefulWidget {
  const _CompanionFab({required this.onPressed, this.onLongPress});

  final VoidCallback onPressed;
  final VoidCallback? onLongPress;

  @override
  State<_CompanionFab> createState() => _CompanionFabState();
}

class _CompanionFabState extends State<_CompanionFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_c.value);
        return Transform.translate(
          offset: Offset(0, -4 * t),
          child: Transform.scale(scale: 1 + 0.05 * t, child: child),
        );
      },
      child: GestureDetector(
        onLongPress: widget.onLongPress,
        child: FloatingActionButton(
          key: TourKeys.companionFab,
          heroTag: 'companion-entry',
          backgroundColor: CozyColors.primary,
          shape: CozyTokens.smooth(
            18,
            side: const BorderSide(
              color: CozyColors.outline,
              width: CozyTokens.borderWidth,
            ),
          ),
          onPressed: widget.onPressed,
          child: const HugeIcon(
            icon: HugeIcons.strokeRoundedBubbleChatSpark,
            color: Colors.white,
            size: 26,
          ),
        ),
      ),
    );
  }
}

/// Lifts the FAB up from the default [endFloat] spot (which overlaps the
/// "Let's Pray Now" footer button) so it perches at the top-right of that
/// button instead. [lift] is the vertical rise in logical pixels.
class _AboveFooterFabLocation extends FloatingActionButtonLocation {
  const _AboveFooterFabLocation(this.lift);

  final double lift;

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry geometry) {
    final base = FloatingActionButtonLocation.endFloat.getOffset(geometry);
    return Offset(base.dx, base.dy - lift);
  }
}
