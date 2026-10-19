import 'dart:io';

import 'package:faithlock/services/analytics/posthog/export.dart';
import 'package:faithlock/services/subscription/revenuecat_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Copy + pricing shown on the Live Activity and carried into the promo page.
///
/// Kept here (not in the widget) so an A/B variant only changes data, never
/// layout code.
class PromoOfferCopy {
  final String variant;
  final String headline;
  final String subhead;

  /// Page button. First person on purpose — "my" outperforms "your" on CTAs.
  final String ctaLabel;

  /// Live Activity button. Kept short: the Dynamic Island expanded region and
  /// the Lock Screen pill both truncate anything longer than a word or two.
  final String ctaShort;

  /// Live Activity price line, a short sentence: "$1 for 7 days".
  final String priceLabel;

  /// Bare price token for the page's hero, before StoreKit answers. Must stay
  /// a token, not a sentence — it is rendered at 68pt.
  final String priceShort;

  const PromoOfferCopy({
    required this.variant,
    required this.headline,
    required this.subhead,
    required this.ctaLabel,
    required this.ctaShort,
    required this.priceLabel,
    required this.priceShort,
  });

  /// Warm / gift-framed. Deliberately no caps-lock, no fake scarcity.
  static const gift = PromoOfferCopy(
    variant: 'gift',
    headline: 'A small gift, just for you',
    subhead: 'Your first month for \$1',
    ctaLabel: 'Unwrap my gift',
    ctaShort: 'Unwrap',
    priceLabel: '\$1 for 1 month',
    priceShort: '\$1',
  );

  /// Value-framed — the honest-utility control for the copy test.
  static const value = PromoOfferCopy(
    variant: 'value',
    headline: 'Your welcome offer is ready',
    subhead: '1 month of FaithLock for \$1',
    ctaLabel: 'Get my offer',
    ctaShort: 'See offer',
    priceLabel: '\$1 · 1 month',
    priceShort: '\$1',
  );

  static const variants = <String, PromoOfferCopy>{
    'gift': gift,
    'value': value,
  };

  static PromoOfferCopy byVariant(String? variant) =>
      variants[variant] ?? gift;
}

/// Drives the "reserved welcome gift" Live Activity (Lock Screen, Notification
/// Center, Dynamic Island).
///
/// ## Why it is shaped this way
///
/// Apple's HIG is explicit: *"Don't use a Live Activity to display ads or
/// promotions."* It is a design guideline rather than an App Store Review
/// rule, and it is enforced unevenly — but it is enforceable under 4.0
/// (Design). Every constraint below exists to keep this defensible:
///
/// * [reserveOffer] is only ever called from an **explicit user tap**
///   ("Reserve my gift"), never silently on launch. The Live Activity then
///   tracks a real, user-initiated, time-boxed event.
/// * The window is a genuine deadline persisted at reservation time. Reopening
///   the app does **not** extend it ([_expiresAtKey]).
/// * Strictly **once per install** ([_reservedAtKey]) — no re-arming, no
///   nagging.
/// * Ends immediately on purchase, and self-dismisses at expiry.
/// * Gated by the remote flag [flagKey], so it can be killed without shipping
///   a build if App Review or users push back.
class PromoLiveActivityService {
  PromoLiveActivityService._();

  static final PromoLiveActivityService instance = PromoLiveActivityService._();

  static const MethodChannel _channel =
      MethodChannel('faithlock/live_activity');

  /// PostHog flag. Multivariate: `control` | `gift` | `value`.
  /// `control` = no Live Activity (in-app card only) — the A/B baseline.
  static const String flagKey = 'promo_live_activity';

  /// RevenueCat offering carrying the $1 introductory price.
  ///
  /// It points at `faithlock.annual.premium.promo`, a separate SKU: the live
  /// annual product already runs a 3-day free trial, and Apple allows only one
  /// introductory offer per product per territory. A second SKU keeps that
  /// trial untouched.
  ///
  /// The intro is **one month**, not one week: Apple rejects a week-long
  /// PAY_UP_FRONT offer on a yearly subscription
  /// (`Provided duration is not supported by PAY_UP_FRONT`).
  static const String offeringId = 'promo_dollar_week';

