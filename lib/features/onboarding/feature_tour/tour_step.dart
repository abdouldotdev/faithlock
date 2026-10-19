import 'package:flutter/widgets.dart';

/// Where the spotlight card sits relative to the highlighted element when there
/// is room on both sides. [auto] picks whichever half of the screen (above or
/// below the target) has more space.
enum TourCardAnchor { auto, above, below, center }

/// A single beat in the first-day feature tour: a spotlit on-screen element
/// plus the short "here's what this does" copy that floats beside it.
///
/// [targetKey] points at the live widget to cut a hole around. When it is null
/// the step is a full-screen message (welcome / wrap-up) with no spotlight.
/// [navIndex], when set, switches the bottom-nav tab to that index *before* the
/// step is measured, so cross-tab targets (Bible) are laid out before we read
/// their geometry.
class TourStep {
  const TourStep({
    required this.id,
    required this.titleKey,
    required this.bodyKey,
    this.targetKey,
    this.icon,
    this.navIndex,
    this.anchor = TourCardAnchor.auto,
    this.cutoutRadius = 24,
    this.cutoutPadding = 8,
    this.shape = TourCutoutShape.rrect,
    this.interactive = false,
    this.hintKey,
    this.onReveal,
    this.spotlightBuilder,
    this.cutoutTransform,
  });

  /// Stable analytics / debug identifier.
  final String id;

  /// Translation keys (resolved with GetX `.tr` at paint time so the copy
  /// follows the active locale).
  final String titleKey;
  final String bodyKey;

  /// `HugeIcons.strokeRounded*` glyph shown in the card header chip.
  final List<List<dynamic>>? icon;

  /// Live widget to spotlight. Null → centered full-screen message.
  final GlobalKey? targetKey;

  /// Bottom-nav tab to activate before measuring this step.
  final int? navIndex;

  final TourCardAnchor anchor;
  final double cutoutRadius;
  final double cutoutPadding;
  final TourCutoutShape shape;

  /// Interactive step: the veil lets taps fall through to the real spotlit
  /// element (so the user genuinely performs the action), the card drops its
  /// "Next" button, and the tour auto-advances once the action's flow closes
  /// and we return to the host screen.
  final bool interactive;

  /// Optional translation key for the small call-to-action hint shown on an
  /// interactive step (e.g. "Tap to pray") in place of the Next button.
  final String? hintKey;

  /// Side effect to run when this step is revealed — e.g. nudging the garden so
  /// the user watches it grow on the payoff step. Awaited but never blocks.
  final Future<void> Function()? onReveal;

  /// Optional extra art anchored to the spotlight cutout. Given the build
  /// context and the target's (lerped, global) [Rect], it returns a widget the
  /// overlay drops straight into its full-screen Stack — so the builder owns its
  /// own [Positioned] placement (and should wrap interactive art in an
  /// [IgnorePointer] so it never steals taps). Only the garden step uses it, to
  /// stand Toby beside the highlighted pot watering it.
  final Widget Function(BuildContext context, Rect targetRect)?
      spotlightBuilder;

  /// Optional transform from the measured target rect to the rect actually lit
  /// (and used to anchor the ring + card). Applied each frame *after* the morph
  /// lerp, so [spotlightBuilder] still receives the raw target rect to anchor
  /// to. The garden step uses it to grow the hole to the union of the pot +
  /// Toby and balance its side margins. Null → the target rect is lit as-is.
  final Rect Function(BuildContext context, Rect targetRect)? cutoutTransform;

  bool get isMessage => targetKey == null;
}

/// Cutout silhouette around the target. [circle] suits round targets (FAB),
/// [rrect] suits cards, buttons and nav items.
enum TourCutoutShape { rrect, circle }
