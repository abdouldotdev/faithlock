import 'package:flutter/foundation.dart' show kDebugMode, kReleaseMode;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:faithlock/app_routes.dart';
import 'package:faithlock/config/app_config.dart';
import 'package:faithlock/features/bible/controllers/bible_engagement_controller.dart';
import 'package:faithlock/features/faithlock/controllers/faithlock_settings_controller.dart';
import 'package:faithlock/features/faithlock/screens/bible/cozy_reflections_screen.dart';
import 'package:faithlock/features/faithlock/controllers/stats_controller.dart';
import 'package:faithlock/features/garden/controllers/garden_controller.dart';
import 'package:faithlock/features/faithlock/services/unlock_flow_service.dart';
import 'package:faithlock/services/analytics/posthog/export.dart';
import 'package:faithlock/features/onboarding/feature_tour/feature_tour.dart';
import 'package:faithlock/features/onboarding/screens/scripture_onboarding_v3_screen.dart';
import 'package:faithlock/navigation/controllers/navigation_controller.dart';
import 'package:faithlock/features/paywall/screens/paywall_screen_v2.dart';
import 'package:faithlock/features/profile/controllers/settings_controller.dart';
import 'package:faithlock/services/subscription/revenuecat_service.dart';
import 'package:faithlock/shared/widgets/cozy/cozy.dart';

/// Cozy "Profile" tab — chunky, warm rebuild of the settings/profile screen.
/// Reuses the existing controllers and actions; visuals only are restyled.
class CozyProfileScreen extends StatelessWidget {
  CozyProfileScreen({super.key});

  SettingsController get _settings => Get.isRegistered<SettingsController>()
      ? Get.find<SettingsController>()
      : Get.put(SettingsController());

  FaithLockSettingsController get _faithLock =>
      Get.isRegistered<FaithLockSettingsController>()
          ? Get.find<FaithLockSettingsController>()
          : Get.put(FaithLockSettingsController());

  StatsController get _stats => Get.isRegistered<StatsController>()
      ? Get.find<StatsController>()
      : Get.put(StatsController());

  BibleEngagementController get _engagement =>
      Get.isRegistered<BibleEngagementController>()
          ? Get.find<BibleEngagementController>()
          : Get.put(BibleEngagementController());