  /// How long the reservation is honoured.
  ///
  /// 8h, and not less: the Lock Screen is the channel this whole feature bets
  /// on, so the activity should live across the day and collect impressions.
  /// A shorter window also sharpens the once-per-install rule
  /// ([_reservedAtKey]) into a trap — put the phone down, lose the offer.
  ///
  /// 8h and not more: ActivityKit ends a Live Activity after eight hours, so a
  /// longer countdown would vanish mid-flight, showing a deadline the card no
  /// longer lives to reach.
  static const Duration window = Duration(hours: 8);

  static const String _reservedAtKey = 'promo_la_reserved_at';
  static const String _expiresAtKey = 'promo_la_expires_at';
  static const String _variantKey = 'promo_la_variant';

  bool _restoredThisSession = false;

  // ---------------------------------------------------------------------------
  // Capability
  // ---------------------------------------------------------------------------

  /// iOS 16.2+ with a widget extension that ships the activity.
  Future<bool> get isSupported async {
    if (!Platform.isIOS) return false;
    return await _invoke<bool>('isSupported') ?? false;
  }

  /// The user can disable Live Activities per app in Settings — respect it.
  Future<bool> get areActivitiesEnabled async {
    if (!Platform.isIOS) return false;
    return await _invoke<bool>('areActivitiesEnabled') ?? false;
  }

  Future<bool> get isRunning async {
    if (!Platform.isIOS) return false;
    return await _invoke<bool>('isRunning') ?? false;
  }

  // ---------------------------------------------------------------------------
  // Eligibility
  // ---------------------------------------------------------------------------

