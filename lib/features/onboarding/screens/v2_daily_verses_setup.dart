import 'package:faithlock/features/onboarding/controllers/scripture_onboarding_controller.dart';
import 'package:faithlock/features/onboarding/controllers/scripture_onboarding_v2_controller.dart';
import 'package:faithlock/features/onboarding/utils/animation_utils.dart';
import 'package:faithlock/features/onboarding/widgets/onboarding_wrapper.dart';
import 'package:faithlock/services/notifications/daily_verse_notification_service.dart';
import 'package:faithlock/shared/widgets/cozy/cozy.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';

/// V2 Daily Verses Setup — cozy rebuild. Replaces the notification-permission
/// step with a value-driven verse delivery setup: lion hero with a thought
/// bubble, then frequency chips, then per-time pickers.
class V2DailyVersesSetup extends StatefulWidget {
  final VoidCallback onComplete;

  const V2DailyVersesSetup({
    super.key,
    required this.onComplete,
  });

  @override
  State<V2DailyVersesSetup> createState() => _V2DailyVersesSetupState();
}

class _V2DailyVersesSetupState extends State<V2DailyVersesSetup> {
  final controller = Get.find<ScriptureOnboardingController>()
      as ScriptureOnboardingV2Controller;

  bool _showContent = false;
  int _step = 0; // 0 = frequency, 1 = times
  static const _stepCount = 2;
  int _selectedFrequency = 1;

  final List<TimeOfDay> _selectedTimes = [
    const TimeOfDay(hour: 8, minute: 0),
  ];

