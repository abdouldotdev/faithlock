import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_cube/flutter_cube.dart' as cube;
import 'package:get/get.dart';

import '../controllers/grace_garden_controller.dart';
import '../domain/garden_engine.dart';

/// THE TREE — a single navigable 3D tree that grows, thickens, and bears the
/// nine Fruits of the Spirit (spec attribution). One tree = the whole journey:
///   • size/fullness  = total practice across all fruits (endless),
///   • each fruit type = N coloured fruits on the canopy, count/ripeness from
///     that Fruit's growth (read an anxiety verse → a "Peace" fruit ripens),
///   • health         = lush & upright vs wilted (desaturated, drooping, fewer fruit),
///   • winter         = thinner canopy.
/// Drag to orbit, pinch to zoom (flutter_cube trackball). Procedural low-poly
/// now; swap to a real OBJ tree later via the same rebuild.
class GardenTree3D extends StatefulWidget {
  final GraceGardenController c;
  const GardenTree3D({super.key, required this.c});

  @override
  State<GardenTree3D> createState() => _GardenTree3DState();
}

class _GardenTree3DState extends State<GardenTree3D> {
  cube.Scene? _scene;
  final List<Worker> _workers = [];

  static const Color _bark = Color(0xFF6B4E37);
  static const Color _barkDark = Color(0xFF553D2B);
  static const Color _leaf = Color(0xFF6E9A52);
  static const Color _dryLeaf = Color(0xFFB89B45);

  @override
  void initState() {
    super.initState();
    final c = widget.c;
    _workers.add(ever(c.plots, (_) => _rebuild()));
    _workers.add(ever(c.health, (_) => _rebuild()));
    _workers.add(ever(c.season, (_) => _rebuild()));
  }

  @override
  void dispose() {
    for (final w in _workers) {
      w.dispose();
    }
    super.dispose();
  }

  void _onSceneCreated(cube.Scene scene) {
    _scene = scene;
    scene.camera.position.setValues(0, 3.2, -12);
    scene.camera.target.setValues(0, 2.4, 0);
    scene.camera.fov = 50;
    _rebuild();
  }

  // total practice across all fruits → 0..~ maturity units
  double _maturity(GraceGardenController c) {
    var total = 0;
    for (final f in kFruits) {
      total += c.plots[f.key]!.growth;
    }
    // 9×5 = 45 at start; grows unbounded. Soft log-ish curve, capped for size.
    return (math.log(1 + total / 60) * 1.6).clamp(0.25, 4.2);
  }

  void _rebuild() {
    final scene = _scene;
    if (scene == null) return;
    final c = widget.c;
    final m = _maturity(c);
    final health = (c.health.value / 100).clamp(0.0, 1.0);
    final season = c.season.value;

    final world = cube.Object(scene: scene);
    world.add(_ground(season));
    world.add(_buildTree(c, m, health, season));
    scene.world = world;
    scene.update();
  }

  // ── Tree assembly ────────────────────────────────────────────────────────────

