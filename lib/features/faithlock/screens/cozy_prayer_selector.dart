import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:faithlock/features/faithlock/screens/cozy_mood_check_in_screen.dart';
import 'package:faithlock/features/faithlock/screens/cozy_written_prayer_screen.dart';
import 'package:faithlock/features/faithlock/services/mood_prayer_match.dart';
import 'package:faithlock/features/faithlock/services/mood_service.dart';
import 'package:faithlock/features/prayer_audio/data/prayer_repository.dart';
import 'package:faithlock/services/analytics/posthog/export.dart';
import 'package:faithlock/shared/widgets/cozy/cozy.dart';

/// Fire a PostHog event from these top-level prayer-flow functions, guarded so
/// analytics never blocks praying.
void _trackPrayer(String event, Map<String, dynamic> props) {
  final a = PostHogService.instance;
  if (a.isReady) a.events.trackCustom(event, props);
}

/// Entry point for the "Pray" action: ask how the user feels first, then offer
/// the prayer modes. The mood check-in is the first step, so dismissing it
/// (close / back) CANCELS the flow and returns home — the user chose to bail,
/// we don't push the selector on them. To pray, they confirm with "Continue"
/// (the default mood is one tap away).
Future<void> startCozyPrayerFlow(BuildContext context) async {
  final MoodLevel? mood = await showCozyMoodCheckIn(
    context,
    prompt: 'mood_howAreYouFeeling'.tr,
  );
  // Dismissed (close / back) → cancel the whole flow, stay home.
  if (mood == null) {
    _trackPrayer('prayer_flow_cancelled', {
      'at': 'mood_pre',
      'context': 'home_prayer',
    });
    return;
  }
  // Persist the reading so the selector can recommend a prayer that meets the
  // user where they are (and a future iteration can show mood trends).
  await MoodService().saveMood(mood);
  _trackPrayer('mood_recorded', {
    'mood': mood.name,
    'phase': 'pre',
    'context': 'home_prayer',
  });
  if (!context.mounted) return;
  showCozyPrayerSelector(context);
}

/// Cozy prayer-mode selector — ALWAYS offers both options (no remembered
/// shortcut), shown as a FULL PAGE that rises from the bottom. Tapping "Pray"
/// or "Let's Pray Now" opens this.
void showCozyPrayerSelector(BuildContext context) {
  Get.to<void>(
    () => const CozyPrayerSelectorScreen(),
    transition: Transition.downToUp,
    duration: const Duration(milliseconds: 320),
    fullscreenDialog: true,
  );
}

/// Opens the written-prayer reading screen with the prayer that best matches
/// the user's last mood (falling back to the first available prayer). Closes
/// the selector first, mirroring the Guided Audio path.
Future<void> _openWrittenPrayer(BuildContext context) async {
  Get.back(); // close the selector
  final prayers = await PrayerRepository().fetchPrayers();
  final mood = await MoodService().lastMood();
  final lastId = await MoodService().lastCuratedId();
  final prayer = MoodPrayerMatch.recommend(mood, prayers, excludeId: lastId);
  if (prayer == null) {
    final ctx = Get.context;
    if (ctx != null) {
      CozyToast.show(ctx, 'prayer_stillLoading'.tr);
    }
    return;
  }
  await MoodService().saveLastCuratedId(prayer.id);
  _trackPrayer('prayer_matched_to_mood', {
    'prayer_id': prayer.id,
    'mood': mood?.name,
    'mode': 'text',
    'source': 'home',
  });
  Get.to<void>(
    () => CozyWrittenPrayerScreen(prayer: prayer),
    transition: Transition.rightToLeft,
    duration: const Duration(milliseconds: 280),
  );
}

/// Full-screen prayer-mode chooser (cozy / cream theme).
class CozyPrayerSelectorScreen extends StatelessWidget {
  const CozyPrayerSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CozyColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Close
              Align(
                alignment: Alignment.centerRight,
                child: CozyIconButton(
                  icon: HugeIcons.strokeRoundedCancel01,
                  onTap: Get.back,
                  size: 48,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'prayer_howToPray'.tr,
                style: CozyText.title.copyWith(fontSize: 32, height: 1.12),
              ),
              const SizedBox(height: 10),
              Text('prayer_chooseMode'.tr, style: CozyText.subtitle),
              const SizedBox(height: 40),
              CozyChoiceCard(
                icon: HugeIcons.strokeRoundedHeadphones,
                iconBackground: CozyColors.peach,
                title: 'prayer_guidedAudio'.tr,
                subtitle: 'prayer_guidedAudioSub'.tr,
                showChevron: true,
                onTap: () {
                  _trackPrayer(
                      'prayer_mode_selected', {'mode': 'guided_audio'});
                  Get.back();
                  Get.toNamed('/prayer-audio-library');
                },
              ),
              const SizedBox(height: 14),
              CozyChoiceCard(
                icon: HugeIcons.strokeRoundedBookOpen01,
                iconBackground: CozyColors.sage,
                title: 'prayer_writtenPrayer'.tr,
                subtitle: 'prayer_writtenPrayerSub'.tr,
                showChevron: true,
                onTap: () {
                  _trackPrayer('prayer_mode_selected', {'mode': 'text'});
                  _openWrittenPrayer(context);
                },
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
