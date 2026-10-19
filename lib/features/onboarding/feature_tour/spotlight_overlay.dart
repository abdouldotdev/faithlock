import 'package:faithlock/core/theme/cozy/cozy.dart';
import 'package:faithlock/navigation/controllers/navigation_controller.dart';
import 'package:faithlock/shared/widgets/cozy/cozy_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';

import 'feature_tour_controller.dart';
import 'tour_step.dart';

/// Full-screen coach-mark overlay. Dims everything, cuts a soft-cornered hole
/// around the current target, traces it with a pulsing terracotta ring, and
/// floats a Cozy info card on the side with the most room. The cutout *morphs*
/// from one target to the next so the tour reads as one continuous gesture.
///
/// Mounted once (by the navigation shell) and shown/hidden via the controller's
/// [FeatureTourController.active] flag, so it can spotlight elements that live
/// in any tab without each screen having to host it.
class SpotlightOverlay extends StatefulWidget {
  const SpotlightOverlay({super.key, required this.controller});

  final FeatureTourController controller;

  @override
  State<SpotlightOverlay> createState() => _SpotlightOverlayState();
}

class _SpotlightOverlayState extends State<SpotlightOverlay>
    with TickerProviderStateMixin {
  /// Drives the cutout morph + card entrance on every step change.
  late final AnimationController _morph;

  /// Slow, looping breath for the highlight ring.
  late final AnimationController _pulse;

  /// Geometry we're animating between. Rect is in global coordinates.
  Rect? _fromRect;
  Rect? _toRect;
  double _fromRadius = 24;
  double _toRadius = 24;

  /// Index we last laid out, so we only re-measure on an actual step change.
  int _laidOutIndex = -1;

  /// Hides the card for a beat while we switch tabs / wait for layout.
  bool _measuring = false;

  @override
  void initState() {
    super.initState();
    _morph = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    widget.controller.index.listen((_) => _onStepChanged());
    // When the tour switches on, index is already 0 (no change event fires), so
    // measure the opening step explicitly here.
    widget.controller.active.listen((on) {
      if (on) {
        _laidOutIndex = -1;
        _toRect = null;
        _onStepChanged();
      }
    });
  }

  @override
  void dispose() {
    _morph.dispose();
    _pulse.dispose();
    super.dispose();
  }

  /// Switch tabs if the step lives on another one, wait for the new layout to
  /// settle, then measure the target and kick off the morph.
  Future<void> _onStepChanged() async {
    if (!mounted) return;
    final c = widget.controller;
    if (!c.active.value || c.steps.isEmpty) return;
    if (_laidOutIndex == c.index.value) return;
    _laidOutIndex = c.index.value;

    final step = c.current;

    if (step.navIndex != null && Get.isRegistered<NavigationController>()) {
      final nav = Get.find<NavigationController>();
      if (nav.currentIndex != step.navIndex) {
        nav.changePage(step.navIndex!);
        setState(() => _measuring = true);
        // Two frames: one for the IndexedStack to swap, one for it to lay out.
        await Future.delayed(const Duration(milliseconds: 260));
      }
    }
    if (!mounted) return;

    // Bring the target into view if it lives inside a scroll view (e.g. the
    // Blocked-Apps tile on the Profile tab) before we read its geometry.
    final targetCtx = step.targetKey?.currentContext;
    if (targetCtx != null) {
      await Scrollable.ensureVisible(
        targetCtx,
        duration: CozyTokens.base,
        alignment: 0.3,
        curve: Curves.easeOutCubic,
      );
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 60));
      if (!mounted) return;
    }

    final next = _measureTarget(step);
    setState(() {
      _measuring = false;
      _fromRect = _toRect ?? next ?? _centerRect();
      _toRect = next;
      _fromRadius = _toRadius;
      _toRadius = step.cutoutRadius;
    });
    _morph.forward(from: 0);

    // Reveal side effect (e.g. grow the garden so it sprouts live on screen).
    step.onReveal?.call();
  }

  /// Global rect of the step's target, padded out a touch, or null for a
  /// message step (no spotlight).
  Rect? _measureTarget(TourStep step) {
    final key = step.targetKey;
    if (key == null) return null;
    final ctx = key.currentContext;
    final box = ctx?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    // Map the target's local rect through every ancestor transform (e.g. the
    // FittedBox that scales the pot) so the cutout lands on the *painted*
    // element rather than its unscaled layout box — otherwise a scaled target
    // gets a wrong-sized hole floating over empty space.
    final rect = MatrixUtils.transformRect(
      box.getTransformTo(null),
      Offset.zero & box.size,
    );
    return rect.inflate(step.cutoutPadding);
  }

  /// A small rect at screen center — used as the "from" when there's no prior
  /// target so the first cutout irises open from the middle.
  Rect _centerRect() {
    final size = MediaQuery.of(context).size;
    return Rect.fromCenter(
      center: size.center(Offset.zero),
      width: 1,
      height: 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return Obx(() {
      if (!c.active.value || c.steps.isEmpty) {
        return const SizedBox.shrink();
      }
      final step = c.current;
      // The overlay is a sibling of the Scaffold (not inside it), so it has no
      // Material ancestor — wrap it so Text renders normally instead of with
      // the debug "missing Material" yellow underline.
      return Material(
        type: MaterialType.transparency,
        child: AnimatedBuilder(
          animation: Listenable.merge([_morph, _pulse]),
          builder: (context, _) {
            final t = Curves.easeOutCubic.transform(_morph.value);
            // Message steps (welcome / wrap-up) dim the whole screen — no hole.
            // `rect` is the raw target hole (what spotlightBuilder anchors to);
            // `litRect` is what we actually cut + ring + anchor the card to,
            // after the step's optional transform (the garden step grows it to
            // wrap Toby and balance its side margins).
            final rect =
                step.isMessage ? null : _lerpRect(_fromRect, _toRect, t);
            final litRect = (rect != null && step.cutoutTransform != null)
                ? step.cutoutTransform!(context, rect)
                : rect;
            final radius = _fromRadius + (_toRadius - _fromRadius) * t;
            return Stack(
              children: [
                // Dimmer + cutout. On a normal step it absorbs taps so the app
                // underneath is inert; on an interactive step it lets taps fall
                // through so the user can actually tap the spotlit element.
                Positioned.fill(
                  child: IgnorePointer(
                    ignoring: step.interactive,
                    child: GestureDetector(
                      onTap: () {}, // swallow stray taps on the dim area
                      child: CustomPaint(
                        painter: _SpotlightPainter(
                          rect: litRect,
                          radius: radius,
                          shape: step.shape,
                          pulse: _pulse.value,
                          ringOpacity: t,
                        ),
                      ),
                    ),
                  ),
                ),
                // Extra art anchored to the cutout (e.g. Toby watering the
                // garden). Only steps that opt in via spotlightBuilder render
                // it, and only once we have a measured hole to anchor to.
                if (rect != null && step.spotlightBuilder != null)
                  step.spotlightBuilder!(context, rect),
                if (!_measuring)
                  _TourCard(
                    step: step,
                    controller: c,
                    targetRect: litRect,
                    appear: t,
                  ),
              ],
            );
          },
        ),
      );
    });
  }

  Rect? _lerpRect(Rect? a, Rect? b, double t) {
    if (a == null) return b;
    if (b == null) return a;
    return Rect.lerp(a, b, t);
  }
}

