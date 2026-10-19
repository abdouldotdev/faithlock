import 'package:flutter/material.dart';

import '../domain/garden_engine.dart';

/// Everything the renderer needs to draw a single plant at a moment in time.
/// Derived from a [Plot] + ambient season. Keeping this a plain value object is
/// what makes the rendering layer SWAPPABLE: the placeholder painter today, a
/// real GLB/sprite renderer once assets land — both consume [PlantVisual].
@immutable
class PlantVisual {
  final FruitMeta meta;

  /// 1..5 youth stage (Seed → Bearing fruit).
  final int stage;

  /// Endless tier (≥6 once mature), drives canopy fullness / extra layers.
  final int tier;

  /// Maturity boost (1.0 youth → 2.25 grove). A size/density multiplier.
  final double boost;

  /// 0 wilted (drooping, desaturated) → 1 lush & upright.
  final double health;

  /// A ripe harvest is ready to be shared (glow + fruit).
  final bool harvestReady;

  /// Selected by the user (ring + lift).
  final bool selected;

  /// Winter dormancy: deciduous species drop foliage; evergreens stay green.
  final bool bare;

  /// Raw internal growth (for fine-grained motion if a renderer wants it).
  final int growth;

  /// Dimmed (e.g. during onboarding element isolation).
  final bool dim;

  const PlantVisual({
    required this.meta,
    required this.stage,
    required this.tier,
    required this.boost,
    required this.health,
    required this.harvestReady,
    required this.selected,
    required this.bare,
    required this.growth,
    this.dim = false,
  });

  factory PlantVisual.fromPlot(
    Plot p, {
    required Season season,
    bool selected = false,
    bool dim = false,
  }) {
    final meta = kFruitByKey[p.fruit]!;
    final d = derive(p.growth);
    final bare = season == Season.winter && !meta.evergreen;
    return PlantVisual(
      meta: meta,
      stage: d.stage,
      tier: d.tier,
      boost: d.boost,
      health: 1.0, // health is garden-wide; the world layer overrides per draw
      harvestReady: p.harvestReady,
      selected: selected,
      bare: bare,
      growth: p.growth,
      dim: dim,
    );
  }

  PlantVisual copyWith({double? health, bool? selected, bool? dim, bool? bare}) {
    return PlantVisual(
      meta: meta,
      stage: stage,
      tier: tier,
      boost: boost,
      health: health ?? this.health,
      harvestReady: harvestReady,
      selected: selected ?? this.selected,
      bare: bare ?? this.bare,
      growth: growth,
      dim: dim ?? this.dim,
    );
  }
}

/// The swap point. Implement this once per asset backend.
///
/// [paint] draws the plant within [size], with its soil point at the bottom
/// centre (`Offset(size.width / 2, size.height)`), rising upward. [t] is a free
/// 0..1 ambient clock the renderer may use for idle sway.
abstract class PlantRenderer {
  const PlantRenderer();
  void paint(Canvas canvas, Size size, PlantVisual v, {double t = 0});
}

/// A minimal built-in renderer so the screen/world compile before Dev1's rich
/// [PlaceholderPlantRenderer] lands. Draws a simple soil mound + a growth-scaled
/// blob so states are visually distinguishable. Replace via the world layer.
class StubPlantRenderer extends PlantRenderer {
  const StubPlantRenderer();

  @override
  void paint(Canvas canvas, Size size, PlantVisual v, {double t = 0}) {
    final base = Offset(size.width / 2, size.height);
    final lush = v.health.clamp(0.0, 1.0);
    final color = Color.lerp(const Color(0xFFB89B45), v.meta.seed, lush)!;
    final h = (16 + v.stage * 18) * (0.7 + 0.3 * v.boost);
    final w = (10 + v.stage * 6).toDouble();
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: Offset(base.dx, base.dy - h / 2), width: w, height: h),
      const Radius.circular(8),
    );
    if (!v.bare) {
      canvas.drawRRect(body, Paint()..color = color.withValues(alpha: v.dim ? 0.4 : 1));
    }
    canvas.drawCircle(Offset(base.dx, base.dy - 1), w * 0.7,
        Paint()..color = const Color(0xFF6B4E37).withValues(alpha: 0.5));
    if (v.selected) {
      canvas.drawCircle(
        Offset(base.dx, base.dy - h * 0.4),
        w,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = const Color(0xFFD68A4E),
      );
    }
  }
}

/// Renders a single plant, with a gentle grow-pop whenever [popSignal] changes
/// and a slow idle sway. Tap forwards to [onTap]. The world passes the active
/// [renderer] (placeholder now, real assets later) — this widget never knows
/// which backend it is.
class GardenPlant extends StatefulWidget {
  final PlantVisual visual;
  final PlantRenderer renderer;
  final int popSignal;
  final Size size;
  final VoidCallback? onTap;

  const GardenPlant({
    super.key,
    required this.visual,
    this.renderer = const StubPlantRenderer(),
    this.popSignal = 0,
    this.size = const Size(96, 132),
    this.onTap,
  });

  @override
  State<GardenPlant> createState() => _GardenPlantState();
}

class _GardenPlantState extends State<GardenPlant>
    with TickerProviderStateMixin {
  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 460),
    value: 1,
  );

  @override
  void didUpdateWidget(covariant GardenPlant old) {
    super.didUpdateWidget(old);
    if (old.popSignal != widget.popSignal) {
      _pop.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _idle.dispose();
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_idle, _pop]),
        builder: (_, __) {
          final pop = Curves.elasticOut.transform(_pop.value);
          final scale = 0.8 + 0.2 * pop;
          return Transform.scale(
            alignment: Alignment.bottomCenter,
            scale: scale,
            child: CustomPaint(
              size: widget.size,
              painter: _PlantPainter(
                widget.renderer,
                widget.visual,
                _idle.value,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PlantPainter extends CustomPainter {
  final PlantRenderer renderer;
  final PlantVisual visual;
  final double t;
  _PlantPainter(this.renderer, this.visual, this.t);

  @override
  void paint(Canvas canvas, Size size) =>
      renderer.paint(canvas, size, visual, t: t);

  @override
  bool shouldRepaint(covariant _PlantPainter old) =>
      old.t != t ||
      old.visual.growth != visual.growth ||
      old.visual.health != visual.health ||
      old.visual.selected != visual.selected ||
      old.visual.harvestReady != visual.harvestReady ||
      old.visual.bare != visual.bare ||
      old.visual.dim != visual.dim;
}
