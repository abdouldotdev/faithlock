import 'package:faithlock/features/onboarding/controllers/scripture_onboarding_v3_controller.dart';
import 'package:faithlock/features/onboarding/utils/animation_utils.dart';
import 'package:faithlock/features/onboarding/widgets/onboarding_wrapper.dart';
import 'package:faithlock/shared/widgets/cozy/cozy.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';

/// V3 Apps & Rules — cozy rebuild. 2-step flow:
///   Step 0: which apps to block (multi-select grid with brand logos)
///   Step 1: unblock rules (single-select)
class V3AppsAndRules extends StatefulWidget {
  final VoidCallback onComplete;
  const V3AppsAndRules({super.key, required this.onComplete});

  @override
  State<V3AppsAndRules> createState() => _V3AppsAndRulesState();
}

class _V3AppsAndRulesState extends State<V3AppsAndRules> {
  final controller = Get.find<ScriptureOnboardingV3Controller>();

  int _step = 0;
  static const _stepCount = 2;

  final Set<String> _apps = {};
  String? _unblockRule;
  double _opacity = 1.0;
  bool _advancing = false;

  List<_AppEntry> get _appOptions => [
    _AppEntry('onbAppsAndRules_app_instagram'.tr, FontAwesomeIcons.instagram,
        Color(0xFFE4405F)),
    _AppEntry(
        'onbAppsAndRules_app_tiktok'.tr, FontAwesomeIcons.tiktok, Color(0xFFFF0050)),
    _AppEntry(
        'onbAppsAndRules_app_xTwitter'.tr, FontAwesomeIcons.xTwitter, CozyColors.ink),
    _AppEntry('onbAppsAndRules_app_youtube'.tr, FontAwesomeIcons.youtube,
        Color(0xFFFF0000)),
    _AppEntry('onbAppsAndRules_app_facebook'.tr, FontAwesomeIcons.facebookF,
        Color(0xFF1877F2)),
    _AppEntry('onbAppsAndRules_app_reddit'.tr, FontAwesomeIcons.redditAlien,
        Color(0xFFFF4500)),
    _AppEntry('onbAppsAndRules_app_newsApps'.tr, FontAwesomeIcons.newspaper,
        CozyColors.inkMuted),
    _AppEntry(
        'onbAppsAndRules_app_other'.tr, FontAwesomeIcons.plus, CozyColors.inkMuted),
  ];

  List<String> get _ruleOptions => [
    'onbAppsAndRules_rule_workHours'.tr,
    'onbAppsAndRules_rule_specificContacts'.tr,
    'onbAppsAndRules_rule_blockFully'.tr,
    'onbAppsAndRules_rule_decideLater'.tr,
  ];

  bool get _isCurrentStepValid {
    switch (_step) {
      case 0:
        return _apps.isNotEmpty;
      case 1:
        return _unblockRule != null;
      default:
        return false;
    }
  }

  Future<void> _onContinue() async {
    if (!_isCurrentStepValid) return;
    await AnimationUtils.lightHaptic();

    if (_step < _stepCount - 1) {
      setState(() => _step++);
      return;
    }

    await controller.saveSelectedApps(_apps.toList());
    await controller.saveUnblockRules([_unblockRule!]);
    await AnimationUtils.heavyHaptic();

    setState(() => _opacity = 0.0);
    await Future.delayed(const Duration(milliseconds: 400));
    widget.onComplete();
  }

