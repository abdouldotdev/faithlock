import 'package:faithlock/features/onboarding/controllers/scripture_onboarding_v3_controller.dart';
import 'package:faithlock/features/onboarding/utils/animation_utils.dart';
import 'package:faithlock/features/onboarding/widgets/onboarding_wrapper.dart';
import 'package:faithlock/shared/widgets/cozy/cozy.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';

/// V3 Attribution — cozy rebuild. Extends V2 sources with faith-specific
/// channels (parish, podcast/Catholic media — high-value organic signals).
class V3Attribution extends StatefulWidget {
  final VoidCallback onComplete;
  const V3Attribution({super.key, required this.onComplete});

  @override
  State<V3Attribution> createState() => _V3AttributionState();
}

class _V3AttributionState extends State<V3Attribution> {
  final controller = Get.find<ScriptureOnboardingV3Controller>();
  String? _selected;
  double _opacity = 1.0;

  List<_Source> get _sources => [
    _Source('parish_pastor', 'onbAttribution_source_parish'.tr,
        FontAwesomeIcons.church, CozyColors.primary),
    _Source('podcast_media', 'onbAttribution_source_podcast'.tr,
        FontAwesomeIcons.microphoneLines, CozyColors.gold),
    _Source('friends_family', 'onbAttribution_source_friendsFamily'.tr,
        FontAwesomeIcons.userGroup, Color(0xFF60A5FA)),
    _Source('appstore', 'onbAttribution_source_appstore'.tr,
        FontAwesomeIcons.appStore, CozyColors.ink),
    _Source('google', 'onbAttribution_source_google'.tr,
        FontAwesomeIcons.google, Color(0xFF4285F4)),
    _Source('tiktok', 'onbAttribution_source_tiktok'.tr, FontAwesomeIcons.tiktok,
        Color(0xFFFF0050)),
    _Source('instagram', 'onbAttribution_source_instagram'.tr,
        FontAwesomeIcons.instagram, Color(0xFFE4405F)),
    _Source('ai', 'onbAttribution_source_ai'.tr, FontAwesomeIcons.robot,
        CozyColors.inkMuted),
    _Source('other', 'onbAttribution_source_other'.tr,
        FontAwesomeIcons.commentDots, CozyColors.inkMuted),
  ];

  Future<void> _onContinue() async {
    if (_selected == null) return;

    await controller.saveAttribution(_selected!);
    await AnimationUtils.heavyHaptic();

    setState(() => _opacity = 0.0);
    await Future.delayed(const Duration(milliseconds: 400));
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingWrapper(
      child: AnimatedOpacity(
        opacity: _opacity,
        duration: const Duration(milliseconds: 400),
        child: Stack(
          children: [
            Positioned.fill(
              bottom: 110,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 96, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'onbAttribution_title'.tr,
                      style: CozyText.title,
                    ),
                    const SizedBox(height: CozyTokens.space24),
                    ..._sources.asMap().entries.map((entry) {
                      final index = entry.key;
                      final src = entry.value;
                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: Duration(milliseconds: 350 + (index * 60)),
                        curve: Curves.easeOut,
                        builder: (context, value, child) => Transform.translate(
                          offset: Offset(0, 16 * (1 - value)),
                          child: Opacity(opacity: value, child: child),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _SourceCard(
                            source: src,
                            isSelected: _selected == src.id,
                            onTap: () {
                              AnimationUtils.lightHaptic();
                              setState(() => _selected = src.id);
                            },
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      CozyColors.background.withValues(alpha: 0),
                      CozyColors.background,
                    ],
                  ),
                ),
                child: CozyButton(
                  text: 'onbAttribution_continue'.tr,
                  onTap: _selected != null ? _onContinue : null,
                  isDisabled: _selected == null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Source {
  final String id;
  final String label;
  final IconData icon;
  final Color iconColor;
  const _Source(this.id, this.label, this.icon, this.iconColor);
}

class _SourceCard extends StatelessWidget {
  final _Source source;
  final bool isSelected;
  final VoidCallback onTap;

  const _SourceCard({
    required this.source,
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
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
            SizedBox(
              width: 28,
              child: Center(
                child: FaIcon(
                  source.icon,
                  size: 18,
                  color: source.iconColor,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                source.label,
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
                width: 26,
                height: 26,
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
