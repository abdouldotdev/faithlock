import 'dart:convert';

import 'package:faithlock/features/faithlock/services/screen_time_service.dart';
import 'package:faithlock/services/analytics/meta/export.dart';
import 'package:faithlock/services/analytics/posthog/export.dart';
import 'package:faithlock/services/analytics/tiktok/export.dart';
import 'package:faithlock/services/storage/preferences_service.dart';
import 'package:faithlock/services/storage/secure_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Controller for managing Scripture Lock onboarding flow and progress
class ScriptureOnboardingController extends GetxController {
  // Use PreferencesService for onboarding state (cleared on uninstall)
  final PreferencesService _prefs = PreferencesService();
  // Use StorageService for user data (persists in Keychain)
  final StorageService _storage = StorageService();
  final PostHogService _analytics = PostHogService.instance;

  // Storage keys
  static const String _keyOnboardingComplete = 'scripture_onboarding_complete';
  static const String _keySummaryComplete = 'onboarding_summary_complete';
  static const String _keyHasAccessedFeatures = 'has_accessed_app_features';
  static const String _keyUserName = 'user_name';
  static const String _keyUserAge = 'user_age';
  static const String _keyAgeSkipped = 'user_age_skipped';
  static const String _keyUserHoursPerDay = 'user_hours_per_day';
  static const String _keyPrayerFrequency = 'prayer_frequency_per_week';
  static const String _key30DayGoals = 'thirty_day_goals';
  static const String _keySelectedVerseCategories = 'selected_verse_categories';
  static const String _keySelectedApps = 'selected_problem_apps';
  static const String _keyIntensityLevel = 'scripture_intensity_level';
  static const String _keySacredCovenantAccepted = 'sacred_covenant_accepted';
  static const String _keySchedules = 'onboarding_schedules';
  static const String _keyAttribution = 'user_attribution_source';

  /// Total steps in this onboarding flow (override in subclasses)
  int get totalSteps => 13;

  // Observable state
  final RxInt currentStep = RxInt(1);
  final RxString userName = RxString('User');
  final RxInt userAge = RxInt(30);
  final RxBool ageSkipped = RxBool(false);
  final RxDouble hoursPerDay = RxDouble(5.0);
  final RxInt prayerTimesPerWeek = RxInt(0);
  final RxList<String> thirtyDayGoals = <String>[].obs;
  final RxList<String> selectedCategories = <String>[].obs;
  final RxList<String> selectedApps = <String>[].obs;
  final RxString intensityLevel = RxString('Balanced');
  final RxBool covenantAccepted = RxBool(false);

  @override
  void onInit() {
    super.onInit();
    // Load asynchronously without blocking
    Future.microtask(() async {
      await loadProgress();
      await _initializeDefaultSchedules();

      // Track onboarding start
      if (_analytics.isReady) {
        await _analytics.onboarding.startOnboarding();
        await _trackStepEntry();
      }
    });
  }

  /// Initialize default schedules if none exist
  Future<void> _initializeDefaultSchedules() async {
    final existingSchedules = await _storage.readString(_keySchedules);

    // Only initialize if no schedules exist
    if (existingSchedules == null || existingSchedules.isEmpty) {
      final defaultSchedules = [
        {
          'name': 'Morning Focus',
          'icon': '🌅',
          'startHour': 8,
          'startMinute': 0,
          'endHour': 10,
          'endMinute': 0,
          'enabled': true,
        },
        {
          'name': 'Afternoon Lock',
          'icon': '☀️',
          'startHour': 12,
          'startMinute': 0,
          'endHour': 16,
          'endMinute': 0,
          'enabled': true,
        },
        {
          'name': 'Night Protection',
          'icon': '🌙',
          'startHour': 20,
          'startMinute': 0,
          'endHour': 23,
          'endMinute': 0,
          'enabled': true,
        },
      ];

      await _storage.writeString(_keySchedules, jsonEncode(defaultSchedules));
      debugPrint('✅ Default schedules initialized');
    }
  }

