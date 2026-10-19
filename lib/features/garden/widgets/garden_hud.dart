import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../shared/widgets/cozy/cozy.dart';
import '../controllers/grace_garden_controller.dart';
import '../domain/garden_engine.dart';

/// OWNER: Dev2 (Experience & Flow).
///
/// Top overlay: where we are (season + a qualitative garden mood — never raw
/// numbers) and entry points to the journal and to replay the onboarding.
class GardenHud extends StatelessWidget {
  final GraceGardenController c;
  final VoidCallback onJournal;
  final VoidCallback onReplay;

  const GardenHud({
    super.key,
    required this.c,
    required this.onJournal,
    required this.onReplay,
  });

  static const _seasonLabel = {
    Season.spring: '🌸 Spring',
    Season.summer: '☀️ Summer',
    Season.autumn: '🍂 Autumn',
    Season.winter: '❄️ Winter',
  };

  /// Qualitative read of overall vitality — grace-framed, no numbers.
  static String _mood(int health) {
    if (health >= 85) return 'Thriving';
    if (health >= 60) return 'Tended';
    if (health >= 40) return 'Resting';
    return 'Waiting for you';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Season + mood, stacked so the mood reads as a quiet subtitle.
            Obx(() => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _pill(_seasonLabel[c.season.value]!),
                    const SizedBox(height: 6),
                    _moodChip(_mood(c.health.value)),
                  ],
                )),
            Row(
              children: [
                _btn(Icons.menu_book_rounded, onJournal, 'Journal'),
                const SizedBox(width: 8),
                _btn(Icons.replay_rounded, onReplay, 'Replay the tour'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: ShapeDecoration(
          color: CozyColors.surface,
          shape: CozyTokens.smooth(CozyTokens.radiusPill,
              side: const BorderSide(
                  color: CozyColors.outline,
                  width: CozyTokens.borderWidthThin)),
          shadows: CozyTokens.shadowSoft,
        ),
        child: Text(text, style: CozyText.label),
      );

  Widget _moodChip(String mood) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.only(right: 6),
              decoration: const BoxDecoration(
                color: CozyColors.primary,
                shape: BoxShape.circle,
              ),
            ),
            Text(mood,
                style: CozyText.subtitle.copyWith(color: CozyColors.ink)),
          ],
        ),
      );

  Widget _btn(IconData icon, VoidCallback onTap, String tooltip) => Tooltip(
        message: tooltip,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 42,
            height: 42,
            decoration: ShapeDecoration(
              color: CozyColors.surface,
              shape: CozyTokens.smooth(CozyTokens.radiusMd,
                  side: const BorderSide(
                      color: CozyColors.outline,
                      width: CozyTokens.borderWidthThin)),
              shadows: CozyTokens.shadowSoft,
            ),
            child: Icon(icon, color: CozyColors.ink, size: 20),
          ),
        ),
      );
}
