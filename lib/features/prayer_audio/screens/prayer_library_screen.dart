import 'package:faithlock/features/prayer_audio/constants/prayer_palette.dart';
import 'package:faithlock/features/prayer_audio/controllers/prayer_library_controller.dart';
import 'package:faithlock/features/prayer_audio/models/prayer.dart';
import 'package:faithlock/features/prayer_audio/screens/prayer_player_screen.dart';
import 'package:faithlock/features/faithlock/services/mood_prayer_match.dart';
import 'package:faithlock/features/faithlock/services/mood_service.dart';
import 'package:faithlock/features/onboarding/feature_tour/feature_tour.dart';
import 'package:faithlock/shared/widgets/cozy/cozy_mood_slider.dart';
import 'package:faithlock/services/analytics/posthog/export.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';

// ─── Constants ───────────────────────────────────────────────────────────────

const _cream = PrayerPalette.cream;
const _card = PrayerPalette.card;
const _ink = PrayerPalette.ink;
const _orange = PrayerPalette.orange;
const _peach = PrayerPalette.peach;
const _subtle = PrayerPalette.subtle;
const _font = PrayerPalette.font;

// ─── Prayer Library Screen ────────────────────────────────────────────────────

class PrayerLibraryScreen extends StatefulWidget {
  const PrayerLibraryScreen({super.key});

  @override
  State<PrayerLibraryScreen> createState() => _PrayerLibraryScreenState();
}

class _PrayerLibraryScreenState extends State<PrayerLibraryScreen> {
  late final PrayerLibraryController _controller;
  late final Worker _loadingWorker;

  final PostHogService _analytics = PostHogService.instance;

  void _track(String event, [Map<String, dynamic> props = const {}]) {
    if (_analytics.isReady) _analytics.events.trackCustom(event, props);
  }

  /// Last mood from the pre-prayer check-in — drives the "Curated for you" hero.
  MoodLevel? _mood;

  /// The mood-matched prayer, computed ONCE (random pick, anti-repeat) so it
  /// doesn't re-roll on every rebuild.
  Prayer? _curated;
  bool _curatedComputed = false;

  /// The curated hero starts hidden; it's revealed a beat AFTER the normal
  /// library is on screen so the reorganization reads as intentional.
  bool _curatedRevealed = false;
  bool _revealScheduled = false;

  /// Lets the user collapse the curated hero back to the plain library — a
  /// suggestion should never be a locked-in state.
  bool _curatedDismissed = false;

  /// Anchor for the first-day tour's spotlight on the curated hero.
  final GlobalKey _curatedKey = GlobalKey();

