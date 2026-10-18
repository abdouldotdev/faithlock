import 'dart:async';

import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:faithlock/services/analytics/posthog/export.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// AppsFlyer attribution service — answers "where did this install come from".
///
/// Singleton service following the same pattern as [TikTokService] /
/// [MetaService]. All calls are wrapped in try/catch: attribution failures
/// must never break the app.
///
/// ## Revenue lives in RevenueCat, not here
///
/// Trials, purchases and renewals are sent to AppsFlyer server-side by the
/// RevenueCat → AppsFlyer integration (renewals happen while the app is
/// closed, a client event would miss them). This service only links the two
/// by setting `$appsflyerId` on the RevenueCat customer. Do NOT log
/// `af_purchase` / `af_subscribe` from the client: it would double count.
///
/// ## ATT
///
/// The SDK 7 plugin has no `waitForATTUserAuthorization`. The first session is
/// held back (up to [_attWaitTimeout]) while the ATT prompt is still pending,
/// so the install carries the IDFA when the user grants it. Call
/// [onTrackingAuthorizationResolved] right after the ATT prompt.
class AppsFlyerService {
  static final AppsFlyerService instance = AppsFlyerService._internal();
  AppsFlyerService._internal();

  /// Same budget as AppsFlyer's former `waitForATTUserAuthorization(60)`.
  static const Duration _attWaitTimeout = Duration(seconds: 60);

  final AppsFlyerSdk _sdk = AppsFlyerSdk.instance;
  final Completer<void> _attResolved = Completer<void>();
  bool _initialized = false;
  bool _firstSessionSent = false;

  bool get isInitialized => _initialized;

  /// Initialize the SDK and start reporting sessions.
  ///
  /// [customerUserId] should be the stable Supabase user id, so AppsFlyer raw
  /// data joins with PostHog / Supabase. Call after RevenueCat is configured.
  Future<void> init({
    required String devKey,
    required String appId,
    String? customerUserId,
    bool enableDebug = false,
  }) async {
    if (_initialized) return;
    if (devKey.isEmpty) {
      debugPrint('AppsFlyer dev key missing → skipping init');
      return;
    }

    try {
      if (enableDebug) await _sdk.enableDebug(true);
      await _sdk.init(devKey: devKey, appId: appId);

      // SDK 7 keeps these in memory only: re-applied on every cold start.
      if (customerUserId != null && customerUserId.isNotEmpty) {
        await _sdk.setCustomerUserId(customerUserId);
      }

      await _sdk.registerConversionListener(
        onConversionDataSuccess: _onConversionData,
        onConversionDataFail: (error) =>
            debugPrint('AppsFlyer conversion data failed: $error'),
      );

      // Registered last: the callback can fire immediately.
      await _sdk.registerSessionReadyListener(_onSessionReady);

      _initialized = true;
      debugPrint('AppsFlyer SDK initialized');

      await _linkRevenueCat();
    } catch (e) {
      debugPrint('AppsFlyer SDK initialization failed: $e');
    }
  }

  /// Call once the ATT prompt has been answered (granted or not).
  Future<void> onTrackingAuthorizationResolved() async {
    if (!_attResolved.isCompleted) _attResolved.complete();
    // Re-collect so RevenueCat forwards the IDFA when it was just granted.
    try {
      await Purchases.collectDeviceIdentifiers();
    } catch (e) {
      debugPrint('RevenueCat collectDeviceIdentifiers failed: $e');
    }
  }

  Future<void> _onSessionReady() async {
    if (!_firstSessionSent) {
      _firstSessionSent = true;
      await _waitForAttIfPending();
    }
    try {
      await _sdk.start();
    } catch (e) {
      debugPrint('AppsFlyer start failed: $e');
    }
  }

