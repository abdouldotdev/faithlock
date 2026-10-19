import 'package:faithlock/features/debug/screens/analytics_test_screen.dart';
import 'package:faithlock/features/faithlock/screens/permissions_onboarding_screen.dart';
import 'package:faithlock/features/faithlock/screens/relock_in_progress_screen.dart';
import 'package:faithlock/features/faithlock/screens/unlock_chooser_screen.dart';
import 'package:faithlock/features/faithlock/services/schedule_monitor_service.dart';
import 'package:faithlock/features/faithlock/services/screen_time_service.dart';
import 'package:faithlock/features/garden/screens/grace_garden_screen.dart';
import 'package:faithlock/features/onboarding/screens/onboarding_summary_screen.dart';
import 'package:faithlock/features/paywall/screens/cozy_promo_offer_screen.dart';
import 'package:faithlock/features/onboarding/screens/scripture_onboarding_screen.dart';
import 'package:faithlock/features/onboarding/screens/scripture_onboarding_v2_screen.dart';
import 'package:faithlock/features/prayer_audio/screens/prayer_library_screen.dart';
import 'package:faithlock/features/prayer_learning/export.dart';
import 'package:faithlock/navigation/screens/main_screen.dart';
import 'package:faithlock/services/storage/secure_storage_service.dart';
import 'package:get/get.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => StorageService());

    // Screen Time service for app blocking and unlocking
    Get.lazyPut(() => ScreenTimeService());

    // Initialize schedule monitoring service (will start when needed)
    Get.lazyPut(() => ScheduleMonitorService());
  }
}

class AppRoutes {
  static String getInitialRoute() {
    return root;
  }

  static Future<String> determineInitialRoute() async {
    return main;
  }

  static bool get needsInteractiveOnboarding => true;

  // Alternative: Use OnboardingHelper for dynamic selection
  // Instead of route-based, you can use:
  // OnboardingHelper.launch(needsUserInteraction: true/false)
  // OnboardingHelper.smartLaunch(needsPermissions: true, needsUserInput: false)

  static const String root = '/';
  static const String onboarding = '/onboarding';
  static const String scriptureOnboarding = '/scripture-onboarding';
  static const String scriptureOnboardingV2 = '/scripture-onboarding-v2';
  static const String permissionsOnboarding = '/permissions-onboarding';
  static const String onboardingSummary = '/onboarding-summary';
  static const String prayerLearning = '/prayer-learning';
  static const String unlockChooser = '/unlock-chooser';
  static const String main = '/main';
  static const String home = '/home';
  static const String analyticsTest = '/debug/analytics-test';
  static const String relockInProgress = '/relock-in-progress';
  static const String prayerAudioLibrary = '/prayer-audio-library';
  static const String garden = '/garden';
  static const String promoOffer = '/promo-offer';

  static List<GetPage<dynamic>> getPages() {
    return <GetPage<dynamic>>[
      GetPage<dynamic>(
        name: scriptureOnboarding,
        page: () => const ScriptureOnboardingScreen(),
      ),
      GetPage<dynamic>(
        name: scriptureOnboardingV2,
        page: () => const ScriptureOnboardingV2Screen(),
      ),
      GetPage<dynamic>(
        name: permissionsOnboarding,
        page: () => const PermissionsOnboardingScreen(),
      ),
      GetPage<dynamic>(
        name: onboardingSummary,
        page: () => const OnboardingSummaryScreen(),
      ),
      GetPage<dynamic>(
        name: prayerLearning,
        page: () => const PrayerLearningScreen(),
      ),
      GetPage<dynamic>(
        name: unlockChooser,
        page: () => const UnlockChooserScreen(),
      ),
      GetPage<dynamic>(name: main, page: () => const MainScreen()),
      GetPage<dynamic>(name: home, page: () => const MainScreen()),
      GetPage<dynamic>(
          name: analyticsTest, page: () => const AnalyticsTestScreen()),
      GetPage<dynamic>(
          name: relockInProgress, page: () => const RelockInProgressScreen()),
      GetPage<dynamic>(
        name: prayerAudioLibrary,
        page: () => const PrayerLibraryScreen(),
      ),
      GetPage<dynamic>(
        name: garden,
        page: () => const GraceGardenScreen(),
      ),
      GetPage<dynamic>(
        name: promoOffer,
        page: () {
          final args = Get.arguments;
          final source = (args is Map && args['source'] is String)
              ? args['source'] as String
              : 'unknown';
          return CozyPromoOfferScreen(source: source);
        },
        // Rises from the bottom like a sheet — it is an interruption, and it
        // should read as one the user can flick away.
        transition: Transition.downToUp,
      ),
    ];
  }
}
