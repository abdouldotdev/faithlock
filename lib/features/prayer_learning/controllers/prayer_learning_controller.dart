import 'dart:async';

import 'package:faithlock/features/faithlock/models/export.dart';
import 'package:faithlock/features/faithlock/services/badge_service.dart';
import 'package:faithlock/features/faithlock/services/gamification_dialog_service.dart';
import 'package:faithlock/features/faithlock/services/question_generator.dart';
import 'package:faithlock/features/faithlock/services/stats_service.dart';
import 'package:faithlock/features/faithlock/services/streak_freeze_service.dart';
import 'package:faithlock/features/faithlock/services/unlock_timer_service.dart';
import 'package:faithlock/features/faithlock/services/verse_selection_strategy.dart';
import 'package:faithlock/features/bible/data/bible_repository.dart';
import 'package:faithlock/features/lock_challenge/models/verse_question.dart';
import 'package:faithlock/services/ai/meditation_validator_service.dart';
import 'package:faithlock/services/analytics/posthog/export.dart';
import 'package:faithlock/services/analytics/posthog/first_value_instrumentation.dart';
import 'package:faithlock/services/rate_app_service.dart';
import 'package:faithlock/services/storage/preferences_service.dart';
import 'package:faithlock/services/storage/secure_storage_service.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Validation states for meditation response
enum ValidationState {
  idle, // Not yet validated
  validating, // AI validation in progress
  valid, // Validation passed
  invalid, // Validation failed
}

/// Controller for guided prayer learning (Balanced mode)
class PrayerLearningController extends GetxController {
  final StorageService _storage = StorageService();
  final StatsService _statsService = StatsService();
  final VerseSelectionStrategy _verseStrategy = VerseSelectionStrategy();
  final MeditationValidatorService _validator = MeditationValidatorService();
  final PostHogService _analytics = PostHogService.instance;
  late final Future<FirstValueInstrumentation> _firstValueInstrumentation =
      _createFirstValueInstrumentation();

  // Text controllers - persist across rebuilds
  late final TextEditingController meditationTextController;
  late final TextEditingController recitationTextController;

  // Observable state
  final RxInt currentStep = RxInt(0);
  final RxString meditationInput = RxString('');
  final RxString recitationInput = RxString('');
  final RxInt meditationTimer = RxInt(30);
  final RxBool isTimerRunning = RxBool(false);
  final RxBool showHint = RxBool(false);
  final RxDouble completionScore = RxDouble(0.0);
  final Rxn<VerseQuestion> selectedVerse = Rxn<VerseQuestion>();
  final RxInt unlockDurationMinutes = RxInt(0);

  // Confetti on the completion step is held back until any gamification dialogs
  // (badge earned, etc.) have been dismissed — otherwise the dialog covers the
  // 3s burst and it's only visible on later sessions with no new badge.
  final RxBool showConfetti = false.obs;

  // Meditation validation state
  final Rx<ValidationState> meditationValidationState =
      ValidationState.idle.obs;
  final RxString validationFeedback = RxString('');
  final RxDouble meditationQualityScore =
      RxDouble(0.0); // AI validation score (0.0-1.0)

  // Steps in Balanced mode
  List<String> get stepTitles => [
        'prayer_readAbsorb'.tr,
        'prayer_meditate'.tr,
        'prayer_remember'.tr,
        'prayer_complete'.tr,
      ];

  // Timer
  Timer? _timer;

  // Session tracking
  DateTime? _sessionStartTime;

