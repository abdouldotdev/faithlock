import 'dart:math' as math;

import 'package:faithlock/shared/widgets/cozy/cozy.dart';
import 'package:flutter/material.dart';

/// "Garden of Grace" hero — a hand-painted (CustomPainter) garden that grows
/// with the user's practice. The plant is procedural, driven by:
///   - [progress] 0→1 : seed → sprout → plant → bloom → fruit (stem height,
///     leaf count, flowers, fruit all scale up)
///   - [health]   0→1 : 1 = lush green & upright; low = wilted (drooping,
///     desaturated toward dry yellow) for neglect.
class GardenHero extends StatelessWidget {
  final double progress;
  final double health;

  /// When true, draws the pot directly — no background fill, no rounded clip —
  /// so it can sit inside another card without looking like a nested card.
  final bool embedded;
  const GardenHero({
    super.key,
    this.progress = 0.05,
    this.health = 1.0,
    this.embedded = false,
  });

  int get _stageDots =>
      progress <= 0 ? 0 : (progress * 5).ceil().clamp(1, 5);

  @override
  Widget build(BuildContext context) {
    final stack = Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _GardenPainter(
                  progress: progress, health: health, embedded: embedded),
            ),
          ),
          if (!embedded)
            Positioned(
              left: CozyTokens.space20,
              right: CozyTokens.space20,
              top: CozyTokens.space16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('GARDEN OF GRACE',
                      style:
                          CozyText.label.copyWith(color: CozyColors.inkMuted)),
                  Row(
                    children: List.generate(5, (i) {
                      final filled = i < _stageDots;
                      return Container(
                        width: 7,
                        height: 7,
                        margin: const EdgeInsets.only(left: 5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              filled ? CozyColors.primary : Colors.transparent,
                          border: Border.all(
                            color: filled
                                ? CozyColors.primary
                                : CozyColors.inkMuted,
                            width: 1.5,
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
        ],
    );
    if (embedded) return stack;
    return ClipRRect(
      borderRadius: BorderRadius.circular(44),
      child: stack,
    );
  }
}

double _lerp(double a, double b, double t) => a + (b - a) * t;

Offset _quad(Offset p0, Offset p1, Offset p2, double t) {
  final u = 1 - t;
  return p0 * (u * u) + p1 * (2 * u * t) + p2 * (t * t);
}

class _GardenPainter extends CustomPainter {
  final double progress;
  final double health;
  final bool embedded;
  _GardenPainter(
      {required this.progress, required this.health, this.embedded = false});

  static const _ink = Color(0xFF3D2B1F);
  static const _potLight = Color(0xFFE8B488);
  static const _pot = Color(0xFFD68A4E);
  static const _potDark = Color(0xFFB46C38);
  static const _soilLight = Color(0xFF6B4E37);
  static const _soilDark = Color(0xFF3F2A1B);
  static const _leafLight = Color(0xFFA6C683);
  static const _leafDark = Color(0xFF5A7A3E);
  static const _vein = Color(0xFF4C6834);
  static const _wilt = Color(0xFFB89B45);
  static const _glow = Color(0xFFF8E6BE);
  static const _bgTop = Color(0xFFFFFDF8);
  static const _bgBottom = Color(0xFFF3E7CE);

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final cx = size.width / 2;

    if (!embedded) _paintBackground(canvas, size);

    // Pot sits flush to the very bottom of the canvas (tiny 4px gap) so it
    // reads as resting on the floor rather than floating mid-frame.
    final potBottomY = h - 4;
    final potTopY = h - 82;
    const topHW = 62.0;
    const botHW = 46.0;
    final soilY = potTopY - 3;

    // Plant is drawn before the rim so the stem appears to rise out of the soil
    // (behind the front rim), then soil/rim frame the base.
    _paintPotBody(canvas, cx, potTopY, potBottomY, topHW, botHW);
    _paintPlantBehind(canvas, cx, soilY);
    _paintRim(canvas, cx, potTopY, topHW);
    _paintSoil(canvas, cx, soilY, topHW);
    _paintPlant(canvas, cx, soilY);
    if (!embedded) _paintSparkles(canvas, size);
  }

  // ── Plant ────────────────────────────────────────────────────────────────
  void _paintPlantBehind(Canvas canvas, double cx, double soilY) {}

  Color _green(double t) {
    final g = Color.lerp(_leafLight, _leafDark, t)!;
    return Color.lerp(_wilt, g, health.clamp(0.0, 1.0))!;
  }

  void _paintPlant(Canvas canvas, double cx, double soilY) {
    if (progress <= 0.001) return;
    // Below ~0.22 it's a delicate sprout; past that it grows into a real tree
    // with a tapered trunk and a broad spreading canopy. [tf] 0→1 drives the
    // trunk height and how wide the foliage fans out.
    final tf = ((progress - 0.22) / 0.78).clamp(0.0, 1.0);
    if (tf > 0.0) {
      _paintTree(canvas, cx, soilY, progress.clamp(0.0, 1.0), tf);
      return;
    }
    _paintSprout(canvas, cx, soilY);
  }

  /// Early life — a delicate curved stem with a few alternating leaves, before
  /// it becomes a tree.
  void _paintSprout(Canvas canvas, double cx, double soilY) {
    final droop = (1 - health).clamp(0.0, 1.0); // 0 upright .. 1 wilted

    final stemH = _lerp(16, 116, progress);
    final base = Offset(cx, soilY - 1);
    final top = Offset(cx + 2 + droop * 6, soilY - stemH + droop * stemH * 0.18);
    final ctrl = Offset(
      cx - 8 + droop * 22,
      soilY - stemH * 0.5 + droop * stemH * 0.25,
    );

    // Stem.
    final stem = Path()
      ..moveTo(base.dx, base.dy)
      ..quadraticBezierTo(ctrl.dx, ctrl.dy, top.dx, top.dy);
    canvas.drawPath(
      stem,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _lerp(3, 6.5, progress)
        ..strokeCap = StrokeCap.round
        ..color = _green(0.55),
    );

    // Leaves along the stem, alternating sides.
    final pairs = 1 + (progress * 6).floor(); // 1..7
    for (var i = 0; i < pairs; i++) {
      final f = (i + 1) / (pairs + 1);
      final pt = _quad(base, ctrl, top, f);
      final side = i.isEven ? -1.0 : 1.0;
      final leafLen = _lerp(11, 30, progress) * (0.65 + f * 0.5);
      // Upward angle that collapses downward as it wilts.
      final up = (0.55 - droop * 1.25);
      final dir = Offset(side * math.cos(up), -math.sin(up) + droop * 0.9);
      final norm = dir.distance == 0 ? dir : dir / dir.distance;
      final tip = pt + norm * leafLen;
      _paintLeaf(canvas, pt, tip, leafLen * 0.42);
    }

    // Flowers near the upper third once it's blooming.
    if (progress > 0.6 && health > 0.45) {
      final n = 1 + ((progress - 0.6) / 0.4 * 3).floor().clamp(0, 3);
      for (var i = 0; i < n; i++) {
        final f = 0.62 + i * 0.13;
        if (f > 0.98) break;
        final pt = _quad(base, ctrl, top, f);
        final side = i.isEven ? 1.0 : -1.0;
        _paintFlower(canvas, pt + Offset(side * 13, -2),
            _lerp(3.5, 5.0, progress));
      }
    }

    // A ripe fruit at full growth.
    if (progress > 0.85 && health > 0.5) {
      final pt = _quad(base, ctrl, top, 0.82);
      _paintFruit(canvas, pt + const Offset(14, 6),
          _lerp(5.5, 8.0, (progress - 0.85) / 0.15));
    }

    // Bud crown / tip.
    canvas.drawCircle(
        top, _lerp(2.6, 3.6, progress), Paint()..color = _green(0.15));
    canvas.drawCircle(top, _lerp(2.6, 3.6, progress), _outline()..strokeWidth = 1.6);

    // Dew drop on a young plant.
    if (progress < 0.5 && health > 0.7) {
      final dew = _quad(base, ctrl, top, 0.7) + const Offset(10, -2);
      canvas.drawCircle(
          dew, 2.4, Paint()..color = Colors.white.withValues(alpha: 0.85));
      canvas.drawCircle(Offset(dew.dx - 0.7, dew.dy - 0.7), 0.9,
          Paint()..color = Colors.white);
    }
  }

  /// Mature life — a real tree: a tapered trunk and a broad, faceted canopy
  /// that spreads wide as [tf] (0→1) grows. Health desaturates and droops it
  /// (via [_green]); blossoms then fruit appear on the crown as it matures.
  void _paintTree(
      Canvas canvas, double cx, double soilY, double p, double tf) {
    final droop = (1 - health).clamp(0.0, 1.0);

    final trunkH = _lerp(38, 104, tf);
    final baseW = _lerp(7, 18, tf);
    final topW = baseW * 0.5;
    final lean = droop * 8;
    final trunkTopY = soilY - trunkH;
    final topCx = cx + lean;

    // Trunk — tapered and gently waisted.
    final trunk = Path()
      ..moveTo(cx - baseW, soilY)
      ..quadraticBezierTo(
          cx - baseW * 0.55, soilY - trunkH * 0.5, topCx - topW, trunkTopY)
      ..lineTo(topCx + topW, trunkTopY)
      ..quadraticBezierTo(
          cx + baseW * 0.55, soilY - trunkH * 0.5, cx + baseW, soilY)
      ..close();
    final trunkRect = Rect.fromLTRB(cx - baseW, trunkTopY, cx + baseW, soilY);
    canvas.drawPath(
      trunk,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [_soilLight, _soilDark],
        ).createShader(trunkRect),
    );
    canvas.drawPath(trunk, _outline());

    // Canopy geometry — widens with growth, sags a touch when wilted.
    final canopyW = _lerp(34, 116, tf) * (1 + droop * 0.06);
    final canopyH = _lerp(28, 78, tf) * (1 - droop * 0.18);
    final cc =
        Offset(topCx, trunkTopY - canopyH * 0.55 + droop * canopyH * 0.45);
    final path = _canopyPath(cc, canopyW, canopyH);

    // Soft drop shadow under the canopy.
    canvas.drawPath(
      path.shift(const Offset(0, 7)),
      Paint()
        ..color = _ink.withValues(alpha: 0.06)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    // Faceted green fill — light crown to deep underside.
    final box = path.getBounds();
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_green(0.12), _green(0.6), _green(0.95)],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(box),
    );

    // Volume — sun-side highlight + deeper shade at the base.
    canvas.save();
    canvas.clipPath(path);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cc.dx - canopyW * 0.32, cc.dy - canopyH * 0.42),
        width: canopyW * 0.9,
        height: canopyH * 0.8,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.12),
    );
    if (health > 0.5) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cc.dx, cc.dy + canopyH * 0.5),
          width: canopyW * 1.3,
          height: canopyH * 0.7,
        ),
        Paint()..color = _leafDark.withValues(alpha: 0.18),
      );
    }
    canvas.restore();

    canvas.drawPath(path, _outline());

    // Blossoms, then fruit, scattered across the crown as it matures.
    final rnd = math.Random(11);
    final pts = <Offset>[];
    final spots = 5 + (tf * 7).round();
    for (var i = 0; i < spots; i++) {
      final a = rnd.nextDouble() * math.pi * 2;
      final rr = math.sqrt(rnd.nextDouble());
      pts.add(Offset(
        cc.dx + math.cos(a) * canopyW * 0.74 * rr,
        cc.dy + math.sin(a) * canopyH * 0.7 * rr - canopyH * 0.05,
      ));
    }
    if (p > 0.45 && p < 0.82 && health > 0.5) {
      final n = (1 + (p - 0.45) / 0.37 * 4).round().clamp(1, 5);
      for (var i = 0; i < n && i < pts.length; i++) {
        _paintFlower(canvas, pts[i], _lerp(3.5, 5.0, tf));
      }
    }
    if (p > 0.7 && health > 0.5) {
      final n = (1 + (p - 0.7) / 0.3 * 5).round().clamp(1, 6);
      for (var i = 0; i < n && i < pts.length; i++) {
        _paintFruit(canvas, pts[pts.length - 1 - i], _lerp(4.5, 7.0, tf));
      }
    }
  }

  /// A broad, gently faceted canopy silhouette — a wobbled ellipse centered at
  /// [c] with half-extents [hw]×[hh]. Straight segments give the cozy low-poly
  /// edge instead of a perfect oval.
  Path _canopyPath(Offset c, double hw, double hh) {
    const steps = 26;
    const lobes = 7;
    final path = Path();
    for (var i = 0; i <= steps; i++) {
      final a = (i / steps) * math.pi * 2;
      final x = c.dx + math.cos(a) * hw * (1 + 0.12 * math.sin(lobes * a));
      final y =
          c.dy + math.sin(a) * hh * (1 + 0.10 * math.sin(lobes * a + 1.6));
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  void _paintLeaf(Canvas canvas, Offset base, Offset tip, double width) {
    final dir = tip - base;
    final len = dir.distance;
    if (len < 0.5) return;
    final mid = base + dir * 0.5;
    final normal = Offset(-dir.dy, dir.dx) / len;
    final c1 = mid + normal * width;
    final c2 = mid - normal * width;

    final leaf = Path()
      ..moveTo(base.dx, base.dy)
      ..quadraticBezierTo(c1.dx, c1.dy, tip.dx, tip.dy)
      ..quadraticBezierTo(c2.dx, c2.dy, base.dx, base.dy)
      ..close();

    final box = leaf.getBounds();
    canvas.drawPath(
      leaf,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_green(0.0), _green(0.55), _green(1.0)],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(box),
    );
    canvas.drawLine(
      base,
      tip,
      Paint()
        ..color = (health > 0.5 ? _vein : _ink).withValues(alpha: 0.6)
        ..strokeWidth = 1.3
        ..strokeCap = StrokeCap.round,
    );
    final hl = base + dir * 0.32 + normal * (width * 0.4);
    canvas.drawCircle(
        hl, 1.9, Paint()..color = Colors.white.withValues(alpha: 0.22));
    canvas.drawPath(leaf, _outline()..strokeWidth = 1.9);
  }

  void _paintFlower(Canvas canvas, Offset c, double r) {
    const petal = Color(0xFFF3D9BE);
    const petalEdge = Color(0xFFE7B98E);
    for (var i = 0; i < 5; i++) {
      final a = (i / 5) * math.pi * 2;
      final pc = c + Offset(math.cos(a), math.sin(a)) * r;
      canvas.drawCircle(pc, r * 0.78, Paint()..color = petal);
      canvas.drawCircle(pc, r * 0.78, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = petalEdge);
    }
    canvas.drawCircle(c, r * 0.6, Paint()..color = const Color(0xFFC9A962));
    canvas.drawCircle(c, r * 0.6, _outline()..strokeWidth = 1.2);
  }

  void _paintFruit(Canvas canvas, Offset c, double r) {
    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.3, -0.4),
          colors: [Color(0xFFF08A5D), Color(0xFFCC4E32)],
        ).createShader(rect),
    );
    canvas.drawCircle(c, r, _outline()..strokeWidth = 1.8);
    // Sheen + tiny stem.
    canvas.drawCircle(c + Offset(-r * 0.35, -r * 0.4), r * 0.22,
        Paint()..color = Colors.white.withValues(alpha: 0.6));
    canvas.drawLine(
      Offset(c.dx, c.dy - r),
      Offset(c.dx - 1, c.dy - r - 4),
      Paint()
        ..color = _leafDark
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );
  }

  // ── Pot / soil / scene (stable across stages) ─────────────────────────────
  void _paintBackground(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_bgTop, _bgBottom],
        ).createShader(rect),
    );
    final glowRect = Rect.fromCircle(
        center: Offset(size.width * 0.82, size.height * 0.18), radius: 120);
    canvas.drawCircle(
      glowRect.center,
      120,
      Paint()
        ..shader = RadialGradient(
          colors: [_glow.withValues(alpha: 0.7), _glow.withValues(alpha: 0.0)],
        ).createShader(glowRect),
    );
  }

  void _paintPotBody(Canvas canvas, double cx, double topY, double bottomY,
      double topHW, double botHW) {
    final body = Path()
      ..moveTo(cx - topHW, topY)
      ..lineTo(cx + topHW, topY)
      ..lineTo(cx + botHW, bottomY - 9)
      ..quadraticBezierTo(cx + botHW, bottomY, cx + botHW - 9, bottomY)
      ..lineTo(cx - botHW + 9, bottomY)
      ..quadraticBezierTo(cx - botHW, bottomY, cx - botHW, bottomY - 9)
      ..close();
    final bodyRect = Rect.fromLTRB(cx - topHW, topY, cx + topHW, bottomY);
    canvas.drawPath(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [_potLight, _pot, _potDark],
          stops: [0.0, 0.55, 1.0],
        ).createShader(bodyRect),
    );
    canvas.drawPath(
      body,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, _potDark.withValues(alpha: 0.45)],
          stops: const [0.45, 1.0],
        ).createShader(bodyRect),
    );
    canvas.save();
    canvas.clipPath(body);
    canvas.drawOval(
      Rect.fromLTWH(cx - topHW + 8, topY + 8, 26, bottomY - topY - 12),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.restore();
    canvas.drawPath(body, _outline());
  }

  void _paintRim(Canvas canvas, double cx, double topY, double topHW) {
    const rimHW = 70.0;
    final rimRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(cx - rimHW, topY - 16, rimHW * 2, 24),
      const Radius.circular(9),
    );
    final r = rimRect.outerRect;
    canvas.drawRRect(
      rimRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [_potLight, _pot, _potDark],
          stops: [0.0, 0.5, 1.0],
        ).createShader(r),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - rimHW + 6, topY - 13, rimHW * 2 - 12, 6),
        const Radius.circular(4),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.22),
    );
    canvas.drawRRect(rimRect, _outline());
  }

  void _paintSoil(Canvas canvas, double cx, double soilY, double topHW) {
    final soilRect = Rect.fromCenter(
        center: Offset(cx, soilY), width: topHW * 2 - 16, height: 20);
    canvas.drawOval(
      soilRect,
      Paint()
        ..shader = const RadialGradient(colors: [_soilLight, _soilDark])
            .createShader(soilRect),
    );
    final rnd = math.Random(7);
    for (var i = 0; i < 26; i++) {
      final a = rnd.nextDouble() * math.pi * 2;
      final rr = rnd.nextDouble();
      final dx = cx + math.cos(a) * (topHW - 14) * rr;
      final dy = soilY + math.sin(a) * 7 * rr;
      canvas.drawCircle(
        Offset(dx, dy),
        rnd.nextDouble() * 1.4 + 0.5,
        Paint()
          ..color =
              (rnd.nextBool() ? _soilLight : _soilDark).withValues(alpha: 0.6),
      );
    }
    canvas.drawOval(soilRect, _outline()..strokeWidth = 2.0);
  }

  void _paintSparkles(Canvas canvas, Size size) {
    final rnd = math.Random(19);
    const gold = Color(0xFFC9A962);
    for (var i = 0; i < 5; i++) {
      final dx = size.width * (0.18 + rnd.nextDouble() * 0.66);
      final dy = size.height * (0.22 + rnd.nextDouble() * 0.32);
      final s = rnd.nextDouble() * 2.2 + 1.6;
      _sparkle(canvas, Offset(dx, dy), s,
          gold.withValues(alpha: 0.30 + rnd.nextDouble() * 0.3));
    }
  }

  void _sparkle(Canvas canvas, Offset c, double s, Color color) {
    final path = Path()
      ..moveTo(c.dx, c.dy - s)
      ..quadraticBezierTo(c.dx, c.dy, c.dx + s, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + s)
      ..quadraticBezierTo(c.dx, c.dy, c.dx - s, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - s)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  Paint _outline() => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5
    ..strokeJoin = StrokeJoin.round
    ..color = _ink;

  @override
  bool shouldRepaint(covariant _GardenPainter old) =>
      old.progress != progress ||
      old.health != health ||
      old.embedded != embedded;
}
