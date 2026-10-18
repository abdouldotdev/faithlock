import 'package:faithlock/features/onboarding/screens/onboarding_summary_screen.dart';
import 'package:faithlock/features/paywall/screens/subscription_expired_screen.dart';
import 'package:faithlock/services/subscription/revenuecat_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// Service to guard premium features behind paywall
/// Prevents bypass of paywall by checking subscription status
class PaywallGuardService {
  static final PaywallGuardService _instance = PaywallGuardService._internal();
  factory PaywallGuardService() => _instance;
  PaywallGuardService._internal();

  /// RevenueCat is configured in the background at launch, possibly after the
  /// first screen runs this guard. Reading entitlements before that returns
  /// "no subscription" and would send paying users to the paywall.
  static const Duration _initTimeout = Duration(seconds: 8);

  RevenueCatService get _revenueCat => RevenueCatService.instance;

  /// Check if user has active subscription
  /// If not, redirect to appropriate screen (expired or paywall)
  Future<bool> checkSubscriptionAccess({
    String? placementId,
    bool showPaywallIfInactive = true,
  }) async {
    try {
      debugPrint('🔒 [PaywallGuard] Checking subscription access...');

      await _waitForRevenueCat();
      final hasSubscription = _revenueCat.hasAnyActiveSubscription;

      if (hasSubscription) {
        debugPrint('✅ [PaywallGuard] Active subscription found');
        return true;
      }

      debugPrint('⚠️ [PaywallGuard] No active subscription');

      if (showPaywallIfInactive) {
        // Check if user had a subscription that expired
        final expiredInfo = await _checkExpiredSubscription();

        if (expiredInfo.hadSubscription) {
          debugPrint(
              '🔄 [PaywallGuard] Expired subscription detected - showing expired screen');
          Get.offAll(
            () => SubscriptionExpiredScreen(
              wasTrialUser: expiredInfo.wasTrialUser,
              expirationDate: expiredInfo.expirationDate,
            ),
          );
        } else {
          debugPrint('🚪 [PaywallGuard] Never subscribed - showing paywall...');
          Get.offAll(() => const OnboardingSummaryScreen());
        }
      }

      return false;
    } catch (e) {
      debugPrint('❌ [PaywallGuard] Error checking subscription: $e');
      return false;
    }
  }

  Future<void> _waitForRevenueCat() async {
    final deadline = DateTime.now().add(_initTimeout);
    while (!_revenueCat.isInitialized && DateTime.now().isBefore(deadline)) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    if (!_revenueCat.isInitialized) {
      debugPrint('⚠️ [PaywallGuard] RevenueCat not initialized after '
          '${_initTimeout.inSeconds}s');
    }
  }

  /// Check if user had an expired subscription
  Future<_ExpiredSubscriptionInfo> _checkExpiredSubscription() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      final allEntitlements = customerInfo.entitlements.all;

      // Check if user has any past entitlements (active or inactive)
      if (allEntitlements.isEmpty) {
        return _ExpiredSubscriptionInfo(
          hadSubscription: false,
          wasTrialUser: false,
        );
      }

      // Find the most recent entitlement
      final sortedEntitlements = allEntitlements.values.toList()
        ..sort((a, b) {
          final aDate = DateTime.parse(a.latestPurchaseDate);
          final bDate = DateTime.parse(b.latestPurchaseDate);
          return bDate.compareTo(aDate);
        });

      final mostRecentEntitlement = sortedEntitlements.first;

      // Check if user ever had an active entitlement but it's now expired
      final hadActiveSubscription = !mostRecentEntitlement.isActive &&
          mostRecentEntitlement.expirationDate != null;

      if (hadActiveSubscription) {
        // Determine if it was a trial
        final purchaseDate =
            DateTime.parse(mostRecentEntitlement.originalPurchaseDate);
        final expirationDate =
            DateTime.parse(mostRecentEntitlement.expirationDate!);
        final subscriptionDuration = expirationDate.difference(purchaseDate);

        // Consider it a trial if it lasted <= 14 days
        final wasTrialUser = subscriptionDuration.inDays <= 14;

        return _ExpiredSubscriptionInfo(
          hadSubscription: true,
          wasTrialUser: wasTrialUser,
          expirationDate: expirationDate,
        );
      }

      return _ExpiredSubscriptionInfo(
        hadSubscription: false,
        wasTrialUser: false,
      );
    } catch (e) {
      debugPrint('❌ [PaywallGuard] Error checking expired subscription: $e');
      return _ExpiredSubscriptionInfo(
        hadSubscription: false,
        wasTrialUser: false,
      );
    }
  }

  /// Check subscription status without navigation
  bool hasActiveSubscription() {
    return _revenueCat.hasAnyActiveSubscription;
  }

  /// Get subscription status for display
  SubscriptionStatus getStatus() {
    return _revenueCat.getSubscriptionStatus();
  }
}

/// Helper class to track expired subscription info
class _ExpiredSubscriptionInfo {
  final bool hadSubscription;
  final bool wasTrialUser;
  final DateTime? expirationDate;

  _ExpiredSubscriptionInfo({
    required this.hadSubscription,
    required this.wasTrialUser,
    this.expirationDate,
  });
}
