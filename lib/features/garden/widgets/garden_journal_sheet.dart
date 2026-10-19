import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../shared/widgets/cozy/cozy.dart';
import '../controllers/grace_garden_controller.dart';
import '../domain/garden_engine.dart';

/// OWNER: Dev2 (Experience & Flow).
///
/// The growth journal (spec §15): the history of actions that grew (or rested) a
/// plant — grace-framed, qualitative ("tracks time abiding, not holiness"). When
/// [fruit] is set, it filters to that plant's story and shows a small header
/// with its current named stage.
Future<void> showGardenJournal(BuildContext context, GraceGardenController c,
    {FruitKey? fruit}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => GardenJournalSheet(c: c, fruit: fruit),
  );
}

class GardenJournalSheet extends StatelessWidget {
  final GraceGardenController c;
  final FruitKey? fruit;
  const GardenJournalSheet({super.key, required this.c, this.fruit});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ShapeDecoration(
        color: CozyColors.background,
        shape: CozyTokens.smoothTop(CozyTokens.radiusLg),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 5,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: CozyColors.border,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
          Text(
            fruit == null
                ? 'Your garden journal'
                : '${fruitLabel(fruit!)} — its story',
            style: CozyText.title,
          ),
          const SizedBox(height: 4),
          Text(
            fruit == null
                ? 'A record of time spent abiding — not a scoreboard. 🤍'
                : 'How this one has grown as you’ve tended it. 🤍',
            style: CozyText.subtitle,
          ),
          if (fruit != null) ...[
            const SizedBox(height: 14),
            _StageBanner(c: c, fruit: fruit!),
          ],
          const SizedBox(height: 16),
          Flexible(
            child: Obx(() {
              final entries = fruit == null
                  ? c.log.toList()
                  : c.log.where((e) => e.fruit == fruit).toList();
              if (entries.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    fruit == null
                        ? 'Nothing yet — your story begins as you tend.'
                        : 'No entries yet for ${fruitLabel(fruit!)}. Tend it and watch.',
                    style: CozyText.body,
                  ),
                );
              }
              return ListView.separated(
                itemCount: entries.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 16, color: CozyColors.divider),
                itemBuilder: (_, i) => _row(entries[i]),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _row(LogEntry e) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(e.icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              e.text,
              style: e.milestone
                  ? CozyText.body.copyWith(fontWeight: FontWeight.w700)
                  : CozyText.body,
            ),
          ),
        ],
      );
}

/// A small banner for the per-plant view: shows the plant's current named stage
/// (qualitative — derived from internal growth, never a raw number) and how many
/// milestones it has bloomed through.
class _StageBanner extends StatelessWidget {
  final GraceGardenController c;
  final FruitKey fruit;
  const _StageBanner({required this.c, required this.fruit});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final p = c.plots[fruit]!;
      final d = derive(p.growth);
      final blooms = p.bloomedTiers.length;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: ShapeDecoration(
          color: CozyColors.surface,
          shape: CozyTokens.smooth(CozyTokens.radiusMd,
              side: const BorderSide(
                  color: CozyColors.outline,
                  width: CozyTokens.borderWidthThin)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: CozyColors.sage,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Text('🌿', style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Now: ${d.name}', style: CozyText.heading),
                  const SizedBox(height: 2),
                  Text(
                    blooms == 0
                        ? 'Just beginning to grow.'
                        : blooms == 1
                            ? 'Bloomed through 1 stage so far.'
                            : 'Bloomed through $blooms stages so far.',
                    style: CozyText.subtitle,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}