  cube.Object _buildTree(
      GraceGardenController c, double m, double health, Season season) {
    final root = cube.Object(lighting: false, backfaceCulling: false);
    root.rotation.setValues(0, 0, (1 - health) * 9); // slight wilt lean
    root.updateTransform();

    final leaf = Color.lerp(_dryLeaf, _leaf, health)!;
    final trunkH = 1.6 + m * 0.7;
    final trunkR = 0.18 + m * 0.06;

    // Tapered trunk (two stacked segments) + a root flare.
    root.add(_part(_cylinder(trunkR * 1.35, trunkR * 1.05, trunkH * 0.45, 7, _barkDark)));
    root.add(_part(_cylinder(trunkR * 1.05, trunkR * 0.7, trunkH * 0.6, 7, _bark),
        y: trunkH * 0.45));

    final canopyY = trunkH;
    // Branches fan out near the top.
    final branchCount = 3 + (m).round().clamp(0, 3);
    for (var i = 0; i < branchCount; i++) {
      final a = 2 * math.pi * i / branchCount + 0.5;
      final br = _part(
        _cylinder(trunkR * 0.5, trunkR * 0.2, trunkH * 0.5, 5, _bark),
        x: math.cos(a) * trunkR,
        z: math.sin(a) * trunkR,
        y: trunkH * 0.7,
      );
      br.rotation.setValues(math.cos(a) * 35, 0, math.sin(a) * 35);
      br.updateTransform();
      root.add(br);
    }

    // Canopy = cluster of overlapping blobs (fuller = more mature). Thinner in
    // winter. Evergreen-ish: never fully bare (it's THE tree).
    final winter = season == Season.winter;
    final blobs = (winter ? 4 : 6) + m.round().clamp(0, 4);
    final canopyR = 0.85 + m * 0.28;
    final rnd = math.Random(7);
    final canopyCenters = <cube.Vector3>[];
    for (var i = 0; i < blobs; i++) {
      final a = 2 * math.pi * i / blobs + rnd.nextDouble();
      final rad = canopyR * (0.45 + rnd.nextDouble() * 0.5);
      final cx = math.cos(a) * rad;
      final cz = math.sin(a) * rad;
      final cy = canopyY + 0.3 + rnd.nextDouble() * canopyR * 0.8;
      final br = canopyR * (winter ? 0.5 : 0.62) * (0.7 + rnd.nextDouble() * 0.5);
      root.add(_part(_sphere(br, 4, 7, leaf), x: cx, y: cy, z: cz));
      canopyCenters.add(cube.Vector3(cx, cy, cz));
    }
    // a top crown blob
    root.add(_part(_sphere(canopyR * 0.7, 4, 7, leaf), y: canopyY + canopyR + 0.2));
    canopyCenters.add(cube.Vector3(0, canopyY + canopyR + 0.2, 0));

    // ── Fruits: the nine Fruits of the Spirit borne on the canopy ──
    if (health > 0.35) {
      final fruits = <_FruitDot>[];
      for (final meta in kFruits) {
        final n = _fruitCount(c.plots[meta.key]!.growth);
        final col = Color.lerp(_dryLeaf, meta.seed, health)!;
        for (var k = 0; k < n; k++) {
          fruits.add(_FruitDot(col));
        }
      }
      // Scatter them over the canopy surface (golden-angle spiral).
      for (var i = 0; i < fruits.length; i++) {
        final center = canopyCenters[i % canopyCenters.length];
        final t = (i + 0.5) / fruits.length;
        final phi = math.acos(1 - 2 * t);
        final theta = math.pi * (1 + math.sqrt(5)) * i;
        final r = canopyR * 0.62;
        root.add(_part(
          _sphere(0.12 + 0.02 * m.clamp(0, 2), 3, 6, fruits[i].color),
          x: center.x + r * math.sin(phi) * math.cos(theta),
          y: center.y + r * math.cos(phi) * 0.7,
          z: center.z + r * math.sin(phi) * math.sin(theta),
        ));
      }
    }

    return root;
  }

  /// How many of a given Fruit are visible on the tree, from its growth.
  int _fruitCount(int growth) {
    final d = derive(growth);
    if (growth < 40) return 0; // not yet bearing
    if (d.tier >= 8) return 4;
    if (d.tier >= 6) return 3;
    if (growth >= 80) return 2;
    return 1;
  }

  // ── Primitives (procedural, pseudo-shaded by height) ─────────────────────────

  cube.Object _part(cube.Mesh mesh,
      {double x = 0, double y = 0, double z = 0}) {
    final o = cube.Object(mesh: mesh, lighting: false, backfaceCulling: false);
    o.position.setValues(x, y, z);
    o.updateTransform();
    return o;
  }

