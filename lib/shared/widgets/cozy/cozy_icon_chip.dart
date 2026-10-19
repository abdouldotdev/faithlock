import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../core/theme/cozy/cozy.dart';

/// A rounded-square icon container with the chunky outline and a pastel fill.
/// Used as the leading visual inside [CozyChoiceCard], headers, etc.
///
/// Pass an [icon] for a HugeIcons glyph, or [child] for an emoji / illustration:
/// ```dart
/// CozyIconChip(child: Text('🙏', style: TextStyle(fontSize: 30)),
///   background: CozyColors.primaryLight)
/// ```
class CozyIconChip extends StatelessWidget {
  final List<List<dynamic>>? icon;
  final Widget? child;
  final Color background;
  final Color? iconColor;
  final double size;
  final double iconSize;

  /// Whether to draw the chunky outline border (true) or render a borderless
  /// soft pastel chip (false, e.g. inside stat cards).
  final bool bordered;

  /// Render as a circle instead of a smooth rounded square.
  final bool circle;

  const CozyIconChip({
    super.key,
    this.icon,
    this.child,
    this.background = CozyColors.surfaceMuted,
    this.iconColor,
    this.size = 64,
    this.iconSize = 30,
    this.bordered = true,
    this.circle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: circle
          ? BoxDecoration(
              color: background,
              shape: BoxShape.circle,
              border: bordered
                  ? Border.all(
                      color: CozyColors.outline,
                      width: CozyTokens.borderWidth,
                    )
                  : null,
            )
          : ShapeDecoration(
              color: background,
              shape: CozyTokens.smooth(
                CozyTokens.radiusMd,
                side: bordered
                    ? const BorderSide(
                        color: CozyColors.outline,
                        width: CozyTokens.borderWidth,
                      )
                    : BorderSide.none,
              ),
            ),
      child: child ??
          (icon != null
              ? HugeIcon(
                  icon: icon!,
                  size: iconSize,
                  color: iconColor ?? CozyColors.ink,
                )
              : null),
    );
  }
}
