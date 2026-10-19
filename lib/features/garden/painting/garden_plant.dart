import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Shared procedural-plant painting, used by both the compact pot hero and the
/// full garden world. A plant rises from [base] (its soil point), driven by:
///   - [progress] 0→1 : seed → sprout → plant → bloom → fruit
///   - [health]   0→1 : 1 lush & upright, low = wilted (droops + browns)
///   - [scale]        : overall size multiplier (depth in the world scene)

const Color gardenInk = Color(0xFF3D2B1F);
const Color _leafLight = Color(0xFFA6C683);
const Color _leafDark = Color(0xFF5A7A3E);
const Color _vein = Color(0xFF4C6834);
const Color _wilt = Color(0xFFB89B45);

double gLerp(double a, double b, double t) => a + (b - a) * t;

Offset gQuad(Offset p0, Offset p1, Offset p2, double t) {
  final u = 1 - t;
  return p0 * (u * u) + p1 * (2 * u * t) + p2 * (t * t);
}

Color plantGreen(double health, double t) {
  final g = Color.lerp(_leafLight, _leafDark, t)!;
  return Color.lerp(_wilt, g, health.clamp(0.0, 1.0))!;
}

Paint gardenOutline([double w = 2.5]) => Paint()
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeJoin = StrokeJoin.round
  ..color = gardenInk;

void paintPlant(
  Canvas canvas,
  Offset base,
  double progress,
  double health, {
  double scale = 1.0,
}) {
  if (progress <= 0.001) return;
  final droop = (1 - health).clamp(0.0, 1.0);
  final stemH = gLerp(16, 116, progress) * scale;
  final top = Offset(
    base.dx + 2 * scale + droop * 6 * scale,
    base.dy - stemH + droop * stemH * 0.18,
  );
  final ctrl = Offset(
    base.dx - 8 * scale + droop * 22 * scale,
    base.dy - stemH * 0.5 + droop * stemH * 0.25,
  );

  final stem = Path()
    ..moveTo(base.dx, base.dy)
    ..quadraticBezierTo(ctrl.dx, ctrl.dy, top.dx, top.dy);
  canvas.drawPath(
    stem,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = gLerp(3, 6.5, progress) * scale
      ..strokeCap = StrokeCap.round
      ..color = plantGreen(health, 0.55),
  );

  final pairs = 1 + (progress * 6).floor();
  for (var i = 0; i < pairs; i++) {
    final f = (i + 1) / (pairs + 1);
    final pt = gQuad(base, ctrl, top, f);
    final side = i.isEven ? -1.0 : 1.0;
    final leafLen = gLerp(11, 30, progress) * (0.65 + f * 0.5) * scale;
    final up = 0.55 - droop * 1.25;
    final dir = Offset(side * math.cos(up), -math.sin(up) + droop * 0.9);
    final norm = dir.distance == 0 ? dir : dir / dir.distance;
    _leaf(canvas, pt, pt + norm * leafLen, leafLen * 0.42, health);
  }

  if (progress > 0.6 && health > 0.45) {
    final n = 1 + ((progress - 0.6) / 0.4 * 3).floor().clamp(0, 3);
    for (var i = 0; i < n; i++) {
      final f = 0.62 + i * 0.13;
      if (f > 0.98) break;
      final pt = gQuad(base, ctrl, top, f);
      final side = i.isEven ? 1.0 : -1.0;
      _flower(canvas, pt + Offset(side * 13 * scale, -2 * scale),
          gLerp(3.5, 5.0, progress) * scale);
    }
  }

  if (progress > 0.85 && health > 0.5) {
    final pt = gQuad(base, ctrl, top, 0.82);
    _fruit(canvas, pt + Offset(14 * scale, 6 * scale),
        gLerp(5.5, 8.0, (progress - 0.85) / 0.15) * scale);
  }

  canvas.drawCircle(top, gLerp(2.6, 3.6, progress) * scale,
      Paint()..color = plantGreen(health, 0.15));
  canvas.drawCircle(top, gLerp(2.6, 3.6, progress) * scale, gardenOutline(1.6));

  if (progress < 0.5 && health > 0.7) {
    final dew = gQuad(base, ctrl, top, 0.7) + Offset(10 * scale, -2 * scale);
    canvas.drawCircle(
        dew, 2.4 * scale, Paint()..color = Colors.white.withValues(alpha: 0.85));
    canvas.drawCircle(Offset(dew.dx - 0.7, dew.dy - 0.7), 0.9 * scale,
        Paint()..color = Colors.white);
  }
}

void _leaf(Canvas canvas, Offset base, Offset tip, double width, double health) {
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
        colors: [plantGreen(health, 0), plantGreen(health, 0.55), plantGreen(health, 1)],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(box),
  );
  canvas.drawLine(
    base,
    tip,
    Paint()
      ..color = (health > 0.5 ? _vein : gardenInk).withValues(alpha: 0.6)
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round,
  );
  final hl = base + dir * 0.32 + normal * (width * 0.4);
  canvas.drawCircle(hl, 1.9, Paint()..color = Colors.white.withValues(alpha: 0.22));
  canvas.drawPath(leaf, gardenOutline(1.9));
}

void _flower(Canvas canvas, Offset c, double r) {
  const petal = Color(0xFFF3D9BE);
  const petalEdge = Color(0xFFE7B98E);
  for (var i = 0; i < 5; i++) {
    final a = (i / 5) * math.pi * 2;
    final pc = c + Offset(math.cos(a), math.sin(a)) * r;
    canvas.drawCircle(pc, r * 0.78, Paint()..color = petal);
    canvas.drawCircle(
        pc,
        r * 0.78,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = petalEdge);
  }
  canvas.drawCircle(c, r * 0.6, Paint()..color = const Color(0xFFC9A962));
  canvas.drawCircle(c, r * 0.6, gardenOutline(1.2));
}

void _fruit(Canvas canvas, Offset c, double r) {
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
  canvas.drawCircle(c, r, gardenOutline(1.8));
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
