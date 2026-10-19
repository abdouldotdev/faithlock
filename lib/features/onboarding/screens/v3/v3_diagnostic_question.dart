import 'package:faithlock/features/onboarding/controllers/scripture_onboarding_v3_controller.dart';
import 'package:faithlock/features/onboarding/utils/animation_utils.dart';
import 'package:faithlock/features/onboarding/widgets/onboarding_wrapper.dart';
import 'package:faithlock/shared/widgets/cozy/cozy.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';

/// Generic single-question diagnostic screen for V3 — cozy rebuild.
/// Used for qualitative reflection questions (no slider, just choices).
class V3DiagnosticQuestion extends StatefulWidget {
  final VoidCallback onComplete;
  final String questionKey;
  final String question;
  final List<String> options;

  const V3DiagnosticQuestion({
    super.key,
    required this.onComplete,
    required this.questionKey,
    required this.question,
    required this.options,
  });

  @override
  State<V3DiagnosticQuestion> createState() => _V3DiagnosticQuestionState();
}

class _V3DiagnosticQuestionState extends State<V3DiagnosticQuestion> {
  final controller = Get.find<ScriptureOnboardingV3Controller>();
  String? _selected;
  double _opacity = 1.0;

  @override
  void didUpdateWidget(covariant V3DiagnosticQuestion oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The screen reuses this widget for back-to-back questions; reset
    // local state so the new question renders fresh (otherwise the
    // fade-out opacity from the previous question persists → black screen).
    if (oldWidget.questionKey != widget.questionKey) {
      setState(() {
        _selected = null;
        _opacity = 1.0;
      });
    }
  }

  Future<void> _select(String option) async {
    // Block taps once we've started fading out — prevents double-advance.
    if (_opacity < 1.0) return;
    setState(() => _selected = option);
    await AnimationUtils.lightHaptic();

    // Short beat so the user sees their selection register before we
    // auto-advance. If they tap another option during this delay, the
    // newer tap wins — this in-flight advance is cancelled below.
    final triggered = option;
    await Future.delayed(const Duration(milliseconds: 280));
    if (!mounted || _selected != triggered || _opacity < 1.0) return;

    await _advance();
  }

  Future<void> _advance() async {
    if (_selected == null) return;

    await controller.saveDiagnosticAnswer(widget.questionKey, _selected!);
    await AnimationUtils.heavyHaptic();

    if (!mounted) return;
    setState(() => _opacity = 0.0);
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
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
                widget.question,
                style: CozyText.title,
              ),
              const SizedBox(height: CozyTokens.space24),
              Expanded(
                child: ListView.separated(
                  itemCount: widget.options.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: CozyTokens.space12),
                  itemBuilder: (context, index) {
                    final option = widget.options[index];
                    final isSelected = _selected == option;
                    return _OptionCard(
                      label: option,
                      isSelected: isSelected,
                      onTap: () => _select(option),
                    );
                  },
                ),
              ),
              // No Continue button: tapping an option auto-advances after a
              // short beat (see _select). Multi-select screens keep their CTA.
            ],
          ),
        ),
      ),
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
    final Color accent = CozyColors.primary;
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
