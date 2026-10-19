import 'dart:async';
import 'dart:convert';

import 'package:faithlock/config/env.dart';
import 'package:faithlock/config/logger.dart';
import 'package:faithlock/features/prayer_audio/models/prayer.dart';
import 'package:faithlock/services/storage/preferences_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Cache key used to persist the last-good prayer list in SharedPreferences.
///
/// Bump the suffix whenever the Prayer schema changes so stale caches from
/// previous app versions don't shadow new fields. v2 added `word_timings`
/// (Replicate forced-alignment) — without this bump, prayers cached on v1
/// devices would never get the timings and would silently fall back to the
/// TTS engine instead of playing the ElevenLabs MP3.
const _kPrayerCacheKey = 'prayer_metadata_cache_v2';

/// Repository for fetching and caching prayer metadata.
///
/// Strategy — stale-while-revalidate:
///   1. If a locally-cached JSON exists, return it immediately (instant /
///      offline load) and kick off a background refresh.
///   2. If no cache exists, fetch from Supabase, cache the result, and return.
///   3. On any Supabase error (network, empty response, bad data), fall back
///      to the local cache or — if the cache is also absent — to the built-in
///      mock catalog.  Never crashes, never returns an empty list.
///
/// Reads go through the [SupabaseClient] so they carry the anonymous
/// `authenticated` session JWT — required because the `prayers` table RLS
/// only grants SELECT to the `authenticated` role.
class PrayerRepository {
  PrayerRepository({
    SupabaseClient? client,
    PreferencesService? prefs,
  })  : _client = client,
        _prefs = prefs ?? PreferencesService();

  final SupabaseClient? _client;
  final PreferencesService _prefs;

  /// Resolves the Supabase client lazily so the repository can be constructed
  /// before (or without) Supabase being initialized.
  SupabaseClient get _supabase => _client ?? Supabase.instance.client;

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Returns the best available prayer list and triggers a background refresh.
  Future<List<Prayer>> fetchPrayers() async {
    // 1. Try returning cached data immediately (stale-while-revalidate).
    final cached = await _loadCache();
    if (cached != null && cached.isNotEmpty) {
      logger.info('[PrayerRepository] Returning ${cached.length} cached prayers, refreshing in background');
      // Fire-and-forget background refresh — caller gets cached data instantly.
      unawaited(_refreshFromSupabase());
      return cached;
    }

    // 2. No cache — must wait for the network.
    return _refreshFromSupabase();
  }

  // ── Supabase fetch ─────────────────────────────────────────────────────────

  /// Fetches prayers via the Supabase client (carrying the authenticated
  /// session JWT), persists the result, and returns it.
  /// Falls back to [_loadCache] → [_mockPrayers] on failure.
  Future<List<Prayer>> _refreshFromSupabase() async {
    try {
      final supabaseUrl = Env.supabaseUrl;
      final anonKey = Env.supabaseAnonKey;

      // Detect placeholder values — skip the real network call.
      if (supabaseUrl.contains('YOUR_PROJECT') || anonKey.contains('YOUR_SUPABASE')) {
        logger.warning('[PrayerRepository] Supabase credentials not configured → using mock');
        return await _loadCache() ?? _mockPrayers;
      }

      // Reads run through the client so the anonymous `authenticated` session
      // JWT is attached automatically (required by the `prayers` table RLS).
      final List<dynamic> rows = await _supabase
          .from('prayers')
          .select()
          .order('domain')
          .timeout(const Duration(seconds: 10));

      if (rows.isEmpty) {
        logger.info('[PrayerRepository] Supabase returned empty list → using fallback');
        return await _loadCache() ?? _mockPrayers;
      }

      final prayers = rows
          .cast<Map<String, dynamic>>()
          .map(Prayer.fromMap)
          .toList();

      // Persist for next cold start / offline use.
      await _persistCache(prayers);
      logger.info('[PrayerRepository] Fetched ${prayers.length} prayers from Supabase');
      return prayers;
    } catch (e) {
      logger.warning('[PrayerRepository] Supabase fetch failed: $e → using fallback');
      return await _loadCache() ?? _mockPrayers;
    }
  }

  // ── Cache helpers ──────────────────────────────────────────────────────────

