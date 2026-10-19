import 'package:faithlock/config/app_config.dart';
import 'package:faithlock/features/faithlock/controllers/faithlock_settings_controller.dart';
import 'package:faithlock/features/faithlock/controllers/stats_controller.dart';
import 'package:faithlock/features/faithlock/models/export.dart';
import 'package:faithlock/features/faithlock/services/export.dart';
import 'package:faithlock/features/onboarding/constants/onboarding_theme.dart';
import 'package:faithlock/features/onboarding/controllers/scripture_onboarding_controller.dart';
import 'package:faithlock/features/onboarding/screens/scripture_onboarding_v3_screen.dart';
import 'package:faithlock/features/paywall/screens/paywall_screen_v2.dart';
import 'package:faithlock/features/profile/controllers/settings_controller.dart';
import 'package:faithlock/services/notifications/daily_verse_notification_service.dart';
import 'package:faithlock/services/notifications/local_notification_service.dart';
import 'package:faithlock/services/notifications/winback_notification_service.dart';
import 'package:faithlock/services/subscription/revenuecat_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:get/get.dart';

class ProfileScreen extends StatelessWidget {
  ProfileScreen({super.key});

  final SettingsController settingsController = Get.put(SettingsController());

  // Use lazy initialization to avoid blocking UI
  FaithLockSettingsController get faithLockController =>
      Get.put(FaithLockSettingsController());

  // Stats controller — already initialized by the Today tab; find or put lazily
  StatsController get statsController => Get.isRegistered<StatsController>()
      ? Get.find<StatsController>()
      : Get.put(StatsController());

  @override
  Widget build(BuildContext context) {
    final bool isIOS = GetPlatform.isIOS;

    if (isIOS) {
      return _buildIOSProfileScreen(context);
    } else {
      return _buildAndroidProfileScreen(context);
    }
  }

