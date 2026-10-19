import 'package:faithlock/app_routes.dart';
import 'package:faithlock/config/app_config.dart';
import 'package:faithlock/config/env.dart';
import 'package:faithlock/core/localization/app_translations.dart';
import 'package:faithlock/core/navigation/app_route_observer.dart';
import 'package:faithlock/core/theme/export.dart';
import 'package:faithlock/features/faithlock/services/faithlock_database_service.dart';
import 'package:faithlock/features/faithlock/services/unlock_timer_service.dart';
import 'package:faithlock/features/onboarding/screens/initial_route_screen.dart';
import 'package:faithlock/services/analytics/meta/export.dart';
import 'package:faithlock/services/analytics/posthog/export.dart';
import 'package:faithlock/services/analytics/tiktok/export.dart';
import 'package:faithlock/services/app_config_service.dart';
import 'package:faithlock/services/app_launch_service.dart';
import 'package:faithlock/services/auto_navigation_service.dart';
import 'package:faithlock/services/deep_link_service.dart';
import 'package:faithlock/services/live_activity/promo_live_activity_service.dart';
import 'package:faithlock/services/notifications/local_notification_service.dart';
import 'package:faithlock/services/notifications/notification_navigation_service.dart';
import 'package:faithlock/services/notifications/daily_verse_notification_service.dart';
import 'package:faithlock/services/notifications/winback_notification_service.dart';
import 'package:faithlock/services/subscription/revenuecat_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('🚀 FaithLock: Starting app initialization...');

  await Future.wait([
    _initializeDatabase(),
    _initializeSupabase(),
    SystemChrome.setPreferredOrientations(<DeviceOrientation>[
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]),
  ]);

  debugPrint('✅ Critical services initialized');

  // Remote feature flags (Supabase app_config) — fetched at launch so the
  // paywall variant is known before any screen reads it. Resilient: failures
  // fall back to compiled-in defaults.
  await AppConfigService.instance.load();

  // Load saved locale before running app
  Locale? savedLocale;
  try {
    final prefs = await SharedPreferences.getInstance();
    final savedLang = prefs.getString('app_language');
    if (savedLang == 'fr') {
      savedLocale = const Locale('fr', 'FR');
    } else if (savedLang == 'en') {
      savedLocale = const Locale('en', 'US');
    }
    debugPrint('✅ Saved locale loaded: $savedLang');
  } catch (e) {
    debugPrint('⚠️ Error loading saved locale: $e');
  }

  _initializeNonCriticalServices();

  runApp(App(savedLocale: savedLocale));
}

/// Initializes Supabase and ensures an anonymous `authenticated` session.
///
/// Reads on the `prayers` table are gated by RLS to the `authenticated` role,
/// so an anonymous sign-in is required — otherwise the repository receives an
/// empty list and falls back to mock data. Failures degrade gracefully (mock
/// data) and never crash boot.
Future<void> _initializeSupabase() async {
  // Skip when credentials are still placeholders (e.g. fresh clone / CI).
  if (Env.supabaseUrl.contains('YOUR_PROJECT') ||
      Env.supabaseAnonKey.contains('YOUR_SUPABASE')) {
    debugPrint(
        '⚠️ Supabase credentials not configured → skipping init (mock data)');
    return;
  }

  try {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
    );

    // Sign in anonymously so reads carry the `authenticated` session JWT.
    if (Supabase.instance.client.auth.currentSession == null) {
      await Supabase.instance.client.auth.signInAnonymously();
      debugPrint('✅ Supabase anonymous session established');
    } else {
      debugPrint('✅ Supabase session restored');
    }
    debugPrint('✅ Supabase initialized');
  } catch (e) {
    // Degrade gracefully to mock data — never block or crash boot.
    debugPrint('⚠️ Supabase initialization failed: $e');
  }
}

Future<void> _initializeDatabase() async {
  try {
    final FaithLockDatabaseService db = FaithLockDatabaseService();
    await db.database.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw Exception('Database initialization timed out after 10 seconds');
      },
    );
    debugPrint('✅ Database initialized');
  } catch (e, stackTrace) {
    debugPrint('❌ Database initialization failed: $e');
    debugPrint('Stack trace: $stackTrace');
    // Don't rethrow - allow app to continue without database
    // The app can handle missing data gracefully
  }
}

