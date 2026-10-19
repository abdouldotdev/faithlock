import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../shared/widgets/cozy/cozy.dart';
import '../controllers/grace_garden_controller.dart';

/// OWNER: Dev2 (Experience & Flow).
///
/// "Welcome home" / new-morning recap (spec §14): shown when controller.recap is
/// set; reassures that nothing was lost while away. Eases in with a soft scale +
/// fade so it feels like the morning arriving rather than a hard alert.
class GardenRecapModal extends StatelessWidget {
  final GraceGardenController c;
  const GardenRecapModal({super.key, required this.c});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final r = c.recap.value;
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 360),
        switchInCurve: Curves.easeOutBack,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, anim) =>
            FadeTransition(opacity: anim, child: child),
        child: r == null
            ? const SizedBox.shrink(key: ValueKey('recap-none'))
            : _Card(
                key: const ValueKey('recap-shown'),
                message: r.message,
                lines: r.lines,
                onDismiss: () => c.setRecap(null),
              ),
      );
    });
  }
}

class _Card extends StatelessWidget {
  final String message;
  final List<String> lines;
  final VoidCallback onDismiss;

  const _Card({
    super.key,
    required this.message,
    required this.lines,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: const Color(0x66000000),
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.94, end: 1),
            duration: const Duration(milliseconds: 360),
            curve: Curves.easeOutBack,
            builder: (_, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              decoration: ShapeDecoration(
                color: CozyColors.surface,
                shape: CozyTokens.smooth(CozyTokens.radiusLg,
                    side: const BorderSide(
                        color: CozyColors.outline,
                        width: CozyTokens.borderWidth)),
                shadows: CozyTokens.shadowHard,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🌿', style: TextStyle(fontSize: 34)),
                  const SizedBox(height: 12),
                  Text(message,
                      style: CozyText.title, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  for (final line in lines) ...[
                    Text(line,
                        style: CozyText.body, textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 12),
                  CozyButton(text: 'Tend the garden', onTap: onDismiss),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