  cube.Mesh _mk(List<cube.Vector3> v, List<cube.Polygon> f, Color base) {
    var minY = double.infinity, maxY = -double.infinity;
    for (final p in v) {
      if (p.y < minY) minY = p.y;
      if (p.y > maxY) maxY = p.y;
    }
    final range = (maxY - minY).abs() < 1e-6 ? 1.0 : (maxY - minY);
    final dark = Color.lerp(Colors.black, base, 0.5)!;
    final colors = [
      for (final p in v)
        Color.lerp(dark, base, ((p.y - minY) / range).clamp(0.0, 1.0))!
    ];
    final mat = cube.Material();
    mat.diffuse.setFrom(cube.fromColor(base));
    mat.ambient.setFrom(cube.fromColor(base));
    return cube.Mesh(vertices: v, indices: f, colors: colors, material: mat);
  }

  cube.Mesh _cylinder(double rb, double rt, double h, int seg, Color color) {
    final v = <cube.Vector3>[];
    final f = <cube.Polygon>[];
    for (var i = 0; i < seg; i++) {
      final a = 2 * math.pi * i / seg;
      v.add(cube.Vector3(math.cos(a) * rb, 0, math.sin(a) * rb));
    }
    for (var i = 0; i < seg; i++) {
      final a = 2 * math.pi * i / seg;
      v.add(cube.Vector3(math.cos(a) * rt, h, math.sin(a) * rt));
    }
    for (var i = 0; i < seg; i++) {
      final ni = (i + 1) % seg;
      f.add(cube.Polygon(i, seg + i, seg + ni));
      f.add(cube.Polygon(i, seg + ni, ni));
    }
    final top = v.length;
    v.add(cube.Vector3(0, h, 0));
    for (var i = 0; i < seg; i++) {
      f.add(cube.Polygon(seg + i, top, seg + (i + 1) % seg));
    }
    return _mk(v, f, color);
  }

  cube.Mesh _sphere(double r, int latSeg, int lonSeg, Color color) {
    final v = <cube.Vector3>[];
    final f = <cube.Polygon>[];
    for (var la = 0; la <= latSeg; la++) {
      final theta = math.pi * la / latSeg;
      for (var lo = 0; lo <= lonSeg; lo++) {
        final phi = 2 * math.pi * lo / lonSeg;
        v.add(cube.Vector3(
          r * math.sin(theta) * math.cos(phi),
          r * math.cos(theta),
          r * math.sin(theta) * math.sin(phi),
        ));
      }
    }
    final cols = lonSeg + 1;
    for (var la = 0; la < latSeg; la++) {
      for (var lo = 0; lo < lonSeg; lo++) {
        final a = la * cols + lo;
        final b = a + cols;
        f.add(cube.Polygon(a, b, a + 1));
        f.add(cube.Polygon(a + 1, b, b + 1));
      }
    }
    return _mk(v, f, color);
  }

  cube.Object _ground(Season season) {
    final (Color top, Color soil) = switch (season) {
      Season.spring => (const Color(0xFF9DBB73), const Color(0xFF6B4E37)),
      Season.summer => (const Color(0xFFAEC57E), const Color(0xFF6B4E37)),
      Season.autumn => (const Color(0xFFC79A5B), const Color(0xFF5A3F28)),
      Season.winter => (const Color(0xFFD7E0E8), const Color(0xFF5A4636)),
    };
    final disc = _cylinder(4.6, 4.9, 0.5, 22, soil);
    final o = cube.Object(mesh: disc, lighting: false, backfaceCulling: false);
    o.position.setValues(0, -0.5, 0);
    o.updateTransform();
    final grass = cube.Object(
        mesh: _cylinder(4.5, 4.5, 0.06, 22, top),
        lighting: false,
        backfaceCulling: false);
    grass.position.setValues(0, 0, 0);
    grass.updateTransform();
    o.add(grass);
    return o;
  }

  @override
  Widget build(BuildContext context) {
    return cube.Cube(interactive: true, onSceneCreated: _onSceneCreated);
  }
}

class _FruitDot {
  final Color color;
  _FruitDot(this.color);
}
