import 'dart:async';

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:faithlock/features/faithlock/controllers/stats_controller.dart';
import 'package:faithlock/features/garden/controllers/garden_controller.dart';
import 'package:faithlock/features/garden/widgets/realistic_tree_pot.dart';
import 'package:faithlock/shared/widgets/cozy/cozy.dart';

/// Shared Hero tag so the home pot morphs smoothly into this fullscreen view.
const String kGardenPotHeroTag = 'garden-pot-hero';

/// Fullscreen view of the garden pot: the plant enlarged, Toby tending it
/// beside the pot, a subtle auto-cycling motivational bubble, and a collapse
/// control (button · swipe-down · tap-background) to return home.
class GardenPotFullscreenScreen extends StatefulWidget {
  const GardenPotFullscreenScreen({super.key});

  @override
  State<GardenPotFullscreenScreen> createState() =>
      _GardenPotFullscreenScreenState();
}

class _GardenPotFullscreenScreenState extends State<GardenPotFullscreenScreen> {
  late final GardenController garden;
  StatsController? stats;

  @override
  void initState() {
    super.initState();
    garden = Get.isRegistered<GardenController>()
        ? Get.find<GardenController>()
        : Get.put(GardenController());
    if (Get.isRegistered<StatsController>()) {
      stats = Get.find<StatsController>();
    }
  }

  void _collapse() {
    if (Navigator.of(context).canPop()) Get.back();
  }

  // ── Stage / mood derivation ───────────────────────────────────────────────
  _Stage _stageFor(double p) {
    if (p < 0.10) return _Stage('🌱', 'garden_stageSeed', 'garden_msgSeed', 1);
    if (p < 0.35) {
      return _Stage('🌿', 'garden_stageSprout', 'garden_msgSprout', 2);
    }
    if (p < 0.60) {
      return _Stage('🪴', 'garden_stageGrowing', 'garden_msgGrowing', 3);
    }
    if (p < 0.85) {
      return _Stage('🌸', 'garden_stageBlooming', 'garden_msgBlooming', 4);
    }
    return _Stage('🍎', 'garden_stageFruit', 'garden_msgFruit', 5);
  }

  /// A short, human comment on how the tree is *doing* — health first (spec §8:
  /// low health is **resting**, never wilting/failing — suffering-safe), then the
  /// named growth stage (spec §6). No numbers, no score (spec §0/§2).
  String _stateComment(double p, double h) {
    if (h < 0.35) return '🌙  Resting deeply — water it when you can';
    if (h < 0.60) return '💤  Resting — a little water revives it';
    if (h >= 0.80 && p >= 0.85) return '☀️  Thriving — heavy with fruit';
    if (p >= 0.85) return '🍎  Bearing fruit';
    if (p >= 0.60) return '🌸  In bloom';
    if (p >= 0.35) return '🌿  Growing strong';
    if (p >= 0.10) return '🌱  A young sprout';
    return '🌱  Freshly planted';
  }

