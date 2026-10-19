import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../core/theme/cozy/cozy.dart';
import 'cozy_tappable.dart';

class CozyNavItem {
  /// Builds the tab glyph for the current state. [active] picks the
  /// filled/outline variant, [color] is the resolved tint, [size] the glyph
  /// size. A builder (rather than a single icon) lets each tab supply its own
  /// filled+outline pair from any icon family.
  final Widget Function(bool active, Color color, double size) iconBuilder;
  final String label;

  /// Optional anchor for coach-mark / feature-tour spotlights. When set, it is
  /// attached to this tab's tappable cell so the tour can measure just this
  /// item (rather than the whole nav bar).
  final Key? itemKey;

  const CozyNavItem({
    required this.iconBuilder,
    required this.label,
    this.itemKey,
  });
}

/// Renders a HugeIcons glyph for a bottom-nav tab, tinted instantly via
/// [ColorFiltered]. The underlying [HugeIcon] is built with a constant color +
/// stroke, so its SVG string never changes and is parsed only once — switching
/// tabs recolors at the compositing layer instead of triggering HugeIcon's
/// async SVG re-parse (which left the previous tab's color lingering a moment).
class CozyNavIcon extends StatelessWidget {
  const CozyNavIcon({
    super.key,
    required this.icon,
    required this.color,
    required this.size,
  });

  /// A `HugeIcons.strokeRounded*` constant.
  final List<List<dynamic>> icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    // srcIn keeps the glyph's alpha (anti-aliasing) and paints it [color];
    // the inner HugeIcon color is irrelevant, only its shape matters.
    return ColorFiltered(
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      child: HugeIcon(
        icon: icon,
        color: const Color(0xFF000000),
        size: size,
        strokeWidth: 2.0,
      ),
    );
  }
}

/// Bottom navigation — a floating pill detached from the screen edge: rounded on
/// all sides, traced with the chunky dark outline and lifted by the signature
/// solid (no-blur) shadow. Active item uses the filled icon + brand color;
/// inactive items use the outline icon + muted ink.
class CozyBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<CozyNavItem> items;

  const CozyBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  static const double _radius = 32;

  /// Inactive tab tint — a medium warm brown (darker than [CozyColors.inkMuted]
  /// so unselected tabs read clearly against the cream surface, as in the mockup).
  static const Color _inactive = Color(0xFF8A7159);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: CozyColors.surface,
            shape: CozyTokens.smooth(
              _radius,
              side: const BorderSide(
                color: CozyColors.outline,
                width: CozyTokens.borderWidth,
              ),
            ),
            shadows: const [
              // Solid, no-blur drop — the "lifted sticker" look, centered below
              // the floating pill rather than the offset card shadow.
              BoxShadow(
                color: CozyColors.ink,
                offset: Offset(0, 3),
                blurRadius: 0,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(items.length, (index) {
                final item = items[index];
                final bool active = index == currentIndex;
                final Color color = active ? CozyColors.primary : _inactive;
                return Expanded(
                  child: CozyTappable(
                    onTap: () => onTap(index),
                    pressedScale: 0.9,
                    child: Padding(
                      key: item.itemKey,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          item.iconBuilder(active, color, 28),
                          const SizedBox(height: 5),
                          Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: CozyText.label.copyWith(
                              fontSize: 12,
                              color: color,
                              letterSpacing: 0.2,
                              fontWeight:
                                  active ? FontWeight.w700 : FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
