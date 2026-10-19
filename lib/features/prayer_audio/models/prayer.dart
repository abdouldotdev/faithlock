import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

// ─── Prayer Domain ──────────────────────────────────────────────────────────

enum PrayerDomain {
  dailyRhythm,
  struggles,
  drawingNear,
  scripture,
  lifeSeasons,
  digitalFocus,
}

extension PrayerDomainX on PrayerDomain {
  /// Localized section name. Resolves `prayerDomain_<name>` from the app
  /// translations (EN/FR), e.g. dailyRhythm → "Daily Rhythm" / "Rythme
  /// quotidien". Falls back to the key if a locale lacks it.
  String get displayName => 'prayerDomain_$name'.tr;

  IconData get icon {
    switch (this) {
      case PrayerDomain.dailyRhythm:
        return CupertinoIcons.sun_max_fill;
      case PrayerDomain.struggles:
        return CupertinoIcons.shield_fill;
      case PrayerDomain.drawingNear:
        return CupertinoIcons.heart_fill;
      case PrayerDomain.scripture:
        return CupertinoIcons.book_fill;
      case PrayerDomain.lifeSeasons:
        return CupertinoIcons.leaf_arrow_circlepath;
      case PrayerDomain.digitalFocus:
        return CupertinoIcons.device_phone_portrait;
    }
  }

  /// Parse from a raw string value stored in the database.
  static PrayerDomain fromString(String value) {
    switch (value) {
      case 'daily_rhythm':
        return PrayerDomain.dailyRhythm;
      case 'struggles':
        return PrayerDomain.struggles;
      case 'drawing_near':
        return PrayerDomain.drawingNear;
      case 'scripture':
        return PrayerDomain.scripture;
      case 'life_seasons':
        return PrayerDomain.lifeSeasons;
      case 'digital_focus':
        return PrayerDomain.digitalFocus;
      default:
        return PrayerDomain.dailyRhythm;
    }
  }

  String get rawValue {
    switch (this) {
      case PrayerDomain.dailyRhythm:
        return 'daily_rhythm';
      case PrayerDomain.struggles:
        return 'struggles';
      case PrayerDomain.drawingNear:
        return 'drawing_near';
      case PrayerDomain.scripture:
        return 'scripture';
      case PrayerDomain.lifeSeasons:
        return 'life_seasons';
      case PrayerDomain.digitalFocus:
        return 'digital_focus';
    }
  }
}

// ─── Word Timing (forced-alignment output) ───────────────────────────────────

/// One aligned word from a forced-alignment pass (Replicate
/// `cureau/force-align-wordstamps`): a token plus the **millisecond** range
/// in the audio where it is spoken.
///
/// We always store milliseconds (int) internally for precision and easy
/// arithmetic; the Replicate model returns seconds (double) and is converted
/// to ms at parse time.
class WordTiming {
  const WordTiming({
    required this.word,
    required this.startMs,
    required this.endMs,
  });

  final String word;
  final int startMs;
  final int endMs;

  Duration get start => Duration(milliseconds: startMs);
  Duration get end => Duration(milliseconds: endMs);
  int get durationMs => endMs - startMs;

  /// Parse one entry. Accepts both the raw Replicate shape (`start`/`end`
  /// seconds) and our normalised storage shape (`start_ms`/`end_ms` ints) so
  /// a partial dataset never crashes playback.
  factory WordTiming.fromMap(Map<String, dynamic> m) {
    int toMs(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is double) return (v * 1000).round();
      if (v is num) return (v.toDouble() * 1000).round();
      return 0;
    }

    final hasMs = m.containsKey('start_ms') || m.containsKey('end_ms');
    return WordTiming(
      word: (m['word'] ?? '').toString(),
      startMs: hasMs ? (m['start_ms'] as num?)?.toInt() ?? 0 : toMs(m['start']),
      endMs: hasMs ? (m['end_ms'] as num?)?.toInt() ?? 0 : toMs(m['end']),
    );
  }

  /// Canonical storage shape (`start_ms` / `end_ms` ints) — what we write to
  /// the `prayers.word_timings` jsonb column.
  Map<String, dynamic> toMap() => {
        'word': word,
        'start_ms': startMs,
        'end_ms': endMs,
      };
}

// ─── Prayer Model ────────────────────────────────────────────────────────────

class Prayer {
  const Prayer({
    required this.id,
    required this.title,
    required this.domain,
    required this.scriptureRef,
    required this.durationSec,
    this.scriptureText,
    this.scriptText,
    this.audioUrl,
    this.audioPath,
    this.wordTimings,
    this.lang = 'en',
  });

  final String id;
  final String title;
  final PrayerDomain domain;

  /// Short reference, e.g. "Psalm 23:1".
  final String scriptureRef;

  /// Optional full verse text.
  final String? scriptureText;

  /// Optional full prayer script / transcript.
  final String? scriptText;

  /// Duration in seconds.
  final int durationSec;

  /// Remote URL for the audio file. May be null while content is pending.
  /// Kept for backward-compat; prefer [audioPath] + a signed URL.
  final String? audioUrl;

  /// Object path inside the private `prayer-audio` storage bucket, e.g.
  /// "en/morning-prayer.mp3". Playback mints a short-lived signed URL from
  /// this path. May be null while content is pending.
  final String? audioPath;

  /// Forced-alignment word timestamps for [audioPath], produced by Replicate
  /// `cureau/force-align-wordstamps`. Drives the karaoke sync exactly when
  /// non-null; absent → fall back to estimated TTS sync.
  final List<WordTiming>? wordTimings;

  final String lang;

  // ── Derived helpers ──────────────────────────────────────────────────────

  /// Human-readable duration, e.g. "5 min".
  String get durationLabel {
    final minutes = (durationSec / 60).ceil();
    return '$minutes min';
  }

  // ── Factory ──────────────────────────────────────────────────────────────

  factory Prayer.fromMap(Map<String, dynamic> map) {
    // `word_timings` is jsonb in Supabase — comes back as List<dynamic> of
    // maps. Wraps any non-list (null / malformed) into an empty timing list
    // so a partial dataset never crashes playback.
    List<WordTiming>? parseTimings(dynamic raw) {
      if (raw is List) {
        final out = <WordTiming>[];
        for (final e in raw) {
          if (e is Map) {
            out.add(WordTiming.fromMap(Map<String, dynamic>.from(e)));
          }
        }
        return out.isEmpty ? null : out;
      }
      return null;
    }

    return Prayer(
      id: (map['id'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      domain: PrayerDomainX.fromString((map['domain'] ?? '').toString()),
      scriptureRef: (map['scripture_ref'] ?? '').toString(),
      scriptureText: map['scripture_text']?.toString(),
      scriptText: map['script_text']?.toString(),
      durationSec: (map['duration_sec'] as num?)?.toInt() ?? 0,
      audioUrl: map['audio_url']?.toString(),
      audioPath: map['audio_path']?.toString(),
      wordTimings: parseTimings(map['word_timings']),
      lang: (map['lang'] ?? 'en').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'domain': domain.rawValue,
      'scripture_ref': scriptureRef,
      'scripture_text': scriptureText,
      'script_text': scriptText,
      'duration_sec': durationSec,
      'audio_url': audioUrl,
      'audio_path': audioPath,
      'word_timings': wordTimings?.map((t) => t.toMap()).toList(),
      'lang': lang,
    };
  }

  @override
  String toString() => 'Prayer(id: $id, title: $title, domain: $domain)';
}