  List<String> _messagesFor(double p, double health, int streak) {
    final stage = _stageFor(p);
    final msgs = <String>[];
    if (health < 0.5) msgs.add('garden_msgThirsty'.tr);
    msgs.add(stage.msgKey.tr);
    if (streak > 0) {
      msgs.add('garden_msgStreak'.trParams({'streak': '$streak'}));
    } else {
      msgs.add('garden_msgTendToday'.tr);
    }
    return msgs;
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    // Enlarged hero: the plant dominates, near full width, as tall as it fits so
    // the page is used (box height tracks the frame ratio → no letterbox).
    final potW = (media.size.width * 0.98).clamp(300.0, 560.0);
    final potH = potW / RealisticTreePot.aspectRatio;

    return Scaffold(
      backgroundColor: CozyColors.background,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _collapse,
        onVerticalDragEnd: (d) {
          if ((d.primaryVelocity ?? 0) > 260) _collapse();
        },
        child: SafeArea(
          child: Stack(
            children: [
              // Living header — anchors the top third instead of leaving a void.
              // Line 1: how the tree is doing (health-first, suffering-safe).
              // Line 2: a discreet stat line from data we already have
              //   (streak · minutes in prayer today). Both lines fade/hide
              //   gracefully when there's nothing to show.
              Positioned(
                top: 72,
                left: CozyTokens.space24,
                right: CozyTokens.space24,
                child: Obx(() {
                  final s = stats?.userStats.value;
                  final streak = s?.currentStreak ?? 0;
                  final prayed = s?.prayedMinutesToday ?? 0;
                  final parts = <String>[
                    if (streak > 0)
                      'garden_hdrStreak'.trParams({'count': '$streak'}),
                    if (prayed > 0)
                      'garden_hdrPrayed'.trParams({'count': '$prayed'}),
                  ];
                  final sub = parts.join('   ·   ');
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _stateComment(
                            garden.progress.value, garden.health.value),
                        textAlign: TextAlign.center,
                        style: CozyText.heading.copyWith(color: CozyColors.ink),
                      ),
                      if (sub.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          sub,
                          textAlign: TextAlign.center,
                          style: CozyText.label
                              .copyWith(color: CozyColors.inkMuted),
                        ),
                      ],
                    ],
                  );
                }),
              ),

              // Collapse control — top-right.
              Positioned(
                right: CozyTokens.space16,
                top: CozyTokens.space8,
                child: CozyIconButton(
                  icon: HugeIcons.strokeRoundedArrowDown01,
                  size: 46,
                  onTap: _collapse,
                ),
              ),

              // Subtle motivational bubble — floats above the pot.
              Align(
                alignment: const Alignment(0, -0.32),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: CozyTokens.space24),
                  child: Obx(() {
                    final msgs = _messagesFor(
                      garden.progress.value,
                      garden.health.value,
                      stats?.userStats.value?.currentStreak ?? 0,
                    );
                    return _FloatingBubble(messages: msgs);
                  }),
                ),
              ),

              // Just the pot/tree — enlarged, centred, Hero-morph from home.
              // (Toby is hidden for now.)
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: SizedBox(
                    width: media.size.width,
                    height: potH,
                    child: Transform.scale(
                      scale: 0.92,
                      alignment: Alignment.bottomCenter,
                      child: Obx(
                        () => Hero(
                          tag: kGardenPotHeroTag,
                          child: FittedBox(
                            fit: BoxFit.contain,
                            alignment: Alignment.bottomCenter,
                            // Box matches the frame aspect ratio so the tree fills
                            // it (rendered as large as possible).
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
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stage {
  final String emoji;
  final String labelKey;
  final String msgKey;
  final int step;
  const _Stage(this.emoji, this.labelKey, this.msgKey, this.step);
}

/// A subtle, well-designed pill that cross-fades through [messages] every few
/// seconds. Soft surface, hairline border, gentle shadow — never shouty.
class _FloatingBubble extends StatefulWidget {
  final List<String> messages;
  const _FloatingBubble({required this.messages});

  @override
  State<_FloatingBubble> createState() => _FloatingBubbleState();
}

class _FloatingBubbleState extends State<_FloatingBubble>
    with SingleTickerProviderStateMixin {
  int _i = 0;
  Timer? _timer;
  late final AnimationController _sway = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    _arm();
  }

  void _arm() {
    _timer?.cancel();
    if (widget.messages.length < 2) return;
    _timer = Timer.periodic(const Duration(milliseconds: 4200), (_) {
      if (!mounted) return;
      setState(() => _i = (_i + 1) % widget.messages.length);
    });
  }

  @override
  void didUpdateWidget(covariant _FloatingBubble old) {
    super.didUpdateWidget(old);
    if (!listEquals(old.messages, widget.messages)) {
      _i = 0;
      _arm();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sway.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.messages.isEmpty) return const SizedBox.shrink();
    final text = widget.messages[_i % widget.messages.length];
    return AnimatedBuilder(
      animation: _sway,
      builder: (context, child) => Transform.translate(
        offset: Offset((Curves.easeInOut.transform(_sway.value) - 0.5) * 12, 0),
        child: child,
      ),
      child: AnimatedSwitcher(
        duration: CozyTokens.base,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.18),
              end: Offset.zero,
            ).animate(anim),
            child: child,
          ),
        ),
        child: Container(
          key: ValueKey(text),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: ShapeDecoration(
            color: CozyColors.surface.withValues(alpha: 0.94),
            shape: CozyTokens.smooth(
              CozyTokens.radiusPill,
              side: BorderSide(
                color: CozyColors.outline.withValues(alpha: 0.12),
                width: CozyTokens.borderWidthThin,
              ),
            ),
            shadows: CozyTokens.shadowSoft,
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: CozyText.label.copyWith(color: CozyColors.ink, height: 1.25),
          ),
        ),
      ),
    );
  }
}
