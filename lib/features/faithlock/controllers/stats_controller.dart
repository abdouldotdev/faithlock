import 'dart:async';

import 'package:faithlock/features/faithlock/models/export.dart';
import 'package:faithlock/features/faithlock/services/export.dart';
import 'package:faithlock/services/analytics/posthog/export.dart';
import 'package:faithlock/services/home_widget_service.dart';
import 'package:faithlock/services/storage/secure_storage_service.dart';
import 'package:get/get.dart';

/// Controller for Stats Dashboard Screen
/// Manages loading and refreshing user statistics
class StatsController extends GetxController {
  final StatsService _statsService = StatsService();
  final ScreenTimeService _screenTimeService = ScreenTimeService();
  final StorageService _storage = StorageService();
  final VerseService _verseService = VerseService();
  final PostHogService _analytics = PostHogService.instance;
  final StreakFreezeService _freezeService = StreakFreezeService();
  final BadgeService _badgeService = BadgeService();

  // Observable state
  final Rx<UserStats?> userStats = Rx<UserStats?>(null);
  final RxBool isLoading = RxBool(true);
  final RxString errorMessage = RxString('');
  final RxInt lockedAppsCount = RxInt(0);
  final RxString userName = RxString('');
  final Rx<BibleVerse?> dailyVerse = Rx<BibleVerse?>(null);
  final RxBool isDailyVerseFavorite = RxBool(false);
  final Rx<StreakFreezeState?> freezeState = Rx<StreakFreezeState?>(null);
  final RxList<EarnedBadge> earnedBadges = <EarnedBadge>[].obs;

  // Timer for periodic refresh after picker
  Timer? _refreshTimer;

  // DEBUG: Enable fake stats for screenshots
  static const bool useFakeStats = true; // Set to false for production

