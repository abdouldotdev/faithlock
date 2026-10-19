import 'package:faithlock/features/onboarding/controllers/scripture_onboarding_v2_controller.dart';
import 'package:faithlock/features/onboarding/controllers/scripture_onboarding_controller.dart';
import 'package:faithlock/features/onboarding/screens/step1_5_name_capture.dart';
import 'package:faithlock/features/onboarding/screens/step1_divine_revelation.dart';
import 'package:faithlock/features/onboarding/screens/step6_final_encouragement.dart';
import 'package:faithlock/features/onboarding/screens/step7_screen_time_permission.dart';
import 'package:faithlock/features/onboarding/screens/onboarding_welcome_screen.dart';
import 'package:faithlock/features/onboarding/screens/v2_self_confrontation.dart';
import 'package:faithlock/features/onboarding/screens/v2_goals_selection.dart';
import 'package:faithlock/features/onboarding/screens/v2_daily_verses_setup.dart';
import 'package:faithlock/features/onboarding/screens/v2_summary_screen.dart';
import 'package:faithlock/features/onboarding/screens/v2_commitment_level.dart';
import 'package:faithlock/features/onboarding/screens/v2_free_for_you.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

/// V2 Onboarding Screen - Optimized 11-step flow
///
/// Flow:
/// 1. Welcome (PASSIVE) - Judah intro
/// 2. Name/Age (ACTIVE) - reuse
/// 3. Divine Revelation (PASSIVE) - reuse
/// 4. Self-Confrontation V2 (ACTIVE) - lighter
/// 5. Goals Selection (ACTIVE) - with Judah
/// 6. Fingerprint Seal (ACTIVE) - reuse
/// 7. Screen Time Permission (ACTIVE) - reuse
/// 8. Daily Verses Setup (ACTIVE) - NEW
/// 9. Summary V2 (PASSIVE) - NEW
/// 10. How Committed (ACTIVE) - NEW
/// 11. Free For You (PASSIVE) - NEW → Paywall
class ScriptureOnboardingV2Screen extends StatefulWidget {
  const ScriptureOnboardingV2Screen({super.key});

  @override
  State<ScriptureOnboardingV2Screen> createState() =>
      _ScriptureOnboardingV2ScreenState();
}

class _ScriptureOnboardingV2ScreenState
    extends State<ScriptureOnboardingV2Screen> {
  late final ScriptureOnboardingV2Controller v2Controller;

  @override
  void initState() {
    super.initState();
    // Register V2 controller as both base type and V2 type
    // so OnboardingWrapper's Get.find<ScriptureOnboardingController>() works
    v2Controller = ScriptureOnboardingV2Controller();
    Get.put<ScriptureOnboardingController>(v2Controller);
    Get.put<ScriptureOnboardingV2Controller>(v2Controller);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Stack(
        children: [
          Obx(() {
            switch (v2Controller.currentStep.value) {
              case 1:
                return OnBoardingWelcomeScreen(
                  onComplete: () => v2Controller.nextStep(),
                );

              case 2:
                return Step1_5NameCapture(
                  
                  onComplete: () => v2Controller.nextStep(),
                );

              case 3:
                return Step1DivineRevelation(
                  onComplete: () => v2Controller.nextStep(),
                );

              case 4:
                return V2SelfConfrontation(
                  onComplete: () => v2Controller.nextStep(),
                );

              case 5:
                return V2GoalsSelection(
                  onComplete: () => v2Controller.nextStep(),
                );

              case 6:
                return Step6FinalEncouragement(
                  onComplete: () => v2Controller.nextStep(),
                );

              case 7:
                return Step7ScreenTimePermission(
                  onComplete: () => v2Controller.nextStep(),
                );

              case 8:
                return V2DailyVersesSetup(
                  onComplete: () => v2Controller.nextStep(),
                );

              case 9:
                return V2SummaryScreen(
                  onComplete: () => v2Controller.nextStep(),
                );

              case 10:
                return V2CommitmentLevel(
                  onComplete: () => v2Controller.nextStep(),
                );

              case 11:
                return const V2FreeForYou();

              default:
                return CupertinoPageScaffold(
                  backgroundColor: const Color(0xFF1C1C1E),
                  child: Center(
                    child: Text(
                      'Step ${v2Controller.currentStep.value} - Error',
                      style: const TextStyle(color: CupertinoColors.white),
                    ),
                  ),
                );
            }
          }),
        ],
      ),
    );
  }
}
