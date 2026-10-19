import 'dart:async';

import 'package:faithlock/shared/widgets/cozy/cozy.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:faithlock/services/analytics/posthog/export.dart';

/// Daily streak intro — plays once per day on first app open.
///
/// Animation timeline (≈3.4s total):
/// 1. Card slides up + fades in (yesterday's date visible).
/// 2. Date flips from yesterday → today.
/// 3. Flame ignites: scale + color transition from muted to terracotta.
/// 4. Streak number scales in, hold beat.
/// 5. Card slides UP off-screen; route pops, home is revealed.
///
/// Both this screen and [CozyHomeScreen] share [CozyColors.background], so
/// the route pop is visually seamless — no jarring color flash.
class CozyStreakIntroScreen extends StatefulWidget {
  final int streak;

  const CozyStreakIntroScreen({super.key, required this.streak});

  @override
  State<CozyStreakIntroScreen> createState() => _CozyStreakIntroScreenState();
}

class _CozyStreakIntroScreenState extends State<CozyStreakIntroScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entry;
  late final AnimationController _flame;
  late final AnimationController _exit;

  /// Continuous burn loop (scale pulse + slight tilt + color shimmer) so the
  /// flame stays alive once it's ignited. Reversing animation between
  /// 0 → 1 → 0 → 1… on a ~1.4s cycle gives a calm breathing rhythm.
  late final AnimationController _burn;

  /// false → render yesterday's date · true → today's date
  bool _showToday = false;

  /// Tap anywhere on the screen marks dismissed; the timeline shortcuts to
  /// the exit phase at the next await point.
  bool _dismissed = false;
  final Completer<void> _dismissCompleter = Completer<void>();

  final PostHogService _analytics = PostHogService.instance;

  @override
  void initState() {
    super.initState();
    if (_analytics.isReady) {
      _analytics.events.trackCustom('streak_intro_viewed', {
        'streak': widget.streak,
      });
    }
    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _flame = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _exit = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _burn = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _runTimeline();
  }

  Future<void> _runTimeline() async {
    // 1 — Card entry
    await _entry.forward();
    if (!mounted || _dismissed) return _runExit();
    HapticFeedback.lightImpact();

    await _wait(400);
    if (!mounted || _dismissed) return _runExit();

    // 2 — Date flip (AnimatedSwitcher handles the transition)
    setState(() => _showToday = true);
    await _wait(560);
    if (!mounted || _dismissed) return _runExit();
    HapticFeedback.lightImpact();

    await _wait(220);
    if (!mounted || _dismissed) return _runExit();

    // 3 — Flame ignites + streak number scales in
    await _flame.forward();
    if (!mounted || _dismissed) return _runExit();
    HapticFeedback.mediumImpact();
    // Kick off the continuous burn loop so the flame stays alive after the
    // ignite, not frozen on a single frame.
    _burn.repeat(reverse: true);

    // 4 — Hold the celebration — long enough to actually read the result.
    // Tap anywhere on the card to short-circuit and dismiss early.
    await _wait(2400);
    if (!mounted) return;

    // 5 — Card slides up off-screen, then pop
    await _runExit();
  }

  Future<void> _runExit() async {
    if (!mounted) return;
    if (!_exit.isAnimating && _exit.value == 0) {
      await _exit.forward();
    }
    if (!mounted) return;
    Navigator.of(context).maybePop();
  }

  /// Returns early if the user has tapped to dismiss — keeps the timeline
  /// responsive instead of forcing them to wait out a long beat.
  Future<void> _wait(int millis) {
    return Future.any<void>([
      Future<void>.delayed(Duration(milliseconds: millis)),
      _dismissCompleter.future,
    ]);
  }

  void _onTapDismiss() {
    if (_dismissed) return;
    _dismissed = true;
    if (!_dismissCompleter.isCompleted) _dismissCompleter.complete();
  }

  @override
  void dispose() {
    _entry.dispose();
    _flame.dispose();
    _exit.dispose();
    _burn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CozyColors.background,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _onTapDismiss,
        child: SafeArea(
        child: Center(
          child: AnimatedBuilder(
            animation: Listenable.merge([_entry, _exit]),
            builder: (context, child) {
              // Entry: slides up FROM below (+40 → 0).
              final entryY = (1.0 - _entry.value) * 40;
              // Exit: slides UP OUT of view (0 → -screen height roughly).
              final exitY =
                  -_exit.value * MediaQuery.of(context).size.height * 0.75;
              final opacity = _entry.value * (1.0 - _exit.value);
              return Transform.translate(
                offset: Offset(0, entryY + exitY),
                child: Opacity(opacity: opacity, child: child),
              );
            },
            child: _buildCard(),
          ),
        ),
        ),
      ),
    );
  }

  // ── Card ────────────────────────────────────────────────────────────────

  Widget _buildCard() {
    return Container(
      width: 320,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
      decoration: ShapeDecoration(
        color: CozyColors.surface,
        shape: CozyTokens.smooth(
          CozyTokens.radiusLg,
          side: const BorderSide(
            color: CozyColors.outline,
            width: CozyTokens.borderWidth,
          ),
        ),
        shadows: CozyTokens.shadowHard,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _dateRow(),
          const SizedBox(height: 24),
          _flameWithHalo(),
          const SizedBox(height: 12),
          _heroNumber(),
          const SizedBox(height: 2),
          _dayStreakCaption(),
          const SizedBox(height: 24),
          _streakStrip(),
        ],
      ),
    );
  }

  /// Flame with a soft radial halo behind it — gives the icon visual weight
  /// without resorting to particles or sparkles (anti-cozy).
  ///
  /// Two animations are layered:
  /// - The ignite ([_flame], 0→1, one-shot): scale + color transition from
  ///   muted → terracotta as the timeline runs.
  /// - The burn ([_burn], 0↔1, reversing forever): a calm breathing pulse —
  ///   subtle scale + tilt + color shimmer + halo bloom — so the flame
  ///   actually looks like it's burning instead of frozen on a single frame.
  Widget _flameWithHalo() {
    return AnimatedBuilder(
      animation: Listenable.merge([_flame, _burn]),
      builder: (context, _) {
        final t = _flame.value;
        // Ignite scale: 0 → 1.2 (overshoot) → 1.0
        final igniteScale = t < 0.6
            ? Curves.easeOutBack.transform(t / 0.6) * 1.2
            : 1.2 - ((t - 0.6) / 0.4) * 0.2;
        // Burn pulse — a soft sine-like in-out via the reversing controller.
        final burn = Curves.easeInOut.transform(_burn.value);
        // Once the ignite has settled, the burn breathes ±4 % scale and
        // ±1.4° tilt, with a tiny vertical flicker.
        final ignited = t > 0.65 ? 1.0 : 0.0;
        final burnScale = 1.0 + ignited * (burn - 0.5) * 0.08;
        final burnTilt = ignited * (burn - 0.5) * 0.05; // ≈±1.4°
        final burnY = ignited * (burn - 0.5) * 4.0; // ±2 px flicker
        final flameScale = igniteScale.clamp(0.0, 1.25) * burnScale;

        // Color shimmer between primary and a warmer ember tone.
        final ignitedColor = Color.lerp(
          CozyColors.inkMuted.withValues(alpha: 0.25),
          CozyColors.primary,
          Curves.easeOut.transform(t),
        )!;
        const ember = Color(0xFFF0A35E); // warm orange ember
        final flameColor =
            Color.lerp(ignitedColor, ember, ignited * burn * 0.45)!;

        // Halo bloom: scales with the ignite progress, then breathes with
        // the burn cycle (intensity ±15 %).
        final haloScale =
            Curves.easeOutCubic.transform((t - 0.05).clamp(0.0, 1.0)) *
                (1.0 + ignited * (burn - 0.5) * 0.15);
        final haloOpacity = 1.0 + ignited * (burn - 0.5) * 0.4;

        return SizedBox(
          width: 180,
          height: 140,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Halo — soft warm radial behind the flame
              Transform.scale(
                scale: haloScale,
                child: Opacity(
                  opacity: haloOpacity.clamp(0.6, 1.0),
                  child: Container(
                    width: 160,
                    height: 130,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          CozyColors.primary.withValues(alpha: 0.28),
                          CozyColors.primary.withValues(alpha: 0.08),
                          CozyColors.primary.withValues(alpha: 0),
                        ],
                        stops: const [0.0, 0.55, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
              // Flame icon on top — breathing pulse + tiny tilt + flicker
              Transform.translate(
                offset: Offset(0, burnY),
                child: Transform.rotate(
                  angle: burnTilt,
                  child: Transform.scale(
                    scale: flameScale,
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedFire,
                      size: 110,
                      color: flameColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Massive streak number — the visual hero. Counts up from 0 → streak as
  /// the flame ignites.
  Widget _heroNumber() {
    return AnimatedBuilder(
      animation: _flame,
      builder: (context, _) {
        final t = Curves.easeOut.transform(_flame.value);
        final displayed = (t * widget.streak).round();
        return Opacity(
          opacity: t,
          child: Text(
            '$displayed',
            style: CozyText.display.copyWith(
              fontSize: 132,
              height: 0.95,
              fontWeight: FontWeight.w800,
              letterSpacing: -2,
            ),
          ),
        );
      },
    );
  }

  Widget _dayStreakCaption() {
    return AnimatedBuilder(
      animation: _flame,
      builder: (context, _) {
        // Fade in slightly after the number
        final t = ((_flame.value - 0.3) / 0.7).clamp(0.0, 1.0);
        return Opacity(
          opacity: t,
          child: Text(
            'streak_dayStreak'.tr,
            style: CozyText.label.copyWith(
              fontSize: 13,
              letterSpacing: 2.2,
              fontWeight: FontWeight.w800,
              color: CozyColors.inkMuted,
            ),
          ),
        );
      },
    );
  }

  /// Streak strip — a row of small rounded rectangles, one per day toward
  /// the next milestone. Achieved days are filled terracotta with a tiny
  /// flame inside; remaining days are empty outline boxes.
  ///
  /// "Tous les streaks" résumés visuellement — like little burning candles
  /// lined up to show how the streak is built and what's left to the
  /// milestone, all in one glance, no extra copy.
  Widget _streakStrip() {
    final goal = _nextMilestone(widget.streak);

    return AnimatedBuilder(
      animation: _flame,
      builder: (context, _) {
        // Reveal starts at 60% of the flame animation
        final reveal = ((_flame.value - 0.6) / 0.4).clamp(0.0, 1.0);
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(goal, (i) {
            final filled = i < widget.streak;
            // Each box pops in sequentially.
            final t = ((reveal * goal) - i).clamp(0.0, 1.0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.5),
              child: Transform.scale(
                scale: t,
                child: _streakBox(filled: filled),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _streakBox({required bool filled}) {
    return Container(
      width: 14,
      height: 24,
      alignment: Alignment.center,
      decoration: ShapeDecoration(
        color: filled ? CozyColors.primary : CozyColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
          side: BorderSide(
            color: filled
                ? CozyColors.outline
                : CozyColors.inkMuted.withValues(alpha: 0.3),
            width: filled ? 1.6 : 1.2,
          ),
        ),
      ),
      child: filled
          ? const Text(
              '🔥',
              style: TextStyle(fontSize: 9, height: 1),
            )
          : null,
    );
  }

  int _nextMilestone(int streak) {
    const milestones = [7, 14, 30, 60, 100, 200, 365];
    for (final m in milestones) {
      if (streak < m) return m;
    }
    return ((streak ~/ 100) + 1) * 100;
  }

  Widget _dateRow() {
    final now = DateTime.now();
    final shown =
        _showToday ? now : now.subtract(const Duration(days: 1));
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 480),
      transitionBuilder: (child, anim) {
        // Incoming slides DOWN into view; outgoing slides up out.
        final slideIn = Tween<Offset>(
          begin: const Offset(0, 0.6),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
        return ClipRect(
          child: SlideTransition(
            position: slideIn,
            child: FadeTransition(opacity: anim, child: child),
          ),
        );
      },
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.center,
          children: [
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        );
      },
      child: Text(
        _formatDate(shown),
        key: ValueKey(_showToday),
        style: CozyText.label.copyWith(
          fontSize: 13,
          letterSpacing: 1.4,
          color: CozyColors.inkMuted,
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    final months = 'streak_months'.tr.split(',');
    return '${months[d.month - 1]} ${d.day.toString().padLeft(2, '0')}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Persistence helper — only show the intro once per calendar day.
// ─────────────────────────────────────────────────────────────────────────────

class StreakIntroService {
  StreakIntroService._();

  static const String _prefsKey = 'last_streak_intro_shown_date';

  /// True when the intro hasn't been shown today AND the user has an active
  /// streak worth celebrating. Guards against showing on day 0 / reset.
  static Future<bool> shouldShow(int currentStreak) async {
    if (currentStreak < 1) return false;
    final prefs = await SharedPreferences.getInstance();
    final lastShown = prefs.getString(_prefsKey);
    return lastShown != _todayKey();
  }

  /// Record that the intro played today so it won't repeat until tomorrow.
  static Future<void> markShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, _todayKey());
  }

  static String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }
}