  /// The unblock-rule step is single-select: tapping a rule registers it then
  /// auto-advances (it's the last step, so this saves + completes). No button.
  Future<void> _selectRule(String rule) async {
    if (_advancing) return;
    _advancing = true;
    setState(() => _unblockRule = rule);
    await Future.delayed(const Duration(milliseconds: 280));
    if (!mounted) {
      _advancing = false;
      return;
    }
    await _onContinue();
    _advancing = false;
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingWrapper(
      child: AnimatedOpacity(
        opacity: _opacity,
        duration: const Duration(milliseconds: 400),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 96, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 450),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  // Top-align so the title sits at the top instead of being
                  // vertically centered by the switcher's default alignment.
                  layoutBuilder: (currentChild, previousChildren) => Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      ...previousChildren,
                      if (currentChild != null) currentChild,
                    ],
                  ),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween(
                        begin: const Offset(0.04, 0),
                        end: Offset.zero,
                      ).animate(anim),
                      child: child,
                    ),
                  ),
                  child: KeyedSubtree(
                    key: ValueKey(_step),
                    child: _buildStep(),
                  ),
                ),
              ),
              // Only the apps step (multi-select) keeps a button; the unblock
              // step is single-select and auto-advances on tap.
              if (_step == 0) ...[
                const SizedBox(height: CozyTokens.space16),
                CozyButton(
                  text: 'onbAppsAndRules_nextButton'.tr,
                  onTap: _isCurrentStepValid ? _onContinue : null,
                  isDisabled: !_isCurrentStepValid,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'onbAppsAndRules_appsTitle'.tr,
                style: CozyText.title,
              ),
              const SizedBox(height: CozyTokens.space8),
              Text('onbAppsAndRules_appsSubtitle'.tr, style: CozyText.subtitle),
              const SizedBox(height: CozyTokens.space24),
              ..._appOptions.map((app) {
                final selected = _apps.contains(app.label);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _AppTile(
                    entry: app,
                    selected: selected,
                    onTap: () {
                      AnimationUtils.lightHaptic();
                      setState(() {
                        if (selected) {
                          _apps.remove(app.label);
                        } else {
                          _apps.add(app.label);
                        }
                      });
                    },
                  ),
                );
              }),
            ],
          ),
        );
      case 1:
      default:
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'onbAppsAndRules_rulesTitle'.tr,
                style: CozyText.title,
              ),
              const SizedBox(height: CozyTokens.space24),
              ..._ruleOptions.map((rule) {
                final selected = _unblockRule == rule;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _RuleCard(
                    label: rule,
                    isSelected: selected,
                    onTap: () => _selectRule(rule),
                  ),
                );
              }),
            ],
          ),
        );
    }
  }
}

class _AppEntry {
  final String label;
  final IconData icon;
  final Color brandColor;
  const _AppEntry(this.label, this.icon, this.brandColor);
}

class _AppTile extends StatelessWidget {
  final _AppEntry entry;
  final bool selected;
  final VoidCallback onTap;

  const _AppTile({
    required this.entry,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const accent = CozyColors.primary;
    return CozyTappable(
      onTap: onTap,
      pressedScale: 0.98,
      child: AnimatedContainer(
        duration: CozyTokens.base,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: ShapeDecoration(
          color: selected ? CozyColors.selectedFill : CozyColors.surface,
          shape: CozyTokens.smooth(
            CozyTokens.radiusLg,
            side: BorderSide(
              color: selected ? accent : CozyColors.outline,
              width: CozyTokens.borderWidth,
            ),
          ),
          shadows: CozyTokens.shadowHard,
        ),
        child: Row(
          children: [
            FaIcon(entry.icon, size: 22, color: entry.brandColor),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                entry.label,
                style: CozyText.body.copyWith(
                  color: selected ? accent : CozyColors.ink,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            AnimatedOpacity(
              opacity: selected ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: CozyColors.surface, width: 2),
                ),
                child: const HugeIcon(
                  icon: HugeIcons.strokeRoundedTick02,
                  size: 14,
                  color: CozyColors.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _RuleCard({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = CozyColors.primary;
    return CozyTappable(
      onTap: onTap,
      pressedScale: 0.98,
      child: AnimatedContainer(
        duration: CozyTokens.base,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: ShapeDecoration(
          color: isSelected ? CozyColors.selectedFill : CozyColors.surface,
          shape: CozyTokens.smooth(
            CozyTokens.radiusLg,
            side: BorderSide(
              color: isSelected ? accent : CozyColors.outline,
              width: CozyTokens.borderWidth,
            ),
          ),
          shadows: CozyTokens.shadowHard,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: CozyText.body.copyWith(
                  color: isSelected ? accent : CozyColors.ink,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            AnimatedOpacity(
              opacity: isSelected ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: CozyColors.surface, width: 2),
                ),
                child: const HugeIcon(
                  icon: HugeIcons.strokeRoundedTick02,
                  size: 14,
                  color: CozyColors.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
