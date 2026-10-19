import 'package:faithlock/features/onboarding/controllers/scripture_onboarding_controller.dart';
import 'package:faithlock/shared/widgets/cozy/cozy.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Onboarding progress bar — cozy: a chunky bordered back chip + a thick
/// terracotta-filled progress pill on the cream canvas.
class OnboardingProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const OnboardingProgressBar({
    super.key,
    required this.currentStep,
    this.totalSteps = 9,
  });

  @override
  Widget build(BuildContext context) {
    final progress = currentStep / totalSteps;
    final controller = Get.find<ScriptureOnboardingController>();

    final isFirstStep = currentStep <= 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        spacing: 10,
        children: [
          if (!isFirstStep)
            CozyTappable(
              onTap: controller.previousStep,
              pressedScale: 0.92,
              child: Container(
                height: 32,
                width: 42,
                alignment: Alignment.center,
                decoration: ShapeDecoration(
                  color: CozyColors.surface,
                  shape: CozyTokens.smooth(
                    CozyTokens.radiusSm,
                    side: const BorderSide(
                      color: CozyColors.outline,
                      width: CozyTokens.borderWidth,
                    ),
                  ),
                ),
                child: const Icon(
                  CupertinoIcons.back,
                  color: CozyColors.ink,
                  size: 18,
                ),
              ),
            ),
          Expanded(
            flex: 4,
            child: Container(
              height: 14,
              decoration: ShapeDecoration(
                color: CozyColors.surfaceMuted,
                shape: CozyTokens.smooth(
                  CozyTokens.radiusPill,
                  side: const BorderSide(
                    color: CozyColors.outline,
                    width: CozyTokens.borderWidthThin,
                  ),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(CozyTokens.radiusPill),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 14,
                  backgroundColor: Colors.transparent,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(CozyColors.primary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
