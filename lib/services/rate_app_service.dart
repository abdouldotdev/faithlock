import 'package:faithlock/features/onboarding/screens/rating_request_screen.dart';
import 'package:faithlock/services/analytics/posthog/config/event_templates.dart';
import 'package:faithlock/services/analytics/posthog/posthog_service.dart';
import 'package:faithlock/services/storage/preferences_service.dart';
import 'package:faithlock/services/storage/secure_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:in_app_review/in_app_review.dart';

class RateAppService {
  static const String _keyHasRated = 'has_rated_app';
  static const String _keyLastPrompt = 'last_rate_prompt_date';
  static const String _keyOnboardingPromptShown =
      'onboarding_rate_prompt_shown';
  static const String _keyFirstPrayerPromptShown =
      'first_prayer_rate_prompt_shown';
  static const String _keyRatingPending = 'rating_prompt_pending';
  static const String _keyPrayerCompletions = 'prayer_completions';

  final PreferencesService _prefs = PreferencesService();
  final StorageService _secureStorage = StorageService();
  final InAppReview _inAppReview = InAppReview.instance;
  final PostHogService _analytics = PostHogService.instance;

  Future<bool> hasRatedApp() async {
    return await _prefs.readBool(_keyHasRated) ?? false;
  }

  Future<bool> shouldShowOnboardingPrompt() async {
    final shown = await _prefs.readBool(_keyOnboardingPromptShown) ?? false;
    return !shown;
  }

  Future<bool> shouldShowFirstPrayerPrompt() async {
    final shown = await _prefs.readBool(_keyFirstPrayerPromptShown) ?? false;
    return !shown;
  }

  /// Get the current prayer completion count
  Future<int> _getPrayerCount() async {
    final count = await _secureStorage.readString(_keyPrayerCompletions);
    return int.tryParse(count ?? '0') ?? 0;
  }

  /// Increment the prayer completion count and return the new count
  Future<int> incrementPrayerCount() async {
    final current = await _getPrayerCount();
    final newCount = current + 1;
    await _secureStorage.writeString(_keyPrayerCompletions, newCount.toString());
    debugPrint('🙏 Prayer count incremented to: $newCount');
    return newCount;
  }

  /// Check if rating prompt is pending for next app launch
  Future<bool> hasPendingRatingPrompt() async {
    return await _prefs.readBool(_keyRatingPending) ?? false;
  }

  /// Schedule rating prompt for next app launch
  /// Called when: hasRated == false AND prayerCount < 1
  Future<void> scheduleRatingForNextLaunch() async {
    final hasRated = await this.hasRatedApp();
    if (hasRated) return;
    
    final prayerCount = await _getPrayerCount();
    if (prayerCount >= 1) return;
    
    await _prefs.writeBool(_keyRatingPending, true);
    debugPrint('📅 Rating prompt scheduled for next launch');
  }

  /// Clear pending rating prompt (called after showing it)
  Future<void> clearPendingRatingPrompt() async {
    await _prefs.writeBool(_keyRatingPending, false);
  }

  /// Try to show rating prompt based on conditions:
  /// - If hasRated: never show
  /// - If prayerCount >= 1: show native prompt now
  /// - If prayerCount < 1: schedule for next launch
  Future<void> tryShowRatingPrompt() async {
    final hasRated = await this.hasRatedApp();
    if (hasRated) return;
    
    final prayerCount = await _getPrayerCount();
    if (prayerCount >= 1) {
      await showNativeRatingPrompt();
    } else {
      await scheduleRatingForNextLaunch();
    }
  }

  Future<void> showOnboardingPrompt({bool useOnboardingWrapper = false}) async {
    if (!await shouldShowOnboardingPrompt()) return;

    await _prefs.writeBool(_keyOnboardingPromptShown, true);
    await _prefs.writeString(
        _keyLastPrompt, DateTime.now().toIso8601String());

    await Get.to(
      () => RatingRequestScreen(
        title: '${'rate_readyToHelp'.tr} 💛',
        message: 'rate_excitedMessage'.tr,
        useOnboardingWrapper: useOnboardingWrapper,
        onRate: () async {
          if (_analytics.isReady) {
            await _analytics.events.track(
              PostHogEventType.rateIntentShown,
              {
                'source': 'onboarding',
                'timestamp': DateTime.now().toIso8601String(),
              },
            );
          }
          await _rateApp();
          await Future.delayed(const Duration(seconds: 1));
          Get.back();
        },
        onSkip: () {
          if (_analytics.isReady) {
            _analytics.events.track(
              PostHogEventType.rateIntentSkipped,
              {
                'source': 'onboarding',
                'timestamp': DateTime.now().toIso8601String(),
              },
            );
          }
          Get.back();
        },
      ),
    );
  }

  Future<void> showFirstPrayerPrompt() async {
    if (!await shouldShowFirstPrayerPrompt()) return;

    await _prefs.writeBool(_keyFirstPrayerPromptShown, true);
    await _prefs.writeString(
        _keyLastPrompt, DateTime.now().toIso8601String());

    await Future.delayed(const Duration(seconds: 2));

    await Get.to(
      () => RatingRequestScreen(
        title: '${'rate_amazingTitle'.tr} 🙏✨',
        message: 'rate_firstPrayerMessage'.tr,
        onRate: () async {
          if (_analytics.isReady) {
            await _analytics.events.track(
              PostHogEventType.rateIntentShown,
              {
                'source': 'first_prayer',
                'timestamp': DateTime.now().toIso8601String(),
              },
            );
          }
          await _rateApp();
          await Future.delayed(const Duration(milliseconds: 500));
          Get.back();
        },
        onSkip: () {
          if (_analytics.isReady) {
            _analytics.events.track(
              PostHogEventType.rateIntentSkipped,
              {
                'source': 'first_prayer',
                'timestamp': DateTime.now().toIso8601String(),
              },
            );
          }
          Get.back();
        },
      ),
    );
  }

  Future<void> showRatingOnProfile() async {
    try {
      if (_analytics.isReady) {
        await _analytics.events.track(
          PostHogEventType.rateIntentShown,
          {
            'source': 'profile',
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
      }
      await _rateApp();
      Get.back();
    } catch (e) {}
  }

  /// Show native in-app review prompt without the custom dialog.
  /// Used after first prayer completion.
  Future<void> showNativeRatingPrompt({String source = 'first_prayer'}) async {
    try {
      if (_analytics.isReady) {
        await _analytics.events.track(
          PostHogEventType.rateIntentShown,
          {
            'source': source,
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
      }
      await _inAppReview.requestReview();
      await _prefs.writeBool(_keyHasRated, true);
      await clearPendingRatingPrompt();
      debugPrint('✅ In-app review requested');
    } catch (e) {
      debugPrint('❌ Error showing native rating prompt: $e');
    }
  }

  Future<void> _rateApp() async {
    try {
      debugPrint('🔔 Requesting in-app review...');

      // Request in-app review (works on TestFlight if quota not exhausted)
      await _inAppReview.requestReview();

      await _prefs.writeBool(_keyHasRated, true);
      debugPrint('✅ In-app review requested');

      if (_analytics.isReady) {
        await _analytics.events.track(
          PostHogEventType.rateCompleted,
          {
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
      }
    } catch (e) {
      debugPrint('❌ Error showing rating: $e');
    }
  }
}
