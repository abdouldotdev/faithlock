import 'package:faithlock/features/faithlock/models/export.dart';
import 'package:faithlock/features/faithlock/services/faithlock_database_service.dart';
import 'package:faithlock/features/faithlock/services/streak_freeze_service.dart';
import 'package:faithlock/services/storage/secure_storage_service.dart';
import 'package:flutter/material.dart' hide Badge;

class StatsService {
  final FaithLockDatabaseService _db = FaithLockDatabaseService();
  final StorageService _storage = StorageService();
  final StreakFreezeService _freezeService = StreakFreezeService();

  // Streak event flags (reset after dialogs are shown)
  bool _lastStreakFreezeUsed = false;
  bool _lastStreakWasLost = false;
  int _lostStreakValue = 0;

  bool get lastStreakFreezeUsed => _lastStreakFreezeUsed;
  bool get lastStreakWasLost => _lastStreakWasLost;
  int get lostStreakValue => _lostStreakValue;

  void resetStreakFlags() {
    _lastStreakFreezeUsed = false;
    _lastStreakWasLost = false;
    _lostStreakValue = 0;
  }

  // Storage keys
  static const String _keyCurrentStreak = 'faithlock_current_streak';
  static const String _keyLongestStreak = 'faithlock_longest_streak';
  static const String _keyLastUnlockDate = 'faithlock_last_unlock_date';

  // Record unlock attempt
  Future<void> recordUnlockAttempt({
    required String verseId,
    required bool wasSuccessful,
    required int attemptCount,
    int? timeToUnlockSeconds,
    int? unlockDurationMinutes,
    UnlockMethod? method,
  }) async {
    final attempt = UnlockAttempt(
      verseId: verseId,
      timestamp: DateTime.now(),
      wasSuccessful: wasSuccessful,
      attemptCount: attemptCount,
      timeToUnlockSeconds: timeToUnlockSeconds,
      unlockDurationMinutes: unlockDurationMinutes,
      method: method,
    );

    await _db.insertUnlockAttempt(attempt);

    // Update daily stats
    await _updateDailyStats(wasSuccessful);

    // Update streak
    if (wasSuccessful) {
      await _updateStreak();
    }
  }

  // Update daily stats
  Future<void> _updateDailyStats(bool wasSuccessful) async {
    final today = DateTime.now();
    final stats = await _db.getDailyStats(today);

    final updated = DailyStats(
      date: today,
      versesRead: wasSuccessful ? stats.versesRead + 1 : stats.versesRead,
      successfulUnlocks: wasSuccessful ? stats.successfulUnlocks + 1 : stats.successfulUnlocks,
      failedAttempts: !wasSuccessful ? stats.failedAttempts + 1 : stats.failedAttempts,
      screenTimeMinutes: stats.screenTimeMinutes,
    );

    await _db.insertDailyStats(updated);
  }

  // Update streak (with freeze protection)
  Future<void> _updateStreak() async {
    // Reset flags for this update cycle
    _lastStreakFreezeUsed = false;
    _lastStreakWasLost = false;
    _lostStreakValue = 0;

    // Ensure freeze service is initialized and recharged
    await _freezeService.checkAndRecharge();

    final lastUnlockStr = await _storage.readString(_keyLastUnlockDate);
    final currentStreakStr = await _storage.readString(_keyCurrentStreak);
    final longestStreakStr = await _storage.readString(_keyLongestStreak);

    final currentStreak =
        currentStreakStr != null ? int.tryParse(currentStreakStr) ?? 0 : 0;
    final longestStreak =
        longestStreakStr != null ? int.tryParse(longestStreakStr) ?? 0 : 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (lastUnlockStr != null) {
      final lastUnlock = DateTime.parse(lastUnlockStr);
      final lastUnlockDay =
          DateTime(lastUnlock.year, lastUnlock.month, lastUnlock.day);

      // Check if already unlocked today
      if (lastUnlockDay == today) {
        return; // Streak already counted for today
      }

      final daysDiff = today.difference(lastUnlockDay).inDays;

      if (daysDiff == 1) {
        // Consecutive day — increment streak
        final newStreak = currentStreak + 1;
        await _storage.writeString(_keyCurrentStreak, newStreak.toString());

        if (newStreak > longestStreak) {
          await _storage.writeString(_keyLongestStreak, newStreak.toString());
        }

        // Reset consecutive freeze flag (user showed up today)
        await _freezeService.resetConsecutiveFlag();
      } else if (daysDiff == 2) {
        // Missed exactly 1 day — try streak freeze
        final freezeUsed = await _freezeService.tryUseFreeze();

        if (freezeUsed) {
          // Freeze saved the streak — increment as if consecutive
          final newStreak = currentStreak + 1;
          await _storage.writeString(_keyCurrentStreak, newStreak.toString());

          if (newStreak > longestStreak) {
            await _storage.writeString(
                _keyLongestStreak, newStreak.toString());
          }

          _lastStreakFreezeUsed = true;
          debugPrint(
              '🧊 Streak freeze saved streak! Now at $newStreak days');
        } else {
          // No freeze available — streak breaks
          _lastStreakWasLost = true;
          _lostStreakValue = currentStreak;
          await _storage.writeString(_keyCurrentStreak, '1');
          debugPrint(
              '💔 Streak lost ($currentStreak days) — no freeze available');
        }
      } else if (daysDiff > 2) {
        // Missed 2+ days — streak always breaks (can't chain freezes)
        _lastStreakWasLost = true;
        _lostStreakValue = currentStreak;
        await _storage.writeString(_keyCurrentStreak, '1');
        debugPrint(
            '💔 Streak lost ($currentStreak days) — missed $daysDiff days');
      }
    } else {
      // First unlock ever
      await _storage.writeString(_keyCurrentStreak, '1');
      await _storage.writeString(_keyLongestStreak, '1');
    }

    // Update last unlock date
    await _storage.writeString(_keyLastUnlockDate, now.toIso8601String());
  }

