import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Regle de mise a jour des person properties pour un event donne.
class _PersonPropertyRule {
  /// Proprietes compteur a incrementer de 1.
  final List<String> increment;

  /// Proprietes date a positionner a l'instant de l'event.
  final List<String> stamp;

  /// Proprietes booleennes a passer a `true`.
  final List<String> setTrue;

  const _PersonPropertyRule({
    this.increment = const [],
    this.stamp = const [],
    this.setTrue = const [],
  });
}

/// Maintient les person properties PostHog a jour en temps reel.
///
/// Le backfill one-shot (`scripts/posthog_backfill_person_properties.py`)
/// recalcule ces proprietes depuis l'historique d'events ; ce module prend le
/// relais pour les nouveaux events, sans requete reseau supplementaire cote
/// lecture : les compteurs vivent en local ([SharedPreferences]) et sont
/// pousses via `identify(userProperties: ...)`.
///
/// Branchement : un seul point d'appel, dans
/// `EventTrackingModule.trackCustom`, qui couvre donc tous les events du
/// catalogue sans toucher aux 25 sites d'appel metier.
class PersonPropertiesModule {
  static const String _prefsPrefix = 'ph_person_prop_';

  /// Delai de coalescence : plusieurs events rapproches ne declenchent qu'un
  /// seul `identify`, ce qui evite de spammer PostHog pendant un flow.
  static const Duration _flushDelay = Duration(seconds: 2);

  final dynamic _postHogService;

  SharedPreferences? _prefs;
  bool _isInitialized = false;
  Timer? _flushTimer;

  /// Proprietes modifiees depuis le dernier flush.
  final Map<String, Object> _pending = {};

  PersonPropertiesModule(this._postHogService);

