import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/equal_width_grid.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../achievements/models/streak_info.dart';
import '../../achievements/providers/achievement_providers.dart';
import '../../achievements/widgets/achievement_icons.dart';
import '../models/learning_analytics.dart';
import '../models/script_analytics.dart';
import '../models/weak_area.dart';
import '../providers/analytics_providers.dart';
import '../widgets/insight_card.dart';
import '../widgets/learning_streak_card.dart';
import '../widgets/progress_ring.dart';
import '../widgets/script_summary_card.dart';
import '../widgets/statistic_card.dart';
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
    final StreakInfo streak =
        ref.watch(streakInfoProvider).asData?.value ?? StreakInfo.empty;

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
            _AnalyticsContent(analytics: analytics, streak: streak),
        loading: () => const LoadingIndicator(),
        error: (Object error, StackTrace stackTrace) => _AnalyticsContent(
          analytics: LearningAnalytics.empty,
          streak: streak,
        ),
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
  const _AnalyticsContent({required this.analytics, required this.streak});

  final LearningAnalytics analytics;
  final StreakInfo streak;

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
          // A bare `Wrap` sized each card to its own label width, so the
          // tiles never lined up into columns — the exact problem
          // `EqualWidthGrid` was written for on the dashboard, which this
          // screen had simply never adopted (Milestone 31, Issue 3). The
          // streak tiles are gone from here: the dedicated streak card
          // below now owns those numbers, so keeping them would state the
          // same fact twice.
          EqualWidthGrid(
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
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Learning Streak',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          LearningStreakCard(
            currentStreak: streak.currentStreak,
            longestStreak: streak.longestStreak,
            lastActiveDate: streak.lastActiveDate,
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Script Breakdown',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          // Full-width, one per row: at `SizedBox(width: 280)` these sat in
          // a single left-aligned column with dead space beside them on a
          // phone, and would have overflowed a screen narrower than 280dp
          // plus padding (Milestone 31, Issue 3).
          for (final ScriptAnalytics script in analytics.scriptBreakdown) ...[
            ScriptSummaryCard(
              title: _scriptTitle(script.contentId),
              analytics: script,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          const SizedBox(height: AppSpacing.lg),
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
          // Was a bare `StatisticCard`, which sizes to its own content and
          // so sat as one narrow tile stranded against the left edge.
          SizedBox(
            width: double.infinity,
            child: StatisticCard(
              icon: Icons.emoji_events_outlined,
              label: 'Unlocked',
              value:
                  '${analytics.achievementsUnlocked} / ${analytics.achievementsTotal}',
            ),
          ),
          if (analytics.nextAchievements.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Text('Next up', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            for (final next in analytics.nextAchievements)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
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
                          const SizedBox(height: AppSpacing.sm),
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
