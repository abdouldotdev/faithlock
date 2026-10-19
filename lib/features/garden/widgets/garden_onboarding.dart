import 'dart:async';

import 'package:flutter/material.dart';

import '../../../shared/widgets/cozy/cozy.dart';
import '../controllers/grace_garden_controller.dart';
import '../domain/garden_engine.dart';

/// OWNER: Dev2 (Experience & Flow).
///
/// Cinematic onboarding tour. THE BIG ONE. Requirements (from product):
///  - AUTO-PLAYS — the user never has to Read/Pray/Talk; it demonstrates.
///  - Teaches the SYSTEM: the garden is the RENDER of actions done elsewhere in
///    the app (reading, praying), not where you do them.
///  - Explains attribution (a verse on anxiety → Peace deepens), the tree states
///    (seed → bearing fruit → endless tiers), and REGRESSION when you stop using
///    the app (health dips, leaves wait — nothing is lost).
///  - ISOLATES each visual element in sync with the narration (use
///    controller.setIntro(focus:, solo:) so the world spotlights one plant).
///  - Ends on a PULSING "Begin" button.
///
/// The tour is a scripted list of [_Scene]s played one at a time by a [Timer].
/// Each scene narrates a single idea, mutates the world via the controller's
/// pure setters (never the journal-writing actions), and isolates the relevant
/// plant. The final scene reveals the pulsing Begin button. Right before
/// [onDone] we call [GraceGardenController.reset] so the 30-day sim starts from
/// a clean seed state.
class GardenOnboarding extends StatefulWidget {
  final GraceGardenController c;
  final VoidCallback onDone;
  const GardenOnboarding({super.key, required this.c, required this.onDone});

  @override
  State<GardenOnboarding> createState() => _GardenOnboardingState();
}

/// One beat of the tour. [hold] is how long this scene stays before the next.
class _Scene {
  final String line;
  final Duration hold;
  final void Function(GraceGardenController c) act;
  const _Scene(this.line, this.act, {this.hold = const Duration(seconds: 4)});
}

