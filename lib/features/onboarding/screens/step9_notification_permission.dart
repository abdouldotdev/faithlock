import 'package:faithlock/features/onboarding/controllers/scripture_onboarding_controller.dart';
import 'package:faithlock/features/onboarding/utils/animation_utils.dart';
import 'package:faithlock/features/onboarding/widgets/onboarding_wrapper.dart';
import 'package:faithlock/services/notifications/daily_verse_notification_service.dart';
import 'package:faithlock/services/notifications/local_notification_service.dart';
import 'package:faithlock/services/storage/preferences_service.dart';
import 'package:faithlock/shared/widgets/cozy/cozy.dart';
import 'package:faithlock/shared/widgets/dialogs/fast_confirmation_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';

/// Step 9: Notification Permission — cozy rebuild. Typed intro/explanation,
/// then bell hero + benefits + activate CTA. Daily-verses time picker
/// (V1/V2 only) is also restyled in cozy.
class Step9NotificationPermission extends StatefulWidget {
  /// When provided (V3 flow) the screen acts as a permission-only step: after
  /// the permission response it calls [onComplete] and skips the daily-verse
  /// time selection (handled by the dedicated Daily Verses screen).
  final VoidCallback? onComplete;
  const Step9NotificationPermission({super.key, this.onComplete});

  @override
  State<Step9NotificationPermission> createState() =>
      _Step9NotificationPermissionState();
}

