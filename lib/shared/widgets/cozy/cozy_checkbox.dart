import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../core/theme/cozy/cozy.dart';
import 'cozy_tappable.dart';

/// Rounded-square checkbox with the chunky outline.
/// Checked = [activeColor] fill + white check; unchecked = outlined.
class CozyCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final double size;
  final Color? activeColor;
  final bool hapticFeedback;

  const CozyCheckbox({
    super.key,
    required this.value,
    this.onChanged,
    this.size = 26,
    this.activeColor,
    this.hapticFeedback = true,
  });

  @override
  Widget build(BuildContext context) {
    final Color active = activeColor ?? CozyColors.primary;

    return CozyTappable(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      hapticFeedback: hapticFeedback,
      pressedScale: 0.88,
      child: AnimatedContainer(
        duration: CozyTokens.fast,
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: value ? active : CozyColors.surface,
          borderRadius: BorderRadius.circular(size * 0.3),
          border: Border.all(
            color: value ? active : CozyColors.outline,
            width: 2,
          ),
        ),
        child: value
            ? HugeIcon(
                icon: HugeIcons.strokeRoundedTick02,
                size: size * 0.64,
                color: CozyColors.onPrimary,
              )
            : null,
      ),
    );
  }
}
