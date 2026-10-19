import 'package:faithlock/features/lock_challenge/controllers/lock_challenge_controller.dart';
import 'package:faithlock/features/onboarding/constants/onboarding_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

/// Lock Challenge Screen - Powerful conviction-based quiz to unlock apps
class LockChallengeScreen extends StatelessWidget {
  const LockChallengeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LockChallengeController());

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
          child: Obx(() {
            if (controller.isCompleted.value) {
              return _buildVictoryScreen(context, controller);
            }
            return _buildQuizScreen(context, controller);
          }),
        ),
      ),
    );
  }

  Widget _buildQuizScreen(
      BuildContext context, LockChallengeController controller) {
    return Column(
      children: [
        // Progress bar
        _buildProgressBar(context, controller),

        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // Header icon
                const Center(
                  child: Text('🔥⚔️🔥', style: TextStyle(fontSize: 48)),
                ),

                const SizedBox(height: 24),

                // Title
                Center(
                  child: Text(
                    'challenge_momentOfTruth'.tr,
                    style: OnboardingTheme.title1.copyWith(
                      color: CupertinoColors.systemOrange,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 16),

                // Challenge message
                Obx(() => Center(
                      child: Text(
                        controller.challengeMessage.value,
                        style: OnboardingTheme.body.copyWith(
                          color: OnboardingTheme.labelPrimary,
                          fontSize: 17,
                          fontStyle: FontStyle.italic,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )),

                const SizedBox(height: 40),

                // Verse card
                Obx(() => _buildVerseCard(controller)),

                const SizedBox(height: 32),

                // Answer options
                Obx(() => _buildAnswerOptions(context, controller)),

                const SizedBox(height: 40),

                // Emergency bypass / action buttons
                _buildEmergencyBypass(context, controller),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(
      BuildContext context, LockChallengeController controller) {
    return Obx(() {
      final progress = controller.progress;
      return Column(
        children: [
          SizedBox(
            height: 4,
            child: _ProgressBar(progress: progress),
          ),
          const SizedBox(height: 12),
          Text(
            'challenge_questionProgress'.trParams({
              'current': '${controller.currentQuestionIndex.value + 1}',
              'total': '${controller.totalQuestions}',
            }),
            style: OnboardingTheme.footnote.copyWith(
              color: OnboardingTheme.labelTertiary,
              fontSize: 13,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildVerseCard(LockChallengeController controller) {
    final question = controller.currentQuestion;
    if (question == null) return const SizedBox.shrink();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: OnboardingTheme.cardBackground,
        borderRadius: BorderRadius.circular(OnboardingTheme.radiusMedium),
        border: Border.all(
          color: OnboardingTheme.goldColor,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: OnboardingTheme.goldColor.withValues(alpha: 0.3),
            blurRadius: 16,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question.verseWithBlank,
            style: OnboardingTheme.body.copyWith(
              fontSize: 18,
              height: 1.6,
              color: OnboardingTheme.labelPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '— ${question.reference}',
            style: OnboardingTheme.footnote.copyWith(
              fontSize: 14,
              color: OnboardingTheme.goldColor,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerOptions(
      BuildContext context, LockChallengeController controller) {
    final question = controller.currentQuestion;
    if (question == null) return const SizedBox.shrink();

    return Column(
      children: List.generate(
        question.options.length,
        (index) => _buildAnswerOption(context, controller, index,
            question.options[index]),
      ),
    );
  }

  Widget _buildAnswerOption(
    BuildContext context,
    LockChallengeController controller,
    int index,
    String option,
  ) {
    return Obx(() {
      final isSelected = controller.selectedAnswerIndex.value == index;
      final showResult = controller.showResult.value;
      final isCorrect = controller.isAnswerCorrect.value;

      Color backgroundColor;
      Color borderColor;
      Color textColor;

      if (showResult && isSelected) {
        backgroundColor = isCorrect
            ? CupertinoColors.systemGreen.withValues(alpha: 0.15)
            : CupertinoColors.systemRed.withValues(alpha: 0.15);
        borderColor =
            isCorrect ? CupertinoColors.systemGreen : CupertinoColors.systemRed;
        textColor =
            isCorrect ? CupertinoColors.systemGreen : CupertinoColors.systemRed;
      } else if (isSelected) {
        backgroundColor = OnboardingTheme.goldColor.withValues(alpha: 0.15);
        borderColor = OnboardingTheme.goldColor;
        textColor = OnboardingTheme.goldColor;
      } else {
        backgroundColor = OnboardingTheme.cardBackground;
        borderColor = OnboardingTheme.cardBorder;
        textColor = OnboardingTheme.labelPrimary;
      }

      return GestureDetector(
        onTap: showResult ? null : () => controller.selectAnswer(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius:
                BorderRadius.circular(OnboardingTheme.radiusMedium),
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: backgroundColor,
                  border: Border.all(color: borderColor, width: 2),
                ),
                child: showResult && isSelected
                    ? Icon(
                        isCorrect
                            ? CupertinoIcons.checkmark
                            : CupertinoIcons.xmark,
                        color: textColor,
                        size: 16,
                      )
                    : Center(
                        child: Text(
                          String.fromCharCode(65 + index), // A, B, C, D
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            fontFamily: OnboardingTheme.fontFamily,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  option,
                  style: OnboardingTheme.body.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildActionButtons(
      BuildContext context, LockChallengeController controller) {
    return Obx(() {
      final showResult = controller.showResult.value;
      final isCorrect = controller.isAnswerCorrect.value;

      if (!showResult) return const SizedBox.shrink();

      return Center(
        child: isCorrect
            ? CupertinoButton(
                color: CupertinoColors.systemGreen,
                borderRadius: BorderRadius.circular(12),
                onPressed: () => controller.nextQuestion(),
                child: Text(
                  controller.hasNextQuestion
                      ? 'challenge_nextQuestion'.tr
                      : 'challenge_complete'.tr,
                  style: TextStyle(
                    fontFamily: OnboardingTheme.fontFamily,
                    fontWeight: FontWeight.w600,
                    color: OnboardingTheme.labelPrimary,
                  ),
                ),
              )
            : CupertinoButton(
                color: CupertinoColors.systemOrange,
                borderRadius: BorderRadius.circular(12),
                onPressed: () => controller.retryQuestion(),
                child: Text(
                  'challenge_tryAgain'.tr,
                  style: TextStyle(
                    fontFamily: OnboardingTheme.fontFamily,
                    fontWeight: FontWeight.w600,
                    color: OnboardingTheme.labelPrimary,
                  ),
                ),
              ),
      );
    });
  }

  Widget _buildEmergencyBypass(
      BuildContext context, LockChallengeController controller) {
    return Center(
      child: Column(
        children: [
          Obx(() => _buildActionButtons(context, controller)),
          const SizedBox(height: 24),
          Text(
            'challenge_easyWayOut'.tr,
            style: OnboardingTheme.footnote.copyWith(
              color: OnboardingTheme.labelTertiary,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => _showBreakCovenantDialog(context, controller),
            child: Text(
              'challenge_surrenderCovenant'.tr,
              style: TextStyle(
                fontFamily: OnboardingTheme.fontFamily,
                color: CupertinoColors.systemRed.withValues(alpha: 0.7),
                fontSize: 14,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBreakCovenantDialog(
      BuildContext context, LockChallengeController controller) {
    showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(
          'challenge_breakCovenant'.tr,
          style: const TextStyle(
            fontFamily: OnboardingTheme.fontFamily,
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: CupertinoColors.systemRed,
          ),
        ),
        content: Text(
          'challenge_breakCovenantMessage'.tr,
          style: const TextStyle(
            fontFamily: OnboardingTheme.fontFamily,
            fontSize: 14,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: Text(
              'challenge_stayStrong'.tr,
              style: const TextStyle(
                fontFamily: OnboardingTheme.fontFamily,
                color: OnboardingTheme.goldColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: Text(
              'challenge_breakCovenantConfirm'.tr,
              style: const TextStyle(
                fontFamily: OnboardingTheme.fontFamily,
              ),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop(); // Close dialog
              await controller.breakCovenant();
              Get.back(); // Close challenge screen
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVictoryScreen(
      BuildContext context, LockChallengeController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🏆✨', style: TextStyle(fontSize: 80)),

            const SizedBox(height: 32),

            Text(
              'challenge_victory'.tr,
              style: OnboardingTheme.title1.copyWith(
                color: OnboardingTheme.goldColor,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            Text(
              'challenge_victoryMessage'.tr,
              style: OnboardingTheme.body.copyWith(
                color: OnboardingTheme.labelPrimary,
                fontSize: 18,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 48),

            Obx(() => Text(
                  'challenge_correctCount'.trParams({
                    'correct': '${controller.correctAnswersCount.value}',
                    'total': '${controller.totalQuestions}',
                  }),
                  style: OnboardingTheme.footnote.copyWith(
                    color: OnboardingTheme.labelSecondary,
                    fontSize: 15,
                  ),
                )),

            const SizedBox(height: 48),

            SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                color: OnboardingTheme.goldColor,
                borderRadius: BorderRadius.circular(14),
                onPressed: () {
                  Get.back();
                },
                child: Text(
                  'continue_btn'.tr,
                  style: TextStyle(
                    fontFamily: OnboardingTheme.fontFamily,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: OnboardingTheme.backgroundColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Gold progress bar with no Material dependency
class _ProgressBar extends StatelessWidget {
  final double progress;

  const _ProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Container(
        width: constraints.maxWidth,
        height: 4,
        color: OnboardingTheme.cardBackground,
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: OnboardingTheme.goldColor,
                boxShadow: [
                  BoxShadow(
                    color: OnboardingTheme.goldColor.withValues(alpha: 0.5),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
