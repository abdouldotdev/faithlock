import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:faithlock/features/garden/domain/garden_engine.dart';
import 'package:faithlock/features/garden/render/plant_renderer.dart';
import 'package:faithlock/features/garden/render/placeholder_plant_renderer.dart';

/// Golden grids for the FINAL [PlaceholderPlantRenderer] (dev1).
///
/// Two goldens:
///   1. `garden_plants.png` — every species × a few (stage/health/harvest)
///      states, to lock each archetype silhouette + health + harvest glow.
///   2. `garden_plant_states.png` — stage 1..5 sweep, selected, dim, bare
///      (deciduous) vs evergreen, endless-tier boost, lush vs wilted.
///
/// Determinism: we draw the renderer DIRECTLY through a [CustomPaint] at a
/// fixed ambient clock `t = 0` (dev1's hook), bypassing [GardenPlant]'s
/// repeating idle/grow-pop animation so the glow pulse, willow sway, and star
/// twinkle are all frozen.
///
/// Generate / refresh:  flutter test --update-goldens test/garden/plant_golden_test.dart
/// Verify:              flutter test test/garden/plant_golden_test.dart
const _renderer = PlaceholderPlantRenderer();
const _ink = Color(0xFF3D2B1F);
const _cellBg = Color(0xFFFFFDF8);
const _pageBg = Color(0xFFFBF3E2);

/// Paints a [PlantVisual] at a frozen clock — no animation, no GardenPlant.
class _FrozenPlant extends StatelessWidget {
  final PlantVisual visual;
  const _FrozenPlant(this.visual);

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: const Size(96, 120), painter: _Painter(visual));
}

class _Painter extends CustomPainter {
  final PlantVisual v;
  _Painter(this.v);
  @override
  void paint(Canvas canvas, Size size) =>
      _renderer.paint(canvas, size, v, t: 0);
  @override
  bool shouldRepaint(covariant _Painter old) => old.v != v;
}

Widget _label(String s) => Text(
      s,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontFamily: 'Satoshi',
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: _ink,
      ),
    );

Widget _cell(String label, PlantVisual v) => Container(
      width: 112,
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: _cellBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _ink, width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _label(label),
          const SizedBox(height: 4),
          _FrozenPlant(v),
        ],
      ),
    );

void main() {
  setUpAll(() async {
    for (final f in [
      'assets/fonts/Satoshi/Satoshi-Regular.otf',
      'assets/fonts/Satoshi/Satoshi-Medium.otf',
      'assets/fonts/Satoshi/Satoshi-Bold.otf',
    ]) {
      final file = File(f);
      if (!file.existsSync()) continue;
      final bytes = file.readAsBytesSync();
      final loader = FontLoader('Satoshi')
        ..addFont(
            Future.value(ByteData.view(Uint8List.fromList(bytes).buffer)));
      await loader.load();
    }
  });

  PlantVisual visual(
    FruitKey key, {
    required int growth,
    double health = 1.0,
    bool harvestReady = false,
    bool selected = false,
    bool dim = false,
    Season season = Season.spring,
  }) {
    final p = Plot(fruit: key, growth: growth, harvestReady: harvestReady);
    return PlantVisual.fromPlot(p, season: season, selected: selected, dim: dim)
        .copyWith(health: health);
  }

  testWidgets('garden plants — all 9 species × states', (tester) async {
    const states = <(String, int, double, bool)>[
      // label, growth, health, harvestReady
      ('Seed', 8, 1.0, false),
      ('Growing', 50, 1.0, false),
      ('Bearing', 90, 1.0, true),
      ('Resting', 70, 0.2, false),
    ];

    Widget speciesRow(FruitMeta meta) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 92, child: _label(meta.label)),
            const SizedBox(width: 8),
            for (final s in states)
              _cell(
                s.$1,
                visual(meta.key,
                    growth: s.$2, health: s.$3, harvestReady: s.$4),
              ),
          ],
        );

    await tester.binding.setSurfaceSize(const Size(640, 1560));
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: _pageBg,
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                key: const Key('species-grid'),
                mainAxisSize: MainAxisSize.min,
                children: [for (final m in kFruits) speciesRow(m)],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await expectLater(
      find.byKey(const Key('species-grid')),
      matchesGoldenFile('garden_plants.png'),
    );
  });

  testWidgets('garden plant — stages, flags, dormancy, endless tier',
      (tester) async {
    final cells = <Widget>[
      // Stage 1..5 on a deciduous tree (Patience).
      _cell('Seed', visual(FruitKey.patience, growth: 8)),
      _cell('Sprouting', visual(FruitKey.patience, growth: 28)),
      _cell('Growing', visual(FruitKey.patience, growth: 48)),
      _cell('Blossoming', visual(FruitKey.patience, growth: 68)),
      _cell('Bearing', visual(FruitKey.patience, growth: 90)),
      // Flags.
      _cell('Selected', visual(FruitKey.love, growth: 60, selected: true)),
      _cell('Dim', visual(FruitKey.joy, growth: 60, dim: true)),
      _cell('Harvest glow',
          visual(FruitKey.peace, growth: 95, harvestReady: true)),
      // Winter dormancy: deciduous goes bare, evergreens stay green.
      _cell('Bare (deciduous)',
          visual(FruitKey.patience, growth: 60, season: Season.winter)),
      _cell('Evergreen (Peace)',
          visual(FruitKey.peace, growth: 60, season: Season.winter)),
      _cell('Evergreen (Faith)',
          visual(FruitKey.faithfulness, growth: 60, season: Season.winter)),
      // Endless tier: high growth → boost 2.25 (Grove) → fuller/taller canopy.
      _cell('Grove (boost 2.25)', visual(FruitKey.patience, growth: 700)),
      // Lush vs wilted, same stage.
      _cell('Lush', visual(FruitKey.kindness, growth: 70, health: 1.0)),
      _cell('Wilted', visual(FruitKey.kindness, growth: 70, health: 0.2)),
    ];

    await tester.binding.setSurfaceSize(const Size(620, 720));
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: _pageBg,
          body: Center(
            child: Wrap(
              key: const Key('state-grid'),
              alignment: WrapAlignment.center,
              children: cells,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await expectLater(
      find.byKey(const Key('state-grid')),
      matchesGoldenFile('garden_plant_states.png'),
    );
  });
}
