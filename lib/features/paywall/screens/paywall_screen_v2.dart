import 'package:faithlock/features/paywall/controllers/paywall_controller.dart';
import 'package:faithlock/services/app_config_service.dart';
import 'package:faithlock/shared/widgets/cozy/cozy.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'package:faithlock/features/onboarding/screens/scripture_onboarding_v3_screen.dart';

/// Cozy-themed paywall — warm cream canvas, chunky outlined cards, terracotta
/// CTA. Visuals follow the cozy design system ([CozyColors] / [CozyText] /
/// [CozyTokens]); all subscription logic stays in [PaywallController].
class PaywallScreenV2 extends StatefulWidget {
  final String? placementId;
  final bool redirectToHomeOnClose;

  /// When false, the close button never appears (hard paywall). Used in the
  /// onboarding conversion flow so the user must choose a plan.
  final bool showCloseButton;

  const PaywallScreenV2({
    super.key,
    this.placementId,
    this.redirectToHomeOnClose = false,
    this.showCloseButton = true,
  });

  @override
  State<PaywallScreenV2> createState() => _PaywallScreenV2State();
}

class _PaywallScreenV2State extends State<PaywallScreenV2> {
  late PaywallController controller;

  bool _showClose = false;
  bool _animateIn = false;

  @override
  void initState() {
    super.initState();
    controller = Get.put(PaywallController(
      placementId: widget.placementId,
      redirectToHomeOnClose: widget.redirectToHomeOnClose,
    ));

    // Gentle fade/slide-in.
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) setState(() => _animateIn = true);
    });

    // Reveal the close button after a short beat (soft conversion pressure).
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showClose = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CozyColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            AnimatedOpacity(
              opacity: _animateIn ? 1 : 0,
              duration: const Duration(milliseconds: 600),
              child: AnimatedSlide(
                offset: _animateIn ? Offset.zero : const Offset(0, 0.04),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                  child: Column(
                    children: [
                      _avatarCluster(),
                      const SizedBox(height: 14),
                      _believersPill(),
                      const SizedBox(height: 14),
                      _headline(),
                      const SizedBox(height: 28),
                      _benefits(),
                      const SizedBox(height: 28),
                      Obx(() => _buildPlans()),
                      const SizedBox(height: 24),
                      Obx(() {
                        if (AppConfigService.instance.simplePaywall.value) {
                          // Simplified variant: trust badge above the CTA, no
                          // price-anchor ("cheaper than gum") line.
                          return Column(
                            children: [
                              _trustRow(),
                              const SizedBox(height: 12),
                              _ctaButton(),
                            ],
                          );
                        }
                        return Column(
                          children: [
                            _gumLine(),
                            const SizedBox(height: 10),
                            _ctaButton(),
                            const SizedBox(height: 14),
                            _trustRow(),
                          ],
                        );
                      }),
                      const SizedBox(height: 16),
                      _footerLinks(),
                    ],
                  ),
                ),
              ),
            ),
            // Close button — floats over the content so it never pushes the
            // hero down. Only visible after a soft 3s pressure beat.
            if (widget.showCloseButton)
              Positioned(top: 8, right: 16, child: _floatingClose()),
            if (kDebugMode) ..._debugButtons(),
          ],
        ),
      ),
    );
  }

  // ── Floating close button (absolute, no column space) ──────────────────────

  Widget _floatingClose() {
    return AnimatedOpacity(
      opacity: _showClose ? 1 : 0,
      duration: const Duration(milliseconds: 300),
      child: IgnorePointer(
        ignoring: !_showClose,
        child: CozyTappable(
          onTap: controller.closePaywall,
          pressedScale: 0.92,
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: CozyColors.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: CozyColors.outline,
                width: CozyTokens.borderWidth,
              ),
              boxShadow: CozyTokens.shadowHard,
            ),
            child: const HugeIcon(
              icon: HugeIcons.strokeRoundedCancel01,
              size: 18,
              color: CozyColors.ink,
            ),
          ),
        ),
      ),
    );
  }

  // ── Avatar cluster ───────────────────────────────────────────────────────────
  //
  // Real-looking faces for social proof. We use `i.pravatar.cc`, which allows
  // hotlinking and returns a stable, distinct portrait per `img` id — unlike
  // `thispersondoesnotexist.com`, which blocks non-browser clients (so the
  // avatars silently rendered as empty cream circles).
  static const _faceUrls = [
    'https://i.pravatar.cc/150?img=12',
    'https://i.pravatar.cc/150?img=32',
    'https://i.pravatar.cc/150?img=47',
    'https://i.pravatar.cc/150?img=68',
  ];

  Widget _avatarCluster() {
    const double d = 36;
    const double overlap = 12;
    final double totalWidth = d + (_faceUrls.length - 1) * (d - overlap);

    return SizedBox(
      width: totalWidth,
      height: d,
      child: Stack(
        children: [
          for (int i = 0; i < _faceUrls.length; i++)
            Positioned(left: i * (d - overlap), child: _faceAvatar(_faceUrls[i])),
        ],
      ),
    );
  }

  Widget _faceAvatar(String url) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: CozyColors.surfaceMuted,
        shape: BoxShape.circle,
        border: Border.all(
          color: CozyColors.outline,
          width: CozyTokens.borderWidth,
        ),
      ),
      child: ClipOval(
        child: Image.network(
          url,
          fit: BoxFit.cover,
          width: 36,
          height: 36,
          // Decode at 2× for crispness on retina without blowing memory.
          cacheWidth: 72,
          cacheHeight: 72,
          // Never show an empty circle: fall back to a person glyph while
          // loading or if the network image can't be fetched.
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return _avatarFallback();
          },
          errorBuilder: (_, __, ___) => _avatarFallback(),
        ),
      ),
    );
  }

  Widget _avatarFallback() {
    return Container(
      color: CozyColors.surfaceMuted,
      alignment: Alignment.center,
      child: const Icon(
        Icons.person,
        size: 22,
        color: CozyColors.inkMuted,
      ),
    );
  }

  // ── Believers pill ───────────────────────────────────────────────────────────

  Widget _believersPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: ShapeDecoration(
        color: CozyColors.surface,
        shape: CozyTokens.smooth(
          CozyTokens.radiusPill,
          side: const BorderSide(
            color: CozyColors.outline,
            width: CozyTokens.borderWidth,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const HugeIcon(
            icon: HugeIcons.strokeRoundedFire,
            size: 16,
            color: CozyColors.primary,
          ),
          const SizedBox(width: 8),
          Text(
            'paywall_socialProof'
                .trParams({'count': '10,000+'}).toUpperCase(),
            style: CozyText.label.copyWith(
              color: CozyColors.ink,
              fontWeight: FontWeight.w800,
              fontSize: 12,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  // ── Headline ───────────────────────────────────────────────────────────────

  Widget _headline() {
    return Text(
      'paywall_headlineMain'.tr,
      textAlign: TextAlign.center,
      style: CozyText.title.copyWith(fontSize: 30, height: 1.12),
    );
  }

  // ── Benefits ───────────────────────────────────────────────────────────────

  Widget _benefits() {
    final benefits = <({List<List<dynamic>> icon, Color color, String text})>[
      (
        icon: HugeIcons.strokeRoundedUnavailable,
        color: CozyColors.error,
        text: 'paywall_benefit1'.tr,
      ),
      (
        icon: HugeIcons.strokeRoundedBookOpen01,
        color: CozyColors.primary,
        text: 'paywall_benefit2'.tr,
      ),
      (
        icon: HugeIcons.strokeRoundedChartLineData01,
        color: CozyColors.success,
        text: 'paywall_benefit4'.tr,
      ),
    ];

    return Column(
      children: [
        for (int i = 0; i < benefits.length; i++)
          Padding(
            padding:
                EdgeInsets.only(bottom: i < benefits.length - 1 ? 18 : 0),
            child: Row(
              children: [
                CozyIconChip(
                  icon: benefits[i].icon,
                  iconColor: benefits[i].color,
                  background: CozyColors.surface,
                  circle: true,
                  size: 48,
                  iconSize: 22,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    benefits[i].text,
                    style: CozyText.body.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ── Plans ──────────────────────────────────────────────────────────────────

  Widget _buildPlans() {
    if (controller.packages.isEmpty) {
      return const SizedBox(
        height: 80,
        child: Center(
          child: CircularProgressIndicator(
            color: CozyColors.primary,
            strokeWidth: 2,
          ),
        ),
      );
    }

    return Column(
      children: [
        for (int i = 0; i < controller.packages.length; i++) _planCard(i),
      ],
    );
  }

  Widget _planCard(int index) {
    final package = controller.packages[index];
    final bool selected = controller.selectedPlanIndex.value == index;
    final bool isYearly = controller.isYearlyPackage(package);
    final String savings = controller.getSavingsText(package);
    final String title = controller.getPlanTitle(package);
    final String priceText = controller.getPriceText(package);
    final String dailyText = _dailyPriceText(package);

    final card = Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: ShapeDecoration(
        color: selected ? CozyColors.surface : CozyColors.surfaceMuted,
        shape: CozyTokens.smooth(
          CozyTokens.radiusPill,
          side: BorderSide(
            color: selected ? CozyColors.primary : CozyColors.outline,
            width: CozyTokens.borderWidth,
          ),
        ),
        shadows: selected ? CozyTokens.shadowHard : null,
      ),
      child: Row(
        children: [
          _radio(selected),
          const SizedBox(width: 14),
          // Title + price
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: CozyText.heading.copyWith(
                    fontSize: 19,
                    color: selected ? CozyColors.ink : CozyColors.inkMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  priceText,
                  style: CozyText.subtitle.copyWith(fontSize: 13),
                ),
              ],
            ),
          ),
          // Savings + daily price
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (savings.isNotEmpty) ...[
                Text(
                  savings,
                  style: CozyText.heading.copyWith(
                    fontSize: 17,
                    color: CozyColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
              ],
              Text(
                dailyText,
                style: CozyText.subtitle.copyWith(fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );

    return Padding(
      padding: EdgeInsets.only(
        top: isYearly ? 14 : 0,
        bottom: index < controller.packages.length - 1 ? 14 : 0,
      ),
      child: CozyTappable(
        onTap: () => controller.selectPlan(index),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            card,
            if (isYearly)
              Positioned(
                top: -13,
                left: 0,
                right: 0,
                child: Center(child: _bestValueTag()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _radio(bool selected) {
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: CozyColors.surface,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? CozyColors.primary : CozyColors.outline,
          width: 2.5,
        ),
      ),
      child: selected
          ? Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: CozyColors.primary,
                shape: BoxShape.circle,
              ),
            )
          : null,
    );
  }

  Widget _bestValueTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: ShapeDecoration(
        color: CozyColors.primary,
        shape: CozyTokens.smooth(
          CozyTokens.radiusPill,
          side: const BorderSide(
            color: CozyColors.outline,
            width: CozyTokens.borderWidth,
          ),
        ),
      ),
      child: Text(
        'paywall_bestValue'.tr,
        style: CozyText.label.copyWith(
          color: CozyColors.ink,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  String _dailyPriceText(Package package) {
    final price = package.storeProduct.price;
    final currencySymbol =
        package.storeProduct.currencyCode == 'EUR' ? '€' : '\$';
    double dailyPrice;
    if (controller.isYearlyPackage(package)) {
      dailyPrice = price / 365;
    } else {
      final period =
          package.storeProduct.subscriptionPeriod?.toLowerCase() ?? '';
      if (period.contains('month') || period.contains('m')) {
        dailyPrice = price / 30;
      } else {
        dailyPrice = price / 7;
      }
    }
    return '$currencySymbol${dailyPrice.toStringAsFixed(2)}/${'paywall_day'.tr}';
  }

  // ── CTA ────────────────────────────────────────────────────────────────────

  Widget _ctaButton() {
    return Obx(() {
      final hasFreeTrial = controller.hasFreeTrial;
      final text = AppConfigService.instance.simplePaywall.value
          ? 'paywall_ctaTryFree'.tr
          : (hasFreeTrial
              ? 'paywall_ctaFreeTrial'.tr
              : 'paywall_ctaNoTrial'.tr);
      return CozyButton(
        text: text,
        height: 60,
        borderRadius: CozyTokens.radiusPill,
        isLoading: controller.isPurchasing.value,
        onTap: () {
          HapticFeedback.mediumImpact();
          controller.startSubscription();
        },
      );
    });
  }

  // ── Trust row ────────────────────────────────────────────────────────────────

  Widget _trustRow() {
    // "Cancel anytime" only — the trial-reminder line was redundant with the
    // CTA copy ("Start FREE for 3 Days") and made the trust strip cluttered.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: ShapeDecoration(
        color: CozyColors.surfaceMuted.withValues(alpha: 0.6),
        shape: CozyTokens.smooth(CozyTokens.radiusPill),
      ),
      child: _trustItem(
        FontAwesomeIcons.shieldHalved,
        'paywall_cancelAnytimeShort'.tr,
      ),
    );
  }

  Widget _trustItem(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FaIcon(icon, size: 11, color: CozyColors.inkMuted),
        const SizedBox(width: 6),
        Text(
          label.toUpperCase(),
          style: CozyText.label.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  // ── Price anchor ("cheaper than gum") ────────────────────────────────────────

  Widget _gumLine() {
    if (controller.packages.isEmpty) return const SizedBox.shrink();
    final index = controller.selectedPlanIndex.value;
    if (index >= controller.packages.length) return const SizedBox.shrink();
    if (!controller.isYearlyPackage(controller.packages[index])) {
      return const SizedBox.shrink();
    }

    final perDay = controller.getYearlyPerDayPrice();
    final base = CozyText.label.copyWith(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      fontStyle: FontStyle.italic,
      letterSpacing: 0.5,
    );

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: base,
        children: [
          if (perDay.isNotEmpty) ...[
            TextSpan(
              text: '$perDay/${'paywall_day'.tr}'.toUpperCase(),
              style: base.copyWith(
                color: CozyColors.primary,
                fontWeight: FontWeight.w800,
                fontStyle: FontStyle.normal,
              ),
            ),
            const TextSpan(text: '  ·  '),
          ],
          TextSpan(text: '${'paywall_priceAnchorSuffix'.tr.toUpperCase()} 🙏'),
        ],
      ),
    );
  }

  // ── Footer links ─────────────────────────────────────────────────────────────

  Widget _footerLinks() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _footerLink('paywall_restore'.tr, controller.restorePurchases),
        _footerDot(),
        _footerLink('paywall_privacy'.tr, controller.openPrivacyPolicy),
        _footerDot(),
        _footerLink('paywall_terms'.tr, controller.openTermsOfService),
      ],
    );
  }

  Widget _footerDot() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Text(
        '·',
        style: CozyText.label.copyWith(
          color: CozyColors.inkMuted.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _footerLink(String text, VoidCallback onTap) {
    return CozyTappable(
      onTap: onTap,
      pressedScale: 0.95,
      child: Text(
        text.toUpperCase(),
        style: CozyText.label.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: CozyColors.inkMuted.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  // ── Debug-only shortcuts ──────────────────────────────────────────────────────

  List<Widget> _debugButtons() {
    return [
      Positioned(
        top: 8,
        left: 16,
        child: GestureDetector(
          onTap: () => Get.to(() => const ScriptureOnboardingV3Screen()),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '▶ Onboarding',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
      Positioned(
        top: 46,
        left: 16,
        child: GestureDetector(
          onTap: controller.debugBypassPaywall,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '⏭ Skip Paywall',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    ];
  }
}