  /// Load any saved progress
  Future<void> loadProgress() async {
    final savedHoursStr = await _storage.readString(_keyUserHoursPerDay);
    if (savedHoursStr != null) {
      hoursPerDay.value = double.tryParse(savedHoursStr) ?? 0.0;
    }

    // Restore the user's name so re-engagement screens (e.g. the summary shown
    // on relaunch) display it instead of the default placeholder.
    final savedName = await _storage.readString(_keyUserName);
    if (savedName != null && savedName.isNotEmpty) {
      userName.value = savedName;
    }

    // Load age data
    final savedAgeStr = await _storage.readString(_keyUserAge);
    if (savedAgeStr != null) {
      userAge.value = int.tryParse(savedAgeStr) ?? 25;
    }
    final skipped = await _storage.readString(_keyAgeSkipped);
    ageSkipped.value = skipped == 'true';
  }

  /// Check if onboarding has been completed
  Future<bool> isOnboardingComplete() async {
    final complete = await _prefs.readBool(_keyOnboardingComplete);
    return complete ?? false;
  }

  /// Move to next step
  void nextStep() async {
    // Track step exit before moving
    if (_analytics.isReady) {
      await _trackStepExit();
    }

    if (currentStep.value < totalSteps) {
      currentStep.value++;

      // Track new step entry
      if (_analytics.isReady) {
        await _trackStepEntry();
      }
    }
  }

  /// Jump to specific step (debug only)
  void jumpToStep(int step) {
    if (step >= 1 && step <= totalSteps) {
      currentStep.value = step;
    }
  }

  /// Move to previous step (if needed)
  void previousStep() {
    if (currentStep.value > 1) {
      currentStep.value--;
    }
  }

  /// Save user name from Step 1.5
  Future<void> saveUserName(String name) async {
    userName.value = name;
    await _storage.writeString(_keyUserName, name);

    // Track user property
    if (_analytics.isReady) {
      await _analytics.onboarding.setUserProperties({'user_name': name});
    }
  }

  /// Save attribution source from Step 1.75
  Future<void> saveAttribution(String source) async {
    await _storage.writeString(_keyAttribution, source);

    if (_analytics.isReady) {
      await _analytics.onboarding.setUserProperties({
        'attribution_source': source,
      });
    }
  }

  /// Save user age from Step 1.5 (stored locally only per Apple 5.1.1)
  Future<void> saveUserAge(int age) async {
    userAge.value = age;
    ageSkipped.value = false;
    await _storage.writeString(_keyUserAge, age.toString());
    await _storage.writeString(_keyAgeSkipped, 'false');
  }

  /// Skip age input during onboarding (Apple Guideline 5.1.1 compliance)
  Future<void> skipAge() async {
    ageSkipped.value = true;
    userAge.value = 30; // Default preview age
    await _storage.writeString(_keyAgeSkipped, 'true');
  }

  /// Save hours per day from Step 2
  Future<void> saveHoursPerDay(double hours) async {
    hoursPerDay.value = hours;
    await _storage.writeString(_keyUserHoursPerDay, hours.toString());

    // Track user property
    if (_analytics.isReady) {
      await _analytics.onboarding.setUserProperties({'hours_per_day': hours});
    }
  }

  /// Save prayer frequency from Step 2B
  Future<void> savePrayerFrequency(int times) async {
    prayerTimesPerWeek.value = times;
    await _storage.writeString(_keyPrayerFrequency, times.toString());

    // Track user property
    if (_analytics.isReady) {
      await _analytics.onboarding
          .setUserProperties({'prayer_frequency': times});
    }
  }

  /// Save 30-day goals from Step 4B
  Future<void> save30DayGoals(List<String> goals) async {
    thirtyDayGoals.value = goals;
    await _storage.writeString(_key30DayGoals, goals.join(','));
  }

  /// Calculate time statistics
  Map<String, dynamic> calculateTimeStats() {
    final hours = hoursPerDay.value;
    final hoursPerWeek = hours * 7;
    final hoursPerYear = hours * 365;
    final daysPerYear = hoursPerYear / 24;

    final fullDays = daysPerYear.floor();
    final remainingHours = ((daysPerYear - fullDays) * 24).round();

    return {
      'hoursPerDay': hours,
      'hoursPerWeek': hoursPerWeek,
      'hoursPerYear': hoursPerYear,
      'fullDays': fullDays,
      'remainingHours': remainingHours,
      'formatted': '$fullDays days and $remainingHours hours',
    };
  }