  /// Feature-tour controller, when the app is running the first-day tour.
  FeatureTourController? get _tour => Get.isRegistered<FeatureTourController>()
      ? Get.find<FeatureTourController>()
      : null;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(PrayerLibraryController());
    _track('prayer_library_viewed');
    _loadMood();
    // Reveal once the list has loaded — via the reactive flip, or immediately
    // if prayers were already cached when we mounted.
    _loadingWorker = ever<bool>(_controller.isLoading, (loading) {
      if (!loading) {
        _scheduleCuratedReveal();
        _maybeComputeCurated();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_controller.isLoading.value) {
        _scheduleCuratedReveal();
        _maybeComputeCurated();
      }
    });
  }

  Future<void> _loadMood() async {
    final mood = await MoodService().lastMood();
    if (!mounted) return;
    setState(() => _mood = mood);
    _maybeComputeCurated();
  }

  /// Computes the curated pick exactly once, when both the mood and the prayer
  /// list are ready — a random match for the mood, avoiding the previously
  /// suggested prayer, then persisted so the next visit differs too.
  Future<void> _maybeComputeCurated() async {
    if (_curatedComputed || !mounted) return;
    if (_mood == null || _controller.prayers.isEmpty) return;
    _curatedComputed = true;
    final lastId = await MoodService().lastCuratedId();
    if (!mounted) return;
    final pick = MoodPrayerMatch.recommend(
      _mood,
      _controller.prayers,
      excludeId: lastId,
    );
    if (pick != null) await MoodService().saveLastCuratedId(pick.id);
    if (!mounted) return;
    setState(() => _curated = pick);
  }

  void _scheduleCuratedReveal() {
    if (_revealScheduled || !mounted) return;
    _revealScheduled = true;
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      HapticFeedback.lightImpact();
      setState(() => _curatedRevealed = true);
    });
  }

  @override
  void dispose() {
    _loadingWorker.dispose();
    Get.delete<PrayerLibraryController>(force: false);
    super.dispose();
  }

  void _openPlayer(Prayer prayer, {bool heavy = false}) {
    _track('prayer_library_prayer_selected', {
      'prayer_id': prayer.id,
      'domain': prayer.domain.name,
      // "heavy" taps come from the featured/curated hero, light from the grid.
      'source': heavy ? 'featured' : 'list',
    });
    heavy ? HapticFeedback.mediumImpact() : HapticFeedback.lightImpact();
    Get.to(
      () => PrayerPlayerScreen(prayer: prayer),
      transition: Transition.cupertino,
      duration: const Duration(milliseconds: 300),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final scaffold = DefaultTextStyle(
      style: const TextStyle(
        fontFamily: _font,
        fontSize: 16,
        color: _ink,
        decoration: TextDecoration.none,
      ),
      child: CupertinoPageScaffold(
        backgroundColor: _cream,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            _buildNavBar(),
            _buildContent(),
            const SliverToBoxAdapter(child: SizedBox(height: 48)),
          ],
        ),
      ),
    );

    final tour = _tour;
    final curatedShown =
        _curatedRevealed && !_curatedDismissed && _curated != null;
    if (tour == null || !curatedShown) return scaffold;

    // The real tour spotlight (dim + cutout + Cozy card) on the curated pick,
    // matching every other tour step. Only while the tour is actually running.
    return Stack(
      children: [
        scaffold,
        Positioned.fill(
          child: Obx(
            () => tour.active.value &&
                    tour.steps.isNotEmpty &&
                    tour.current.id == 'pray'
                ? SimpleSpotlight(
                    targetKey: _curatedKey,
                    icon: HugeIcons.strokeRoundedSparkles,
                    title: 'tour_curated_title'.tr,
                    body: 'tour_curated_card_body'.tr,
                    hint: 'tour_pray_hint'.tr,
                    onSkip: () => tour.finish(completed: false),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

  // ── Nav bar ────────────────────────────────────────────────────────────────

  Widget _buildNavBar() {
    return SliverToBoxAdapter(
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
          child: Row(
            children: [
              _CircleButton(
                icon: CupertinoIcons.arrow_left,
                onTap: () {
                  HapticFeedback.lightImpact();
                  Get.back();
                },
              ),
              const SizedBox(width: 16),
              Text(
                'prayer_pray'.tr,
                style: const TextStyle(
                  fontFamily: _font,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Content ────────────────────────────────────────────────────────────────

  Widget _buildContent() {
    return Obx(() {
      if (_controller.isLoading.value) {
        return const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CupertinoActivityIndicator(color: _ink)),
        );
      }

      if (_controller.errorMessage.value.isNotEmpty &&
          _controller.prayers.isEmpty) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: _ErrorState(
            message: _controller.errorMessage.value,
            onRetry: _controller.loadPrayers,
          ),
        );
      }

      final featured = _controller.featuredPrayer;
      final curated = _curated;
      final showCurated =
          _curatedRevealed && !_curatedDismissed && curated != null;

      // Build the hero with explicit null-narrowing so the morph swaps cleanly
      // between the featured pick and the mood-matched one.
      Widget? hero;
      if (showCurated) {
        final pick = curated;
        hero = _CuratedCard(
          key: _curatedKey,
          prayer: pick,
          mood: _mood!,
          onTap: () => _openPlayer(pick, heavy: true),
          onDismiss: () => setState(() => _curatedDismissed = true),
        );
      } else if (featured != null) {
        hero = _FeaturedCard(
          key: const ValueKey('featured'),
          prayer: featured,
          onTap: () => _openPlayer(featured, heavy: true),
        );
      }

      return SliverList(
        delegate: SliverChildListDelegate([
          // ── Hero: today's prayer → (after reveal) "Curated for you" ───────
          // Same slot: the featured card morphs into the mood-matched pick so
          // the personalization reads as a deliberate reorganization.
          if (hero != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: AnimatedSize(
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 420),
                  switchInCurve: Curves.easeOutCubic,
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.96, end: 1.0).animate(anim),
                      child: child,
                    ),
                  ),
                  child: hero,
                ),
              ),
            ),
            const SizedBox(height: 34),
          ],

          // ── Theme sections (2-column grid) ───────────────────────────────
          //
          // Built as Rows of pairs wrapped in IntrinsicHeight so the two cards
          // on a row share the height of the taller one. Each card's internal
          // `Spacer()` then pushes the Play pill to the same Y across the row.
          // (Plain Wrap let each card auto-size to its own content, which made
          // multi-line titles misalign the Play buttons.)
          for (final entry in _controller.grouped.entries) ...[
            _DomainSectionHeader(domain: entry.key),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  for (int i = 0; i < entry.value.length; i += 2)
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: i + 2 < entry.value.length ? 18 : 0,
                      ),
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _PrayerGridCard(
                                prayer: entry.value[i],
                                onTap: () => _openPlayer(entry.value[i]),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: i + 1 < entry.value.length
                                  ? _PrayerGridCard(
                                      prayer: entry.value[i + 1],
                                      onTap: () =>
                                          _openPlayer(entry.value[i + 1]),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ]),
      );
    });
  }
}

// ─── Featured hero card ──────────────────────────────────────────────────────

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({super.key, required this.prayer, required this.onTap});
  final Prayer prayer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
      decoration: PrayerPalette.cardDecoration(
        radius: 28,
        shadowOffset: const Offset(0, 7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: _peach,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'prayer_todaysPrayer'.tr,
              style: const TextStyle(
                fontFamily: _font,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: _ink,
                letterSpacing: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            prayer.title,
            style: const TextStyle(
              fontFamily: _font,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: _ink,
              letterSpacing: -0.5,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),

          // Reference
          Text(
            prayer.scriptureRef.toUpperCase(),
            style: const TextStyle(
              fontFamily: _font,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: _orange,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 22),
          _BeginButton(
            onTap: onTap,
            durationLabel: prayer.durationLabel,
          ),
        ],
      ),
    );
  }
}

// ─── Curated-for-you hero (mood-matched) ──────────────────────────────────────

class _CuratedCard extends StatelessWidget {
  const _CuratedCard({
    super.key,
    required this.prayer,
    required this.mood,
    required this.onTap,
    required this.onDismiss,
  });
  final Prayer prayer;
  final MoodLevel mood;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
      decoration: PrayerPalette.cardDecoration(
        radius: 28,
        shadowOffset: const Offset(0, 7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge + dismiss
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: _peach,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(mood.emoji, style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 7),
                    Text(
                      'prayer_curatedForYou'.tr,
                      style: const TextStyle(
                        fontFamily: _font,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              _Pressable(
                onTap: onDismiss,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: _cream,
                    shape: BoxShape.circle,
                    border: Border.all(color: _ink, width: 1.8),
                  ),
                  child: const Icon(
                    CupertinoIcons.xmark,
                    color: _ink,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // "Because you're feeling weary."
          Text(
            'prayer_becauseFeeling'
                .trParams({'mood': ('mood_${mood.name}'.tr).toLowerCase()}),
            style: const TextStyle(
              fontFamily: _font,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _subtle,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),

          // Title
          Text(
            prayer.title,
            style: const TextStyle(
              fontFamily: _font,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: _ink,
              letterSpacing: -0.5,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),

          // Reference
          Text(
            prayer.scriptureRef.toUpperCase(),
            style: const TextStyle(
              fontFamily: _font,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: _orange,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 22),
          _BeginButton(
            onTap: onTap,
            durationLabel: prayer.durationLabel,
            label: 'prayer_prayThisNow'.tr,
          ),
        ],
      ),
    );
  }
}

class _BeginButton extends StatelessWidget {
  const _BeginButton({
    required this.onTap,
    required this.durationLabel,
    this.label,
  });
  final VoidCallback onTap;
  final String durationLabel;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return _Pressable(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: _orange,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: _ink, width: 2.5),
          boxShadow: PrayerPalette.hardShadow(offset: const Offset(0, 4)),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: _ink, width: 1.8),
              ),
              alignment: Alignment.center,
              child: const Icon(
                CupertinoIcons.play_fill,
                color: _orange,
                size: 14,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label ?? 'prayer_beginTodays'.tr,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: _font,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.1,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _ink, width: 1.5),
              ),
              child: Text(
                durationLabel,
                style: const TextStyle(
                  fontFamily: _font,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Domain section header ────────────────────────────────────────────────────

class _DomainSectionHeader extends StatelessWidget {
  const _DomainSectionHeader({required this.domain});
  final PrayerDomain domain;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        children: [
          Icon(domain.icon, color: _orange, size: 18),
          const SizedBox(width: 10),
          Text(
            domain.displayName.toUpperCase(),
            style: const TextStyle(
              fontFamily: _font,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: _subtle,
              letterSpacing: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Prayer grid card (2-column) ──────────────────────────────────────────────

class _PrayerGridCard extends StatelessWidget {
  const _PrayerGridCard({required this.prayer, required this.onTap});
  final Prayer prayer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _Pressable(
      onTap: onTap,
      child: Container(
        height: 188,
        padding: const EdgeInsets.all(16),
        decoration: PrayerPalette.cardDecoration(
          radius: 22,
          shadowOffset: const Offset(3, 5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon chip
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _peach,
                shape: BoxShape.circle,
                border: Border.all(color: _ink, width: 2),
              ),
              child: Icon(prayer.domain.icon, color: _ink, size: 18),
            ),
            const SizedBox(height: 10),
            Text(
              prayer.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: _font,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _ink,
                height: 1.15,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              prayer.scriptureRef.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: _font,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _subtle,
                letterSpacing: 0.6,
              ),
            ),
            const Spacer(),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _peach,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _ink, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: _ink.withValues(alpha: 0.18),
                      offset: const Offset(0, 2),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: _orange,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.play_fill,
                        color: Colors.white,
                        size: 11,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'prayer_playDuration'
                          .trParams({'d': prayer.durationLabel}),
                      style: const TextStyle(
                        fontFamily: _font,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

// ─── Pressable wrapper (scale on tap) ─────────────────────────────────────────

class _Pressable extends StatefulWidget {
  const _Pressable({required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(_press);
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _press.forward(),
      onTapUp: (_) {
        _press.reverse();
        widget.onTap();
      },
      onTapCancel: () => _press.reverse(),
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

// ─── Circular bordered button ─────────────────────────────────────────────────

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _Pressable(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: _card,
          shape: BoxShape.circle,
          border: Border.all(color: _ink, width: 2.5),
          boxShadow: PrayerPalette.hardShadow(offset: const Offset(0, 3)),
        ),
        child: Icon(icon, color: _ink, size: 24),
      ),
    );
  }
}

// ─── Error state ──────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_circle,
              color: _orange,
              size: 44,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: _font,
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: _subtle,
              ),
            ),
            const SizedBox(height: 20),
            _Pressable(
              onTap: onRetry,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                decoration: BoxDecoration(
                  color: _orange,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: _ink, width: 2.5),
                  boxShadow:
                      PrayerPalette.hardShadow(offset: const Offset(0, 4)),
                ),
                child: Text(
                  'prayer_tryAgain'.tr,
                  style: TextStyle(
                    fontFamily: _font,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