class _Step9NotificationPermissionState
    extends State<Step9NotificationPermission> {
  final controller = Get.find<ScriptureOnboardingController>();
  final LocalNotificationService _notificationService =
      LocalNotificationService();
  final PreferencesService _prefs = PreferencesService();
  final DailyVerseNotificationService _dailyVerseService =
      DailyVerseNotificationService();

  String _currentPhase = 'permission';

  bool _isRequestingPermission = false;

  bool _showTimeSelection = false;
  int _selectedFrequency = 1;
  final List<TimeOfDay> _selectedTimes = [
    const TimeOfDay(hour: 8, minute: 0),
  ];
  bool _isSavingTimes = false;

  double _opacity = 1.0;

  Future<void> _onEnableNotifications() async {
    if (_isRequestingPermission) return;
    await AnimationUtils.heavyHaptic();
    setState(() => _isRequestingPermission = true);

    try {
      await _notificationService.initialize();
      final granted = await _notificationService.requestPermissions();
      debugPrint('📱 [STEP 9] Permission response: $granted');
      await _prefs.writeBool('notification_permission_asked', true);
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      _transitionToTimeSelection();
    } catch (e) {
      debugPrint('❌ Error requesting Notifications permission: $e');
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      _transitionToTimeSelection();
    } finally {
      if (mounted) setState(() => _isRequestingPermission = false);
    }
  }

  void _transitionToTimeSelection() {
    // V3 flow: permission-only step → advance instead of entering the time
    // selection phase (handled by the dedicated Daily Verses screen).
    if (widget.onComplete != null) {
      widget.onComplete!();
      return;
    }
    setState(() {
      _currentPhase = 'timeSelection';
      _showTimeSelection = true;
    });
    AnimationUtils.mediumHaptic();
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
    final picked = await showTimePicker(
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
    if (picked != null) {
      setState(() => _selectedTimes[index] = picked);
      await AnimationUtils.lightHaptic();
    }
  }

  Future<void> _onActivateDailyVerses() async {
    if (_isSavingTimes) return;
    setState(() => _isSavingTimes = true);

    try {
      await AnimationUtils.heavyHaptic();
      await _dailyVerseService.enableWithMultipleTimes(_selectedTimes);
      await controller.completeOnboarding();

      if (!mounted) return;
      setState(() => _opacity = 0.0);
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      controller.nextStep();
    } catch (e) {
      debugPrint('❌ Error saving daily verse times: $e');
      await controller.completeOnboarding();
      if (!mounted) return;
      controller.nextStep();
    } finally {
      if (mounted) setState(() => _isSavingTimes = false);
    }
  }

  // Kept for the V1/V2 flow and in case a skip affordance is re-added; the V3
  // permission phase mirrors the shield step and has no skip button.
  // ignore: unused_element
  Future<void> _onSkipNotifications() async {
    await AnimationUtils.lightHaptic();
    final shouldSkip = await FastConfirmationDialog.show(
      title: 'notifPerm_skipTitle'.tr,
      message: 'notifPerm_skipMessage'.tr,
      confirmText: 'notifPerm_skipForNow'.tr,
      cancelText: 'notifPerm_enableReminders'.tr,
      isDestructiveConfirm: false,
    );
    if (shouldSkip) {
      await _prefs.writeBool('notification_permission_asked', true);
      if (widget.onComplete != null) {
        widget.onComplete!();
      } else {
        await controller.completeOnboarding();
        controller.nextStep();
      }
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'onbNotifPerm_periodAm'.tr : 'onbNotifPerm_periodPm'.tr;
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

  Widget _frequencyChip(int frequency) {
    final isSelected = _selectedFrequency == frequency;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: CozyTappable(
        onTap: () => _onFrequencyChanged(frequency),
        pressedScale: 0.95,
        child: AnimatedContainer(
          duration: CozyTokens.base,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
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
            'onbNotifPerm_frequencyLabel'.trParams({'frequency': frequency.toString()}),
            style: CozyText.body.copyWith(
              color: isSelected ? CozyColors.onPrimary : CozyColors.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  Widget _timePicker(int index) {
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

  Widget _buildPermissionPhase() {
    // Mirrors the Screen Time (shield) step: hero, title, one subtitle, CTA —
    // no benefit list or skip, since notifications are required for the
    // lock/unlock flow (the notification is how we route you to the quiz).
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 156,
          height: 156,
          alignment: Alignment.center,
          decoration: ShapeDecoration(
            color: CozyColors.primaryLight,
            shape: const CircleBorder(
              side: BorderSide(
                color: CozyColors.outline,
                width: CozyTokens.borderWidth,
              ),
            ),
            shadows: CozyTokens.shadowHard,
          ),
          child: const HugeIcon(
            icon: HugeIcons.strokeRoundedBellDot,
            size: 76,
            color: CozyColors.primaryDark,
          ),
        ),
        const SizedBox(height: CozyTokens.space24),
        Text(
          'notifPerm_enableTitle'.tr,
          style: CozyText.title,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: CozyTokens.space12),
        Text(
          'notifPerm_subtitle'.tr,
          style: CozyText.body.copyWith(color: CozyColors.inkMuted),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: CozyTokens.space32),
        CozyButton(
          text: _isRequestingPermission
              ? 'notifPerm_requesting'.tr
              : 'notifPerm_enableBtn'.tr,
          onTap: _isRequestingPermission ? null : _onEnableNotifications,
          isLoading: _isRequestingPermission,
        ),
      ],
    );
  }

  Widget _buildTimeSelectionPhase() {
    return AnimatedOpacity(
      opacity: _showTimeSelection ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 600),
      child: Column(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [1, 2, 3].map(_frequencyChip).toList(),
          ),
          const SizedBox(height: CozyTokens.space24),
          Text(
            'dailyVerses_when'.tr,
            style: CozyText.label.copyWith(color: CozyColors.primary),
          ),
          const SizedBox(height: CozyTokens.space16),
          ...List.generate(_selectedTimes.length, _timePicker),
          const SizedBox(height: CozyTokens.space32),
          CozyButton(
            text: 'dailyVerses_activate'.tr,
            onTap: _isSavingTimes ? null : _onActivateDailyVerses,
            isLoading: _isSavingTimes,
          ),
          const SizedBox(height: CozyTokens.space16),
          CozyTappable(
            onTap: () async {
              await AnimationUtils.lightHaptic();
              await controller.completeOnboarding();
              controller.nextStep();
            },
            child: Text('dailyVerses_later'.tr, style: CozyText.subtitle),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingWrapper(
      child: AnimatedOpacity(
        opacity: _opacity,
        duration: const Duration(milliseconds: 1000),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              24,
              _currentPhase == 'timeSelection' ? 70 : 40,
              24,
              24,
            ),
            child: _currentPhase == 'permission'
                ? _buildPermissionPhase()
                : _buildTimeSelectionPhase(),
          ),
        ),
      ),
    );
  }
}