void _initializeNonCriticalServices() {
  Future.microtask(() async {
    debugPrint('⏳ Loading non-critical services in background...');

    // Initialize LocalNotificationService for handling notification taps
    // This does NOT request permissions - only sets up the tap handler
    try {
      final LocalNotificationService notificationService =
          LocalNotificationService();
      await notificationService.initialize();
      debugPrint('✅ LocalNotificationService initialized');
    } catch (e) {
      debugPrint('⚠️ LocalNotificationService initialization failed: $e');
    }

    // Initialize NotificationNavigationService to handle iOS MethodChannel navigation
    try {
      final NotificationNavigationService navService =
          NotificationNavigationService();
      await navService.initialize();
      debugPrint('✅ NotificationNavigationService initialized');
    } catch (e) {
      debugPrint('⚠️ NotificationNavigationService initialization failed: $e');
    }

    try {
      final PostHogService postHog = PostHogService.instance;
      await postHog.init(
        customApiKey: Env.postHogApiKey,
        environment: kDebugMode ? 'development' : 'production',
        enableDebug: kDebugMode,
      );
      debugPrint('✅ PostHog initialized');

      // Link every event to the stable (anonymous) Supabase user so analytics
      // attach to one person across launches, and stamp "user since" = the
      // account's creation date. Guarded: Supabase may be skipped (placeholder
      // creds) and its `.instance` getter throws when uninitialized.
      try {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null && postHog.isReady) {
          await postHog.users.identify(
            userId: user.id,
            properties: {
              if (user.createdAt.isNotEmpty) 'user_since': user.createdAt,
            },
          );
          debugPrint('✅ PostHog identified user ${user.id}');
        }
      } catch (e) {
        debugPrint('⚠️ PostHog identify skipped: $e');
      }
    } catch (e) {
      debugPrint('⚠️ PostHog initialization failed: $e');
    }

    try {
      final TikTokService tiktok = TikTokService.instance;
      await tiktok.init(
        iosAppId: Env.tiktokIosAppId,
        tiktokIosId: Env.tiktokIosId,
        androidAppId: Env.tiktokAndroidAppId,
        tiktokAndroidId: Env.tiktokAndroidId,
        enableDebug: kDebugMode,
      );
      debugPrint('✅ TikTok Events SDK initialized');
    } catch (e) {
      debugPrint('⚠️ TikTok Events SDK initialization failed: $e');
    }

    try {
      // Meta App Events. App ID + client token are read from Info.plist
      // (iOS) and AndroidManifest (Android). Advertiser tracking stays
      // disabled until ATT is granted via MetaService.requestTracking().
      await MetaService.instance.init(enableDebug: kDebugMode);
      debugPrint('✅ Meta App Events SDK initialized');
    } catch (e) {
      debugPrint('⚠️ Meta App Events SDK initialization failed: $e');
    }

    try {
      // RevenueCat
      final RevenueCatService revenueCat = Get.put(RevenueCatService());
      await revenueCat.initialize(
        apiKey: Env.revenueCatApiKey,
        enableDebugLogs: kDebugMode,
      );
      debugPrint('✅ RevenueCat initialized');
    } catch (e) {
      debugPrint('⚠️ RevenueCat initialization failed: $e');
    }

    try {
      // Deep Links — required for the Live Activity tap (faithlock://promo)
      // and for prayer/unlock notification links to route anywhere.
      final DeepLinkService deepLinkService = DeepLinkService();
      await deepLinkService.initialize();
      debugPrint('✅ DeepLinkService initialized');
    } catch (e) {
      debugPrint('⚠️ DeepLinkService initialization failed: $e');
    }

    try {
      // Re-arms the welcome-offer Live Activity if its window is still open.
      // Never starts one on its own — see PromoLiveActivityService.
      await PromoLiveActivityService.instance.restoreIfNeeded();
    } catch (e) {
      debugPrint('⚠️ Promo Live Activity restore failed: $e');
    }

    // Win-back: check if sequence completed (after RevenueCat)
    try {
      await WinBackNotificationService().checkAndMarkCompleted();
      debugPrint('✅ WinBackNotificationService checked');
    } catch (e) {
      debugPrint('⚠️ WinBackNotificationService check failed: $e');
    }

    // Daily verse: reschedule upcoming notifications on each app launch
    try {
      await DailyVerseNotificationService().scheduleUpcoming();
      debugPrint('✅ DailyVerseNotificationService scheduled');
    } catch (e) {
      debugPrint('⚠️ DailyVerseNotificationService scheduling failed: $e');
    }

    try {
      // Unlock Timer Service
      final UnlockTimerService unlockTimerService = UnlockTimerService();
      unlockTimerService.initialize();
      debugPrint('✅ UnlockTimerService initialized');
    } catch (e) {
      debugPrint('⚠️ UnlockTimerService initialization failed: $e');
    }

    try {
      // App Launch Service - set as natural launch by default
      final AppLaunchService launchService = AppLaunchService();
      await launchService.setLaunchSource(AppLaunchService.sourceNatural);
      debugPrint('✅ AppLaunchService initialized (natural launch)');
    } catch (e) {
      debugPrint('⚠️ AppLaunchService initialization failed: $e');
    }

    debugPrint('✅ All non-critical services loaded');
  });
}

// Function removed - notification permissions are now requested during onboarding
// See: lib/features/onboarding/ for permission flow

class App extends StatefulWidget {
  final Locale? savedLocale;

  const App({super.key, this.savedLocale});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  void initState() {
    super.initState();

    // Auto-navigation is now handled by InitialRouteScreen
    // This prevents double navigation logic
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPrayerNavigation();
    });
  }

  Future<void> _checkPrayerNavigation() async {
    // Only check for prayer navigation flag
    // Don't interfere with InitialRouteScreen's routing logic
    try {
      final autoNavService = AutoNavigationService();
      await autoNavService.checkAndNavigate();
    } catch (e) {
      debugPrint('⚠️ Error checking prayer navigation: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppConfig.appName,
      theme: FastTheme.light,
      darkTheme: FastTheme.dark,
      themeMode:
          FastTheme.isDarkMode(context) ? ThemeMode.dark : ThemeMode.light,
      debugShowCheckedModeBanner: false,
      initialBinding: AppBindings(),
      navigatorObservers: [appRouteObserver],
      getPages: AppRoutes.getPages(),
      home: InitialRouteScreen(),
      translations: AppTranslations(),
      localizationsDelegates: const <LocalizationsDelegate<Object>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        DefaultCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppConfig.supportedLocales,
      // Default to English unless the user has explicitly picked a language.
      // (Don't follow the device locale — onboarding/copy is authored in EN
      // and the in-app language toggle owns the choice from there.)
      locale: widget.savedLocale ?? AppConfig.defaultLocale,
      fallbackLocale: AppConfig.defaultLocale,
    );
  }
}