  /// Calculate life statistics based on age and phone usage
  Map<String, dynamic> calculateLifeStats() {
    final age = userAge.value;
    final hours = hoursPerDay.value;

    // Average life expectancy
    const int averageLifeExpectancy = 80;
    final int yearsRemaining = averageLifeExpectancy - age;
    final int totalDaysInLife = averageLifeExpectancy * 365;
    final int daysLived = age * 365;
    final int daysRemaining = yearsRemaining * 365;

    // Calculate wasted days per year and lifetime
    final double daysWastedPerYear = (hours * 365) / 24;
    final double daysWastedInFuture = daysWastedPerYear * yearsRemaining;
    final double percentageOfLifeWasted =
        (daysWastedInFuture / totalDaysInLife) * 100;

    // Calculate days saved with 2 weeks of using the app (80% reduction in usage)
    final double hoursAfterApp = hours * 0.2; // 80% reduction
    final double daysSavedPerYear = ((hours - hoursAfterApp) * 365) / 24;
    final double daysSavedIn2Weeks = (daysSavedPerYear / 365) * 14;

    return {
      'age': age,
      'averageLifeExpectancy': averageLifeExpectancy,
      'yearsRemaining': yearsRemaining,
      'totalDaysInLife': totalDaysInLife,
      'daysLived': daysLived,
      'daysRemaining': daysRemaining,
      'daysWastedPerYear': daysWastedPerYear.floor(),
      'daysWastedInFuture': daysWastedInFuture.floor(),
      'percentageOfLifeWasted': percentageOfLifeWasted,
      'daysSavedPerYear': daysSavedPerYear.floor(),
      'daysSavedIn2Weeks': daysSavedIn2Weeks,
    };
  }

  /// Save selected verse categories from Step 7
  Future<void> saveVerseCategories(List<String> categories) async {
    selectedCategories.value = categories;
    await _storage.writeString(
      _keySelectedVerseCategories,
      categories.join(','),
    );

    // Track user property and feature adoption
    if (_analytics.isReady) {
      await _analytics.onboarding.setUserProperties({
        'selected_categories': categories.join(','),
      });
      await _analytics.onboarding.trackFeatureAdoption(
        featureName: 'verse_categories',
        value: categories.length,
      );
    }
  }

  /// Save selected apps from Step 7
  Future<void> saveSelectedApps(List<String> apps) async {
    selectedApps.value = apps;
    await _storage.writeString(_keySelectedApps, apps.join(','));

    // Track user property and feature adoption
    if (_analytics.isReady) {
      await _analytics.onboarding.setUserProperties({
        'selected_apps_count': apps.length,
      });
      await _analytics.onboarding.trackFeatureAdoption(
        featureName: 'apps_selection',
        value: apps.length,
      );
    }
  }

  /// Save intensity level from Step 7
  Future<void> saveIntensityLevel(String level) async {
    intensityLevel.value = level;
    await _storage.writeString(_keyIntensityLevel, level);

    // Track user property and feature adoption
    if (_analytics.isReady) {
      await _analytics.onboarding.setUserProperties({
        'intensity_level': level,
      });
      await _analytics.onboarding.trackFeatureAdoption(
        featureName: 'intensity_level',
        value: level,
      );
    }
  }

  /// Save covenant acceptance from Step 6
  Future<void> acceptCovenant(bool accepted) async {
    covenantAccepted.value = accepted;
    await _storage.writeBool(_keySacredCovenantAccepted, accepted);

    // Track user property
    if (_analytics.isReady) {
      await _analytics.onboarding.setUserProperties({
        'covenant_accepted': accepted,
      });
    }
  }