  Future<List<Prayer>?> _loadCache() async {
    try {
      final raw = await _prefs.readString(_kPrayerCacheKey);
      if (raw == null) return null;
      final list = jsonDecode(raw) as List;
      return list
          .cast<Map<String, dynamic>>()
          .map(Prayer.fromMap)
          .toList();
    } catch (e) {
      logger.warning('[PrayerRepository] Cache read failed: $e');
      return null;
    }
  }

  Future<void> _persistCache(List<Prayer> prayers) async {
    try {
      final json = jsonEncode(prayers.map((p) => p.toMap()).toList());
      await _prefs.writeString(_kPrayerCacheKey, json);
    } catch (e) {
      logger.warning('[PrayerRepository] Cache write failed: $e');
    }
  }

  // ── Mock catalog (fallback of last resort) ─────────────────────────────────

  static final List<Prayer> _mockPrayers = [
    // Daily Rhythm
    const Prayer(
      id: 'mock-1',
      title: 'Morning Prayer',
      domain: PrayerDomain.dailyRhythm,
      scriptureRef: 'Psalm 5:3',
      scriptureText:
          'In the morning, Lord, you hear my voice; in the morning I lay my requests before you and wait expectantly.',
      durationSec: 5 * 60,
      lang: 'en',
    ),
    const Prayer(
      id: 'mock-2',
      title: 'Evening Examen',
      domain: PrayerDomain.dailyRhythm,
      scriptureRef: 'Psalm 4:8',
      scriptureText:
          'In peace I will lie down and sleep, for you alone, Lord, make me dwell in safety.',
      durationSec: 7 * 60,
      lang: 'en',
    ),

    // Struggles
    const Prayer(
      id: 'mock-3',
      title: 'Peace Over Anxiety',
      domain: PrayerDomain.struggles,
      scriptureRef: 'Philippians 4:6–7',
      scriptureText:
          'Do not be anxious about anything, but in every situation, by prayer and petition, with thanksgiving, present your requests to God.',
      durationSec: 6 * 60,
      lang: 'en',
    ),
    const Prayer(
      id: 'mock-4',
      title: 'Strength in Weakness',
      domain: PrayerDomain.struggles,
      scriptureRef: '2 Corinthians 12:9',
      scriptureText:
          'My grace is sufficient for you, for my power is made perfect in weakness.',
      durationSec: 5 * 60,
      lang: 'en',
    ),

    // Drawing Near
    const Prayer(
      id: 'mock-5',
      title: 'A Heart of Gratitude',
      domain: PrayerDomain.drawingNear,
      scriptureRef: '1 Thessalonians 5:18',
      scriptureText:
          "Give thanks in all circumstances; for this is God's will for you in Christ Jesus.",
      durationSec: 4 * 60,
      lang: 'en',
    ),
    const Prayer(
      id: 'mock-6',
      title: 'Be Still (Reset)',
      domain: PrayerDomain.drawingNear,
      scriptureRef: 'Psalm 46:10',
      scriptureText:
          'Be still, and know that I am God; I will be exalted among the nations, I will be exalted in the earth.',
      durationSec: 8 * 60,
      lang: 'en',
    ),

    // Scripture
    const Prayer(
      id: 'mock-7',
      title: 'Psalm 23',
      domain: PrayerDomain.scripture,
      scriptureRef: 'Psalm 23:1–6',
      scriptureText:
          'The Lord is my shepherd, I lack nothing. He makes me lie down in green pastures...',
      durationSec: 6 * 60,
      lang: 'en',
    ),
    const Prayer(
      id: 'mock-8',
      title: 'Psalm 91',
      domain: PrayerDomain.scripture,
      scriptureRef: 'Psalm 91:1–2',
      scriptureText:
          'Whoever dwells in the shelter of the Most High will rest in the shadow of the Almighty.',
      durationSec: 7 * 60,
      lang: 'en',
    ),
    const Prayer(
      id: 'mock-9',
      title: "The Lord's Prayer",
      domain: PrayerDomain.scripture,
      scriptureRef: 'Matthew 6:9–13',
      scriptureText:
          'Our Father in heaven, hallowed be your name, your kingdom come, your will be done, on earth as it is in heaven.',
      durationSec: 5 * 60,
      lang: 'en',
    ),

    // Life Seasons
    const Prayer(
      id: 'mock-10',
      title: 'Praying for Others',
      domain: PrayerDomain.lifeSeasons,
      scriptureRef: 'James 5:16',
      scriptureText:
          'The prayer of a righteous person is powerful and effective.',
      durationSec: 6 * 60,
      lang: 'en',
    ),
  ];
}
