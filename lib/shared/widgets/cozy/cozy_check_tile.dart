import 'package:flutter/material.dart';

import '../../../core/theme/cozy/cozy.dart';
import 'cozy_checkbox.dart';
import 'cozy_tappable.dart';

/// A list row with a leading checkbox and a label.
/// [filled] = white rounded card (habit list); otherwise a plain row (to-do
/// list). Tapping anywhere toggles. When checked, [strikeThroughWhenChecked]
/// strikes + mutes the label.
class CozyCheckTile extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool filled;
  final bool strikeThroughWhenChecked;
  final Color? activeColor;
  final Widget? trailing;

  const CozyCheckTile({
    super.key,
    required this.label,
    required this.value,
    this.onChanged,
    this.filled = true,
    this.strikeThroughWhenChecked = false,
    this.activeColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final bool struck = value && strikeThroughWhenChecked;

    final row = Row(
      children: [
        // Display-only — the whole tile is the tap target.
        CozyCheckbox(value: value, activeColor: activeColor),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: CozyText.body.copyWith(
              color: struck ? CozyColors.inkMuted : CozyColors.ink,
              decoration: struck ? TextDecoration.lineThrough : null,
              decorationColor: CozyColors.inkMuted,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );

    void toggle() => onChanged?.call(!value);

    if (!filled) {
      return CozyTappable(
        onTap: onChanged == null ? null : toggle,
        pressedScale: 1.0,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: row,
        ),
      );
    }

    return CozyTappable(
      onTap: onChanged == null ? null : toggle,
      pressedScale: 0.99,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CozyColors.surface,
          borderRadius: BorderRadius.circular(CozyTokens.radiusMd),
          border: Border.all(
            color: CozyColors.border,
            width: CozyTokens.borderWidthThin,
          ),
        ),
        child: row,
      ),
    );
  }
}
