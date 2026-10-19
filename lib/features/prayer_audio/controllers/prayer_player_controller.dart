import 'dart:async';

import 'package:faithlock/config/logger.dart';
import 'package:faithlock/features/prayer_audio/models/prayer.dart';
import 'package:faithlock/services/analytics/posthog/export.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// One renderable unit of a prayer script: a spoken line or a `(pause)` beat.
class PrayerSegment {
  const PrayerSegment({
    required this.text,
    required this.isPause,
    required this.estMs,
  });

  /// Spoken text (empty for a pause).
  final String text;

  /// Whether this is a silent `(pause)` beat.
  final bool isPause;

  /// Estimated duration (ms) — used by the TTS fallback timeline and as a
  /// safety net when no word timings are available.
  final int estMs;
}

/// Drives the guided-prayer reading.
///
/// The controller has two playback engines and picks one at [load] time:
///
///   1. **Audio mode** (preferred) — uses [just_audio] to play a pre-recorded
///      ElevenLabs MP3 from Supabase storage, and drives the karaoke highlight
///      from forced-alignment word timestamps produced by Replicate
///      (`cureau/force-align-wordstamps`, stored on the prayer as
///      [Prayer.wordTimings]). Sync is exact.
///
///   2. **TTS fallback** — when no MP3 or no word timings are available, the
///      old on-device [flutter_tts] loop runs, with an estimated timeline.
///
/// Both engines write into the same reactive surface (`activeIndex`,
/// `wordStart`, `wordEnd`, `elapsed`, `isPlaying`, …) so the UI is engine-
/// agnostic.
class PrayerPlayerController extends GetxController {
  // ── Reactive surface (UI binds to these) ──────────────────────────────────

  final RxList<PrayerSegment> segments = <PrayerSegment>[].obs;
  final RxInt activeIndex = 0.obs;

  /// Character offsets of the word currently being spoken, within the active
  /// segment's text. `wordStart == wordEnd` means "no active word yet".
  final RxInt wordStart = 0.obs;
  final RxInt wordEnd = 0.obs;

  final RxBool isPlaying = false.obs;
  final RxBool isPreparing = true.obs;
  final RxBool isFinished = false.obs;

  /// True when no script could be played (empty content or every engine failed).
  final RxBool isUnavailable = false.obs;

  final Rx<Duration> elapsed = Duration.zero.obs;
  final Rx<Duration> total = Duration.zero.obs;

  // ── Engines ────────────────────────────────────────────────────────────────
  _Engine? _engine;

  // ── Analytics ──────────────────────────────────────────────────────────────
  final PostHogService _analytics = PostHogService.instance;

  void _track(String event, Map<String, dynamic> props) {
    if (_analytics.isReady) _analytics.events.trackCustom(event, props);
  }

  /// The prayer being played + where this player was opened from (`'home'` |
  /// `'unlock'`), set by [load] so completion / control events can reference
  /// them.
  Prayer? _prayer;
  String _source = 'home';
  DateTime? _startedAt;