  /// Save schedules from Step 5 (Armor Configuration)
  Future<void> saveSchedules(List<Map<String, dynamic>> schedules) async {
    // Convert TimeOfDay to string format for storage. Skip any malformed
    // entries so a missing/mistyped 'start'|'end' can't crash the save.
    final schedulesData = schedules
        .where((s) => s['start'] is TimeOfDay && s['end'] is TimeOfDay)
        .map((schedule) {
      final start = schedule['start'] as TimeOfDay;
      final end = schedule['end'] as TimeOfDay;

      return {
        'name': schedule['name'],
        'icon': schedule['icon'],
        'startHour': start.hour,
        'startMinute': start.minute,
        'endHour': end.hour,
        'endMinute': end.minute,
        'enabled': schedule['enabled'],
      };
    }).toList();

    await _storage.writeString(_keySchedules, jsonEncode(schedulesData));

    // Track user property and feature adoption
    if (_analytics.isReady) {
      await _analytics.onboarding.setUserProperties({
        'schedules_count': schedulesData.length,
      });
      await _analytics.onboarding.trackFeatureAdoption(
        featureName: 'schedules',
        value: schedulesData.length,
      );
    }

    // Setup native DeviceActivity schedules
    try {
      final screenTimeService = Get.find<ScreenTimeService>();
      await screenTimeService.setupSchedules(schedulesData);
    } catch (e) {
      print('⚠️ Failed to setup native schedules: $e');
      // Don't throw - allow onboarding to continue
    }
  }

  /// Complete onboarding
  Future<void> completeOnboarding() async {
    await _prefs.writeBool(_keyOnboardingComplete, true);

    // Request iOS App Tracking Transparency *before* firing conversion events,
    // so Meta receives them with the correct authorization status. The prompt
    // is shown only on iOS 14.5+ and only the first time. On Android / older
    // iOS this is a no-op.
    try {
      await MetaService.instance.requestTracking();
    } catch (e) {
      debugPrint('ATT request failed: $e');
    }

    // Track onboarding completion
    if (_analytics.isReady) {
      await _analytics.onboarding.trackOnboardingComplete();
    }

    // Track TikTok registration event
    try {
      TikTokService.instance.trackCompleteRegistration();
    } catch (e) {
      debugPrint('TikTok trackCompleteRegistration failed: $e');
    }

    // Track Meta CompleteRegistration event
    try {
      await MetaService.instance.trackCompleteRegistration(method: 'onboarding');
    } catch (e) {
      debugPrint('Meta trackCompleteRegistration failed: $e');
    }
  }

  /// Complete summary screen
  Future<void> completeSummary() async {
    await _prefs.writeBool(_keySummaryComplete, true);
  }

  /// Check if summary is complete
  Future<bool> isSummaryComplete() async {
    return await _prefs.readBool(_keySummaryComplete) ?? false;
  }

  /// Check if user has ever accessed app features (with active subscription)
  Future<bool> hasAccessedFeatures() async {
    return await _prefs.readBool(_keyHasAccessedFeatures) ?? false;
  }

  /// Mark that user has accessed app features
  /// Call this when user successfully enters MainScreen with active subscription
  Future<void> markFeaturesAccessed() async {
    await _prefs.writeBool(_keyHasAccessedFeatures, true);
    debugPrint('✅ User marked as having accessed app features');
  }

  /// Reset onboarding (for testing)
  Future<void> resetOnboarding() async {
    await _prefs.writeBool(_keyOnboardingComplete, false);
    await _prefs.writeBool(_keySummaryComplete, false);
    await _prefs.writeBool(_keyHasAccessedFeatures, false);
    currentStep.value = 1;
    hoursPerDay.value = 0.0;
    ageSkipped.value = false;
    selectedCategories.clear();
    selectedApps.clear();
    intensityLevel.value = 'Balanced';
    covenantAccepted.value = false;
  }

