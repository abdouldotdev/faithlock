import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/cozy/cozy.dart';
import 'cozy_button.dart';
import 'cozy_mood_slider.dart';

/// A self-contained "how do you feel?" card wrapping [CozyMoodSlider] with a
/// prompt and an optional confirm button.
///
/// Two intended uses (same widget, different copy):
/// - **Before praying** — a general check-in:
///   `CozyMoodCheckIn(prompt: 'How are you feeling?')`
/// - **After a prayer** — pass the post-prayer copy:
///   `CozyMoodCheckIn(
///      prompt: 'How is your heart now?',
///      subtitle: 'After this time with God.',
///    )`
class CozyMoodCheckIn extends StatefulWidget {
  /// Headline question shown above the slider.
  final String? prompt;

  /// Optional supporting line under the prompt.
  final String? subtitle;

  /// Mood the slider starts on.
  final MoodLevel initial;

  /// Confirm button label.
  final String? ctaLabel;

  /// Fires when the confirm button is tapped, with the chosen mood.
  final ValueChanged<MoodLevel>? onSubmit;

  /// Fires on every mood change while dragging.
  final ValueChanged<MoodLevel>? onChanged;

  /// Whether the confirm button is shown.
  final bool showCta;

  const CozyMoodCheckIn({
    super.key,
    this.prompt,
    this.subtitle,
    this.initial = MoodLevel.okay,
    this.ctaLabel,
    this.onSubmit,
    this.onChanged,
    this.showCta = true,
  });

  @override
  State<CozyMoodCheckIn> createState() => _CozyMoodCheckInState();
}

class _CozyMoodCheckInState extends State<CozyMoodCheckIn> {
  late MoodLevel _mood = widget.initial;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
      decoration: ShapeDecoration(
        color: CozyColors.surface,
        shape: CozyTokens.smooth(
          CozyTokens.radiusLg,
          side: const BorderSide(
            color: CozyColors.outline,
            width: CozyTokens.borderWidth,
          ),
        ),
        shadows: CozyTokens.shadowHard,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.prompt ?? 'mood_howAreYouFeeling'.tr,
            textAlign: TextAlign.center,
            style: CozyText.title.copyWith(fontSize: 22),
          ),
          if (widget.subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              widget.subtitle!,
              textAlign: TextAlign.center,
              style: CozyText.subtitle,
            ),
          ],
          const SizedBox(height: 24),
          CozyMoodSlider(
            initial: widget.initial,
            onChanged: (m) {
              _mood = m;
              widget.onChanged?.call(m);
            },
          ),
          if (widget.showCta) ...[
            const SizedBox(height: 24),
            CozyButton(
              text: widget.ctaLabel ?? 'mood_continue'.tr,
              onTap: () => widget.onSubmit?.call(_mood),
            ),
          ],
        ],
      ),
    );
  }
}
