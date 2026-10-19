import 'package:faithlock/core/helpers/export.dart';
import 'package:faithlock/services/rate_app_service.dart';
import 'package:faithlock/services/subscription/revenuecat_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:faithlock/services/analytics/posthog/export.dart';

/// Controller for managing application settings
class SettingsController extends GetxController {
  static const String _keyDarkMode = 'dark_mode';
  static const String _keyNotifications = 'notifications_enabled';
  static const String _keyLanguage = 'app_language';
  static const String _keyBiometric = 'biometric_enabled';
  static const String _keyAnalytics = 'analytics_enabled';
  static const String _keyCrashReporting = 'crash_reporting_enabled';

  late final SharedPreferences _prefs;

  final PostHogService _analytics = PostHogService.instance;

  // Observable settings
  final RxBool isDarkMode = false.obs;
  final RxBool notificationsEnabled = true.obs;
  final RxString appLanguage = 'en'.obs;
  final RxBool biometricEnabled = false.obs;
  final RxBool analyticsEnabled = true.obs;
  final RxBool crashReportingEnabled = true.obs;

  // App version info
  final RxString appVersion = '1.0.0'.obs;
  final RxString buildNumber = '1'.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeSettings();
  }

  Future<void> _initializeSettings() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadSettings();
  }

  Future<void> _loadSettings() async {
    // Load settings from persistent storage
    isDarkMode.value = _prefs.getBool(_keyDarkMode) ?? false;
    notificationsEnabled.value = _prefs.getBool(_keyNotifications) ?? true;
    appLanguage.value = _prefs.getString(_keyLanguage) ?? 'en';
    biometricEnabled.value = _prefs.getBool(_keyBiometric) ?? false;
    analyticsEnabled.value = _prefs.getBool(_keyAnalytics) ?? true;
    crashReportingEnabled.value = _prefs.getBool(_keyCrashReporting) ?? true;

    // Apply settings
    Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);

    // Analytics settings are handled in the analytics service
  }

  // Theme settings
  Future<void> toggleDarkMode(bool value) async {
    isDarkMode.value = value;
    await _prefs.setBool(_keyDarkMode, value);
    Get.changeThemeMode(value ? ThemeMode.dark : ThemeMode.light);
  }

  // Notification settings
  Future<void> toggleNotifications(bool value) async {
    notificationsEnabled.value = value;
    await _prefs.setBool(_keyNotifications, value);
  }

  // Language settings
  Future<void> changeLanguage(String languageCode) async {
    final previous = appLanguage.value;
    appLanguage.value = languageCode;
    await _prefs.setString(_keyLanguage, languageCode);

    if (_analytics.isReady) {
      _analytics.events.trackCustom('language_changed', {
        'language': languageCode,
        'previous': previous,
      });
    }

    // Update app locale
    final locale = Locale(languageCode);
    Get.updateLocale(locale);
  }

  // Security settings
  Future<void> toggleBiometric(bool value) async {
    biometricEnabled.value = value;
    await _prefs.setBool(_keyBiometric, value);
  }

  // Privacy settings
  Future<void> toggleAnalytics(bool value) async {
    analyticsEnabled.value = value;
    await _prefs.setBool(_keyAnalytics, value);

    // Update analytics opt-out status
  }

  Future<void> toggleCrashReporting(bool value) async {
    crashReportingEnabled.value = value;
    await _prefs.setBool(_keyCrashReporting, value);
  }

  // Support actions
  Future<void> rateApp() async {
    RateAppService().showRatingOnProfile();
  }

  Future<void> contactSupport() async {
    const String email = 'faithlock@appbiz-studio.com';
    const String subject = 'Support Request';
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': subject,
        'body': 'App Version: ${appVersion.value} (${buildNumber.value})\n\n',
      },
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      UIHelper.showErrorSnackBar(
        'Could not open email client',
      );
    }
  }

  Future<void> openPrivacyPolicy() async {
    const String privacyUrl =
        'https://appbiz-studio.com/apps/faithlock/privacy/';
    final Uri uri = Uri.parse(privacyUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> openTerms() async {
    const String termsUrl = 'https://appbiz-studio.com/apps/faithlock/terms/';
    final Uri uri = Uri.parse(termsUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> openTermsOfService() async {
    const String termsUrl = 'https://faithlock.com/terms';
    final Uri uri = Uri.parse(termsUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> shareApp() async {
    UIHelper.showSuccessSnackBar('Share feature coming soon!');
  }

  // Subscription management
  Future<void> manageSubscription() async {
    try {
      // Check if user has an active subscription
      final revenueCatService = RevenueCatService.instance;

      if (!revenueCatService.isInitialized) {
        UIHelper.showErrorSnackBar(
          'Subscription service not available. Please try again later.',
        );
        return;
      }

      // Get customer info to access subscription management URL
      final customerInfo = await Purchases.getCustomerInfo();
      final managementURL = customerInfo.managementURL;

      if (managementURL != null) {
        final uri = Uri.parse(managementURL);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          UIHelper.showErrorSnackBar('Could not open subscription management');
        }
      } else {
        UIHelper.showErrorSnackBar(
          'No active subscription found',
        );
      }
    } catch (e) {
      print('Error opening subscription management: $e');
      UIHelper.showErrorSnackBar(
        'Could not open subscription management',
      );
    }
  }

  // Clear all app data
  Future<void> clearAppData() async {
    await _prefs.clear();
    // TODO: Clear secure storage when available

    // Reset to defaults
    await _loadSettings();
  }
}
