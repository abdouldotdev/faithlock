import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/grace_garden_controller.dart';
import '../domain/garden_engine.dart';
import '../render/placeholder_plant_renderer.dart';
import '../render/plant_renderer.dart';

/// OWNER: Dev1 (Rendering & World).
///
/// The full-screen Garden of Grace scene — a cozy low-relief diorama:
///   • a day/night sky driven by [GraceGardenController.timeOfDay] (sun/moon,
///     stars at night),
///   • a tilted planter bed with three depth rows (back rows sit smaller &
///     higher for perspective),
///   • a season tint wash over the whole scene,
///   • a floating ⓘ hint that points at the plants and vanishes after the first
///     tap (controller.tappedPlant),
///   • onboarding isolation: a real spotlight on controller.introFocus and a
///     vignette that hides the rest when controller.introSolo is set.
///
/// Plants are always drawn via [GardenPlant] + the supplied [renderer]
/// (PlaceholderPlantRenderer now, real assets later).
class GardenWorld extends StatelessWidget {
  final GraceGardenController c;
  final PlantRenderer renderer;
  final bool interactive;

  const GardenWorld({
    super.key,
    required this.c,
    this.renderer = const PlaceholderPlantRenderer(),
    this.interactive = true,
  });

  // Canonical 3×3 layout: back row (depth 0) → front row (depth 2).
  static const List<List<FruitKey>> _rows = [
    [FruitKey.love, FruitKey.joy, FruitKey.peace],
    [FruitKey.patience, FruitKey.kindness, FruitKey.goodness],
    [FruitKey.faithfulness, FruitKey.gentleness, FruitKey.selfcontrol],
  ];

