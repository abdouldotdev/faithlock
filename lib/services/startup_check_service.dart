import 'package:faithlock/features/faithlock/services/screen_time_service.dart';
import 'package:faithlock/services/app_launch_service.dart';
import 'package:faithlock/services/storage/secure_storage_service.dart';
import 'package:faithlock/shared/widgets/dialogs/fast_alert_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Service to perform startup checks when app launches
class StartupCheckService {
  static final StartupCheckService _instance = StartupCheckService._internal();
  factory StartupCheckService() => _instance;
  StartupCheckService._internal();

  final ScreenTimeService _screenTimeService = ScreenTimeService();
  final AppLaunchService _launchService = AppLaunchService();
  final StorageService _storage = StorageService();

  bool _hasChecked = false;

  /// Perform startup checks (call from main screen or splash)
  /// This handles Screen Time authorization and app selection prompts
  Future<void> performStartupChecks(BuildContext context) async {
    // Only check once per app session
    if (_hasChecked) return;
    _hasChecked = true;

    // Only prompt on natural launches (not from notifications)
    final isNatural = await _launchService.isNaturalLaunch();
    if (!isNatural) {
      debugPrint('📱 Skipping startup check - launched via notification');
      return;
    }

    debugPrint('📱 Performing startup checks (natural launch)');

    // Wait a bit for UI to settle
    await Future.delayed(const Duration(milliseconds: 500));

    // Check Screen Time authorization first
    final isAuthorized = await _screenTimeService.isAuthorized();
    if (!isAuthorized) {
      debugPrint('⚠️ Screen Time not authorized - prompting user');
      final granted = await _promptScreenTimeAuthorization(context);

      if (!granted) {
        debugPrint('⚠️ User declined Screen Time authorization');
        return;
      }

      // Wait a bit after Screen Time authorization
      await Future.delayed(const Duration(seconds: 2));
    }

    // Apps not selected? Don't nag with a launch dialog — the dashboard
    // already surfaces an inline "Select Apps" empty state for that.
    final hasApps = await _screenTimeService.hasSelectedApps();
    if (!hasApps) {
      debugPrint('ℹ️ No apps selected - skipping startup prompt (handled in dashboard)');
      return;
    }

    debugPrint(
        '✅ Startup checks passed - Screen Time authorized and apps selected');
  }

  /// Prompt user to authorize Screen Time
  Future<bool> _promptScreenTimeAuthorization(BuildContext context) async {
    if (!context.mounted) return false;

    // Check if we already asked
    final hasAskedBefore =
        await _storage.readBool('screen_time_prompt_shown') ?? false;

    // Show explanatory dialog
    await FastAlertDialog.show(
      context: context,
      title: 'startup_enableScreenTime'.tr,
      message: 'startup_screenTimeMessage'.tr,
      actions: [
        if (hasAskedBefore)
          FastDialogAction(
            text: 'later'.tr,
            isCancel: true,
            onPressed: () => Navigator.pop(context, false),
          ),
        FastDialogAction(
          text: 'startup_enable'.tr,
          isDefault: true,
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    );

    // Wait for dialog animation
    await Future.delayed(const Duration(milliseconds: 300));

    // Request authorization
    final granted = await _screenTimeService.requestAuthorization();

    // Mark that we asked
    await _storage.writeBool('screen_time_prompt_shown', true);

    if (granted) {
      debugPrint('✅ Screen Time authorization granted');
    } else {
      debugPrint('❌ Screen Time authorization denied');
    }

    return granted;
  }

  /// Reset check flag (for testing)
  void resetCheck() {
    _hasChecked = false;
  }
}