  @override
  Widget build(BuildContext context) {
    final settings = _settings;
    final faithLock = _faithLock;
    final stats = _stats;

    return Scaffold(
      backgroundColor: CozyColors.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (AppConfig.appFeatures.journeyStats) ...[
                _journey(stats),
                const SizedBox(height: 24),
              ],
              _settingsGroup(context, settings, faithLock),
              _supportGroup(settings),
              _subscriptionGroup(settings),
              // Dev tools (replay onboarding / paywall / tour) show in debug AND
              // profile builds, but never in the real release build shipped to
              // the App Store — so you keep them while testing (`flutter run
              // --profile`) without exposing skip-paywall to real users.
              if (!kReleaseMode) ...[
                const SizedBox(height: 28),
                _debugGroup(),
              ],
              // Garden presence simulator — debug builds only.
              if (kDebugMode) ...[
                const SizedBox(height: 4),
                const _GardenDebugPanel(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Your Journey ─────────────────────────────────────────────────────────

  Widget _journey(StatsController stats) {
    return Obx(() {
      final s = stats.userStats.value;
      final streak = s?.currentStreak ?? 0;
      final verses = s?.totalVersesRead ?? 0;
      final timeSaved = s?.screenTimeReducedFormatted ?? '0 min';
      final success = s?.successRateFormatted ?? '0%';

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text('YOUR JOURNEY', style: CozyText.label),
          ),
          Row(
            children: [
              Expanded(
                child: CozyStatCard(
                  icon: HugeIcons.strokeRoundedFire,
                  iconColor: CozyColors.ink,
                  iconBackground: CozyColors.peach,
                  value: '$streak',
                  label: 'Day streak',
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: CozyStatCard(
                  icon: HugeIcons.strokeRoundedBookOpen01,
                  iconColor: CozyColors.ink,
                  iconBackground: CozyColors.sage,
                  value: '$verses',
                  label: 'Verses read',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: CozyStatCard(
                  icon: HugeIcons.strokeRoundedTimer01,
                  iconColor: CozyColors.ink,
                  iconBackground: CozyColors.surfaceMuted,
                  value: timeSaved,
                  label: 'Time saved',
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: CozyStatCard(
                  icon: HugeIcons.strokeRoundedAward01,
                  iconColor: CozyColors.ink,
                  iconBackground: CozyColors.primaryLight,
                  value: success,
                  label: 'Success rate',
                ),
              ),
            ],
          ),
        ],
      );
    });
  }

  // ── Settings ───────────────────────────────────────────────────────────

  Widget _settingsGroup(
    BuildContext context,
    SettingsController settings,
    FaithLockSettingsController faithLock,
  ) {
    final features = AppConfig.appFeatures;
    final tiles = <Widget>[
      KeyedSubtree(
        // Spotlight anchor for the first-day feature tour ("lock apps" step).
        key: TourKeys.lockApps,
        child: Obx(() {
          final authorized = faithLock.isScreenTimeAuthorized.value;
          final count = faithLock.selectedAppsCount.value;
          final subtitle = !authorized
              ? 'screenTimePermRequired'.tr
              : (count > 0 ? 'appsConfigured'.tr : 'noAppsSelected'.tr);
          return _tile(
            icon: HugeIcons.strokeRoundedAppStore,
            iconBg: CozyColors.peach,
            title: 'blockedApps'.tr,
            subtitle: subtitle,
            trailing: count > 0
                ? const HugeIcon(
                    icon: HugeIcons.strokeRoundedCheckmarkCircle01,
                    color: CozyColors.success,
                    size: 22,
                  )
                : null,
            onTap: () async {
              if (!authorized) {
                await faithLock.requestScreenTimePermission();
              }
              if (faithLock.isScreenTimeAuthorized.value) {
                await faithLock.selectAppsToBlock();
              }
            },
          );
        }),
      ),
      // How the user earns blocked apps back (quiz vs prayer audio/text).
      _UnlockMethodTile(
        tile: ({required String subtitle, required VoidCallback onTap}) =>
            _tile(
          icon: HugeIcons.strokeRoundedSquareLock01,
          iconBg: CozyColors.surfaceMuted,
          title: 'unlock_method_setting'.tr,
          subtitle: subtitle,
          onTap: onTap,
        ),
      ),
      if (features.darkMode)
        Obx(() => _tile(
              icon: HugeIcons.strokeRoundedDarkMode,
              iconBg: CozyColors.surfaceMuted,
              title: 'darkMode'.tr,
              trailing: Switch.adaptive(
                value: settings.isDarkMode.value,
                onChanged: settings.toggleDarkMode,
                activeThumbColor: CozyColors.primary,
              ),
            )),
      Obx(() {
        final granted = settings.notificationsEnabled.value;
        return _tile(
          icon: HugeIcons.strokeRoundedBellDot,
          iconBg: CozyColors.sage,
          title: 'notifications'.tr,
          subtitle: 'notificationsSub'.tr,
          trailing: HugeIcon(
            icon: granted
                ? HugeIcons.strokeRoundedCheckmarkCircle01
                : HugeIcons.strokeRoundedAlertCircle,
            color: granted ? CozyColors.success : CozyColors.warning,
            size: 22,
          ),
          onTap: faithLock.requestNotificationsPermission,
        );
      }),
      // Saved verse reflections (written from the Bible reader / after prayer).
      Obx(() {
        final count = _engagement.reflections.length;
        return _tile(
          icon: HugeIcons.strokeRoundedNote01,
          iconBg: CozyColors.peach,
          title: 'bibleui_myReflections'.tr,
          subtitle: count > 0
              ? 'bibleui_reflectionsCount'.trParams({'count': '$count'})
              : 'bibleui_myReflectionsSub'.tr,
          onTap: () => Get.to(() => const CozyReflectionsScreen()),
        );
      }),
      if (features.languageSelection)
        Obx(() => _tile(
              icon: HugeIcons.strokeRoundedLanguageCircle,
              iconBg: CozyColors.primaryLight,
              title: 'language'.tr,
              subtitle:
                  '${'current'.tr} ${settings.appLanguage.value.toUpperCase()}',
              onTap: () => _showLanguagePicker(context, settings),
            )),
      if (features.analyticsEnabled)
        Obx(() => _tile(
              icon: HugeIcons.strokeRoundedBarChart,
              iconBg: CozyColors.surfaceMuted,
              title: 'analytics'.tr,
              subtitle: 'helpImproveApp'.tr,
              trailing: Switch.adaptive(
                value: settings.analyticsEnabled.value,
                onChanged: settings.toggleAnalytics,
                activeThumbColor: CozyColors.primary,
              ),
            )),
    ];
    return _group('settings'.tr, tiles);
  }

  Widget _supportGroup(SettingsController settings) {
    final features = AppConfig.appFeatures;
    final tiles = <Widget>[
      // Dev-only, like the other replay tools — hidden in the App Store release.
      if (!kReleaseMode)
        _tile(
          icon: HugeIcons.strokeRoundedSparkles,
          iconBg: CozyColors.primaryLight,
          title: 'replayTour_title'.tr,
          subtitle: 'replayTour_sub'.tr,
          onTap: () {
            if (Get.isRegistered<NavigationController>()) {
              Get.find<NavigationController>().changePage(0);
            }
            if (Get.isRegistered<FeatureTourController>()) {
              Get.find<FeatureTourController>()
                  .begin(buildFirstDayTour(), source: 'replay');
            }
          },
        ),
      _tile(
        icon: HugeIcons.strokeRoundedStar,
        iconBg: CozyColors.peach,
        title: 'rateApp'.tr,
        onTap: settings.rateApp,
      ),
      _tile(
        icon: HugeIcons.strokeRoundedMail01,
        iconBg: CozyColors.sage,
        title: 'contactSupport'.tr,
        onTap: settings.contactSupport,
      ),
      if (features.privacySettings)
        _tile(
          icon: HugeIcons.strokeRoundedFile01,
          iconBg: CozyColors.surfaceMuted,
          title: 'privacyPolicy'.tr,
          onTap: settings.openPrivacyPolicy,
        ),
      if (features.termsSettings)
        _tile(
          icon: HugeIcons.strokeRoundedFile01,
          iconBg: CozyColors.surfaceMuted,
          title: 'termsAndConditions'.tr,
          onTap: settings.openTerms,
        ),
    ];
    return _group('support'.tr, tiles);
  }

  Widget _subscriptionGroup(SettingsController settings) {
    return Obx(() {
      final pro = RevenueCatService.instance.isSubscriptionActive.value;
      final tiles = <Widget>[
        if (pro)
          _tile(
            icon: HugeIcons.strokeRoundedCreditCard,
            iconBg: CozyColors.primaryLight,
            title: 'manageSubscription'.tr,
            subtitle: 'manageSubscriptionSub'.tr,
            onTap: settings.manageSubscription,
          )
        else
          _tile(
            icon: HugeIcons.strokeRoundedCrown,
            iconBg: CozyColors.gold.withValues(alpha: 0.3),
            title: 'getFaithLockPro'.tr,
            subtitle: 'unlockAllFeatures'.tr,
            onTap: () =>
                Get.to(() => const PaywallScreenV2(placementId: 'profile')),
          ),
      ];
      return _group('subscription'.tr, tiles);
    });
  }

  // ── Debug group (debug + profile builds, never release) ──────────────────

  /// Two replay shortcuts used while iterating on the V3 onboarding and the
  /// paywall — saves the dance of clearing prefs / reinstalling. Visible
  /// only in debug builds.
  Widget _debugGroup() {
    return _group('DEBUG', [
      _tile(
        icon: HugeIcons.strokeRoundedReload,
        iconBg: Colors.redAccent.withValues(alpha: 0.18),
        title: 'Replay onboarding',
        subtitle: 'Push the full V3 onboarding flow',
        onTap: () => Get.to(() => const ScriptureOnboardingV3Screen()),
      ),
      _tile(
        icon: HugeIcons.strokeRoundedDollarCircle,
        iconBg: CozyColors.primaryLight,
        title: 'Replay paywall',
        subtitle: 'Open PaywallScreenV2 standalone',
        onTap: () =>
            Get.to(() => const PaywallScreenV2(placementId: 'debug_replay')),
      ),
      // Fire the same unlock flow that runs when a blocked app is opened and the
      // shield notification is tapped — mirrors
      // NotificationNavigationService._navigateToPrayer(). Lets you test the
      // "opened a locked app" path without actually opening a blocked app.
      _tile(
        icon: HugeIcons.strokeRoundedBellDot,
        iconBg: CozyColors.peach,
        title: 'Trigger lock notification',
        subtitle: 'Open the unlock flow (as if a blocked app was opened)',
        onTap: () => Get.offAllNamed(AppRoutes.unlockChooser),
      ),
    ]);
  }

  // ── Shared row + group builders ──────────────────────────────────────────

  Widget _group(String title, List<Widget> tiles) {
    final children = <Widget>[];
    for (var i = 0; i < tiles.length; i++) {
      children.add(tiles[i]);
      if (i < tiles.length - 1) {
        children.add(Container(
          height: 1.5,
          margin: const EdgeInsets.only(left: 66),
          color: CozyColors.divider,
        ));
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(title.toUpperCase(), style: CozyText.label),
        ),
        CozyCard(
          padding: EdgeInsets.zero,
          child: Column(children: children),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _tile({
    required List<List<dynamic>> icon,
    required Color iconBg,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          CozyIconChip(
            icon: icon,
            iconColor: CozyColors.ink,
            background: iconBg,
            bordered: false,
            size: 38,
            iconSize: 20,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: CozyText.body,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: CozyText.subtitle.copyWith(fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          trailing ??
              (onTap != null
                  ? const HugeIcon(
                      icon: HugeIcons.strokeRoundedArrowRight01,
                      color: CozyColors.inkMuted,
                      size: 24,
                    )
                  : const SizedBox.shrink()),
        ],
      ),
    );

    if (onTap == null) return row;
    return CozyTappable(onTap: onTap, pressedScale: 0.99, child: row);
  }

  // ── Language picker ──────────────────────────────────────────────────────

  void _showLanguagePicker(BuildContext context, SettingsController settings) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: CozyColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(CozyTokens.radiusLg)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('selectLanguage'.tr, style: CozyText.title),
              const SizedBox(height: 16),
              Obx(() {
                final lang = settings.appLanguage.value;
                return Column(
                  children: [
                    CozyChoiceCard(
                      leading: const SizedBox(
                        width: 52,
                        child: Center(
                            child:
                                Text('🇺🇸', style: TextStyle(fontSize: 32))),
                      ),
                      title: 'english'.tr,
                      selected: lang == 'en',
                      filledWhenSelected: true,
                      onTap: () {
                        settings.changeLanguage('en');
                        Get.back();
                      },
                    ),
                    const SizedBox(height: 12),
                    CozyChoiceCard(
                      leading: const SizedBox(
                        width: 52,
                        child: Center(
                            child:
                                Text('🇫🇷', style: TextStyle(fontSize: 32))),
                      ),
                      title: 'french'.tr,
                      selected: lang == 'fr',
                      filledWhenSelected: true,
                      onTap: () {
                        settings.changeLanguage('fr');
                        Get.back();
                      },
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

/// Settings row for the remembered unlock method. Reads the current choice and
/// opens a picker (Ask every time / Quiz / Prayer audio / Prayer text). Renders
/// itself through [tile] so it reuses the profile's row styling.
class _UnlockMethodTile extends StatefulWidget {
  const _UnlockMethodTile({required this.tile});

  final Widget Function({required String subtitle, required VoidCallback onTap})
      tile;

  @override
  State<_UnlockMethodTile> createState() => _UnlockMethodTileState();
}

class _UnlockMethodTileState extends State<_UnlockMethodTile> {
  final UnlockFlowService _service = UnlockFlowService();
  UnlockMethod? _method;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final m = await _service.remembered();
    if (!mounted) return;
    setState(() {
      _method = m;
      _loaded = true;
    });
  }

  String get _subtitle {
    if (!_loaded) return '…';
    return (_method?.labelKey ?? 'unlock_method_ask').tr;
  }

  @override
  Widget build(BuildContext context) {
    return widget.tile(subtitle: _subtitle, onTap: _showPicker);
  }

  void _showPicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: CozyColors.background,
      // Allow the sheet to grow with content + scroll instead of overflowing.
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(CozyTokens.radiusLg)),
      ),
      builder: (_) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('unlock_method_setting'.tr, style: CozyText.title),
              const SizedBox(height: 6),
              Text('unlock_method_settingSub'.tr, style: CozyText.subtitle),
              const SizedBox(height: 18),
              _choice(
                null,
                'unlock_method_ask'.tr,
                HugeIcons.strokeRoundedHelpCircle,
                CozyColors.surfaceMuted,
              ),
              const SizedBox(height: 12),
              _choice(
                UnlockMethod.quiz,
                'unlock_method_quiz'.tr,
                HugeIcons.strokeRoundedQuiz01,
                CozyColors.sage,
              ),
              const SizedBox(height: 12),
              _choice(
                UnlockMethod.prayerAudio,
                'unlock_method_audio'.tr,
                HugeIcons.strokeRoundedHeadphones,
                CozyColors.peach,
              ),
              const SizedBox(height: 12),
              _choice(
                UnlockMethod.prayerText,
                'unlock_method_text'.tr,
                HugeIcons.strokeRoundedTextFont,
                CozyColors.primaryLight,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _choice(
    UnlockMethod? method,
    String title,
    List<List<dynamic>> icon,
    Color iconBg,
  ) {
    return CozyChoiceCard(
      icon: icon,
      iconBackground: iconBg,
      iconColor: CozyColors.ink,
      title: title,
      selected: _method == method,
      filledWhenSelected: true,
      onTap: () async {
        final previous = _method?.storageValue ?? 'ask';
        await _service.remember(method);
        final analytics = PostHogService.instance;
        if (analytics.isReady && previous != (method?.storageValue ?? 'ask')) {
          analytics.events.trackCustom('unlock_method_setting_changed', {
            'method': method?.storageValue ?? 'ask',
            'previous': previous,
            'source': 'profile',
          });
        }
        if (mounted) setState(() => _method = method);
        Get.back();
      },
    );
  }
}

/// Debug-only garden simulator (kDebugMode). Pick a "regularity" (cumulative
/// active days) and an "absence" (days since active), then "reopen the app" to
/// apply that scenario to the live garden tree so you can watch it evolve.
class _GardenDebugPanel extends StatefulWidget {
  const _GardenDebugPanel();

  @override
  State<_GardenDebugPanel> createState() => _GardenDebugPanelState();
}

class _GardenDebugPanelState extends State<_GardenDebugPanel> {
  GardenController get _garden => Get.isRegistered<GardenController>()
      ? Get.find<GardenController>()
      : Get.put(GardenController());

  static const List<(String, int)> _regularity = [
    ('Nouveau', 0),
    ('Occasionnel', 8),
    ('Régulier', 25),
    ('Fidèle', 60),
    ('Ancien', 120),
    ('Grove', 200),
  ];
  static const List<int> _absence = [0, 1, 3, 7, 14, 30, 60, 90];

  int _activeDays = 25;
  int _daysAway = 0;

  Widget _pill(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: ShapeDecoration(
          color: selected ? CozyColors.primary : CozyColors.surface,
          shape: CozyTokens.smooth(
            CozyTokens.radiusPill,
            side: BorderSide(
              color: selected ? CozyColors.primary : CozyColors.outline,
              width: CozyTokens.borderWidthThin,
            ),
          ),
        ),
        child: Text(
          label,
          style: CozyText.label.copyWith(
            color: selected ? CozyColors.onPrimary : CozyColors.ink,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final regularityLabel = _regularity
        .firstWhere((r) => r.$2 == _activeDays,
            orElse: () => ('?', _activeDays))
        .$1;
    final resting = _daysAway > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 10),
          child: Text('🌱 GARDEN DEBUG', style: CozyText.label),
        ),
        CozyCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Régularité',
                  style: CozyText.label
                      .copyWith(color: CozyColors.inkMuted, fontSize: 11)),
              const SizedBox(height: 6),
              Wrap(
                runSpacing: 6,
                children: [
                  for (final r in _regularity)
                    _pill(r.$1, _activeDays == r.$2,
                        () => setState(() => _activeDays = r.$2)),
                ],
              ),
              const SizedBox(height: 12),
              Text("Jours d'absence",
                  style: CozyText.label
                      .copyWith(color: CozyColors.inkMuted, fontSize: 11)),
              const SizedBox(height: 6),
              Wrap(
                runSpacing: 6,
                children: [
                  for (final d in _absence)
                    _pill('$d j', _daysAway == d,
                        () => setState(() => _daysAway = d)),
                ],
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => _garden.debugApply(
                  activeDays: _activeDays,
                  daysSinceActive: _daysAway,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  alignment: Alignment.center,
                  decoration: ShapeDecoration(
                    color: CozyColors.surface,
                    shape: CozyTokens.smooth(
                      CozyTokens.radiusPill,
                      side: const BorderSide(
                        color: CozyColors.outline,
                        width: CozyTokens.borderWidthThin,
                      ),
                    ),
                  ),
                  child: Text("Rouvrir l'app",
                      style: CozyText.label.copyWith(color: CozyColors.ink)),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'régularité: $regularityLabel ($_activeDays j) · '
                "absence: $_daysAway j → ${resting ? 'resting' : 'active'}",
                style: CozyText.label
                    .copyWith(color: CozyColors.inkMuted, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
