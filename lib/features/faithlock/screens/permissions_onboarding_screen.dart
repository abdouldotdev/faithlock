import 'package:faithlock/features/faithlock/services/screen_time_service.dart';
import 'package:faithlock/features/onboarding/constants/onboarding_theme.dart';
import 'package:faithlock/navigation/screens/main_screen.dart';
import 'package:faithlock/shared/widgets/notifications/fast_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

/// Permissions Onboarding Screen
/// Request Screen Time permission on first launch
class PermissionsOnboardingScreen extends StatefulWidget {
  const PermissionsOnboardingScreen({super.key});

  @override
  State<PermissionsOnboardingScreen> createState() =>
      _PermissionsOnboardingScreenState();
}

class _PermissionsOnboardingScreenState
    extends State<PermissionsOnboardingScreen> {
  final ScreenTimeService _screenTimeService = ScreenTimeService();
  bool _isRequesting = false;

  Future<void> _requestPermission() async {
    setState(() {
      _isRequesting = true;
    });

    try {
      await _screenTimeService.requestAuthorization();
      await Future.delayed(const Duration(milliseconds: 500));

      final isAuthorized = await _screenTimeService.isAuthorized();

      if (mounted) {
        setState(() {
          _isRequesting = false;
        });

        if (isAuthorized) {
          FastToast.showSuccess(
            context: context,
            message: 'permissions_successMsg'.tr,
          );
          await Future.delayed(const Duration(milliseconds: 500));
          Get.offAll(() => MainScreen());
        } else {
          FastToast.showError(
            context: context,
            message: 'permissions_deniedMsg'.tr,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRequesting = false;
        });
        FastToast.showError(
          context: context,
          message: 'permissions_failedMsg'.tr,
        );
      }
    }
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
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const Spacer(),

                // Shield icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: OnboardingTheme.goldColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.lock_shield_fill,
                    size: 64,
                    color: OnboardingTheme.goldColor,
                  ),
                ),

                const SizedBox(height: 32),

                // Title
                Text(
                  'permissions_enableScreenTime'.tr,
                  style: OnboardingTheme.title2.copyWith(
                    color: OnboardingTheme.labelPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                // Description
                Text(
                  'permissions_description'.tr,
                  style: OnboardingTheme.body.copyWith(
                    color: OnboardingTheme.labelSecondary,
                    fontSize: 17,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                // Continue button
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    color: OnboardingTheme.goldColor,
                    borderRadius: BorderRadius.circular(14),
                    onPressed: _isRequesting ? null : _requestPermission,
                    child: _isRequesting
                        ? const CupertinoActivityIndicator(
                            color: CupertinoColors.white,
                            radius: 12,
                          )
                        : Text(
                            'Continue',
                            style: TextStyle(
                              fontFamily: OnboardingTheme.fontFamily,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: OnboardingTheme.backgroundColor,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
