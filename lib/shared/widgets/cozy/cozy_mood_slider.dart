import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/cozy/cozy.dart';
import 'cozy_glass_slider.dart';

/// One state on the mood spectrum, ordered heavy → joyful. Each carries the
/// emoji shown in the slider, a short label, and an accent color the slider /
/// halo tint to as the user drags.
enum MoodLevel {
  crushed('😭', 'Crushed', Color(0xFF6B7BA6)),
  heavy('😢', 'Heavy', Color(0xFF7C8DB0)),
  weary('😟', 'Weary', Color(0xFF9C8773)),
  okay('😐', 'Okay', Color(0xFFCBA86A)),
  peaceful('🙂', 'Peaceful', Color(0xFFD68A4E)),
  grateful('😊', 'Grateful', Color(0xFFE0954E)),
  joyful('😄', 'Joyful', Color(0xFFE9AE52));

  const MoodLevel(this.emoji, this.label, this.color);

  final String emoji;
  final String label;
  final Color color;
}

/// A reusable "how do you feel?" control: a big emoji that morphs through the
/// [MoodLevel] spectrum (😢 → 😄) as the user drags a liquid-glass slider left
/// to right. Built on [CozyGlassSlider], so it inherits the glass thumb, pill
/// track, division snapping and selection haptics.
///
/// ```dart
/// CozyMoodSlider(
///   initial: MoodLevel.okay,
///   onChanged: (mood) => _selected = mood,
/// )
/// ```
class CozyMoodSlider extends StatefulWidget {
  /// Mood the slider starts on. Defaults to the neutral middle.
  final MoodLevel initial;

  /// Fires every time the selected mood changes (on each division crossing).
  final ValueChanged<MoodLevel>? onChanged;

  /// Whether the current mood's label is shown under the emoji.
  final bool showLabel;

  /// Font size of the morphing emoji.
  final double emojiSize;

  const CozyMoodSlider({
    super.key,
    this.initial = MoodLevel.okay,
    this.onChanged,
    this.showLabel = true,
    this.emojiSize = 72,
  });

  @override
  State<CozyMoodSlider> createState() => _CozyMoodSliderState();
}

class _CozyMoodSliderState extends State<CozyMoodSlider> {
  late MoodLevel _mood = widget.initial;

  static const List<MoodLevel> _moods = MoodLevel.values;

  void _onSliderChanged(double v) {
    final i = v.round().clamp(0, _moods.length - 1);
    final next = _moods[i];
    if (next == _mood) return;
    setState(() => _mood = next);
    widget.onChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final double haloSize = widget.emojiSize + 36;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Morphing emoji inside a soft halo that tints toward the mood color.
        AnimatedContainer(
          duration: CozyTokens.base,
          curve: Curves.easeOut,
          width: haloSize,
          height: haloSize,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color.lerp(_mood.color, CozyColors.surface, 0.78),
          ),
          child: AnimatedSwitcher(
            duration: CozyTokens.fast,
            transitionBuilder: (child, anim) => ScaleTransition(
              scale: Tween<double>(begin: 0.6, end: 1.0).animate(
                CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
              ),
              // anim stays in [0,1] — safe for FadeTransition's opacity.
              child: FadeTransition(opacity: anim, child: child),
            ),
            child: Text(
              _mood.emoji,
              key: ValueKey<MoodLevel>(_mood),
              style: TextStyle(fontSize: widget.emojiSize),
            ),
          ),
        ),
        if (widget.showLabel) ...[
          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: CozyTokens.fast,
            child: Text(
              'mood_${_mood.name}'.tr,
              key: ValueKey<MoodLevel>(_mood),
              style: CozyText.heading.copyWith(color: _mood.color),
            ),
          ),
        ],
        const SizedBox(height: 18),
        CozyGlassSlider(
          value: _mood.index.toDouble(),
          min: 0,
          max: (_moods.length - 1).toDouble(),
          divisions: _moods.length - 1,
          activeColor: _mood.color,
          onChanged: _onSliderChanged,
        ),
      ],
    );
  }
}
