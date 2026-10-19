import 'dart:async';

import 'package:faithlock/features/onboarding/controllers/scripture_onboarding_v3_controller.dart';
import 'package:faithlock/features/onboarding/utils/animation_utils.dart';
import 'package:faithlock/features/onboarding/widgets/onboarding_wrapper.dart';
import 'package:faithlock/shared/widgets/cozy/cozy.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';

/// V3 Personalization — cozy rebuild. Intro screen + 5 question screens:
///   Step 0: intro ("Let's tailor this to your faith.")
///   Step 1: tradition (single)
///   Step 2: spiritual state (single)
///   Step 3: prayer intent — 1× / 2× / 3× / More (single, grid 2x2)
///   Step 4: prayer moments (multi)
///   Step 5: prayer practices (multi)
class V3Personalization extends StatefulWidget {
  final VoidCallback onComplete;
  const V3Personalization({super.key, required this.onComplete});

  @override
  State<V3Personalization> createState() => _V3PersonalizationState();
}

class _V3PersonalizationState extends State<V3Personalization> {
  final controller = Get.find<ScriptureOnboardingV3Controller>();

  int _step = 0;
  static const _stepCount = 6;

  Timer? _introAutoAdvance;

  @override
  void initState() {
    super.initState();
    _introAutoAdvance = Timer(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      setState(() => _step = 1);
    });
  }

  @override
  void dispose() {
    _introAutoAdvance?.cancel();
    super.dispose();
  }

  String? _tradition;
  String? _state;
  String? _prayerIntent;
  final Set<String> _practices = {};
  final Set<String> _moments = {};
  double _opacity = 1.0;

  /// Guards the auto-advance beat on single-select steps so a quick double
  /// tap can't skip a step.
  bool _advancing = false;

  List<String> get _traditions => [
    'onbPersonalization_traditionCatholic'.tr,
    'onbPersonalization_traditionProtestant'.tr,
    'onbPersonalization_traditionEvangelical'.tr,
    'onbPersonalization_traditionOrthodox'.tr,
    'onbPersonalization_traditionFiguring'.tr,
  ];

  List<String> get _states => [
    'onbPersonalization_stateDrifted'.tr,
    'onbPersonalization_stateRebuild'.tr,
    'onbPersonalization_stateStarting'.tr,
    'onbPersonalization_stateDeeper'.tr,
  ];

  List<String> get _practiceOptions => [
    'onbPersonalization_practiceMass'.tr,
    'onbPersonalization_practiceRosary'.tr,
    'onbPersonalization_practiceLectio'.tr,
    'onbPersonalization_practiceOffice'.tr,
    'onbPersonalization_practiceSimple'.tr,
    'onbPersonalization_practiceUnsure'.tr,
  ];

  List<String> get _prayerIntents => [
    'onbPersonalization_intent1x'.tr,
    'onbPersonalization_intent2x'.tr,
    'onbPersonalization_intent3x'.tr,
    'onbPersonalization_intentMore'.tr,
  ];

  List<String> get _momentOptions => [
    'onbPersonalization_momentMorning'.tr,
    'onbPersonalization_momentCommute'.tr,
    'onbPersonalization_momentLunch'.tr,
    'onbPersonalization_momentBed'.tr,
    'onbPersonalization_momentHelp'.tr,
  ];

  bool get _isCurrentStepValid {
    switch (_step) {
      case 0:
        return true;
      case 1:
        return _tradition != null;
      case 2:
        return _state != null;
      case 3:
        return _prayerIntent != null;
      case 4:
        return _moments.isNotEmpty;
      case 5:
        return _practices.isNotEmpty;
      default:
        return false;
    }
  }

  /// Single-select steps (tradition / state / prayer intent) behave like the
  /// diagnostic questions: tapping a choice registers it, then auto-advances
  /// after a short beat — no Next button. These steps are never the last one,
  /// so we just bump [_step].
  Future<void> _selectSingle(VoidCallback assign) async {
    if (_advancing) return;
    _advancing = true;
    await AnimationUtils.lightHaptic();
    if (!mounted) {
      _advancing = false;
      return;
    }
    setState(assign);
    await Future.delayed(const Duration(milliseconds: 280));
    if (!mounted) {
      _advancing = false;
      return;
    }
    // Advance (or finish on the last step) — every step is now single-select.
    await _onContinue();
    _advancing = false;
  }

  Future<void> _onContinue() async {
    if (!_isCurrentStepValid) return;

    if (_step < _stepCount - 1) {
      setState(() => _step++);
      return;
    }

    await controller.saveFaithTradition(_tradition!);
    await controller.saveSpiritualState(_state!);
    await controller.savePrayerIntent(_prayerIntent!);
    await controller.savePrayerMoments(_moments.toList());
    await controller.savePrayerPractices(_practices.toList());
    await AnimationUtils.heavyHaptic();

    setState(() => _opacity = 0.0);
    await Future.delayed(const Duration(milliseconds: 400));
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    // Every step is single-select and auto-advances on tap (like the
    // diagnostic questions), so there is no confirm button.
    return OnboardingWrapper(
      child: AnimatedOpacity(
        opacity: _opacity,
        duration: const Duration(milliseconds: 400),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 96, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 450),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  // Top-align so the title sits at the top (like the diagnostic
                  // steps) instead of being vertically centered by the
                  // switcher's default Alignment.center.
                  layoutBuilder: (currentChild, previousChildren) => Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      ...previousChildren,
                      if (currentChild != null) currentChild,
                    ],
                  ),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return Center(
          child: Text(
            'onbPersonalization_introTitle'.tr,
            style: CozyText.display.copyWith(fontSize: 32),
            textAlign: TextAlign.center,
          ),
        );
      case 1:
        return _QuestionStep(
          title: 'onbPersonalization_traditionQuestion'.tr,
          child: _OptionCardList(
            options: _traditions,
            selected: _tradition == null ? const {} : {_tradition!},
            onSelect: (v) => _selectSingle(() => _tradition = v),
          ),
        );
      case 2:
        return _QuestionStep(
          title: 'onbPersonalization_stateQuestion'.tr,
          child: _OptionCardList(
            options: _states,
            selected: _state == null ? const {} : {_state!},
            onSelect: (v) => _selectSingle(() => _state = v),
          ),
        );
      case 3:
        return _QuestionStep(
          title: 'onbPersonalization_intentQuestion'.tr,
          child: _OptionCardList(
            options: _prayerIntents,
            selected: _prayerIntent == null ? const {} : {_prayerIntent!},
            onSelect: (v) => _selectSingle(() => _prayerIntent = v),
          ),
        );
      case 4:
        return _QuestionStep(
          title: 'onbPersonalization_momentQuestion'.tr,
          child: _OptionCardList(
            options: _momentOptions,
            selected: _moments,
            onSelect: (v) => _selectSingle(() => _moments
              ..clear()
              ..add(v)),
          ),
        );
      case 5:
      default:
        return _QuestionStep(
          title: 'onbPersonalization_practiceQuestion'.tr,
          child: _OptionCardList(
            options: _practiceOptions,
            selected: _practices,
            onSelect: (v) => _selectSingle(() => _practices
              ..clear()
              ..add(v)),
          ),
        );
    }
  }
}