  @override
  void onInit() {
    super.onInit();
    // TEMPORARY: Reset test streak data - Remove this line after app restart
    // _statsService.resetAllStats();
    loadStats();
    loadLockedAppsCount();
    loadUserName();
    loadDailyVerse();
    loadFreezeState();
    loadEarnedBadges();

    // Track dashboard viewed
    if (_analytics.isReady) {
      _analytics.events.trackCustom('stats_dashboard_viewed', {
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  /// Load user name from storage
  Future<void> loadUserName() async {
    try {
      final name = await _storage.readString('user_name');
      userName.value = name ?? '';
    } catch (e) {
      userName.value = '';
    }
  }

  /// Load user statistics from service
  Future<void> loadStats() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final stats = await _statsService.getUserStats();
      userStats.value = stats;
      // Keep the iOS home-screen widget in step with fresh stats (no-op off iOS).
      unawaited(HomeWidgetService.instance.refreshFromControllers());
    } catch (e) {
      errorMessage.value = 'Failed to load statistics: $e';
    } finally {
      isLoading.value = false;
    }
  }

  /// Load locked apps count
  Future<void> loadLockedAppsCount() async {
    try {
      final count = await _screenTimeService.getSelectedAppsCount();
      lockedAppsCount.value = count;
    } catch (e) {
      lockedAppsCount.value = 0;
    }
  }

  /// Load daily verse from database
  Future<void> loadDailyVerse() async {
    try {
      final verse = await _verseService.getDailyVerse();
      dailyVerse.value = verse;

      if (verse != null) {
        final isFav = await _verseService.isFavorite(verse.id);
        isDailyVerseFavorite.value = isFav;
      }
    } catch (e) {
      dailyVerse.value = null;
      isDailyVerseFavorite.value = false;
    }
  }

  /// Load streak freeze state
  Future<void> loadFreezeState() async {
    try {
      final state = await _freezeService.getFreezeState();
      freezeState.value = state;
    } catch (e) {
      freezeState.value = null;
    }
  }

  /// Load earned badges from database
  Future<void> loadEarnedBadges() async {
    try {
      final badges = await _badgeService.getEarnedBadges();
      earnedBadges.assignAll(badges);
    } catch (e) {
      earnedBadges.clear();
    }
  }

  /// Toggle favorite status for daily verse
  Future<void> toggleDailyVerseFavorite() async {
    try {
      if (dailyVerse.value == null) return;

      final newStatus =
          await _verseService.toggleFavorite(dailyVerse.value!.id);
      isDailyVerseFavorite.value = newStatus;

      // Track favorite toggle
      if (_analytics.isReady) {
        _analytics.events.trackCustom('daily_verse_favorite_toggled', {
          'verse_id': dailyVerse.value!.id,
          'verse_reference': dailyVerse.value!.reference,
          'is_favorite': newStatus,
        });
      }
    } catch (e) {
      // Handle error silently or show message
    }
  }

  /// Open app picker
  /// Starts a periodic check to detect when picker is closed and selection changes
  Future<void> openAppPicker() async {
    try {
      // Track app picker opened
      if (_analytics.isReady) {
        _analytics.events.trackCustom('app_picker_opened', {
          'current_locked_count': lockedAppsCount.value,
        });
      }

      // Store current count before opening picker
      final currentCount = lockedAppsCount.value;

      await _screenTimeService.presentAppPicker();

      // Start periodic check (every 500ms for 10 seconds)
      // This will detect when the picker is closed and selection changes
      int checks = 0;
      _refreshTimer?.cancel();
      _refreshTimer =
          Timer.periodic(const Duration(milliseconds: 500), (timer) async {
        checks++;

        // Get updated count
        final newCount = await _screenTimeService.getSelectedAppsCount();

        if (newCount != currentCount) {
          lockedAppsCount.value = newCount;
          timer.cancel();
        }

        // Stop after 10 seconds (20 checks)
        if (checks >= 20) {
          timer.cancel();
          // Do final check
          await loadLockedAppsCount();
        }
      });
    } catch (e) {
      // Handle error silently or show message
      _refreshTimer?.cancel();
    }
  }

  @override
  void onClose() {
    _refreshTimer?.cancel();
    super.onClose();
  }

  /// Refresh statistics (pull-to-refresh)
  Future<void> refreshStats() async {
    await loadStats();
    await loadFreezeState();
    await loadEarnedBadges();
  }

  /// Get formatted streak text
  String getStreakText() {
    if (userStats.value == null) return '0 days';
    final streak = userStats.value!.currentStreak;
    return '$streak ${streak == 1 ? 'day' : 'days'}';
  }

  /// Get formatted verses read text
  String getVersesReadText() {
    if (userStats.value == null) return '0 verses';
    final verses = userStats.value!.totalVersesRead;
    return '$verses ${verses == 1 ? 'verse' : 'verses'}';
  }

  /// Get formatted success rate text
  String getSuccessRateText() {
    if (userStats.value == null) return '0%';
    final rate = userStats.value!.averageQuizScore;
    return '${(rate * 100).toStringAsFixed(0)}%';
  }

  /// Get formatted screen time text
  String getScreenTimeText() {
    if (userStats.value == null) return '0 min';
    final minutes = userStats.value!.screenTimeReducedMinutes;

    if (minutes < 60) {
      return '$minutes min';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      if (remainingMinutes == 0) {
        return '$hours ${hours == 1 ? 'hr' : 'hrs'}';
      }
      return '${hours}h ${remainingMinutes}m';
    }
  }

  /// Get personalized greeting based on time of day
  String getGreeting() {
    final hour = DateTime.now().hour;
    final name = userName.value.isNotEmpty ? ', ${userName.value}' : '';

    if (hour < 12) {
      return 'Good Morning$name';
    } else if (hour < 17) {
      return 'Good Afternoon$name';
    } else if (hour < 21) {
      return 'Good Evening$name';
    } else {
      return 'Good Night$name';
    }
  }

  /// Get varied greeting messages with name
  String getVariedGreeting() {
    final hour = DateTime.now().hour;
    final name = userName.value.isNotEmpty ? userName.value : 'Friend';

    if (hour < 12) {
      final morningGreetings = [
        'Good Morning, $name',
        'Rise and Shine, $name',
        'Hello $name, Blessed Morning',
        'Morning $name!',
      ];
      return morningGreetings[DateTime.now().day % morningGreetings.length];
    } else if (hour < 17) {
      final afternoonGreetings = [
        'Good Afternoon, $name',
        'Hello $name!',
        'Blessed Day, $name',
        'Hey $name!',
      ];
      return afternoonGreetings[DateTime.now().day % afternoonGreetings.length];
    } else if (hour < 21) {
      final eveningGreetings = [
        'Good Evening, $name',
        'Evening $name!',
        'Hello $name, Blessed Evening',
        'Hey $name!',
      ];
      return eveningGreetings[DateTime.now().day % eveningGreetings.length];
    } else {
      final nightGreetings = [
        'Good Night, $name',
        'Evening $name!',
        'Hello $name',
        'Hey $name!',
      ];
      return nightGreetings[DateTime.now().day % nightGreetings.length];
    }
  }

  /// Get greeting emoji
  String getGreetingEmoji() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return '🌅';
    } else if (hour < 17) {
      return '☀️';
    } else if (hour < 21) {
      return '🌆';
    } else {
      return '🌙';
    }
  }

