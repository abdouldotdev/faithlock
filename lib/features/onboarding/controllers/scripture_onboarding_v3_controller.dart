import 'package:faithlock/features/onboarding/controllers/scripture_onboarding_v2_controller.dart';
import 'package:faithlock/services/analytics/posthog/export.dart';
import 'package:faithlock/services/storage/secure_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// V3 Onboarding Controller - Opal-inspired diagnostic + reveal flow.
///
/// Extends V2 to inherit name capture, hours, prayer frequency, attribution,
/// commitment level, projection math, completion logic, and analytics.
///
/// Adds V3-specific state:
///   - diagnostic answers (qualitative reflection on screen dependency)
///   - faith tradition + spiritual state
///   - prayer moments + practice
///   - apps to block + unblock rules
class ScriptureOnboardingV3Controller extends ScriptureOnboardingV2Controller {
  // Storage keys (V3-specific)
  static const String _keyDiagnosticAnswers = 'v3_diagnostic_answers';
  static const String _keyFaithTradition = 'v3_faith_tradition';
  static const String _keySpiritualState = 'v3_spiritual_state';
  static const String _keyPrayerMoments = 'v3_prayer_moments';
  static const String _keyPrayerPractices = 'v3_prayer_practices';
  static const String _keyUnblockRules = 'v3_unblock_rules';
  static const String _keyGodName = 'v3_god_name';
  static const String _keyPrayerIntent = 'v3_prayer_intent_per_day';

  /// V3 has 20 user-facing steps (Laura's full vision).
  ///   1. Welcome carousel
  ///   2-10. Diagnostic phase (9 questions)
  ///   11. Fake loader (calculation)
  ///   12. Reveal (Opal-style)
  ///   13. Personalization (tradition + state + moments + practices)
  ///   14. Prayer intent (1×/2×/3×/More)
  ///   15. Apps to block + unblock rules
  ///   16. Dual name capture (Toby name + God name)
  ///   17. Commitment seal (fingerprint)
  ///   18. Screen Time permission
  ///   19. Social proof
  ///   20. Attribution → Building plan loader → paywall
  @override
  int get totalSteps => 22;

  // V3 state
  final RxList<String> diagnosticAnswers = <String>[].obs;
  final RxString faithTradition = RxString('');
  final RxString spiritualState = RxString('');
  final RxList<String> prayerMoments = <String>[].obs;
  final RxList<String> prayerPractices = <String>[].obs;
  final RxList<String> unblockRules = <String>[].obs;
  final RxString godName = RxString('');
  final RxString prayerIntentPerDay = RxString('');

  final StorageService _v3Storage = StorageService();
  final PostHogService _v3Analytics = PostHogService.instance;

  /// Display name for Toby in user-facing copy.
  /// Internal widget class is still JudahMascot (assets unchanged).
  static const String mascotName = 'Toby';

  String getV3StepName(int step) {
    switch (step) {
      case 1:
        return 'V3 Welcome Carousel';
      case 2:
        return 'V3 Diagnostic - Peace';
      case 3:
        return 'V3 Diagnostic - Phone Checks';
      case 4:
        return 'V3 Diagnostic - Hours/Day';
      case 5:
        return 'V3 Diagnostic - Lonely';
      case 6:
        return 'V3 Diagnostic - Silence';
      case 7:
        return 'V3 Diagnostic - Missing Self';
      case 8:
        return 'V3 Diagnostic - Lost Practice';
      case 9:
        return 'V3 Diagnostic - Practice to Build';
      case 10:
        return 'V3 Diagnostic - God Sees Week';
      case 11:
        return 'V3 Fake Loader';
      case 12:
        return 'V3 Reveal';
      case 13:
        return 'V3 Social Proof';
      case 14:
        return 'V3 Personalization';
      case 15:
        return 'V3 Prayer Times';
      case 16:
        return 'V3 Prayer Frequency';
      case 17:
        return 'V3 Apps & Rules';
      case 18:
        return 'V3 Dual Name Capture';
      case 19:
        return 'V3 Commitment Seal';
      case 20:
        return 'V3 Screen Time Permission';
      case 21:
        return 'V3 Notifications Permission';
      case 22:
        return 'V3 Attribution';
      default:
        return 'V3 Unknown Step';
    }
  }