/// Per-question layout: title at the top + options below.
class _QuestionStep extends StatelessWidget {
  final String title;
  final Widget child;
  const _QuestionStep({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: CozyText.title),
          const SizedBox(height: CozyTokens.space24),
          child,
        ],
      ),
    );
  }
}

/// List of chunky full-width cards — matches the diagnostic question style
/// (`V3DiagnosticQuestion._OptionCard`). Works for both single-select
/// (one entry in [selected], tap auto-advances) and multi-select (toggle
/// several, confirm with the Next button).
class _OptionCardList extends StatelessWidget {
  final List<String> options;
  final Set<String> selected;
  final ValueChanged<String> onSelect;

  const _OptionCardList({
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final opt in options) ...[
          _OptionCard(
            label: opt,
            isSelected: selected.contains(opt),
            onTap: () => onSelect(opt),
          ),
          if (opt != options.last)
            const SizedBox(height: CozyTokens.space12),
        ],
      ],
    );
  }
}

class _OptionCard extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionCard({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const accent = CozyColors.primary;
    return CozyTappable(
      onTap: onTap,
      pressedScale: 0.98,
      child: AnimatedContainer(
        duration: CozyTokens.base,
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: ShapeDecoration(
          color: isSelected ? CozyColors.selectedFill : CozyColors.surface,
          shape: CozyTokens.smooth(
            CozyTokens.radiusLg,
            side: BorderSide(
              color: isSelected ? accent : CozyColors.outline,
              width: CozyTokens.borderWidth,
            ),
          ),
          shadows: CozyTokens.shadowHard,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: CozyText.body.copyWith(
                  color: isSelected ? accent : CozyColors.ink,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            AnimatedOpacity(
              opacity: isSelected ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: CozyColors.surface, width: 2),
                ),
                child: const HugeIcon(
                  icon: HugeIcons.strokeRoundedTick02,
                  size: 14,
                  color: CozyColors.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
