import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/garden_engine.dart';
import 'plant_renderer.dart';

/// OWNER: Dev1 (Rendering & World).
///
/// Procedural placeholder rendering until real 3D/sprite assets land. Each of the
/// nine Fruits draws a recognisable silhouette keyed off [PlantVisual.meta.archetype]
/// (flower / tree / pine / willow / bush / vine), tinted with [meta.seed].
///
/// Honoured states (per the renderer contract):
///   • stage 1..5      seed → sprout → growing → blossoming → bearing fruit
///   • tier / boost    endless maturity: fuller, taller canopies (boost up to 2.25)
///   • health 0..1     wilt = droop + desaturation toward dry straw
///   • harvestReady    a warm glow + visible ripe fruit
///   • selected        a lift + terracotta ring under the plant
///   • bare            winter dormancy for deciduous; evergreens (meta.evergreen) stay green
///   • dim             onboarding isolation (drawn faded)
///
/// Everything is painted from the soil point at the bottom-centre of [size],
/// rising upward, so the world layer can place it anywhere. [t] is a 0..1 ambient
/// clock used for tiny per-element life (twinkle, sway is already applied by the
/// GardenPlant widget).
class PlaceholderPlantRenderer extends PlantRenderer {
  const PlaceholderPlantRenderer();

  // Warm shared ink, matching the cozy / garden_plant palette.
  static const Color _ink = Color(0xFF3D2B1F);
  static const Color _bark = Color(0xFF6B4E37);
  static const Color _barkDark = Color(0xFF553D2B);
  static const Color _dry = Color(0xFFB89B45); // wilt straw
  static const Color _soil = Color(0xFF5A4029);

  @override
  void paint(Canvas canvas, Size size, PlantVisual v, {double t = 0}) {
    final base = Offset(size.width / 2, size.height);
    final unit = size.width / 96; // design space is ~96px wide
    final health = v.health.clamp(0.0, 1.0);
    final alpha = v.dim ? 0.4 : 1.0;

    // Selection: a soft terracotta ring under the plant (the lift itself is done
    // by GardenPlant's scale; here we anchor it to the ground).
    if (v.selected) {
      _selectionRing(canvas, base, size, unit, alpha);
    }

    // A small soil mound so the plant feels planted, not floating.
    _soilMound(canvas, base, unit, alpha);

    // Stage→progress so very young plants are clearly seedlings.
    // 1:Seed 2:Sprouting 3:Growing 4:Blossoming 5:Bearing fruit, then tier adds
    // body via [boost].
    final stageF = ((v.stage - 1) / 4).clamp(0.0, 1.0);
    final maturity = stageF; // 0..1 within youth
    final boost = v.boost.clamp(1.0, 2.25);

    if (v.stage <= 1 && !v.harvestReady) {
      // A literal seed/sprout regardless of archetype — nothing has emerged yet.
      _seedling(canvas, base, unit, health, alpha, t);
      return;
    }

    final ctx = _PlantCtx(
      canvas: canvas,
      base: base,
      unit: unit,
      maturity: maturity,
      boost: boost,
      health: health,
      stage: v.stage,
      bare: v.bare,
      evergreen: v.meta.evergreen,
      seed: v.meta.seed,
      harvestReady: v.harvestReady,
      alpha: alpha,
      t: t,
    );

    switch (v.meta.archetype) {
      case PlantArchetype.flower:
        _flowerSpecies(ctx);
        break;
      case PlantArchetype.tree:
        _treeSpecies(ctx);
        break;
      case PlantArchetype.pine:
        _pineSpecies(ctx);
        break;
      case PlantArchetype.willow:
        _willowSpecies(ctx);
        break;
      case PlantArchetype.bush:
        _bushSpecies(ctx);
        break;
      case PlantArchetype.vine:
        _vineSpecies(ctx);
        break;
    }
  }

  // ── Shared helpers ──────────────────────────────────────────────────────────

  /// Desaturate + dry a foliage color as health falls.
  Color _foliage(Color seed, double health) {
    return Color.lerp(_dry, seed, health.clamp(0.0, 1.0))!;
  }

