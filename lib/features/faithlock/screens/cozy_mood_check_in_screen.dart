import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:faithlock/shared/widgets/cozy/cozy.dart';
import 'package:faithlock/services/analytics/posthog/export.dart';

/// Presents the cozy mood check-in as a full page that rises from the bottom,
/// modeled on [showCozyPrayerSelector]. Resolves to the [MoodLevel] the user
/// confirmed via the CTA, or `null` if they dismissed it (close button / back).
///
/// Used at two moments in the prayer flow:
/// - **Before praying** — `prompt: 'How are you feeling?'`
/// - **After a prayer** — `prompt: 'How is your heart now?'`,
///   `subtitle: 'After this time with God.'`
Future<MoodLevel?> showCozyMoodCheckIn(
  BuildContext context, {
  required String prompt,
  String? subtitle,
  String? ctaLabel,
  MoodLevel initial = MoodLevel.okay,
  bool showClose = true,
}) {
  final result = Get.to<MoodLevel>(
    () => CozyMoodCheckInScreen(
      prompt: prompt,
      subtitle: subtitle,
      ctaLabel: ctaLabel,
      initial: initial,
      showClose: showClose,
    ),
    transition: Transition.downToUp,
    duration: const Duration(milliseconds: 320),
    fullscreenDialog: true,
  );
  return result ?? Future<MoodLevel?>.value();
}

/// Full-screen mood check-in (cozy / cream theme). Pops with the chosen
/// [MoodLevel] when the CTA is tapped.
class CozyMoodCheckInScreen extends StatelessWidget {
  const CozyMoodCheckInScreen({
    super.key,
    required this.prompt,
    this.subtitle,
    this.ctaLabel,
    this.initial = MoodLevel.okay,
    this.showClose = true,
  });

  final String prompt;
  final String? subtitle;
  final String? ctaLabel;
  final MoodLevel initial;

  /// Whether to show the top-right close button. Hidden after a prayer — there
  /// the user is meant to answer (Continue), not bail out without checking in.
  final bool showClose;

  static final PostHogService _analytics = PostHogService.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CozyColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Close — dismisses without a result. Hidden after a prayer (a
              // placeholder keeps the card's vertical position unchanged).
              if (showClose)
                Align(
                  alignment: Alignment.centerRight,
                  child: CozyIconButton(
                    icon: HugeIcons.strokeRoundedCancel01,
                    onTap: Get.back,
                    size: 48,
                  ),
                )
              else
                const SizedBox(height: 48),
              const Spacer(),
              CozyMoodCheckIn(
                prompt: prompt,
                subtitle: subtitle,
                ctaLabel: ctaLabel,
                initial: initial,
                onSubmit: (mood) {
                  if (_analytics.isReady) {
                    _analytics.events.trackCustom('mood_check_in_submitted', {
                      'mood': mood.name,
                      // The prompt distinguishes the before/after-prayer moment.
                      'moment': showClose ? 'before_prayer' : 'after_prayer',
                    });
                  }
                  Get.back<MoodLevel>(result: mood);
                },
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
