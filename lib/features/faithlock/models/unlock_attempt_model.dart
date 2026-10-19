import 'package:faithlock/features/faithlock/models/bible_verse_model.dart';

/// How an unlock was earned. Drives which home stat the attempt feeds:
/// [bibleQuiz] counts toward "Verses Read", the prayer methods count toward
/// "Prayed Today".
enum UnlockMethod {
  bibleQuiz('bible_quiz'),
  prayerAudio('prayer_audio'),
  prayerText('prayer_text'),
  prayerLearning('prayer_learning');

  const UnlockMethod(this.value);

  final String value;

  /// Parse a stored value. Legacy rows without a method default to [bibleQuiz]
  /// to preserve the original "verses read" semantics.
  static UnlockMethod? fromValue(String? value) {
    if (value == null) return null;
    return UnlockMethod.values.firstWhere(
      (m) => m.value == value,
      orElse: () => UnlockMethod.bibleQuiz,
    );
  }

  /// True for prayer-based unlocks (audio, text, learning session).
  bool get isPrayer =>
      this == prayerAudio || this == prayerText || this == prayerLearning;

  /// True for Bible verse quiz unlocks.
  bool get isBible => this == bibleQuiz;
}

class UnlockAttempt {
  final int? id;
  final String verseId;
  final DateTime timestamp;
  final bool wasSuccessful;
  final int attemptCount;
  final int? timeToUnlockSeconds;
  final int? unlockDurationMinutes; // Duration user selected to unlock apps
  final UnlockMethod? method; // How the unlock was earned (quiz vs prayer)
  final BibleVerse? verse; // Optional, for joins

  const UnlockAttempt({
    this.id,
    required this.verseId,
    required this.timestamp,
    required this.wasSuccessful,
    required this.attemptCount,
    this.timeToUnlockSeconds,
    this.unlockDurationMinutes,
    this.method,
    this.verse,
  });

  factory UnlockAttempt.fromJson(Map<String, dynamic> json) {
    return UnlockAttempt(
      id: json['id'] as int?,
      verseId: json['verse_id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      wasSuccessful: json['was_successful'] == 1,
      attemptCount: json['attempt_count'] as int,
      timeToUnlockSeconds: json['time_to_unlock'] as int?,
      unlockDurationMinutes: json['unlock_duration_minutes'] as int?,
      method: UnlockMethod.fromValue(json['unlock_method'] as String?),
      verse: json['verse'] != null
          ? BibleVerse.fromJson(json['verse'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'verse_id': verseId,
      'timestamp': timestamp.toIso8601String(),
      'was_successful': wasSuccessful ? 1 : 0,
      'attempt_count': attemptCount,
      if (timeToUnlockSeconds != null) 'time_to_unlock': timeToUnlockSeconds,
      if (unlockDurationMinutes != null) 'unlock_duration_minutes': unlockDurationMinutes,
      if (method != null) 'unlock_method': method!.value,
    };
  }

  UnlockAttempt copyWith({
    int? id,
    String? verseId,
    DateTime? timestamp,
    bool? wasSuccessful,
    int? attemptCount,
    int? timeToUnlockSeconds,
    int? unlockDurationMinutes,
    UnlockMethod? method,
    BibleVerse? verse,
  }) {
    return UnlockAttempt(
      id: id ?? this.id,
      verseId: verseId ?? this.verseId,
      timestamp: timestamp ?? this.timestamp,
      wasSuccessful: wasSuccessful ?? this.wasSuccessful,
      attemptCount: attemptCount ?? this.attemptCount,
      timeToUnlockSeconds: timeToUnlockSeconds ?? this.timeToUnlockSeconds,
      unlockDurationMinutes: unlockDurationMinutes ?? this.unlockDurationMinutes,
      method: method ?? this.method,
      verse: verse ?? this.verse,
    );
  }

  Duration? get timeToUnlock {
    if (timeToUnlockSeconds == null) return null;
    return Duration(seconds: timeToUnlockSeconds!);
  }

  String? get formattedTimeToUnlock {
    if (timeToUnlockSeconds == null) return null;
    if (timeToUnlockSeconds! < 60) {
      return '$timeToUnlockSeconds seconds';
    }
    final minutes = timeToUnlockSeconds! ~/ 60;
    final seconds = timeToUnlockSeconds! % 60;
    return '${minutes}m ${seconds}s';
  }

  @override
  String toString() {
    return 'UnlockAttempt(id: $id, success: $wasSuccessful, attempts: $attemptCount)';
  }
}