  Paint _fill(Color c, double alpha) =>
      Paint()..color = c.withValues(alpha: c.a * alpha);

  Paint _outline(double w, double alpha, [Color? color]) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round
    ..color = (color ?? _ink).withValues(alpha: alpha);

  void _selectionRing(
      Canvas canvas, Offset base, Size size, double unit, double alpha) {
    final ringRect = Rect.fromCenter(
      center: Offset(base.dx, base.dy - 2 * unit),
      width: size.width * 0.62,
      height: size.width * 0.22,
    );
    canvas.drawOval(
      ringRect,
      Paint()
        ..color = const Color(0xFFD68A4E).withValues(alpha: 0.22 * alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawOval(
      ringRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4 * unit
        ..color = const Color(0xFFD68A4E).withValues(alpha: 0.9 * alpha),
    );
  }

  void _soilMound(Canvas canvas, Offset base, double unit, double alpha) {
    final r = Rect.fromCenter(
      center: Offset(base.dx, base.dy),
      width: 30 * unit,
      height: 11 * unit,
    );
    canvas.drawOval(r, _fill(_soil, alpha));
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(base.dx, base.dy - 1.5 * unit),
          width: 24 * unit,
          height: 7 * unit),
      _fill(const Color(0xFF6E4E30), alpha),
    );
  }

  /// A trunk/stem rising from base to [top], thicker at maturity.
  Offset _trunk(_PlantCtx c, double height, double thickness,
      {double leanX = 0, Color? color}) {
    final base = c.base;
    final droop = (1 - c.health) * 0.5;
    final top = Offset(base.dx + leanX, base.dy - height);
    final ctrl = Offset(
      base.dx + leanX * 0.4 + droop * 8 * c.unit,
      base.dy - height * 0.5 + droop * height * 0.18,
    );
    final stem = Path()
      ..moveTo(base.dx, base.dy)
      ..quadraticBezierTo(ctrl.dx, ctrl.dy, top.dx, top.dy);
    c.canvas.drawPath(
      stem,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness
        ..strokeCap = StrokeCap.round
        ..color = (color ?? _bark).withValues(alpha: c.alpha),
    );
    return top;
  }

