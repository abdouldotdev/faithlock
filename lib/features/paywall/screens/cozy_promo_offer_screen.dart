import 'package:faithlock/features/paywall/controllers/promo_offer_controller.dart';
import 'package:faithlock/shared/widgets/cozy/cozy.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';

/// Landing page for the reserved welcome offer.
///
/// Ordered by what actually moves the decision, strongest first: the price,
/// then the deadline, then the proof, then the button. The renewal terms sit
/// *below* the button — still complete, still on screen before any charge, but
/// no longer lying across the path to the tap.
///
/// Deliberately single-option: the point of the reservation is that the choice
/// has already been narrowed to one.
class CozyPromoOfferScreen extends StatefulWidget {
  const CozyPromoOfferScreen({super.key, this.source = 'unknown'});

  final String source;

  @override
  State<CozyPromoOfferScreen> createState() => _CozyPromoOfferScreenState();
}

class _CozyPromoOfferScreenState extends State<CozyPromoOfferScreen>
    with TickerProviderStateMixin {
  late final PromoOfferController controller;

  /// Staggered entrance. Each element gets a slice of this one timeline.
  late final AnimationController _entry;

  /// Slow breath under the CTA, and the countdown's pulse in the last minutes.
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    controller = Get.put(
      PromoOfferController(source: widget.source),
      tag: widget.source,
    );

    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Honour the system "reduce motion" setting: jump straight to the end
    // state rather than animating.
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _entry.value = 1;
      _pulse.stop();
    } else if (!_entry.isAnimating && _entry.value == 0) {
      _entry.forward();
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _entry.dispose();
    _pulse.dispose();
    super.dispose();
  }

  /// Fade + rise for the slice [begin]..[end] of the entrance timeline.
  Widget _stagger(double begin, double end, Widget child) {
    final curve = CurvedAnimation(
      parent: _entry,
      curve: Interval(begin, end, curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: curve,
      builder: (_, inner) => Opacity(
        opacity: curve.value,
        child: Transform.translate(
          offset: Offset(0, 18 * (1 - curve.value)),
          child: inner,
        ),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) controller.dismiss();
      },
      child: Scaffold(
        backgroundColor: CozyColors.background,
        body: SafeArea(
          child: Obx(
            () => Column(
              children: [
                _TopBar(controller: controller),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                    child: Column(
                      children: [
                        _stagger(0.00, 0.45, _GiftMark(entry: _entry)),
                        const SizedBox(height: CozyTokens.space20),
                        _stagger(
                          0.10,
                          0.55,
                          Text(
                            controller.copy.value.headline,
                            style: CozyText.title,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: CozyTokens.space24),
                        _stagger(
                          0.20,
                          0.70,
                          _PriceHero(controller: controller),
                        ),
                        const SizedBox(height: CozyTokens.space20),
                        if (!controller.hasExpired.value)
                          _stagger(
                            0.35,
                            0.85,
                            _Countdown(controller: controller, pulse: _pulse),
                          ),
                        const SizedBox(height: CozyTokens.space24),
                        _stagger(
                          0.45,
                          1.00,
                          _Benefits(entry: _entry),
                        ),
                      ],
                    ),
                  ),
                ),
                _stagger(0.55, 1.00, _BottomBar(controller: controller)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------

class _TopBar extends StatelessWidget {
  const _TopBar({required this.controller});

  final PromoOfferController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          const Spacer(),
          // Always-visible, full-size close control. A hidden or delayed
          // dismiss is the single most common paywall rejection (3.1.2).
          CozyIconButton(
            icon: HugeIcons.strokeRoundedCancel01,
            size: 44,
            onTap: () {
              controller.dismiss();
              Get.back<void>();
            },
          ),
        ],
      ),
    );
  }
}

/// The gift, landing with a small overshoot so the screen opens on movement.
class _GiftMark extends StatelessWidget {
  const _GiftMark({required this.entry});

  final AnimationController entry;

  @override
  Widget build(BuildContext context) {
    final scale = CurvedAnimation(
      parent: entry,
      curve: const Interval(0, 0.5, curve: Curves.easeOutBack),
    );
    return ScaleTransition(
      scale: Tween<double>(begin: 0.72, end: 1).animate(scale),
      child: Container(
        width: 104,
        height: 104,
        decoration: ShapeDecoration(
          color: CozyColors.peach,
          shape: CozyTokens.smooth(
            CozyTokens.radiusLg,
            side: const BorderSide(
              color: CozyColors.outline,
              width: CozyTokens.borderWidth,
            ),
          ),
          shadows: CozyTokens.shadowHard,
        ),
        alignment: Alignment.center,
        child: const Text('🎁', style: TextStyle(fontSize: 50)),
      ),
    );
  }
}

/// The single most persuasive fact on the screen, sized accordingly.
class _PriceHero extends StatelessWidget {
  const _PriceHero({required this.controller});

  final PromoOfferController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.hasExpired.value) {
      return Column(
        children: [
          Text('Offer ended', style: CozyText.display),
          const SizedBox(height: 6),
          Text(
            'The regular plans are still here.',
            style: CozyText.subtitle,
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return Column(
      children: [
        // Scale down rather than clip: currencies vary wildly in length
        // ("$1.00", "1,00 €", "CHF 1.00", "￥150").
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            controller.introPrice,
            style: CozyText.display.copyWith(
              fontSize: 68,
              height: 1.0,
              letterSpacing: -2,
            ),
            maxLines: 1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'for your first ${controller.introPeriod}',
          style: CozyText.body.copyWith(color: CozyColors.inkMuted),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Deadline made visible. Warm for most of the window, alarming in the last
/// ten minutes — and the pulse only runs then, so it means something.
class _Countdown extends StatelessWidget {
  const _Countdown({required this.controller, required this.pulse});

  final PromoOfferController controller;
  final AnimationController pulse;

  @override
  Widget build(BuildContext context) {
    final urgent = controller.isEndingSoon;
    final accent = urgent ? CozyColors.error : CozyColors.primary;

    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
      decoration: ShapeDecoration(
        color: accent.withValues(alpha: 0.12),
        shape: CozyTokens.smooth(
          CozyTokens.radiusPill,
          side: BorderSide(color: accent, width: CozyTokens.borderWidthThin),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedClock01,
            color: accent,
            size: 17,
          ),
          const SizedBox(width: 8),
          Text(
            'Offer ends in',
            style: CozyText.label.copyWith(color: CozyColors.ink),
          ),
          const SizedBox(width: 8),
          Text(
            controller.countdownLabel,
            style: CozyText.heading.copyWith(
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );

    if (!urgent) return pill;

    return AnimatedBuilder(
      animation: pulse,
      builder: (_, child) => Transform.scale(
        scale: 1 + 0.03 * pulse.value,
        child: child,
      ),
      child: pill,
    );
  }
}

class _Benefits extends StatelessWidget {
  const _Benefits({required this.entry});

  final AnimationController entry;

  static const _items = <String>[
    'Lock the apps that pull you away',
    'Unlock with a prayer or a verse',
    'Your streak, your garden, your pace',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < _items.length; i++)
          FadeTransition(
            opacity: CurvedAnimation(
              parent: entry,
              // Each line lands just after the one above it.
              curve: Interval(0.5 + i * 0.12, 0.85 + i * 0.05),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  const HugeIcon(
                    icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                    color: CozyColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(_items[i], style: CozyText.body),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.controller});

  final PromoOfferController controller;

  @override
  Widget build(BuildContext context) {
    final expired = controller.hasExpired.value;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
      color: CozyColors.background,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (controller.errorMessage.value.isNotEmpty) ...[
            Text(
              controller.errorMessage.value,
              style: CozyText.subtitle.copyWith(color: CozyColors.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: CozyTokens.space12),
          ],
          CozyButton(
            text: expired ? 'See the plans' : controller.ctaLabel,
            height: 64,
            isLoading: controller.isPurchasing.value,
            isDisabled: controller.isLoading.value,
            onTap: () async {
              if (expired) {
                Get.back<void>();
                return;
              }
              final ok = await controller.purchase();
              if (ok) Get.back<void>(result: true);
            },
          ),
          const SizedBox(height: 10),
          // Renewal terms live *under* the button: complete and legible before
          // any charge, without standing between the offer and the tap.
          if (!expired && controller.disclosure.isNotEmpty)
            Text(
              controller.disclosure,
              style: CozyText.subtitle.copyWith(fontSize: 12, height: 1.35),
              textAlign: TextAlign.center,
            ),
          TextButton(
            onPressed: controller.isPurchasing.value
                ? null
                : () async {
                    final ok = await controller.restore();
                    if (ok) Get.back<void>(result: true);
                  },
            child: Text('Restore purchase', style: CozyText.label),
          ),
        ],
      ),
    );
  }
}
