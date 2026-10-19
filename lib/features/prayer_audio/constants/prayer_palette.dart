import 'package:flutter/widgets.dart';

/// Warm, light "neo-brutalist" palette for the Prayer audio experience.
///
/// This is intentionally its own palette (rather than the app-wide dark
/// [OnboardingTheme]) — the Pray surface is a calm, paper-cream space with
/// thick espresso borders, hard offset shadows, and a single warm-orange
/// accent. Matches docs/design/new/prayers/.
class PrayerPalette {
  PrayerPalette._();

  /// Paper-cream page background.
  static const Color cream = Color(0xFFFBEED1);

  /// Cards / sheets sit on pure white.
  static const Color card = Color(0xFFFFFFFF);

  /// Espresso ink — primary text, borders, and the hard offset shadow.
  static const Color ink = Color(0xFF3D2817);

  /// Warm orange accent — CTAs, play controls, active reference text.
  static const Color orange = Color(0xFFE3883A);

  /// Soft peach — badges and icon-chip fills.
  static const Color peach = Color(0xFFF6DCBF);

  /// Dimmed reading text (upcoming / past lines in the karaoke reader).
  static const Color muted = Color(0xFFB7A88F);

  /// Secondary labels (durations, captions).
  static const Color subtle = Color(0xFF9B8C79);

  /// Standard font — keeps continuity with the rest of the app.
  static const String font = 'Satoshi';

  // ── Neo-brutalist building blocks ──────────────────────────────────────────

  /// A hard (un-blurred) offset shadow in espresso ink — the signature look.
  static List<BoxShadow> hardShadow({
    Offset offset = const Offset(0, 6),
    Color? color,
  }) =>
      [
        BoxShadow(
          color: color ?? ink,
          offset: offset,
          blurRadius: 0,
          spreadRadius: 0,
        ),
      ];

  /// White card with a thick ink border + hard drop shadow.
  static BoxDecoration cardDecoration({
    double radius = 24,
    Color fill = card,
    double borderWidth = 2.5,
    Offset shadowOffset = const Offset(0, 6),
  }) =>
      BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: ink, width: borderWidth),
        boxShadow: hardShadow(offset: shadowOffset),
      );
}
