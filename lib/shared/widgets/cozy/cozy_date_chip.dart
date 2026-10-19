import 'package:flutter/widgets.dart';

import '../../../core/theme/cozy/cozy.dart';
import 'cozy_tappable.dart';

/// A vertical date pill ("JULY / 7"). Selected = brand fill + hard shadow.
class CozyDateChip extends StatelessWidget {
  final String topLabel;
  final String bottomLabel;
  final bool selected;
  final VoidCallback? onTap;

  const CozyDateChip({
    super.key,
    required this.topLabel,
    required this.bottomLabel,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CozyTappable(
      onTap: onTap,
      pressedScale: 0.93,
      child: AnimatedContainer(
        duration: CozyTokens.base,
        curve: Curves.easeOut,
        width: 56,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: selected ? CozyColors.primary : CozyColors.surfaceMuted,
          borderRadius: BorderRadius.circular(CozyTokens.radiusSm),
          border: Border.all(
            color: selected ? CozyColors.outline : CozyColors.border,
            width: selected
                ? CozyTokens.borderWidth
                : CozyTokens.borderWidthThin,
          ),
          boxShadow: selected ? CozyTokens.shadowHard : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              topLabel.toUpperCase(),
              style: CozyText.label.copyWith(
                fontSize: 11,
                color: selected
                    ? CozyColors.onPrimary.withValues(alpha: 0.85)
                    : CozyColors.inkMuted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              bottomLabel,
              style: CozyText.heading.copyWith(
                fontSize: 20,
                color: selected ? CozyColors.onPrimary : CozyColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
