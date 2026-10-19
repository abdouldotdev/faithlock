import 'package:faithlock/features/onboarding/controllers/scripture_onboarding_controller.dart';
import 'package:faithlock/features/onboarding/utils/animation_utils.dart';
import 'package:faithlock/features/paywall/screens/paywall_screen_v2.dart';
import 'package:faithlock/shared/widgets/cozy/cozy.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';

/// V2 Free For You — cozy rebuild. Soft transition before the paywall: a
/// celebratory lion hero on cream canvas, then the personalized benefits, then
/// a chunky CTA. Reuses the existing animation sequence and i18n keys.
class V2FreeForYou extends StatefulWidget {
  const V2FreeForYou({super.key});

  @override
  State<V2FreeForYou> createState() => _V2FreeForYouState();
}

class _V2FreeForYouState extends State<V2FreeForYou> {
  final controller = Get.find<ScriptureOnboardingController>();

  bool _showTitle = false;
  bool _showBenefits = false;
  bool _showButton = false;
  final List<bool> _visibleBenefits = [false, false, false, false];

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  Future<void> _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 600));

    // Title
    setState(() => _showTitle = true);
    await AnimationUtils.mediumHaptic();

    await Future.delayed(const Duration(milliseconds: 500));

    // Benefits
    setState(() => _showBenefits = true);
    for (int i = 0; i < _visibleBenefits.length; i++) {
      await Future.delayed(const Duration(milliseconds: 300));
      setState(() => _visibleBenefits[i] = true);
      await AnimationUtils.lightHaptic();
    }

    await Future.delayed(const Duration(milliseconds: 600));

    // Button
    setState(() => _showButton = true);
    await AnimationUtils.heavyHaptic();
  }

  Future<void> _onStartFreeTrial() async {
    await AnimationUtils.heavyHaptic();
    await controller.completeOnboarding();
    Get.off(() => const PaywallScreenV2(showCloseButton: false));
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CozyColors.background,
      // Material ancestor so Text renders without the yellow debug underlines
      // (this screen sits outside OnboardingWrapper).
      child: Material(
        type: MaterialType.transparency,
        child: SafeArea(
          child: Stack(
            children: [
              // Content
              Positioned.fill(
                bottom: _showButton ? 132 : 0,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 40, 24, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _titleBlock(),
                      const SizedBox(height: CozyTokens.space32),
                      if (_showBenefits) ..._benefits(),
                    ],
                  ),
                ),
              ),
              if (_showButton) _bottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Title + subtitle ────────────────────────────────────────────────────────

  Widget _titleBlock() {
    return AnimatedOpacity(
      opacity: _showTitle ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'freeForYou_title'.tr,
            style: CozyText.display.copyWith(fontSize: 38, height: 1.1),
            textAlign: TextAlign.start,
          ),
          const SizedBox(height: CozyTokens.space12),
          Text(
            'freeForYou_subtitle'.tr,
            style: CozyText.body.copyWith(
              color: CozyColors.inkMuted,
              fontSize: 19,
              height: 1.4,
            ),
            textAlign: TextAlign.start,
          ),
        ],
      ),
    );
  }

  // ── Benefits ────────────────────────────────────────────────────────────────

  List<Widget> _benefits() {
    final items = <_Benefit>[
      _Benefit(
        icon: HugeIcons.strokeRoundedBookOpen01,
        bg: CozyColors.peach,
        text: 'freeForYou_benefit1'.tr,
      ),
      _Benefit(
        icon: HugeIcons.strokeRoundedClock01,
        bg: CozyColors.sage,
        text: 'freeForYou_benefit2'.tr,
      ),
      _Benefit(
        icon: HugeIcons.strokeRoundedNotification03,
        bg: CozyColors.primaryLight,
        text: 'freeForYou_benefit3'.tr,
      ),
      _Benefit(
        icon: HugeIcons.strokeRoundedTradeUp,
        bg: CozyColors.surfaceMuted,
        text: 'freeForYou_benefit4'.tr,
      ),
    ];
    return [
      for (int i = 0; i < items.length; i++) ...[
        _benefitRow(i, items[i]),
        if (i < items.length - 1) const SizedBox(height: CozyTokens.space12),
      ],
    ];
  }

  Widget _benefitRow(int index, _Benefit b) {
    return AnimatedOpacity(
      opacity: _visibleBenefits[index] ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 400),
      child: AnimatedSlide(
        offset: _visibleBenefits[index] ? Offset.zero : const Offset(0, 0.3),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        child: Row(
          children: [
            CozyIconChip(
              icon: b.icon,
              background: b.bg,
              iconColor: CozyColors.ink,
              size: 44,
              iconSize: 22,
            ),
            const SizedBox(width: 14),
            Expanded(child: Text(b.text, style: CozyText.body)),
          ],
        ),
      ),
    );
  }

  // ── Bottom bar (fixed CTA) ──────────────────────────────────────────────────

  Widget _bottomBar() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              CozyColors.background.withValues(alpha: 0),
              CozyColors.background,
              CozyColors.background,
            ],
            stops: const [0.0, 0.35, 1.0],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 44),
        child: AnimatedOpacity(
          opacity: _showButton ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CozyButton(
                text: 'freeForYou_startTrial'.tr,
                onTap: _onStartFreeTrial,
              ),
              const SizedBox(height: 10),
              Text(
                'freeForYou_trialPeriod'.tr,
                style: CozyText.subtitle.copyWith(fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Benefit {
  final List<List<dynamic>> icon;
  final Color bg;
  final String text;

  const _Benefit({required this.icon, required this.bg, required this.text});
}