  @override
  Widget build(BuildContext context) {
    // LayoutBuilder MUST be outside Obx: the Obx builder has to read every .value
    // synchronously in its own scope to register reactivity. If Obx wrapped the
    // LayoutBuilder, the reads would happen later in the layout callback (outside
    // the Obx scope) and GetX would throw "improper use of a GetX".
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final scene = Obx(
          () => Stack(
            fit: StackFit.expand,
            children: [
              _Sky(t: c.timeOfDay.value),
              _planterBed(c.timeOfDay.value),
              ..._depthRows(context, size),
              _SeasonTint(season: c.season.value),
              if (c.introSolo.value && c.introFocus.value != null)
                _spotlight(size),
              if (!c.tappedPlant.value && !c.introActive.value)
                _tapHint(size),
            ],
          ),
        );
        if (!interactive) return scene;
        return InteractiveViewer(
          minScale: 0.85,
          maxScale: 2.4,
          boundaryMargin: const EdgeInsets.all(40),
          child: scene,
        );
      },
    );
  }

  // ── Ground / planter bed ────────────────────────────────────────────────────

  Widget _planterBed(double timeOfDay) {
    final night = (timeOfDay - 0.5).abs() * 2;
    final grassTop = Color.lerp(
        const Color(0xFF9DBB73), const Color(0xFF2E3A24), night * 0.85)!;
    final grassBottom = Color.lerp(
        const Color(0xFF7E9A56), const Color(0xFF24301C), night * 0.85)!;
    final soil =
        Color.lerp(const Color(0xFF6B4E37), const Color(0xFF2C2016), night * 0.7)!;
    final soilDark = Color.lerp(
        const Color(0xFF553D2B), const Color(0xFF1F160E), night * 0.7)!;
    return Align(
      alignment: Alignment.bottomCenter,
      child: FractionallySizedBox(
        heightFactor: 0.66,
        child: CustomPaint(
          painter: _BedPainter(
            grassTop: grassTop,
            grassBottom: grassBottom,
            soil: soil,
            soilDark: soilDark,
          ),
        ),
      ),
    );
  }

  // ── Plants laid out in three depth rows ─────────────────────────────────────

  List<Widget> _depthRows(BuildContext context, Size size) {
    final solo = c.introSolo.value;
    final focus = c.introFocus.value;
    final health = (c.health.value / 100).clamp(0.0, 1.0);

    // Bed occupies the bottom ~66% of the scene. We place rows within it with a
    // gentle vertical perspective: back row higher & smaller, front row lower &
    // bigger.
    final bedTop = size.height * 0.34;
    final bedH = size.height - bedTop;

    // vertical band each row sits in (as a fraction of the bed height)
    const rowBands = [0.16, 0.40, 0.70];
    // scale per depth (back smaller)
    const rowScale = [0.74, 0.88, 1.06];
    // horizontal inset per depth (back row narrower → converging perspective)
    const rowInsetFrac = [0.20, 0.13, 0.05];

    final widgets = <Widget>[];
    for (var r = 0; r < _rows.length; r++) {
      final rowY = bedTop + bedH * rowBands[r];
      final inset = size.width * rowInsetFrac[r];
      final usableW = size.width - inset * 2;
      final cellW = usableW / 3;
      final plantW = (cellW * 0.86).clamp(40.0, 120.0) * rowScale[r];
      final plantH = plantW * 1.4;

      for (var col = 0; col < 3; col++) {
        final key = _rows[r][col];
        final cx = inset + cellW * (col + 0.5);
        widgets.add(
          Positioned(
            left: cx - plantW / 2,
            top: rowY - plantH,
            width: plantW,
            height: plantH,
            child: _plot(key, solo, focus, health, Size(plantW, plantH)),
          ),
        );
      }
    }
    return widgets;
  }

  Widget _plot(
      FruitKey key, bool solo, FruitKey? focus, double health, Size size) {
    final p = c.plots[key]!;
    final hidden = solo && focus != null && focus != key;
    final dim = focus != null && focus != key && !solo;
    final visual = PlantVisual.fromPlot(
      p,
      season: c.season.value,
      selected: c.selected.value == key,
      dim: dim,
    ).copyWith(health: health);
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOut,
      opacity: hidden ? 0 : 1,
      child: GardenPlant(
        visual: visual,
        renderer: renderer,
        popSignal: c.popSignal[key] ?? 0,
        size: size,
        onTap: () => c.select(c.selected.value == key ? null : key),
      ),
    );
  }

  // ── Onboarding spotlight ────────────────────────────────────────────────────

  /// Darken everything except a soft circle around the focused plant.
  Widget _spotlight(Size size) {
    final focus = c.introFocus.value;
    if (focus == null) return const SizedBox.shrink();
    // find the focused plant's screen position from the same layout math.
    final pos = _focusCenter(focus, size);
    return IgnorePointer(
      child: CustomPaint(
        size: size,
        painter: _SpotlightPainter(center: pos, radius: size.width * 0.24),
      ),
    );
  }

  Offset _focusCenter(FruitKey key, Size size) {
    final bedTop = size.height * 0.34;
    final bedH = size.height - bedTop;
    const rowBands = [0.16, 0.40, 0.70];
    const rowInsetFrac = [0.20, 0.13, 0.05];
    for (var r = 0; r < _rows.length; r++) {
      final col = _rows[r].indexOf(key);
      if (col < 0) continue;
      final inset = size.width * rowInsetFrac[r];
      final usableW = size.width - inset * 2;
      final cellW = usableW / 3;
      final cx = inset + cellW * (col + 0.5);
      final rowY = bedTop + bedH * rowBands[r];
      return Offset(cx, rowY - size.width * 0.12);
    }
    return Offset(size.width / 2, size.height / 2);
  }

  // ── Tap hint ────────────────────────────────────────────────────────────────

  /// A pulsing pill that points at the front-centre plant (Kindness/centre).
  Widget _tapHint(Size size) {
    // anchor near the centre-front plant so the arrow clearly points at a plant.
    final target = _focusCenter(FruitKey.kindness, size);
    return Positioned(
      left: target.dx - 70,
      top: target.dy - size.width * 0.34,
      width: 140,
      child: const IgnorePointer(child: _PulseInfo()),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sky
// ─────────────────────────────────────────────────────────────────────────────

class _Sky extends StatelessWidget {
  final double t; // 0 night · 0.5 noon · 1 night
  const _Sky({required this.t});

  @override
  Widget build(BuildContext context) {
    final night = (t - 0.5).abs() * 2; // 0 noon → 1 midnight
    final dawn = (1 - (t - 0.25).abs() * 4).clamp(0.0, 1.0); // warm at ~0.25
    final dusk = (1 - (t - 0.75).abs() * 4).clamp(0.0, 1.0); // warm at ~0.75
    final warm = math.max(dawn, dusk);

    var top = Color.lerp(const Color(0xFF8FC2E8), const Color(0xFF141B33), night)!;
    var bottom =
        Color.lerp(const Color(0xFFFBF3E2), const Color(0xFF2A2748), night)!;
    // dawn/dusk wash
    top = Color.lerp(top, const Color(0xFFE9A06B), warm * 0.5)!;
    bottom = Color.lerp(bottom, const Color(0xFFF6C99A), warm * 0.6)!;

    return CustomPaint(
      painter: _SkyPainter(top: top, bottom: bottom, night: night, t: t),
    );
  }
}

class _SkyPainter extends CustomPainter {
  final Color top;
  final Color bottom;
  final double night;
  final double t;
  _SkyPainter(
      {required this.top,
      required this.bottom,
      required this.night,
      required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top, bottom],
        ).createShader(rect),
    );

    // sun/moon traverses an arc across the top half as t goes 0→1.
    final arcX = size.width * t;
    final arcY = size.height * 0.30 +
        math.sin(t * math.pi) * -size.height * 0.18; // dips at noon
    final isDay = night < 0.5;
    final body = Offset(arcX, arcY);
    final r = size.width * 0.06;
    if (isDay) {
      canvas.drawCircle(
          body,
          r * 1.8,
          Paint()
            ..color = const Color(0xFFFFF1C9).withValues(alpha: 0.5)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22));
      canvas.drawCircle(body, r, Paint()..color = const Color(0xFFFDE7A6));
    } else {
      canvas.drawCircle(
          body,
          r * 1.6,
          Paint()
            ..color = const Color(0xFFDCE6FF).withValues(alpha: 0.35)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18));
      canvas.drawCircle(body, r * 0.9, Paint()..color = const Color(0xFFEDF1FF));
      // crescent shadow
      canvas.drawCircle(body + Offset(r * 0.4, -r * 0.3), r * 0.85,
          Paint()..color = top);
    }

    // stars at night
    if (night > 0.45) {
      final sa = ((night - 0.45) / 0.55).clamp(0.0, 1.0);
      final rng = math.Random(7);
      final star = Paint()..color = Colors.white;
      for (var i = 0; i < 46; i++) {
        final x = rng.nextDouble() * size.width;
        final y = rng.nextDouble() * size.height * 0.55;
        final twinkle = 0.4 + 0.6 * ((math.sin(i * 12.9 + t * 6) + 1) / 2);
        star.color = Colors.white.withValues(alpha: sa * twinkle * 0.9);
        canvas.drawCircle(Offset(x, y), rng.nextDouble() * 1.4 + 0.4, star);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SkyPainter old) =>
      old.t != t || old.top != top || old.bottom != bottom;
}