  // iOS Native Style
  Widget _buildIOSProfileScreen(BuildContext context) {
    // Force dark Cupertino brightness so system colors resolve to Apple's
    // dark-gray surfaces (#1C1C1E / #2C2C2E) like the rest of the app —
    // otherwise this screen follows the system theme and renders white.
    return CupertinoTheme(
      data: const CupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: OnboardingTheme.goldColor,
      ),
      child: Builder(
        builder: (context) => CupertinoPageScaffold(
          backgroundColor: CupertinoColors.secondarySystemGroupedBackground
              .resolveFrom(context),
          child: SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _buildIOSSettingsList(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIOSSettingsList(BuildContext context) {
    final appFeatures = AppConfig.appFeatures;

    return Column(
      children: [
        // App Settings Section
        _buildIOSSection([
          // _buildIOSListTile(
          //   context,
          //   leading: CupertinoIcons.lock_shield_fill,
          //   title: 'FaithLock Settings',
          //   subtitle: 'Manage permissions & app blocking',
          //   iconColor: CupertinoColors.systemPurple,
          //   onTap: () => Get.to(() => const SettingsScreen()),
          // ),
          // Blocked Apps - Direct access
          Obx(() {
            String subtitle;
            if (!faithLockController.isScreenTimeAuthorized.value) {
              subtitle = 'screenTimePermRequired'.tr;
            } else if (faithLockController.selectedAppsCount.value > 0) {
              subtitle = 'appsConfigured'.tr;
            } else {
              subtitle = 'noAppsSelected'.tr;
            }

            return _buildIOSListTile(
              context,
              leading: CupertinoIcons.square_grid_2x2,
              title: 'blockedApps'.tr,
              subtitle: subtitle,
              iconColor: CupertinoColors.systemRed,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (faithLockController.selectedAppsCount.value > 0)
                    Icon(
                      CupertinoIcons.checkmark_circle_fill,
                      color: CupertinoColors.systemGreen,
                      size: 20,
                    ),
                  if (faithLockController.selectedAppsCount.value > 0)
                    const SizedBox(width: 8),
                  Icon(
                    CupertinoIcons.chevron_forward,
                    color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                    size: 16,
                  ),
                ],
              ),
              onTap: faithLockController.isScreenTimeAuthorized.value
                  ? () => faithLockController.selectAppsToBlock()
                  : null,
            );
          }),
          if (appFeatures.darkMode)
            _buildIOSListTile(
              context,
              leading: CupertinoIcons.moon_fill,
              title: 'darkMode'.tr,
              trailing: Obx(() => Transform.scale(
                    scale: 0.8,
                    child: CupertinoSwitch(
                      value: settingsController.isDarkMode.value,
                      onChanged: settingsController.toggleDarkMode,
                    ),
                  )),
            ),

          _buildIOSListTile(
            context,
            leading: CupertinoIcons.bell,
            title: 'notifications'.tr,
            subtitle: 'notificationsSub'.tr,
            onTap: () => Get.put(FaithLockSettingsController())
                .requestNotificationsPermission(),
            trailing: Obx(() {
              final isGranted = settingsController.notificationsEnabled.value;
              return Icon(
                isGranted
                    ? CupertinoIcons.checkmark_circle_fill
                    : CupertinoIcons.exclamationmark_circle,
                color: isGranted
                    ? CupertinoColors.systemGreen
                    : CupertinoColors.systemRed,
                size: 20,
              );
            }),
          ),
          if (appFeatures.languageSelection)
            _buildIOSListTile(
              context,
              leading: CupertinoIcons.globe,
              title: 'language'.tr,
              subtitle:
                  '${'current'.tr} ${settingsController.appLanguage.value.toUpperCase()}',
              onTap: () => _showLanguagePicker(context),
            ),
          if (appFeatures.analyticsEnabled)
            _buildIOSListTile(
              context,
              leading: CupertinoIcons.chart_bar_fill,
              title: 'analytics'.tr,
              subtitle: 'helpImproveApp'.tr,
              trailing: Obx(() => Transform.scale(
                    scale: 0.8,
                    child: CupertinoSwitch(
                      value: settingsController.analyticsEnabled.value,
                      onChanged: settingsController.toggleAnalytics,
                    ),
                  )),
            ),
        ], title: 'settings'.tr),

        // Support Section
        _buildIOSSection([
          _buildIOSListTile(
            context,
            leading: CupertinoIcons.star_fill,
            title: 'rateApp'.tr,
            iconColor: CupertinoColors.systemOrange,
            onTap: settingsController.rateApp,
          ),
          _buildIOSListTile(
            context,
            leading: CupertinoIcons.mail_solid,
            title: 'contactSupport'.tr,
            iconColor: CupertinoColors.systemGreen,
            onTap: settingsController.contactSupport,
          ),
          if (appFeatures.privacySettings)
            _buildIOSListTile(
              context,
              leading: CupertinoIcons.doc_text_fill,
              title: 'privacyPolicy'.tr,
              iconColor: CupertinoColors.systemIndigo,
              onTap: settingsController.openPrivacyPolicy,
            ),
          if (appFeatures.termsSettings)
            _buildIOSListTile(
              context,
              leading: CupertinoIcons.doc_text_fill,
              title: 'termsAndConditions'.tr,
              iconColor: CupertinoColors.systemIndigo,
              onTap: settingsController.openTerms,
            ),
        ], title: 'support'.tr),

        // Subscription Section
        Obx(() {
          final hasSubscription =
              RevenueCatService.instance.isSubscriptionActive.value;

          return _buildIOSSection([
            if (hasSubscription)
              _buildIOSListTile(
                context,
                leading: CupertinoIcons.creditcard_fill,
                title: 'manageSubscription'.tr,
                subtitle: 'manageSubscriptionSub'.tr,
                iconColor: CupertinoColors.systemPurple,
                onTap: settingsController.manageSubscription,
              )
            else
              _buildIOSListTile(
                context,
                leading: CupertinoIcons.star_fill,
                title: 'getFaithLockPro'.tr,
                subtitle: 'unlockAllFeatures'.tr,
                iconColor: CupertinoColors.systemYellow,
                onTap: () => Get.to(() => const PaywallScreenV2(placementId: 'profile')),
              ),
          ], title: 'subscription'.tr);
        }),

        // ── Your Journey — detailed stats ──────────────────────────────────
        _buildJourneySection(context),

        // Debug Panel (only in debug mode)
        if (kDebugMode) _buildDebugPanel(context),
      ],
    );
  }

  // ─── YOUR JOURNEY — moved from Home ──────────────────────────────────────

  Widget _buildJourneySection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 16, 12),
            child: Text(
              'YOUR JOURNEY',
              style: TextStyle(
                fontFamily: OnboardingTheme.fontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: OnboardingTheme.goldColor,
                letterSpacing: 0.8,
              ),
            ),
          ),
          Obx(() {
            final ctrl = statsController;
            final stats = ctrl.userStats.value;
            final streak = stats?.currentStreak ?? 0;
            final longestStreak = stats?.longestStreak ?? 0;
            final versesRead = stats?.totalVersesRead ?? 0;
            final timeSaved = stats?.screenTimeReducedFormatted ?? '0 min';
            final successRate = stats?.successRateFormatted ?? '0%';
            final progress = ctrl.getProgressToNextMilestone();

            return Column(
              children: [
                // ── Streak card ─────────────────────────────────────────
                _buildJourneyCard(context, [
                  _buildJourneyRow(
                    context,
                    icon: CupertinoIcons.flame_fill,
                    iconColor: const Color(0xFFFF9500),
                    title: 'Current Streak',
                    value: '$streak day${streak == 1 ? '' : 's'}',
                  ),
                  _divider(context),
                  _buildJourneyRow(
                    context,
                    icon: CupertinoIcons.rosette,
                    iconColor: OnboardingTheme.goldColor,
                    title: 'Longest Streak',
                    value: '$longestStreak day${longestStreak == 1 ? '' : 's'}',
                  ),
                  _divider(context),
                  // Progress to next milestone
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Next Milestone',
                              style: TextStyle(
                                fontFamily: OnboardingTheme.fontFamily,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: CupertinoColors.label.resolveFrom(context),
                              ),
                            ),
                            Text(
                              ctrl.getNextMilestoneText(),
                              style: TextStyle(
                                fontFamily: OnboardingTheme.fontFamily,
                                fontSize: 14,
                                color:
                                    CupertinoColors.secondaryLabel.resolveFrom(context),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            backgroundColor: CupertinoColors.systemGrey5
                                .resolveFrom(context),
                            valueColor: AlwaysStoppedAnimation<Color>(
                                OnboardingTheme.goldColor),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${(progress * 100).toInt()}% complete',
                          style: TextStyle(
                            fontSize: 12,
                            color: CupertinoColors.secondaryLabel
                                .resolveFrom(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ]),

                const SizedBox(height: 12),

                // ── Verse & time stats ──────────────────────────────────
                _buildJourneyCard(context, [
                  _buildJourneyRow(
                    context,
                    icon: CupertinoIcons.book_fill,
                    iconColor: const Color(0xFF5AC8FA),
                    title: 'Verses Read',
                    value: '$versesRead',
                  ),
                  _divider(context),
                  _buildJourneyRow(
                    context,
                    icon: CupertinoIcons.timer,
                    iconColor: const Color(0xFF34C759),
                    title: 'Time Saved',
                    value: timeSaved,
                  ),
                  _divider(context),
                  _buildJourneyRow(
                    context,
                    icon: CupertinoIcons.checkmark_seal_fill,
                    iconColor: const Color(0xFF5856D6),
                    title: 'Success Rate',
                    value: successRate,
                  ),
                ]),

                const SizedBox(height: 12),

                // ── Badges ──────────────────────────────────────────────
                _buildBadgesCard(context, ctrl),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildJourneyCard(BuildContext context, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        // Apple's elevated grouped surface (#1C1C1E in dark) for real layering.
        color: CupertinoColors.tertiarySystemGroupedBackground
            .resolveFrom(Get.context!),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey
                .resolveFrom(Get.context!)
                .withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildJourneyRow(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontFamily: OnboardingTheme.fontFamily,
                fontSize: 17,
                fontWeight: FontWeight.w400,
                color: CupertinoColors.label.resolveFrom(context),
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: OnboardingTheme.fontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 0.5,
      indent: 56,
      color: CupertinoColors.separator.resolveFrom(Get.context!),
    );
  }

  Widget _buildBadgesCard(BuildContext context, StatsController ctrl) {
    final allBadges = BadgeDefinitions.allBadges;
    final earnedIds = ctrl.earnedBadges.map((e) => e.badgeId).toSet();

    return Container(
      decoration: BoxDecoration(
        // Apple's elevated grouped surface (#1C1C1E in dark) for real layering.
        color: CupertinoColors.tertiarySystemGroupedBackground
            .resolveFrom(Get.context!),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey
                .resolveFrom(Get.context!)
                .withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ACHIEVEMENTS',
                  style: TextStyle(
                    fontFamily: OnboardingTheme.fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    letterSpacing: 0.8,
                  ),
                ),
                Text(
                  '${earnedIds.length}/${allBadges.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: OnboardingTheme.goldColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: allBadges.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final badge = allBadges[index];
                  final isEarned = earnedIds.contains(badge.id.name);
                  return GestureDetector(
                    onTap: () => _showBadgeInfoInProfile(context, badge, isEarned),
                    child: Column(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isEarned
                                ? OnboardingTheme.goldColor.withValues(alpha: 0.12)
                                : CupertinoColors.systemGrey6.resolveFrom(context),
                            borderRadius: BorderRadius.circular(12),
                            border: isEarned
                                ? Border.all(
                                    color: OnboardingTheme.goldColor
                                        .withValues(alpha: 0.4),
                                    width: 1.5,
                                  )
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              badge.emoji,
                              style: TextStyle(
                                fontSize: 24,
                                color: isEarned
                                    ? null
                                    : CupertinoColors.systemGrey3
                                        .resolveFrom(context),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 48,
                          child: Text(
                            isEarned ? badge.name.split(' ').first : '???',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                              color: isEarned
                                  ? CupertinoColors.label.resolveFrom(context)
                                  : CupertinoColors.tertiaryLabel
                                      .resolveFrom(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBadgeInfoInProfile(
      BuildContext context, Badge badge, bool isEarned) {
    showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text('${badge.emoji} ${badge.name}'),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            isEarned
                ? badge.description
                : '${badge.description}\n\nNot yet earned.',
            style: TextStyle(
              color: isEarned ? null : CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ─── DEBUG PANEL ─────────────────────────────────────────

  Future<void> _debugResetOnboarding(BuildContext context) async {
    final controller = Get.isRegistered<ScriptureOnboardingController>()
        ? Get.find<ScriptureOnboardingController>()
        : Get.put(ScriptureOnboardingController());
    await controller.resetOnboarding();
    // Relaunch V3 onboarding — it registers its own controller in initState.
    Get.offAll(() => const ScriptureOnboardingV3Screen());
  }

  Widget _buildDebugPanel(BuildContext context) {
    return Column(
      children: [
        _buildIOSSection([
          _buildIOSSectionHeader(context, 'Notifications'),
          _buildIOSListTile(
            context,
            leading: CupertinoIcons.bell_fill,
            title: 'Win-Back #1 (Offer)',
            subtitle: '+24h — Free week promo',
            iconColor: CupertinoColors.systemOrange,
            onTap: () => _debugSendWinBackNotification(context, 0),
          ),
          _buildIOSListTile(
            context,
            leading: CupertinoIcons.bell_fill,
            title: 'Win-Back #2 (Reminder)',
            subtitle: '+48h — Offer reminder',
            iconColor: CupertinoColors.systemOrange,
            onTap: () => _debugSendWinBackNotification(context, 1),
          ),
          _buildIOSListTile(
            context,
            leading: CupertinoIcons.bell_fill,
            title: 'Win-Back #3 (Mirror)',
            subtitle: '+3d — Identity + aspiration',
            iconColor: CupertinoColors.systemYellow,
            onTap: () => _debugSendWinBackNotification(context, 2),
          ),
          _buildIOSListTile(
            context,
            leading: CupertinoIcons.bell_fill,
            title: 'Win-Back #4 (Story)',
            subtitle: '+5d — Testimonial',
            iconColor: CupertinoColors.systemYellow,
            onTap: () => _debugSendWinBackNotification(context, 3),
          ),
          _buildIOSListTile(
            context,
            leading: CupertinoIcons.bell_fill,
            title: 'Win-Back #5 (Goodbye)',
            subtitle: '+7d — Final message',
            iconColor: CupertinoColors.systemRed,
            onTap: () => _debugSendWinBackNotification(context, 4),
          ),
          _buildIOSListTile(
            context,
            leading: CupertinoIcons.book_fill,
            title: 'Send Daily Verse',
            subtitle: 'Immediate verse notification',
            iconColor: CupertinoColors.systemTeal,
            onTap: () => _debugSendDailyVerseNotification(context),
          ),
          _buildIOSListTile(
            context,
            leading: CupertinoIcons.arrow_counterclockwise,
            title: 'Reset Win-Back Sequence',
            subtitle: 'Clear completed state',
            iconColor: CupertinoColors.systemGrey,
            onTap: () => _debugResetWinBack(context),
          ),
        ], title: '🛠 DEBUG PANEL'),

        _buildIOSSection([
          _buildIOSSectionHeader(context, 'Onboarding'),
          _buildIOSListTile(
            context,
            leading: CupertinoIcons.arrow_2_circlepath,
            title: 'Reset & Replay Onboarding',
            subtitle: 'Clear flags → relaunch V3 from step 1',
            iconColor: CupertinoColors.systemPurple,
            onTap: () => _debugResetOnboarding(context),
          ),
        ]),

        _buildIOSSection([
          _buildIOSSectionHeader(context, 'Streak & Freeze'),
          _buildIOSListTile(
            context,
            leading: CupertinoIcons.flame_fill,
            title: 'Simulate Streak Freeze Saved',
            subtitle: 'Show freeze dialog (streak=5, freezes=2)',
            iconColor: CupertinoColors.systemBlue,
            onTap: () => _debugShowStreakFreezeSaved(context),
          ),
          _buildIOSListTile(
            context,
            leading: CupertinoIcons.heart_slash_fill,
            title: 'Simulate Streak Lost',
            subtitle: 'Show streak lost dialog (12-day streak)',
            iconColor: CupertinoColors.systemRed,
            onTap: () => _debugShowStreakLost(context),
          ),
          _buildIOSListTile(
            context,
            leading: CupertinoIcons.snow,
            title: 'Use a Freeze',
            subtitle: 'Consume 1 streak freeze',
            iconColor: CupertinoColors.systemCyan,
            onTap: () => _debugUseFreeze(context),
          ),
          _buildIOSListTile(
            context,
            leading: CupertinoIcons.arrow_counterclockwise,
            title: 'Reset Streak to 0',
            subtitle: 'Keep longest streak intact',
            iconColor: CupertinoColors.systemGrey,
            onTap: () => _debugResetStreak(context),
          ),
          _buildIOSListTile(
            context,
            leading: CupertinoIcons.trash,
            title: 'Reset ALL Stats',
            subtitle: 'Streak + longest + last unlock',
            iconColor: CupertinoColors.destructiveRed,
            onTap: () => _debugResetAllStats(context),
          ),
        ]),

        _buildIOSSection([
          _buildIOSSectionHeader(context, 'Badges'),
          _buildIOSListTile(
            context,
            leading: CupertinoIcons.star_circle_fill,
            title: 'Award All Badges',
            subtitle: 'Grant all 12 badges at once',
            iconColor: CupertinoColors.systemYellow,
            onTap: () => _debugAwardAllBadges(context),
          ),
          ..._buildBadgeAwardTiles(context),
        ]),

        _buildIOSSection([
          _buildIOSSectionHeader(context, 'Badge Dialogs'),
          _buildIOSListTile(
            context,
            leading: CupertinoIcons.sparkles,
            title: 'Show Badge Dialog (First Prayer)',
            subtitle: 'Simulate earning firstPrayer badge',
            iconColor: CupertinoColors.systemPurple,
            onTap: () => _debugShowBadgeDialog(context, BadgeId.firstPrayer),
          ),
          _buildIOSListTile(
            context,
            leading: CupertinoIcons.sparkles,
            title: 'Show Badge Dialog (Streak Warrior)',
            subtitle: 'Simulate earning streakWarrior badge',
            iconColor: CupertinoColors.systemPurple,
            onTap: () => _debugShowBadgeDialog(context, BadgeId.streakWarrior),
          ),
          _buildIOSListTile(
            context,
            leading: CupertinoIcons.sparkles,
            title: 'Show Multiple Badges',
            subtitle: 'Show 3 badge dialogs in sequence',
            iconColor: CupertinoColors.systemPurple,
            onTap: () => _debugShowMultipleBadgeDialogs(context),
          ),
        ]),

        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildIOSSectionHeader(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: CupertinoColors.secondaryLabel.resolveFrom(context),
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  List<Widget> _buildBadgeAwardTiles(BuildContext context) {
    return BadgeId.values.map((badgeId) {
      final badge = BadgeDefinitions.getBadge(badgeId);
      return _buildIOSListTile(
        context,
        leading: CupertinoIcons.rosette,
        title: '${badge.emoji} ${badge.name}',
        subtitle: 'Award badge: ${badgeId.name}',
        iconColor: CupertinoColors.systemIndigo,
        onTap: () => _debugAwardSingleBadge(context, badgeId),
      );
    }).toList();
  }

  // ─── DEBUG ACTIONS ───────────────────────────────────────

  void _debugSendWinBackNotification(BuildContext context, int index) {
    final titles = [
      'winback_title2'.tr, // Offer (+24h)
      'winback_title2'.tr, // Reminder (+48h) - same as offer
      'winback_title3'.tr, // Mirror (+3d)
      'winback_title4'.tr, // Story (+5d)
      'winback_title5'.tr, // Goodbye (+7d)
    ];
    final bodies = [
      'winback_body2'.tr,
      'winback_body2'.tr, // Reminder - same as offer
      'winback_body3'.tr,
      'winback_body4'.tr,
      'winback_body5'.tr,
    ];

    final safeIndex = index.clamp(0, 4);
    LocalNotificationService().showNotification(
      id: 900 + safeIndex,
      title: titles[safeIndex],
      body: bodies[safeIndex],
      payload: '${WinBackNotificationService.payloadPrefix}_$safeIndex',
    );
    _showDebugToast(context, 'Win-back #${safeIndex + 1} sent');
  }

  void _debugSendDailyVerseNotification(BuildContext context) async {
    final verseService = VerseService();
    final verse = await verseService.getDailyVerse();
    final text = verse != null
        ? '"${verse.text}" — ${verse.reference}'
        : 'Open FaithLock for your daily verse';

    LocalNotificationService().showNotification(
      id: 950,
      title: 'Daily Verse',
      body: text,
      payload: verse != null
          ? '${DailyVerseNotificationService.payloadPrefix}_${verse.id}'
          : DailyVerseNotificationService.payloadPrefix,
    );
    _showDebugToast(context, 'Daily verse notification sent');
  }

  void _debugResetWinBack(BuildContext context) async {
    await WinBackNotificationService().reset();
    _showDebugToast(context, 'Win-back sequence reset');
  }

  void _debugShowStreakFreezeSaved(BuildContext context) {
    GamificationDialogService.showStreakFreezeSaved(
      context: context,
      currentStreak: 5,
      freezesRemaining: 2,
    );
  }

  void _debugShowStreakLost(BuildContext context) {
    GamificationDialogService.showStreakLost(
      context: context,
      lostStreak: 12,
    );
  }

  void _debugUseFreeze(BuildContext context) async {
    final service = StreakFreezeService();
    await service.initializeIfNeeded();
    final used = await service.tryUseFreeze();
    final state = await service.getFreezeState();
    _showDebugToast(
      context,
      used
          ? 'Freeze used! ${state.freezesRemaining}/${state.maxFreezes} remaining'
          : 'No freeze available (remaining: ${state.freezesRemaining}, consecutive: ${state.usedConsecutiveFreeze})',
    );
  }

  void _debugResetStreak(BuildContext context) async {
    await StatsService().resetStreak();
    _showDebugToast(context, 'Current streak reset to 0');
  }

  void _debugResetAllStats(BuildContext context) async {
    await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Reset ALL Stats?'),
        content: const Text(
            'This will clear streak, longest streak, and last unlock date. Cannot be undone.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              await StatsService().resetAllStats();
              Navigator.of(ctx).pop();
              if (context.mounted) {
                _showDebugToast(context, 'All stats cleared');
              }
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _debugAwardAllBadges(BuildContext context) async {
    final badgeService = BadgeService();
    int awarded = 0;
    for (final badgeId in BadgeId.values) {
      final isNew = await badgeService.awardBadge(badgeId);
      if (isNew) awarded++;
    }
    if (context.mounted) {
      _showDebugToast(context, '$awarded new badges awarded (${BadgeId.values.length} total)');
    }
  }

  void _debugAwardSingleBadge(BuildContext context, BadgeId badgeId) async {
    final badgeService = BadgeService();
    final isNew = await badgeService.awardBadge(badgeId);
    final badge = BadgeDefinitions.getBadge(badgeId);
    if (context.mounted) {
      if (isNew) {
        _showDebugToast(context, '${badge.emoji} ${badge.name} awarded!');
      } else {
        _showDebugToast(context, '${badge.emoji} ${badge.name} already earned');
      }
    }
  }

  void _debugShowBadgeDialog(BuildContext context, BadgeId badgeId) {
    final badge = BadgeDefinitions.getBadge(badgeId);
    GamificationDialogService.showBadgeEarned(
      context: context,
      badge: badge,
    );
  }

  void _debugShowMultipleBadgeDialogs(BuildContext context) {
    final badges = [
      BadgeDefinitions.getBadge(BadgeId.firstPrayer),
      BadgeDefinitions.getBadge(BadgeId.streakStarter),
      BadgeDefinitions.getBadge(BadgeId.verseExplorer),
    ];
    GamificationDialogService.showBadgesEarned(
      context: context,
      badges: badges,
    );
  }

  void _showDebugToast(BuildContext context, String message) {
    showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Debug'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildIOSSection(List<Widget> children, {String? title}) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color:
                      CupertinoColors.secondaryLabel.resolveFrom(Get.context!),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
          Container(
            decoration: BoxDecoration(
              // Use tertiarySystemGroupedBackground (#2C2C2E in dark) so tiles
              // are visibly elevated above the #1C1C1E base — systemBackground
              // resolves to pure black in dark mode, producing no contrast.
              color: CupertinoColors.tertiarySystemGroupedBackground
                  .resolveFrom(Get.context!),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: children.asMap().entries.map((entry) {
                final index = entry.key;
                final child = entry.value;
                return Column(
                  children: [
                    child,
                    if (index < children.length - 1)
                      Divider(
                        height: 1,
                        thickness: 0.5,
                        indent: 56,
                        color:
                            CupertinoColors.separator.resolveFrom(Get.context!),
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIOSListTile(
    BuildContext context, {
    required IconData leading,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? titleColor,
    Color? iconColor,
    bool isDestructive = false,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isDestructive
                    ? CupertinoColors.systemRed.withValues(alpha: 0.1)
                    : (iconColor ?? CupertinoColors.systemBlue)
                        .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                leading,
                color: iconColor ??
                    (isDestructive
                        ? CupertinoColors.systemRed
                        : CupertinoColors.systemBlue),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),

            // Title and subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w400,
                      color: titleColor ??
                          (isDestructive
                              ? CupertinoColors.systemRed
                              : CupertinoColors.label.resolveFrom(context)),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 15,
                        color:
                            CupertinoColors.secondaryLabel.resolveFrom(context),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Trailing widget
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing,
            ] else if (onTap != null) ...[
              const SizedBox(width: 8),
              Icon(
                CupertinoIcons.chevron_forward,
                color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                size: 16,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Android Material Style
  Widget _buildAndroidProfileScreen(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Settings List
            _buildAndroidSettingsList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAndroidSettingsList(BuildContext context) {
    final appFeatures = AppConfig.appFeatures;

    return Column(
      children: [
        // App Settings
        _buildAndroidSection(
          context,
          'settings'.tr,
          [
            if (appFeatures.darkMode)
              _buildAndroidListTile(
                context,
                leading: Icons.dark_mode,
                title: 'darkMode'.tr,
                trailing: Obx(() => Switch(
                      value: settingsController.isDarkMode.value,
                      onChanged: settingsController.toggleDarkMode,
                    )),
              ),
            if (appFeatures.languageSelection)
              _buildAndroidListTile(
                context,
                leading: Icons.language,
                title: 'language'.tr,
                subtitle: settingsController.appLanguage.value.toUpperCase(),
                onTap: () => _showLanguagePicker(context),
              ),
          ],
        ),

        // Support
        _buildAndroidSection(
          context,
          'support'.tr,
          [
            if (appFeatures.showAppVersion)
              _buildAndroidListTile(
                context,
                leading: Icons.info,
                title: 'appInformation'.tr,
                onTap: settingsController.rateApp,
              ),
            _buildAndroidListTile(
              context,
              leading: Icons.mail,
              title: 'contactSupport'.tr,
              onTap: settingsController.contactSupport,
            ),
            _buildAndroidListTile(
              context,
              leading: Icons.privacy_tip,
              title: 'privacyPolicy'.tr,
              onTap: settingsController.openPrivacyPolicy,
            ),
          ],
        ),

        // Subscription Section
        Obx(() {
          final hasSubscription =
              RevenueCatService.instance.isSubscriptionActive.value;

          return _buildAndroidSection(
            context,
            'subscription'.tr,
            [
              if (hasSubscription)
                _buildAndroidListTile(
                  context,
                  leading: Icons.credit_card,
                  title: 'manageSubscription'.tr,
                  subtitle: 'manageSubscriptionSub'.tr,
                  iconColor: Colors.purple,
                  onTap: settingsController.manageSubscription,
                )
              else
                _buildAndroidListTile(
                  context,
                  leading: Icons.star,
                  title: 'becomePremium'.tr,
                  subtitle: 'unlockAllFeatures'.tr,
                  iconColor: Colors.amber,
                  onTap: () => Get.to(() => const PaywallScreenV2(placementId: 'profile')),
                ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildAndroidSection(
    BuildContext context,
    String? title,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).primaryColor,
                  ),
            ),
          ),
        ],
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildAndroidListTile(
    BuildContext context, {
    required IconData leading,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? titleColor,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(
        leading,
        color: iconColor ?? Theme.of(context).primaryColor,
      ),
      title: Text(
        title,
        style: TextStyle(color: titleColor),
      ),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing:
          trailing ?? (onTap != null ? const Icon(Icons.chevron_right) : null),
      onTap: onTap,
    );
  }

  // Language Picker
  void _showLanguagePicker(BuildContext context) {
    if (GetPlatform.isIOS) {
      showCupertinoModalPopup(
        context: context,
        builder: (context) => Container(
          height: 280,
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground.resolveFrom(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                // Handle bar
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey3.resolveFrom(context),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => Get.back(),
                        child: Text(
                          'cancel'.tr,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      Text(
                        'selectLanguage'.tr,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => Get.back(),
                        child: Text(
                          'done'.tr,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Picker
                Expanded(
                  child: CupertinoPicker(
                    itemExtent: 44.0,
                    scrollController: FixedExtentScrollController(
                      initialItem:
                          settingsController.appLanguage.value == 'en' ? 0 : 1,
                    ),
                    onSelectedItemChanged: (int index) {
                      settingsController
                          .changeLanguage(index == 0 ? 'en' : 'fr');
                    },
                    children: [
                      _buildLanguagePickerItem('🇺🇸', 'english'.tr),
                      _buildLanguagePickerItem('🇫🇷', 'french'.tr),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        builder: (context) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'selectLanguage'.tr,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Obx(() => RadioListTile<String>(
                    title: Text('english'.tr),
                    value: 'en',
                    groupValue: settingsController.appLanguage.value,
                    onChanged: (value) {
                      if (value != null) {
                        settingsController.changeLanguage(value);
                        Get.back();
                      }
                    },
                  )),
              Obx(() => RadioListTile<String>(
                    title: Text('french'.tr),
                    value: 'fr',
                    groupValue: settingsController.appLanguage.value,
                    onChanged: (value) {
                      if (value != null) {
                        settingsController.changeLanguage(value);
                        Get.back();
                      }
                    },
                  )),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildLanguagePickerItem(String flag, String language) {
    return Container(
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            flag,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 12),
          Text(
            language,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