/// Paints the dim veil with a hole punched out, plus a breathing ring.
class _SpotlightPainter extends CustomPainter {
  _SpotlightPainter({
    required this.rect,
    required this.radius,
    required this.shape,
    required this.pulse,
    required this.ringOpacity,
  });

  final Rect? rect;
  final double radius;
  final TourCutoutShape shape;
  final double pulse; // 0..1 breathing value
  final double ringOpacity; // fades the ring in with the morph

  @override
  void paint(Canvas canvas, Size size) {
    final full = Offset.zero & size;
    final veil = Paint()..color = CozyColors.ink.withValues(alpha: 0.74);

    if (rect == null) {
      // Message step: just dim the whole screen, no hole.
      canvas.drawRect(full, veil);
      return;
    }

    final hole = shape == TourCutoutShape.circle
        ? (Path()
          ..addOval(Rect.fromCircle(
            center: rect!.center,
            radius: rect!.longestSide / 2,
          )))
        : (Path()
          ..addRRect(RRect.fromRectAndRadius(
            rect!,
            Radius.circular(radius),
          )));

    // Veil = full screen minus the hole.
    final veilPath = Path.combine(
      PathOperation.difference,
      Path()..addRect(full),
      hole,
    );
    canvas.drawPath(veilPath, veil);

    // Breathing highlight ring hugging the cutout.
    final grow = 3 + pulse * 5;
    final ringRect = rect!.inflate(grow);
    final ringPath = shape == TourCutoutShape.circle
        ? (Path()
          ..addOval(Rect.fromCircle(
            center: ringRect.center,
            radius: ringRect.longestSide / 2,
          )))
        : (Path()
          ..addRRect(RRect.fromRectAndRadius(
            ringRect,
            Radius.circular(radius + grow),
          )));
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = CozyColors.primary
          .withValues(alpha: (0.85 - pulse * 0.45) * ringOpacity);
    canvas.drawPath(ringPath, ring);
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) =>
      old.rect != rect ||
      old.radius != radius ||
      old.pulse != pulse ||
      old.ringOpacity != ringOpacity;
}

