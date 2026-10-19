import 'package:flutter/material.dart';

import '../../../core/theme/cozy/cozy.dart';
import 'cozy_card.dart';
import 'cozy_icon_chip.dart';

/// A compact stat card: icon chip + big value + small caps label.
/// e.g. `CozyStatCard(value: '0 min', label: 'Time saved', icon: HugeIcons.strokeRoundedTimer01)`.
class CozyStatCard extends StatelessWidget {
  final List<List<dynamic>>? icon;
  final Widget? iconChild;
  final Color iconBackground;
  final Color? iconColor;
  final String value;
  final String label;
  final VoidCallback? onTap;

  /// Render the icon chip as a circle (default) or a smooth rounded square.
  final bool iconCircle;

  /// Trace the chunky outline around the icon chip.
  final bool iconBordered;

  const CozyStatCard({
    super.key,
    required this.value,
    required this.label,
    this.icon,
    this.iconChild,
    this.iconBackground = CozyColors.surfaceMuted,
    this.iconColor,
    this.onTap,
    this.iconCircle = true,
    this.iconBordered = false,
  });

  @override
  Widget build(BuildContext context) {
    return CozyCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          CozyIconChip(
            icon: icon,
            iconColor: iconColor,
            iconSize: 22,
            size: 48,
            background: iconBackground,
            bordered: iconBordered,
            circle: iconCircle,
            child: iconChild,
          ),
          const SizedBox(height: 14),
          Text(value, style: CozyText.title.copyWith(fontSize: 24)),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            style: CozyText.label.copyWith(fontSize: 11, letterSpacing: 0.6),
          ),
        ],
      ),
    );
  }
}
