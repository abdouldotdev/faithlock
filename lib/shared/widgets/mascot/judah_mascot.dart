import 'package:flutter/material.dart';

/// Emotional states for Judah the lion cub mascot.
///
/// Each state maps to a GIF file in assets/mascot/:
///   judah_neutral.gif, judah_happy.gif, etc.
enum JudahState {
  /// Standing, slight smile, gentle wave. Dashboard greeting, navigation.
  neutral,

  /// Jumping with paws up, sparkles. Quiz success, streak milestone, relock.
  happy,

  /// Leaning forward, pointing forward. Quiz active, wrong answer retry.
  encouraging,

  /// Sitting, eyes closed, paws together, golden glow. Verse display, evening.
  praying,

  /// Sitting, head tilted, paw on chest. Streak lost, subscription expired.
  sad,

  /// Standing tall, chest puffed, arms crossed. New records, milestones.
  proud,

  /// One paw pointing right, teacher expression. Tutorials, empty states.
  pointing,

  /// Curled up, eyes closed, zzz symbols. Loading states, idle.
  sleeping,

  /// With shield/protection icon. Screen Time permission screen.
  appProtection,

  /// With clock/time icon. Notification timing selection screen.
  timeSelection,
}

extension JudahStateX on JudahState {
  /// Asset path for this state's GIF.
  String get assetPath {
    // Handle camelCase to snake_case conversion
    final snakeName = name.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (match) => '_${match.group(0)!.toLowerCase()}',
    );
    return 'assets/mascot/judah_$snakeName.gif';
  }
}

/// Predefined sizes for mascot display across the app.
enum JudahSize {
  /// 32px - Notification icon, tab bar. Head silhouette only.
  xs(32),

  /// 48px - Toasts, inline messages. Head only.
  s(48),

  /// 80px - Dashboard greeting, cards. Head + upper body.
  m(80),

  /// 120px - Dialogs, celebration moments. Full body simplified.
  l(120),

  /// 200px - Onboarding, empty states, full screen moments.
  xl(200);

  const JudahSize(this.pixels);
  final double pixels;
}

/// Reusable mascot widget that displays Judah in a given emotional state.
///
/// Usage:
/// ```dart
/// JudahMascot(
///   state: JudahState.happy,
///   size: JudahSize.l,
///   message: "Yes! That's the one!",
/// )
/// ```
class JudahMascot extends StatelessWidget {
  const JudahMascot({
    super.key,
    required this.state,
    this.size = JudahSize.m,
    this.message,
    this.messageStyle,
    this.showMessage = true,
    this.circular = false,
  });

  /// The emotional state determining which GIF to display.
  final JudahState state;

  /// Display size of the mascot.
  final JudahSize size;

  /// Optional text bubble message shown below the mascot.
  final String? message;

  /// Custom style for the message text.
  final TextStyle? messageStyle;

  /// Whether to show the message bubble. Defaults to true.
  final bool showMessage;

  /// When true, the GIF is clipped to a circle (with a slight zoom to crop the
  /// white background margins) — useful as an avatar on colored surfaces.
  final bool circular;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Mascot GIF (optionally clipped to a circle, white margins cropped)
        _buildMascotImage(),

        // Message bubble
        if (showMessage && message != null && message!.isNotEmpty) ...[
          const SizedBox(height: 8),
          _MessageBubble(
            message: message!,
            style: messageStyle,
            maxWidth: size.pixels * 2.5,
          ),
        ],
      ],
    );
  }

  /// The mascot GIF, optionally clipped to a circle with the white background
  /// margins cropped out (avatar style for colored surfaces).
  Widget _buildMascotImage() {
    final image = Image.asset(
      state.assetPath,
      width: size.pixels,
      height: size.pixels,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
    );
    if (!circular) return image;
    return ClipOval(
      child: SizedBox(
        width: size.pixels,
        height: size.pixels,
        child: Transform.scale(
          scale: 1.15,
          child: image,
        ),
      ),
    );
  }

  /// Fallback widget when GIF asset is not yet available.
  Widget _buildPlaceholder() {
    final iconSize = size.pixels * 0.5;
    return Container(
      width: size.pixels,
      height: size.pixels,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFD4A843),
            const Color(0xFFF5C842).withValues(alpha: 0.7),
          ],
        ),
      ),
      child: Center(
        child: Text(
          _placeholderEmoji,
          style: TextStyle(fontSize: iconSize),
        ),
      ),
    );
  }

  String get _placeholderEmoji {
    switch (state) {
      case JudahState.neutral:
        return '\u{1F981}'; // lion
      case JudahState.happy:
        return '\u{1F389}'; // party
      case JudahState.encouraging:
        return '\u{1F4AA}'; // flexed bicep
      case JudahState.praying:
        return '\u{1F64F}'; // praying hands
      case JudahState.sad:
        return '\u{1F622}'; // crying
      case JudahState.proud:
        return '\u{1F451}'; // crown
      case JudahState.pointing:
        return '\u{1F449}'; // pointing right
      case JudahState.sleeping:
        return '\u{1F4A4}'; // zzz
      case JudahState.appProtection:
        return '\u{1F6E1}'; // shield
      case JudahState.timeSelection:
        return '\u{1F552}'; // clock
    }
  }
}

/// Speech bubble widget for mascot messages.
class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    this.style,
    this.maxWidth = 200,
  });

  final String message;
  final TextStyle? style;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          message,
          style: style ??
              const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2B2B2B),
                height: 1.3,
              ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