  /// Get inspirational verse snippet
  String getInspirationalQuote() {
    return '"Be strong in the Lord and in His mighty power."';
  }

  /// Get journey context text
  String getJourneyText() {
    if (userStats.value == null) return 'Start your journey today';
    final streak = userStats.value!.currentStreak;
    if (streak == 0) {
      return 'Begin your spiritual journey';
    } else if (streak == 1) {
      return 'Day 1 of your journey';
    } else {
      return 'Day $streak of your journey';
    }
  }

  /// Get motivational message based on streak
  String getMotivationalMessage() {
    if (userStats.value == null) return '✨ Start your spiritual journey';
    final streak = userStats.value!.currentStreak;

    if (streak == 0) {
      return '🌱 Every journey begins with a first step';
    } else if (streak == 1) {
      return '✨ You\'ve started! Keep going';
    } else if (streak == 2) {
      return '💫 Two days strong! Momentum building';
    } else if (streak == 3) {
      return '🔥 3 days consecutive!';
    } else if (streak == 4) {
      return '💪 Your discipline is inspiring';
    } else if (streak == 5) {
      return '⭐ 5 days! Almost there';
    } else if (streak == 6) {
      return '🌟 One more day to complete the week!';
    } else if (streak == 7) {
      return '🎉 7 days complete! You did it!';
    } else if (streak < 14) {
      return '🏆 $streak days of victories!';
    } else if (streak < 30) {
      return '👑 $streak days! You\'re unstoppable';
    } else {
      return '🔥 $streak days! Legendary streak';
    }
  }

  /// Get inspirational quote
  String getInspirationalVerseQuote() {
    final quotes = [
      '"Be strong and courageous" - Joshua 1:9',
      '"Faith can move mountains" - Matthew 17:20',
      '"I can do all things through Christ" - Philippians 4:13',
      '"The Lord is my strength" - Exodus 15:2',
      '"Trust in the Lord with all your heart" - Proverbs 3:5',
      '"Be still and know that I am God" - Psalm 46:10',
      '"Walk by faith, not by sight" - 2 Corinthians 5:7',
      '"He gives strength to the weary" - Isaiah 40:29',
    ];

    // Rotate quote based on day of year
    final dayOfYear =
        DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    return quotes[dayOfYear % quotes.length];
  }

  /// Get progress to next milestone (0.0 - 1.0)
  double getProgressToNextMilestone() {
    if (userStats.value == null) return 0.0;
    final streak = userStats.value!.currentStreak;

    if (streak < 7) {
      return streak / 7.0;
    } else if (streak < 14) {
      return (streak - 7) / 7.0;
    } else if (streak < 30) {
      return (streak - 14) / 16.0;
    } else {
      return 1.0;
    }
  }

  /// Get next milestone text
  String getNextMilestoneText() {
    if (userStats.value == null) return '7 days 🎯';
    final streak = userStats.value!.currentStreak;

    if (streak < 7) {
      final remaining = 7 - streak;
      return '$remaining day${remaining == 1 ? '' : 's'} to 7-day streak 🎯';
    } else if (streak < 14) {
      final remaining = 14 - streak;
      return '$remaining day${remaining == 1 ? '' : 's'} to 14-day streak 🏆';
    } else if (streak < 30) {
      final remaining = 30 - streak;
      return '$remaining day${remaining == 1 ? '' : 's'} to 30-day streak 👑';
    } else {
      return 'Legendary status! 🔥';
    }
  }
}