  @override
  void onInit() {
    super.onInit();
    _sessionStartTime = DateTime.now();

    // Initialize text controllers
    meditationTextController = TextEditingController();
    recitationTextController = TextEditingController();

    // Listen to text changes
    meditationTextController.addListener(() {
      meditationInput.value = meditationTextController.text;
    });
    recitationTextController.addListener(() {
      recitationInput.value = recitationTextController.text;
      showHint.value = false;
    });

    _loadVerse();
    unawaited(_recordFirstFocusStarted());

    // Track session started
    if (_analytics.isReady) {
      _analytics.events.trackCustom('prayer_session_started', {
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  static Future<FirstValueInstrumentation> _createFirstValueInstrumentation() async {
    final preferences = await SharedPreferences.getInstance();
    return FirstValueInstrumentation(
      store: SharedPreferencesFirstValueStore(preferences),
      isReady: () => PostHogService.instance.isReady,
      emit: (event) async {
        final analytics = PostHogService.instance;
        if (!analytics.isReady) return;
        await analytics.events.trackCustom(event.name, event.properties);
      },
    );
  }

  Future<void> _recordFirstFocusStarted() async {
    final instrumentation = await _firstValueInstrumentation;
    await instrumentation.recordFocusStarted(at: DateTime.now());
  }

  Future<void> _recordFirstFocusCompleted() async {
    final instrumentation = await _firstValueInstrumentation;
    await instrumentation.recordFocusCompleted(at: DateTime.now());
  }

  @override
  void onClose() {
    _timer?.cancel();
    meditationTextController.dispose();
    recitationTextController.dispose();
    super.onClose();
  }

  /// Load a verse based on user's selected categories and current streak
  /// Uses intelligent curriculum progression for Days 1-28
  Future<void> _loadVerse() async {
    try {
      // Get user's selected categories from onboarding
      final categoriesStr =
          await _storage.readString('selected_verse_categories');
      final categoryNames = categoriesStr?.split(',') ?? ['Temptation'];

      // Convert category names to VerseCategory enum
      final List<VerseCategory> selectedCategories = categoryNames
          .map((name) => VerseCategoryExtension.fromString(name.trim()))
          .toList();

      // Get current streak for curriculum progression
      final userStats = await _statsService.getUserStats();
      final currentStreak = userStats.currentStreak;
      debugPrint(
          '🎓 Loading verse for streak: $currentStreak, categories: $categoryNames');

      // Get recently shown verses for spaced repetition (last 7 days)
      final todayUnlocks = await _statsService.getTodayUnlocks();
      final excludeIds =
          todayUnlocks.map((attempt) => attempt.verseId).toList();

      // Use intelligent verse selection strategy
      final BibleVerse? verse = await _verseStrategy.selectVerse(
        currentStreak: currentStreak,
        selectedCategories: selectedCategories,
        excludeIds: excludeIds,
      );

      if (verse == null) {
        debugPrint('⚠️ No verse found, using fallback');
        _loadFallbackVerse();
        return;
      }

      // Show the verse text in the Bible version the user picked in Profile
      // (curriculum selection stays BSB; only the displayed text swaps).
      final displayVerse = await _localizeVerseText(verse);

      // Generate question from selected verse
      final question = QuestionGenerator.generateQuestion(displayVerse);
      selectedVerse.value = question;

      debugPrint(
          '✅ Loaded verse: ${displayVerse.reference} (${displayVerse.translation})');
    } catch (e) {
      debugPrint('❌ Error loading verse: $e');
      _loadFallbackVerse();
    }
  }

  /// Swap the verse text to the Bible version selected in Profile
  /// (`bible_selected_version`). The curriculum picks verses from the BSB
  /// dataset; here we look up the SAME reference in the chosen version's DB and
  /// use its text when present, falling back to BSB on any miss/error. The
  /// fill-in-the-blank keyword is kept — [QuestionGenerator] already regenerates
  /// from the shown text when that keyword isn't found (e.g. a French verse).
  Future<BibleVerse> _localizeVerseText(BibleVerse verse) async {
    try {
      final abbr =
          await PreferencesService().readString('bible_selected_version') ??
              'BSB';
      if (abbr == 'BSB') return verse;

      final records = await BibleRepository().versesFor(
        bookName: verse.book,
        chapter: verse.chapter,
        versionAbbr: abbr,
      );

      String? swapped;
      for (final r in records) {
        if (r.number == verse.verse) {
          swapped = r.text;
          break;
        }
      }

      if (swapped == null || swapped.isEmpty) return verse;
      return verse.copyWith(text: swapped, translation: abbr);
    } catch (e) {
      debugPrint('⚠️ Verse text-swap failed, keeping BSB: $e');
      return verse;
    }
  }

  /// Fallback verse when intelligent selection fails
  void _loadFallbackVerse() {
    selectedVerse.value = VerseQuestionDatabase.getQuestionsForCategories(
      ['Temptation'],
      count: 1,
    ).first;
  }

  /// Get current step title
  String get currentStepTitle => currentStep.value < stepTitles.length
      ? stepTitles[currentStep.value]
      : '';

  /// Get progress percentage
  double get progress => (currentStep.value + 1) / stepTitles.length;

  /// Check if we can proceed to next step
  bool get canProceed {
    switch (currentStep.value) {
      case 0: // Reading step - can always proceed
        return true;
      case 1: // Meditation - must be validated by AI
        return meditationValidationState.value == ValidationState.valid;
      case 2: // Fill-in-the-blank - must be correct
        return _isRecitationCorrect();
      case 3: // Complete
        return true;
      default:
        return false;
    }
  }

  /// Check if user can skip meditation anyway (has some input)
  bool get canSkipMeditation {
    return currentStep.value == 1 &&
        meditationValidationState.value == ValidationState.invalid;
  }

  /// Move to next step
  Future<void> nextStep() async {
    // Allow skip if meditation is invalid but user wants to proceed
    final allowSkip = canSkipMeditation;

    if ((canProceed || allowSkip) &&
        currentStep.value < stepTitles.length - 1) {
      // Track step completed
      if (_analytics.isReady) {
        _analytics.events.trackCustom('prayer_step_completed', {
          'step_index': currentStep.value,
          'step_name': stepTitles[currentStep.value],
          'verse_reference': selectedVerse.value?.reference ?? 'unknown',
          'was_skipped': allowSkip && !canProceed,
        });
      }

      // Calculate partial score for this step
      _updateCompletionScore();

      currentStep.value++;

      // Start timer for meditation step
      if (currentStep.value == 1) {
        _startMeditationTimer();
      }

      // If we just moved to the completion step, save stats
      if (currentStep.value == stepTitles.length - 1) {
        await _completeSession();
      }
    }
  }

  /// Move to previous step
  void previousStep() {
    if (currentStep.value > 0) {
      // Cancel timer if going back from meditation step
      if (currentStep.value == 1) {
        _timer?.cancel();
        isTimerRunning.value = false;
      }

      currentStep.value--;

      // Reset validation state when going back to meditation
      if (currentStep.value == 1) {
        resetMeditationValidation();
      }
    }
  }

  /// Start meditation countdown timer
  void _startMeditationTimer() {
    isTimerRunning.value = true;
    meditationTimer.value = 30;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (meditationTimer.value > 0) {
        meditationTimer.value--;
      } else {
        _timer?.cancel();
        isTimerRunning.value = false;
      }
    });
  }

  /// Skip meditation timer
  void skipTimer() {
    _timer?.cancel();
    meditationTimer.value = 0;
    isTimerRunning.value = false;
  }

  /// Check if recitation is correct
  bool _isRecitationCorrect() {
    if (selectedVerse.value == null) return false;

    final userAnswer = recitationInput.value.trim().toLowerCase();
    final correctAnswer = selectedVerse.value!.correctAnswer.toLowerCase();

    // Allow some flexibility (80% match)
    final similarity = _calculateSimilarity(userAnswer, correctAnswer);
    return similarity >= 0.8;
  }

  /// Calculate similarity between two strings (simple version)
  double _calculateSimilarity(String a, String b) {
    if (a == b) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;

    // Simple contains check for now
    if (b.contains(a) || a.contains(b)) {
      return 0.85;
    }

    return a == b ? 1.0 : 0.0;
  }

  /// Show hint for recitation
  void toggleHint() {
    showHint.value = !showHint.value;
  }

  /// Validate meditation response with AI
  Future<void> validateMeditationResponse() async {
    final response = meditationInput.value.trim();

    // Only block truly empty input up front — the AI is the judge of the
    // minimum (it rejects generic filler like "help me thanks").
    if (response.isEmpty) {
      meditationValidationState.value = ValidationState.invalid;
      validationFeedback.value = 'prayer_minThought'.tr;
      return;
    }

    // Start AI validation
    meditationValidationState.value = ValidationState.validating;
    validationFeedback.value = 'prayer_analyzingReflection'.tr;

    try {
      final verse = selectedVerse.value;
      if (verse == null) {
        meditationValidationState.value = ValidationState.invalid;
        validationFeedback.value = 'prayer_noVerseError'.tr;
        return;
      }

      // Get user goals and struggles (optional context)
      final userGoals = await _storage.readString('user_goals');
      final userStruggles = await _storage.readString('user_struggles');

      // Validate with AI
      final result = await _validator.validateMeditationResponse(
        verseText: verse.verse,
        verseReference: verse.reference,
        userResponse: response,
        userGoals: userGoals,
        userStruggles: userStruggles,
      );

      // Update state based on result
      meditationValidationState.value =
          result.isValid ? ValidationState.valid : ValidationState.invalid;
      validationFeedback.value = result.feedback;
      meditationQualityScore.value = result.score; // Store AI score (0.0-1.0)

      debugPrint(
          '✅ Meditation validated: ${result.isValid} (score: ${result.score})');
    } catch (e) {
      debugPrint('❌ Validation error: $e');
      // Fallback when the validator itself throws: keep the same minimum-effort
      // floor as the pre-check instead of accepting anything 3+ chars.
      final ok = !_isTooShortToReflect(response);
      meditationValidationState.value =
          ok ? ValidationState.valid : ValidationState.invalid;
      validationFeedback.value = ok
          ? '${'prayer_thankYouReflection'.tr} 🙏'
          : 'prayer_shareBriefThought'.tr;
      meditationQualityScore.value = ok ? 0.7 : 0.3; // Fallback score
    }
  }

  /// Minimum effort for a meditation reflection: a short real sentence (enough
  /// characters and at least a few words), not one or two words. Meaning-level
  /// filtering (e.g. rejecting generic "help me thanks") is done by the AI.
  bool _isTooShortToReflect(String response) {
    final t = response.trim();
    if (t.length < 12) return true;
    final words = t
        .split(RegExp(r'\s+'))
        .where((w) => RegExp(r'[a-zA-Zà-ÿ]').hasMatch(w));
    return words.length < 3;
  }

  /// Reset meditation validation state
  void resetMeditationValidation() {
    meditationValidationState.value = ValidationState.idle;
    validationFeedback.value = '';
  }

  /// Update completion score based on performance
  /// Scoring: Reading (20%) + Meditation (30% from AI) + Recitation (50%)
  void _updateCompletionScore() {
    switch (currentStep.value) {
      case 0: // Reading - Fixed 20%
        completionScore.value += 0.20;
        break;

      case 1: // Meditation - 30% (generous scoring)
        double meditationScore = 0.30; // Base meditation weight

        if (meditationValidationState.value == ValidationState.valid) {
          // AI validated - always give 25-30% (generous!)
          // AI score maps to 85-100% of meditation points
          final qualityMultiplier =
              0.85 + (meditationQualityScore.value * 0.15);
          completionScore.value += meditationScore * qualityMultiplier;
          debugPrint(
              '📊 Meditation score: ${(meditationScore * qualityMultiplier * 100).toInt()}% (validated ✓)');
        } else if (meditationValidationState.value == ValidationState.invalid) {
          // Invalid but user skipped - still give decent credit for effort
          completionScore.value +=
              meditationScore * 0.7; // 70% of meditation points
          debugPrint('📊 Meditation score: 21% (skipped)');
        } else {
          // Not validated - give credit for having any text (even short)
          final hasMinimalInput = meditationInput.value.trim().length >= 3;
          completionScore.value +=
              hasMinimalInput ? (meditationScore * 0.6) : 0;
          debugPrint(
              '📊 Meditation score: ${hasMinimalInput ? "18%" : "0%"} (not validated)');
        }
        break;

      case 2: // Recitation - 50% (generous scoring)
        final isCorrect = _isRecitationCorrect();
        final accuracy = _calculateRecitationAccuracy();

        if (isCorrect) {
          // Perfect recitation = full 50%
          completionScore.value += 0.50;
          debugPrint('📊 Recitation score: 50% (perfect!)');
        } else if (accuracy >= 0.7) {
          // 70%+ accuracy = 45% (generous!)
          completionScore.value += 0.45;
          debugPrint('📊 Recitation score: 45% (excellent!)');
        } else if (accuracy >= 0.5) {
          // 50-69% accuracy = 40%
          completionScore.value += 0.40;
          debugPrint('📊 Recitation score: 40% (great!)');
        } else {
          // <50% accuracy = 35% (still generous for effort)
          completionScore.value += 0.35;
          debugPrint('📊 Recitation score: 35% (good try!)');
        }
        break;
    }

    debugPrint(
        '📊 Total completion score: ${(completionScore.value * 100).toInt()}%');
  }

  /// Calculate recitation accuracy (0.0-1.0)
  double _calculateRecitationAccuracy() {
    if (selectedVerse.value == null) return 0.0;

    final expected = selectedVerse.value!.verse.toLowerCase().trim();
    final actual = recitationInput.value.toLowerCase().trim();

    if (actual.isEmpty) return 0.0;
    if (expected == actual) return 1.0;

    // Calculate similarity using simple word matching
    final expectedWords = expected.split(RegExp(r'\s+'));
    final actualWords = actual.split(RegExp(r'\s+'));

    int matches = 0;
    for (final word in actualWords) {
      if (expectedWords.contains(word)) {
        matches++;
      }
    }

    return actualWords.isEmpty ? 0.0 : matches / actualWords.length;
  }

  /// Complete the learning session
  Future<void> _completeSession() async {
    // Hold confetti until dialogs (if any) are dismissed — see [showConfetti].
    showConfetti.value = false;
    final sessionDuration = _sessionStartTime != null
        ? DateTime.now().difference(_sessionStartTime!).inSeconds
        : 60;

    if (selectedVerse.value != null) {
      try {
        await _statsService.recordUnlockAttempt(
          verseId: selectedVerse.value!.reference,
          wasSuccessful: true,
          attemptCount: 1,
          timeToUnlockSeconds: sessionDuration,
          unlockDurationMinutes: unlockDurationMinutes.value > 0
              ? unlockDurationMinutes.value
              : null, // Pass actual unlock duration
          method: UnlockMethod.prayerLearning,
        );
      } catch (e) {
        debugPrint('⚠️ Failed to record prayer stats: $e');
      }
    }

    // Track session completed
    if (_analytics.isReady) {
      _analytics.events.trackCustom('prayer_session_completed', {
        'verse_reference': selectedVerse.value?.reference ?? 'unknown',
        'completion_score': completionScore.value,
        'meditation_quality': meditationQualityScore.value,
        'session_duration_seconds': sessionDuration,
        'unlock_duration_minutes': unlockDurationMinutes.value,
      });
    }
    await _recordFirstFocusCompleted();

    try {
      await _saveStats();
    } catch (e) {
      debugPrint('⚠️ Failed to save stats: $e');
    }

    // Check and award badges
    List<Badge> newBadges = [];
    try {
      final badgeService = BadgeService();
      final updatedStats = await _statsService.getUserStats();
      newBadges = await badgeService.checkAndAwardBadges(
        stats: updatedStats,
        sessionScore: completionScore.value,
        sessionHour: DateTime.now().hour,
        usedStreakFreeze: _statsService.lastStreakFreezeUsed,
      );

      // Track analytics for freeze and badges
      if (_analytics.isReady) {
        if (_statsService.lastStreakFreezeUsed) {
          final freezeState = await StreakFreezeService().getFreezeState();
          _analytics.events.trackCustom('streak_freeze_used', {
            'streak_preserved': updatedStats.currentStreak,
            'freezes_remaining': freezeState.freezesRemaining,
          });
        }
        if (_statsService.lastStreakWasLost) {
          _analytics.events.trackCustom('streak_lost', {
            'previous_streak': _statsService.lostStreakValue,
          });
        }
        for (final badge in newBadges) {
          _analytics.events.trackCustom('badge_earned', {
            'badge_id': badge.id.name,
            'badge_name': badge.name,
            'badge_category': badge.category.name,
          });
        }
      }
    } catch (e) {
      debugPrint('⚠️ Badge check failed: $e');
    }

    // Show gamification dialogs after UI is ready
    final freezeUsed = _statsService.lastStreakFreezeUsed;
    final streakLost = _statsService.lastStreakWasLost;
    final lostValue = _statsService.lostStreakValue;
    _statsService.resetStreakFlags();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final context = Get.context;
      if (context == null || !context.mounted) return;

      if (freezeUsed) {
        try {
          final freezeState = await StreakFreezeService().getFreezeState();
          final stats = await _statsService.getUserStats();
          if (context.mounted) {
            await GamificationDialogService.showStreakFreezeSaved(
              context: context,
              currentStreak: stats.currentStreak,
              freezesRemaining: freezeState.freezesRemaining,
            );
          }
        } catch (e) {
          debugPrint('⚠️ Failed to show freeze dialog: $e');
        }
      } else if (streakLost && lostValue > 1) {
        try {
          if (context.mounted) {
            await GamificationDialogService.showStreakLost(
              context: context,
              lostStreak: lostValue,
            );
          }
        } catch (e) {
          debugPrint('⚠️ Failed to show streak lost dialog: $e');
        }
      }

      if (newBadges.isNotEmpty && context.mounted) {
        try {
          await GamificationDialogService.showBadgesEarned(
            context: context,
            badges: newBadges,
          );
        } catch (e) {
          debugPrint('⚠️ Failed to show badge dialog: $e');
        }
      }

      // Dialogs (if any) are dismissed now — let the confetti fly on the
      // revealed completion screen.
      showConfetti.value = true;
    });

    // Rating prompt logic: show after 3 prayers or schedule for next launch
    await RateAppService().tryShowRatingPrompt();
  }

