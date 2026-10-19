import 'package:faithlock/core/theme/cozy/cozy.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';

/// A self-contained, single-target spotlight that matches the first-day tour's
/// look (dim veil + soft-cornered cutout + pulsing terracotta ring + Cozy info
/// card). Unlike the tour's [SpotlightOverlay] — which lives in the navigation
/// shell — this one can be dropped onto ANY screen (e.g. a pushed route like
/// the prayer library) to spotlight one element there.
///
/// The veil ignores pointers, so the highlighted element stays tappable. Mount
/// it as a `Positioned.fill` child of a [Stack] over the host screen's body.
class SimpleSpotlight extends StatefulWidget {
  const SimpleSpotlight({
    super.key,
    required this.targetKey,
    required this.title,
    required this.body,
    this.icon,
    this.hint,
    this.onSkip,
    this.cutoutRadius = 28,
    this.cutoutPadding = 8,
  });

  /// Key attached to the widget to spotlight on the host screen.
  final GlobalKey targetKey;

  final String title;
  final String body;

  /// `HugeIcons.strokeRounded*` glyph for the card's header chip.
  final List<List<dynamic>>? icon;

  /// Small call-to-action under the body (e.g. "Tap to pray").
  final String? hint;

  /// Optional "skip" affordance.
  final VoidCallback? onSkip;

  final double cutoutRadius;
  final double cutoutPadding;

  @override
  State<SimpleSpotlight> createState() => _SimpleSpotlightState();
}

class _SimpleSpotlightState extends State<SimpleSpotlight>
    with TickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat(reverse: true);

  late final AnimationController _appear = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  )..forward();

  @override
  void dispose() {
    _pulse.dispose();
    _appear.dispose();
    super.dispose();
  }

  /// Global rect of the target, padded out — re-read every frame so the cutout
  /// tracks the target through its reveal animation and any scrolling.
  Rect? _measure() {
    final box =
        widget.targetKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final origin = box.localToGlobal(Offset.zero);
    return (origin & box.size).inflate(widget.cutoutPadding);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulse, _appear]),
      builder: (context, _) {
        final rect = _measure();
        if (rect == null) return const SizedBox.shrink();
        final t = Curves.easeOutCubic.transform(_appear.value);
        // Dropped onto pushed routes whose body isn't under a Material (e.g. the
        // prayer library), so wrap our card in one — otherwise Text renders with
        // the debug "missing Material" yellow underline.
        return Material(
          type: MaterialType.transparency,
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _SpotlightPainter(
                      rect: rect,
                      radius: widget.cutoutRadius,
                      pulse: _pulse.value,
                      opacity: t,
                    ),
                  ),
                ),
              ),
              _card(context, rect, t),
            ],
          ),
        );
      },
    );
  }

  Widget _card(BuildContext context, Rect rect, double appear) {
    final media = MediaQuery.of(context);
    final size = media.size;
    const margin = 20.0;
    final spaceAbove = rect.top - media.padding.top - margin;
    final spaceBelow =
        size.height - rect.bottom - media.padding.bottom - margin;
    final placeBelow = spaceBelow >= spaceAbove;

    return Positioned(
      left: margin,
      right: margin,
      top: placeBelow ? rect.bottom + 18 : null,
      bottom: placeBelow ? null : size.height - rect.top + 18,
      child: Opacity(
        opacity: appear.clamp(0, 1),
        child: Transform.translate(
          offset: Offset(0, (placeBelow ? -12 : 12) * (1 - appear)),
          child: DecoratedBox(
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
                      if (widget.icon != null) ...[
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
                            icon: widget.icon!,
                            color: CozyColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Text(
                          widget.title,
                          style: CozyText.heading.copyWith(fontSize: 19),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.body,
                    style: CozyText.body.copyWith(
                      color: CozyColors.inkMuted,
                      height: 1.35,
                    ),
                  ),
                  if (widget.hint != null) ...[
                    const SizedBox(height: 14),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const HugeIcon(
                          icon: HugeIcons.strokeRoundedTap01,
                          color: CozyColors.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            widget.hint!,
                            style: CozyText.label.copyWith(
                              color: CozyColors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (widget.onSkip != null) ...[
                    const SizedBox(height: 6),
                    Center(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: widget.onSkip,
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Dim veil with a rounded hole + a breathing terracotta ring — mirrors the
/// tour's spotlight painter so the look is identical.
class _SpotlightPainter extends CustomPainter {
  _SpotlightPainter({
    required this.rect,
    required this.radius,
    required this.pulse,
    required this.opacity,
  });

  final Rect rect;
  final double radius;
  final double pulse;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final full = Offset.zero & size;
    final veil = Paint()
      ..color = CozyColors.ink.withValues(alpha: 0.74 * opacity);

    final hole = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
    final veilPath = Path.combine(
      PathOperation.difference,
      Path()..addRect(full),
      hole,
    );
    canvas.drawPath(veilPath, veil);

    final grow = 3 + pulse * 5;
    final ringRect = rect.inflate(grow);
    final ringPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        ringRect,
        Radius.circular(radius + grow),
      ));
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color =
          CozyColors.primary.withValues(alpha: (0.85 - pulse * 0.45) * opacity);
    canvas.drawPath(ringPath, ring);
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) =>
      old.rect != rect || old.pulse != pulse || old.opacity != opacity;
}
