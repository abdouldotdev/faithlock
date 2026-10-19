import 'package:faithlock/features/faithlock/controllers/schedule_controller.dart';
import 'package:faithlock/features/onboarding/constants/onboarding_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

/// Schedule Management Screen
/// Manage lock schedules from onboarding
class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ScheduleController());

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
          middle: Obx(() => Text(
                'schedule_appsCount'
                    .trParams({'count': '${controller.selectedAppsCount.value}'}),
                style: const TextStyle(
                  fontFamily: OnboardingTheme.fontFamily,
                  fontWeight: FontWeight.w600,
                  color: OnboardingTheme.labelPrimary,
                  fontSize: 17,
                ),
              )),
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: controller.testScheduleMonitoring,
            child: const Icon(
              CupertinoIcons.lab_flask,
              color: OnboardingTheme.goldColor,
              size: 22,
            ),
          ),
          backgroundColor: CupertinoColors.systemBackground.resolveFrom(context)
              .withValues(alpha: 0.85),
          border: Border(
            bottom: BorderSide(
              color: CupertinoColors.separator.resolveFrom(context),
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(
                child: CupertinoActivityIndicator(radius: 16),
              );
            }

            if (controller.errorMessage.value.isNotEmpty) {
              return _buildErrorState(context, controller);
            }

            if (controller.schedules.isEmpty) {
              return _buildEmptyState(context);
            }

            return _buildScheduleList(context, controller);
          }),
        ),
      ),
    );
  }

  Widget _buildErrorState(
      BuildContext context, ScheduleController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_circle,
              size: 64,
              color: CupertinoColors.systemRed,
            ),
            const SizedBox(height: 16),
            Text(
              controller.errorMessage.value,
              style: OnboardingTheme.body.copyWith(
                color: OnboardingTheme.labelSecondary,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CupertinoButton.filled(
              onPressed: controller.loadSchedules,
              child: Text(
                'retry'.tr,
                style: const TextStyle(
                  fontFamily: OnboardingTheme.fontFamily,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
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
              'schedule_noSchedules'.tr,
              style: OnboardingTheme.title3.copyWith(
                color: OnboardingTheme.labelPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'schedule_completeOnboarding'.tr,
              style: OnboardingTheme.body.copyWith(
                color: OnboardingTheme.labelSecondary,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleList(
      BuildContext context, ScheduleController controller) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      itemCount: controller.schedules.length,
      itemBuilder: (context, index) {
        final schedule = controller.schedules[index];
        final isActive = controller.isScheduleActive(schedule);
        final isEnabled = schedule['enabled'] as bool;
        final name = schedule['name'] as String;
        final icon = schedule['icon'] as String;
        final startHour = schedule['startHour'] as int;
        final startMinute = schedule['startMinute'] as int;
        final endHour = schedule['endHour'] as int;
        final endMinute = schedule['endMinute'] as int;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isActive
                  ? OnboardingTheme.goldColor.withValues(alpha: 0.1)
                  : CupertinoColors.tertiarySystemGroupedBackground
                      .resolveFrom(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive
                    ? OnboardingTheme.goldColor
                    : isEnabled
                        ? OnboardingTheme.goldColor.withValues(alpha: 0.3)
                        : CupertinoColors.separator.resolveFrom(context),
                width: isActive ? 2 : 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
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
                              color: OnboardingTheme.labelPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            controller.getScheduleDuration(schedule),
                            style: OnboardingTheme.footnote.copyWith(
                              color: OnboardingTheme.labelPrimary.withValues(
                                alpha: isEnabled ? 0.5 : 0.3,
                              ),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    CupertinoSwitch(
                      value: isEnabled,
                      activeTrackColor: OnboardingTheme.goldColor,
                      onChanged: (_) =>
                          controller.toggleScheduleEnabled(index),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                Container(
                  height: 0.5,
                  color: CupertinoColors.separator.resolveFrom(context),
                ),
                const SizedBox(height: 12),

                // Time display row
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            controller.editScheduleTime(index, true),
                        child: _buildTimeCell(
                          context: context,
                          label: 'schedule_start'.tr,
                          time: controller.formatTime(
                              startHour, startMinute),
                          isEnabled: isEnabled,
                        ),
                      ),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '→',
                        style: TextStyle(
                          fontSize: 20,
                          color: OnboardingTheme.labelTertiary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            controller.editScheduleTime(index, false),
                        child: _buildTimeCell(
                          context: context,
                          label: 'schedule_end'.tr,
                          time: controller.formatTime(
                              endHour, endMinute),
                          isEnabled: isEnabled,
                        ),
                      ),
                    ),
                  ],
                ),

                if (isEnabled && isActive) ...[
                  const SizedBox(height: 12),
                  Obx(() => Row(
                        children: [
                          Icon(
                            controller.isScreenTimeAuthorized.value &&
                                    controller.selectedAppsCount.value > 0
                                ? CupertinoIcons.lock_fill
                                : CupertinoIcons.calendar,
                            size: 16,
                            color: controller.isScreenTimeAuthorized.value &&
                                    controller.selectedAppsCount.value > 0
                                ? OnboardingTheme.goldColor
                                : CupertinoColors.systemOrange,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              controller.isScreenTimeAuthorized.value &&
                                      controller.selectedAppsCount.value > 0
                                  ? 'schedule_activeBlocked'.tr
                                  : 'schedule_activePeriod'.tr,
                              style: OnboardingTheme.footnote.copyWith(
                                color: controller.isScreenTimeAuthorized
                                            .value &&
                                        controller.selectedAppsCount.value > 0
                                    ? OnboardingTheme.goldColor
                                    : CupertinoColors.systemOrange,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      )),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimeCell({
    required BuildContext context,
    required String label,
    required String time,
    required bool isEnabled,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (isEnabled
                  ? OnboardingTheme.goldColor
                  : CupertinoColors.quaternaryLabel.resolveFrom(context))
              .withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: OnboardingTheme.caption.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: OnboardingTheme.labelPrimary.withValues(
                alpha: isEnabled ? 0.6 : 0.3,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            time,
            style: OnboardingTheme.body.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: OnboardingTheme.labelPrimary.withValues(
                alpha: isEnabled ? 1.0 : 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
