import 'dart:math' as math;

import 'package:faithlock/features/onboarding/constants/onboarding_theme.dart';
import 'package:faithlock/features/onboarding/controllers/scripture_onboarding_controller.dart';
import 'package:faithlock/features/onboarding/controllers/scripture_onboarding_v2_controller.dart';
import 'package:faithlock/features/onboarding/utils/animation_utils.dart';
import 'package:faithlock/shared/widgets/buttons/fast_button.dart';
import 'package:faithlock/shared/widgets/mascot/judah_mascot.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// V2 Summary Screen - Personalized projection with milestones
/// Shows Before/After, Week 1 → Week 2 → Month 1 progression,
/// Freedom Projection, Testimonials, and Judah proud
class V2SummaryScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const V2SummaryScreen({
    super.key,
    required this.onComplete,
  });

  @override
  State<V2SummaryScreen> createState() => _V2SummaryScreenState();
}

class _V2SummaryScreenState extends State<V2SummaryScreen>
    with TickerProviderStateMixin {
  final controller =
      Get.find<ScriptureOnboardingController>() as ScriptureOnboardingV2Controller;

  bool _showLoading = true;
  bool _showContent = false;
  bool _showBeforeAfter = false;
  bool _showMilestones = false;
  bool _showFreedomProjection = false;
  bool _showTestimonial = false;
  bool _showMascot = false;
  bool _showButton = false;

  late AnimationController _loadingController;

  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _startAnimation();
  }

  @override
  void dispose() {
    _loadingController.dispose();
    super.dispose();
  }

  Future<void> _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 500));

    // Loading phase
    await Future.delayed(const Duration(milliseconds: 2000));

    setState(() {
      _showLoading = false;
      _showContent = true;
    });
    await AnimationUtils.mediumHaptic();

    // Before/After
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _showBeforeAfter = true);
    await AnimationUtils.lightHaptic();

    // Milestones
    await Future.delayed(const Duration(milliseconds: 600));
    setState(() => _showMilestones = true);
    await AnimationUtils.lightHaptic();

    // Freedom Projection
    await Future.delayed(const Duration(milliseconds: 600));
    setState(() => _showFreedomProjection = true);
    await AnimationUtils.mediumHaptic();

    // Testimonial
    await Future.delayed(const Duration(milliseconds: 600));
    setState(() => _showTestimonial = true);
    await AnimationUtils.lightHaptic();

    // Mascot
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _showMascot = true);
    await AnimationUtils.mediumHaptic();

    // Button
    await Future.delayed(const Duration(milliseconds: 400));
    setState(() => _showButton = true);
    await AnimationUtils.heavyHaptic();
  }

  @override
  Widget build(BuildContext context) {
    final projection = controller.calculateProjection();

    return CupertinoPageScaffold(
      backgroundColor: OnboardingTheme.backgroundColor,
      child: Stack(
        children: [
          // Scrollable content
          Positioned.fill(
            bottom: _showButton ? 120 : 0,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(
                left: OnboardingTheme.horizontalPadding,
                right: OnboardingTheme.horizontalPadding,
                top: 60,
                bottom: OnboardingTheme.verticalPadding,
              ),
              child: Column(
                children: [
                  // Loading
                  if (_showLoading) ...[
                    const SizedBox(height: 100),
                    AnimatedBuilder(
                      animation: _loadingController,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _loadingController.value * 2 * math.pi,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: OnboardingTheme.goldColor,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.shield,
                              size: 40,
                              color: OnboardingTheme.goldColor,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: OnboardingTheme.space24),
                    Text(
                      'summary_loading'.tr,
                      style: OnboardingTheme.callout.copyWith(
                        color: OnboardingTheme.goldColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],

                  // Content
                  if (_showContent) ...[
                    Text(
                      'summary_title'.trParams({'name': controller.userName.value}),
                      style: OnboardingTheme.title2,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: OnboardingTheme.space8),
                    Text(
                      'summary_subtitle'.tr,
                      style: OnboardingTheme.callout,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: OnboardingTheme.space32),

                    // Before / After
                    if (_showBeforeAfter)
                      _buildBeforeAfter(projection),

                    if (_showBeforeAfter)
                      const SizedBox(height: OnboardingTheme.space24),

                    // Milestones
                    if (_showMilestones)
                      _buildMilestones(projection),

                    if (_showMilestones)
                      const SizedBox(height: OnboardingTheme.space24),

                    // Freedom Projection
                    if (_showFreedomProjection)
                      _buildFreedomProjection(projection),

                    if (_showFreedomProjection)
                      const SizedBox(height: OnboardingTheme.space24),

                    // Testimonial
                    if (_showTestimonial)
                      _buildTestimonial(),

                    if (_showTestimonial)
                      const SizedBox(height: OnboardingTheme.space24),

                    // Judah proud
                    if (_showMascot)
                      AnimatedOpacity(
                        opacity: _showMascot ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 600),
                        child: JudahMascot(
                          state: JudahState.proud,
                          size: JudahSize.l,
                          message: 'summary_mascot'.tr,
                        ),
                      ),

                    const SizedBox(height: 60),
                  ],
                ],
              ),
            ),
          ),

          // Fixed button at bottom
          if (_showButton)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      OnboardingTheme.backgroundColor.withValues(alpha: 0),
                      OnboardingTheme.backgroundColor,
                      OnboardingTheme.backgroundColor,
                    ],
                    stops: const [0.0, 0.3, 1.0],
                  ),
                ),
                padding: const EdgeInsets.only(
                  left: 40,
                  right: 40,
                  top: 30,
                  bottom: 50,
                ),
                child: AnimatedOpacity(
                  opacity: _showButton ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 400),
                  child: FastButton(
                    text: 'continue_btn'.tr,
                    onTap: () async {
                      await AnimationUtils.heavyHaptic();
                      await controller.completeSummary();
                      widget.onComplete();
                    },
                    backgroundColor: OnboardingTheme.goldColor,
                    textColor: OnboardingTheme.backgroundColor,
                    style: FastButtonStyle.filled,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBeforeAfter(Map<String, dynamic> p) {
    return AnimatedOpacity(
      opacity: _showBeforeAfter ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      child: Container(
        padding: const EdgeInsets.all(OnboardingTheme.space20),
        decoration: OnboardingTheme.cardDecoration,
        child: Column(
          children: [
            Text(
              'summary_realityToday'.tr,
              style: OnboardingTheme.callout.copyWith(
                color: OnboardingTheme.labelPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: OnboardingTheme.space16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn(
                  '${(p['currentHours'] as double).toStringAsFixed(1)}h',
                  'summary_phonePerDay'.tr,
                  OnboardingTheme.systemRed,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: OnboardingTheme.cardBorder,
                ),
                _buildStatColumn(
                  '${p['currentPrayer']}x',
                  'summary_prayerPerWeek'.tr,
                  OnboardingTheme.systemOrange,
                ),
              ],
            ),
            const SizedBox(height: OnboardingTheme.space20),
            const Icon(Icons.arrow_downward,
                color: OnboardingTheme.goldColor, size: 24),
            const SizedBox(height: OnboardingTheme.space12),
            Text(
              'summary_afterOneMonth'.tr,
              style: OnboardingTheme.callout.copyWith(
                color: OnboardingTheme.goldColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: OnboardingTheme.space16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn(
                  '${(p['month1Hours'] as double).toStringAsFixed(1)}h',
                  'summary_phonePerDay'.tr,
                  OnboardingTheme.systemGreen,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: OnboardingTheme.cardBorder,
                ),
                _buildStatColumn(
                  '${p['month1Prayer']}x',
                  'summary_prayerPerWeek'.tr,
                  OnboardingTheme.systemGreen,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMilestones(Map<String, dynamic> p) {
    return AnimatedOpacity(
      opacity: _showMilestones ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      child: Container(
        padding: const EdgeInsets.all(OnboardingTheme.space20),
        decoration: OnboardingTheme.cardDecoration,
        child: Column(
          children: [
            Text(
              'summary_milestones'.tr,
              style: OnboardingTheme.callout.copyWith(
                color: OnboardingTheme.labelPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: OnboardingTheme.space16),
            _buildMilestoneRow(
              'summary_week1'.tr,
              '${(p['week1Hours'] as double).toStringAsFixed(1)}h ${'summary_screenTime'.tr}',
              OnboardingTheme.systemOrange,
            ),
            const SizedBox(height: OnboardingTheme.space12),
            _buildMilestoneRow(
              'summary_week2'.tr,
              '${(p['week2Hours'] as double).toStringAsFixed(1)}h ${'summary_screenTime'.tr}',
              OnboardingTheme.goldColor,
            ),
            const SizedBox(height: OnboardingTheme.space12),
            _buildMilestoneRow(
              'summary_month1'.tr,
              '${(p['month1Hours'] as double).toStringAsFixed(1)}h ${'summary_screenTime'.tr}',
              OnboardingTheme.systemGreen,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMilestoneRow(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: OnboardingTheme.subhead.copyWith(
            color: OnboardingTheme.labelPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: OnboardingTheme.subhead.copyWith(color: color),
        ),
      ],
    );
  }

  Widget _buildFreedomProjection(Map<String, dynamic> p) {
    final dailyReclaimed = p['dailyReclaimed'] as double;
    final yearlyDays = p['yearlyReclaimedDays'] as int;

    return AnimatedOpacity(
      opacity: _showFreedomProjection ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      child: Container(
        padding: const EdgeInsets.all(OnboardingTheme.space20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              OnboardingTheme.goldColor.withValues(alpha: 0.12),
              OnboardingTheme.goldColor.withValues(alpha: 0.03),
            ],
          ),
          borderRadius: BorderRadius.circular(OnboardingTheme.radiusLarge),
          border: Border.all(
            color: OnboardingTheme.goldColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            const Icon(Icons.access_time_filled,
                color: OnboardingTheme.goldColor, size: 32),
            const SizedBox(height: OnboardingTheme.space12),
            Text(
              'summary_freedom'.tr,
              style: OnboardingTheme.callout.copyWith(
                color: OnboardingTheme.goldColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: OnboardingTheme.space16),
            Text(
              '+${dailyReclaimed.toStringAsFixed(1)}h',
              style: OnboardingTheme.displayNumber.copyWith(
                color: OnboardingTheme.goldColor,
                fontSize: 48,
              ),
            ),
            Text(
              'summary_reclaimedDaily'.tr,
              style: OnboardingTheme.subhead.copyWith(
                color: OnboardingTheme.labelSecondary,
              ),
            ),
            const SizedBox(height: OnboardingTheme.space16),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: OnboardingTheme.goldColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'summary_daysReclaimedYear'.trParams({'days': yearlyDays.toString()}),
                style: OnboardingTheme.footnote.copyWith(
                  color: OnboardingTheme.goldColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestimonial() {
    return AnimatedOpacity(
      opacity: _showTestimonial ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: OnboardingTheme.space20,
          vertical: OnboardingTheme.space16,
        ),
        decoration: BoxDecoration(
          color: OnboardingTheme.cardBackground,
          borderRadius:
              BorderRadius.circular(OnboardingTheme.radiusMedium),
          border: Border.all(
            color: OnboardingTheme.goldColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (index) => const Icon(
                  Icons.star,
                  size: 16,
                  color: OnboardingTheme.goldColor,
                ),
              ),
            ),
            const SizedBox(height: OnboardingTheme.space12),
            Text(
              'summary_testimonial'.tr,
              style: OnboardingTheme.subhead.copyWith(
                color: OnboardingTheme.labelPrimary,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: OnboardingTheme.space12),
            Text(
              'summary_testimonialAuthor'.tr,
              style: OnboardingTheme.caption.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: OnboardingTheme.title3.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: OnboardingTheme.caption.copyWith(
            color: OnboardingTheme.labelSecondary,
          ),
        ),
      ],
    );
  }
}
