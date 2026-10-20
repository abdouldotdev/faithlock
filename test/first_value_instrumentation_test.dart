import 'package:faithlock/services/analytics/posthog/first_value_instrumentation.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryStore implements FirstValueStore {
  final Map<String, String> values = {};

  @override
  String? read(String key) => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}

void main() {
  test('emits first focus start exactly once with minimal properties', () async {
    final events = <TrackedEvent>[];
    final instrumentation = FirstValueInstrumentation(
      store: _MemoryStore(),
      isReady: () => true,
      emit: events.add,
    );

    await instrumentation.recordFocusStarted(
      at: DateTime.utc(2026, 10, 19, 10),
    );
    await instrumentation.recordFocusStarted(
      at: DateTime.utc(2026, 10, 19, 10, 1),
    );

    expect(events, hasLength(1));
    expect(events.single.name, 'first_focus_started');
    expect(events.single.properties, {
      'schema_version': 1,
      'focus_kind': 'prayer',
    });
  });

  test('emits first completion once and sequences a second completion', () async {
    final events = <TrackedEvent>[];
    final instrumentation = FirstValueInstrumentation(
      store: _MemoryStore(),
      isReady: () => true,
      emit: events.add,
    );
    final first = DateTime.utc(2026, 10, 19, 10);

    await instrumentation.recordFocusStarted(at: first);
    await instrumentation.recordFocusCompleted(at: first.add(const Duration(minutes: 5)));
    await instrumentation.recordFocusCompleted(at: first.add(const Duration(days: 2)));
    await instrumentation.recordFocusCompleted(at: first.add(const Duration(days: 8)));

    expect(events.map((event) => event.name), [
      'first_focus_started',
      'first_focus_completed',
      'focus_completed',
      'focus_completed',
    ]);
    expect(events[1].properties, {
      'schema_version': 1,
      'focus_kind': 'prayer',
      'completion_number': 1,
    });
    expect(events[2].properties, {
      'schema_version': 1,
      'focus_kind': 'prayer',
      'completion_number': 2,
      'first_completion_at': '2026-10-19T10:05:00.000Z',
    });
    expect(events[3].properties, {
      'schema_version': 1,
      'focus_kind': 'prayer',
      'completion_number': 3,
      'first_completion_at': '2026-10-19T10:05:00.000Z',
    });
  });

  test('retries pending milestones when provider becomes ready exactly once', () async {
    final store = _MemoryStore();
    final events = <TrackedEvent>[];
    var isReady = false;
    final instrumentation = FirstValueInstrumentation(
      store: store,
      isReady: () => isReady,
      emit: events.add,
    );
    final first = DateTime.utc(2026, 10, 19, 10);

    await instrumentation.recordFocusStarted(at: first);
    await instrumentation.recordFocusCompleted(
      at: first.add(const Duration(minutes: 5)),
    );
    expect(events, isEmpty);

    isReady = true;
    await instrumentation.recordFocusCompleted(
      at: first.add(const Duration(minutes: 5)),
    );
    await instrumentation.recordFocusStarted(at: first);
    await instrumentation.recordFocusCompleted(
      at: first.add(const Duration(minutes: 6)),
    );

    expect(events.map((event) => event.name), [
      'first_focus_started',
      'first_focus_completed',
    ]);
  });

  test('does not emit a completion twice after recreation with persisted state', () async {
    final store = _MemoryStore();
    final events = <TrackedEvent>[];
    final first = DateTime.utc(2026, 10, 19, 10);

    await FirstValueInstrumentation(
      store: store,
      isReady: () => true,
      emit: events.add,
    )
        .recordFocusStarted(at: first);
    await FirstValueInstrumentation(
      store: store,
      isReady: () => true,
      emit: events.add,
    )
        .recordFocusCompleted(at: first.add(const Duration(minutes: 5)));
    await FirstValueInstrumentation(
      store: store,
      isReady: () => true,
      emit: events.add,
    )
        .recordFocusCompleted(at: first.add(const Duration(minutes: 5)));

    expect(events.map((event) => event.name), [
      'first_focus_started',
      'first_focus_completed',
      'focus_completed',
    ]);
    expect(events.last.properties['completion_number'], 2);
  });
}