  /// Reset current streak to 0 (used when user abandons prayer session)
  /// Keeps longest streak intact as historical record
  Future<void> resetStreak() async {
    await _storage.writeString(_keyCurrentStreak, '0');
    // Note: We keep longest streak and last unlock date for historical purposes
  }

  // Get user stats
  Future<UserStats> getUserStats() async {
    final currentStreakStr = await _storage.readString(_keyCurrentStreak);
    final longestStreakStr = await _storage.readString(_keyLongestStreak);
    final currentStreak = currentStreakStr != null ? int.tryParse(currentStreakStr) ?? 0 : 0;
    final longestStreak = longestStreakStr != null ? int.tryParse(longestStreakStr) ?? 0 : 0;
    final lastUnlockStr = await _storage.readString(_keyLastUnlockDate);

    // Get all unlock history
    List<UnlockAttempt> unlockHistory = [];
    try {
      unlockHistory = await _db.getUnlockHistory(limit: 1000);
    } catch (e) {
      // Database might not be initialized yet
      unlockHistory = [];
    }

    // Calculate totals.
    // "Verses read" counts ONLY Bible verse quiz unlocks — prayer-based unlocks
    // (audio/text/learning) are surfaced through "prayed today" instead.
    // Legacy rows have no method (null) and default to Bible to preserve history.
    final totalVersesRead = unlockHistory
        .where((a) => a.wasSuccessful && (a.method?.isBible ?? true))
        .length;
    final successfulUnlocks = unlockHistory.where((a) => a.wasSuccessful).length;
    final failedAttempts = unlockHistory.where((a) => !a.wasSuccessful).length;

    // Real prayer time today, from prayer-based unlock flows only.
    final prayedMinutesToday = _calculatePrayedMinutesToday(unlockHistory);

    // Bible-quiz verses read today (the home "Today" card; total stays all-time).
    final versesReadToday = _calculateVersesReadToday(unlockHistory);

    // Get verses by category
    final versesByCategory = await _getVersesByCategory(unlockHistory);

    // Calculate average quiz score
    final averageScore = _calculateAverageQuizScore(unlockHistory);

    // Calculate screen time reduced (use actual unlock durations)
    final screenTimeReduced = _calculateScreenTimeReduced(unlockHistory);

    return UserStats(
      totalVersesRead: totalVersesRead,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      screenTimeReducedMinutes: screenTimeReduced,
      prayedMinutesToday: prayedMinutesToday,
      versesReadToday: versesReadToday,
      successfulUnlocks: successfulUnlocks,
      failedAttempts: failedAttempts,
      versesByCategory: versesByCategory,
      lastUnlockDate: lastUnlockStr != null ? DateTime.parse(lastUnlockStr) : DateTime.now(),
      averageQuizScore: averageScore,
    );
  }

  // Get verses by category from unlock history
  Future<Map<VerseCategory, int>> _getVersesByCategory(List<UnlockAttempt> history) async {
    final Map<VerseCategory, int> categoryCount = {};

    for (final attempt in history.where((a) => a.wasSuccessful)) {
      final verse = await _db.getVerseById(attempt.verseId);
      if (verse != null) {
        categoryCount[verse.category] = (categoryCount[verse.category] ?? 0) + 1;
      }
    }

    return categoryCount;
  }

