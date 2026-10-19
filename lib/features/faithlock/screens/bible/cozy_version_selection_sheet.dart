import 'package:faithlock/features/bible/controllers/bible_controller.dart';
import 'package:faithlock/services/analytics/posthog/export.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:faithlock/shared/widgets/cozy/cozy.dart';

// ── Sheet widget ──────────────────────────────────────────────────────────────

/// Bible version picker — displayed as a modal bottom sheet.
/// Wired to [BibleController]: selecting a version persists and reacts globally.
///
/// Show via [CozyVersionSelectionSheet.show]:
/// ```dart
/// CozyVersionSelectionSheet.show(context);
/// ```
class CozyVersionSelectionSheet extends StatelessWidget {
  const CozyVersionSelectionSheet({super.key});

  /// Shows this sheet as a modal bottom sheet.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: CozyColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(CozyTokens.radiusLg),
        ),
      ),
      builder: (_) => const CozyVersionSelectionSheet(),
    );
  }

  BibleController get _ctrl {
    if (!Get.isRegistered<BibleController>()) {
      Get.put(BibleController());
    }
    return Get.find<BibleController>();
  }

  @override
  Widget build(BuildContext context) {
    // Constrain the sheet so it never exceeds 85% of screen height.
    final double maxHeight = MediaQuery.of(context).size.height * 0.85;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: _topBar(),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'bible_availableVersions'.tr.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CozyText.label.copyWith(
                  letterSpacing: 1.2,
                  fontSize: 11,
                  color: CozyColors.inkMuted,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: Obx(() {
                final currentAbbr = _ctrl.selectedVersion.value.abbr;
                return ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  children: _ctrl.versions.map((v) {
                    final bool selected = v.abbr == currentAbbr;
                    final bool unavailable = !v.isAvailable;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Opacity(
                        // Dim the row so the disabled state is obvious. The
                        // null onTap below keeps it actually untappable.
                        opacity: unavailable ? 0.5 : 1.0,
                        child: CozyChoiceCard(
                          title: v.name,
                          subtitle: v.subtitle,
                          leading: CozyLetterBadge(
                            label: v.abbr,
                            background: selected
                                ? CozyColors.onPrimary.withValues(alpha: 0.25)
                                : v.badgeColor,
                            textColor: selected
                                ? CozyColors.onPrimary
                                : CozyColors.ink,
                            size: 52,
                          ),
                          selected: selected,
                          filledWhenSelected: true,
                          trailing: unavailable ? _comingSoonTag() : null,
                          onTap: unavailable
                              ? null
                              : () async {
                                  final previous =
                                      _ctrl.selectedVersion.value.abbr;
                                  await _ctrl.selectVersion(v);
                                  if (previous != v.abbr) {
                                    final analytics = PostHogService.instance;
                                    if (analytics.isReady) {
                                      analytics.events.trackCustom(
                                        'bible_version_changed',
                                        {
                                          'version': v.abbr,
                                          'previous': previous,
                                        },
                                      );
                                    }
                                  }
                                  Get.back();
                                },
                        ),
                      ),
                    );
                  }).toList(),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  /// Small chunky pill used as the trailing widget on disabled versions.
  Widget _comingSoonTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: ShapeDecoration(
        color: CozyColors.surfaceMuted,
        shape: CozyTokens.smooth(
          CozyTokens.radiusPill,
          side: const BorderSide(
            color: CozyColors.outline,
            width: CozyTokens.borderWidthThin,
          ),
        ),
      ),
      child: Text(
        'bible_comingSoon'.tr.toUpperCase(),
        style: CozyText.label.copyWith(
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: CozyColors.inkMuted,
        ),
      ),
    );
  }

  // ── Top bar ───────────────────────────────────────────────────────────────

  Widget _topBar() {
    return Row(
      children: [
        CozyIconButton(
          icon: HugeIcons.strokeRoundedCancel01,
          onTap: Get.back,
          size: 48,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            'bible_bibleVersion'.tr,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: CozyText.title,
          ),
        ),
      ],
    );
  }
}
