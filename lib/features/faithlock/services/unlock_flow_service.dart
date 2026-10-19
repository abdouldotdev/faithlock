import 'package:faithlock/app_routes.dart';
import 'package:faithlock/features/faithlock/screens/cozy_mood_check_in_screen.dart';
import 'package:faithlock/features/faithlock/screens/cozy_written_prayer_screen.dart';
import 'package:faithlock/features/faithlock/models/unlock_attempt_model.dart'
    as stats;
import 'package:faithlock/features/faithlock/services/mood_prayer_match.dart';
import 'package:faithlock/features/faithlock/services/mood_service.dart';
import 'package:faithlock/features/faithlock/services/stats_service.dart';
import 'package:faithlock/features/faithlock/services/unlock_timer_service.dart';
import 'package:faithlock/features/prayer_audio/data/prayer_repository.dart';
import 'package:faithlock/features/prayer_audio/models/prayer.dart';
import 'package:faithlock/features/prayer_audio/screens/prayer_player_screen.dart';
import 'package:faithlock/services/analytics/posthog/export.dart';
import 'package:faithlock/services/storage/preferences_service.dart';
import 'package:faithlock/shared/widgets/cozy/cozy.dart';
import 'package:faithlock/shared/widgets/dialogs/unlock_duration_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// The ways a user can earn back a blocked app.
enum UnlockMethod { quiz, prayerAudio, prayerText }

extension UnlockMethodX on UnlockMethod {
  String get storageValue => switch (this) {
        UnlockMethod.quiz => 'quiz',
        UnlockMethod.prayerAudio => 'prayer_audio',
        UnlockMethod.prayerText => 'prayer_text',
      };

  /// Translation key for the human-readable label (used in Profile + chooser).
  String get labelKey => switch (this) {
        UnlockMethod.quiz => 'unlock_method_quiz',
        UnlockMethod.prayerAudio => 'unlock_method_audio',
        UnlockMethod.prayerText => 'unlock_method_text',
      };

  static UnlockMethod? fromStorage(String? v) => switch (v) {
        'quiz' => UnlockMethod.quiz,
        'prayer_audio' => UnlockMethod.prayerAudio,
        'prayer_text' => UnlockMethod.prayerText,
        _ => null,
      };
}

/// Orchestrates the "earn back a blocked app" flow.
///
/// Entry is the [UnlockChooserScreen] (routed from the notification / shield).
/// The user picks Quiz or Prayer (→ Audio or Text); a prayer is matched to the
/// mood they report right then. On completion every path converges on
/// [finishUnlock] — ask the unlock duration, record the attempt, start the
/// timer, and return to the app — mirroring the existing quiz behaviour.
///
/// The choice can be remembered (offered from the 2nd unlock onward) and is
/// editable in Profile.
class UnlockFlowService {
  static final UnlockFlowService _instance = UnlockFlowService._();
  factory UnlockFlowService() => _instance;
  UnlockFlowService._();

  final PreferencesService _prefs = PreferencesService();
  final PostHogService _analytics = PostHogService.instance;

  void _track(String event, Map<String, dynamic> props) {
    if (_analytics.isReady) _analytics.events.trackCustom(event, props);
  }

  static const String _keyMethod = 'unlock_method_remembered';
  static const String _keyEventCount = 'unlock_event_count';

  // ── Remembered choice (editable in Profile) ──────────────────────────────

  Future<UnlockMethod?> remembered() async =>
      UnlockMethodX.fromStorage(await _prefs.readString(_keyMethod));

  /// Persist a remembered method, or pass null to clear it ("ask every time").
  Future<void> remember(UnlockMethod? method) async {
    if (method == null) {
      await _prefs.deleteData(_keyMethod);
    } else {
      await _prefs.writeString(_keyMethod, method.storageValue);
    }
    if (_analytics.isReady) {
      _analytics.users.setUserProperties({
        'preferred_unlock_method': method?.storageValue ?? 'ask',
      });
    }
  }

  // ── Unlock-event counter (gates the "Remember my choice" offer) ──────────

  Future<int> eventCount() async => await _prefs.readInt(_keyEventCount) ?? 0;

  Future<void> bumpEventCount() async {
    final n = await eventCount();
    await _prefs.writeInt(_keyEventCount, n + 1);
  }

  /// "Remember my choice" is offered from the 2nd unlock onward (so the very
  /// first time the user always sees the explainer choices).
  bool shouldOfferRemember(int eventCount) => eventCount >= 1;

  // ── Launching a challenge ─────────────────────────────────────────────────