/// The floating Cozy explanation card: header chip + title + body, a row of
/// step dots, and Skip / Next controls. Positioned on whichever side of the
/// target has the most vertical room (or centered for a message step).
class _TourCard extends StatelessWidget {
  const _TourCard({
    required this.step,
    required this.controller,
    required this.targetRect,
    required this.appear,
  });

  final TourStep step;
  final FeatureTourController controller;
  final Rect? targetRect;
  final double appear;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final size = media.size;
    const cardMargin = 20.0;
    final maxCardWidth = size.width - cardMargin * 2;

    final card = _buildCard(context);

    // Message step → dead center.
    if (targetRect == null || step.anchor == TourCardAnchor.center) {
      return Center(
        child: _fade(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxCardWidth),
            child: card,
          ),
        ),
      );
    }

    final spaceAbove = targetRect!.top - media.padding.top - cardMargin;
    final spaceBelow =
        size.height - targetRect!.bottom - media.padding.bottom - cardMargin;
    final placeBelow = step.anchor == TourCardAnchor.below ||
        (step.anchor == TourCardAnchor.auto && spaceBelow >= spaceAbove);

    return Positioned(
      left: cardMargin,
      right: cardMargin,
      top: placeBelow ? targetRect!.bottom + 18 : null,
      bottom: placeBelow ? null : size.height - targetRect!.top + 18,
      child: _fade(
        slideFrom: placeBelow ? -12 : 12,
        child: Align(
          alignment: Alignment.center,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxCardWidth),
            child: card,
          ),
        ),
      ),
    );
  }

  Widget _fade({required Widget child, double slideFrom = 8}) {
    return Opacity(
      opacity: appear.clamp(0, 1),
      child: Transform.translate(
        offset: Offset(0, slideFrom * (1 - appear)),
        child: child,
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    return DecoratedBox(
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
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (step.icon != null) ...[
                  Container(
                    width: 40,
                    height: 40,
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
                      icon: step.icon!,
                      color: CozyColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    step.titleKey.tr,
                    style: CozyText.heading.copyWith(fontSize: 19),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Builder(
              builder: (_) {
                final bodyStyle = CozyText.body.copyWith(
                  color: CozyColors.inkMuted,
                  height: 1.35,
                );
                // The curated step personalizes its body with the mood the user
                // just picked (loaded async on reveal), so it reacts to the
                // controller; every other step is plain static copy.
                if (step.id == 'curated') {
                  return Obx(() {
                    final mood = controller.curatedMood.value;
                    final body = mood.isEmpty
                        ? 'tour_curated_body_generic'.tr
                        : 'tour_curated_body'.trParams({'mood': mood});
                    return Text(body, style: bodyStyle);
                  });
                }
                return Text(step.bodyKey.tr, style: bodyStyle);
              },
            ),
            const SizedBox(height: 18),
            if (step.interactive)
              // Interactive step: no Next and no hint label — the user advances
              // simply by doing the action (tapping the real spotlit button
              // beneath the veil). Keep just the progress dots.
              _StepDots(
                count: controller.total,
                index: controller.index.value,
              )
            else
              Row(
                children: [
                  _StepDots(
                    count: controller.total,
                    index: controller.index.value,
                  ),
                  const Spacer(),
                  if (!controller.isFirst)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _GhostButton(
                        label: 'tour_back'.tr,
                        onTap: controller.back,
                      ),
                    ),
                  CozyButton(
                    text: controller.isLast ? 'tour_finish'.tr : 'tour_next'.tr,
                    fullWidth: false,
                    height: 46,
                    borderRadius: 16,
                    onTap: controller.next,
                  ),
                ],
              ),
            const SizedBox(height: 4),
            Center(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => controller.finish(completed: false),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    'tour_skip'.tr,
                    style: CozyText.label.copyWith(
                      color: CozyColors.inkMuted,
                      decoration: TextDecoration.underline,
                    ),
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

/// Minimal text button for the secondary "Back" action.
class _GhostButton extends StatelessWidget {
  const _GhostButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Text(
          label,
          style: CozyText.button.copyWith(
            color: CozyColors.inkMuted,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

/// Progress dots; the active one stretches into a terracotta pill.
class _StepDots extends StatelessWidget {
  const _StepDots({required this.count, required this.index});
  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: CozyTokens.fast,
          margin: const EdgeInsets.only(right: 5),
          width: active ? 20 : 8,
          height: 8,
          decoration: ShapeDecoration(
            color: active ? CozyColors.primary : CozyColors.surfaceMuted,
            shape: CozyTokens.smooth(
              CozyTokens.radiusPill,
              side: BorderSide(
                color: active ? CozyColors.outline : CozyColors.border,
                width: CozyTokens.borderWidthThin,
              ),
            ),
          ),
        );
      }),
    );
  }
}
