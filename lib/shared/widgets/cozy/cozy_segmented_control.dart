import 'package:flutter/material.dart';

import '../../../core/theme/cozy/cozy.dart';
import 'cozy_tappable.dart';

/// Pill-shaped segmented toggle (Old Testament / New Testament style).
///
/// Container = [CozyColors.surfaceMuted] pill with thin border.
/// Active segment = [CozyColors.primary] fill + white text + [CozyTokens.shadowHard].
/// Inactive segment = transparent + [CozyColors.inkMuted] text.
///
/// ```dart
/// CozySegmentedControl(
///   segments: const ['Old Testament', 'New Testament'],
///   selectedIndex: 0,
///   onChanged: (i) => setState(() => _tab = i),
/// )
/// ```
class CozySegmentedControl extends StatelessWidget {
  final List<String> segments;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const CozySegmentedControl({
    super.key,
    required this.segments,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: CozyColors.surfaceMuted,
        borderRadius: BorderRadius.circular(CozyTokens.radiusPill),
        border: Border.all(
          color: CozyColors.border,
          width: CozyTokens.borderWidthThin,
        ),
      ),
      child: Row(
        children: List.generate(segments.length, (index) {
          final bool active = index == selectedIndex;
          return Expanded(
            child: CozyTappable(
              onTap: () => onChanged(index),
              pressedScale: 0.95,
              child: AnimatedContainer(
                duration: CozyTokens.base,
                curve: Curves.easeOut,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? CozyColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(CozyTokens.radiusPill),
                  border: active
                      ? Border.all(
                          color: CozyColors.outline,
                          width: CozyTokens.borderWidth,
                        )
                      : null,
                  boxShadow: active ? CozyTokens.shadowHard : null,
                ),
                child: Text(
                  segments[index],
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CozyText.label.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: active ? CozyColors.onPrimary : CozyColors.inkMuted,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