  /// Set once playback completes — lets the screen's dispose distinguish a
  /// finished prayer from an abandoned one.
  bool completed = false;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void onClose() {
    _engine?.dispose();
    super.onClose();
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Parse [prayer]'s script, pick an engine, and start playback.
  ///
  /// [source] records where the player was opened from (`'home'` for the audio
  /// library, `'unlock'` when praying to earn back an app) for analytics.
  Future<void> load(Prayer prayer, {String source = 'home'}) async {
    isPreparing.value = true;
    isUnavailable.value = false;
    isFinished.value = false;
    activeIndex.value = 0;
    elapsed.value = Duration.zero;

    _prayer = prayer;
    _source = source;
    _startedAt = DateTime.now();
    completed = false;
    _track('prayer_started', {
      'prayer_id': prayer.id,
      'mode': 'audio',
      'source': source,
    });

    final script = _scriptFor(prayer);
    final parsed = _parse(script);
    if (parsed.isEmpty) {
      isUnavailable.value = true;
      isPreparing.value = false;
      _track('prayer_audio_unavailable', {
        'prayer_id': prayer.id,
        'fallback': 'tts',
      });
      return;
    }
    segments.assignAll(parsed);

    // Tear down any previous engine before swapping.
    await _engine?.dispose();
    _engine = await _pickEngine(prayer);

    isPreparing.value = false;
    if (_engine == null) {
      isUnavailable.value = true;
      _track('prayer_audio_unavailable', {
        'prayer_id': prayer.id,
        'fallback': 'tts',
      });
      return;
    }
    await play();
  }

  /// Toggle play / pause.
  Future<void> playPause() => isPlaying.value ? pause() : play();

  Future<void> play() async {
    if (isUnavailable.value || _engine == null || segments.isEmpty) return;
    if (isFinished.value) {
      activeIndex.value = 0;
      elapsed.value = Duration.zero;
      isFinished.value = false;
      await _engine!.seek(Duration.zero);
    }
    await _engine!.play();
  }

  Future<void> pause() {
    return _engine?.pause() ?? Future.value();
  }

  Future<void> seek(Duration target) => _seek(target);

  Future<void> _seek(Duration target) async {
    if (_engine == null) return;
    final clamped = target.isNegative ? Duration.zero : target;
    final capped = clamped > total.value ? total.value : clamped;
    isFinished.value = false;
    await _engine!.seek(capped);
  }

  Future<void> skipBack() {
    return _seek(elapsed.value - const Duration(seconds: 15));
  }

  Future<void> skipForward() {
    return _seek(elapsed.value + const Duration(seconds: 15));
  }

  /// Jump straight to the start of segment [index] (tapping a line).
  Future<void> jumpToSegment(int index) {
    if (segments.isEmpty || _engine == null) return Future.value();
    final clamped = index.clamp(0, segments.length - 1).toInt();
    return _seek(_engine!.startOfSegment(clamped));
  }

  /// Seconds spent in this prayer session so far (since [load]).
  int get sessionSeconds =>
      _startedAt != null ? DateTime.now().difference(_startedAt!).inSeconds : 0;

  /// Fire [prayer_completed] once playback reaches the end. Idempotent.
  void markCompleted() {
    if (completed) return;
    completed = true;
    final id = _prayer?.id;
    if (id == null) return;
    _track('prayer_completed', {
      'prayer_id': id,
      'mode': 'audio',
      'source': _source,
      'time_spent_seconds': _startedAt != null
          ? DateTime.now().difference(_startedAt!).inSeconds
          : 0,
    });
  }

  /// Fire [prayer_abandoned] when the player closes before completing. Called
  /// from the screen's dispose; no-op if the prayer was completed.
  void trackAbandonedIfNeeded() {
    if (completed) return;
    final id = _prayer?.id;
    if (id == null) return;
    final totMs = total.value.inMilliseconds;
    final pct = totMs > 0
        ? ((elapsed.value.inMilliseconds / totMs) * 100).clamp(0, 100).round()
        : null;
    _track('prayer_abandoned', {
      'prayer_id': id,
      'mode': 'audio',
      'source': _source,
      'progress_pct': pct,
    });
  }

  /// Playback progress in [0, 1].
  double get progress {
    final totMs = total.value.inMilliseconds;
    if (totMs <= 0) return 0;
    return (elapsed.value.inMilliseconds / totMs).clamp(0.0, 1.0);
  }

  // ── Engine selection ───────────────────────────────────────────────────────

  Future<_Engine?> _pickEngine(Prayer prayer) async {
    // Audio mode requires BOTH an MP3 path AND forced-alignment timings;
    // anything less degrades into the TTS fallback (estimated sync) so the
    // experience never breaks.
    final hasAudio = (prayer.audioPath?.isNotEmpty ?? false);
    final hasTimings = (prayer.wordTimings?.isNotEmpty ?? false);
    if (hasAudio && hasTimings) {
      try {
        final engine = _AudioEngine(controller: this, prayer: prayer);
        await engine.prepare();
        return engine;
      } catch (e) {
        logger
            .warning('[PrayerPlayerController] Audio engine failed → TTS: $e');
      }
    }
    try {
      final engine = _TtsEngine(controller: this, prayer: prayer);
      await engine.prepare();
      return engine;
    } catch (e) {
      logger.warning('[PrayerPlayerController] TTS engine failed: $e');
      return null;
    }
  }

  // ── Script parsing ────────────────────────────────────────────────────────

  String _scriptFor(Prayer prayer) {
    final script = (prayer.scriptText ?? '').trim();
    if (script.isNotEmpty) return script;
    return (prayer.scriptureText ?? '').trim();
  }

  static const int _msPerWord = 420; // ≈ 2.4 calm words/second
  static const int _minLineMs = 700;
  static const int _pauseMs = 1800; // mirrors the pipeline's <break time="2s">

  static int _estMsFor(String line) {
    final words = line.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    return (words.length * _msPerWord).clamp(_minLineMs, 1 << 30).toInt();
  }

  static List<PrayerSegment> _parse(String script) {
    final out = <PrayerSegment>[];
    final chunks = script.split('(pause)');
    for (var c = 0; c < chunks.length; c++) {
      final chunk = chunks[c].replaceAll(RegExp(r'\s+'), ' ').trim();
      if (chunk.isNotEmpty) {
        // One readable line per sentence — the scripts are written for the ear.
        for (final s in chunk.split(RegExp(r'(?<=[.!?…])\s+'))) {
          final t = s.trim();
          if (t.isNotEmpty) {
            out.add(
                PrayerSegment(text: t, isPause: false, estMs: _estMsFor(t)));
          }
        }
      }
      if (c < chunks.length - 1) {
        out.add(const PrayerSegment(text: '', isPause: true, estMs: _pauseMs));
      }
    }
    return out;
  }
}

// ─── Engine interface ────────────────────────────────────────────────────────

abstract class _Engine {
  Future<void> prepare();
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration target);
  Future<void> dispose();

