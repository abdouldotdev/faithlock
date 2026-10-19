import 'dart:async';

import 'package:faithlock/services/analytics/posthog/export.dart';
import 'package:faithlock/services/live_activity/promo_live_activity_service.dart';
import 'package:faithlock/services/subscription/revenuecat_service.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:purchases_flutter/purchases_flutter.dart' hide PurchaseResult;

/// Drives the `$1 first week → annual` welcome offer page.
///
/// The offer itself lives entirely in App Store Connect + RevenueCat: the
/// annual product carries a **paid introductory offer** (1 week, $1, pay up
/// front). This controller only picks that package and renders honest copy
/// around it — the intro price, the renewal price, and the real deadline.
class PromoOfferController extends GetxController {
  final RevenueCatService _revenueCat = RevenueCatService.instance;
  final PromoLiveActivityService _liveActivity =
      PromoLiveActivityService.instance;

  /// Where the user came from: `live_activity`, `home_card`, `deeplink`…
  final String source;

  PromoOfferController({this.source = 'unknown'});

  final RxBool isLoading = true.obs;
  final RxBool isPurchasing = false.obs;
  final RxString errorMessage = ''.obs;

  /// Remaining time on the reservation. Zero once expired.
  final Rx<Duration> remaining = Duration.zero.obs;
  final RxBool hasExpired = false.obs;

  final Rx<PromoOfferCopy> copy = PromoOfferCopy.gift.obs;

  Package? _package;
  Package? get package => _package;
  StoreProduct? get product => _package?.storeProduct;

  DateTime? _expiresAt;
  Timer? _ticker;

  // ---------------------------------------------------------------------------
  // Display helpers
  // ---------------------------------------------------------------------------

  IntroductoryPrice? get _intro => product?.introductoryPrice;

  /// True when the intro period costs nothing — i.e. the product carries a free
  /// trial rather than the $1 paid intro. Both must read correctly: rendering a
  /// free trial as "$0.00" is the kind of detail that reads as a broken app.
  bool get isFreeIntro => (_intro?.price ?? -1) == 0;

  /// Localized intro price, e.g. "$1.00" / "Free" — falls back to the copy
  /// token when StoreKit metadata is unavailable (offline first paint).
  String get introPrice {
    final intro = _intro;
    if (intro == null) return copy.value.priceShort;
    return isFreeIntro ? 'Free' : intro.priceString;
  }

  /// The real intro duration from StoreKit, e.g. "7 days", "1 week".
  String get introPeriod {
    final intro = _intro;
    if (intro == null) return '7 days';

    final count = intro.periodNumberOfUnits;
    final unit = switch (intro.periodUnit) {
      PeriodUnit.day => 'day',
      PeriodUnit.week => 'week',
      PeriodUnit.month => 'month',
      PeriodUnit.year => 'year',
      _ => 'day',
    };
    return '$count ${count == 1 ? unit : '${unit}s'}';
  }

  /// One-line summary of what the user is actually about to get.
  ///
  /// Derived from StoreKit whenever the product is loaded, so the page can
  /// never promise something the store will not honour — the variant copy is
  /// only the pre-load placeholder.
  String get offerSummary {
    if (_intro == null) return copy.value.subhead;
    return isFreeIntro
        ? 'Free for your first $introPeriod'
        : '$introPrice for your first $introPeriod';
  }

  /// Button label. The price is not repeated here — it is already the largest
  /// thing on the screen, and a button that restates it reads as a second ask.
  String get ctaLabel =>
      isFreeIntro ? 'Start my free trial' : copy.value.ctaLabel;

  /// Final stretch of the window. Drives the countdown turning from warm to
  /// alarming — honest, because the offer really is about to go.
  bool get isEndingSoon =>
      !hasExpired.value &&
      remaining.value > Duration.zero &&
      remaining.value <= const Duration(minutes: 10);

  /// Localized renewal price, e.g. "$39.99".
  String get renewalPrice => product?.priceString ?? '—';

  /// Human renewal cadence for the disclosure line.
  String get renewalPeriod {
    final period = product?.subscriptionPeriod;
    if (period == null) return 'year';
    if (period.contains('Y')) return 'year';
    if (period.contains('M')) return 'month';
    if (period.contains('W')) return 'week';
    return 'period';
  }

  /// The mandated, unambiguous disclosure. Vague renewal terms are one of the
  /// most common paywall rejections under guideline 3.1.2.
  ///
  /// Empty until the real price is known — "Then — per year" states nothing and
  /// looks broken. The CTA stays disabled meanwhile, so no one can buy without
  /// having seen the terms.
  String get disclosure => product == null
      ? ''
      : 'Then $renewalPrice per $renewalPeriod. Cancel anytime in Settings.';