  // Calculate average quiz score (returns value between 0.0 and 1.0)
  double _calculateAverageQuizScore(List<UnlockAttempt> history) {
    if (history.isEmpty) return 0.0;

    final totalAttempts = history.length;
    final successfulAttempts = history.where((a) => a.wasSuccessful).length;

    return successfulAttempts / totalAttempts;
  }

  // Calculate screen time reduced using actual unlock durations
  int _calculateScreenTimeReduced(List<UnlockAttempt> history) {
    int totalMinutes = 0;

    for (final attempt in history.where((a) => a.wasSuccessful)) {
      if (attempt.unlockDurationMinutes != null) {
        // Use actual duration selected by user
        totalMinutes += attempt.unlockDurationMinutes!;
      } else {
        // Fallback to 5 minutes for old records without duration
        totalMinutes += 5;
      }
    }

    return totalMinutes;
  }

  // Calculate today's prayer time (minutes) from prayer-based unlock flows.
  // Uses the time spent in the prayer flow (audio/text/learning) before
  // unlocking. Bible quiz unlocks are excluded — they feed "verses read".
  int _calculatePrayedMinutesToday(List<UnlockAttempt> history) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    int totalSeconds = 0;
    for (final attempt in history) {
      if (!attempt.wasSuccessful) continue;
      if (!(attempt.method?.isPrayer ?? false)) continue;
      if (attempt.timestamp.isBefore(startOfDay)) continue;
      totalSeconds += attempt.timeToUnlockSeconds ?? 0;
    }

    return (totalSeconds / 60).round();
  }

  // Count today's Bible-quiz verses read. Mirrors the "today" window used for
  // prayed minutes so the home card's two stats are both day-scoped.
  int _calculateVersesReadToday(List<UnlockAttempt> history) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    int count = 0;
    for (final attempt in history) {
      if (!attempt.wasSuccessful) continue;
      if (!(attempt.method?.isBible ?? true)) continue;
      if (attempt.timestamp.isBefore(startOfDay)) continue;
      count++;
    }

    return count;
  }

  // Get weekly progress
  Future<List<DailyStats>> getWeeklyProgress() async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));

    return await _db.getStatsRange(weekStart, weekEnd);
  }

  // Get monthly progress
  Future<List<DailyStats>> getMonthlyProgress() async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);

    return await _db.getStatsRange(monthStart, monthEnd);
  }

  // Calculate current streak manually (check for consecutive days)
  Future<int> calculateStreak() async {
    List<UnlockAttempt> unlockHistory = [];
    try {
      unlockHistory = await _db.getUnlockHistory(limit: 365);
    } catch (e) {
      // Database might not be initialized yet
      return 0;
    }

    if (unlockHistory.isEmpty) return 0;

    int streak = 0;
    DateTime? lastDate;

    for (final attempt in unlockHistory.where((a) => a.wasSuccessful)) {
      final attemptDate = DateTime(
        attempt.timestamp.year,
        attempt.timestamp.month,
        attempt.timestamp.day,
      );

      if (lastDate == null) {
        // First successful unlock
        final today = DateTime.now();
        final todayDate = DateTime(today.year, today.month, today.day);

        // Check if it's today or yesterday
        final daysDiff = todayDate.difference(attemptDate).inDays;

        if (daysDiff <= 1) {
          streak = 1;
          lastDate = attemptDate;
        } else {
          break; // Too old, no current streak
        }
      } else {
        // Check if consecutive
        final daysDiff = lastDate.difference(attemptDate).inDays;

        if (daysDiff == 1) {
          streak++;
          lastDate = attemptDate;
        } else if (daysDiff == 0) {
          // Same day, don't increment
          continue;
        } else {
          // Streak broken
          break;
        }
      }
    }

    return streak;
  }

  // Get today's unlock attempts
  Future<List<UnlockAttempt>> getTodayUnlocks() async {
    try {
      return await _db.getTodayUnlocks();
    } catch (e) {
      // Database might not be initialized yet, return empty list
      return [];
    }
  }

  // Reset all stats (for testing or user request)
  Future<void> resetAllStats() async {
    await _storage.deleteData(_keyCurrentStreak);
    await _storage.deleteData(_keyLongestStreak);
    await _storage.deleteData(_keyLastUnlockDate);
  }
}
