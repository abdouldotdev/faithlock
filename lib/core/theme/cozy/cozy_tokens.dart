import 'package:flutter/widgets.dart';
import 'package:smooth_corner/smooth_corner.dart';

import 'cozy_colors.dart';

/// Cozy design tokens: corner radius, spacing, motion, and elevation.
class CozyTokens {
  CozyTokens._();

  // ---- Corner radius ----
  // Generous, soft radii — cards/chips should read as rounded, not boxy.
  static const double radiusSm = 16;
  static const double radiusMd = 22;
  static const double radiusLg = 32;
  static const double radiusPill = 100;

  // ---- Borders ----
  /// Chunky signature border width.
  static const double borderWidth = 2.5;

  /// Subtle hairline border width.
  static const double borderWidthThin = 1.5;

  // ---- Shapes (iOS-style continuous-curvature corners) ----
  // 1.0 = maximum continuous-curvature "squircle" (matches the reference
  // mockups). Lower values flatten back toward a classic circular rounded rect.
  static const double smoothness = 1.0;

  /// Squircle shape for [ShapeDecoration] (all corners).
  static ShapeBorder smooth(double radius, {BorderSide side = BorderSide.none}) {
    return SmoothRectangleBorder(
      smoothness: smoothness,
      side: side,
      borderRadius: BorderRadius.circular(radius),
    );
  }

  /// Squircle shape with only the top corners rounded.
  static ShapeBorder smoothTop(double radius) {
    return SmoothRectangleBorder(
      smoothness: smoothness,
      borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
    );
  }

  // ---- Spacing (8pt-ish scale) ----
  static const double space4 = 4;
  static const double space8 = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space32 = 32;

  // ---- Motion ----
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration base = Duration(milliseconds: 220);

  // ---- Elevation ----
  /// Signature chunky offset shadow (solid, no blur) — the "lifted sticker" look.
  /// Y-offset kept modest (5) so the shadow doesn't bleed into the gap below
  /// stacked cards (option lists, plan tiers) where it used to overlap.
  static const List<BoxShadow> shadowHard = [
    BoxShadow(
      color: CozyColors.ink,
      offset: Offset(3, 5),
      blurRadius: 0,
    ),
  ];

  /// Soft, diffuse shadow for cards and secondary buttons.
  static List<BoxShadow> get shadowSoft => [
        BoxShadow(
          color: CozyColors.ink.withValues(alpha: 0.06),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  /// Tinted shadow for primary buttons and active chips.
  static List<BoxShadow> get shadowButton => [
        BoxShadow(
          color: CozyColors.primary.withValues(alpha: 0.28),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ];
}
