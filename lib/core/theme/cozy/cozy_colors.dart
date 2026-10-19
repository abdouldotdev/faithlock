import 'package:flutter/material.dart';

import '../../constants/core/fast_colors.dart';

/// Cozy design-system palette.
///
/// Built on FaithLock's EXISTING brand colors ([FastColors]) wherever a token
/// maps cleanly (brand + semantic). The warm neutrals (cream canvas, brown ink)
/// are the only derived values — FaithLock's base palette has no warm neutral.
/// They harmonize with the existing onboarding warm tones (gold #C9A962,
/// beige #E8DCC4). Swap them for [FastColors.scaffoldBackground] /
/// [FastColors.textPrimary] if you prefer the existing cool neutrals.
class CozyColors {
  CozyColors._();

  // ---- Brand / primary action (warm terracotta — matches the cozy mockups) ----
  // Intentionally overrides FaithLock's pink brand (#F2647C) for the cozy
  // system: every reference mockup uses terracotta for CTAs, active nav, and
  // selected states. Editing these 3 lines re-themes the whole system.
  static const Color primary = Color(0xFFD68A4E); // terracotta
  static const Color primaryDark = Color(0xFFC0763C);
  static const Color primaryLight = Color(0xFFE8B488);

  /// Warm gold accent — mirrors OnboardingTheme.goldColor.
  static const Color gold = Color(0xFFC9A962);

  // ---- Pastel icon-chip fills ----
  static const Color peach = Color(0xFFF3D9BE); // soft peach
  static const Color sage = Color(0xFFCFDDC3); // soft sage

  // ---- Warm neutrals (derived — see class doc) ----
  /// Cream app canvas.
  static const Color background = Color(0xFFFBF3E2);

  /// Card / elevated surface.
  static const Color surface = Color(0xFFFFFDF8);

  /// Subtle beige-tinted surface (icon chips, unselected date chips).
  static const Color surfaceMuted = Color(0xFFF3E7CE);

  /// Mirrors OnboardingTheme.beigeColor.
  static const Color beige = Color(0xFFE8DCC4);

  // ---- Ink (text) ----
  static const Color ink = Color(0xFF3D2B1F); // warm brown
  static const Color inkMuted = Color(0xFF9C8773); // muted brown
  static const Color onPrimary = FastColors.white;

  // ---- Lines ----
  static const Color border = Color(0xFFEAD9BC);
  static const Color divider = Color(0xFFEFE3CC);

  /// Chunky dark outline (cards, buttons, icon chips) — the signature border.
  static const Color outline = ink;

  // ---- Semantic (sourced from FastColors) ----
  static const Color success = FastColors.successGreen; // #4CAF50
  static const Color error = FastColors.error; // #E57373
  static const Color warning = FastColors.warning; // #FFB74D

  // ---- Derived runtime tints ----
  /// Light tint of [primary] for selected card / row fills.
  static Color get selectedFill => primary.withValues(alpha: 0.12);

  /// Press / hover overlay.
  static Color get pressedOverlay => ink.withValues(alpha: 0.06);
}
