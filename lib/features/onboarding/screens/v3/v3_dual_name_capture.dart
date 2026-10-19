import 'package:faithlock/features/onboarding/controllers/scripture_onboarding_v3_controller.dart';
import 'package:faithlock/features/onboarding/utils/animation_utils.dart';
import 'package:faithlock/features/onboarding/widgets/onboarding_wrapper.dart';
import 'package:faithlock/shared/widgets/cozy/cozy.dart';
import 'package:faithlock/shared/widgets/inputs/fast_text_input.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// V3 Dual Name Capture — cozy rebuild. 2-step flow:
///   Step 0: everyday name (required) → controller.userName
///   Step 1: name before God (optional) → controller.godName
class V3DualNameCapture extends StatefulWidget {
  final VoidCallback onComplete;
  const V3DualNameCapture({super.key, required this.onComplete});

  @override
  State<V3DualNameCapture> createState() => _V3DualNameCaptureState();
}

class _V3DualNameCaptureState extends State<V3DualNameCapture> {
  final controller = Get.find<ScriptureOnboardingV3Controller>();
  final _displayCtrl = TextEditingController();
  final _godCtrl = TextEditingController();
  final _displayFocus = FocusNode();
  final _godFocus = FocusNode();

  int _step = 0;
  static const _stepCount = 2;
  double _opacity = 1.0;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _displayFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _displayCtrl.dispose();
    _godCtrl.dispose();
    _displayFocus.dispose();
    _godFocus.dispose();
    super.dispose();
  }

  bool get _isCurrentStepValid {
    switch (_step) {
      case 0:
        return _displayCtrl.text.trim().isNotEmpty;
      case 1:
        return true; // god name is optional
      default:
        return false;
    }
  }

  Future<void> _onContinue() async {
    if (!_isCurrentStepValid) return;
    await AnimationUtils.lightHaptic();

    if (_step == 0) {
      _displayFocus.unfocus();
      setState(() => _step = 1);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _godFocus.requestFocus();
      });
      return;
    }

    await controller.saveUserName(_displayCtrl.text.trim());
    await controller.saveGodName(_godCtrl.text.trim());
    await AnimationUtils.heavyHaptic();

    _godFocus.unfocus();
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
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 450),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween(
                        begin: const Offset(0.04, 0),
                        end: Offset.zero,
                      ).animate(anim),
                      child: child,
                    ),
                  ),
                  child: KeyedSubtree(
                    key: ValueKey(_step),
                    child: _buildStep(),
                  ),
                ),
              ),
              const SizedBox(height: CozyTokens.space16),
              CozyButton(
                text: _step == _stepCount - 1
                    ? 'onbDualNameCapture_buttonContinue'.tr
                    : 'onbDualNameCapture_buttonNext'.tr,
                onTap: _isCurrentStepValid ? _onContinue : null,
                isDisabled: !_isCurrentStepValid,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'onbDualNameCapture_step0Title'.trParams(
                  {'mascotName': ScriptureOnboardingV3Controller.mascotName},
                ),
                style: CozyText.title,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: CozyTokens.space24),
              FastTextInput(
                controller: _displayCtrl,
                focusNode: _displayFocus,
                hintText: 'onbDualNameCapture_step0HintText'.tr,
                textCapitalization: TextCapitalization.words,
                textStyle: CozyText.title.copyWith(color: CozyColors.primary),
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
        );
      case 1:
      default:
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'onbDualNameCapture_step1Title'.tr,
                style: CozyText.title,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: CozyTokens.space8),
              Text(
                'onbDualNameCapture_step1Subtitle'.tr,
                style: CozyText.subtitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: CozyTokens.space24),
              FastTextInput(
                controller: _godCtrl,
                focusNode: _godFocus,
                hintText: 'onbDualNameCapture_step1HintText'.tr,
                textCapitalization: TextCapitalization.words,
                textStyle: CozyText.title.copyWith(
                  color: CozyColors.primary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        );
    }
  }
}