  double _opacity = 1.0;

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  Future<void> _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 400));
    setState(() => _showContent = true);
    await AnimationUtils.mediumHaptic();
  }

  void _onFrequencyChanged(int frequency) {
    setState(() {
      _selectedFrequency = frequency;
      _selectedTimes.clear();
      if (frequency >= 1) {
        _selectedTimes.add(const TimeOfDay(hour: 8, minute: 0));
      }
      if (frequency >= 2) {
        _selectedTimes.add(const TimeOfDay(hour: 12, minute: 30));
      }
      if (frequency >= 3) {
        _selectedTimes.add(const TimeOfDay(hour: 20, minute: 0));
      }
    });
    AnimationUtils.lightHaptic();
  }

  Future<void> _showTimePicker(int index) async {
    final currentTime = _selectedTimes[index];
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    TimeOfDay? picked;

    if (isIOS) {
      var temp = currentTime;
      await showCupertinoModalPopup(
        context: context,
        builder: (ctx) {
          return Container(
            height: 300,
            color: CozyColors.surface,
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CupertinoButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(
                            'cancel'.tr,
                            style: CozyText.body
                                .copyWith(color: CozyColors.inkMuted),
                          ),
                        ),
                        CupertinoButton(
                          onPressed: () {
                            picked = temp;
                            Navigator.pop(ctx);
                          },
                          child: Text(
                            'done'.tr,
                            style: CozyText.body.copyWith(
                              color: CozyColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: CupertinoTheme(
                      data: const CupertinoThemeData(
                        textTheme: CupertinoTextThemeData(
                          dateTimePickerTextStyle: TextStyle(
                            color: CozyColors.ink,
                            fontSize: 22,
                          ),
                        ),
                      ),
                      child: CupertinoDatePicker(
                        mode: CupertinoDatePickerMode.time,
                        use24hFormat: false,
                        initialDateTime: DateTime(2026, 1, 1,
                            currentTime.hour, currentTime.minute),
                        onDateTimeChanged: (dt) {
                          temp =
                              TimeOfDay(hour: dt.hour, minute: dt.minute);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } else {
      picked = await showTimePicker(
        context: context,
        initialTime: currentTime,
        builder: (context, child) {
          return Theme(
            data: ThemeData.light().copyWith(
              colorScheme: const ColorScheme.light(
                primary: CozyColors.primary,
                surface: CozyColors.surface,
                onSurface: CozyColors.ink,
              ),
            ),
            child: child!,
          );
        },
      );
    }

    if (picked != null) {
      setState(() => _selectedTimes[index] = picked!);
      await AnimationUtils.lightHaptic();
    }
  }

  Future<void> _onActivate() async {
    await AnimationUtils.heavyHaptic();
    await controller.saveDailyVerseFrequency(_selectedFrequency);
    await controller.saveDailyVerseTimes(_selectedTimes);

    // Notification permission is requested once, by the dedicated permission
    // step after Screen Time — not here. We only schedule; delivery starts once
    // that step grants permission (the app also reschedules on each launch).
    final dailyVerseService = DailyVerseNotificationService();
    await dailyVerseService.enableWithMultipleTimes(_selectedTimes);

    setState(() => _opacity = 0.0);
    await Future.delayed(const Duration(milliseconds: 800));
    widget.onComplete();
  }

  Future<void> _onSkip() async {
    await AnimationUtils.lightHaptic();
    setState(() => _opacity = 0.0);
    await Future.delayed(const Duration(milliseconds: 600));
    widget.onComplete();
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am
        ? 'onbDailyVersesSetup_periodAM'.tr
        : 'onbDailyVersesSetup_periodPM'.tr;
    return '$hour:$minute $period';
  }

  String _getTimeLabel(int index) {
    switch (index) {
      case 0:
        return 'dailyVerses_morning'.tr;
      case 1:
        return 'dailyVerses_afternoon'.tr;
      case 2:
        return 'dailyVerses_evening'.tr;
      default:
        return '';
    }
  }

  Future<void> _goToTimes() async {
    await AnimationUtils.lightHaptic();
    setState(() => _step = 1);
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingWrapper(
      child: AnimatedOpacity(
        opacity: _opacity,
        duration: const Duration(milliseconds: 800),
        child: AnimatedOpacity(
          opacity: _showContent ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 600),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
            child: Column(
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
                      child: SingleChildScrollView(child: _buildStep()),
                    ),
                  ),
                ),
                const SizedBox(height: CozyTokens.space16),
                CozyButton(
                  text: _step == _stepCount - 1
                      ? 'dailyVerses_activate'.tr
                      : 'onbDailyVersesSetup_nextButton'.tr,
                  onTap: _step == _stepCount - 1 ? _onActivate : _goToTimes,
                ),
                const SizedBox(height: CozyTokens.space12),
                CozyTappable(
                  onTap: _onSkip,
                  child: Text(
                    'dailyVerses_later'.tr,
                    style: CozyText.subtitle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return Column(
          children: [
            Text(
              'dailyVerses_title'.tr,
              style: CozyText.title,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: CozyTokens.space8),
            Text(
              'dailyVerses_subtitle'.tr,
              style: CozyText.body.copyWith(color: CozyColors.inkMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: CozyTokens.space32),
            Text(
              'dailyVerses_frequency'.tr,
              style: CozyText.label.copyWith(color: CozyColors.primary),
            ),
            const SizedBox(height: CozyTokens.space16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final f in [1, 2, 3])
                  Padding(
                    padding: const EdgeInsets.only(bottom: CozyTokens.space12),
                    child: _buildFrequencyChip(f),
                  ),
              ],
            ),
          ],
        );
      case 1:
      default:
        return Column(
          children: [
            Text(
              'dailyVerses_when'.tr,
              style: CozyText.title,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: CozyTokens.space24),
            ...List.generate(_selectedTimes.length, _buildTimePicker),
          ],
        );
    }
  }

  Widget _buildFrequencyChip(int frequency) {
    final isSelected = _selectedFrequency == frequency;
    return CozyTappable(
      onTap: () => _onFrequencyChanged(frequency),
      pressedScale: 0.98,
      child: AnimatedContainer(
        duration: CozyTokens.base,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: ShapeDecoration(
          color: isSelected ? CozyColors.primary : CozyColors.surface,
          shape: CozyTokens.smooth(
            CozyTokens.radiusLg,
            side: BorderSide(
              color: isSelected ? CozyColors.primary : CozyColors.outline,
              width: CozyTokens.borderWidth,
            ),
          ),
          shadows: CozyTokens.shadowHard,
        ),
        child: Text(
          // Universal count token ("1x" / "2x" / "3x") — no localization needed;
          // built directly to avoid the broken ${...} interpolation in i18n.
          '${frequency}x',
          style: CozyText.body.copyWith(
            color: isSelected ? CozyColors.onPrimary : CozyColors.ink,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildTimePicker(int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: CozyTokens.space12),
      child: CozyTappable(
        onTap: () => _showTimePicker(index),
        pressedScale: 0.98,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: ShapeDecoration(
            color: CozyColors.surface,
            shape: CozyTokens.smooth(
              CozyTokens.radiusLg,
              side: const BorderSide(
                color: CozyColors.outline,
                width: CozyTokens.borderWidth,
              ),
            ),
            shadows: CozyTokens.shadowHard,
          ),
          child: Row(
            children: [
              const HugeIcon(
                icon: HugeIcons.strokeRoundedClock01,
                color: CozyColors.primary,
                size: 22,
              ),
              const SizedBox(width: 12),
              Text(_getTimeLabel(index), style: CozyText.subtitle),
              const Spacer(),
              Text(
                _formatTime(_selectedTimes[index]),
                style: CozyText.body.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 8),
              const Icon(
                CupertinoIcons.chevron_right,
                color: CozyColors.inkMuted,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