// ─────────────────────────────────────────────────────────────────────────────
// Planter bed
// ─────────────────────────────────────────────────────────────────────────────

class _BedPainter extends CustomPainter {
  final Color grassTop;
  final Color grassBottom;
  final Color soil;
  final Color soilDark;
  _BedPainter({
    required this.grassTop,
    required this.grassBottom,
    required this.soil,
    required this.soilDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // grassy rolling hill across the back third
    final grass = Path()
      ..moveTo(0, h * 0.22)
      ..quadraticBezierTo(w * 0.5, h * 0.10, w, h * 0.20)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      grass,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [grassTop, grassBottom],
        ).createShader(Offset.zero & size),
    );

    // soil planter bed: a gently trapezoidal raised bed (perspective).
    final bedTop = h * 0.34;
    final bed = Path()
      ..moveTo(w * 0.10, bedTop)
      ..lineTo(w * 0.90, bedTop)
      ..lineTo(w * 1.02, h)
      ..lineTo(w * -0.02, h)
      ..close();
    canvas.drawPath(
      bed,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [soil, soilDark],
        ).createShader(Rect.fromLTRB(0, bedTop, w, h)),
    );

    // bed front lip highlight
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.10, bedTop)
        ..lineTo(w * 0.90, bedTop),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = grassBottom.withValues(alpha: 0.6),
    );

    // soil furrow rows to sell depth
    final furrow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = soilDark.withValues(alpha: 0.5);
    for (final f in [0.50, 0.72, 0.92]) {
      final y = bedTop + (h - bedTop) * f;
      final spread = (f - 0.34) * w * 0.6;
      canvas.drawLine(
          Offset(w * 0.10 - spread * 0.2, y), Offset(w * 0.90 + spread * 0.2, y), furrow);
    }
  }

  @override
  bool shouldRepaint(covariant _BedPainter old) =>
      old.grassTop != grassTop ||
      old.soil != soil ||
      old.grassBottom != grassBottom;
}

// ─────────────────────────────────────────────────────────────────────────────
// Season tint
// ─────────────────────────────────────────────────────────────────────────────

class _SeasonTint extends StatelessWidget {
  final Season season;
  const _SeasonTint({required this.season});

  @override
  Widget build(BuildContext context) {
    final (Color color, double alpha) = switch (season) {
      Season.spring => (const Color(0xFFB7E0A8), 0.06),
      Season.summer => (const Color(0xFFFFE9A8), 0.05),
      Season.autumn => (const Color(0xFFE89B5A), 0.12),
      Season.winter => (const Color(0xFFBFD4E8), 0.16),
    };
    return IgnorePointer(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        color: color.withValues(alpha: alpha),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Onboarding spotlight
// ─────────────────────────────────────────────────────────────────────────────

class _SpotlightPainter extends CustomPainter {
  final Offset center;
  final double radius;
  _SpotlightPainter({required this.center, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final shade = Paint()
      ..shader = RadialGradient(
        colors: const [Colors.transparent, Color(0xCC1A130C)],
        stops: const [0.0, 1.0],
      ).createShader(
        Rect.fromCircle(center: center, radius: radius * 2.2),
      );
    canvas.drawRect(rect, shade);
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter old) =>
      old.center != center || old.radius != radius;
}

// ─────────────────────────────────────────────────────────────────────────────
// Tap hint
// ─────────────────────────────────────────────────────────────────────────────

/// A pulsing ⓘ pill above a plant, with a little arrow pointing down at it.
class _PulseInfo extends StatefulWidget {
  const _PulseInfo();
  @override
  State<_PulseInfo> createState() => _PulseInfoState();
}

class _PulseInfoState extends State<_PulseInfo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _a = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      builder: (_, __) {
        final v = Curves.easeInOut.transform(_a.value);
        return Opacity(
          opacity: 0.55 + 0.45 * v,
          child: Transform.translate(
            offset: Offset(0, -4 + v * 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xE63D2B1F),
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Text(
                    'ⓘ  tap a plant',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // downward arrow pointing at the plant
                CustomPaint(
                  size: const Size(16, 9),
                  painter: _ArrowPainter(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(p, Paint()..color = const Color(0xE63D2B1F));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
