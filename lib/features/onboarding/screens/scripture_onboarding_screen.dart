import 'package:faithlock/app_routes.dart';
import 'package:faithlock/features/onboarding/controllers/scripture_onboarding_controller.dart';
import 'package:faithlock/features/onboarding/screens/onboarding_summary_screen.dart';
import 'package:faithlock/features/onboarding/screens/step1_5_name_capture.dart';
import 'package:faithlock/features/onboarding/screens/step1_75_attribution.dart';
import 'package:faithlock/features/onboarding/screens/step1_divine_revelation.dart';
import 'package:faithlock/features/onboarding/screens/step2_self_confrontation.dart';
import 'package:faithlock/features/onboarding/screens/step3_eternal_warfare.dart';
import 'package:faithlock/features/onboarding/screens/step3_5_testimonials.dart';
import 'package:faithlock/features/onboarding/screens/step4_call_to_covenant.dart';
import 'package:faithlock/features/onboarding/screens/step6_final_encouragement.dart';
import 'package:faithlock/features/onboarding/screens/step7_screen_time_permission.dart';
import 'package:faithlock/features/onboarding/screens/step9_notification_permission.dart';
import 'package:faithlock/features/onboarding/screens/v2_free_for_you.dart';
import 'package:faithlock/features/onboarding/screens/onboarding_welcome_screen.dart';
import 'package:faithlock/features/onboarding/constants/onboarding_theme.dart';
import 'package:faithlock/features/onboarding/widgets/onboarding_wrapper.dart';
import 'package:faithlock/shared/widgets/mascot/judah_mascot.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Main Scripture Lock onboarding screen with personalized flow
class ScriptureOnboardingScreen extends StatelessWidget {
  const ScriptureOnboardingScreen({super.key});

  // Set to true to show skip button for testing
  static const bool isTesting = true;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ScriptureOnboardingController());

    return CupertinoPageScaffold(
      child: Stack(
        children: [
          Obx(() {
            switch (controller.currentStep.value) {
              case 1:
                return OnBoardingWelcomeScreen(
                  onComplete: () => controller.nextStep(),
                );

              case 2:
                return Step1_5NameCapture(
                  onComplete: () => controller.nextStep(),
                );

              case 3:
                return Step175Attribution(
                  onComplete: () => controller.nextStep(),
                );

              case 4:
                return Step1DivineRevelation(
                  onComplete: () => controller.nextStep(),
                );

              case 5:
                return Step2SelfConfrontation(
                  onComplete: () => controller.nextStep(),
                );

              case 6:
                return Step3EternalWarfare(
                  onComplete: () => controller.nextStep(),
                );

              case 7:
                return Step35Testimonials(
                  onComplete: () => controller.nextStep(),
                );

              case 8:
                return Step4CallToCovenant(
                  onComplete: () => controller.nextStep(),
                );

              case 9:
                return Step6FinalEncouragement(
                  onComplete: () => controller.nextStep(),
                );

              case 10:
                return Step7ScreenTimePermission(
                  onComplete: () => controller.nextStep(),
                );

              case 11:
                return const Step9NotificationPermission();

              case 12:
                return const OnboardingSummaryScreen();

              case 13:
                return const V2FreeForYou();

              default:
                return CupertinoPageScaffold(
                  backgroundColor: OnboardingTheme.backgroundColor,
                  child: Center(
                    child: Text(
                      'Step ${controller.currentStep.value} - Error',
                      style: const TextStyle(color: CupertinoColors.white),
                    ),
                  ),
                );
            }
          }),

          // _buildDemoButton(controller),

          // Skip button for testing
          if (kDebugMode && isTesting) _buildSkipButton(controller),

          // // Debug controls (only in debug mode)
          // if (kDebugMode) _buildDebugControls(controller),
        ],
      ),
    );
  }

  /// Build skip button for testing
  Widget _buildSkipButton(ScriptureOnboardingController controller) {
    return Positioned(
      top: MediaQuery.of(Get.context!).padding.top + 16,
      left: 16,
      child: Obx(() => GestureDetector(
            onTap: () => controller.nextStep(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Skip ${controller.currentStep.value}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.skip_next,
                    color: Colors.white,
                    size: 16,
                  ),
                ],
              ),
            ),
          )),
    );
  }

  /// Build demo button (always visible, even in production)
  Widget _buildDemoButton(ScriptureOnboardingController controller) {
    return Positioned(
      top: 60,
      right: 20,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            // Fill with demo data
            await controller.fillWithDemoData();

            // Navigate to summary
            Get.off(() => const OnboardingSummaryScreen());
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '🎬',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(width: 6),
                Text(
                  'Demo',
                  style: TextStyle(
                    color: Color(0xFFD4AF37),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build debug controls for easy navigation
  Widget _buildDebugControls(ScriptureOnboardingController controller) {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Obx(() => Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red, width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current step indicator
                Text(
                  'DEBUG MODE - Step ${controller.currentStep.value}/8',
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Step navigation buttons
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (int i = 1; i <= 8; i++)
                      _buildDebugButton(
                        label: '$i',
                        onPressed: () => controller.jumpToStep(i),
                        isActive: controller.currentStep.value == i,
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // Quick action buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildDebugActionButton(
                        label: 'onboarding_prev'.tr,
                        icon: Icons.arrow_back,
                        onPressed: () => controller.previousStep(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDebugActionButton(
                        label: 'onboarding_next'.tr,
                        icon: Icons.arrow_forward,
                        onPressed: () => controller.nextStep(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDebugActionButton(
                        label: 'onboarding_finish'.tr,
                        icon: Icons.check,
                        onPressed: () async {
                          await controller.completeOnboarding();
                          Get.offAllNamed(AppRoutes.home);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )),
    );
  }

  /// Build individual step button
  Widget _buildDebugButton({
    required String label,
    required VoidCallback onPressed,
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isActive ? Colors.red : Colors.grey.shade800,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? Colors.red : Colors.grey.shade600,
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.grey.shade400,
              fontSize: 12,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  /// Build action button (Prev/Next/Finish)
  Widget _buildDebugActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mascot transition step - Judah proud moment before summary
class _MascotTransitionStep extends StatefulWidget {
  final String userName;

  const _MascotTransitionStep({required this.userName});

  @override
  State<_MascotTransitionStep> createState() => _MascotTransitionStepState();
}

class _MascotTransitionStepState extends State<_MascotTransitionStep> {
  bool _showContent = false;

  @override
  void initState() {
    super.initState();
    _startTransition();
  }

  Future<void> _startTransition() async {
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() => _showContent = true);

    // Auto-navigate to summary after 3 seconds
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      Get.off(() => const OnboardingSummaryScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingWrapper(
      child: AnimatedOpacity(
        opacity: _showContent ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 800),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: OnboardingTheme.horizontalPadding,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const JudahMascot(
                  state: JudahState.proud,
                  size: JudahSize.xl,
                  showMessage: false,
                ),
                const SizedBox(height: OnboardingTheme.space32),
                Text(
                  'All set, ${widget.userName}.',
                  style: OnboardingTheme.title2.copyWith(
                    color: OnboardingTheme.labelPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: OnboardingTheme.space16),
                Text(
                  "I've got your back.",
                  style: OnboardingTheme.title3.copyWith(
                    color: OnboardingTheme.goldColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
