import 'package:faithlock/features/onboarding/utils/animation_utils.dart';
import 'package:faithlock/features/onboarding/widgets/onboarding_wrapper.dart';
import 'package:faithlock/shared/widgets/cozy/cozy.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// V3 Social Proof — cozy rebuild. Testimonials wall with two opposite-scrolling
/// marquees on the cream canvas, chunky bordered cards, terracotta accents.
class V3SocialProof extends StatefulWidget {
  final VoidCallback onComplete;
  const V3SocialProof({super.key, required this.onComplete});

  @override
  State<V3SocialProof> createState() => _V3SocialProofState();
}

class _V3SocialProofState extends State<V3SocialProof> {
  double _opacity = 1.0;

  List<_Testimonial> get _topRow => <_Testimonial>[
    _Testimonial(
      quote: 'onbSocialProof_tMarc_quote'.tr,
      author: 'onbSocialProof_tMarc_author'.tr,
      detail: 'onbSocialProof_tMarc_detail'.tr,
    ),
    _Testimonial(
      quote: 'onbSocialProof_tJames_quote'.tr,
      author: 'onbSocialProof_tJames_author'.tr,
      detail: 'onbSocialProof_tJames_detail'.tr,
    ),
    _Testimonial(
      quote: 'onbSocialProof_tDavid_quote'.tr,
      author: 'onbSocialProof_tDavid_author'.tr,
      detail: 'onbSocialProof_tDavid_detail'.tr,
    ),
    _Testimonial(
      quote: 'onbSocialProof_tDaniel_quote'.tr,
      author: 'onbSocialProof_tDaniel_author'.tr,
      detail: 'onbSocialProof_tDaniel_detail'.tr,
    ),
  ];

  List<_Testimonial> get _bottomRow => <_Testimonial>[
    _Testimonial(
      quote: 'onbSocialProof_tSarah_quote'.tr,
      author: 'onbSocialProof_tSarah_author'.tr,
      detail: 'onbSocialProof_tSarah_detail'.tr,
    ),
    _Testimonial(
      quote: 'onbSocialProof_tHannah_quote'.tr,
      author: 'onbSocialProof_tHannah_author'.tr,
      detail: 'onbSocialProof_tHannah_detail'.tr,
    ),
    _Testimonial(
      quote: 'onbSocialProof_tMaria_quote'.tr,
      author: 'onbSocialProof_tMaria_author'.tr,
      detail: 'onbSocialProof_tMaria_detail'.tr,
    ),
    _Testimonial(
      quote: 'onbSocialProof_tGrace_quote'.tr,
      author: 'onbSocialProof_tGrace_author'.tr,
      detail: 'onbSocialProof_tGrace_detail'.tr,
    ),
  ];

  Future<void> _onContinue() async {
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 96, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ...List.generate(
                            5,
                            (_) => const Padding(
                              padding: EdgeInsets.only(right: 2),
                              child: Text(
                                '★',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: CozyColors.gold,
                                  height: 1,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'onbSocialProof_rating'.tr,
                            style: CozyText.subtitle,
                          ),
                        ],
                      ),
                      const SizedBox(height: CozyTokens.space16),
                      Text(
                        'onbSocialProof_title'.tr,
                        style: CozyText.title,
                      ),
                      const SizedBox(height: CozyTokens.space8),
                      Text(
                        'onbSocialProof_subtitle'.tr,
                        style: CozyText.body
                            .copyWith(color: CozyColors.inkMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: CozyTokens.space24),
                SizedBox(
                  height: 320,
                  child: ShaderMask(
                    shaderCallback: (rect) => const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.transparent,
                        Colors.white,
                        Colors.white,
                        Colors.transparent,
                      ],
                      stops: [0.0, 0.05, 0.95, 1.0],
                    ).createShader(rect),
                    blendMode: BlendMode.dstIn,
                    child: Column(
                      children: [
                        Expanded(
                          child: _MarqueeRow(
                            items: _topRow,
                            rightToLeft: true,
                          ),
                        ),
                        const SizedBox(height: CozyTokens.space12),
                        Expanded(
                          child: _MarqueeRow(
                            items: _bottomRow,
                            rightToLeft: false,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 96),
              ],
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
                  text: 'onbSocialProof_ctaButton'.tr,
                  onTap: _onContinue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Testimonial {
  final String quote;
  final String author;
  final String detail;
  const _Testimonial({
    required this.quote,
    required this.author,
    required this.detail,
  });
}

/// A single horizontal marquee: content is doubled and translated continuously
/// so it loops seamlessly. [rightToLeft] flips the direction.
class _MarqueeRow extends StatefulWidget {
  final List<_Testimonial> items;
  final bool rightToLeft;
  const _MarqueeRow({required this.items, required this.rightToLeft});

  @override
  State<_MarqueeRow> createState() => _MarqueeRowState();
}

class _MarqueeRowState extends State<_MarqueeRow>
    with SingleTickerProviderStateMixin {
  static const double _cardWidth = 210;
  static const double _unit = _cardWidth + 12;
  static const double _pxPerSecond = 34;

  late final AnimationController _c;
  late final double _runWidth;

  @override
  void initState() {
    super.initState();
    _runWidth = widget.items.length * _unit;
    _c = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: (_runWidth / _pxPerSecond * 1000).round(),
      ),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final doubled = [...widget.items, ...widget.items];
    final track = OverflowBox(
      alignment: Alignment.centerLeft,
      maxWidth: double.infinity,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final t in doubled)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: SizedBox(
                width: _cardWidth,
                child: _TestimonialCard(testimonial: t),
              ),
            ),
        ],
      ),
    );

    return ClipRect(
      child: AnimatedBuilder(
        animation: _c,
        child: track,
        builder: (context, child) {
          final v = _c.value;
          final dx =
              widget.rightToLeft ? -v * _runWidth : -(1 - v) * _runWidth;
          return Transform.translate(offset: Offset(dx, 0), child: child);
        },
      ),
    );
  }
}

class _TestimonialCard extends StatelessWidget {
  final _Testimonial testimonial;
  const _TestimonialCard({required this.testimonial});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: ShapeDecoration(
        color: CozyColors.surface,
        shape: CozyTokens.smooth(
          CozyTokens.radiusLg,
          side: const BorderSide(
            color: CozyColors.outline,
            width: CozyTokens.borderWidth,
          ),
        ),
        shadows: CozyTokens.shadowHard,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Text(
              '"${testimonial.quote}"',
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              style: CozyText.body.copyWith(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: CozyTokens.space12),
          Text(
            '— ${testimonial.author}, ${testimonial.detail}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: CozyText.label.copyWith(color: CozyColors.primary),
          ),
        ],
      ),
    );
  }
}