  /// Returns the timeline position where [segmentIndex] begins.
  Duration startOfSegment(int segmentIndex);
}

// ─── Audio engine (just_audio + Replicate word timings) ──────────────────────

class _AudioEngine implements _Engine {
  _AudioEngine({required this.controller, required this.prayer});

  final PrayerPlayerController controller;
  final Prayer prayer;

  final AudioPlayer _player = AudioPlayer();

  /// `wordTimings` indices, ordered by start time (already sorted by Replicate,
  /// but we re-sort defensively in [prepare]).
  late final List<WordTiming> _timings;

  /// For each [_timings] entry, the segment it belongs to + the char range
  /// inside that segment's text — populated by [_buildWordIndex].
  /// `_segOf[i] == -1` means the timing couldn't be mapped (skipped at playback).
  late final List<int> _segOf;
  late final List<int> _charStart;
  late final List<int> _charEnd;

  /// Start ms of each segment on the audio timeline — used by [startOfSegment]
  /// (tap a line → seek there). Derived from the first word that maps to
  /// each segment; pause segments inherit the previous spoken segment's end.
  late final List<int> _segStartMs;

  StreamSubscription<Duration>? _posSub;
  StreamSubscription<PlayerState>? _stateSub;

  /// Guards [_onFinish] so end-of-playback fires exactly once per run (the
  /// state stream and the position fallback can both reach the end).
  bool _finished = false;

  /// Wall-clock of the last user seek.
  DateTime? _lastSeekAt;

