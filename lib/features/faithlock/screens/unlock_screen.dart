import 'package:faithlock/features/faithlock/controllers/unlock_controller.dart';
import 'package:faithlock/features/onboarding/constants/onboarding_theme.dart';
import 'package:faithlock/shared/widgets/mascot/judah_mascot.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Unlock Screen — 100 % Cupertino/iOS-native, Apple dark design language.
// ─────────────────────────────────────────────────────────────────────────────

class UnlockScreen extends StatelessWidget {
  const UnlockScreen({super.key});

  // ── Theme constants ────────────────────────────────────────────────────────
  static const _gold = OnboardingTheme.goldColor;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(UnlockController());

    return CupertinoTheme(
      data: const CupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: _gold,
        textTheme: CupertinoTextThemeData(
          navTitleTextStyle: TextStyle(
            fontFamily: OnboardingTheme.fontFamily,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: OnboardingTheme.labelPrimary,
          ),
        ),
      ),
      child: Builder(
        builder: (ctx) => CupertinoPageScaffold(
          // Nil backgroundColor → liquid-glass nav bar renders correctly.
          backgroundColor:
              CupertinoColors.secondarySystemGroupedBackground.resolveFrom(ctx),
          navigationBar: CupertinoNavigationBar(
            // Liquid-glass: do NOT set an opaque backgroundColor.
            middle: Text(
              'readAndAnswer'.tr,
              style: const TextStyle(
                fontFamily: OnboardingTheme.fontFamily,
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: OnboardingTheme.labelPrimary,
              ),
            ),
          ),
          child: SafeArea(
            child: Obx(() => _buildBody(ctx, controller)),
          ),
        ),
      ),
    );
  }

  // ── Body dispatch ──────────────────────────────────────────────────────────

  Widget _buildBody(BuildContext context, UnlockController controller) {
    if (controller.isLoading.value) {
      return _LoadingState();
    }

    if (controller.currentVerse.value == null ||
        controller.currentQuiz.value == null) {
      return _ErrorState(controller: controller);
    }

    return _QuizContent(controller: controller);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Loading state — skeleton-style with Judah sleeping mascot
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const JudahMascot(
            state: JudahState.sleeping,
            size: JudahSize.l,
          ),
          const SizedBox(height: 20),
          const CupertinoActivityIndicator(
            radius: 12,
            color: OnboardingTheme.goldColor,
          ),
          const SizedBox(height: 16),
          Text(
            'loadingVerse'.tr,
            style: const TextStyle(
              fontFamily: OnboardingTheme.fontFamily,
              fontSize: 15,
              color: OnboardingTheme.labelSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error state
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.controller});
  final UnlockController controller;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_circle,
              size: 56,
              color: CupertinoColors.systemRed,
            ),
            const SizedBox(height: 20),
            Text(
              'failedToLoadVerse'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: OnboardingTheme.fontFamily,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: OnboardingTheme.labelPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Obx(() => Text(
                  controller.errorMessage.value,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: OnboardingTheme.fontFamily,
                    fontSize: 15,
                    color: OnboardingTheme.labelSecondary,
                  ),
                )),
            const SizedBox(height: 32),
            _GoldButton(
              text: 'retry'.tr,
              onTap: controller.retryWithNewVerse,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main quiz content — scrollable
// ─────────────────────────────────────────────────────────────────────────────

class _QuizContent extends StatelessWidget {
  const _QuizContent({required this.controller});
  final UnlockController controller;

  @override
  Widget build(BuildContext context) {
    final verse = controller.currentVerse.value!;
    final quiz = controller.currentQuiz.value!;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Mascot ─────────────────────────────────────────────────
                Center(child: Obx(() => _buildMascot())),
                const SizedBox(height: 8),

                // ── Subtitle ───────────────────────────────────────────────
                Text(
                  'reflectOnVerse'.tr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: OnboardingTheme.fontFamily,
                    fontSize: 15,
                    color: OnboardingTheme.labelSecondary,
                  ),
                ),

                const SizedBox(height: 28),

                // ── Verse card ─────────────────────────────────────────────
                _VerseCard(verse: verse),

                const SizedBox(height: 28),

                // ── Question ───────────────────────────────────────────────
                Text(
                  quiz.question,
                  style: const TextStyle(
                    fontFamily: OnboardingTheme.fontFamily,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: OnboardingTheme.labelPrimary,
                  ),
                ),

                const SizedBox(height: 16),

                // ── Answer options ─────────────────────────────────────────
                Obx(() => Column(
                      children: List.generate(
                        quiz.options.length,
                        (i) => _AnswerOption(
                          label: quiz.options[i],
                          index: i,
                          controller: controller,
                        ),
                      ),
                    )),

                // ── Inline error / hint banner ─────────────────────────────
                Obx(() {
                  if (!controller.showError.value) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: _FeedbackBanner(
                      message: controller.errorMessage.value,
                      isWarning: controller.isAnswerRevealed.value,
                    ),
                  );
                }),

                const SizedBox(height: 12),

                // ── Attempt counter ────────────────────────────────────────
                Obx(() => Text(
                      'attemptCount'.trParams({
                        'current': controller.attemptCount.value.toString(),
                        'max': UnlockController.maxAttempts.toString(),
                      }),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: OnboardingTheme.fontFamily,
                        fontSize: 13,
                        color: OnboardingTheme.labelTertiary,
                      ),
                    )),

                const SizedBox(height: 20),

                // ── Primary CTA ────────────────────────────────────────────
                Obx(() {
                  final revealed = controller.isAnswerRevealed.value;
                  final noSelection = controller.selectedAnswer.value == -1;
                  if (revealed) {
                    return _GoldButton(
                      text: 'tryNewVerse'.tr,
                      onTap: controller.retryWithNewVerse,
                    );
                  }
                  return _GoldButton(
                    text: 'submitAnswer'.tr,
                    onTap: noSelection ? null : controller.submitAnswer,
                    disabled: noSelection,
                  );
                }),

                const SizedBox(height: 12),

                // ── Emergency bypass ───────────────────────────────────────
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(44, 44),
                  onPressed: () => _showBypassDialog(context, controller),
                  child: Text(
                    'emergencyBypassTitle'.tr,
                    style: const TextStyle(
                      fontFamily: OnboardingTheme.fontFamily,
                      fontSize: 14,
                      color: OnboardingTheme.labelTertiary,
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMascot() {
    final revealed = controller.isAnswerRevealed.value;
    final selected = controller.selectedAnswer.value;
    final correct = controller.currentQuiz.value?.correctAnswerIndex;
    final isCorrect = revealed && selected == correct;
    final isWrong = revealed && selected != correct;

    final JudahState state;
    final String? msg;

    if (isCorrect) {
      state = JudahState.happy;
      msg = 'correctAnswer'.tr;
    } else if (isWrong) {
      state = JudahState.encouraging;
      msg = 'wrongAnswer'.tr;
    } else {
      state = JudahState.encouraging;
      msg = null;
    }

    return JudahMascot(state: state, size: JudahSize.l, message: msg);
  }

  Future<void> _showBypassDialog(
    BuildContext context,
    UnlockController controller,
  ) async {
    HapticFeedback.mediumImpact();
    return showCupertinoDialog<void>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text(
          'emergencyBypassTitle'.tr,
          style: const TextStyle(fontFamily: OnboardingTheme.fontFamily),
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'emergencyBypassMessage'.tr,
            style: const TextStyle(
              fontFamily: OnboardingTheme.fontFamily,
              fontSize: 13,
            ),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'cancel'.tr,
              style: const TextStyle(fontFamily: OnboardingTheme.fontFamily),
            ),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(context).pop();
              controller.useEmergencyBypass();
            },
            child: Text(
              'bypass'.tr,
              style: const TextStyle(fontFamily: OnboardingTheme.fontFamily),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Verse card
// ─────────────────────────────────────────────────────────────────────────────

class _VerseCard extends StatelessWidget {
  const _VerseCard({required this.verse});
  final dynamic verse; // BibleVerse

  @override
  Widget build(BuildContext context) {
    // Elevated card: slightly lighter than the grouped bg
    final cardSurface =
        CupertinoColors.tertiarySystemGroupedBackground.resolveFrom(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardSurface,
        borderRadius: BorderRadius.circular(OnboardingTheme.radiusLarge),
        border: Border.all(color: OnboardingTheme.goldColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: OnboardingTheme.goldColor.withValues(alpha: 0.18),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '"${verse.text}"',
            style: const TextStyle(
              fontFamily: OnboardingTheme.fontFamily,
              fontSize: 18,
              fontStyle: FontStyle.italic,
              height: 1.65,
              color: OnboardingTheme.labelPrimary,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            verse.reference,
            style: const TextStyle(
              fontFamily: OnboardingTheme.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: OnboardingTheme.goldColor,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Answer option row
// ─────────────────────────────────────────────────────────────────────────────

class _AnswerOption extends StatelessWidget {
  const _AnswerOption({
    required this.label,
    required this.index,
    required this.controller,
  });

  final String label;
  final int index;
  final UnlockController controller;

  static const _font = OnboardingTheme.fontFamily;
  static const _gold = OnboardingTheme.goldColor;
  static const _textPrimary = OnboardingTheme.labelPrimary;

  @override
  Widget build(BuildContext context) {
    final isSelected = controller.selectedAnswer.value == index;
    final isCorrect = index == controller.currentQuiz.value!.correctAnswerIndex;
    final revealed = controller.isAnswerRevealed.value;

    final showCorrect = revealed && isCorrect;
    final showWrong = revealed && isSelected && !isCorrect;

    Color borderColor;
    Color bgColor;
    Color bulletColor;

    if (showCorrect) {
      borderColor = CupertinoColors.systemGreen;
      bgColor = CupertinoColors.systemGreen.withValues(alpha: 0.12);
      bulletColor = CupertinoColors.systemGreen;
    } else if (showWrong) {
      borderColor = CupertinoColors.systemRed;
      bgColor = CupertinoColors.systemRed.withValues(alpha: 0.12);
      bulletColor = CupertinoColors.systemRed;
    } else if (isSelected) {
      borderColor = _gold;
      bgColor = _gold.withValues(alpha: 0.08);
      bulletColor = _gold;
    } else {
      borderColor = OnboardingTheme.cardBorder;
      bgColor = OnboardingTheme.cardBackground;
      bulletColor = OnboardingTheme.labelTertiary;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () {
          if (!revealed) {
            HapticFeedback.selectionClick();
            controller.selectAnswer(index);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: isSelected || showCorrect || showWrong ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              // Bullet / checkmark
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (isSelected || showCorrect)
                      ? bulletColor
                      : CupertinoColors.transparent,
                  border: Border.all(color: bulletColor, width: 1.5),
                ),
                child: (isSelected || showCorrect)
                    ? const Icon(
                        CupertinoIcons.check_mark,
                        size: 13,
                        color: CupertinoColors.white,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: _font,
                    fontSize: 16,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: _textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Feedback banner (error / warning)
// ─────────────────────────────────────────────────────────────────────────────

class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner({required this.message, required this.isWarning});
  final String message;
  final bool isWarning;

  static const _font = OnboardingTheme.fontFamily;

  @override
  Widget build(BuildContext context) {
    final color =
        isWarning ? CupertinoColors.systemOrange : CupertinoColors.systemRed;
    final icon = isWarning
        ? CupertinoIcons.info_circle_fill
        : CupertinoIcons.exclamationmark_circle_fill;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: _font,
                fontSize: 14,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Gold primary button — matches onboarding CTA style
// ─────────────────────────────────────────────────────────────────────────────

class _GoldButton extends StatelessWidget {
  const _GoldButton({
    required this.text,
    required this.onTap,
    this.disabled = false,
  });

  final String text;
  final VoidCallback? onTap;
  final bool disabled;

  static const _font = OnboardingTheme.fontFamily;
  static const _gold = OnboardingTheme.goldColor;
  static const _bg = OnboardingTheme.backgroundColor;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: disabled ? null : () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: disabled ? _gold.withValues(alpha: 0.35) : _gold,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            fontFamily: _font,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: disabled ? _bg.withValues(alpha: 0.5) : _bg,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
