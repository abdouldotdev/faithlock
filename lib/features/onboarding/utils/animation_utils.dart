import 'package:flutter/services.dart';

/// iOS-style Animation Utilities
/// Optimized timing and haptics for smooth, professional experience
class AnimationUtils {
  // ==================== TIMING CONSTANTS ====================
  // iOS-optimized durations

  /// Fast typing for better engagement
  static const int typingSpeedMs = 12;

  /// Short pause between elements
  static const int pauseShort = 500;

  /// Medium pause for emphasis
  static const int pauseMedium = 1000;

  /// Long pause for reflection
  static const int pauseLong = 1500;

  /// Auto-continue delay
  static const int autoContinueMs = 2500;

  /// Fade transition duration
  static const int fadeMs = 300;

  // ==================== HAPTIC FEEDBACK ====================

  /// Types of haptic feedback
  static Future<void> lightHaptic() => HapticFeedback.lightImpact();
  static Future<void> mediumHaptic() => HapticFeedback.mediumImpact();
  static Future<void> heavyHaptic() => HapticFeedback.heavyImpact();
  static Future<void> selectionHaptic() => HapticFeedback.selectionClick();

  // ==================== ANIMATION METHODS ====================

  /// Typing effect with haptic feedback
  /// iOS-optimized for faster, smoother typing
  static Future<void> typeText({
    required String fullText,
    required Function(String) onUpdate,
    required Function(bool) onCursorVisibility,
    int? speedMs,
    bool withHaptic = true,
  }) async {
    final speed = speedMs ?? typingSpeedMs;
    onCursorVisibility(true);

    for (int i = 0; i <= fullText.length; i++) {
      await Future.delayed(Duration(milliseconds: speed));
      onUpdate(fullText.substring(0, i));

      // Light haptic feedback for typing feel
      if (withHaptic && i < fullText.length && i % 5 == 0) {
        await selectionHaptic();
      }
    }

    // Hide cursor almost immediately
    await Future.delayed(Duration(milliseconds: 150));
    onCursorVisibility(false);
  }

  /// iOS-style fade transition between steps
  static Future<void> fadeToNextStep({
    required Function() onFadeComplete,
    int? fadeOutMs, // Optional override
    int? darkScreenMs, // Optional override
  }) async {
    final fadeOut = fadeOutMs ?? fadeMs;
    final darkScreen = darkScreenMs ?? pauseMedium;

    // Fade out current content
    await Future.delayed(Duration(milliseconds: fadeOut));

    // Show black screen with heavy haptic
    await heavyHaptic();
    await Future.delayed(Duration(milliseconds: darkScreen));

    // Trigger next step
    onFadeComplete();
  }

  /// Sequence of haptic pulses
  static Future<void> hapticSequence({
    required int count,
    int delayMs = 200,
    bool heavy = false,
  }) async {
    for (int i = 0; i < count; i++) {
      if (heavy) {
        await heavyHaptic();
      } else {
        await lightHaptic();
      }
      if (i < count - 1) {
        await Future.delayed(Duration(milliseconds: delayMs));
      }
    }
  }

  /// Pause with optional haptic
  static Future<void> pause({
    required int durationMs,
    bool withHaptic = false,
    bool heavy = false,
  }) async {
    if (withHaptic) {
      if (heavy) {
        await heavyHaptic();
      } else {
        await mediumHaptic();
      }
    }
    await Future.delayed(Duration(milliseconds: durationMs));
  }
}