  /// True for a short grace window after a user scrub. *All* completion paths
  /// (the position fallback and the completed-state event) are suppressed during
  /// it, so dragging the slider toward the end — especially on short prayers
  /// where the remaining audio plays out almost instantly — never pops the
  /// post-prayer mood check-in. Genuine end-of-playback (no recent seek) still
  /// completes normally.
  bool get _recentSeek =>
      _lastSeekAt != null &&
      DateTime.now().difference(_lastSeekAt!).inMilliseconds < 1500;

  @override
  Future<void> prepare() async {
    _timings = List<WordTiming>.from(prayer.wordTimings ?? const [])
      ..sort((a, b) => a.startMs.compareTo(b.startMs));

    _buildWordIndex();

    final url = await _resolveAudioUrl(prayer.audioPath!);
    final dur = await _player.setUrl(url);

    // Prefer the audio's true duration; fall back to the last word end if the
    // header is missing.
    final totalMs =
        (dur?.inMilliseconds ?? (_timings.isNotEmpty ? _timings.last.endMs : 0))
            .clamp(0, 1 << 30)
            .toInt();
    controller.total.value = Duration(milliseconds: totalMs);

    _stateSub = _player.playerStateStream.listen((s) {
      controller.isPlaying.value = s.playing;
      // Natural end of the source — but ignore a 'completed' that lands right
      // after a scrub (dragging to ~the end then the tail plays out instantly),
      // so seeking can't masquerade as finishing the prayer.
      if (s.processingState == ProcessingState.completed && !_recentSeek) {
        _onFinish();
      }
    });

    // Use a high-frequency position stream — default `positionStream` only
    // ticks ~every 200ms, which is too coarse for word-level karaoke sweep
    // (words can be 100-300ms long). createPositionStream lets us request
    // 50-100ms updates so the sweep advances smoothly through each word.
    _posSub = _player
        .createPositionStream(
          steps: 800,
          minPeriod: const Duration(milliseconds: 50),
          maxPeriod: const Duration(milliseconds: 100),
        )
        .listen(_onPosition);
  }

  /// Walk segments + timings together and assign each timing to its segment
  /// and character range.
  ///
  /// The transcript Replicate was given is the same `script_text` we parse
  /// into segments here (with `(pause)` stripped both sides), so the **order**
  /// of timings is reliable even when individual tokens differ in punctuation
  /// (Replicate may emit "Father," vs our tokeniser's "Father"). We therefore
  /// pair token-to-timing by **index** rather than by text match — the
  /// previous text-match version dropped any timing whose word didn't match
  /// exactly, leaving holes that stalled the karaoke sweep on the first word.
  void _buildWordIndex() {
    final segs = controller.segments;
    _segOf = List<int>.filled(_timings.length, -1);
    _charStart = List<int>.filled(_timings.length, 0);
    _charEnd = List<int>.filled(_timings.length, 0);
    _segStartMs = List<int>.filled(segs.length, 0);

    int wIdx = 0;
    int lastSpokenEndMs = 0;

    for (var s = 0; s < segs.length; s++) {
      final seg = segs[s];
      if (seg.isPause) {
        // Pause sits between the previous spoken segment's end and the next
        // word's start; we anchor it at the end of the last spoken segment.
        _segStartMs[s] = lastSpokenEndMs;
        continue;
      }
      final tokens = _tokenise(seg.text);
      int? firstStartMs;
      for (final tok in tokens) {
        if (wIdx >= _timings.length) break;
        _segOf[wIdx] = s;
        _charStart[wIdx] = tok.start;
        _charEnd[wIdx] = tok.end;
        firstStartMs ??= _timings[wIdx].startMs;
        lastSpokenEndMs = _timings[wIdx].endMs;
        wIdx++;
      }
      _segStartMs[s] = firstStartMs ?? lastSpokenEndMs;
    }
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration target) async {
    // Seeking back from the end re-arms end detection (replay / scrub-back).
    if (target < controller.total.value - const Duration(milliseconds: 250)) {
      _finished = false;
    }
    // Refresh the highlight + scrubber *first*, synchronously, so the reader
    // tracks the drag in real time. Awaiting the audio engine's seek before
    // updating the UI made the karaoke text appear frozen while scrubbing —
    // under a fast drag just_audio's seeks lag and coalesce, so the post-await
    // update arrived only once the drag was released. Flagged as a seek so
    // dragging to (or past) the end never *marks the prayer finished*; only
    // natural playback reaching the end may do that.
    _lastSeekAt = DateTime.now();
    _onPosition(target, fromSeek: true);
    await _player.seek(target);
  }

