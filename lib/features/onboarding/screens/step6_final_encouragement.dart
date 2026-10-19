import 'dart:async';

import 'package:faithlock/features/onboarding/controllers/scripture_onboarding_controller.dart';
import 'package:faithlock/features/onboarding/utils/animation_utils.dart';
import 'package:faithlock/features/onboarding/widgets/fingerprint_scanner.dart';
import 'package:faithlock/features/onboarding/widgets/onboarding_wrapper.dart';
import 'package:faithlock/shared/widgets/cozy/cozy.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Step 6: Final Encouragement — cozy rebuild. Two phases on the cream canvas
/// (no typewriter):
///   Phase 0: encouragement message + Scripture promise — auto-navigates.
///   Phase 1: the fingerprint covenant scanner.
class Step6FinalEncouragement extends StatefulWidget {
  final VoidCallback onComplete;

  const Step6FinalEncouragement({
    super.key,
    required this.onComplete,
  });

  @override
  State<Step6FinalEncouragement> createState() =>
      _Step6FinalEncouragementState();
}

class _Step6FinalEncouragementState extends State<Step6FinalEncouragement> {
  final controller = Get.find<ScriptureOnboardingController>();

  /// 0 = message + verse (auto-navigates), 1 = fingerprint covenant.
  int _phase = 0;

  /// The verse fades in a beat after the message (staged appear on phase 0).
  bool _showVerse = false;

  Timer? _verseTimer;
  Timer? _advanceTimer;

  @override
  void initState() {
    super.initState();
    // Phase 0: message appears, then the verse fades in, then the whole screen
    // auto-navigates to the fingerprint covenant — no tap, no typewriter.
    _verseTimer = Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() => _showVerse = true);
      AnimationUtils.lightHaptic();
    });
    _advanceTimer = Timer(const Duration(milliseconds: 3400), () {
      if (!mounted) return;
      setState(() => _phase = 1);
      AnimationUtils.mediumHaptic();
    });
  }

  @override
  void dispose() {
    _verseTimer?.cancel();
    _advanceTimer?.cancel();
    super.dispose();
  }

  Future<void> _onScanComplete() async {
    await controller.acceptCovenant(true);
    await AnimationUtils.heavyHaptic();

    widget.onComplete();
  }

  TextStyle get _emphasisStyle => CozyText.title.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.35,
      );

  TextStyle get _verseStyle => CozyText.body.copyWith(
        fontSize: 16,
        fontStyle: FontStyle.italic,
        color: CozyColors.primary,
        height: 1.5,
      );

  @override
  Widget build(BuildContext context) {
    final userName = controller.userName.value;
    return OnboardingWrapper(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: _phase == 0
                ? _messageView(userName)
                : _fingerprintView(userName),
          ),
        ),
      ),
    );
  }

  /// Phase 0 — encouragement appears, then the verse fades in. Auto-navigates.
  Widget _messageView(String userName) {
    return Column(
      key: const ValueKey('message'),
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Message: gentle fade + slide on mount.
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOut,
          builder: (context, t, child) => Opacity(
            opacity: t,
            child: Transform.translate(
              offset: Offset(0, 12 * (1 - t)),
              child: child,
            ),
          ),
          child: Text(
            'finalEnc_message'.trParams({'name': userName}),
            style: _emphasisStyle,
            textAlign: TextAlign.center,
          ),
        ),
        // Verse: appears a beat later.
        AnimatedOpacity(
          opacity: _showVerse ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOut,
          child: AnimatedSlide(
            offset: _showVerse ? Offset.zero : const Offset(0, 0.2),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOut,
            child: Padding(
              padding: const EdgeInsets.only(top: 18),
              child: Text(
                'finalEnc_verse'.tr,
                style: _verseStyle,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Phase 1 — the fingerprint covenant scanner.
  Widget _fingerprintView(String userName) {
    return SingleChildScrollView(
      key: const ValueKey('fingerprint'),
      child: FingerprintScanner(
        userName: userName,
        onComplete: _onScanComplete,
      ),
    );
  }
}
