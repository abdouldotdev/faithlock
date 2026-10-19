import 'dart:async';

import 'package:faithlock/features/onboarding/controllers/scripture_onboarding_v3_controller.dart';
import 'package:faithlock/features/onboarding/utils/animation_utils.dart';
import 'package:faithlock/features/onboarding/widgets/onboarding_wrapper.dart';
import 'package:faithlock/shared/widgets/cozy/cozy.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// V3 Reveal Screen — cozy rebuild. 3-stage cinematic sequence on the cream
/// canvas with terracotta accents:
///   Stage 0: "Some hard news, then something hopeful." (intro)
///   Stage 1: bad news — line-by-line reveal + big hero number
///   Stage 2: good news — haloed lion + "Redeem my time" CTA
class V3RevealScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const V3RevealScreen({super.key, required this.onComplete});

  @override
  State<V3RevealScreen> createState() => _V3RevealScreenState();
}

class _V3RevealScreenState extends State<V3RevealScreen> {
  final controller = Get.find<ScriptureOnboardingV3Controller>();

  int _stage = 0;
  static const _stageCount = 3;

  static const _introHoldMs = 2400;
  static const _badNewsAnimMs = 5400;

  Timer? _autoAdvance;
  Timer? _badNewsGate;
  bool _badNewsReady = false;

  @override
  void initState() {
    super.initState();
    _scheduleIntroAutoAdvance();
  }

  @override
  void dispose() {
    _autoAdvance?.cancel();
    _badNewsGate?.cancel();
    super.dispose();
  }

  void _scheduleIntroAutoAdvance() {
    _autoAdvance?.cancel();
    if (_stage != 0) return;
    _autoAdvance = Timer(
      const Duration(milliseconds: _introHoldMs),
      () {
        if (!mounted) return;
        _advance();
      },
    );
  }

  void _gateBadNewsCta() {
    _badNewsGate?.cancel();
    setState(() => _badNewsReady = false);
    _badNewsGate = Timer(
      const Duration(milliseconds: _badNewsAnimMs),
      () {
        if (!mounted) return;
        setState(() => _badNewsReady = true);
      },
    );
  }

  Future<void> _advance() async {
    await AnimationUtils.mediumHaptic();
    if (!mounted) return;
    setState(() => _stage++);
    if (_stage == 1) _gateBadNewsCta();
  }

