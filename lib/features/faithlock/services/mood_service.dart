import 'package:faithlock/services/storage/preferences_service.dart';
import 'package:faithlock/shared/widgets/cozy/cozy_mood_slider.dart';

/// Persists the most recent mood check-in (last [MoodLevel] + ISO timestamp).
///
/// Kept intentionally small — just the latest reading — so the prayer flow can
/// recommend content right after a check-in, and a future iteration can build
/// a trend view on top without a schema change.
class MoodService {
  MoodService({PreferencesService? prefs})
      : _prefs = prefs ?? PreferencesService();

  final PreferencesService _prefs;

  static const String _key = 'last_mood_check_in';

  /// Saves [mood] as the most recent reading, stamped with the current time.
  Future<void> saveMood(MoodLevel mood) async {
    await _prefs.writeMap(_key, {
      'mood': mood.name,
      'at': DateTime.now().toIso8601String(),
    });
  }

  /// Returns the last saved mood, or null if none / unrecognized.
  Future<MoodLevel?> lastMood() async {
    final map = await _prefs.readMap(_key);
    final name = map?['mood'] as String?;
    if (name == null) return null;
    for (final m in MoodLevel.values) {
      if (m.name == name) return m;
    }
    return null;
  }

  static const String _curatedKey = 'last_curated_prayer_id';

  /// Remembers the last suggested prayer id so the next recommendation can
  /// avoid repeating it.
  Future<void> saveLastCuratedId(String id) =>
      _prefs.writeString(_curatedKey, id);

  Future<String?> lastCuratedId() => _prefs.readString(_curatedKey);
}
