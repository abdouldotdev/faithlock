import 'package:faithlock/features/onboarding/controllers/scripture_onboarding_v3_controller.dart';
import 'package:faithlock/features/onboarding/utils/animation_utils.dart';
import 'package:faithlock/features/onboarding/widgets/onboarding_wrapper.dart';
import 'package:faithlock/shared/widgets/cozy/cozy.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// V3 Diagnostic — Hours per day on phone (cozy).
/// Slider input. Saves to controller.hoursPerDay.
class V3DiagnosticHours extends StatefulWidget {
  final VoidCallback onComplete;
  const V3DiagnosticHours({super.key, required this.onComplete});

  @override
  State<V3DiagnosticHours> createState() => _V3DiagnosticHoursState();
}

class _V3DiagnosticHoursState extends State<V3DiagnosticHours> {
  final controller = Get.find<ScriptureOnboardingV3Controller>();
  double _hours = 0;
  double _opacity = 1.0;

  /// Bucket identifier — also used as the AnimatedSwitcher key, so the
  /// message only re-fades when the user crosses a real bucket boundary.
  int get _bucket {
    if (_hours == 0) return 0;
    if (_hours < 2) return 1;
    if (_hours < 4) return 2;
    if (_hours < 6) return 3;
    if (_hours < 10) return 4;
    return 5;
  }

  /// Always use the app's primary color regardless of bucket.
  Color _color() => CozyColors.primary;

  /// Tailored psychological reflection per screen-time bucket.
  String _severityMessage() {
    switch (_bucket) {
      case 0:
        return 'onbDiagnosticHours_messageBucketZero'.tr;
      case 1:
        return 'onbDiagnosticHours_messageBucketOne'.tr;
      case 2:
        return 'onbDiagnosticHours_messageBucketTwo'.tr;
      case 3:
        return 'onbDiagnosticHours_messageBucketThree'.tr;
      case 4:
        return 'onbDiagnosticHours_messageBucketFour'.tr;
      default:
        return 'onbDiagnosticHours_messageBucketFive'.tr;
    }
  }

  String _format() {
    if (_hours == _hours.roundToDouble()) return _hours.toInt().toString();
    return _hours.toStringAsFixed(1);
  }

  Future<void> _onContinue() async {
    if (_hours <= 0) return;
    await controller.saveHoursPerDay(_hours);
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
                'onbDiagnosticHours_title'.tr,
                style: CozyText.title,
              ),
              const Spacer(),
              Center(
                child: Text(
                  _format(),
                  style: CozyText.display.copyWith(
                    color: _color(),
                    fontSize: 72,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  'onbDiagnosticHours_unitLabel'.tr,
                  style: CozyText.label,
                ),
              ),
              const SizedBox(height: CozyTokens.space32),
              CozyGlassSlider(
                value: _hours,
                min: 0,
                max: 16,
                divisions: 32,
                trackHeight: 24,
                thumbSize: 40,
                activeColor: _color(),
                onChanged: (v) => setState(() => _hours = v),
              ),
              const SizedBox(height: CozyTokens.space24),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: Padding(
                  key: ValueKey(_bucket),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    _severityMessage(),
                    style: CozyText.body.copyWith(
                      color: CozyColors.inkMuted,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const Spacer(),
              CozyButton(
                text: 'onbDiagnosticHours_continueButton'.tr,
                onTap: _hours > 0 ? _onContinue : null,
                isDisabled: _hours <= 0,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
