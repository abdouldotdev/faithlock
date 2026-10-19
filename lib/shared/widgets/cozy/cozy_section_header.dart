import 'package:flutter/widgets.dart';

import '../../../core/theme/cozy/cozy.dart';

/// Title + optional subtitle, with an optional [trailing] widget.
/// Override [titleStyle] (e.g. [CozyText.display]) for page-level headers.
class CozySectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final TextStyle? titleStyle;
  final Widget? trailing;

  const CozySectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.titleStyle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: titleStyle ?? CozyText.title),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: CozyText.subtitle),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 12),
          trailing!,
        ],
      ],
    );
  }
}
