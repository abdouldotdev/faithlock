import 'package:flutter/material.dart';

import '../../../shared/widgets/cozy/cozy.dart';

/// Toby's emotional states in the garden, driven by how the plant is doing.
enum TobyMood { idle, watering, sad }

/// Maps garden state → Toby's mood: wilting plant makes him sad, a fresh seed
/// leaves him idle, otherwise he's happily watering. Shared by the home hero
/// and the fullscreen pot view.
TobyMood tobyMoodFor(double progress, double health) {
  if (health < 0.5) return TobyMood.sad;
  if (progress < 0.10) return TobyMood.idle;
  return TobyMood.watering;
}

/// Toby art (transparent animated WebP loops). `watering` is the real pouring
/// render (Toby tipping his can toward the plant); `idle` is the calm loop.
/// `sad` has no dedicated render yet, so it falls back to idle (never an
/// off-character lion). Drop `toby_sad.webp` into `assets/mascot/` and repoint
/// the line below when it lands (prompts in docs/toby-mascot-prompts.md).
const Map<TobyMood, String> _tobyGif = {
  TobyMood.idle: 'assets/mascot/toby_idle.webp',
  TobyMood.watering: 'assets/mascot/toby_watering.webp',
  TobyMood.sad: 'assets/mascot/toby_idle.webp',
};

/// Toby — the lion-cub helper who tends the plant beside the pot. A gentle idle
/// bob keeps him alive; the GIF itself carries the per-mood animation.
class TobyMascot extends StatefulWidget {
  final TobyMood mood;
  final double size;

  const TobyMascot({
    super.key,
    this.mood = TobyMood.idle,
    this.size = 120,
  });

  @override
  State<TobyMascot> createState() => _TobyMascotState();
}

class _TobyMascotState extends State<TobyMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bob = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gif = _tobyGif[widget.mood] ?? _tobyGif[TobyMood.idle]!;
    return AnimatedBuilder(
      animation: _bob,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, -3 * _bob.value),
        child: child,
      ),
      child: Image.asset(
        gif,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => _fallback(),
      ),
    );
  }

  Widget _fallback() => Container(
        width: widget.size,
        height: widget.size,
        decoration: ShapeDecoration(
          color: CozyColors.primaryLight,
          shape: CozyTokens.smooth(
            CozyTokens.radiusPill,
            side: const BorderSide(
                color: CozyColors.outline, width: CozyTokens.borderWidth),
          ),
        ),
        alignment: Alignment.center,
        child: Text('🦁', style: TextStyle(fontSize: widget.size * 0.42)),
      );
}