  Future<void> _waitForAttIfPending() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return;
    try {
      // permission_handler reports "not determined" as `denied` on iOS.
      final status = await Permission.appTrackingTransparency.status;
      if (!status.isDenied) return;
      await _attResolved.future.timeout(_attWaitTimeout, onTimeout: () {});
    } catch (e) {
      debugPrint('AppsFlyer ATT wait failed: $e');
    }
  }

  /// Sets `$appsflyerId` on the RevenueCat customer so server-side revenue
  /// events are attributed to the right install.
  Future<void> _linkRevenueCat() async {
    try {
      final uid = await _sdk.getAppsFlyerUID();
      if (uid == null || uid.isEmpty) return;
      await Purchases.setAppsflyerID(uid);
      await Purchases.collectDeviceIdentifiers();
      debugPrint('RevenueCat linked to AppsFlyer ($uid)');
    } catch (e) {
      debugPrint('RevenueCat ↔ AppsFlyer link failed: $e');
    }
  }

  /// Mirrors the install source into PostHog (first touch) and RevenueCat,
  /// so funnels and revenue can be split by acquisition channel.
  Future<void> _onConversionData(Map<String, dynamic> data) async {
    // The payload is wrapped in `payload` on some SDK versions.
    final raw = data['payload'] is Map ? data['payload'] as Map : data;
    final Map<String, dynamic> payload = Map<String, dynamic>.from(raw);
    if (payload['is_first_launch'] != true &&
        payload['is_first_launch'] != 'true') {
      return;
    }

    final String status = '${payload['af_status'] ?? 'unknown'}';
    final String mediaSource = _str(payload['media_source']) ??
        (status == 'Organic' ? 'organic' : 'unknown');
    final String? campaign = _str(payload['campaign']);
    final String? adSet = _str(payload['adset']) ?? _str(payload['adgroup']);
    final String? ad = _str(payload['ad']) ?? _str(payload['af_ad']);
    final String? keyword = _str(payload['af_keywords']);

    debugPrint('AppsFlyer install: $status / $mediaSource / $campaign');

    try {
      final postHog = PostHogService.instance;
      if (postHog.isReady) {
        final props = <String, Object>{
          'af_status': status,
          'af_media_source': mediaSource,
          if (campaign != null) 'af_campaign': campaign,
          if (_str(payload['campaign_id']) != null)
            'af_campaign_id': _str(payload['campaign_id'])!,
          if (adSet != null) 'af_adset': adSet,
          if (ad != null) 'af_ad': ad,
          if (keyword != null) 'af_keyword': keyword,
        };
        await Posthog().identify(
          userId: await Posthog().getDistinctId(),
          userPropertiesSetOnce: props,
        );
        await postHog.events.trackCustom('install_attributed', props);
      }
    } catch (e) {
      debugPrint('PostHog attribution sync failed: $e');
    }

    try {
      await Purchases.setMediaSource(mediaSource);
      if (campaign != null) await Purchases.setCampaign(campaign);
      if (adSet != null) await Purchases.setAdGroup(adSet);
      if (ad != null) await Purchases.setAd(ad);
      if (keyword != null) await Purchases.setKeyword(keyword);
    } catch (e) {
      debugPrint('RevenueCat attribution sync failed: $e');
    }
  }

  static String? _str(Object? value) {
    if (value == null) return null;
    final s = '$value'.trim();
    return s.isEmpty || s == 'null' ? null : s;
  }

  // ---------------------------------------------------------------------------
  // Funnel events (non-revenue only — see class doc)
  // ---------------------------------------------------------------------------

  Future<void> trackEvent(String name, {Map<String, dynamic>? values}) async {
    if (!_initialized) return;
    try {
      await _sdk.logEvent(name, eventValues: values);
      if (kDebugMode) debugPrint('AppsFlyer event: $name');
    } catch (e) {
      debugPrint('AppsFlyer event tracking failed: $e');
    }
  }

  Future<void> trackCompleteRegistration({String? method}) =>
      trackEvent('af_complete_registration', values: {
        if (method != null) 'af_registration_method': method,
      });
}
