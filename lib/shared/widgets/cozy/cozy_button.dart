import 'package:flutter/material.dart';

import '../../../core/theme/cozy/cozy.dart';
import 'cozy_tappable.dart';

enum CozyButtonVariant { primary, secondary, soft }

/// Chunky cozy button: solid fill, thick outline, hard offset shadow.
/// [CozyButtonVariant.primary] = brand fill / white text,
/// [CozyButtonVariant.secondary] = white fill / ink text.
class CozyButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final CozyButtonVariant variant;
  final Widget? icon;
  final Widget? trailing;
  final bool isLoading;
  final bool isDisabled;
  final bool fullWidth;
  final double height;
  final double? borderRadius;
  final bool hapticFeedback;

  /// Optional fill override (e.g. a pastel chip). Falls back to the [variant]
  /// fill when null.
  final Color? fillColor;

  const CozyButton({
    super.key,
    required this.text,
    this.onTap,
    this.variant = CozyButtonVariant.primary,
    this.icon,
    this.trailing,
    this.isLoading = false,
    this.isDisabled = false,
    this.fullWidth = true,
    this.height = 58,
    this.borderRadius,
    this.hapticFeedback = true,
    this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    final bool enabled = !isDisabled && !isLoading && onTap != null;
    final bool isPrimary = variant == CozyButtonVariant.primary;
    final bool isSoft = variant == CozyButtonVariant.soft;

    final Color foreground = isPrimary ? CozyColors.onPrimary : CozyColors.ink;
    final Color fill = fillColor ??
        switch (variant) {
          CozyButtonVariant.primary => CozyColors.primary,
          CozyButtonVariant.secondary => CozyColors.surface,
          CozyButtonVariant.soft => CozyColors.surfaceMuted,
        };
    final BorderSide side = isSoft
        ? const BorderSide(
            color: CozyColors.border, width: CozyTokens.borderWidthThin)
        : const BorderSide(
            color: CozyColors.outline, width: CozyTokens.borderWidth);
    final double radius =
        borderRadius ?? (isSoft ? CozyTokens.radiusPill : CozyTokens.radiusMd);

    return CozyTappable(
      onTap: enabled ? onTap : null,
      hapticFeedback: hapticFeedback,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: Container(
          width: fullWidth ? double.infinity : null,
          height: height,
          // Center content only when stretched full-width; otherwise a non-null
          // alignment would force the box to fill the parent's width.
          alignment: fullWidth ? Alignment.center : null,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: ShapeDecoration(
            color: fill,
            shape: CozyTokens.smooth(radius, side: side),
            shadows: (enabled && !isSoft) ? CozyTokens.shadowHard : null,
          ),
          child: _content(foreground),
        ),
      ),
    );
  }

  Widget _content(Color foreground) {
    if (isLoading) {
      return SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.4,
          valueColor: AlwaysStoppedAnimation<Color>(foreground),
        ),
      );
    }

    return Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          IconTheme.merge(
            data: IconThemeData(color: foreground, size: 20),
            child: icon!,
          ),
          const SizedBox(width: 10),
        ],
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: CozyText.button.copyWith(color: foreground),
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 10),
          IconTheme.merge(
            data: IconThemeData(color: foreground, size: 20),
            child: trailing!,
          ),
        ],
      ],
    );
  }
}