  Future<void> start(UnlockMethod method) async {
    _track('unlock_flow_started', {
      'method': method.storageValue,
      'event_count': await eventCount(),
    });
    switch (method) {
      case UnlockMethod.quiz:
        startQuiz();
      case UnlockMethod.prayerAudio:
        await startPrayer(audio: true);
      case UnlockMethod.prayerText:
        await startPrayer(audio: false);
    }
  }

  /// The classic verse quiz (already self-contained: it asks the unlock
  /// duration and releases the apps on completion).
  void startQuiz() => Get.offAllNamed(AppRoutes.prayerLearning);

  /// Pray to unlock: ask the current mood, pick a matching prayer, open the
  /// audio player or the written reader, and release the apps when it ends.
  Future<void> startPrayer({required bool audio}) async {
    final ctx = Get.context;
    if (ctx == null) return;

    // Ask how they feel right now so the match is fresh.
    final mood = await showCozyMoodCheckIn(
      ctx,
      prompt: 'mood_howAreYouFeeling'.tr,
    );
    if (mood != null) {
      await MoodService().saveMood(mood);
      _track('mood_recorded', {
        'mood': mood.name,
        'phase': 'pre',
        'context': 'unlock',
      });
    } else {
      _track('mood_skipped', {'phase': 'pre', 'context': 'unlock'});
    }

    final prayers = await PrayerRepository().fetchPrayers();
    final lastId = await MoodService().lastCuratedId();

    // For audio, only consider prayers that actually have audio; fall back to
    // the full catalogue if none are audio-capable.
    final pool = audio
        ? prayers
            .where((p) =>
                (p.audioPath?.isNotEmpty ?? false) ||
                (p.audioUrl?.isNotEmpty ?? false))
            .toList()
        : prayers;
    final candidates = pool.isNotEmpty ? pool : prayers;

    final Prayer? prayer =
        MoodPrayerMatch.recommend(mood, candidates, excludeId: lastId);
    if (prayer == null) {
      final c = Get.context;
      if (c != null) CozyToast.show(c, 'prayer_stillLoading'.tr);
      return;
    }
    await MoodService().saveLastCuratedId(prayer.id);

    _track('prayer_matched_to_mood', {
      'prayer_id': prayer.id,
      'mood': mood?.name,
      'mode': audio ? 'audio' : 'text',
      'source': 'unlock',
    });

    final startedAt = DateTime.now();
    Future<void> onCompleted() => finishUnlock(
          prayerId: prayer.id,
          startedAt: startedAt,
          mode: audio ? 'audio' : 'text',
        );

    if (audio) {
      Get.to<void>(
        () => PrayerPlayerScreen(prayer: prayer, onCompleted: onCompleted),
        transition: Transition.cupertino,
      );
    } else {
      Get.to<void>(
        () => CozyWrittenPrayerScreen(prayer: prayer, onCompleted: onCompleted),
        transition: Transition.rightToLeft,
      );
    }
  }

  /// Shared completion: ask the unlock duration, record the attempt, start the
  /// timer, and return home. Mirrors the quiz's last step exactly.
  Future<void> finishUnlock({
    required String prayerId,
    DateTime? startedAt,
    String? mode,
  }) async {
    final ctx = Get.context;
    Duration? duration;
    if (ctx != null && ctx.mounted) {
      duration = await UnlockDurationDialog.show(context: ctx);
    }

    if (duration != null) {
      _track('unlock_duration_selected', {
        'duration_minutes': duration.inMinutes,
      });
    }

    final seconds = startedAt != null
        ? DateTime.now().difference(startedAt).inSeconds
        : null;

    final method = mode == 'audio' ? 'prayer_audio' : 'prayer_text';
    _track('unlock_completed', {
      'method': method,
      'mode': mode,
      'prayer_id': prayerId,
      'duration_minutes': (duration != null && duration.inMinutes > 0)
          ? duration.inMinutes
          : null,
      'time_to_unlock_seconds': seconds,
    });
    try {
      await StatsService().recordUnlockAttempt(
        verseId: prayerId,
        wasSuccessful: true,
        attemptCount: 1,
        timeToUnlockSeconds: seconds,
        unlockDurationMinutes: (duration != null && duration.inMinutes > 0)
            ? duration.inMinutes
            : null,
        method: mode == 'audio'
            ? stats.UnlockMethod.prayerAudio
            : stats.UnlockMethod.prayerText,
      );
    } catch (e) {
      debugPrint('⚠️ [UnlockFlow] failed to record unlock: $e');
    }

    if (duration != null) {
      try {
        await UnlockTimerService().startUnlock(duration: duration);
      } catch (e) {
        debugPrint('⚠️ [UnlockFlow] failed to start unlock timer: $e');
      }
    }

    Get.offAllNamed(AppRoutes.main);
  }
}