  Future<void> _onCta() async {
    await AnimationUtils.heavyHaptic();
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final stats = controller.calculateRevealStats();
    final daysPerYear = (stats['daysPerYear'] as num?)?.toInt() ?? 0;
    final lifetimeHours = (stats['lifetimeHours'] as num?)?.toInt() ?? 0;

    return OnboardingWrapper(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 72, 24, 20),
        child: Column(
          children: [
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 600),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween(
                      begin: const Offset(0, 0.04),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: _buildStage(
                  key: ValueKey(_stage),
                  daysPerYear: daysPerYear,
                  lifetimeHours: lifetimeHours,
                ),
              ),
            ),
            if (_stage > 0) ...[
              const SizedBox(height: CozyTokens.space24),
              Builder(builder: (context) {
                final isFinal = _stage == _stageCount - 1;
                final disabled = !isFinal && !_badNewsReady;
                return CozyButton(
                  text: isFinal
                      ? 'onbReveal_redeemCta'.tr
                      : 'onbReveal_continueCta'.tr,
                  onTap: disabled ? null : (isFinal ? _onCta : _advance),
                  isDisabled: disabled,
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStage({
    required Key key,
    required int daysPerYear,
    required int lifetimeHours,
  }) {
    switch (_stage) {
      case 0:
        return _IntroStage(key: key);
      case 1:
        return _BadNewsStage(
          key: key,
          daysPerYear: daysPerYear,
          lifetimeHours: lifetimeHours,
        );
      case 2:
      default:
        return _GoodNewsStage(key: key);
    }
  }
}

String _formatThousands(int n) {
  return n.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
}

class _IntroStage extends StatelessWidget {
  const _IntroStage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'onbReveal_introTitle'.tr,
        style: CozyText.title,
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _BadNewsStage extends StatefulWidget {
  final int daysPerYear;
  final int lifetimeHours;
  const _BadNewsStage({
    super.key,
    required this.daysPerYear,
    required this.lifetimeHours,
  });

  @override
  State<_BadNewsStage> createState() => _BadNewsStageState();
}

class _BadNewsStageState extends State<_BadNewsStage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  late final Animation<double> _lineAltar;
  late final Animation<double> _lineDays;
  late final Animation<double> _lineMeaning;
  late final Animation<double> _heroNumber;
  late final Animation<double> _lineClose;
  late final Animation<double> _lineFootnote;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5400),
    );

    _lineAltar = _interval(0.00, 0.18);
    _lineDays = _interval(0.20, 0.36);
    _lineMeaning = _interval(0.40, 0.54);
    _heroNumber = _interval(0.58, 0.78, curve: Curves.easeOutBack);
    _lineClose = _interval(0.82, 0.93);
    _lineFootnote = _interval(0.94, 1.00);

    _c.forward();
  }

  Animation<double> _interval(double start, double end, {Curve? curve}) {
    return CurvedAnimation(
      parent: _c,
      curve: Interval(start, end, curve: curve ?? Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bodyStyle = CozyText.body.copyWith(height: 1.35);
    const highlight = CozyColors.primary;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _RevealLine(
                    animation: _lineAltar,
                    child: Text(
                      'onbReveal_badNewsLine1'.tr,
                      style: bodyStyle.copyWith(fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: CozyTokens.space24),
                  _RevealLine(
                    animation: _lineDays,
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: bodyStyle,
                        children: [
                          TextSpan(text: 'onbReveal_badNewsPrefix'.tr),
                          TextSpan(
                            text: 'onbReveal_badNewsDays'.trParams(
                                {'count': '${widget.daysPerYear}'}),
                            style: bodyStyle.copyWith(
                              color: highlight,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          TextSpan(text: 'onbReveal_badNewsSuffix'.tr),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: CozyTokens.space32),
                  _RevealLine(
                    animation: _lineMeaning,
                    child: Text(
                      'onbReveal_badNewsLine3'.tr,
                      style: bodyStyle.copyWith(color: CozyColors.inkMuted),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: CozyTokens.space12),
                  AnimatedBuilder(
                    animation: _heroNumber,
                    builder: (context, child) {
                      final v = _heroNumber.value;
                      return Opacity(
                        opacity: v.clamp(0.0, 1.0),
                        child: Transform.scale(
                          scale: 0.85 + 0.15 * v,
                          child: child,
                        ),
                      );
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ShaderMask(
                          shaderCallback: (rect) => const LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              CozyColors.primaryLight,
                              CozyColors.primary,
                              CozyColors.primaryDark,
                            ],
                          ).createShader(rect),
                          blendMode: BlendMode.srcIn,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              _formatThousands(widget.lifetimeHours),
                              style: CozyText.display.copyWith(
                                fontSize: 80,
                                letterSpacing: -2,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: CozyTokens.space8),
                        Text(
                          'onbReveal_hoursLabel'.tr,
                          style: CozyText.label.copyWith(
                            color: CozyColors.primary,
                            letterSpacing: 4,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: CozyTokens.space16),
                  _RevealLine(
                    animation: _lineClose,
                    child: Text(
                      'onbReveal_badNewsLine4'.tr,
                      style: bodyStyle,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: CozyTokens.space32),
                  _RevealLine(
                    animation: _lineFootnote,
                    offset: 6,
                    child: Text(
                      'onbReveal_badNewsFootnote'.tr,
                      style: CozyText.subtitle.copyWith(fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: CozyTokens.space20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Fades + slides a child upwards as its driving animation progresses.
class _RevealLine extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;
  final double offset;
  const _RevealLine({
    required this.animation,
    required this.child,
    this.offset = 12,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, c) {
        final v = animation.value;
        return Opacity(
          opacity: v.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, offset * (1 - v)),
            child: c,
          ),
        );
      },
      child: child,
    );
  }
}

class _GoodNewsStage extends StatelessWidget {
  const _GoodNewsStage({super.key});

  @override
  Widget build(BuildContext context) {
    final bodyStyle =
        CozyText.body.copyWith(height: 1.4, color: CozyColors.ink);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 3),
                  Text(
                    'onbReveal_goodNewsLabel'.tr,
                    style: CozyText.label.copyWith(
                      color: CozyColors.primary,
                      letterSpacing: 2.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: CozyTokens.space16),
                  ShaderMask(
                    shaderCallback: (rect) => const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        CozyColors.primaryLight,
                        CozyColors.primary,
                        CozyColors.primaryDark,
                      ],
                    ).createShader(rect),
                    blendMode: BlendMode.srcIn,
                    child: Text(
                      'onbReveal_goodNewsTitle'.tr,
                      style: CozyText.display.copyWith(
                        fontSize: 32,
                        color: Colors.white,
                        height: 1.15,
                        letterSpacing: -0.8,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: CozyTokens.space20),
                  Text(
                    'onbReveal_goodNewsDescription'.tr,
                    style: bodyStyle,
                    textAlign: TextAlign.center,
                  ),
                  const Spacer(flex: 4),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

