import 'package:faithlock/features/onboarding/constants/onboarding_theme.dart';
import 'package:faithlock/features/onboarding/utils/animation_utils.dart';
import 'package:faithlock/features/paywall/screens/paywall_screen_v2.dart';
import 'package:faithlock/services/notifications/winback_notification_service.dart';
import 'package:faithlock/shared/widgets/mascot/judah_mascot.dart';
import 'package:faithlock/shared/widgets/notifications/fast_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class SubscriptionExpiredScreen extends StatefulWidget {
  final bool wasTrialUser;
  final DateTime? expirationDate;

  const SubscriptionExpiredScreen({
    super.key,
    this.wasTrialUser = false,
    this.expirationDate,
  });

  @override
  State<SubscriptionExpiredScreen> createState() =>
      _SubscriptionExpiredScreenState();
}

class _SubscriptionExpiredScreenState extends State<SubscriptionExpiredScreen>
    with SingleTickerProviderStateMixin {
  bool _showContent = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _startAnimation();
    _triggerWinBack();
  }

  void _triggerWinBack() {
    WinBackNotificationService()
        .scheduleWinBackSequence(source: 'expired_screen');
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() => _showContent = true);
    await AnimationUtils.mediumHaptic();
  }

  String _getTitle() {
    if (widget.wasTrialUser) {
      return 'expired_trialEnded'.tr;
    }
    return 'expired_subscriptionExpired'.tr;
  }

  String _getMessage() {
    if (widget.wasTrialUser) {
      return 'expired_trialMessage'.tr;
    }
    return 'expired_subscriptionMessage'.tr;
  }

  void _onRenewNow() async {
    await AnimationUtils.heavyHaptic();

    Get.off(() => const PaywallScreenV2());
  }

  Future<void> _onContactSupport() async {
    await AnimationUtils.lightHaptic();

    const String email = 'support@faithlock.app';
    const String subject = 'FaithLock Subscription Support';
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': subject,
        'body': widget.wasTrialUser
            ? 'I have questions about continuing after my trial period.\n\n'
            : 'I have questions about renewing my subscription.\n\n',
      },
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        FastToast.error(
          'expired_emailError'.trParams({'email': email}),
          title: 'expired_errorTitle'.tr,
        );
      }
    } catch (e) {
      FastToast.error(
        'Could not open email client. Please email us at $email',
        title: 'Error',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scaffoldBg = CupertinoColors.secondarySystemGroupedBackground
        .resolveFrom(context);

    return CupertinoTheme(
      data: const CupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: OnboardingTheme.goldColor,
      ),
      child: CupertinoPageScaffold(
        backgroundColor: scaffoldBg,
        child: SafeArea(
          child: AnimatedOpacity(
            opacity: _showContent ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 800),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: OnboardingTheme.horizontalPadding,
                  vertical: OnboardingTheme.verticalPadding,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Judah sad mascot
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: const JudahMascot(
                            state: JudahState.sad,
                            size: JudahSize.xl,
                            showMessage: false,
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: OnboardingTheme.space40),

                    // Title
                    Text(
                      _getTitle(),
                      style: OnboardingTheme.title2.copyWith(
                        color: OnboardingTheme.labelPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: OnboardingTheme.space24),

                    // Message
                    Text(
                      _getMessage(),
                      style: OnboardingTheme.body.copyWith(
                        color: OnboardingTheme.labelSecondary,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: OnboardingTheme.space40),

                    // What you'll get back section
                    Container(
                      padding: const EdgeInsets.all(OnboardingTheme.space24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            OnboardingTheme.goldColor.withValues(alpha: 0.1),
                            OnboardingTheme.goldColor.withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius:
                            BorderRadius.circular(OnboardingTheme.radiusLarge),
                        border: Border.all(
                          color: OnboardingTheme.goldColor.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'expired_continueJourney'.tr,
                            style: OnboardingTheme.callout.copyWith(
                              color: OnboardingTheme.labelPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: OnboardingTheme.space20),
                          _buildBenefit(
                            icon: CupertinoIcons.shield_fill,
                            text: 'expired_benefit1'.tr,
                          ),
                          const SizedBox(height: OnboardingTheme.space16),
                          _buildBenefit(
                            icon: CupertinoIcons.clock_fill,
                            text: 'expired_benefit2'.tr,
                          ),
                          const SizedBox(height: OnboardingTheme.space16),
                          _buildBenefit(
                            icon: CupertinoIcons.heart_fill,
                            text: 'expired_benefit3'.tr,
                          ),
                          const SizedBox(height: OnboardingTheme.space16),
                          _buildBenefit(
                            icon: CupertinoIcons.graph_circle_fill,
                            text: 'expired_benefit4'.tr,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: OnboardingTheme.space40),

                    // Stats reminder
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: OnboardingTheme.space16,
                        vertical: OnboardingTheme.space12,
                      ),
                      decoration: BoxDecoration(
                        color: OnboardingTheme.systemGreen.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(OnboardingTheme.radiusMedium),
                        border: Border.all(
                          color: OnboardingTheme.systemGreen.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            CupertinoIcons.graph_circle_fill,
                            size: 20,
                            color: OnboardingTheme.systemGreen,
                          ),
                          const SizedBox(width: OnboardingTheme.space8),
                          Flexible(
                            child: Text(
                              'expired_usersReport'.tr,
                              style: OnboardingTheme.footnote.copyWith(
                                color: OnboardingTheme.systemGreen,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: OnboardingTheme.space40),

                    // Renew button
                    GestureDetector(
                      onTap: _onRenewNow,
                      child: Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          color: OnboardingTheme.goldColor,
                          borderRadius:
                              BorderRadius.circular(OnboardingTheme.radiusMedium),
                        ),
                        child: Center(
                          child: Text(
                            'expired_renewBtn'.tr,
                            style: OnboardingTheme.callout.copyWith(
                              color: OnboardingTheme.backgroundColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: OnboardingTheme.space16),

                    // Optional: Contact support
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      onPressed: _onContactSupport,
                      child: Text(
                        'expired_needHelp'.tr,
                        style: OnboardingTheme.footnote.copyWith(
                          color: OnboardingTheme.labelTertiary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBenefit({required IconData icon, required String text}) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: OnboardingTheme.goldColor.withValues(alpha: 0.2),
          ),
          child: Icon(
            icon,
            size: 20,
            color: OnboardingTheme.goldColor,
          ),
        ),
        const SizedBox(width: OnboardingTheme.space12),
        Expanded(
          child: Text(
            text,
            style: OnboardingTheme.body.copyWith(
              color: OnboardingTheme.labelPrimary,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }
}
