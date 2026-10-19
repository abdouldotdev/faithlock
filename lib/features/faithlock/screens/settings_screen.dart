import 'package:faithlock/features/faithlock/controllers/faithlock_settings_controller.dart';
import 'package:faithlock/features/onboarding/constants/onboarding_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

/// Premium iOS-style Settings Screen
/// Manage permissions and app configuration
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(FaithLockSettingsController());

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
        child: CustomScrollView(
          slivers: [
            CupertinoSliverNavigationBar(
              largeTitle: Text(
                'settings'.tr,
                style: const TextStyle(
                  fontFamily: OnboardingTheme.fontFamily,
                  fontWeight: FontWeight.bold,
                  color: OnboardingTheme.labelPrimary,
                ),
              ),
              backgroundColor:
                  CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context)
                      .withValues(alpha: 0.92),
              border: Border(
                bottom: BorderSide(
                  color: CupertinoColors.separator.resolveFrom(context),
                  width: 0.5,
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Personal Section
                    _buildSectionLabel('settings_personal'.tr, context),
                    _buildPersonalSection(context, controller),

                    const SizedBox(height: 32),

                    // Permissions Section
                    _buildSectionLabel('permissions'.tr, context),
                    _buildPermissionsSection(context, controller),

                    const SizedBox(height: 32),

                    // App Behavior Section
                    _buildSectionLabel('appBehavior'.tr, context),
                    _buildBehaviorSection(context, controller),

                    const SizedBox(height: 32),

                    // About Section
                    _buildSectionLabel('about'.tr, context),
                    _buildAboutSection(context, controller),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String title, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, bottom: 8, top: 0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontFamily: OnboardingTheme.fontFamily,
          color: CupertinoColors.secondaryLabel.resolveFrom(context),
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildPersonalSection(
      BuildContext context, FaithLockSettingsController controller) {
    return CupertinoListSection.insetGrouped(
      backgroundColor:
          CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context),
      decoration: BoxDecoration(
        color: CupertinoColors.tertiarySystemGroupedBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        Obx(() => CupertinoListTile(
              leading: _buildIconBadge(
                CupertinoIcons.person,
                OnboardingTheme.goldColor,
              ),
              title: Text(
                'settings_age'.tr,
                style: _tileTitleStyle,
              ),
              subtitle: Text(
                controller.ageSkipped.value || controller.userAge.value == 0
                    ? 'settings_ageNotSet'.tr
                    : 'settings_ageValue'.trParams({
                        'age': controller.userAge.value.toString(),
                      }),
                style: _tileSubtitleStyle(context),
              ),
              trailing: const CupertinoListTileChevron(),
              onTap: () => controller.showAgePicker(),
            )),
      ],
    );
  }

  Widget _buildPermissionsSection(
      BuildContext context, FaithLockSettingsController controller) {
    return CupertinoListSection.insetGrouped(
      backgroundColor:
          CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context),
      decoration: BoxDecoration(
        color: CupertinoColors.tertiarySystemGroupedBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // Screen Time Permission
        Obx(() => _buildPermissionTile(
              context: context,
              icon: CupertinoIcons.device_phone_portrait,
              title: 'screenTime'.tr,
              subtitle: 'screenTimeRequired'.tr,
              status: controller.screenTimeStatus.value,
              isAuthorized: controller.isScreenTimeAuthorized.value,
              onTap: () => controller.requestScreenTimePermission(),
            )),

        // Notifications Permission
        Obx(() => _buildPermissionTile(
              context: context,
              icon: CupertinoIcons.bell,
              title: 'notifications'.tr,
              subtitle: 'notificationsSub'.tr,
              status: controller.notificationsStatus.value,
              isAuthorized: controller.isNotificationsAuthorized.value,
              onTap: () => controller.requestNotificationsPermission(),
            )),
      ],
    );
  }

  Widget _buildBehaviorSection(
      BuildContext context, FaithLockSettingsController controller) {
    return CupertinoListSection.insetGrouped(
      backgroundColor:
          CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context),
      decoration: BoxDecoration(
        color: CupertinoColors.tertiarySystemGroupedBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // Master Lock Toggle
        Obx(() => CupertinoListTile(
              leading: _buildIconBadge(
                CupertinoIcons.lock_shield,
                OnboardingTheme.goldColor,
              ),
              title: Text('enableLockSystem'.tr, style: _tileTitleStyle),
              subtitle: Text('masterSwitch'.tr,
                  style: _tileSubtitleStyle(context)),
              trailing: CupertinoSwitch(
                value: controller.isLockEnabled.value,
                activeTrackColor: OnboardingTheme.goldColor,
                onChanged: (value) => controller.toggleLockEnabled(value),
              ),
            )),

        // Notifications Toggle
        Obx(() => CupertinoListTile(
              leading: _buildIconBadge(
                CupertinoIcons.bell,
                OnboardingTheme.goldColor,
              ),
              title:
                  Text('enableNotifications'.tr, style: _tileTitleStyle),
              subtitle: Text(
                controller.isNotificationsAuthorized.value
                    ? 'enableNotificationsSub'.tr
                    : 'tapToEnableNotifications'.tr,
                style: _tileSubtitleStyle(context),
              ),
              trailing: CupertinoSwitch(
                value: controller.isNotificationsAuthorized.value,
                activeTrackColor: OnboardingTheme.goldColor,
                onChanged: (value) async {
                  await controller.requestNotificationsPermission();
                },
              ),
            )),

        // Emergency Bypass
        CupertinoListTile(
          leading: _buildIconBadge(
            CupertinoIcons.exclamationmark_triangle,
            CupertinoColors.systemOrange,
          ),
          title:
              Text('emergencyBypass'.tr, style: _tileTitleStyle),
          subtitle: Text('emergencyBypassSub'.tr,
              style: _tileSubtitleStyle(context)),
          trailing: const CupertinoListTileChevron(),
          onTap: () => controller.showEmergencyBypassInfo(),
        ),

        // Select Apps to Block
        Obx(() {
          String subtitle;
          if (!controller.isScreenTimeAuthorized.value) {
            subtitle = 'screenTimePermRequired'.tr;
          } else if (controller.selectedAppsCount.value > 0) {
            subtitle = 'appsConfigured'.tr;
          } else {
            subtitle = 'noAppsSelected'.tr;
          }

          return CupertinoListTile(
            leading: _buildIconBadge(
              CupertinoIcons.square_grid_2x2,
              OnboardingTheme.goldColor,
            ),
            title: Text('blockedApps'.tr, style: _tileTitleStyle),
            subtitle: Text(subtitle, style: _tileSubtitleStyle(context)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (controller.selectedAppsCount.value > 0)
                  const Icon(
                    CupertinoIcons.checkmark_circle_fill,
                    color: CupertinoColors.systemGreen,
                    size: 20,
                  ),
                if (controller.selectedAppsCount.value > 0)
                  const SizedBox(width: 8),
                const CupertinoListTileChevron(),
              ],
            ),
            onTap: controller.isScreenTimeAuthorized.value
                ? () => controller.showBlockedApps()
                : null,
          );
        }),
      ],
    );
  }

  Widget _buildAboutSection(
      BuildContext context, FaithLockSettingsController controller) {
    return CupertinoListSection.insetGrouped(
      backgroundColor:
          CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context),
      decoration: BoxDecoration(
        color: CupertinoColors.tertiarySystemGroupedBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        CupertinoListTile(
          leading:
              _buildIconBadge(CupertinoIcons.info_circle, OnboardingTheme.goldColor),
          title: Text('aboutFaithLock'.tr, style: _tileTitleStyle),
          subtitle: Text(
            'version'.trParams({'version': '1.0.0'}),
            style: _tileSubtitleStyle(context),
          ),
          trailing: const CupertinoListTileChevron(),
          onTap: () => controller.showAboutInfo(),
        ),
        CupertinoListTile(
          leading:
              _buildIconBadge(CupertinoIcons.doc_text, OnboardingTheme.goldColor),
          title: Text('privacyPolicy'.tr, style: _tileTitleStyle),
          subtitle:
              Text('privacyPolicySub'.tr, style: _tileSubtitleStyle(context)),
          trailing: const CupertinoListTileChevron(),
          onTap: () => controller.openPrivacyPolicy(),
        ),
        CupertinoListTile(
          leading: _buildIconBadge(CupertinoIcons.heart, OnboardingTheme.goldColor),
          title: Text('support'.tr, style: _tileTitleStyle),
          subtitle: Text('supportSub'.tr, style: _tileSubtitleStyle(context)),
          trailing: const CupertinoListTileChevron(),
          onTap: () => controller.openSupport(),
        ),
      ],
    );
  }

  Widget _buildPermissionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required String status,
    required bool isAuthorized,
    required VoidCallback onTap,
  }) {
    final statusColor =
        isAuthorized ? CupertinoColors.systemGreen : CupertinoColors.systemOrange;

    return CupertinoListTile(
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: statusColor, size: 18),
      ),
      title: Text(title, style: _tileTitleStyle),
      subtitle: Text(subtitle, style: _tileSubtitleStyle(context)),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          status,
          style: TextStyle(
            fontFamily: OnboardingTheme.fontFamily,
            color: statusColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildIconBadge(IconData icon, Color color) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }

  TextStyle get _tileTitleStyle => const TextStyle(
        fontFamily: OnboardingTheme.fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: OnboardingTheme.labelPrimary,
      );

  TextStyle _tileSubtitleStyle(BuildContext context) => TextStyle(
        fontFamily: OnboardingTheme.fontFamily,
        fontSize: 13,
        color: CupertinoColors.secondaryLabel.resolveFrom(context),
      );
}
