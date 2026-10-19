import 'package:faithlock/features/garden/controllers/grace_garden_controller.dart';
import 'package:faithlock/features/garden/domain/garden_engine.dart';
import 'package:faithlock/features/garden/widgets/garden_world.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression guard for the "[Get] improper use of a GetX" runtime crash: the
/// world's Obx must read its observables synchronously (LayoutBuilder OUTSIDE
/// Obx, not inside). This builds the world and asserts no exception is thrown.
void main() {
  testWidgets('GardenWorld builds without GetX misuse', (tester) async {
    final c = GraceGardenController();
    c.onInit();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GardenWorld(c: c, interactive: false),
        ),
      ),
    );
    // A single frame is enough to trigger the Obx build path. (Don't settle —
    // GardenPlant runs a repeating idle animation.)
    await tester.pump(const Duration(milliseconds: 16));

    expect(tester.takeException(), isNull);

    // Mutating an observable must rebuild without error too.
    c.setSeason(Season.winter);
    await tester.pump(const Duration(milliseconds: 16));
    expect(tester.takeException(), isNull);
  });
}
