import 'dart:async';

import 'package:faithlock/features/onboarding/utils/animation_utils.dart';
import 'package:faithlock/features/onboarding/widgets/onboarding_wrapper.dart';
import 'package:faithlock/features/profile/controllers/settings_controller.dart';
import 'package:faithlock/shared/widgets/cozy/cozy.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// V3 Welcome Carousel — cozy rebuild. 3 slides, 3 value props, on the cream
/// canvas. Replaces the V2 single welcome screen; punchy, scannable, fast.
class V3WelcomeCarousel extends StatefulWidget {
  final VoidCallback onComplete;

  const V3WelcomeCarousel({super.key, required this.onComplete});

  @override
  State<V3WelcomeCarousel> createState() => _V3WelcomeCarouselState();
}

class _V3WelcomeCarouselState extends State<V3WelcomeCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Built fresh on every access so `.tr` re-resolves when the user switches
  // language via the toggle (a `static final` would cache the first locale).
  List<_CarouselSlide> get _slides => <_CarouselSlide>[
        _CarouselSlide(
          title: 'onbWelcome_slide1Title'.tr,
          body: 'onbWelcome_slide1Body'.tr,
          ctaIsFinal: false,
        ),
        _CarouselSlide(
          title: 'onbWelcome_slide2Title'.tr,
          body: 'onbWelcome_slide2Body'.tr,
          ctaIsFinal: false,
        ),
        _CarouselSlide(
          title: 'onbWelcome_slide3Title'.tr,
          body: 'onbWelcome_slide3Body'.tr,
          ctaIsFinal: true,
        ),
      ];

  Timer? _autoAdvanceTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduleAutoAdvance();
    });
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  /// Schedules the next-slide transition based on the current slide's
  /// estimated reading time. Last slide is left to the user to dismiss
  /// via the "I'm ready" CTA.
  void _scheduleAutoAdvance() {
    _autoAdvanceTimer?.cancel();
    if (_currentPage >= _slides.length - 1) return;

    final slide = _slides[_currentPage];
    final words = '${slide.title} ${slide.body}'
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .length;
    // ~170ms/word + 700ms buffer ≈ brisk skim pace. Tuned to feel
    // moving rather than meditative — users can still swipe ahead.
    final ms = 700 + words * 170;

    _autoAdvanceTimer = Timer(Duration(milliseconds: ms), () {
      if (!mounted) return;
      if (_currentPage < _slides.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  Future<void> _next() async {
    await AnimationUtils.lightHaptic();
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    } else {
      await AnimationUtils.heavyHaptic();
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingWrapper(
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 80, bottom: 20),
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                      _scheduleAutoAdvance();
                    },
                    itemCount: _slides.length,
                    itemBuilder: (context, index) =>
                        _SlideView(slide: _slides[index]),
                  ),
                ),
                const SizedBox(height: CozyTokens.space24),
                _PageIndicator(
                  count: _slides.length,
                  currentIndex: _currentPage,
                ),
                const SizedBox(height: CozyTokens.space24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: CozyButton(
                    text: _slides[_currentPage].ctaIsFinal
                        ? 'onbWelcome_readyButton'.tr
                        : 'onbWelcome_continueButton'.tr,
                    onTap: _next,
                  ),
                ),
                const SizedBox(height: CozyTokens.space16),
              ],
            ),
          ),
          const Positioned(
            top: 34,
            right: 24,
            child: _LanguageToggle(),
          ),
        ],
      ),
    );
  }
}

/// Language picker shown in the top-right of the first onboarding step.
/// Shows only the current flag + a caret; tapping opens a menu to choose
/// another language. Switches the app locale immediately via
/// [SettingsController].
class _LanguageToggle extends StatelessWidget {
  const _LanguageToggle();

  // Getter (not static final) so the labels re-resolve on locale change.
  List<List<String>> get _languages => [
        // [code, flag, label]
        ['en', '🇺🇸', 'onbWelcome_languageEnglish'.tr],
        ['fr', '🇫🇷', 'onbWelcome_languageFrancais'.tr],
      ];

  SettingsController get _settings => Get.isRegistered<SettingsController>()
      ? Get.find<SettingsController>()
      : Get.put(SettingsController());

  @override
  Widget build(BuildContext context) {
    final settings = _settings;
    return Obx(() {
      final lang = settings.appLanguage.value;
      final current = _languages.firstWhere(
        (l) => l[0] == lang,
        orElse: () => _languages.first,
      );
      return PopupMenuButton<String>(
        onSelected: settings.changeLanguage,
        offset: const Offset(0, 46),
        color: CozyColors.surface,
        elevation: 0,
        tooltip: '',
        shape: CozyTokens.smooth(
          CozyTokens.radiusMd,
          side: const BorderSide(
            color: CozyColors.outline,
            width: CozyTokens.borderWidth,
          ),
        ),
        itemBuilder: (context) => [
          for (final l in _languages)
            PopupMenuItem<String>(
              value: l[0],
              child: Row(
                children: [
                  Text(l[1], style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Text(l[2], style: CozyText.body),
                  if (l[0] == lang) ...[
                    const Spacer(),
                    const Icon(
                      Icons.check_rounded,
                      size: 18,
                      color: CozyColors.primary,
                    ),
                  ],
                ],
              ),
            ),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: ShapeDecoration(
            color: CozyColors.surface,
            shape: CozyTokens.smooth(
              CozyTokens.radiusPill,
              side: const BorderSide(
                color: CozyColors.outline,
                width: CozyTokens.borderWidth,
              ),
            ),
            shadows: CozyTokens.shadowHard,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(current[1], style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 4),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: CozyColors.ink,
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _CarouselSlide {
  final String title;
  final String body;
  final bool ctaIsFinal;

  const _CarouselSlide({
    required this.title,
    required this.body,
    required this.ctaIsFinal,
  });
}

class _SlideView extends StatelessWidget {
  final _CarouselSlide slide;
  const _SlideView({required this.slide});

  @override
  Widget build(BuildContext context) {
    // Centered when the content fits; scrollable when it doesn't.
    // The longest slide could overflow the bounded PageView height on shorter
    // screens — this keeps it safe everywhere.
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    slide.title,
                    style: CozyText.display.copyWith(fontSize: 32, height: 1.15),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: CozyTokens.space20),
                  Text(
                    slide.body,
                    style: CozyText.body.copyWith(
                      color: CozyColors.inkMuted,
                      fontSize: 17,
                      height: 1.45,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PageIndicator extends StatelessWidget {
  final int count;
  final int currentIndex;
  const _PageIndicator({required this.count, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 7,
          width: active ? 26 : 7,
          decoration: BoxDecoration(
            color: active
                ? CozyColors.primary
                : CozyColors.inkMuted.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(CozyTokens.radiusPill),
            border: active
                ? Border.all(
                    color: CozyColors.outline,
                    width: 1.2,
                  )
                : null,
          ),
        );
      }),
    );
  }
}
