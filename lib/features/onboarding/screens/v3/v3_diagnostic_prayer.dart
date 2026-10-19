import 'package:faithlock/features/onboarding/controllers/scripture_onboarding_v3_controller.dart';
import 'package:faithlock/features/onboarding/utils/animation_utils.dart';
import 'package:faithlock/features/onboarding/widgets/onboarding_wrapper.dart';
import 'package:faithlock/shared/widgets/cozy/cozy.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// V3 Diagnostic — Prayer frequency per week (cozy).
/// Slider input. Saves to controller.prayerTimesPerWeek.
class V3DiagnosticPrayer extends StatefulWidget {
  final VoidCallback onComplete;
  const V3DiagnosticPrayer({super.key, required this.onComplete});

  @override
  State<V3DiagnosticPrayer> createState() => _V3DiagnosticPrayerState();
}

class _V3DiagnosticPrayerState extends State<V3DiagnosticPrayer> {
  final controller = Get.find<ScriptureOnboardingV3Controller>();
  double _times = 0;
  double _opacity = 1.0;

  Color _color() {
    if (_times == 0) return CozyColors.inkMuted;
    if (_times < 4) return CozyColors.error;
    if (_times < 7) return CozyColors.warning;
    if (_times < 14) return CozyColors.primary;
    return CozyColors.success;
  }

  Future<void> _onContinue() async {
    await controller.savePrayerFrequency(_times.toInt());
    await AnimationUtils.heavyHaptic();

    setState(() => _opacity = 0.0);
    await Future.delayed(const Duration(milliseconds: 400));
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingWrapper(
      child: AnimatedOpacity(
        opacity: _opacity,
        duration: const Duration(milliseconds: 400),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 96, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'onbDiagnosticPrayer_title'.tr,
                style: CozyText.title,
              ),
              const Spacer(),
              Center(
                child: Text(
                  _times.toInt().toString(),
                  style: CozyText.display.copyWith(
                    color: _color(),
                    fontSize: 72,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text('onbDiagnosticPrayer_frequencyLabel'.tr, style: CozyText.label),
              ),
              const SizedBox(height: CozyTokens.space32),
              CozyGlassSlider(
                value: _times,
                min: 0,
                max: 21,
                divisions: 21,
                trackHeight: 24,
                thumbSize: 40,
                activeColor: _color(),
                onChanged: (v) => setState(() => _times = v),
              ),
              const Spacer(),
              CozyButton(
                text: 'onbDiagnosticPrayer_cta'.tr,
                onTap: _onContinue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
