import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../core/theme/cozy/cozy.dart';
import 'cozy_icon_chip.dart';
import 'cozy_tappable.dart';

/// Chunky selectable / navigation card (icon chip + title + optional subtitle).
///
/// - Navigation use: `showChevron: true`.
/// - Selectable use: drive `selected` — a check badge appears and the border
///   turns to [accentColor].
/// - Pass [leading] to replace the square [CozyIconChip] with any widget
///   (e.g. a circular [CozyLetterBadge]).
/// - Set [filledWhenSelected] to fill the entire card with [accentColor] when
///   selected (version-picker solid-orange style). Text becomes white.
class CozyChoiceCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<List<dynamic>>? icon;
  final Widget? iconChild;
  final Color iconBackground;
  final Color? iconColor;
  final bool selected;
  final bool showChevron;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? accentColor;

  /// When provided, replaces the square [CozyIconChip] with this widget.
  final Widget? leading;

  /// When true and [selected] is true, fills the card with [accentColor]
  /// and uses white text. Defaults to false (selectedFill tint behaviour).
  final bool filledWhenSelected;

  const CozyChoiceCard({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.iconChild,
    this.iconBackground = CozyColors.surfaceMuted,
    this.iconColor,
    this.selected = false,
    this.showChevron = false,
    this.onTap,
    this.trailing,
    this.accentColor,
    this.leading,
    this.filledWhenSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color accent = accentColor ?? CozyColors.primary;

    // Determine fill mode.
    final bool solidFill = selected && filledWhenSelected;

    // Card background.
    final Color cardColor = solidFill
        ? accent
        : selected
            ? CozyColors.selectedFill
            : CozyColors.surface;

    // Border color.
    final Color borderColor = selected ? accent : CozyColors.outline;

    // Text colors.
    final Color titleColor = solidFill ? CozyColors.onPrimary : (selected ? accent : CozyColors.ink);
    final Color subtitleColor = solidFill ? CozyColors.onPrimary.withValues(alpha: 0.75) : CozyColors.inkMuted;

    Widget? trailingWidget = trailing;
    trailingWidget ??= selected
        ? _checkBadge(accent, solidFill: solidFill)
        : showChevron
            ? const HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                size: 28,
                color: CozyColors.inkMuted,
              )
            : null;

    // Determine leading widget.
    final Widget leadingWidget = leading ??
        CozyIconChip(
          icon: icon,
          iconColor: iconColor,
          background: iconBackground,
          child: iconChild,
        );

    return CozyTappable(
      onTap: onTap,
      pressedScale: 0.98,
      child: AnimatedContainer(
        duration: CozyTokens.base,
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(16),
        decoration: ShapeDecoration(
          color: cardColor,
          shape: CozyTokens.smooth(
            CozyTokens.radiusLg,
            side: BorderSide(color: borderColor, width: CozyTokens.borderWidth),
          ),
          shadows: CozyTokens.shadowHard,
        ),
        child: Row(
          children: [
            leadingWidget,
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: CozyText.heading.copyWith(color: titleColor),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: CozyText.subtitle.copyWith(color: subtitleColor),
                    ),
                  ],
                ],
              ),
            ),
            if (trailingWidget != null) ...[
              const SizedBox(width: 8),
              trailingWidget,
            ],
          ],
        ),
      ),
    );
  }

  Widget _checkBadge(Color accent, {bool solidFill = false}) {
    // When the card is solid-filled, use white badge with accent check.
    final Color badgeColor = solidFill ? CozyColors.onPrimary : accent;
    final Color checkColor = solidFill ? accent : CozyColors.onPrimary;
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: badgeColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: solidFill ? CozyColors.onPrimary : CozyColors.surface,
          width: 2,
        ),
      ),
      child: HugeIcon(
        icon: HugeIcons.strokeRoundedTick02,
        size: 15,
        color: checkColor,
      ),
    );
  }
}
