import 'dart:convert';
import 'package:faithlock/features/faithlock/services/screen_time_service.dart';
import 'package:faithlock/features/onboarding/constants/onboarding_theme.dart';
import 'package:faithlock/services/storage/secure_storage_service.dart';
import 'package:faithlock/shared/widgets/notifications/fast_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

/// Screen for managing lock schedules
/// Allows users to view, edit, enable/disable schedules
class ScheduleManagementScreen extends StatefulWidget {
  const ScheduleManagementScreen({super.key});

  @override
  State<ScheduleManagementScreen> createState() =>
      _ScheduleManagementScreenState();
}

class _ScheduleManagementScreenState extends State<ScheduleManagementScreen> {
  final StorageService _storage = StorageService();
  final ScreenTimeService _screenTimeService = ScreenTimeService();

  List<Map<String, dynamic>> _schedules = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    try {
      final schedulesJson = await _storage.readString('onboarding_schedules');

      if (schedulesJson != null && schedulesJson.isNotEmpty) {
        final List<dynamic> schedulesData = jsonDecode(schedulesJson);
        setState(() {
          _schedules = schedulesData
              .map((s) => Map<String, dynamic>.from(s))
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading schedules: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveAndResetupSchedules() async {
    try {
      await _storage.writeString(
        'onboarding_schedules',
        jsonEncode(_schedules),
      );

      await _screenTimeService.setupSchedules(_schedules);

      if (mounted) {
        FastToast.showSuccess(
          context: context,
          title: 'schedule_schedulesUpdated'.tr,
          message: 'schedule_schedulesUpdatedMsg'.tr,
        );
      }
    } catch (e) {
      debugPrint('Error saving schedules: $e');
      if (mounted) {
        FastToast.showError(
          context: context,
          title: 'settings_error'.tr,
          message: 'schedule_failedUpdateSchedules'.trParams({'error': '$e'}),
        );
      }
    }
  }

  void _toggleSchedule(int index) {
    setState(() {
      _schedules[index]['enabled'] = !_schedules[index]['enabled'];
    });
    _saveAndResetupSchedules();
  }

  Future<void> _editScheduleTime(int index, bool isStart) async {
    final currentHour =
        _schedules[index][isStart ? 'startHour' : 'endHour'] as int;
    final currentMinute =
        _schedules[index][isStart ? 'startMinute' : 'endMinute'] as int;

    DateTime selectedTime = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
      currentHour,
      currentMinute,
    );

    await showCupertinoModalPopup<void>(
      context: context,
      barrierColor: const Color(0x66000000), // 40% black
      builder: (BuildContext ctx) => Container(
        height: 260,
        decoration: BoxDecoration(
          color: CupertinoColors.tertiarySystemGroupedBackground.resolveFrom(ctx),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              // Toolbar
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: CupertinoColors.separator.resolveFrom(ctx),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: Text(
                        'cancel'.tr,
                        style: TextStyle(
                          fontFamily: OnboardingTheme.fontFamily,
                          color: CupertinoColors.secondaryLabel.resolveFrom(ctx),
                          fontSize: 17,
                        ),
                      ),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: Text(
                        'done'.tr,
                        style: TextStyle(
                          fontFamily: OnboardingTheme.fontFamily,
                          color: OnboardingTheme.goldColor,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _schedules[index][isStart ? 'startHour' : 'endHour'] =
                              selectedTime.hour;
                          _schedules[index]
                                  [isStart ? 'startMinute' : 'endMinute'] =
                              selectedTime.minute;
                        });
                        Navigator.of(ctx).pop();
                        _saveAndResetupSchedules();
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: selectedTime,
                  use24hFormat: true,
                  onDateTimeChanged: (DateTime newTime) {
                    selectedTime = newTime;
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoTheme(
      data: CupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: OnboardingTheme.goldColor,
        textTheme: CupertinoTextThemeData(
          primaryColor: OnboardingTheme.goldColor,
        ),
      ),
      child: CupertinoPageScaffold(
        backgroundColor:
            CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context),
        navigationBar: CupertinoNavigationBar(
          middle: Text(
            'schedule_lockSchedules'.tr,
            style: TextStyle(
              fontFamily: OnboardingTheme.fontFamily,
              fontWeight: FontWeight.w600,
              color: OnboardingTheme.labelPrimary,
              fontSize: 17,
            ),
          ),
          backgroundColor: const Color(0x00000000), // transparent
          border: null,
          previousPageTitle: '',
        ),
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator(radius: 14))
            : _schedules.isEmpty
                ? _buildEmptyState(context)
                : _buildScheduleList(context),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.calendar_badge_minus,
              size: 80,
              color: OnboardingTheme.labelTertiary,
            ),
            const SizedBox(height: 24),
            Text(
              'schedule_noSchedulesFound'.tr,
              style: OnboardingTheme.title3.copyWith(
                color: OnboardingTheme.labelPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'schedule_completeOnboarding'.tr,
              style: OnboardingTheme.body.copyWith(
                color: OnboardingTheme.labelSecondary,
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleList(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        Text(
          'schedule_manageDescription'.tr,
          style: OnboardingTheme.body.copyWith(
            color: OnboardingTheme.labelSecondary,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 24),
        ...List.generate(
          _schedules.length,
          (index) => _buildScheduleCard(context, index),
        ),
      ],
    );
  }

  Widget _buildScheduleCard(BuildContext context, int index) {
    final schedule = _schedules[index];
    final isEnabled = schedule['enabled'] as bool;
    final name = schedule['name'] as String;
    final icon = schedule['icon'] as String;
    final startHour = schedule['startHour'] as int;
    final startMinute = schedule['startMinute'] as int;
    final endHour = schedule['endHour'] as int;
    final endMinute = schedule['endMinute'] as int;

    String formatTime(int hour, int minute) {
      return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    }

    final startMinutes = startHour * 60 + startMinute;
    final endMinutes = endHour * 60 + endMinute;
    var durationMinutes = endMinutes - startMinutes;
    if (durationMinutes < 0) durationMinutes += 24 * 60;
    final durationHours = (durationMinutes / 60).floor();
    final durationMins = durationMinutes % 60;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isEnabled
            ? CupertinoColors.tertiarySystemGroupedBackground.resolveFrom(context)
            : CupertinoColors.tertiarySystemGroupedBackground
                .resolveFrom(context)
                .withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(OnboardingTheme.radiusMedium),
        border: Border.all(
          color: isEnabled
              ? OnboardingTheme.goldColor.withValues(alpha: 0.3)
              : OnboardingTheme.cardBorder,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: OnboardingTheme.body.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: isEnabled
                            ? OnboardingTheme.labelPrimary
                            : OnboardingTheme.labelTertiary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${durationHours}h ${durationMins}m lock',
                      style: OnboardingTheme.footnote.copyWith(
                        fontSize: 13,
                        color: OnboardingTheme.labelTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              CupertinoSwitch(
                value: isEnabled,
                activeTrackColor: OnboardingTheme.goldColor,
                onChanged: (_) => _toggleSchedule(index),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _editScheduleTime(index, true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: CupertinoColors.secondarySystemGroupedBackground
                          .resolveFrom(context)
                          .withValues(alpha: isEnabled ? 1.0 : 0.5),
                      borderRadius:
                          BorderRadius.circular(OnboardingTheme.radiusSmall),
                      border: Border.all(
                        color: (isEnabled
                                ? OnboardingTheme.goldColor
                                : OnboardingTheme.labelTertiary)
                            .withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'schedule_startLabel'.tr,
                          style: OnboardingTheme.footnote.copyWith(
                            fontSize: 11,
                            color: OnboardingTheme.labelTertiary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatTime(startHour, startMinute),
                          style: OnboardingTheme.body.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: isEnabled
                                ? OnboardingTheme.goldColor
                                : OnboardingTheme.labelTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '→',
                style: TextStyle(
                  fontSize: 20,
                  color: OnboardingTheme.labelTertiary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => _editScheduleTime(index, false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: CupertinoColors.secondarySystemGroupedBackground
                          .resolveFrom(context)
                          .withValues(alpha: isEnabled ? 1.0 : 0.5),
                      borderRadius:
                          BorderRadius.circular(OnboardingTheme.radiusSmall),
                      border: Border.all(
                        color: (isEnabled
                                ? OnboardingTheme.goldColor
                                : OnboardingTheme.labelTertiary)
                            .withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'schedule_endLabel'.tr,
                          style: OnboardingTheme.footnote.copyWith(
                            fontSize: 11,
                            color: OnboardingTheme.labelTertiary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatTime(endHour, endMinute),
                          style: OnboardingTheme.body.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: isEnabled
                                ? OnboardingTheme.goldColor
                                : OnboardingTheme.labelTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