  /// A ripe fruit nub used by harvest-ready species.
  void _ripeFruit(Canvas canvas, Offset center, double r, Color seed,
      double alpha, double t) {
    final rect = Rect.fromCircle(center: center, radius: r);
    final hot = Color.lerp(seed, Colors.white, 0.18)!.withValues(alpha: alpha);
    final cool = Color.lerp(seed, _ink, 0.25)!.withValues(alpha: alpha);
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.4),
          colors: [hot, cool],
        ).createShader(rect),
    );
    canvas.drawCircle(center, r, _outline(1.4, alpha));
    canvas.drawCircle(center + Offset(-r * 0.35, -r * 0.4), r * 0.24,
        Paint()..color = Colors.white.withValues(alpha: 0.6 * alpha));
  }

  /// Warm halo behind harvest-ready plants.
  void _harvestGlow(Canvas canvas, Offset center, double radius, double alpha,
      double t) {
    final pulse = 0.5 + 0.5 * math.sin(t * math.pi * 2);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFFF8E6BE)
            .withValues(alpha: (0.30 + 0.12 * pulse) * alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
  }

  /// A leafy blob (used by trees/bushes for canopy lumps).
  void _blob(Canvas canvas, Offset center, double rx, double ry, Color c,
      double alpha) {
    canvas.drawOval(
      Rect.fromCenter(center: center, width: rx * 2, height: ry * 2),
      _fill(c, alpha),
    );
    canvas.drawOval(
      Rect.fromCenter(center: center, width: rx * 2, height: ry * 2),
      _outline(1.6, alpha),
    );
  }

  // ── Seed / sprout (stage 1) ─────────────────────────────────────────────────

  void _seedling(Canvas canvas, Offset base, double unit, double health,
      double alpha, double t) {
    // a tiny curled sprout — two cotyledon leaves on a short stem.
    final stemH = 12 * unit;
    final top = Offset(base.dx, base.dy - stemH);
    canvas.drawPath(
      Path()
        ..moveTo(base.dx, base.dy - 1)
        ..quadraticBezierTo(
            base.dx - 3 * unit, base.dy - stemH * 0.6, top.dx, top.dy),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6 * unit
        ..strokeCap = StrokeCap.round
        ..color = _foliage(const Color(0xFF6E8B4E), health)
            .withValues(alpha: alpha),
    );
    for (final s in [-1.0, 1.0]) {
      final tip = top + Offset(s * 9 * unit, -3 * unit);
      _leafShape(canvas, top, tip, 3.4 * unit,
          _foliage(const Color(0xFF7FA055), health), alpha);
    }
  }

  /// A single pointed leaf from [a] to [b] with given half-[width].
  void _leafShape(Canvas canvas, Offset a, Offset b, double width, Color color,
      double alpha) {
    final dir = b - a;
    final len = dir.distance;
    if (len < 0.5) return;
    final mid = a + dir * 0.5;
    final normal = Offset(-dir.dy, dir.dx) / len;
    final c1 = mid + normal * width;
    final c2 = mid - normal * width;
    final leaf = Path()
      ..moveTo(a.dx, a.dy)
      ..quadraticBezierTo(c1.dx, c1.dy, b.dx, b.dy)
      ..quadraticBezierTo(c2.dx, c2.dy, a.dx, a.dy)
      ..close();
    canvas.drawPath(leaf, _fill(color, alpha));
    canvas.drawPath(leaf, _outline(1.4, alpha));
  }

  // ── FLOWER (Love, Joy) ──────────────────────────────────────────────────────
  // A slender stalk crowned with a big bloom + a couple of buds. Stage drives how
  // open the bloom is; harvest = an extra ripe pod.
  void _flowerSpecies(_PlantCtx c) {
    final h = (28 + c.maturity * 46) * c.boost * c.unit;
    final stemColor = _foliage(const Color(0xFF6E8B4E), c.health);
    final top = _trunk(c, h, (2.6 + c.boost) * c.unit, color: stemColor);

    // a pair of low leaves
    for (final s in [-1.0, 1.0]) {
      final at = Offset(c.base.dx, c.base.dy - h * 0.4);
      final tip = at + Offset(s * 12 * c.unit, -4 * c.unit);
      _leafShape(c.canvas, at, tip, 4 * c.unit, stemColor, c.alpha);
    }

    if (c.bare) {
      // deciduous flower in winter: just the dry stalk + a seed head.
      c.canvas.drawCircle(top, 4 * c.unit, _fill(const Color(0xFF8A7A52), c.alpha));
      c.canvas.drawCircle(top, 4 * c.unit, _outline(1.4, c.alpha));
      return;
    }

    final petalColor = c.seed;
    final open = (c.maturity).clamp(0.0, 1.0);
    final r = (5 + 6 * open) * c.boost * c.unit;

    if (c.harvestReady) {
      _harvestGlow(c.canvas, top, r * 2.4, c.alpha, c.t);
    }

    // budding side blooms once growing
    if (c.maturity > 0.25) {
      for (final s in [-1.0, 1.0]) {
        final bud = Offset(c.base.dx + s * 11 * c.unit, c.base.dy - h * 0.62);
        _bloom(c.canvas, bud, r * 0.5, petalColor, c.health, c.alpha, petals: 5);
      }
    }
    // the crown bloom
    _bloom(c.canvas, top, r, petalColor, c.health, c.alpha,
        petals: 6, open: open);

    if (c.harvestReady) {
      _ripeFruit(c.canvas, top + Offset(0, r * 0.2), r * 0.4,
          Color.lerp(petalColor, const Color(0xFFCC4E32), 0.4)!, c.alpha, c.t);
    }
  }

  void _bloom(Canvas canvas, Offset center, double r, Color color, double health,
      double alpha,
      {int petals = 6, double open = 1.0}) {
    final petalColor = _foliage(color, 0.4 + health * 0.6);
    final spread = 0.55 + open * 0.55;
    for (var i = 0; i < petals; i++) {
      final a = (i / petals) * math.pi * 2;
      final pc = center + Offset(math.cos(a), math.sin(a)) * r * spread;
      canvas.drawCircle(pc, r * 0.62, _fill(petalColor, alpha));
      canvas.drawCircle(pc, r * 0.62, _outline(1.2, alpha));
    }
    canvas.drawCircle(center, r * 0.5, _fill(const Color(0xFFC9A962), alpha));
    canvas.drawCircle(center, r * 0.5, _outline(1.2, alpha));
  }

  // ── TREE (Peace, Patience, Goodness) ────────────────────────────────────────
  // A sturdy trunk with a rounded multi-lump canopy. Tier/boost grows the canopy
  // taller & fuller. Peace is evergreen (stays green in winter).
  void _treeSpecies(_PlantCtx c) {
    final trunkH = (26 + c.maturity * 40) * c.boost * c.unit;
    final thickness = (4 + c.boost * 2.4) * c.unit;
    final top = _trunk(c, trunkH, thickness);

    final foliage = _foliage(c.seed, c.health);
    final canopyR = (16 + c.maturity * 10) * c.boost * c.unit;

    if (c.bare && !c.evergreen) {
      _bareBranches(c, top, canopyR);
      return;
    }

    if (c.harvestReady) {
      _harvestGlow(c.canvas, Offset(top.dx, top.dy - canopyR * 0.4),
          canopyR * 1.5, c.alpha, c.t);
    }

    // back canopy (darker) then front lumps for depth + fullness by tier.
    final dark = Color.lerp(foliage, _ink, 0.22)!;
    _blob(c.canvas, Offset(top.dx, top.dy - canopyR * 0.5), canopyR * 1.05,
        canopyR * 0.95, dark, c.alpha);

    final lumps = 3 + (c.boost - 1).round().clamp(0, 3);
    for (var i = 0; i < lumps; i++) {
      final a = math.pi + (i / (lumps - 1)) * math.pi;
      final off = Offset(math.cos(a), math.sin(a) * 0.7) * canopyR * 0.6;
      _blob(
        c.canvas,
        Offset(top.dx + off.dx, top.dy - canopyR * 0.5 + off.dy),
        canopyR * 0.62,
        canopyR * 0.58,
        foliage,
        c.alpha,
      );
    }
    _blob(c.canvas, Offset(top.dx, top.dy - canopyR * 0.75), canopyR * 0.7,
        canopyR * 0.62, Color.lerp(foliage, Colors.white, 0.12)!, c.alpha);

    if (c.harvestReady) {
      final rng = math.Random(c.seed.toARGB32());
      for (var i = 0; i < 3 + (c.boost).round(); i++) {
        final fx = top.dx + (rng.nextDouble() - 0.5) * canopyR * 1.4;
        final fy = top.dy - canopyR * 0.5 + (rng.nextDouble() - 0.4) * canopyR;
        _ripeFruit(c.canvas, Offset(fx, fy), 3.4 * c.boost * c.unit,
            Color.lerp(c.seed, const Color(0xFFCC4E32), 0.5)!, c.alpha, c.t);
      }
    }
  }

  void _bareBranches(_PlantCtx c, Offset top, double canopyR) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * c.unit
      ..strokeCap = StrokeCap.round
      ..color = _barkDark.withValues(alpha: c.alpha);
    for (final s in [-1.0, -0.4, 0.4, 1.0]) {
      final tip = Offset(top.dx + s * canopyR * 0.9, top.dy - canopyR * 0.8);
      c.canvas.drawLine(top, tip, p);
      final tip2 = tip + Offset(s * canopyR * 0.3, -canopyR * 0.4);
      c.canvas.drawLine(tip, tip2, p);
    }
  }

  // ── PINE (Faithfulness) ─────────────────────────────────────────────────────
  // A conifer: stacked triangular tiers on a short trunk. Evergreen — keeps its
  // green in winter. Extra tiers stack as boost climbs.
  void _pineSpecies(_PlantCtx c) {
    final totalH = (34 + c.maturity * 46) * c.boost * c.unit;
    final trunkH = 8 * c.unit;
    _trunk(c, trunkH, 4 * c.unit, color: _barkDark);

    final foliage = _foliage(c.seed, c.health);
    final tiers = 3 + (c.boost - 1).round().clamp(0, 3);
    final coneTop = c.base.dy - trunkH - (totalH - trunkH);
    final coneBottom = c.base.dy - trunkH;
    final span = coneBottom - coneTop;

    if (c.harvestReady) {
      _harvestGlow(c.canvas, Offset(c.base.dx, coneTop + span * 0.4),
          totalH * 0.6, c.alpha, c.t);
    }

    for (var i = 0; i < tiers; i++) {
      final f = i / tiers;
      final fNext = (i + 1) / tiers;
      final yTop = coneTop + span * f;
      final yBot = coneTop + span * fNext + span * 0.06;
      final w = (8 + f * 26) * c.boost * c.unit;
      final shade = Color.lerp(foliage, _ink, 0.05 + f * 0.12)!;
      final tri = Path()
        ..moveTo(c.base.dx, yTop)
        ..lineTo(c.base.dx - w, yBot)
        ..lineTo(c.base.dx + w, yBot)
        ..close();
      c.canvas.drawPath(tri, _fill(shade, c.alpha));
      c.canvas.drawPath(tri, _outline(1.6, c.alpha));
    }
    // a little star/tip
    c.canvas.drawCircle(Offset(c.base.dx, coneTop),
        2.2 * c.boost * c.unit, _fill(Color.lerp(foliage, Colors.white, 0.2)!, c.alpha));

    if (c.harvestReady) {
      // pinecones / ornaments
      final rng = math.Random(99);
      for (var i = 0; i < 3 + c.boost.round(); i++) {
        final yy = coneTop + span * (0.3 + rng.nextDouble() * 0.6);
        final xx = c.base.dx + (rng.nextDouble() - 0.5) * span * 0.4;
        _ripeFruit(c.canvas, Offset(xx, yy), 3 * c.boost * c.unit,
            const Color(0xFFB5732E), c.alpha, c.t);
      }
    }
  }

  // ── WILLOW (Gentleness) ─────────────────────────────────────────────────────
  // A graceful arching crown with long trailing fronds that sway. Deciduous.
  void _willowSpecies(_PlantCtx c) {
    final trunkH = (24 + c.maturity * 34) * c.boost * c.unit;
    final top = _trunk(c, trunkH, (4 + c.boost * 1.8) * c.unit);
    final foliage = _foliage(c.seed, c.health);
    final crownR = (14 + c.maturity * 8) * c.boost * c.unit;

    if (c.harvestReady) {
      _harvestGlow(
          c.canvas, Offset(top.dx, top.dy), crownR * 1.6, c.alpha, c.t);
    }

    // rounded crown
    if (!(c.bare && !c.evergreen)) {
      _blob(c.canvas, Offset(top.dx, top.dy - crownR * 0.3), crownR,
          crownR * 0.7, Color.lerp(foliage, _ink, 0.18)!, c.alpha);
      _blob(c.canvas, Offset(top.dx, top.dy - crownR * 0.5), crownR * 0.8,
          crownR * 0.55, foliage, c.alpha);
    } else {
      _bareBranches(c, top, crownR);
      return;
    }

    // trailing fronds — long droopy lines, swaying with t.
    final fronds = 6 + (c.boost - 1).round().clamp(0, 4);
    final sway = math.sin(c.t * math.pi * 2) * 3 * c.unit;
    for (var i = 0; i < fronds; i++) {
      final fx = top.dx - crownR + (i / (fronds - 1)) * crownR * 2;
      final originY = top.dy - crownR * 0.2;
      final len = crownR * (0.9 + 0.5 * (1 - (fx - top.dx).abs() / crownR));
      final endX = fx + sway * (0.4 + 0.6 * (i / fronds));
      final path = Path()
        ..moveTo(fx, originY)
        ..quadraticBezierTo(
            fx + 2 * c.unit, originY + len * 0.6, endX, originY + len);
      c.canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 * c.unit
          ..strokeCap = StrokeCap.round
          ..color = Color.lerp(foliage, _ink, 0.05)!
              .withValues(alpha: 0.9 * c.alpha),
      );
    }

    if (c.harvestReady) {
      _ripeFruit(c.canvas, Offset(top.dx, top.dy - crownR * 0.3),
          3.4 * c.boost * c.unit, c.seed, c.alpha, c.t);
    }
  }

  // ── BUSH (Kindness) ─────────────────────────────────────────────────────────
  // A low, wide, rounded shrub of clustered foliage lumps, dotted with small
  // blossoms. Deciduous (goes to twiggy mound in winter).
  void _bushSpecies(_PlantCtx c) {
    final w = (20 + c.maturity * 14) * c.boost * c.unit;
    final h = (16 + c.maturity * 12) * c.boost * c.unit;
    final center = Offset(c.base.dx, c.base.dy - h * 0.55);
    final foliage = _foliage(c.seed, c.health);

    if (c.bare) {
      // twiggy dormant mound
      final p = _outline(1.8 * c.unit, c.alpha, _barkDark);
      for (final s in [-1.0, -0.3, 0.3, 1.0]) {
        c.canvas.drawLine(c.base,
            Offset(c.base.dx + s * w * 0.7, c.base.dy - h * 0.9), p);
      }
      return;
    }

    if (c.harvestReady) {
      _harvestGlow(c.canvas, center, w * 1.2, c.alpha, c.t);
    }

    // back lumps darker, front lighter — a rounded cushion.
    final dark = Color.lerp(foliage, _ink, 0.2)!;
    _blob(c.canvas, center, w, h, dark, c.alpha);
    final lumps = 4 + (c.boost - 1).round().clamp(0, 3);
    final rng = math.Random(c.seed.toARGB32() ^ 0x55);
    for (var i = 0; i < lumps; i++) {
      final lx = center.dx + (rng.nextDouble() - 0.5) * w * 1.3;
      final ly = center.dy - rng.nextDouble() * h * 0.7;
      _blob(c.canvas, Offset(lx, ly), w * 0.42, h * 0.46, foliage, c.alpha);
    }

    // small blossoms once blossoming
    if (c.maturity > 0.4) {
      for (var i = 0; i < 4 + c.boost.round(); i++) {
        final bx = center.dx + (rng.nextDouble() - 0.5) * w * 1.2;
        final by = center.dy - rng.nextDouble() * h;
        _bloom(c.canvas, Offset(bx, by), 2.4 * c.unit,
            Color.lerp(c.seed, Colors.white, 0.35)!, c.health, c.alpha,
            petals: 5);
      }
    }

    if (c.harvestReady) {
      for (var i = 0; i < 3 + c.boost.round(); i++) {
        final bx = center.dx + (rng.nextDouble() - 0.5) * w;
        final by = center.dy - rng.nextDouble() * h * 0.8;
        _ripeFruit(c.canvas, Offset(bx, by), 2.8 * c.boost * c.unit,
            Color.lerp(c.seed, const Color(0xFFCC4E32), 0.4)!, c.alpha, c.t);
      }
    }
  }

  // ── VINE (Self-control) ─────────────────────────────────────────────────────
  // A climbing, twining stem on a small trellis, with paired leaves and grape-like
  // clusters at harvest. Deciduous.
  void _vineSpecies(_PlantCtx c) {
    final h = (30 + c.maturity * 50) * c.boost * c.unit;
    final foliage = _foliage(c.seed, c.health);

    // faint trellis posts behind
    final post = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * c.unit
      ..strokeCap = StrokeCap.round
      ..color = _bark.withValues(alpha: 0.5 * c.alpha);
    for (final s in [-1.0, 1.0]) {
      c.canvas.drawLine(Offset(c.base.dx + s * 8 * c.unit, c.base.dy),
          Offset(c.base.dx + s * 8 * c.unit, c.base.dy - h), post);
    }

    // twining stem: a sine wave climbing up
    final stem = Path()..moveTo(c.base.dx, c.base.dy);
    const steps = 14;
    final droop = (1 - c.health) * 6 * c.unit;
    final nodes = <Offset>[];
    for (var i = 1; i <= steps; i++) {
      final f = i / steps;
      final y = c.base.dy - h * f;
      final x = c.base.dx + math.sin(f * math.pi * 3) * 9 * c.unit + droop * f;
      stem.lineTo(x, y);
      nodes.add(Offset(x, y));
    }
    c.canvas.drawPath(
      stem,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = (2.4 + c.boost) * c.unit
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = Color.lerp(foliage, _ink, 0.1)!.withValues(alpha: c.alpha),
    );

    if (c.bare) {
      // dormant: bare twining stem only.
      return;
    }

    if (c.harvestReady) {
      _harvestGlow(c.canvas, Offset(c.base.dx, c.base.dy - h * 0.6),
          h * 0.5, c.alpha, c.t);
    }

    // paired leaves at every other node
    for (var i = 0; i < nodes.length; i += 2) {
      final n = nodes[i];
      final s = i.isEven ? 1.0 : -1.0;
      _vineLeaf(c.canvas, n, s * (8 + c.boost * 2) * c.unit, foliage, c.alpha);
    }

    // grape-like clusters at harvest
    if (c.harvestReady || c.maturity > 0.7) {
      final clusterColor = c.harvestReady
          ? c.seed
          : Color.lerp(c.seed, _foliage(c.seed, c.health), 0.5)!;
      for (final idx in [3, 8]) {
        if (idx < nodes.length) {
          _grapeCluster(c.canvas, nodes[idx] + Offset(0, 4 * c.unit),
              c.boost * c.unit, clusterColor, c.alpha);
        }
      }
    }
  }

  void _vineLeaf(Canvas canvas, Offset at, double dx, Color color, double alpha) {
    // a small lobed (heart-ish) leaf
    final tip = at + Offset(dx, -2);
    _leafShape(canvas, at, tip, dx.abs() * 0.5, color, alpha);
  }

  void _grapeCluster(
      Canvas canvas, Offset top, double unit, Color color, double alpha) {
    final positions = [
      Offset(0, 0),
      Offset(-3 * unit, 2.6 * unit),
      Offset(3 * unit, 2.6 * unit),
      Offset(0, 4.5 * unit),
      Offset(-2 * unit, 6.5 * unit),
      Offset(2 * unit, 6.5 * unit),
      Offset(0, 8.5 * unit),
    ];
    for (final p in positions) {
      final cc = top + p;
      canvas.drawCircle(cc, 2.6 * unit, _fill(color, alpha));
      canvas.drawCircle(cc, 2.6 * unit, _outline(1.1, alpha));
      canvas.drawCircle(cc + Offset(-unit * 0.7, -unit * 0.7), unit * 0.7,
          Paint()..color = Colors.white.withValues(alpha: 0.5 * alpha));
    }
  }
}

/// Per-draw bundle so species methods stay terse.
class _PlantCtx {
  final Canvas canvas;
  final Offset base;
  final double unit;
  final double maturity; // 0..1 within youth
  final double boost; // 1..2.25 endless
  final double health; // 0..1
  final int stage; // 1..5
  final bool bare;
  final bool evergreen;
  final Color seed;
  final bool harvestReady;
  final double alpha;
  final double t;

  const _PlantCtx({
    required this.canvas,
    required this.base,
    required this.unit,
    required this.maturity,
    required this.boost,
    required this.health,
    required this.stage,
    required this.bare,
    required this.evergreen,
    required this.seed,
    required this.harvestReady,
    required this.alpha,
    required this.t,
  });
}
