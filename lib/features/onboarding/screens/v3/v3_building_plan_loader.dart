import 'package:faithlock/features/onboarding/controllers/scripture_onboarding_v3_controller.dart';
import 'package:faithlock/features/onboarding/utils/animation_utils.dart';
import 'package:faithlock/features/onboarding/widgets/onboarding_wrapper.dart';
import 'package:faithlock/shared/widgets/cozy/cozy.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// V3 Building Plan Loader — cozy rebuild. Pre-paywall theatrical loader
/// ("we crafted this for you") with a chunky lion hero, a thick terracotta
/// progress pill, and rotating status lines.
class V3BuildingPlanLoader extends StatefulWidget {
  final VoidCallback onComplete;
  const V3BuildingPlanLoader({super.key, required this.onComplete});

  @override
  State<V3BuildingPlanLoader> createState() => _V3BuildingPlanLoaderState();
}

class _V3BuildingPlanLoaderState extends State<V3BuildingPlanLoader>
    with TickerProviderStateMixin {
  final controller = Get.find<ScriptureOnboardingV3Controller>();
  late AnimationController _progressController;
  int _stepIndex = 0;

  List<String> get _steps => [
    'onbV3BuildingPlanLoader_stepBuilding'.tr,
    'onbV3BuildingPlanLoader_stepConfiguring'.tr,
    'onbV3BuildingPlanLoader_stepSelecting'.tr,
    'onbV3BuildingPlanLoader_stepSealing'.tr,
  ];

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    )..forward();
    _runSequence();
  }

  Future<void> _runSequence() async {
    for (int i = 0; i < _steps.length; i++) {
      await Future.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;
      setState(() => _stepIndex = i);
      await AnimationUtils.lightHaptic();
    }
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    await AnimationUtils.heavyHaptic();
    widget.onComplete();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = controller.userName.value;
    final greeting = name.isNotEmpty && name != 'User'
        ? 'onbV3BuildingPlanLoader_greetingWithName'.trParams({'name': name})
        : 'onbV3BuildingPlanLoader_greetingDefault'.tr;

    return OnboardingWrapper(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                greeting,
                style: CozyText.title.copyWith(color: CozyColors.primary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: CozyTokens.space24),
              AnimatedBuilder(
                animation: _progressController,
                builder: (context, _) {
                  return SizedBox(
                    width: 240,
                    child: Container(
                      height: 12,
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
                        borderRadius:
                            BorderRadius.circular(CozyTokens.radiusPill),
                        child: LinearProgressIndicator(
                          value: _progressController.value,
                          minHeight: 12,
                          backgroundColor: Colors.transparent,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            CozyColors.primary,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: CozyTokens.space20),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: Text(
                  _steps[_stepIndex],
                  key: ValueKey(_stepIndex),
                  style: CozyText.body.copyWith(color: CozyColors.inkMuted),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