  /// Fill with realistic demo data (for testing/demos)
  Future<void> fillWithDemoData() async {
    // Save realistic demo data
    await saveUserName('John');
    await saveUserAge(28);
    await saveHoursPerDay(6.5);
    await savePrayerFrequency(3);
    await save30DayGoals([
      'Spend more time in prayer',
      'Read the Bible daily',
      'Reduce phone addiction',
    ]);
    await saveVerseCategories([
      'Temptation & Purity',
      'Self-Control & Discipline',
      'Time & Wisdom',
    ]);
    await saveSelectedApps([
      'Instagram',
      'TikTok',
      'YouTube',
    ]);
    await saveIntensityLevel('Balanced');
    await acceptCovenant(true);

    // Save default schedules (already initialized in onInit)
    final defaultSchedules = [
      {
        'name': 'Morning Focus',
        'icon': '🌅',
        'start': const TimeOfDay(hour: 8, minute: 0),
        'end': const TimeOfDay(hour: 10, minute: 0),
        'enabled': true,
      },
      {
        'name': 'Afternoon Lock',
        'icon': '☀️',
        'start': const TimeOfDay(hour: 12, minute: 0),
        'end': const TimeOfDay(hour: 16, minute: 0),
        'enabled': true,
      },
      {
        'name': 'Night Protection',
        'icon': '🌙',
        'start': const TimeOfDay(hour: 20, minute: 0),
        'end': const TimeOfDay(hour: 23, minute: 0),
        'enabled': true,
      },
    ];
    await saveSchedules(defaultSchedules);

    // Complete onboarding
    await completeOnboarding();

    debugPrint('✅ Demo data filled successfully');
  }

  // =========================================================================
  // Analytics Tracking Methods
  // =========================================================================

  /// Get step name for analytics
  String _getStepName(int step) {
    switch (step) {
      case 1:
        return 'Welcome';
      case 2:
        return 'Name Capture';
      case 3:
        return 'Attribution';
      case 4:
        return 'Divine Revelation';
      case 5:
        return 'Self Confrontation';
      case 6:
        return 'Eternal Warfare';
      case 7:
        return 'Testimonials';
      case 8:
        return 'Call to Covenant';
      case 9:
        return 'Final Encouragement';
      case 10:
        return 'Screen Time Permission';
      case 11:
        return 'Notification Permission';
      case 12:
        return 'Summary';
      case 13:
        return 'Free For You';
      default:
        return 'Unknown Step';
    }
  }

  /// Track step entry
  Future<void> _trackStepEntry() async {
    try {
      await _analytics.onboarding.trackStepEntry(
        stepNumber: currentStep.value,
        stepName: _getStepName(currentStep.value),
      );
    } catch (e) {
      debugPrint('Failed to track step entry: $e');
    }
  }

  /// Track step exit with user choices metadata
  Future<void> _trackStepExit() async {
    try {
      // Collect step-specific metadata
      final metadata = _getStepMetadata(currentStep.value);

      await _analytics.onboarding.trackStepExit(
        stepNumber: currentStep.value,
        stepName: _getStepName(currentStep.value),
        metadata: metadata,
      );
    } catch (e) {
      debugPrint('Failed to track step exit: $e');
    }
  }

  /// Get metadata for each step based on user choices
  Map<String, dynamic>? _getStepMetadata(int step) {
    switch (step) {
      case 2:
        return {
          if (userName.value.isNotEmpty) 'user_name_provided': true,
          'age_skipped': ageSkipped.value,
        };

      case 3:
        return {
          'attribution_provided': true,
        };

      case 5:
        return {
          'hours_per_day': hoursPerDay.value,
          'hours_category': _categorizeHours(hoursPerDay.value),
          'prayer_times_per_week': prayerTimesPerWeek.value,
          'prayer_frequency_category':
              _categorizePrayerFrequency(prayerTimesPerWeek.value),
        };

      case 8:
        return {
          'covenant_accepted': covenantAccepted.value,
        };

      case 10:
        return {
          'screen_time_permission_requested': true,
        };

      case 11:
        return {
          'notification_permission_requested': true,
        };

      default:
        return null;
    }
  }

  /// Categorize hours for better analysis
  String _categorizeHours(double hours) {
    if (hours < 2) return 'light_usage';
    if (hours < 4) return 'moderate_usage';
    if (hours < 6) return 'heavy_usage';
    return 'extreme_usage';
  }

  /// Categorize prayer frequency
  String _categorizePrayerFrequency(int times) {
    if (times == 0) return 'never';
    if (times < 3) return 'occasional';
    if (times < 7) return 'regular';
    return 'daily_plus';
  }
}
