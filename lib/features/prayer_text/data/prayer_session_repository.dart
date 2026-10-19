import 'package:faithlock/features/prayer_text/models/prayer_text_models.dart';
import 'package:faithlock/services/storage/preferences_service.dart';

/// Local persistence for completed textual prayer sessions.
///
/// We keep the last [_maxSessions] entries (LIFO) so the profile screen can
/// render an "improved 10/12 times this month" stat without unbounded
/// growth. Sensitive auth tokens stay in secure storage — these are mood
/// reflections and live in plain shared_preferences.
class PrayerSessionRepository {
  PrayerSessionRepository({PreferencesService? prefs})
      : _prefs = prefs ?? PreferencesService();

  static const String _storageKey = 'prayer_text_sessions_v1';

  /// Cap so the JSON blob never grows beyond a few KB on long-time users.
  static const int _maxSessions = 200;

  final PreferencesService _prefs;

  /// Newest first.
  Future<List<PrayerSession>> all() async {
    final raw = await _prefs.readList(_storageKey);
    if (raw == null) return <PrayerSession>[];
    return raw
        .where((e) => e is Map)
        .map((e) => PrayerSession.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Prepends [session] and trims to [_maxSessions].
  Future<void> add(PrayerSession session) async {
    final existing = await all();
    existing.insert(0, session);
    if (existing.length > _maxSessions) {
      existing.removeRange(_maxSessions, existing.length);
    }
    await _prefs.writeList(
      _storageKey,
      existing.map((s) => s.toMap()).toList(),
    );
  }

  /// Aggregate counts for the rétention loop ("improved 10/12 times").
  /// Returns zeros when no sessions exist yet.
  Future<PrayerSessionStats> stats() async {
    final sessions = await all();
    if (sessions.isEmpty) {
      return const PrayerSessionStats(total: 0, improved: 0, avgDelta: 0);
    }
    final improved = sessions.where((s) => s.improved).length;
    final avgDelta = sessions.fold<int>(0, (sum, s) => sum + s.moodDelta) /
        sessions.length;
    return PrayerSessionStats(
      total: sessions.length,
      improved: improved,
      avgDelta: avgDelta,
    );
  }
}

/// Lightweight aggregate; expand later (this week / month buckets) once we
/// know how the profile page consumes it.
class PrayerSessionStats {
  const PrayerSessionStats({
    required this.total,
    required this.improved,
    required this.avgDelta,
  });

  final int total;
  final int improved;
  final double avgDelta;

  double get improvedRatio => total == 0 ? 0 : improved / total;
}