  /// Drops the hours segment under an hour: "58:04" reads as urgent in a way
  /// "00:58:04" does not.
  String get countdownLabel {
    final d = remaining.value;
    if (d <= Duration.zero) return '00:00';
    if (d.inHours == 0) {
      final m = d.inMinutes.toString().padLeft(2, '0');
      final s = (d.inSeconds % 60).toString().padLeft(2, '0');
      return '$m:$s';
    }
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void onInit() {
    super.onInit();
    _bootstrap();
  }

  @override
  void onClose() {
    _ticker?.cancel();
    super.onClose();
  }

  Future<void> _bootstrap() async {
    copy.value = await _liveActivity.currentCopy();

    // Arriving straight from a deep link on a fresh install: no reservation
    // yet, so create one now (the tap on the Live Activity *is* the intent).
    _expiresAt = await _liveActivity.reservedExpiry() ??
        await _liveActivity.reserveOffer();

    _startTicker();
    await _loadPackage();

    _track('promo_offer_viewed', {
      'source': source,
      'variant': copy.value.variant,
      'expired': hasExpired.value,
      'seconds_left': remaining.value.inSeconds,
    });
  }

  void _track(String event, Map<String, dynamic> properties) {
    if (!PostHogService.instance.isReady) return;
    PostHogService.instance.events.trackCustom(event, properties);
  }

  void _startTicker() {
    _tick();
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final expiry = _expiresAt;
    if (expiry == null) {
      remaining.value = Duration.zero;
      hasExpired.value = true;
      return;
    }
    final left = expiry.difference(DateTime.now());
    remaining.value = left.isNegative ? Duration.zero : left;

    if (left.isNegative && !hasExpired.value) {
      hasExpired.value = true;
      _ticker?.cancel();
      _liveActivity.end();
      _track('promo_offer_expired', {'source': source});
    }
  }

  /// RevenueCat's SDK raises a native `fatalError` — which Dart cannot catch —
  /// if it is queried before `Purchases.configure` has run. This page can be
  /// opened from a Live Activity on a cold start, so wait for configuration
  /// instead of assuming it; if it never comes, degrade to the error state
  /// rather than take the app down with us.
  Future<bool> _waitForRevenueCat({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (!_revenueCat.isInitialized && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    if (!_revenueCat.isInitialized) {
      debugPrint('⚠️ [PromoOffer] RevenueCat not configured — offer unavailable');
    }
    return _revenueCat.isInitialized;
  }

  Future<void> _loadPackage() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      if (!await _waitForRevenueCat()) {
        errorMessage.value = 'This offer is not available right now.';
        return;
      }

      // Never hang on the network: an offer page stuck on a spinner is worse
      // than one that admits it failed, and this page is reachable from a Lock
      // Screen tap where the user has no context for what went wrong.
      final offerings = await _revenueCat.getOfferings().timeout(
        const Duration(seconds: 10),
        onTimeout: () => <Offering>[],
      );
      Offering? offering;
      for (final o in offerings) {
        if (o.identifier == PromoLiveActivityService.offeringId) {
          offering = o;
          break;
        }
      }
      // Fall back to the default offering so the page is never a dead end if
      // the promo offering has not been published yet.
      offering ??= offerings.isNotEmpty ? offerings.first : null;

      if (offering == null || offering.availablePackages.isEmpty) {
        errorMessage.value = 'This offer is not available right now.';
        return;
      }

      _package = _pickAnnual(offering.availablePackages);
    } catch (e) {
      debugPrint('❌ [PromoOffer] failed to load package: $e');
      errorMessage.value = 'This offer is not available right now.';
    } finally {
      isLoading.value = false;
    }
  }

  /// The offer is an intro price on the *annual* product — prefer a package
  /// that actually carries an introductory price, then any annual one.
  Package _pickAnnual(List<Package> packages) {
    Package? annualWithIntro;
    Package? annual;

    for (final p in packages) {
      final period = p.storeProduct.subscriptionPeriod ?? '';
      final isAnnual = period.contains('Y') ||
          p.packageType == PackageType.annual;
      if (!isAnnual) continue;
      annual ??= p;
      if (p.storeProduct.introductoryPrice != null) {
        annualWithIntro ??= p;
      }
    }
    return annualWithIntro ?? annual ?? packages.first;
  }

  // ---------------------------------------------------------------------------
  // Purchase
  // ---------------------------------------------------------------------------

  Future<bool> purchase() async {
    final pkg = _package;
    if (pkg == null || isPurchasing.value) return false;

    isPurchasing.value = true;
    errorMessage.value = '';

    _track('promo_offer_cta_tapped', {
      'source': source,
      'variant': copy.value.variant,
      'product_id': pkg.storeProduct.identifier,
    });

    try {
      final result = await _revenueCat.purchaseSubscription(pkg);

      if (result.success) {
        await _liveActivity.end();
        _track('promo_offer_purchased', {
          'source': source,
          'variant': copy.value.variant,
          'product_id': pkg.storeProduct.identifier,
          'price': pkg.storeProduct.price,
        });
        return true;
      }

      // A user-cancelled purchase is not an error worth shouting about.
      final error = result.error ?? 'Purchase failed';
      if (!error.toLowerCase().contains('cancel')) {
        errorMessage.value = error;
      }
      _track('promo_offer_purchase_failed', {
        'source': source,
        'variant': copy.value.variant,
        'error': error,
      });
      return false;
    } finally {
      isPurchasing.value = false;
    }
  }

  Future<bool> restore() async {
    if (!await _waitForRevenueCat(timeout: const Duration(seconds: 2))) {
      errorMessage.value = 'This offer is not available right now.';
      return false;
    }
    isPurchasing.value = true;
    try {
      final result = await _revenueCat.restorePurchases();
      if (result.hasActiveSubscriptions) {
        await _liveActivity.end();
        return true;
      }
      errorMessage.value = 'No previous purchase found.';
      return false;
    } finally {
      isPurchasing.value = false;
    }
  }

  /// Dismissing the offer must also clear the Lock Screen card — leaving it up
  /// after an explicit "no" is exactly the nagging Apple objects to.
  Future<void> dismiss() async {
    _track('promo_offer_dismissed', {
      'source': source,
      'variant': copy.value.variant,
      'seconds_left': remaining.value.inSeconds,
    });
    await _liveActivity.end();
  }
}
