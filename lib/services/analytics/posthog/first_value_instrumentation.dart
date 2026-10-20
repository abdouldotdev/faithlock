import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

/// Minimal event payload used by the first-value contract.
class TrackedEvent {
  const TrackedEvent(this.name, this.properties);

  final String name;
  final Map<String, Object> properties;
}

/// Storage needed to keep first-value milestones idempotent across launches.
abstract interface class FirstValueStore {
  String? read(String key);
  Future<void> write(String key, String value);
}

typedef FirstValueEventEmitter = FutureOr<void> Function(TrackedEvent event);

/// SharedPreferences-backed storage for the app integration.
class SharedPreferencesFirstValueStore implements FirstValueStore {
  SharedPreferencesFirstValueStore(this._preferences);

  final SharedPreferences _preferences;

  @override
  String? read(String key) => _preferences.getString(key);

  @override
  Future<void> write(String key, String value) async {
    await _preferences.setString(key, value);
  }
}

/// Emits first-value milestones without collecting prayer or spiritual content.
///
/// Contract:
/// - `first_focus_started` is emitted once per installation/user storage scope.
/// - `first_focus_completed` is emitted once, with completion number 1.
/// - Later completions emit `focus_completed` with a sequence number and the
///   first completion timestamp, allowing a 7-day PostHog query.
/// - Milestones are persisted as pending before delivery and retried when
///   [isReady] becomes true; pending state is cleared only after emission.
/// - Event properties are limited to schema version, focus kind, sequence, and
///   the first completion timestamp. No prayer text, verse, mood, or score is
///   accepted by this class.
class FirstValueInstrumentation {
  FirstValueInstrumentation({
    required FirstValueStore store,
    required bool Function() isReady,
    required FirstValueEventEmitter emit,
  })  : _store = store,
        _isReady = isReady,
        _emit = emit;

  static const _startedKey = 'faithlock_first_value_started';
  static const _completionCountKey = 'faithlock_focus_completion_count';
  static const _firstCompletionAtKey = 'faithlock_first_value_completed_at';
  static const _pendingStartedKey = 'faithlock_first_value_pending_started';
  static const _pendingCompletionAtKey =
      'faithlock_first_value_pending_completion_at';

  final FirstValueStore _store;
  final bool Function() _isReady;
  final FirstValueEventEmitter _emit;

  Future<void> recordFocusStarted({required DateTime at}) async {
    if (_store.read(_startedKey) == '1') {
      await flushPending();
      return;
    }

    await _store.write(_pendingStartedKey, '1');
    await flushPending();
  }

  Future<void> recordFocusCompleted({required DateTime at}) async {
    final count = int.tryParse(_store.read(_completionCountKey) ?? '') ?? 0;

    if (count == 0) {
      final pendingCompletionAt = _store.read(_pendingCompletionAtKey);
      if (pendingCompletionAt == null || pendingCompletionAt.isEmpty) {
        await _store.write(
          _pendingCompletionAtKey,
          at.toUtc().toIso8601String(),
        );
      }
      await flushPending();
      return;
    }

    final firstCompletionAt = _store.read(_firstCompletionAtKey);
    if (firstCompletionAt == null) return;

    if (!_isReady()) return;
    final nextCount = count + 1;
    await _emit(TrackedEvent(
      'focus_completed',
      {
        'schema_version': 1,
        'focus_kind': 'prayer',
        'completion_number': nextCount,
        'first_completion_at': firstCompletionAt,
      },
    ));
    await _store.write(_completionCountKey, '$nextCount');
  }

  /// Delivers locally persisted milestones once the provider is available.
  /// Pending state is only cleared after the emitter returns successfully.
  Future<void> flushPending() async {
    if (!_isReady()) return;

    if (_store.read(_pendingStartedKey) == '1') {
      await _emit(const TrackedEvent(
        'first_focus_started',
        {
          'schema_version': 1,
          'focus_kind': 'prayer',
        },
      ));
      await _store.write(_startedKey, '1');
      await _store.write(_pendingStartedKey, '');
    }

    final pendingCompletionAt = _store.read(_pendingCompletionAtKey);
    if (pendingCompletionAt == null || pendingCompletionAt.isEmpty) return;

    await _emit(const TrackedEvent(
      'first_focus_completed',
      {
        'schema_version': 1,
        'focus_kind': 'prayer',
        'completion_number': 1,
      },
    ));
    await _store.write(_firstCompletionAtKey, pendingCompletionAt);
    await _store.write(_completionCountKey, '1');
    await _store.write(_pendingCompletionAtKey, '');
  }
}
