import 'package:flutter/widgets.dart';

import '../../../core/theme/cozy/cozy.dart';
import 'cozy_tappable.dart';

/// Generic chunky surface: white fill, thick outline, hard offset shadow.
/// The base container for hero cards, stat cards, etc. Pass [onTap] to make it
/// pressable. Set [shadow] false for a flat bordered card.
class CozyCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final double? borderRadius;
  final bool shadow;
  final VoidCallback? onTap;

  const CozyCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.borderRadius,
    this.shadow = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: ShapeDecoration(
        color: color ?? CozyColors.surface,
        shape: CozyTokens.smooth(
          borderRadius ?? CozyTokens.radiusLg,
          side: const BorderSide(
            color: CozyColors.outline,
            width: CozyTokens.borderWidth,
          ),
        ),
        shadows: shadow ? CozyTokens.shadowHard : null,
      ),
      child: child,
    );

    if (onTap == null) return card;
    return CozyTappable(onTap: onTap, pressedScale: 0.98, child: card);
  }
}
