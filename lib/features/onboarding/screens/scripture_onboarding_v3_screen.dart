import 'package:faithlock/features/onboarding/controllers/scripture_onboarding_controller.dart';
import 'package:faithlock/features/onboarding/controllers/scripture_onboarding_v2_controller.dart';
import 'package:faithlock/features/onboarding/controllers/scripture_onboarding_v3_controller.dart';
import 'package:faithlock/features/onboarding/screens/step6_final_encouragement.dart';
import 'package:faithlock/features/onboarding/screens/step7_screen_time_permission.dart';
import 'package:faithlock/features/onboarding/screens/onboarding_summary_screen.dart';
import 'package:faithlock/features/onboarding/screens/step9_notification_permission.dart';
import 'package:faithlock/features/onboarding/screens/v2_daily_verses_setup.dart';
import 'package:faithlock/features/onboarding/screens/v3/v3_apps_and_rules.dart';
import 'package:faithlock/features/onboarding/screens/v3/v3_attribution.dart';
import 'package:faithlock/features/onboarding/screens/v3/v3_building_plan_loader.dart';
import 'package:faithlock/features/onboarding/screens/v3/v3_diagnostic_hours.dart';
import 'package:faithlock/features/onboarding/screens/v3/v3_diagnostic_question.dart';
import 'package:faithlock/features/onboarding/screens/v3/v3_dual_name_capture.dart';
import 'package:faithlock/features/onboarding/screens/v3/v3_fake_loader.dart';
import 'package:faithlock/features/onboarding/screens/v3/v3_personalization.dart';
import 'package:faithlock/features/onboarding/screens/v3/v3_diagnostic_prayer.dart';
import 'package:faithlock/features/onboarding/screens/v3/v3_reveal_screen.dart';
import 'package:faithlock/features/onboarding/screens/v3/v3_social_proof.dart';
import 'package:faithlock/features/onboarding/screens/v3/v3_welcome_carousel.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// V3 Onboarding - Laura's full vision (20 steps).
///
///   1. Welcome carousel (3 slides)
///   2. Diagnostic Q1 - peace/phone
///   3. Diagnostic Q2 - phone check frequency
///   4. Diagnostic Q3 - hours/day slider
///   5. Diagnostic Q4 - lonely → phone or faith
///   6. Diagnostic Q5 - silence
///   7. Diagnostic Q6 - missing self
///   8. Diagnostic Q7 - lost practice
///   9. Diagnostic Q8 - practice to build
///   10. Diagnostic Q9 - God seeing your week
///   11. Fake loader (anticipation)
///   12. Reveal (Opal-style)
///   13. Personalization (tradition + state + practices + moments)
///   14. Prayer intent (1×/2×/3×/More)
///   15. Apps & unblock rules
///   16. Dual name capture (Toby + before God)
///   17. Commitment seal (fingerprint, reused)
///   18. Screen Time permission (reused)
///   19. Social proof
///   20. Attribution → Building plan loader → V2FreeForYou paywall
class ScriptureOnboardingV3Screen extends StatefulWidget {
  const ScriptureOnboardingV3Screen({super.key});

  @override
  State<ScriptureOnboardingV3Screen> createState() =>
      _ScriptureOnboardingV3ScreenState();
}

