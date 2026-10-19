import 'dart:io';
import 'dart:typed_data';

import 'package:faithlock/features/garden/widgets/garden_hero.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Renders every garden state to test/garden_states.png:
///   flutter test --update-goldens test/garden_hero_state1_test.dart
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
        ..addFont(Future.value(
            ByteData.view(Uint8List.fromList(bytes).buffer)));
      await loader.load();
    }
  });

  testWidgets('garden — all states', (tester) async {
    await tester.binding.setSurfaceSize(const Size(780, 820));

    const states = <(String, double, double)>[
      ('Seed', 0.05, 1.0),
      ('Sprout', 0.25, 1.0),
      ('Young plant', 0.5, 1.0),
      ('Bloom', 0.72, 1.0),
      ('Fruit', 0.96, 1.0),
      ('Wilting (neglect)', 0.6, 0.3),
    ];

    Widget cell(String label, double p, double hth) => Container(
          width: 360,
          margin: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF3D2B1F))),
              const SizedBox(height: 6),
              SizedBox(
                width: 360,
                height: 200,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFDF8),
                    borderRadius: BorderRadius.circular(44),
                    border:
                        Border.all(color: const Color(0xFF3D2B1F), width: 2.5),
                  ),
                  child: GardenHero(progress: p, health: hth),
                ),
              ),
            ],
          ),
        );

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFFFBF3E2),
          body: Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              children: [for (final s in states) cell(s.$1, s.$2, s.$3)],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(Wrap),
      matchesGoldenFile('garden_states.png'),
    );
  });
}
