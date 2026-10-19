import 'package:faithlock/features/faithlock/services/screen_time_service.dart';
import 'package:faithlock/features/onboarding/controllers/scripture_onboarding_controller.dart';
import 'package:faithlock/features/onboarding/utils/animation_utils.dart';
import 'package:faithlock/features/onboarding/widgets/onboarding_wrapper.dart';
import 'package:faithlock/services/storage/secure_storage_service.dart';
import 'package:faithlock/shared/widgets/cozy/cozy.dart';
import 'package:faithlock/shared/widgets/dialogs/fast_confirmation_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';

/// Step 7: Screen Time Permission — cozy rebuild. Typed intro/explanation,
/// then a hero shield + activate CTA on the cream canvas.
class Step7ScreenTimePermission extends StatefulWidget {
  final VoidCallback onComplete;

  const Step7ScreenTimePermission({
    super.key,
    required this.onComplete,
  });

  @override
  State<Step7ScreenTimePermission> createState() =>
      _Step7ScreenTimePermissionState();
}

class _Step7ScreenTimePermissionState extends State<Step7ScreenTimePermission> {
  final controller = Get.find<ScriptureOnboardingController>();
  final ScreenTimeService _screenTimeService = ScreenTimeService();
  final StorageService _storage = StorageService();

  bool _isRequestingPermission = false;

  Future<void> _onConnectScreenTime() async {
    if (_isRequestingPermission) return;
    await AnimationUtils.heavyHaptic();

    setState(() => _isRequestingPermission = true);

    try {
      debugPrint('🛡️ Requesting Screen Time permission...');
      final granted = await _screenTimeService.requestAuthorization();
      debugPrint(granted
          ? '✅ Screen Time permission granted'
          : '❌ Screen Time permission denied');
      await _storage.writeBool('screen_time_prompt_shown', true);
      widget.onComplete();
    } catch (e) {
      debugPrint('❌ Error requesting Screen Time permission: $e');
      widget.onComplete();
    } finally {
      if (mounted) setState(() => _isRequestingPermission = false);
    }
  }

  // Kept for completeness — wired to the confirmation dialog when the skip
  // button is re-enabled (see commented FastPlainButton block below).
  // ignore: unused_element
  Future<void> _onSkipPermission() async {
    await AnimationUtils.lightHaptic();
    final shouldSkip = await FastConfirmationDialog.show(
      title: 'screenPerm_dialogTitle'.tr,
      message: 'screenPerm_dialogMessage'.tr,
      confirmText: 'screenPerm_skipForNow'.tr,
      cancelText: 'continue_btn'.tr,
      isDestructiveConfirm: false,
    );
    if (shouldSkip) widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    // Single static screen (no typewriter): hero shield, title, the merged
    // intro/explanation as a subtitle, then the activate CTA.
    return OnboardingWrapper(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 156,
                height: 156,
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
                  icon: HugeIcons.strokeRoundedShield01,
                  size: 76,
                  color: CozyColors.primaryDark,
                ),
              ),
              const SizedBox(height: CozyTokens.space24),
              Text(
                'screenPerm_activateTitle'.tr,
                style: CozyText.title,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: CozyTokens.space12),
              Text(
                'screenPerm_subtitle'.tr,
                style: CozyText.body.copyWith(color: CozyColors.inkMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: CozyTokens.space32),
              CozyButton(
                text: _isRequestingPermission
                    ? 'screenPerm_requesting'.tr
                    : 'continue_btn'.tr,
                onTap:
                    _isRequestingPermission ? null : _onConnectScreenTime,
                isLoading: _isRequestingPermission,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
