import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../core/theme/cozy/cozy.dart';
import 'cozy_tappable.dart';

/// Floating dark rounded toolbar that appears when a verse is selected in reading mode.
///
/// Shows a row of icon actions: copy, highlight, bookmark, share.
/// This is UI-only — no real actions are wired.
///
/// ```dart
/// CozySelectionToolbar(
///   onCopy: () {},
///   onHighlight: () {},
///   onBookmark: () {},
///   onShare: () {},
/// )
/// ```
class CozySelectionToolbar extends StatelessWidget {
  final VoidCallback? onCopy;
  final VoidCallback? onHighlight;
  final VoidCallback? onBookmark;
  final VoidCallback? onShare;

  const CozySelectionToolbar({
    super.key,
    this.onCopy,
    this.onHighlight,
    this.onBookmark,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: CozyColors.ink,
        borderRadius: BorderRadius.circular(CozyTokens.radiusPill),
        border: Border.all(
          color: CozyColors.ink,
          width: CozyTokens.borderWidth,
        ),
        boxShadow: CozyTokens.shadowHard,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toolbarButton(HugeIcons.strokeRoundedCopy01, onCopy),
          const SizedBox(width: 2),
          _toolbarButton(HugeIcons.strokeRoundedHighlighter, onHighlight,
              activeColor: CozyColors.primary),
          const SizedBox(width: 2),
          _toolbarButton(HugeIcons.strokeRoundedBookmark01, onBookmark),
          const SizedBox(width: 2),
          _toolbarButton(HugeIcons.strokeRoundedShare01, onShare),
        ],
      ),
    );
  }

  Widget _toolbarButton(
    List<List<dynamic>> icon,
    VoidCallback? onTap, {
    Color? activeColor,
  }) {
    return CozyTappable(
      onTap: onTap,
      pressedScale: 0.88,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: activeColor != null
              ? activeColor.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(CozyTokens.radiusPill),
        ),
        child: HugeIcon(
          icon: icon,
          size: 22,
          color: activeColor ?? CozyColors.onPrimary,
        ),
      ),
    );
  }
}