  /// Start unlock timer with user-selected duration
  Future<void> startUnlockTimer(Duration duration) async {
    try {
      final unlockTimerService = UnlockTimerService();
      await unlockTimerService.startUnlock(duration: duration);

      final durationMinutes = duration.inMinutes;
      unlockDurationMinutes.value = durationMinutes;

      // Unified unlock-funnel event: the quiz grant converges here, mirroring
      // the prayer paths' UnlockFlowService.finishUnlock.
      if (_analytics.isReady) {
        final seconds = _sessionStartTime != null
            ? DateTime.now().difference(_sessionStartTime!).inSeconds
            : null;
        _analytics.events.trackCustom('unlock_completed', {
          'method': 'quiz',
          'mode': null,
          'prayer_id': selectedVerse.value?.reference,
          'duration_minutes': durationMinutes > 0 ? durationMinutes : null,
          'time_to_unlock_seconds': seconds,
        });
      }

      debugPrint('✅ Started unlock timer for $durationMinutes minutes');
    } catch (e) {
      debugPrint('❌ Failed to start unlock timer: $e');
      rethrow;
    }
  }

  /// Save learning statistics
  Future<void> _saveStats() async {
    try {
      // Increment prayer completions
      final completions =
          await _storage.readString('prayer_completions') ?? '0';
      final newCompletions = (int.tryParse(completions) ?? 0) + 1;
      await _storage.writeString(
          'prayer_completions', newCompletions.toString());

      // Update today's count
      final today = DateTime.now().toIso8601String().split('T')[0];
      final todayKey = 'prayers_$today';
      final todayPrayers = await _storage.readString(todayKey) ?? '0';
      final newTodayPrayers = (int.tryParse(todayPrayers) ?? 0) + 1;
      await _storage.writeString(todayKey, newTodayPrayers.toString());

      // Save completion score
      await _storage.writeString(
          'last_prayer_score', completionScore.value.toString());
    } catch (e) {
      print('Error saving stats: $e');
    }
  }

  /// Reset for new session
  void reset() {
    currentStep.value = 0;
    meditationInput.value = '';
    recitationInput.value = '';
    meditationTextController.clear();
    recitationTextController.clear();
    meditationTimer.value = 30;
    isTimerRunning.value = false;
    showHint.value = false;
    completionScore.value = 0.0;
    unlockDurationMinutes.value = 0;
    showConfetti.value = false;
    meditationValidationState.value = ValidationState.idle;
    validationFeedback.value = '';
    meditationQualityScore.value = 0.0;
    _timer?.cancel();
    _sessionStartTime = DateTime.now(); // Reset session start time
    _loadVerse();
  }
}
