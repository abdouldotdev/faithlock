import 'package:flutter/widgets.dart';

import '../../../core/theme/cozy/cozy.dart';

/// Circular badge with a short text label (e.g. "Gn", "KJV").
///
/// - Flat by default (no hard shadow) — use [shadow] to opt-in.
/// - Used for book abbreviations in lists and version pickers.
///
/// ```dart
/// CozyLetterBadge(
///   label: 'Gn',
///   background: CozyColors.peach,
///   size: 52,
/// )
/// ```
class CozyLetterBadge extends StatelessWidget {
  final String label;
  final Color background;
  final double size;
  final TextStyle? textStyle;
  final Color? textColor;
  final bool shadow;
  final bool showBorder;

  const CozyLetterBadge({
    super.key,
    required this.label,
    this.background = CozyColors.surfaceMuted,
    this.size = 52,
    this.textStyle,
    this.textColor,
    this.shadow = false,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final double fontSize = size * 0.33;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(
                color: CozyColors.outline,
                width: CozyTokens.borderWidth,
              )
            : null,
        boxShadow: shadow ? CozyTokens.shadowHard : null,
      ),
      // Cap text scale so the abbreviation stays inside the fixed circle.
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.clip,
        textScaler: TextScaler.noScaling,
        style: (textStyle ??
                CozyText.label.copyWith(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ))
            .copyWith(
          color: textColor ?? CozyColors.ink,
        ),
      ),
    );
  }
}
