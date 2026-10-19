import 'package:faithlock/features/onboarding/constants/onboarding_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

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
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            CupertinoSliverNavigationBar(
              largeTitle: Text(
                'progress_title'.tr,
                style: const TextStyle(
                  fontFamily: OnboardingTheme.fontFamily,
                  fontWeight: FontWeight.bold,
                  color: OnboardingTheme.labelPrimary,
                ),
              ),
              backgroundColor:
                  CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context)
                      .withValues(alpha: 0.92),
              border: Border(
                bottom: BorderSide(
                  color: CupertinoColors.separator.resolveFrom(context),
                  width: 0.5,
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section: Progress
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 12),
                      child: Text(
                        'progress_yourProgress'.tr.toUpperCase(),
                        style: TextStyle(
                          fontFamily: OnboardingTheme.fontFamily,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          color: CupertinoColors.secondaryLabel.resolveFrom(context),
                        ),
                      ),
                    ),

                    Container(
                      decoration: BoxDecoration(
                        color: CupertinoColors.tertiarySystemGroupedBackground
                            .resolveFrom(context),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildProgressItem(
                            context,
                            title: 'progress_dailyGoal'.tr,
                            progress: 0.7,
                            color: CupertinoColors.systemBlue,
                          ),
                          const SizedBox(height: 16),
                          _buildProgressItem(
                            context,
                            title: 'progress_weeklyGoal'.tr,
                            progress: 0.5,
                            color: CupertinoColors.systemGreen,
                          ),
                          const SizedBox(height: 16),
                          _buildProgressItem(
                            context,
                            title: 'progress_monthlyGoal'.tr,
                            progress: 0.3,
                            color: OnboardingTheme.goldColor,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Section: Stats
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 12),
                      child: Text(
                        'progress_statistics'.tr.toUpperCase(),
                        style: TextStyle(
                          fontFamily: OnboardingTheme.fontFamily,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          color: CupertinoColors.secondaryLabel.resolveFrom(context),
                        ),
                      ),
                    ),

                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildStatCard(context, 'progress_tasksCompleted'.tr, '24',
                            CupertinoColors.systemGreen),
                        _buildStatCard(context, 'progress_pendingTasks'.tr, '12',
                            OnboardingTheme.goldColor),
                        _buildStatCard(context, 'progress_successRate'.tr, '75%',
                            CupertinoColors.systemBlue),
                        _buildStatCard(context, 'progress_avgCompletionTime'.tr,
                            '3.2h', CupertinoColors.systemPurple),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressItem(
    BuildContext context, {
    required String title,
    required double progress,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: OnboardingTheme.body.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: OnboardingTheme.labelPrimary,
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: OnboardingTheme.footnote.copyWith(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: _ProgressBar(progress: progress, color: color),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      BuildContext context, String title, String value, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.tertiarySystemGroupedBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: OnboardingTheme.title1.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: OnboardingTheme.caption.copyWith(
              fontSize: 13,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple progress bar rendered without Material's LinearProgressIndicator
class _ProgressBar extends StatelessWidget {
  final double progress;
  final Color color;

  const _ProgressBar({required this.progress, required this.color});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: 10,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