class _ScriptureOnboardingV3ScreenState
    extends State<ScriptureOnboardingV3Screen> {
  late final ScriptureOnboardingV3Controller v3Controller;

  @override
  void initState() {
    super.initState();
    v3Controller = ScriptureOnboardingV3Controller();
    // Permanent so the controller survives the `Get.off` navigations at the end
    // of the flow (attribution → building-plan loader → summary). Otherwise
    // GetX auto-disposes it when this screen's route is popped, and the summary
    // screen's `Get.find<ScriptureOnboardingController>()` throws "not found".
    Get.put<ScriptureOnboardingController>(v3Controller, permanent: true);
    Get.put<ScriptureOnboardingV2Controller>(v3Controller, permanent: true);
    Get.put<ScriptureOnboardingV3Controller>(v3Controller, permanent: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Obx(() {
        final next = v3Controller.nextStep;
        switch (v3Controller.currentStep.value) {
          case 1:
            return V3WelcomeCarousel(onComplete: next);

          // ===== Diagnostic phase (Laura's 9 questions) =====
          case 2:
            return V3DiagnosticQuestion(
              onComplete: next,
              questionKey: 'peace_or_phone',
              question: 'onbScriptureV3_peaceOrPhone_question'.tr,
              options: [
                'onbScriptureV3_peaceOrPhone_option1'.tr,
                'onbScriptureV3_peaceOrPhone_option2'.tr,
                'onbScriptureV3_peaceOrPhone_option3'.tr,
              ],
            );

          case 3:
            return V3DiagnosticQuestion(
              onComplete: next,
              questionKey: 'phone_checks_per_day',
              question: 'onbScriptureV3_phoneChecksPerDay_question'.tr,
              options: [
                'onbScriptureV3_phoneChecksPerDay_option1'.tr,
                'onbScriptureV3_phoneChecksPerDay_option2'.tr,
                'onbScriptureV3_phoneChecksPerDay_option3'.tr,
                'onbScriptureV3_phoneChecksPerDay_option4'.tr,
                'onbScriptureV3_phoneChecksPerDay_option5'.tr,
              ],
            );

          case 4:
            return V3DiagnosticHours(onComplete: next);

          case 5:
            return V3DiagnosticQuestion(
              onComplete: next,
              questionKey: 'lonely_reach',
              question: 'onbScriptureV3_lonelyReach_question'.tr,
              options: [
                'onbScriptureV3_lonelyReach_option1'.tr,
                'onbScriptureV3_lonelyReach_option2'.tr,
                'onbScriptureV3_lonelyReach_option3'.tr,
              ],
            );

          case 6:
            return V3DiagnosticQuestion(
              onComplete: next,
              questionKey: 'silence_last',
              question: 'onbScriptureV3_silenceLast_question'.tr,
              options: [
                'onbScriptureV3_silenceLast_option1'.tr,
                'onbScriptureV3_silenceLast_option2'.tr,
                'onbScriptureV3_silenceLast_option3'.tr,
                'onbScriptureV3_silenceLast_option4'.tr,
                'onbScriptureV3_silenceLast_option5'.tr,
              ],
            );

          case 7:
            return V3DiagnosticQuestion(
              onComplete: next,
              questionKey: 'missing_self',
              question: 'onbScriptureV3_missingSelf_question'.tr,
              options: [
                'onbScriptureV3_missingSelf_option1'.tr,
                'onbScriptureV3_missingSelf_option2'.tr,
                'onbScriptureV3_missingSelf_option3'.tr,
                'onbScriptureV3_missingSelf_option4'.tr,
              ],
            );

          case 8:
            return V3DiagnosticQuestion(
              onComplete: next,
              questionKey: 'lost_practice',
              question: 'onbScriptureV3_lostPractice_question'.tr,
              options: [
                'onbScriptureV3_lostPractice_option1'.tr,
                'onbScriptureV3_lostPractice_option2'.tr,
                'onbScriptureV3_lostPractice_option3'.tr,
                'onbScriptureV3_lostPractice_option4'.tr,
                'onbScriptureV3_lostPractice_option5'.tr,
                'onbScriptureV3_lostPractice_option6'.tr,
              ],
            );

          case 9:
            return V3DiagnosticQuestion(
              onComplete: next,
              questionKey: 'practice_to_build',
              question: 'onbScriptureV3_practiceToBuild_question'.tr,
              options: [
                'onbScriptureV3_practiceToBuild_option1'.tr,
                'onbScriptureV3_practiceToBuild_option2'.tr,
                'onbScriptureV3_practiceToBuild_option3'.tr,
                'onbScriptureV3_practiceToBuild_option4'.tr,
                'onbScriptureV3_practiceToBuild_option5'.tr,
                'onbScriptureV3_practiceToBuild_option6'.tr,
              ],
            );

          case 10:
            return V3DiagnosticQuestion(
              onComplete: next,
              questionKey: 'god_sees_week',
              question: 'onbScriptureV3_godSeesWeek_question'.tr,
              options: [
                'onbScriptureV3_godSeesWeek_option1'.tr,
                'onbScriptureV3_godSeesWeek_option2'.tr,
                'onbScriptureV3_godSeesWeek_option3'.tr,
                'onbScriptureV3_godSeesWeek_option4'.tr,
                'onbScriptureV3_godSeesWeek_option5'.tr,
              ],
            );

          // ===== Reveal sequence =====
          case 11:
            return V3FakeLoader(onComplete: next);

          case 12:
            return V3RevealScreen(onComplete: next);

          // ===== Social proof (rides the post-reveal emotional moment, and
          // the testimonials echo "what you just shared" in the diagnostics) =====
          case 13:
            return V3SocialProof(onComplete: next);

          // ===== Personalization phase =====
          case 14:
            return V3Personalization(onComplete: next);

          // Prayer reminder times — right after personalization (they just
          // said how often they want to pray → now set when).
          case 15:
            return V2DailyVersesSetup(onComplete: next);

          case 16:
            return V3DiagnosticPrayer(onComplete: next);

          case 17:
            return V3AppsAndRules(onComplete: next);

          case 18:
            return V3DualNameCapture(onComplete: next);

          // ===== Commitment + permissions =====
          case 19:
            return Step6FinalEncouragement(onComplete: next);

          case 20:
            return Step7ScreenTimePermission(onComplete: next);

          // Notifications permission — right after Screen Time, so the two
          // permission asks are grouped (and we ask after times are set).
          case 21:
            return Step9NotificationPermission(onComplete: next);

          // ===== Attribution + paywall =====
          case 22:
            return V3Attribution(onComplete: () {
              // After attribution: theatrical "Building plan" loader, then mark
              // complete and route to the personalized summary (transformation
              // graph) which self-navigates to the paywall. (The lighter
              // "We want you to use FaithLock for free" interstitial is skipped.)
              Get.off(() => V3BuildingPlanLoader(
                    onComplete: () async {
                      await v3Controller.completeOnboarding();
                      Get.off(() => const OnboardingSummaryScreen());
                    },
                  ));
            });

          default:
            return const _ErrorScreen();
        }
      }),
          if (kDebugMode) _buildDebugSkip(),
        ],
      ),
    );
  }

  /// Debug-only overlay to jump forward through onboarding steps.
  Widget _buildDebugSkip() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      right: 12,
      child: Obx(() => GestureDetector(
            onTap: v3Controller.nextStep,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.85),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Skip ${v3Controller.currentStep.value}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.skip_next, color: Colors.white, size: 16),
                ],
              ),
            ),
          )),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Text(
          'onbScriptureV3_errorMessage'.tr,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
