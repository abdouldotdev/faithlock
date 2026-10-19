import 'package:flutter/material.dart';

/// iOS-style Design System for FaithLock Onboarding
/// Clean, modern, professional - inspired by Apple's design language
class OnboardingTheme {
  // ==================== COLOR SYSTEM ====================
  // iOS Semantic Colors

  /// App background — Apple dark-gray (NOT pure black) for layered depth.
  static const Color backgroundColor = Color(0xFF1C1C1E);

  /// Primary gold - more subtle and refined
  static const Color goldColor = Color(0xFFC9A962);

  /// Secondary beige - softer tone
  static const Color beigeColor = Color(0xFFE8DCC4);

  /// iOS label colors
  static const Color labelPrimary = Color(0xFFFFFFFF);
  static const Color labelSecondary = Color(0x99FFFFFF); // 60% white
  static const Color labelTertiary = Color(0x4DFFFFFF); // 30% white

  /// iOS system colors
  static const Color systemBlue = Color(0xFF007AFF);
  static const Color systemOrange = Color(0xFFFF9500);
  static const Color systemRed = Color(0xFFFF453A);
  static const Color systemGreen = Color(0xFF32D74B);

  /// Card/Container backgrounds
  static const Color cardBackground = Color(0x0DFFFFFF); // 5% white
  static const Color cardBorder = Color(0x1AFFFFFF); // 10% white

  // Legacy color aliases for compatibility
  static const Color grayColor = labelSecondary;
  static const Color redAlert = systemRed;
  static const Color blueSpirit = systemBlue;

  // ==================== TYPOGRAPHY ====================
  // Garamond Font System - Optimized for elegance and readability

  /// Satoshi for all text
  static const String fontFamily = 'Satoshi';

  /// Satoshi for body text
  static const String bodyFontFamily = 'Satoshi';

  /// Font family for numeric / glyph-heavy displays (percentages, big stats,
  /// option pills with symbols like '×').
  ///
  /// Set to `null` to fall back to the platform default (SF Pro on iOS,
  /// Roboto on Android). Garamond is avoided here because it lacks proper
  /// glyphs for several symbols (×, %) and renders digits stylistically.
  static const String? numericFontFamily = null;

  // Garamond Font Sizes (optimized for serif readability)
  static const double largeTitleSize = 42.0;
  static const double title1Size = 34.0;
  static const double title2Size = 26.0;
  static const double title3Size = 22.0;
  static const double bodySize = 20.0;
  static const double calloutSize = 18.0;
  static const double subheadSize = 16.0;
  static const double footnoteSize = 14.0;
  static const double caption1Size = 13.0;

  // Satoshi Line Heights (sans-serif — tight & punchy)
  static const double lineHeightTight = 1.05; // Headlines / large titles
  static const double lineHeightNormal = 1.15; // Body / callouts
  static const double lineHeightRelaxed = 1.3; // Long-form reading

  // ==================== SPACING ====================
  // iOS Standard Spacing (multiples of 4)

  static const double horizontalPadding = 20.0; // iOS standard
  static const double verticalPadding = 24.0;

  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;
  static const double space48 = 48.0;

  // ==================== CORNER RADIUS ====================

  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 20.0;

  // ==================== TEXT STYLES ====================

  /// Large Title - 42pt Regular (Garamond looks heavier, use lighter weight)
  static TextStyle get largeTitle => const TextStyle(
        fontFamily: fontFamily,
        fontSize: largeTitleSize,
        fontWeight: FontWeight.w700, // Bold
        color: labelPrimary,
        height: lineHeightTight,
        letterSpacing: -0.3, // Tighter for large Garamond
      );

  /// Title 1 - 34pt Regular (for biblical verses)
  static TextStyle get title1 => const TextStyle(
        fontFamily: fontFamily,
        fontSize: title1Size,
        fontWeight: FontWeight.w600, // Bold
        color: labelPrimary,
        height: lineHeightNormal,
        letterSpacing: -0.2,
      );

  /// Title 2 - 26pt Regular (for biblical text)
  static TextStyle get title2 => const TextStyle(
        fontFamily: fontFamily,
        fontSize: title2Size,
        fontWeight: FontWeight.w600, // Bold
        color: labelPrimary,
        height: lineHeightNormal,
        letterSpacing: 0.0,
      );

