import 'package:flutter/material.dart';

import '../../../core/theme/cozy/cozy.dart';
import 'cozy_tappable.dart';

/// Circular number chip for chapter selectors.
///
/// - Selected: [CozyColors.primary] fill + white text + [CozyTokens.shadowHard].
/// - Unselected: [CozyColors.surface] fill + [CozyColors.outline] border.
///
/// ```dart
/// CozyChapterChip(
///   number: 1,
///   selected: true,
///   onTap: () => setState(() => _chapter = 1),
/// )
/// ```
class CozyChapterChip extends StatelessWidget {
  final int number;
  final bool selected;
  final VoidCallback? onTap;
  final double size;

  const CozyChapterChip({
    super.key,
    required this.number,
    this.selected = false,
    this.onTap,
    this.size = 46,
  });

  @override
  Widget build(BuildContext context) {
    return CozyTappable(
      onTap: onTap,
      pressedScale: 0.92,
      child: AnimatedContainer(
        duration: CozyTokens.base,
        curve: Curves.easeOut,
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? CozyColors.primary : CozyColors.surface,
          border: Border.all(
            color: CozyColors.outline,
            width: CozyTokens.borderWidth,
          ),
          boxShadow: selected ? CozyTokens.shadowHard : null,
        ),
        // Cap text scale so multi-digit chapters stay inside the fixed circle.
        child: Text(
          '$number',
          maxLines: 1,
          overflow: TextOverflow.clip,
          textScaler: TextScaler.noScaling,
          style: CozyText.label.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: selected ? CozyColors.onPrimary : CozyColors.ink,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}
