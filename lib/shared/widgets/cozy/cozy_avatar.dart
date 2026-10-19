import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../core/theme/cozy/cozy.dart';
import 'cozy_tappable.dart';

/// Circular chunky avatar — outline + hard shadow. Accepts an emoji [child],
/// an [icon] (HugeIcons glyph), or an [image]. Pass [onTap] to make it pressable (profile entry).
class CozyAvatar extends StatelessWidget {
  final Widget? child;
  final List<List<dynamic>>? icon;
  final ImageProvider? image;
  final double size;
  final Color background;
  final bool shadow;
  final VoidCallback? onTap;

  const CozyAvatar({
    super.key,
    this.child,
    this.icon,
    this.image,
    this.size = 52,
    this.background = CozyColors.surfaceMuted,
    this.shadow = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        border: Border.all(
          color: CozyColors.outline,
          width: CozyTokens.borderWidth,
        ),
        boxShadow: shadow ? CozyTokens.shadowHard : null,
        image: image != null
            ? DecorationImage(image: image!, fit: BoxFit.cover)
            : null,
      ),
      child: image != null
          ? null
          : child ??
              (icon != null
                  ? HugeIcon(
                      icon: icon!,
                      size: size * 0.45,
                      color: CozyColors.ink,
                    )
                  : null),
    );

    if (onTap == null) return avatar;
    return CozyTappable(onTap: onTap, pressedScale: 0.92, child: avatar);
  }
}
