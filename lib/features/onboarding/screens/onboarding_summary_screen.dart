import 'dart:async';
import 'dart:math' as math;

import 'package:faithlock/features/onboarding/controllers/scripture_onboarding_controller.dart';
import 'package:faithlock/features/onboarding/utils/animation_utils.dart';
import 'package:faithlock/features/paywall/screens/paywall_screen_v2.dart';
import 'package:faithlock/services/analytics/posthog/config/event_templates.dart';
import 'package:faithlock/services/analytics/posthog/posthog_service.dart';
import 'package:faithlock/shared/widgets/cozy/cozy.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';

/// Onboarding Summary Screen — cozy rebuild: cream canvas, chunky bordered
/// cards with hard offset shadows, terracotta accents. Shows setup completion
/// and the screen-time projection, then navigates to the paywall.
class OnboardingSummaryScreen extends StatefulWidget {
  const OnboardingSummaryScreen({super.key});

  @override
  State<OnboardingSummaryScreen> createState() =>
      _OnboardingSummaryScreenState();
}

class _OnboardingSummaryScreenState extends State<OnboardingSummaryScreen>
    with TickerProviderStateMixin {
  final controller = Get.find<ScriptureOnboardingController>();
  final PostHogService _analytics = PostHogService.instance;

  bool _showLoading = true;
  bool _showSummary = false;
  final List<bool> _visibleItems = [false, false, false, false];
  bool _showGraph = false;
  bool _showButton = false;

  late AnimationController _loadingController;
  late Animation<double> _loadingAnimation;

  // Testimonial carousel — 3 quotes rotating every 4s so the social proof
  // feels alive rather than a static one-liner.
  static const List<({String quoteKey, String authorKey})> _testimonials = [
    (
      quoteKey: 'summaryScreen_testimonial',
      authorKey: 'summaryScreen_testimonial_author'
    ),
    (
      quoteKey: 'summaryScreen_testimonial2',
      authorKey: 'summaryScreen_testimonial2_author'
    ),
    (
      quoteKey: 'summaryScreen_testimonial3',
      authorKey: 'summaryScreen_testimonial3_author'
    ),
  ];
  int _testimonialIndex = 0;
  Timer? _testimonialTimer;

  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _loadingAnimation = CurvedAnimation(
      parent: _loadingController,
      curve: Curves.easeInOut,
    );

    _testimonialTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      setState(() {
        _testimonialIndex = (_testimonialIndex + 1) % _testimonials.length;
      });
    });

    _startAnimation();
    _trackSummaryView();
  }

  Future<void> _trackSummaryView() async {
    if (_analytics.isReady) {
      await _analytics.events.track(
        PostHogEventType.screenView,
        {
          'screen_name': 'onboarding_summary',
          'screen_class': 'OnboardingSummaryScreen',
          'initial_hours': controller.hoursPerDay.value,
          'projected_hours': controller.hoursPerDay.value * 0.3,
          'time_to_reclaim': controller.hoursPerDay.value * 0.7,
        },
      );
    }
  }

  @override
  void dispose() {
    _testimonialTimer?.cancel();
    _loadingController.dispose();
    super.dispose();
  }

  Future<void> _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 500));

    // Phase 1: Loading (2 seconds)
    await Future.delayed(const Duration(milliseconds: 2000));

    // Phase 2: Show summary
    setState(() {
      _showLoading = false;
      _showSummary = true;
    });

    await AnimationUtils.mediumHaptic();

    // Animate items one by one
    for (int i = 0; i < _visibleItems.length; i++) {
      await Future.delayed(const Duration(milliseconds: 400));
      setState(() => _visibleItems[i] = true);
      await AnimationUtils.lightHaptic();
    }

    // Wait a bit
    await Future.delayed(const Duration(milliseconds: 800));

    // Show graph
    setState(() => _showGraph = true);
    await AnimationUtils.mediumHaptic();

    // Wait a bit to let user see the graph
    await Future.delayed(const Duration(milliseconds: 1200));

    // Show button
    setState(() => _showButton = true);
    await AnimationUtils.mediumHaptic();
  }

  Future<void> _onStartJourney() async {
    await AnimationUtils.heavyHaptic();

    if (_analytics.isReady) {
      await _analytics.events.track(
        PostHogEventType.navigationAction,
        {
          'action': 'summary_cta_clicked',
          'button_text': 'Unlock Your Full Potential',
          'destination': 'paywall',
          'initial_hours': controller.hoursPerDay.value,
          'time_to_reclaim': controller.hoursPerDay.value * 0.7,
        },
      );
    }

    await controller.completeSummary();

    // Self-contained navigation to the paywall — this screen is shown on
    // relaunch for unpaid users, outside the onboarding step machine.
    Get.off(() => const PaywallScreenV2(showCloseButton: false));
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CozyColors.background,
      // Material ancestor so Text renders without the yellow debug underlines.
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            Positioned.fill(
              bottom: _showButton ? 132 : 0,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 64, 20, 28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_showLoading) ..._loadingPhase(),
                    if (_showSummary) ..._summaryPhase(),
                  ],
                ),
              ),
            ),
            if (_showButton) _bottomBar(),
          ],
        ),
      ),
    );
  }

  // ── Loading phase ──────────────────────────────────────────────────────────

  List<Widget> _loadingPhase() {
    return [
      const SizedBox(height: 80),
      AnimatedBuilder(
        animation: _loadingAnimation,
        builder: (context, child) {
          return Transform.rotate(
            angle: _loadingAnimation.value * 2 * math.pi,
            child: child,
          );
        },
        child: Container(
          width: 96,
          height: 96,
          alignment: Alignment.center,
          decoration: ShapeDecoration(
            color: CozyColors.peach,
            shape: const CircleBorder(
              side: BorderSide(
                color: CozyColors.outline,
                width: CozyTokens.borderWidth,
              ),
            ),
            shadows: CozyTokens.shadowHard,
          ),
          child: const HugeIcon(
            icon: HugeIcons.strokeRoundedShield01,
            size: 44,
            color: CozyColors.primaryDark,
          ),
        ),
      ),
      const SizedBox(height: CozyTokens.space24),
      Text(
        'summaryScreen_loading'.tr,
        style: CozyText.body.copyWith(color: CozyColors.inkMuted),
        textAlign: TextAlign.center,
      ),
    ];
  }

  // ── Summary phase ──────────────────────────────────────────────────────────

  List<Widget> _summaryPhase() {
    return [
      // Success badge
      Container(
        width: 96,
        height: 96,
        alignment: Alignment.center,
        decoration: ShapeDecoration(
          color: CozyColors.sage,
          shape: const CircleBorder(
            side: BorderSide(
              color: CozyColors.outline,
              width: CozyTokens.borderWidth,
            ),
          ),
          shadows: CozyTokens.shadowHard,
        ),
        child: const HugeIcon(
          icon: HugeIcons.strokeRoundedCheckmarkBadge01,
          size: 52,
          color: CozyColors.ink,
        ),
      ),
      const SizedBox(height: CozyTokens.space24),
      Text(
        'summaryScreen_title'.trParams({'name': controller.userName.value}),
        style: CozyText.title,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: CozyTokens.space24),

      // Configured items
      _summaryItem(
        index: 0,
        icon: HugeIcons.strokeRoundedBookOpen01,
        iconBg: CozyColors.peach,
        title: 'summaryScreen_item1_title'.tr,
        subtitle: 'summaryScreen_item1_subtitle'.tr,
      ),
      const SizedBox(height: CozyTokens.space12),
      _summaryItem(
        index: 1,
        icon: HugeIcons.strokeRoundedClock01,
        iconBg: CozyColors.sage,
        title: 'summaryScreen_item2_title'.tr,
        subtitle: 'summaryScreen_item2_subtitle'.tr,
      ),
      const SizedBox(height: CozyTokens.space12),
      _summaryItem(
        index: 2,
        icon: HugeIcons.strokeRoundedNotification03,
        iconBg: CozyColors.primaryLight,
        title: 'summaryScreen_item3_title'.tr,
        subtitle: 'summaryScreen_item3_subtitle'.tr,
      ),
      const SizedBox(height: CozyTokens.space12),
      _summaryItem(
        index: 3,
        icon: HugeIcons.strokeRoundedFavourite,
        iconBg: CozyColors.surfaceMuted,
        title: 'summaryScreen_item4_title'.tr,
        subtitle: 'summaryScreen_item4_subtitle'.tr,
      ),

      const SizedBox(height: CozyTokens.space24),

      // Transformation promises
      CozyCard(
        child: Column(
          children: [
            Text(
              'summaryScreen_transformation_title'.tr,
              style: CozyText.heading,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: CozyTokens.space16),
            _promiseItem('summaryScreen_promise1'.tr),
            const SizedBox(height: CozyTokens.space12),
            _promiseItem('summaryScreen_promise2'.tr),
            const SizedBox(height: CozyTokens.space12),
            _promiseItem('summaryScreen_promise3'.tr),
            const SizedBox(height: CozyTokens.space12),
            _promiseItem('summaryScreen_promise4'.tr),
          ],
        ),
      ),

      const SizedBox(height: CozyTokens.space24),

      // Projection graph
      if (_showGraph) ...[
        AnimatedOpacity(
          opacity: _showGraph ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 600),
          child: Column(
            children: [
              Text(
                'summaryScreen_graph_title'.tr,
                style: CozyText.heading,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: CozyTokens.space8),
              Text(
                'summaryScreen_graph_subtitle'.tr,
                style: CozyText.subtitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: CozyTokens.space16),
              _projectionGraph(),
              const SizedBox(height: CozyTokens.space12),
              Text(
                'summaryScreen_graph_note'.tr,
                style: CozyText.subtitle.copyWith(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: CozyTokens.space24),
      ],

      // Testimonial carousel — 3 quotes cycling on a 4s timer. Filled ★
      // glyphs (HugeIcons free pack has no solid star). A fixed-height
      // quote container keeps the whole card from jumping size between
      // testimonials of slightly different length.
      _testimonialCarousel(),

      const SizedBox(height: CozyTokens.space16),

      // Stats
      CozyCard(
        color: CozyColors.sage,
        child: Column(
          children: [
            const HugeIcon(
              icon: HugeIcons.strokeRoundedTradeUp,
              size: 30,
              color: CozyColors.ink,
            ),
            const SizedBox(height: CozyTokens.space12),
            Text(
              'summaryScreen_stats_title'.tr,
              style: CozyText.body.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: CozyTokens.space16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _miniStat('summaryScreen_stat1_value'.tr,
                    'summaryScreen_stat1_label'.tr),
                _statDivider(),
                _miniStat('summaryScreen_stat2_value'.tr,
                    'summaryScreen_stat2_label'.tr),
                _statDivider(),
                _miniStat('summaryScreen_stat3_value'.tr,
                    'summaryScreen_stat3_label'.tr),
              ],
            ),
          ],
        ),
      ),
    ];
  }

  // ── Bottom bar (fixed CTA) ───────────────────────────────────────────────────

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
              // Urgency pill
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: CozyColors.primaryLight,
                  borderRadius: BorderRadius.circular(CozyTokens.radiusPill),
                  border: Border.all(
                    color: CozyColors.outline,
                    width: CozyTokens.borderWidthThin,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const HugeIcon(
                      icon: HugeIcons.strokeRoundedTimer02,
                      size: 14,
                      color: CozyColors.ink,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'summaryScreen_urgency'.tr,
                      style: CozyText.label.copyWith(
                        color: CozyColors.ink,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              CozyButton(
                text: 'summaryScreen_cta'.tr,
                onTap: _onStartJourney,
              ),
              const SizedBox(height: 8),
              Text(
                'summaryScreen_risk_reversal'.tr,
                style: CozyText.subtitle.copyWith(fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Projection graph ─────────────────────────────────────────────────────────

  Widget _projectionGraph() {
    final initialHours = controller.hoursPerDay.value;
    final targetHours = initialHours * 0.3;
    final timeReclaimed = initialHours - targetHours;

    return CozyCard(
      child: Column(
        children: [
          SizedBox(
            height: 170,
            child: CustomPaint(
              size: const Size(double.infinity, 170),
              painter: TransformationGraphPainter(
                startValue: 0,
                endValue: timeReclaimed,
                color: CozyColors.primary,
              ),
            ),
          ),
          const SizedBox(height: CozyTokens.space20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem(
                label: 'summaryScreen_screenTimeToday'.tr,
                value: '${initialHours.toStringAsFixed(1)}h',
                color: CozyColors.error,
              ),
              const HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                color: CozyColors.primary,
                size: 22,
              ),
              _statItem(
                label: 'summaryScreen_screenTimeWeek2'.tr,
                value: '${targetHours.toStringAsFixed(1)}h',
                color: CozyColors.success,
              ),
            ],
          ),
          const SizedBox(height: CozyTokens.space16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: CozyColors.selectedFill,
              borderRadius: BorderRadius.circular(CozyTokens.radiusPill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const HugeIcon(
                  icon: HugeIcons.strokeRoundedClock01,
                  size: 18,
                  color: CozyColors.primaryDark,
                ),
                const SizedBox(width: 8),
                Text(
                  '+${timeReclaimed.toStringAsFixed(1)}h ${'summaryScreen_dailyForMatters'.tr}',
                  style: CozyText.body.copyWith(
                    color: CozyColors.primaryDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: CozyText.title.copyWith(color: color, fontSize: 24),
        ),
        const SizedBox(height: 4),
        Text(label, style: CozyText.subtitle.copyWith(fontSize: 12)),
      ],
    );
  }

  // ── Item / promise / stat builders ────────────────────────────────────────────

  Widget _summaryItem({
    required int index,
    required List<List<dynamic>> icon,
    required Color iconBg,
    required String title,
    required String subtitle,
  }) {
    return AnimatedOpacity(
      opacity: _visibleItems[index] ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 400),
      child: AnimatedSlide(
        offset: _visibleItems[index] ? Offset.zero : const Offset(0, 0.3),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        child: Row(
          children: [
            CozyIconChip(
              icon: icon,
              background: iconBg,
              iconColor: CozyColors.ink,
              size: 44,
              iconSize: 22,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: CozyText.body),
                  const SizedBox(height: 2),
                  Text(subtitle, style: CozyText.subtitle),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _promiseItem(String text) {
    return Row(
      children: [
        const CozyIconChip(
          icon: HugeIcons.strokeRoundedTick02,
          background: CozyColors.primaryLight,
          iconColor: CozyColors.primaryDark,
          bordered: false,
          circle: true,
          size: 26,
          iconSize: 16,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: CozyText.body.copyWith(fontSize: 15),
          ),
        ),
      ],
    );
  }

  Widget _statDivider() {
    return Container(
      width: 1.5,
      height: 40,
      color: CozyColors.ink.withValues(alpha: 0.12),
    );
  }

  /// Cycling testimonial card — 3 quotes auto-rotated every 4s, with filled
  /// star glyphs and a fixed-height quote area so the card stops jumping.
  Widget _testimonialCarousel() {
    final t = _testimonials[_testimonialIndex];
    return CozyCard(
      color: CozyColors.surfaceMuted,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Solid stars (HugeIcons free pack has no filled variant).
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (_) => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 1.5),
                child: Text(
                  '★',
                  style: TextStyle(
                    fontSize: 16,
                    color: CozyColors.gold,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Fixed-height quote slot keeps the card from jumping between
          // testimonials of slightly different lengths. Sized for a 3-line
          // quote + author at the current font / line-height — bumped up
          // from 78 to absorb the rendering metric overhead that was
          // causing a 6px overflow.
          SizedBox(
            height: 88,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: Column(
                key: ValueKey(_testimonialIndex),
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    t.quoteKey.tr,
                    style: CozyText.body.copyWith(
                      fontStyle: FontStyle.italic,
                      fontSize: 13.5,
                      height: 1.35,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    t.authorKey.tr,
                    style: CozyText.label.copyWith(fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Dots indicator — animated active pill, dim resting dots.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_testimonials.length, (i) {
              final active = i == _testimonialIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 16 : 5,
                height: 5,
                decoration: BoxDecoration(
                  color: active
                      ? CozyColors.gold
                      : CozyColors.inkMuted.withValues(alpha: 0.3),
                  borderRadius:
                      BorderRadius.circular(CozyTokens.radiusPill),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: CozyText.title.copyWith(fontSize: 22),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: CozyText.subtitle.copyWith(fontSize: 11, height: 1.2),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Custom painter for transformation graph (cozy palette).
class TransformationGraphPainter extends CustomPainter {
  final double startValue;
  final double endValue;
  final Color color;

  TransformationGraphPainter({
    required this.startValue,
    required this.endValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.28),
          color.withValues(alpha: 0.04),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // Calculate 14 data points (2 weeks)
    final points = <Offset>[];
    final fillPath = Path();

    for (int i = 0; i <= 14; i++) {
      final x = (i / 14) * size.width;

      // Exponential growth curve
      final progress = i / 14;
      final value =
          startValue + (endValue - startValue) * (1 - math.exp(-3 * progress));

      // Normalize to graph height (growth: low to high). Guard against a
      // zero range (e.g. 0 screen-time) which would yield NaN/Infinity.
      final maxValue = endValue > startValue ? endValue : startValue;
      final normalizedValue = maxValue == 0 ? 0.0 : value / maxValue;
      final y = (1 - normalizedValue) * (size.height - 40) + 20;

      points.add(Offset(x, y));
    }

    // Draw fill
    if (points.isNotEmpty) {
      fillPath.moveTo(points.first.dx, size.height);
      for (final point in points) {
        fillPath.lineTo(point.dx, point.dy);
      }
      fillPath.lineTo(points.last.dx, size.height);
      fillPath.close();
      canvas.drawPath(fillPath, fillPaint);
    }

    // Draw curve line
    if (points.length > 1) {
      final path = Path();
      path.moveTo(points[0].dx, points[0].dy);

      // Smooth curve using quadratic bezier
      for (int i = 0; i < points.length - 1; i++) {
        final p0 = points[i];
        final p1 = points[i + 1];
        final controlPoint = Offset(
          (p0.dx + p1.dx) / 2,
          (p0.dy + p1.dy) / 2,
        );
        path.quadraticBezierTo(
          controlPoint.dx,
          controlPoint.dy,
          p1.dx,
          p1.dy,
        );
      }

      canvas.drawPath(path, paint);
    }

    // Draw data points (dots)
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final dotBorderPaint = Paint()
      ..color = CozyColors.surface
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    // Draw dots at start, middle, and end
    for (int i in [0, 7, 14]) {
      if (i < points.length) {
        canvas.drawCircle(points[i], 5, dotBorderPaint);
        canvas.drawCircle(points[i], 4, dotPaint);
      }
    }

    // Draw grid lines (subtle)
    final gridPaint = Paint()
      ..color = CozyColors.ink.withValues(alpha: 0.08)
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final y = (i / 4) * size.height;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(TransformationGraphPainter oldDelegate) {
    return oldDelegate.startValue != startValue ||
        oldDelegate.endValue != endValue ||
        oldDelegate.color != color;
  }
}
