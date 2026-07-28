import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../achievements/widgets/achievement_icons.dart';
import '../models/daily_learning_stat.dart';
import '../models/learning_analytics.dart';
import '../models/script_analytics.dart';
import '../models/weak_area.dart';
import '../providers/analytics_providers.dart';
import '../widgets/activity_heatmap.dart';
import '../widgets/insight_card.dart';
import '../widgets/progress_ring.dart';
import '../widgets/script_summary_card.dart';
import '../widgets/statistic_card.dart';
import '../widgets/trend_chart.dart';
import '../widgets/weak_area_card.dart';

const Map<String, String> _scriptTitles = <String, String>{
  'hiragana': 'Hiragana',
  'katakana': 'Katakana',
  'kanji': 'Kanji',
};

String _scriptTitle(String contentId) => _scriptTitles[contentId] ?? contentId;

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<LearningAnalytics> analyticsAsync = ref.watch(
      learningAnalyticsProvider,
    );

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.ios_share_outlined),
            onSelected: (String value) => _export(
              context,
              ref,
              analyticsAsync.asData?.value,
              asCsv: value == 'csv',
            ),
            itemBuilder: (BuildContext context) => const [
              PopupMenuItem<String>(value: 'csv', child: Text('Export as CSV')),
              PopupMenuItem<String>(
                value: 'json',
                child: Text('Export as JSON'),
              ),
            ],
          ),
        ],
      ),
      child: analyticsAsync.when(
        data: (LearningAnalytics analytics) =>
            _AnalyticsContent(analytics: analytics),
        loading: () => const LoadingIndicator(),
        error: (Object error, StackTrace stackTrace) =>
            _AnalyticsContent(analytics: LearningAnalytics.empty),
      ),
    );
  }

  Future<void> _export(
    BuildContext context,
    WidgetRef ref,
    LearningAnalytics? analytics, {
    required bool asCsv,
  }) async {
    if (analytics == null) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    try {
      final file = await ref
          .read(analyticsExportServiceProvider)
          .exportToFile(analytics, asCsv: asCsv);
      messenger.showSnackBar(SnackBar(content: Text('Saved to ${file.path}')));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Export failed. Please try again.')),
      );
    }
  }
}

class _AnalyticsContent extends StatelessWidget {
  const _AnalyticsContent({required this.analytics});

  final LearningAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.md),
          Text(
            'Overall Progress',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: ProgressRing(
              percentage: analytics.completionPercentage,
              label: 'Overall Completion',
              size: 120,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              StatisticCard(
                icon: Icons.check_circle_outline,
                label: 'Lessons Completed',
                value: '${analytics.totalLessonsCompleted}',
              ),
              StatisticCard(
                icon: Icons.quiz_outlined,
                label: 'Practice Sessions',
                value: '${analytics.totalPracticeSessions}',
              ),
              StatisticCard(
                icon: Icons.refresh,
                label: 'Total Reviews',
                value: '${analytics.totalReviews}',
              ),
              StatisticCard(
                icon: Icons.timer_outlined,
                label: 'Study Time (est.)',
                value: '${analytics.estimatedStudyMinutes} min',
              ),
              StatisticCard(
                icon: Icons.local_fire_department_outlined,
                label: 'Current Streak',
                value:
                    '${analytics.currentStreakDays} day${analytics.currentStreakDays == 1 ? '' : 's'}',
              ),
              StatisticCard(
                icon: Icons.emoji_events_outlined,
                label: 'Longest Streak',
                value:
                    '${analytics.longestStreakDays} day${analytics.longestStreakDays == 1 ? '' : 's'}',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Script Breakdown',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              for (final ScriptAnalytics script in analytics.scriptBreakdown)
                SizedBox(
                  width: 280,
                  child: ScriptSummaryCard(
                    title: _scriptTitle(script.contentId),
                    analytics: script,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Accuracy Trends',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          TrendChart(
            series: [
              TrendSeries(
                label: 'Writing accuracy',
                color: Theme.of(context).colorScheme.primary,
                values: [
                  for (final DailyLearningStat day in analytics.dailyActivity)
                    day.averageWritingAccuracy,
                ],
              ),
              TrendSeries(
                label: 'Quiz accuracy',
                color: Theme.of(context).colorScheme.secondary,
                values: [
                  for (final DailyLearningStat day in analytics.dailyActivity)
                    day.averageQuizAccuracy,
                ],
              ),
              TrendSeries(
                label: 'Review success rate',
                color: AppColors.warning,
                values: [
                  for (final DailyLearningStat day in analytics.dailyActivity)
                    day.reviewSuccessRate == null
                        ? null
                        : day.reviewSuccessRate! * 100,
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Activity Calendar',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          ActivityHeatmap(days: analytics.dailyActivity),
          const SizedBox(height: AppSpacing.xl),
          Text('Weak Areas', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () =>
                  context.push('/quiz/play?mode=weak_items&length=10'),
              icon: const Icon(Icons.fitness_center),
              label: const Text('Practice Now'),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (analytics.weakAreas.isEmpty)
            Text(
              'No weak areas detected yet — keep learning!',
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else
            Column(
              children: [
                for (final WeakArea area in analytics.weakAreas)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: WeakAreaCard(weakArea: area),
                  ),
              ],
            ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Achievement Summary',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          StatisticCard(
            icon: Icons.emoji_events_outlined,
            label: 'Unlocked',
            value:
                '${analytics.achievementsUnlocked} / ${analytics.achievementsTotal}',
          ),
          if (analytics.nextAchievements.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text('Next up', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            for (final next in analytics.nextAchievements)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  children: [
                    Icon(achievementIconForKey(next.iconKey)),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            next.title,
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(
                              AppRadius.small,
                            ),
                            child: LinearProgressIndicator(
                              value: next.progress,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
          const SizedBox(height: AppSpacing.xl),
          Text('Study Insights', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          Column(
            children: [
              for (final String insight in analytics.insights)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: InsightCard(text: insight),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}
