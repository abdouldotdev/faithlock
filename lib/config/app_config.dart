import 'package:flutter/material.dart';

class AppConfig {
  // Dev bypass - skip onboarding & paywall, go straight to home
  static const bool bypassPaywall = false;

  // V3 onboarding flag - flip to false to fall back to V2 instantly
  static const bool enableOnboardingV3 = true;

  // App information
  static const String appName = 'Fast App';
  static const String appVersion = '1.0.0';

  /// Public App Store listing — used by share / rate flows.
  static const String appStoreUrl =
      'https://apps.apple.com/us/app/faith-lock-bible-prayer-focus/id6754208209';

  // Localization
  static const Locale defaultLocale = Locale('en', 'US');
  static const List<Locale> supportedLocales = [
    Locale('en', 'US'),
    Locale('fr', 'FR'),
    Locale('pt', 'BR'),
    Locale('de', 'DE'),
    Locale('ja', 'JP'),
  ];

  static final AppFeatures appFeatures = AppFeatures();
}

class AppFeatures {
  // Authentication features
  final bool enableAnonAuth = false;

  // Profile management features
  final bool showProfile = false;
  final bool editProfile = false;
  final bool deleteAccount = true;

  /// "Your Journey" stats grid on the profile screen.
  final bool journeyStats = false;

  // User preferences features
  final bool pushNotifications = false;
  final bool languageSelection = true;
  final bool analyticsEnabled = false;
  final bool darkMode = false;
  final bool privacySettings = true;
  final bool termsSettings = true;

  // Support features
  final bool showHelpCenter = false;
  final bool showAppVersion = false;
}
