import 'package:faithlock/features/faithlock/models/export.dart';
import 'package:faithlock/features/faithlock/services/export.dart';
import 'package:faithlock/services/analytics/posthog/export.dart';
import 'package:get/get.dart';

class UnlockController extends GetxController {
  final VerseService _verseService = VerseService();
  final StatsService _statsService = StatsService();
  final LockService _lockService = LockService();
  final ScreenTimeService _screenTimeService = ScreenTimeService();
  final PostHogService _analytics = PostHogService.instance;

  // Observable state
  final Rx<BibleVerse?> currentVerse = Rx<BibleVerse?>(null);
  final Rx<VerseQuiz?> currentQuiz = Rx<VerseQuiz?>(null);
  final RxInt selectedAnswer = RxInt(-1);
  final RxBool isLoading = RxBool(true);
  final RxBool showError = RxBool(false);
  final RxString errorMessage = RxString('');
  final RxInt attemptCount = RxInt(0);
  final Rx<DateTime?> unlockStartTime = Rx<DateTime?>(null);
  final RxBool isAnswerRevealed = RxBool(false);

  // Constants
  static const int maxAttempts = 3;

  @override
  void onInit() {
    super.onInit();
    _loadVerseAndQuiz();
  }

  Future<void> _loadVerseAndQuiz() async {
    try {
      isLoading.value = true;
      unlockStartTime.value = DateTime.now();

      // Get current streak for difficulty scaling
      final stats = await _statsService.getUserStats();

      // Get contextual verse based on time and streak
      BibleVerse? verse;

      if (stats.currentStreak > 0) {
        verse = await _verseService.getVerseForStreak(stats.currentStreak);
      } else {
        verse = await _verseService.getContextualVerse();
      }

      if (verse == null) {
        // Fallback to random verse
        verse = await _verseService.getRandomVerse();
      }

      if (verse == null) {
        throw Exception('No verses available');
      }

      currentVerse.value = verse;
      currentQuiz.value = VerseQuiz.fromVerse(verse);
      isLoading.value = false;

      if (_analytics.isReady) {
        _analytics.events.trackCustom('unlock_verse_loaded', {
          'verse_id': verse.id,
          'verse_reference': verse.reference,
          'streak_based': stats.currentStreak > 0,
        });
      }
    } catch (e) {
      isLoading.value = false;
      showError.value = true;
      errorMessage.value = 'Failed to load verse: $e';
    }
  }

  void selectAnswer(int index) {
    if (isAnswerRevealed.value) return;
    selectedAnswer.value = index;
  }

  Future<void> submitAnswer() async {
    if (selectedAnswer.value == -1) {
      errorMessage.value = 'Please select an answer';
      showError.value = true;
      return;
    }

    if (currentQuiz.value == null || currentVerse.value == null) return;

    attemptCount.value++;
    final isCorrect = currentQuiz.value!.isCorrectAnswer(selectedAnswer.value);

    if (_analytics.isReady) {
      _analytics.events.trackCustom('unlock_answer_submitted', {
        'verse_id': currentVerse.value!.id,
        'verse_reference': currentVerse.value!.reference,
        'is_correct': isCorrect,
        'attempt_number': attemptCount.value,
      });
    }

    if (isCorrect) {
      await _handleSuccessfulUnlock();
    } else {
      await _handleFailedAttempt();
    }
  }

  Future<void> _handleSuccessfulUnlock() async {
    try {
      // Calculate time to unlock
      final timeToUnlock = unlockStartTime.value != null
          ? DateTime.now().difference(unlockStartTime.value!).inSeconds
          : null;

      // Record successful unlock
      await _statsService.recordUnlockAttempt(
        verseId: currentVerse.value!.id,
        wasSuccessful: true,
        attemptCount: attemptCount.value,
        timeToUnlockSeconds: timeToUnlock,
        method: UnlockMethod.bibleQuiz,
      );

      if (_analytics.isReady) {
        _analytics.events.trackCustom('unlock_successful', {
          'verse_id': currentVerse.value!.id,
          'verse_reference': currentVerse.value!.reference,
          'attempt_count': attemptCount.value,
          'time_to_unlock_seconds': timeToUnlock,
        });
      }

      // Stop Screen Time blocking
      await _screenTimeService.stopBlocking();

      // Clear active lock
      await _lockService.setActiveLock(null);

      // Show success message and close
      Get.back(result: true);
    } catch (e) {
      errorMessage.value = 'Failed to record unlock: $e';
      showError.value = true;
    }
  }

  Future<void> _handleFailedAttempt() async {
    if (attemptCount.value >= maxAttempts) {
      // Max attempts reached - show correct answer
      isAnswerRevealed.value = true;
      errorMessage.value = 'Maximum attempts reached. The correct answer is shown in green.';
      showError.value = true;

      if (_analytics.isReady) {
        _analytics.events.trackCustom('unlock_max_attempts_reached', {
          'verse_id': currentVerse.value!.id,
          'verse_reference': currentVerse.value!.reference,
          'attempt_count': attemptCount.value,
        });
      }

      // Record failed unlock
      await _statsService.recordUnlockAttempt(
        verseId: currentVerse.value!.id,
        wasSuccessful: false,
        attemptCount: attemptCount.value,
        method: UnlockMethod.bibleQuiz,
      );
    } else {
      // Show error and allow retry
      errorMessage.value = 'Incorrect answer. ${maxAttempts - attemptCount.value} attempts remaining.';
      showError.value = true;
      selectedAnswer.value = -1; // Reset selection
    }
  }

  Future<void> useEmergencyBypass() async {
    // Emergency bypass with penalty
    try {
      if (_analytics.isReady) {
        _analytics.events.trackCustom('unlock_emergency_bypass', {
          'verse_id': currentVerse.value?.id ?? 'emergency',
          'attempt_count': attemptCount.value,
        });
      }

      await _statsService.recordUnlockAttempt(
        verseId: currentVerse.value?.id ?? 'emergency',
        wasSuccessful: false,
        attemptCount: maxAttempts,
        method: UnlockMethod.bibleQuiz,
      );

      await _lockService.setActiveLock(null);
      Get.back(result: false); // false indicates emergency bypass
    } catch (e) {
      errorMessage.value = 'Failed to bypass: $e';
      showError.value = true;
    }
  }

  Future<void> retryWithNewVerse() async {
    if (_analytics.isReady) {
      _analytics.events.trackCustom('unlock_retry_new_verse', {
        'previous_verse_id': currentVerse.value?.id,
      });
    }

    selectedAnswer.value = -1;
    attemptCount.value = 0;
    isAnswerRevealed.value = false;
    showError.value = false;
    await _loadVerseAndQuiz();
  }
}
