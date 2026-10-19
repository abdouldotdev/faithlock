import 'package:faithlock/features/faithlock/models/bible_verse_model.dart';

class UserStats {
  final int totalVersesRead;
  final int currentStreak;
  final int longestStreak;
  final int screenTimeReducedMinutes;
  final int prayedMinutesToday; // Real prayer time today (audio/text/learning)
  final int versesReadToday; // Bible-quiz verses read today
  final int successfulUnlocks;
  final int failedAttempts;
  final Map<VerseCategory, int> versesByCategory;
  final DateTime lastUnlockDate;
  final double averageQuizScore;

  const UserStats({
    required this.totalVersesRead,
    required this.currentStreak,
    required this.longestStreak,
    required this.screenTimeReducedMinutes,
    this.prayedMinutesToday = 0,
    this.versesReadToday = 0,
    required this.successfulUnlocks,
    required this.failedAttempts,
    required this.versesByCategory,
    required this.lastUnlockDate,
    required this.averageQuizScore,
  });

  factory UserStats.empty() {
    return UserStats(
      totalVersesRead: 0,
      currentStreak: 0,
      longestStreak: 0,
      screenTimeReducedMinutes: 0,
      prayedMinutesToday: 0,
      versesReadToday: 0,
      successfulUnlocks: 0,
      failedAttempts: 0,
      versesByCategory: {},
      lastUnlockDate: DateTime.now(),
      averageQuizScore: 0.0,
    );
  }

  factory UserStats.fromJson(Map<String, dynamic> json) {
    final categoriesJson =
        json['verses_by_category'] as Map<String, dynamic>? ?? {};
    final versesByCategory = <VerseCategory, int>{};

    categoriesJson.forEach((key, value) {
      final category = VerseCategoryExtension.fromString(key);
      versesByCategory[category] = value as int;
    });

    return UserStats(
      totalVersesRead: json['total_verses_read'] as int? ?? 0,
      currentStreak: json['current_streak'] as int? ?? 0,
      longestStreak: json['longest_streak'] as int? ?? 0,
      screenTimeReducedMinutes:
          json['screen_time_reduced_minutes'] as int? ?? 0,
      prayedMinutesToday: json['prayed_minutes_today'] as int? ?? 0,
      versesReadToday: json['verses_read_today'] as int? ?? 0,
      successfulUnlocks: json['successful_unlocks'] as int? ?? 0,
      failedAttempts: json['failed_attempts'] as int? ?? 0,
      versesByCategory: versesByCategory,
      lastUnlockDate: json['last_unlock_date'] != null
          ? DateTime.parse(json['last_unlock_date'] as String)
          : DateTime.now(),
      averageQuizScore: (json['average_quiz_score'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    final categoriesJson = <String, int>{};
    versesByCategory.forEach((category, count) {
      categoriesJson[category.value] = count;
    });

    return {
      'total_verses_read': totalVersesRead,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'screen_time_reduced_minutes': screenTimeReducedMinutes,
      'prayed_minutes_today': prayedMinutesToday,
      'verses_read_today': versesReadToday,
      'successful_unlocks': successfulUnlocks,
      'failed_attempts': failedAttempts,
      'verses_by_category': categoriesJson,
      'last_unlock_date': lastUnlockDate.toIso8601String(),
      'average_quiz_score': averageQuizScore,
    };
  }

  UserStats copyWith({
    int? totalVersesRead,
    int? currentStreak,
    int? longestStreak,
    int? screenTimeReducedMinutes,
    int? prayedMinutesToday,
    int? versesReadToday,
    int? successfulUnlocks,
    int? failedAttempts,
    Map<VerseCategory, int>? versesByCategory,
    DateTime? lastUnlockDate,
    double? averageQuizScore,
  }) {
    return UserStats(
      totalVersesRead: totalVersesRead ?? this.totalVersesRead,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      screenTimeReducedMinutes:
          screenTimeReducedMinutes ?? this.screenTimeReducedMinutes,
      prayedMinutesToday: prayedMinutesToday ?? this.prayedMinutesToday,
      versesReadToday: versesReadToday ?? this.versesReadToday,
      successfulUnlocks: successfulUnlocks ?? this.successfulUnlocks,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      versesByCategory: versesByCategory ?? this.versesByCategory,
      lastUnlockDate: lastUnlockDate ?? this.lastUnlockDate,
      averageQuizScore: averageQuizScore ?? this.averageQuizScore,
    );
  }

  // Helper getters
  Duration get screenTimeReduced => Duration(minutes: screenTimeReducedMinutes);

  String get screenTimeReducedFormatted {
    if (screenTimeReducedMinutes < 60) {
      return '$screenTimeReducedMinutes min';
    }

    final hours = screenTimeReducedMinutes ~/ 60;
    if (hours < 24) {
      return '$hours h';
    }

    final days = hours ~/ 24;
    if (days < 30) {
      return '$days days';
    }

    final months = days ~/ 30;
    return '$months months';
  }

  /// Today's prayer time, formatted for the "Prayed Today" stat card.
  String get prayedTodayFormatted {
    if (prayedMinutesToday < 60) {
      return '$prayedMinutesToday min';
    }
    final hours = prayedMinutesToday ~/ 60;
    final minutes = prayedMinutesToday % 60;
    return minutes == 0 ? '$hours h' : '${hours}h ${minutes}m';
  }

  double get successRate {
    final total = successfulUnlocks + failedAttempts;
    if (total == 0) return 0.0;
    return (successfulUnlocks / total) * 100;
  }

  String get successRateFormatted => '${successRate.toStringAsFixed(1)}%';

  int get totalAttempts => successfulUnlocks + failedAttempts;

  VerseCategory? get favoriteCategory {
    if (versesByCategory.isEmpty) return null;
    return versesByCategory.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  bool get hasStreakToday {
    final today = DateTime.now();
    return lastUnlockDate.year == today.year &&
        lastUnlockDate.month == today.month &&
        lastUnlockDate.day == today.day;
  }

  @override
  String toString() {
    return 'UserStats(verses: $totalVersesRead, streak: $currentStreak, success: $successRateFormatted)';
  }
}

class DailyStats {
  final DateTime date;
  final int versesRead;
  final int successfulUnlocks;
  final int failedAttempts;
  final int screenTimeMinutes;

  const DailyStats({
    required this.date,
    required this.versesRead,
    required this.successfulUnlocks,
    required this.failedAttempts,
    required this.screenTimeMinutes,
  });

  factory DailyStats.fromJson(Map<String, dynamic> json) {
    return DailyStats(
      date: DateTime.parse(json['date'] as String),
      versesRead: json['verses_read'] as int,
      successfulUnlocks: json['successful_unlocks'] as int,
      failedAttempts: json['failed_attempts'] as int,
      screenTimeMinutes: json['screen_time_minutes'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String().split('T')[0],
      'verses_read': versesRead,
      'successful_unlocks': successfulUnlocks,
      'failed_attempts': failedAttempts,
      'screen_time_minutes': screenTimeMinutes,
    };
  }

  factory DailyStats.empty(DateTime date) {
    return DailyStats(
      date: date,
      versesRead: 0,
      successfulUnlocks: 0,
      failedAttempts: 0,
      screenTimeMinutes: 0,
    );
  }

  double get successRate {
    final total = successfulUnlocks + failedAttempts;
    if (total == 0) return 0.0;
    return (successfulUnlocks / total) * 100;
  }
}