  /// Table event -> proprietes impactees.
  ///
  /// Toute entree ajoutee ici est prise en compte automatiquement : il n'y a
  /// rien a modifier dans les controllers.
  static const Map<String, _PersonPropertyRule> _rules = {
    // -- PRIERE --------------------------------------------------------------
    'prayer_completed': _PersonPropertyRule(
      increment: ['total_prayers_completed'],
      stamp: ['last_prayer_at'],
    ),
    'prayer_started': _PersonPropertyRule(
      increment: ['total_prayers_started'],
    ),
    'prayer_abandoned': _PersonPropertyRule(
      increment: ['total_prayers_abandoned'],
    ),
    'prayer_flow_cancelled': _PersonPropertyRule(
      increment: ['total_prayers_cancelled'],
    ),
    'prayer_session_started': _PersonPropertyRule(
      increment: ['total_prayer_sessions_started'],
    ),
    'prayer_session_completed': _PersonPropertyRule(
      increment: ['total_prayer_sessions_completed'],
      stamp: ['last_prayer_session_at'],
    ),
    'prayer_step_completed': _PersonPropertyRule(
      increment: ['total_prayer_steps_completed'],
    ),
    'prayer_library_viewed': _PersonPropertyRule(
      increment: ['prayer_library_views'],
    ),
    'prayer_library_prayer_selected': _PersonPropertyRule(
      increment: ['prayer_library_selections'],
    ),

    // -- UNLOCK --------------------------------------------------------------
    'unlock_flow_started': _PersonPropertyRule(
      increment: ['total_unlock_flows_started'],
    ),
    'unlock_completed': _PersonPropertyRule(
      increment: ['total_unlocks_completed'],
      stamp: ['last_unlock_at'],
    ),
    'apps_relocked': _PersonPropertyRule(
      increment: ['total_apps_relocked'],
    ),
    'unlock_expired': _PersonPropertyRule(
      increment: ['total_unlock_expirations'],
    ),
    'unlock_entry': _PersonPropertyRule(
      increment: ['total_unlock_entries'],
    ),

    // -- BIBLE ---------------------------------------------------------------
    'bible_reading_completed': _PersonPropertyRule(
      increment: ['bible_chapters_read'],
      stamp: ['last_bible_read_at'],
    ),
    'bible_chapter_opened': _PersonPropertyRule(
      increment: ['bible_chapters_opened'],
    ),
    'bible_book_opened': _PersonPropertyRule(
      increment: ['bible_books_opened'],
    ),
    'bible_search': _PersonPropertyRule(
      increment: ['bible_searches_count'],
    ),
    'bible_verse_of_day_shared': _PersonPropertyRule(
      increment: ['bible_verses_shared'],
    ),
    'bible_verse_of_day_viewed': _PersonPropertyRule(
      increment: ['bible_verse_of_day_views'],
    ),

    // -- COMPANION -----------------------------------------------------------
    'companion_message_sent': _PersonPropertyRule(
      increment: ['companion_messages_sent'],
    ),
    'companion_reply_completed': _PersonPropertyRule(
      increment: ['companion_replies_received'],
    ),
    'companion_opened': _PersonPropertyRule(
      increment: ['companion_sessions_count'],
      stamp: ['last_companion_used_at'],
    ),
    'companion_new_chat': _PersonPropertyRule(
      increment: ['companion_new_chats'],
    ),
    'companion_voice_download': _PersonPropertyRule(
      increment: ['companion_voice_downloads'],
    ),

    // -- MOOD ----------------------------------------------------------------
    'mood_check_in_submitted': _PersonPropertyRule(
      increment: ['mood_checkins_count'],
      stamp: ['last_mood_checkin_at'],
    ),
    'mood_recorded': _PersonPropertyRule(
      increment: ['mood_recorded_count'],
    ),
    'mood_skipped': _PersonPropertyRule(
      increment: ['mood_skips_count'],
    ),

    // -- GAMIFICATION --------------------------------------------------------
    'badge_earned': _PersonPropertyRule(
      increment: ['badges_earned_count'],
      stamp: ['last_badge_earned_at'],
    ),
    'streak_freeze_used': _PersonPropertyRule(
      increment: ['streak_freezes_used'],
    ),
    'streak_intro_viewed': _PersonPropertyRule(
      increment: ['streak_intro_views'],
    ),

    // -- PAYWALL -------------------------------------------------------------
    'paywall_viewed': _PersonPropertyRule(
      increment: ['paywall_views_count'],
    ),
    'paywall_dismissed': _PersonPropertyRule(
      increment: ['paywall_dismissals'],
    ),
    'paywall_plan_selected': _PersonPropertyRule(
      increment: ['purchase_attempts_count'],
    ),
    'paywall_purchase_completed': _PersonPropertyRule(
      stamp: ['purchase_completed_at'],
      setTrue: ['purchases_completed'],
    ),
    'paywall_purchase_failed': _PersonPropertyRule(
      increment: ['purchase_failed_count'],
    ),
    'subscription_restore_started': _PersonPropertyRule(
      increment: ['subscription_restores_attempted'],
      setTrue: ['subscription_restore_attempted'],
    ),
    'subscription_restore_no_purchases': _PersonPropertyRule(
      increment: ['subscription_restores_no_purchases'],
    ),

    // -- ONBOARDING ----------------------------------------------------------
    'onboarding_step_completed': _PersonPropertyRule(
      increment: ['onboarding_steps_completed'],
    ),
    'onboarding_feature_adopted': _PersonPropertyRule(
      increment: ['onboarding_features_adopted'],
    ),

    // -- DIVERS --------------------------------------------------------------
    'notification_tapped': _PersonPropertyRule(
      increment: ['notifications_tapped_count'],
    ),
    'reflections_opened': _PersonPropertyRule(
      increment: ['reflections_opened_count'],
    ),
    'reflections_bookmark_opened': _PersonPropertyRule(
      increment: ['reflections_bookmarks_opened'],
    ),
    'tour_started': _PersonPropertyRule(increment: ['tours_started']),
    'tour_completed': _PersonPropertyRule(increment: ['tours_completed']),
    'tour_skipped': _PersonPropertyRule(increment: ['tours_skipped']),
    'rate_intent_shown': _PersonPropertyRule(increment: ['rate_intents_shown']),
    'rate_completed': _PersonPropertyRule(
      stamp: ['app_rated_at'],
      setTrue: ['app_rated'],
    ),
    'stats_dashboard_viewed': _PersonPropertyRule(
      increment: ['stats_dashboard_views'],
    ),
    'winback_sequence_scheduled': _PersonPropertyRule(
      increment: ['winback_sequence_count'],
    ),
  };

  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _isInitialized = true;
      if (kDebugMode) {
        debugPrint('PersonPropertiesModule: Initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('PersonPropertiesModule: Failed to initialize - $e');
      }
    }
  }

  Future<void> shutdown() async {
    _flushTimer?.cancel();
    _flushTimer = null;
    await flush();
    _isInitialized = false;
  }

  /// Repart de zero apres un logout : les compteurs locaux appartiennent au
  /// distinct_id precedent et ne doivent pas fuiter sur le suivant.
  Future<void> reset() async {
    _flushTimer?.cancel();
    _flushTimer = null;
    _pending.clear();

    final prefs = _prefs;
    if (prefs == null) return;
    for (final key in prefs.getKeys().toList()) {
      if (key.startsWith(_prefsPrefix)) {
        await prefs.remove(key);
      }
    }
  }

  /// Point d'entree unique : appele pour chaque event capture.
  ///
  /// No-op silencieux si l'event n'a pas de regle, ce qui est le cas de la
  /// grande majorite du catalogue.
  Future<void> onEvent(
    String eventName, [
    Map<String, dynamic>? eventProperties,
  ]) async {
    if (!_isInitialized) return;

    // `language_changed` ne rentre pas dans le modele compteur/date : la
    // valeur vient de l'event lui-meme.
    if (eventName == 'language_changed') {
      final language = eventProperties?['language'] ??
          eventProperties?['locale'] ??
          eventProperties?['value'];
      if (language != null) {
        _pending['language'] = language.toString();
        _scheduleFlush();
      }
      return;
    }

    // `Application Opened` doit calculer days_since_last_active a partir de
    // l'ancienne valeur, avant de l'ecraser.
    if (eventName == 'Application Opened') {
      await _handleApplicationOpened();
      return;
    }

    final rule = _rules[eventName];
    if (rule == null) return;

    final now = DateTime.now().toUtc();
    for (final property in rule.increment) {
      _pending[property] = await _bumpCounter(property);
    }
    for (final property in rule.stamp) {
      final iso = now.toIso8601String();
      await _prefs?.setString('$_prefsPrefix$property', iso);
      _pending[property] = iso;
    }
    for (final property in rule.setTrue) {
      await _prefs?.setBool('$_prefsPrefix$property', true);
      _pending[property] = true;
    }

    _scheduleFlush();
  }

  Future<void> _handleApplicationOpened() async {
    final prefs = _prefs;
    final now = DateTime.now().toUtc();

    final previousIso = prefs?.getString('${_prefsPrefix}last_active_date');
    final previous =
        previousIso != null ? DateTime.tryParse(previousIso)?.toUtc() : null;
    if (previous != null) {
      final days = now.difference(previous).inMinutes / 1440.0;
      _pending['days_since_last_active'] =
          double.parse(days.clamp(0.0, double.infinity).toStringAsFixed(2));
    } else {
      _pending['days_since_last_active'] = 0;
    }

    _pending['sessions_count_total'] = await _bumpCounter('sessions_count_total');

    final iso = now.toIso8601String();
    await prefs?.setString('${_prefsPrefix}last_active_date', iso);
    _pending['last_active_date'] = iso;

    _scheduleFlush();
  }

  Future<int> _bumpCounter(String property) async {
    final prefs = _prefs;
    final key = '$_prefsPrefix$property';
    final next = (prefs?.getInt(key) ?? 0) + 1;
    await prefs?.setInt(key, next);
    return next;
  }

  void _scheduleFlush() {
    _flushTimer?.cancel();
    _flushTimer = Timer(_flushDelay, flush);
  }

  /// Pousse les proprietes en attente vers PostHog.
  Future<void> flush() async {
    if (_pending.isEmpty) return;

    final batch = Map<String, Object>.from(_pending);
    _pending.clear();

    try {
      final distinctId = _postHogService.currentUserId as String? ??
          await Posthog().getDistinctId();
      await Posthog().identify(userId: distinctId, userProperties: batch);
      if (kDebugMode) {
        debugPrint(
          'PersonPropertiesModule: ${batch.length} properties pushed '
          '(${batch.keys.join(', ')})',
        );
      }
    } catch (e) {
      // On remet les valeurs en attente : le prochain event retentera. Les
      // compteurs etant persistes, aucune donnee n'est perdue meme si l'app
      // est tuee entre-temps.
      _pending.addAll(batch);
      if (kDebugMode) {
        debugPrint('PersonPropertiesModule: Failed to push properties - $e');
      }
    }
  }

  /// Valeur locale courante d'un compteur (debug / tests).
  int counterValue(String property) =>
      _prefs?.getInt('$_prefsPrefix$property') ?? 0;
}