class _GardenOnboardingState extends State<GardenOnboarding>
    with TickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  // Caption cross-fade as scenes advance.
  late final AnimationController _caption = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  late final List<_Scene> _scenes;
  Timer? _timer;
  int _i = 0;
  String _line = '';
  bool _showBegin = false;

  // The hero plant we ramp through every life-stage. Peace = the canonical
  // "a verse on anxiety → Peace deepens" example, and it's an evergreen tree so
  // the endless-tier silhouettes read clearly.
  static const _hero = FruitKey.peace;

  @override
  void initState() {
    super.initState();
    _scenes = _buildScenes();
    // Start the world in a calm, isolated state: focus the hero, but show the
    // whole garden so the first line ("this is your garden") lands.
    final c = widget.c;
    c.setIntro(active: true, clearFocus: true, solo: false);
    c.setTime(0.5);
    c.setSeason(Season.spring);
    for (final f in kFruits) {
      c.setGrowth(f.key, 5);
    }
    _playFrom(0);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulse.dispose();
    _caption.dispose();
    super.dispose();
  }

  // ── Scene script ─────────────────────────────────────────────────────────
  List<_Scene> _buildScenes() {
    return [
      _Scene(
        'This is your Garden of Grace.',
        (c) {
          c.setIntro(active: true, clearFocus: true, solo: false);
          for (final f in kFruits) {
            c.setGrowth(f.key, 5);
          }
        },
        hold: const Duration(milliseconds: 3600),
      ),
      _Scene(
        'It isn’t where you do things — it’s what grows from them. Every verse you read, every prayer, tends it.',
        (c) => c.setIntro(active: true, clearFocus: true, solo: false),
        hold: const Duration(milliseconds: 4800),
      ),
      _Scene(
        'Watch. You read a verse on anxiety…',
        (c) => c.setIntro(active: true, focus: _hero, solo: true),
        hold: const Duration(milliseconds: 3400),
      ),
      _Scene(
        '…and here, your Peace deepens. That’s all attribution is — your life, reflected.',
        (c) {
          c.setIntro(active: true, focus: _hero, solo: true);
          c.setGrowth(_hero, 28); // seed → sprouting/growing
        },
        hold: const Duration(milliseconds: 4200),
      ),
      _Scene(
        'Keep tending, and a seedling becomes a sapling…',
        (c) => c.setGrowth(_hero, 64), // blossoming → bearing fruit
        hold: const Duration(milliseconds: 3400),
      ),
      _Scene(
        '…then it bears fruit, and keeps growing — there is no ceiling here.',
        (c) => c.setGrowth(_hero, 100), // crosses into endless: Young tree
        hold: const Duration(milliseconds: 3800),
      ),
      _Scene(
        'A young tree. Then established. Then ancient. Grace never stops growing.',
        (c) => c.setGrowth(_hero, 260), // Flourishing tier
        hold: const Duration(milliseconds: 4200),
      ),
      _Scene(
        'And when life pulls you away? Nothing is lost.',
        (c) {
          c.setIntro(active: true, clearFocus: true, solo: false);
          c.setTime(0.08); // dusk — the garden quiets
          c.setHealthValue(34); // leaves wait
        },
        hold: const Duration(milliseconds: 4200),
      ),
      _Scene(
        'The leaves just wait for you. 🤍 Come back, and everything is still here.',
        (c) {
          c.setTime(0.5); // morning returns
          c.setHealthValue(100); // recover
        },
        hold: const Duration(milliseconds: 4400),
      ),
      _Scene(
        'Tended by you. Grown by God. This is your Garden of Grace.',
        (c) {
          c.setIntro(active: true, clearFocus: true, solo: false);
          // Leave a gentle full garden behind the Begin button.
          c.setGrowth(_hero, 100);
        },
        hold: const Duration(milliseconds: 1200),
      ),
    ];
  }

  // ── Playback ─────────────────────────────────────────────────────────────
  void _playFrom(int index) {
    if (!mounted) return;
    if (index >= _scenes.length) {
      _reveal();
      return;
    }
    final scene = _scenes[index];
    scene.act(widget.c);
    setState(() {
      _i = index;
      _line = scene.line;
    });
    _caption.forward(from: 0);
    _timer = Timer(scene.hold, () => _playFrom(index + 1));
  }

  void _reveal() {
    if (!mounted) return;
    setState(() => _showBegin = true);
    _pulse.repeat(reverse: true);
  }

  /// Skip the tour: jump to the final reveal immediately.
  void _skip() {
    _timer?.cancel();
    // Apply the closing scene's framing so the world looks settled.
    final c = widget.c;
    c.setIntro(active: true, clearFocus: true, solo: false);
    c.setTime(0.5);
    c.setHealthValue(100);
    c.setGrowth(_hero, 100);
    setState(() => _line = _scenes.last.line);
    _caption.forward(from: 0);
    _reveal();
  }

  void _finish() {
    _timer?.cancel();
    // Clear the cinematic framing and wipe all demo mutations so the 30-day sim
    // begins from a clean seed garden.
    widget.c.setIntro(active: false, clearFocus: true, solo: false);
    widget.c.reset();
    widget.onDone();
  }

  // ── UI ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          // Gentle scrim so captions stay readable over the world.
          const _CinematicScrim(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Skip — top-right, quiet, hidden once Begin appears.
                  Align(
                    alignment: Alignment.topRight,
                    child: AnimatedOpacity(
                      opacity: _showBegin ? 0 : 1,
                      duration: CozyTokens.base,
                      child: TextButton(
                        onPressed: _showBegin ? null : _skip,
                        child: Text('Skip',
                            style: CozyText.label
                                .copyWith(color: CozyColors.surface)),
                      ),
                    ),
                  ),
                  const Spacer(),
                  _CaptionCard(
                    line: _line,
                    progress: _showBegin ? 1 : (_i + 1) / _scenes.length,
                    fade: _caption,
                  ),
                  const SizedBox(height: 16),
                  AnimatedSwitcher(
                    duration: CozyTokens.base,
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: ScaleTransition(scale: anim, child: child),
                    ),
                    child: _showBegin
                        ? Padding(
                            key: const ValueKey('begin'),
                            padding: const EdgeInsets.only(bottom: 8),
                            child: ScaleTransition(
                              scale: Tween<double>(begin: 1, end: 1.06)
                                  .animate(CurvedAnimation(
                                      parent: _pulse,
                                      curve: Curves.easeInOut)),
                              child: CozyButton(
                                  text: 'Begin', onTap: _finish),
                            ),
                          )
                        : const SizedBox(
                            key: ValueKey('empty'), height: 8),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A soft top-to-bottom scrim that keeps captions legible without hiding the
/// garden the tour is pointing at.
class _CinematicScrim extends StatelessWidget {
  const _CinematicScrim();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0x14000000),
            Color(0x00000000),
            Color(0x3D000000),
          ],
          stops: [0, 0.45, 1],
        ),
      ),
    );
  }
}

/// The narration card: a cozy surface with the current line and a thin progress
/// bar showing how far the tour has played.
class _CaptionCard extends StatelessWidget {
  final String line;
  final double progress;
  final Animation<double> fade;

  const _CaptionCard({
    required this.line,
    required this.progress,
    required this.fade,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      decoration: ShapeDecoration(
        color: CozyColors.surface,
        shape: CozyTokens.smooth(
          CozyTokens.radiusLg,
          side: const BorderSide(
              color: CozyColors.outline, width: CozyTokens.borderWidth),
        ),
        shadows: CozyTokens.shadowHard,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: fade,
            child: Text(
              line,
              key: ValueKey(line),
              style: CozyText.heading,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress.clamp(0, 1)),
              duration: CozyTokens.base,
              curve: Curves.easeOut,
              builder: (_, value, __) => LinearProgressIndicator(
                value: value,
                minHeight: 5,
                backgroundColor: CozyColors.surfaceMuted,
                valueColor:
                    const AlwaysStoppedAnimation(CozyColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