  /// Title 3 - 22pt Regular (for questions)
  static TextStyle get title3 => const TextStyle(
        fontFamily: fontFamily,
        fontSize: title3Size,
        fontWeight: FontWeight.w600, // Bold
        color: labelPrimary,
        height: lineHeightNormal,
        letterSpacing: 0.0,
      );

  /// Body - 20pt Regular (main body text)
  static TextStyle get body => const TextStyle(
        fontFamily: bodyFontFamily,
        fontSize: bodySize,
        fontWeight: FontWeight.w400, // Medium
        color: labelPrimary,
        height: lineHeightNormal,
        letterSpacing: 0.0,
      );

  /// Body Emphasized - 20pt Medium (slightly heavier)
  static TextStyle get bodyEmphasized => const TextStyle(
        fontFamily: bodyFontFamily,
        fontSize: bodySize,
        fontWeight: FontWeight.w500, // Medium instead of Semibold
        color: labelPrimary,
        height: lineHeightNormal,
        letterSpacing: 0.0,
      );

  /// Callout - 18pt Regular
  static TextStyle get callout => const TextStyle(
        fontFamily: bodyFontFamily,
        fontSize: calloutSize,
        fontWeight: FontWeight.w500, // Medium
        color: labelSecondary,
        height: lineHeightNormal,
        letterSpacing: 0.0,
      );

  /// Subhead - 16pt Regular
  static TextStyle get subhead => const TextStyle(
        fontFamily: bodyFontFamily,
        fontSize: subheadSize,
        fontWeight: FontWeight.w400, // Regular
        color: labelSecondary,
        height: lineHeightNormal,
        letterSpacing: 0.2, // Slightly wider for readability
      );

  /// Footnote - 14pt Regular (for references like "— Ephesians 5:16")
  static TextStyle get footnote => const TextStyle(
        fontFamily: bodyFontFamily,
        fontSize: footnoteSize,
        fontWeight: FontWeight.w400, // Regular
        color: labelTertiary,
        height: lineHeightNormal,
        letterSpacing: 0.3, // Wider for small Garamond
      );

  /// Caption - 13pt Regular (for labels)
  static TextStyle get caption => const TextStyle(
        fontFamily: bodyFontFamily,
        fontSize: caption1Size,
        fontWeight: FontWeight.w400, // Regular
        color: labelTertiary,
        height: lineHeightNormal,
        letterSpacing: 0.4, // Wider for very small text
      );

  // ==================== SPECIAL STYLES ====================

  /// Display Number - 80pt Regular (for big stats - Garamond shines at large sizes)
  static TextStyle get displayNumber => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 80.0,
        fontWeight: FontWeight.w400, // Regular for elegant large numbers
        color: labelPrimary,
        height: 1.1,
        letterSpacing: -1.0, // Tighter for large Garamond
      );

  /// Display Unit - 16pt Regular (unit below number)
  static TextStyle get displayUnit => const TextStyle(
        fontFamily: bodyFontFamily,
        fontSize: subheadSize,
        fontWeight: FontWeight.w400, // Regular
        color: labelSecondary,
        height: lineHeightNormal,
        letterSpacing: 0.3,
      );

  // ==================== LEGACY COMPATIBILITY ====================
  // For gradual migration from old theme

  @Deprecated('Use body instead')
  static TextStyle get bodyText => body;

  @Deprecated('Use bodyEmphasized instead')
  static TextStyle get emphasisText => bodyEmphasized;

  @Deprecated('Use title1 instead')
  static TextStyle get headerText => title1;

  @Deprecated('Use footnote instead')
  static TextStyle get referenceText => footnote;

  @Deprecated('Use body with goldColor instead')
  static TextStyle get verseText => body.copyWith(color: goldColor);

  @Deprecated('Use body instead')
  static TextStyle get questionText => body;

  // ==================== COMPONENT STYLES ====================

  /// Card decoration - frosted glass effect
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: cardBackground,
        border: Border.all(color: cardBorder, width: 1.0),
        borderRadius: BorderRadius.circular(radiusLarge),
      );

  /// Button decoration - filled style
  static BoxDecoration filledButtonDecoration(Color color) => BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radiusMedium),
      );

  /// Subtle shadow for cards
  static List<BoxShadow> get cardShadow => [
        const BoxShadow(
          color: Color(0x0A000000), // 4% black
          offset: Offset(0, 2),
          blurRadius: 8,
        ),
      ];
}
