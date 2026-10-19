import 'package:faithlock/services/analytics/posthog/export.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../core/theme/cozy/cozy.dart';
import 'cozy_card.dart';
import 'cozy_icon_button.dart';
import 'cozy_verse_share.dart';

/// Reusable "Verse of the Day" card.
///
/// Pure presentation — pass the verse [text] + [reference] and a [loading]
/// flag; the host wires it to its own source (e.g. a controller's reactive
/// `verseOfDay`). Includes a share button that exports the verse as a nicely
/// designed image via [shareVerseAsImage].
///
/// ```dart
/// Obx(() => CozyVerseOfDayCard(
///   text: ctrl.verseOfDay.value?.text,
///   reference: ctrl.verseOfDay.value?.reference,
///   loading: ctrl.isVerseLoading.value,
/// ))
/// ```
class CozyVerseOfDayCard extends StatefulWidget {
  /// Raw verse text (un-quoted). A gentle fallback is shown when null.
  final String? text;

  /// Verse reference, e.g. "Psalm 119:105".
  final String? reference;

  /// Renders the skeleton loading state when true.
  final bool loading;

  /// Whether the share affordance is shown (hidden while loading regardless).
  final bool showShare;

  /// Whether the card is actually on screen. When false, the
  /// `bible_verse_of_day_viewed` event is suppressed — the host tab can be
  /// built (and this card mounted) by an IndexedStack without being visible.
  final bool visible;

  const CozyVerseOfDayCard({
    super.key,
    this.text,
    this.reference,
    this.loading = false,
    this.showShare = true,
    this.visible = true,
  });

  static const String _fallbackText = 'Thy word is a lamp unto my feet…';
  static const String _fallbackRef = 'Psalm 119:105';

  @override
  State<CozyVerseOfDayCard> createState() => _CozyVerseOfDayCardState();
}

class _CozyVerseOfDayCardState extends State<CozyVerseOfDayCard> {
  bool _sharing = false;

  final PostHogService _analytics = PostHogService.instance;

  // Ensures `bible_verse_of_day_viewed` fires only once per mount, not on
  // every Obx rebuild.
  bool _viewedTracked = false;

  void _track(String event, [Map<String, dynamic> props = const {}]) {
    if (_analytics.isReady) _analytics.events.trackCustom(event, props);
  }

  String get _verseText => (widget.text?.trim().isNotEmpty ?? false)
      ? widget.text!.trim()
      : CozyVerseOfDayCard._fallbackText;

  String get _refText => (widget.reference?.trim().isNotEmpty ?? false)
      ? widget.reference!.trim()
      : CozyVerseOfDayCard._fallbackRef;

  /// Fires the one-time viewed event once a real verse has loaded.
  void _trackViewedOnce() {
    if (_viewedTracked || widget.loading || !widget.visible) return;
    final hasVerse = widget.reference?.trim().isNotEmpty ?? false;
    if (!hasVerse) return;
    _viewedTracked = true;
    _track('bible_verse_of_day_viewed', {'verse_ref': _refText});
  }

  @override
  Widget build(BuildContext context) {
    if (widget.loading) return _buildSkeleton();

    _trackViewedOnce();

    return CozyCard(
      color: CozyColors.surfaceMuted,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Capped at 3 lines so the card keeps a compact, predictable
                // height; anything longer is truncated with an ellipsis.
                Text(
                  '"$_verseText"',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: CozyColors.ink,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _refText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: CozyColors.primary,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          if (widget.showShare) ...[
            const SizedBox(width: 8),
            CozyIconButton(
              icon: HugeIcons.strokeRoundedShare08,
              onTap: _sharing ? null : _share,
              size: 40,
              backgroundColor: CozyColors.surface,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return CozyCard(
      color: CozyColors.surfaceMuted,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bar(double.infinity),
                const SizedBox(height: 8),
                _bar(120),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bar(double width) => Container(
        height: 14,
        width: width,
        decoration: BoxDecoration(
          color: CozyColors.border,
          borderRadius: BorderRadius.circular(4),
        ),
      );

  // ── Share ────────────────────────────────────────────────────────────────

  Future<void> _share() async {
    setState(() => _sharing = true);
    _track('bible_verse_of_day_shared', {'verse_ref': _refText});
    try {
      await shareVerseAsImage(
        context,
        verseText: _verseText,
        reference: _refText,
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }
}
