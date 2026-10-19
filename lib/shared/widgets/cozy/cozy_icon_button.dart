import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../core/theme/cozy/cozy.dart';
import 'cozy_tappable.dart';

/// Rounded-square icon button with the chunky outline + hard offset shadow.
/// This is the back-button style from the reference design.
class CozyIconButton extends StatelessWidget {
  final List<List<dynamic>> icon;
  final VoidCallback? onTap;
  final double size;
  final Color? iconColor;
  final Color? backgroundColor;

  const CozyIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 52,
    this.iconColor,
    this.backgroundColor,
  });

  /// Convenience back button (left arrow).
  const CozyIconButton.back({
    super.key,
    this.onTap,
    this.size = 52,
    this.iconColor,
    this.backgroundColor,
  }) : icon = HugeIcons.strokeRoundedArrowLeft01;

  @override
  Widget build(BuildContext context) {
    return CozyTappable(
      onTap: onTap,
      pressedScale: 0.92,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: ShapeDecoration(
          color: backgroundColor ?? CozyColors.surface,
          shape: CozyTokens.smooth(
            CozyTokens.radiusMd,
            side: const BorderSide(
              color: CozyColors.outline,
              width: CozyTokens.borderWidth,
            ),
          ),
          shadows: CozyTokens.shadowHard,
        ),
        child: HugeIcon(
          icon: icon,
          size: size * 0.42,
          color: iconColor ?? CozyColors.ink,
        ),
      ),
    );
  }
}
