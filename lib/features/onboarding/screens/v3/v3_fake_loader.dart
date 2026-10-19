import 'dart:math' as math;

import 'package:faithlock/features/onboarding/utils/animation_utils.dart';
import 'package:faithlock/features/onboarding/widgets/onboarding_wrapper.dart';
import 'package:faithlock/shared/widgets/cozy/cozy.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

/// V3 Fake Loader — cozy rebuild. Centered terracotta gauge with a soft
/// pulsing halo + trust footer on the cream canvas.
class V3FakeLoader extends StatefulWidget {
  final VoidCallback onComplete;
  const V3FakeLoader({super.key, required this.onComplete});

  @override
  State<V3FakeLoader> createState() => _V3FakeLoaderState();
}

class _V3FakeLoaderState extends State<V3FakeLoader>
    with TickerProviderStateMixin {
  static const _totalDuration = Duration(milliseconds: 5400);

  late final AnimationController _progress;

  @override
  void initState() {
    super.initState();

    _progress = AnimationController(vsync: this, duration: _totalDuration)
      ..addStatusListener((status) async {
        if (status == AnimationStatus.completed && mounted) {
          await AnimationUtils.heavyHaptic();
          widget.onComplete();
        }
      })
      ..forward();
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingWrapper(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Gauge(controller: _progress),
                    const SizedBox(height: CozyTokens.space32),
                    Text(
                      'onbFakeLoader_mainTitle'.tr,
                      style: CozyText.title,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const _TrustFooter(),
            const SizedBox(height: CozyTokens.space24),
          ],
        ),
      ),
    );
  }
}

/// Terracotta circular gauge with animated percentage at the center.
class _Gauge extends StatelessWidget {
  final AnimationController controller;
  const _Gauge({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final v = controller.value;
        final pct = (v * 100).clamp(0, 100).round();
        return SizedBox(
          width: 232,
          height: 232,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(220, 220),
                painter: _GaugePainter(progress: v),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$pct',
                    style: CozyText.display.copyWith(
                      fontSize: 76,
                      letterSpacing: -2,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Text(
                      '%',
                      style: CozyText.heading.copyWith(
                        color: CozyColors.primary,
                        fontSize: 30,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double progress;
  _GaugePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 8;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Track — cozy surface-muted.
    final track = Paint()
      ..color = CozyColors.surfaceMuted
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);

    if (progress <= 0) return;

    // Terracotta gradient arc.
    final sweep = progress * 2 * math.pi;
    final shader = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: -math.pi / 2 + sweep,
      colors: const [
        CozyColors.primaryLight,
        CozyColors.primary,
        CozyColors.primaryDark,
      ],
      tileMode: TileMode.clamp,
    ).createShader(rect);

    final arc = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -math.pi / 2, sweep, false, arc);

    // Leading dot at the tip of the arc.
    final tipAngle = -math.pi / 2 + sweep;
    final tip = Offset(
      center.dx + radius * math.cos(tipAngle),
      center.dy + radius * math.sin(tipAngle),
    );
    final tipBorder = Paint()..color = CozyColors.surface;
    canvas.drawCircle(tip, 9, tipBorder);
    final tipPaint = Paint()..color = CozyColors.primary;
    canvas.drawCircle(tip, 7, tipPaint);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Privacy reassurance footer (lock chip + two short lines).
class _TrustFooter extends StatelessWidget {
  const _TrustFooter();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: ShapeDecoration(
            color: CozyColors.surface,
            shape: const CircleBorder(
              side: BorderSide(
                color: CozyColors.outline,
                width: CozyTokens.borderWidth,
              ),
            ),
          ),
          child: const Icon(
            CupertinoIcons.lock_fill,
            color: CozyColors.ink,
            size: 16,
          ),
        ),
        const SizedBox(height: CozyTokens.space12),
        Text(
          'onbFakeLoader_trustTitle'.tr,
          style: CozyText.body.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          'onbFakeLoader_trustSubtitle'.tr,
          style: CozyText.subtitle,
        ),
      ],
    );
  }
}