  /// True when the user may still be *offered* the reservation.
  ///
  /// Note this gates the in-app entry point, not the Live Activity itself:
  /// the control variant reaches the same promo page without one.
  Future<bool> isEligible() async {
    if (RevenueCatService.instance.isSubscriptionActive.value) return false;

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_reservedAtKey) != null) return false;

    return true;
  }

  /// Build-time QA override: `--dart-define=PROMO_LA_VARIANT=gift`.
  ///
  /// Needed because a debug build cannot run unattached on a physical device
  /// (Flutter refuses to launch it outside its tooling), while profile/release
  /// builds skip the [kDebugMode] fallback below. Empty by default, so a normal
  /// release build is unaffected.
  static const String _forcedVariant =
      String.fromEnvironment('PROMO_LA_VARIANT');

  /// Resolved A/B assignment. `control` means: no Live Activity.
  ///
  /// Release builds fall back to `control` whenever the flag can't be read, so
  /// the Live Activity stays dark until the experiment is deliberately turned
  /// on in PostHog. Debug builds fall back to `gift` instead — otherwise the
  /// feature would be untestable on device before the flag exists.
  Future<String> resolveVariant() async {
    if (_forcedVariant.isNotEmpty) {
      debugPrint('🔧 [PromoLA] variant forced to $_forcedVariant (dart-define)');
      return _forcedVariant;
    }

    const fallback = kDebugMode ? 'gift' : 'control';

    if (!PostHogService.instance.isReady) return fallback;
    try {
      final value = await PostHogService.instance.featureFlags
          .getFlagValue<String>(flagKey, defaultValue: fallback);
      return value ?? fallback;
    } catch (e) {
      debugPrint('⚠️ [PromoLA] flag lookup failed: $e');
      return fallback;
    }
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Starts the Live Activity for an offer the user just reserved.
  ///
  /// Call this **only** from an explicit user action. Returns the deadline the
  /// promo page should count down to, or null if nothing was started.
  Future<DateTime?> reserveOffer({String? forcedVariant}) async {
    if (!await isEligible()) return null;

    final variant = forcedVariant ?? await resolveVariant();
    final expiresAt = DateTime.now().add(window);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_reservedAtKey, DateTime.now().toIso8601String());
    await prefs.setString(_expiresAtKey, expiresAt.toIso8601String());
    await prefs.setString(_variantKey, variant);

    // Control cohort: the offer is reserved all the same, it just never
    // surfaces on the Lock Screen. That is what makes the test a clean read
    // on the Live Activity itself.
    if (variant == 'control') {
      _track('promo_offer_reserved', {'variant': variant, 'live_activity': false});
      return expiresAt;
    }

    final started = await _start(
      copy: PromoOfferCopy.byVariant(variant),
      expiresAt: expiresAt,
      variant: variant,
    );

    _track('promo_offer_reserved', {
      'variant': variant,
      'live_activity': started,
    });

    return expiresAt;
  }

  /// Re-arms the Live Activity after a cold start if the window is still open
  /// (ActivityKit does not survive every termination path). Safe to call on
  /// every app resume — it is idempotent and never extends the deadline.
  Future<void> restoreIfNeeded() async {
    if (!Platform.isIOS) return;
    if (_restoredThisSession) return;
    _restoredThisSession = true;

    if (RevenueCatService.instance.isSubscriptionActive.value) {
      debugPrint('ℹ️ [PromoLA] restore skipped: subscriber');
      await end();
      return;
    }

    final expiresAt = await reservedExpiry();
    if (expiresAt == null) {
      debugPrint('ℹ️ [PromoLA] restore skipped: no reservation');
      return;
    }

    if (!expiresAt.isAfter(DateTime.now())) {
      debugPrint('ℹ️ [PromoLA] restore skipped: window closed ($expiresAt)');
      await end();
      return;
    }
    if (await isRunning) {
      debugPrint('ℹ️ [PromoLA] restore skipped: already running');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final variant = prefs.getString(_variantKey) ?? 'control';
    if (variant == 'control') {
      debugPrint('ℹ️ [PromoLA] restore skipped: control cohort');
      return;
    }

    debugPrint('🎁 [PromoLA] restoring activity until $expiresAt ($variant)');
    await _start(
      copy: PromoOfferCopy.byVariant(variant),
      expiresAt: expiresAt,
      variant: variant,
    );
  }

  /// The deadline of the current reservation, or null if none / expired.
  Future<DateTime?> reservedExpiry() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_expiresAtKey);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  Future<PromoOfferCopy> currentCopy() async {
    final prefs = await SharedPreferences.getInstance();
    return PromoOfferCopy.byVariant(prefs.getString(_variantKey));
  }

  /// Tears the activity down. Call on purchase, on restore, and on expiry.
  Future<void> end({bool immediately = true}) async {
    if (!Platform.isIOS) return;
    await _invoke<bool>('end', {'immediately': immediately});
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  Future<bool> _start({
    required PromoOfferCopy copy,
    required DateTime expiresAt,
    required String variant,
  }) async {
    if (!await isSupported) {
      debugPrint('⚠️ [PromoLA] start aborted: unsupported (iOS < 16.2, '
          'or the native bridge is not registered)');
      return false;
    }
    if (!await areActivitiesEnabled) {
      debugPrint('⚠️ [PromoLA] start aborted: Live Activities off in Settings');
      _track('promo_live_activity_blocked', {'reason': 'disabled_in_settings'});
      return false;
    }

    final id = await _invoke<String>('start', {
      'offerId': offeringId,
      'variant': variant,
      'headline': copy.headline,
      'subhead': copy.subhead,
      'ctaLabel': copy.ctaShort,
      'priceLabel': copy.priceLabel,
      'expiresAtMs': expiresAt.millisecondsSinceEpoch,
    });

    final started = id != null;
    debugPrint(started
        ? '✅ [PromoLA] activity started (id=$id)'
        : '❌ [PromoLA] Activity.request returned no id');
    if (started) {
      _track('promo_live_activity_started', {
        'variant': variant,
        'expires_at': expiresAt.toIso8601String(),
      });
    }
    return started;
  }

  Future<T?> _invoke<T>(String method, [Map<String, dynamic>? args]) async {
    try {
      return await _channel.invokeMethod<T>(method, args);
    } on PlatformException catch (e) {
      debugPrint('⚠️ [PromoLA] $method failed: ${e.code} ${e.message}');
      return null;
    } on MissingPluginException {
      // Bridge not registered (Android, or an older build).
      return null;
    }
  }

  void _track(String event, Map<String, dynamic> properties) {
    if (!PostHogService.instance.isReady) return;
    try {
      PostHogService.instance.events.trackCustom(event, properties);
    } catch (e) {
      debugPrint('⚠️ [PromoLA] analytics failed for $event: $e');
    }
  }
}