  @override
  void nextStep() async {
    if (_v3Analytics.isReady) {
      try {
        await _v3Analytics.onboarding.trackStepExit(
          stepNumber: currentStep.value,
          stepName: getV3StepName(currentStep.value),
        );
      } catch (e) {
        debugPrint('Failed to track V3 step exit: $e');
      }
    }

    if (currentStep.value < totalSteps) {
      currentStep.value++;

      if (_v3Analytics.isReady) {
        try {
          await _v3Analytics.onboarding.trackStepEntry(
            stepNumber: currentStep.value,
            stepName: getV3StepName(currentStep.value),
          );
        } catch (e) {
          debugPrint('Failed to track V3 step entry: $e');
        }
      }
    }
  }

  // ==================== V3 SAVE METHODS ====================

  Future<void> saveDiagnosticAnswer(String questionKey, String answer) async {
    diagnosticAnswers.add('$questionKey:$answer');
    await _v3Storage.writeString(
      _keyDiagnosticAnswers,
      diagnosticAnswers.join('|'),
    );
  }

  Future<void> saveFaithTradition(String tradition) async {
    faithTradition.value = tradition;
    await _v3Storage.writeString(_keyFaithTradition, tradition);
    if (_v3Analytics.isReady) {
      await _v3Analytics.onboarding.setUserProperties({
        'faith_tradition': tradition,
      });
    }
  }

  Future<void> saveSpiritualState(String state) async {
    spiritualState.value = state;
    await _v3Storage.writeString(_keySpiritualState, state);
  }

  Future<void> savePrayerMoments(List<String> moments) async {
    prayerMoments.value = moments;
    await _v3Storage.writeString(_keyPrayerMoments, moments.join(','));
  }

  Future<void> savePrayerPractices(List<String> practices) async {
    prayerPractices.value = practices;
    await _v3Storage.writeString(_keyPrayerPractices, practices.join(','));
  }

  Future<void> saveUnblockRules(List<String> rules) async {
    unblockRules.value = rules;
    await _v3Storage.writeString(_keyUnblockRules, rules.join(','));
  }

  Future<void> saveGodName(String name) async {
    godName.value = name;
    if (name.isNotEmpty) {
      await _v3Storage.writeString(_keyGodName, name);
    }
  }

  Future<void> savePrayerIntent(String intent) async {
    prayerIntentPerDay.value = intent;
    await _v3Storage.writeString(_keyPrayerIntent, intent);
    if (_v3Analytics.isReady) {
      await _v3Analytics.onboarding.setUserProperties({
        'prayer_intent_per_day': intent,
      });
    }
  }

  // ==================== REVEAL CALCULATIONS ====================

  /// Numbers used in the Opal-style reveal screen.
  /// Reuses V1's hoursPerDay state.
  Map<String, dynamic> calculateRevealStats() {
    final hours = hoursPerDay.value;
    final daysPerYear = (hours * 365) / 24;
    final yearsRemaining = 80 - userAge.value;
    final lifetimeDays = (daysPerYear * yearsRemaining).floor();
    final lifetimeYears = (lifetimeDays / 365).toStringAsFixed(1);

    // Total hours spent on the phone over the remaining lifetime.
    final lifetimeHours = (hours * 365 * yearsRemaining).floor();

    // Time reclaimed if user reduces 80%
    final reclaimedDaysPerYear = (daysPerYear * 0.8).floor();

    return {
      'daysPerYear': daysPerYear.floor(),
      'hoursPerYear': (hours * 365).floor(),
      'lifetimeDays': lifetimeDays,
      'lifetimeHours': lifetimeHours,
      'lifetimeYears': lifetimeYears,
      'reclaimedDaysPerYear': reclaimedDaysPerYear,
    };
  }
}
