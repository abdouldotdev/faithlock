import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Remote app configuration fetched once at launch from the Supabase
/// `app_config` singleton row (id = 1). Exposes feature flags as reactive
/// values so the UI can bind to them with `Obx`.
///
/// Resilient by design: any failure (no network, RLS, placeholder creds)
/// leaves the compiled-in defaults in place and never blocks or crashes boot.
class AppConfigService extends GetxService {
  AppConfigService._();
  static final AppConfigService instance = AppConfigService._();

  /// `app_config.simple_paywall` — when true the paywall shows the simplified
  /// "Try it free" variant: the price-anchor ("cheaper than gum") line is
  /// hidden and the "no commitment, cancel anytime" badge sits above the CTA.
  final RxBool simplePaywall = false.obs;

  /// Fetches the config row. Call once at app launch, after Supabase has been
  /// initialized.
  Future<void> load() async {
    try {
      final row = await Supabase.instance.client
          .from('app_config')
          .select('simple_paywall')
          .limit(1)
          .maybeSingle()
          .timeout(const Duration(seconds: 5));

      if (row != null && row['simple_paywall'] is bool) {
        simplePaywall.value = row['simple_paywall'] as bool;
      }
      debugPrint('✅ AppConfig loaded: simplePaywall=${simplePaywall.value}');
    } catch (e) {
      debugPrint('⚠️ AppConfig load failed (using defaults): $e');
    }
  }
}