  @override
  Future<void> dispose() async {
    await _posSub?.cancel();
    await _stateSub?.cancel();
    await _player.dispose();
  }

  @override
  Duration startOfSegment(int segmentIndex) {
    if (segmentIndex < 0 || segmentIndex >= _segStartMs.length) {
      return Duration.zero;
    }
    return Duration(milliseconds: _segStartMs[segmentIndex]);
  }

  // ── Position → active word ────────────────────────────────────────────────

  void _onPosition(Duration pos, {bool fromSeek = false}) {
    final ms = pos.inMilliseconds;
    controller.elapsed.value = pos;

    // Belt-and-suspenders end detection. ProcessingState.completed is the
    // primary signal, but some sources never emit it cleanly (missing/short
    // duration header, or trailing audio beyond the last word timing). Fire
    // once when the position reaches the known total so the end of the prayer
    // is always caught — matching exactly where the progress bar fills up.
    //
    // Only let the position *fallback* end the prayer when it's genuinely been
    // played there: not on a seek-driven sample, not within the grace window
    // after a scrub, and only while actually playing. ProcessingState.completed
    // remains the primary end signal (also grace-guarded above).
    final totMs = controller.total.value.inMilliseconds;
    if (!fromSeek &&
        !_recentSeek &&
        controller.isPlaying.value &&
        !_finished &&
        totMs > 0 &&
        ms >= totMs - 250) {
      _onFinish();
      return;
    }

    if (_timings.isEmpty) return;

    final i = _searchTiming(ms);
    if (i == null) {
      // Before the very first word — leave the reader in its initial state.
      return;
    }

    // Walk back to the nearest timing that has a segment assigned — defensive
    // against rare cases where Replicate emits more words than our script
    // tokeniser produced (e.g. a stray "amen"). Avoids stalling on an
    // unmapped trailing timing.
    int j = i;
    while (j >= 0 && _segOf[j] < 0) {
      j--;
    }
    if (j < 0) return;

    final seg = _segOf[j];
    controller.activeIndex.value = seg;
    controller.wordStart.value = _charStart[j];
    // The reader's karaoke sweep uses [wordEnd] as the "filled up to here"
    // boundary. We always anchor it at the END of the most-recently-spoken
    // word, so during the gap between words the sweep stays at that word's
    // tail rather than collapsing to zero and blanking the highlight.
    controller.wordEnd.value = _charEnd[j];
  }

  /// Returns the index of the **most-recently-started** timing for [ms]:
  ///   • inside a word → that word's index;
  ///   • between word N's end and N+1's start → N;
  ///   • past the last word → the last word's index;
  ///   • before the first word → null.
  ///
  /// This anchor-on-last-started semantics is what makes the karaoke sweep
  /// feel continuous instead of flickering through every inter-word gap.
  int? _searchTiming(int ms) {
    var lo = 0;
    var hi = _timings.length - 1;
    int? ans;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      if (_timings[mid].startMs <= ms) {
        ans = mid;
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    return ans;
  }

  void _onFinish() {
    if (_finished) return;
    _finished = true;
    controller.isPlaying.value = false;
    controller.isFinished.value = true;
    controller.elapsed.value = controller.total.value;
    controller.wordStart.value = 0;
    controller.wordEnd.value = 0;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static Future<String> _resolveAudioUrl(String path) async {
    // Already a fully-qualified URL? Use as-is. Otherwise mint a short-lived
    // signed URL from the private `prayer-audio` storage bucket.
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final client = Supabase.instance.client;
    final signed =
        await client.storage.from('prayer-audio').createSignedUrl(path, 3600);
    return signed;
  }

  /// Extracts word tokens from [text] with their start/end character offsets
  /// inside the original string — used to map each Replicate timing onto the
  /// exact substring the karaoke sweep should fill.
  static const _wordPattern = r"[\p{L}\p{N}’']+";

  static List<({String text, int start, int end})> _tokenise(String text) {
    final re = RegExp(_wordPattern, unicode: true);
    final out = <({String text, int start, int end})>[];
    for (final m in re.allMatches(text)) {
      out.add((text: m.group(0)!, start: m.start, end: m.end));
    }
    return out;
  }
}

// ─── TTS engine (flutter_tts fallback — estimated sync) ──────────────────────

class _TtsEngine implements _Engine {
  _TtsEngine({required this.controller, required this.prayer});

  final PrayerPlayerController controller;
  final Prayer prayer;

  final FlutterTts _tts = FlutterTts();

  late List<int> _startMs;
  int _totalMs = 0;

  int _generation = 0;
  Timer? _ticker;
  int _segStartMs = 0;
  int _segEstMs = 1;
  DateTime _segWallStart = DateTime.now();

  /// Wall-clock of the last user seek; see [_recentSeek].
  DateTime? _lastSeekAt;

  /// Short grace window after a scrub. While true, reaching the end does NOT
  /// complete the prayer (no post-prayer mood check-in) — dragging the slider
  /// toward the end of a short prayer otherwise plays the tail out almost
  /// instantly and looked like finishing. Natural play-through (no recent seek)
  /// still completes normally.
  bool get _recentSeek =>
      _lastSeekAt != null &&
      DateTime.now().difference(_lastSeekAt!).inMilliseconds < 1500;

  @override
  Future<void> prepare() async {
    _buildTimeline();
    await _configureTts(prayer.lang);

    // Word-boundary callback drives the karaoke sweep during a spoken line.
    _tts.setProgressHandler((text, start, end, word) {
      controller.wordStart.value = start;
      controller.wordEnd.value = end;
    });
  }

  @override
  Future<void> play() async {
    controller.isPlaying.value = true;
    _startTicker();
    unawaited(_runFrom(controller.activeIndex.value));
  }

  @override
  Future<void> pause() async {
    controller.isPlaying.value = false;
    _stopTicker();
    _generation++; // supersede running loop
    try {
      await _tts.stop();
    } catch (_) {/* ignore */}
  }

  @override
  Future<void> seek(Duration target) async {
    final segs = controller.segments;
    if (segs.isEmpty) return;
    final ms = target.inMilliseconds.clamp(0, _totalMs).toInt();
    final index = _segmentAt(ms);
    final wasPlaying = controller.isPlaying.value;
    _lastSeekAt = DateTime.now();

    _generation++;
    try {
      await _tts.stop();
    } catch (_) {/* ignore */}

    controller.activeIndex.value = index;
    _anchorSegment(index);

    if (wasPlaying) {
      _startTicker();
      unawaited(_runFrom(index));
    }
  }

  @override
  Future<void> dispose() async {
    _ticker?.cancel();
    _generation++;
    try {
      await _tts.stop();
    } catch (_) {/* ignore */}
  }

  @override
  Duration startOfSegment(int segmentIndex) {
    if (segmentIndex < 0 || segmentIndex >= _startMs.length) {
      return Duration.zero;
    }
    return Duration(milliseconds: _startMs[segmentIndex]);
  }

  // ── Internals ─────────────────────────────────────────────────────────────

  Future<void> _runFrom(int index) async {
    final segs = controller.segments;
    final gen = ++_generation;
    for (var i = index; i < segs.length; i++) {
      if (gen != _generation) return;
      controller.activeIndex.value = i;
      _anchorSegment(i);
      final seg = segs[i];

      if (seg.isPause) {
        await _sleep(seg.estMs, gen);
      } else {
        final spoke = await _speakLine(seg.text);
        if (!spoke && gen == _generation) await _sleep(seg.estMs, gen);
      }

      if (gen != _generation) return;
    }
    if (gen == _generation) _finish();
  }

  Future<bool> _speakLine(String text) async {
    try {
      final result = await _tts.speak(text);
      return result == 1;
    } catch (e) {
      logger.warning('[TtsEngine] speak failed: $e');
      return false;
    }
  }

  Future<void> _sleep(int ms, int gen) async {
    const step = 100;
    var waited = 0;
    while (waited < ms) {
      if (gen != _generation) return;
      final chunk = (ms - waited).clamp(0, step).toInt();
      await Future<void>.delayed(Duration(milliseconds: chunk));
      waited += chunk;
    }
  }

  void _finish() {
    controller.isPlaying.value = false;
    controller.elapsed.value = Duration(milliseconds: _totalMs);
    controller.wordStart.value = 0;
    controller.wordEnd.value = 0;
    _stopTicker();
    // Reaching the end right after a scrub (dragging to ~the end of a short
    // prayer, whose tail plays out almost instantly) is navigation, not
    // finishing — settle at the end but don't pop the post-prayer mood check-in.
    if (_recentSeek) return;
    controller.isFinished.value = true;
  }

  void _anchorSegment(int i) {
    final segs = controller.segments;
    _segStartMs = (i >= 0 && i < _startMs.length) ? _startMs[i] : 0;
    _segEstMs = (i >= 0 && i < segs.length)
        ? segs[i].estMs.clamp(1, 1 << 30).toInt()
        : 1;
    _segWallStart = DateTime.now();
    controller.elapsed.value = Duration(milliseconds: _segStartMs);
    controller.wordStart.value = 0;
    controller.wordEnd.value = 0;
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!controller.isPlaying.value) return;
      final wall = DateTime.now().difference(_segWallStart).inMilliseconds;
      final frac = (wall / _segEstMs).clamp(0.0, 1.0);
      final ms =
          (_segStartMs + frac * _segEstMs).round().clamp(0, _totalMs).toInt();
      controller.elapsed.value = Duration(milliseconds: ms);
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  int _segmentAt(int ms) {
    if (_startMs.isEmpty) return 0;
    var lo = 0, hi = _startMs.length - 1, ans = 0;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      if (_startMs[mid] <= ms) {
        ans = mid;
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    return ans;
  }

  void _buildTimeline() {
    final segs = controller.segments;
    final starts = List<int>.filled(segs.length, 0);
    var t = 0;
    for (var i = 0; i < segs.length; i++) {
      starts[i] = t;
      t += segs[i].estMs;
    }
    _startMs = starts;
    _totalMs = t;
    controller.total.value = Duration(milliseconds: t);
  }

  Future<void> _configureTts(String lang) async {
    try {
      await _tts.awaitSpeakCompletion(true);
      await _tts.setLanguage(lang == 'fr' ? 'fr-FR' : 'en-US');
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);
      await _tts.setSpeechRate(
        defaultTargetPlatform == TargetPlatform.iOS ? 0.45 : 0.92,
      );
      _tts.setCompletionHandler(() {});
      _tts.setCancelHandler(() {});
      _tts.setErrorHandler(
        (msg) => logger.warning('[TtsEngine] TTS error: $msg'),
      );

      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await _tts.setSharedInstance(true);
        await _tts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [
            IosTextToSpeechAudioCategoryOptions.allowBluetooth,
            IosTextToSpeechAudioCategoryOptions.mixWithOthers,
          ],
        );
      }
    } catch (e) {
      logger.warning('[TtsEngine] config failed: $e');
    }
  }
}
