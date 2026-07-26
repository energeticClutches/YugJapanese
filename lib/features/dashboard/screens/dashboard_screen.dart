import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../repositories/content_repository_factory.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/feature_card.dart';
import '../../achievements/models/achievement.dart';
import '../../achievements/models/achievement_progress.dart';
import '../../achievements/models/streak_info.dart';
import '../../achievements/providers/achievement_providers.dart';
import '../../achievements/services/achievement_service.dart';
import '../../achievements/widgets/achievement_card.dart';
import '../../achievements/widgets/achievement_icons.dart';
import '../../achievements/widgets/streak_card.dart';
import '../../analytics/models/daily_learning_stat.dart';
import '../../analytics/models/learning_analytics.dart';
import '../../analytics/providers/analytics_providers.dart';
import '../../progress/models/lesson_progress.dart';
import '../../progress/providers/progress_providers.dart';
import '../../progress/repositories/progress_repository.dart';
import '../../quiz/models/practice_result.dart';
import '../../quiz/models/practice_statistics.dart';
import '../../quiz/providers/practice_providers.dart';
import '../../quiz/services/practice_generator.dart';
import '../../quiz/widgets/session_summary_card.dart';
import '../../review/models/review_item.dart';
import '../../review/providers/review_providers.dart';
import '../../review/widgets/review_summary_card.dart';
import '../models/content_source.dart';
import '../models/learning_statistics.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/continue_learning_card.dart';
import '../widgets/progress_summary_card.dart';
import '../widgets/script_card.dart';
import '../widgets/statistic_card.dart';

class _WeeklyPracticeSummary {
  const _WeeklyPracticeSummary({
    required this.sessionCount,
    required this.averageAccuracy,
  });

  final int sessionCount;
  final double averageAccuracy;
}

_WeeklyPracticeSummary _resolveWeeklyPracticeSummary(
  List<PracticeResult> results,
) {
  final DateTime weekAgo = DateTime.now().subtract(const Duration(days: 7));
  final List<PracticeResult> recent = results
      .where((PracticeResult result) => result.endTime.isAfter(weekAgo))
      .toList();
  if (recent.isEmpty) {
    return const _WeeklyPracticeSummary(sessionCount: 0, averageAccuracy: 0);
  }
  final double totalAccuracy = recent.fold(
    0.0,
    (double sum, PracticeResult result) => sum + result.accuracy,
  );
  return _WeeklyPracticeSummary(
    sessionCount: recent.length,
    averageAccuracy: totalAccuracy / recent.length,
  );
}

String _practiceSummaryTitle(List<PracticeResult>? results) {
  if (results == null || results.isEmpty) {
    return "Try a quiz mode to reinforce what you've learned.";
  }
  final PracticeResult mostRecent = results.reduce(
    (PracticeResult a, PracticeResult b) =>
        a.endTime.isAfter(b.endTime) ? a : b,
  );
  return PracticeGenerator.modeById(mostRecent.modeId)?.title ??
      mostRecent.modeId;
}

double _averageScriptAccuracy(LearningAnalytics analytics) {
  if (analytics.scriptBreakdown.isEmpty) {
    return 0;
  }
  final double total = analytics.scriptBreakdown.fold(
    0.0,
    (double sum, script) => sum + script.averageWritingAccuracy,
  );
  return total / analytics.scriptBreakdown.length;
}

String _resolvePracticeTrend(List<DailyLearningStat> dailyActivity) {
  if (dailyActivity.length < 14) {
    return 'No data yet';
  }
  final List<DailyLearningStat> last7 = dailyActivity.sublist(dailyActivity.length - 7);
  final List<DailyLearningStat> prev7 = dailyActivity.sublist(
    dailyActivity.length - 14,
    dailyActivity.length - 7,
  );
  final List<double> lastValues = last7
      .map((DailyLearningStat d) => d.averageQuizAccuracy)
      .whereType<double>()
      .toList();
  final List<double> prevValues = prev7
      .map((DailyLearningStat d) => d.averageQuizAccuracy)
      .whereType<double>()
      .toList();
  if (lastValues.isEmpty || prevValues.isEmpty) {
    return 'No data yet';
  }
  final double lastAvg = lastValues.reduce((a, b) => a + b) / lastValues.length;
  final double prevAvg = prevValues.reduce((a, b) => a + b) / prevValues.length;
  final double delta = lastAvg - prevAvg;
  if (delta > 1) {
    return 'Improving';
  }
  if (delta < -1) {
    return 'Declining';
  }
  return 'Steady';
}

const Map<String, String> _scriptTitles = <String, String>{
  'hiragana': 'Hiragana',
  'katakana': 'Katakana',
  'kanji': 'Kanji',
};

const Map<String, IconData> _scriptIcons = <String, IconData>{
  'hiragana': Icons.font_download_outlined,
  'katakana': Icons.text_fields_outlined,
  'kanji': Icons.auto_stories_outlined,
};

class _ScriptSummary {
  const _ScriptSummary({
    required this.completionPercentage,
    required this.reviewCount,
  });

  final int completionPercentage;
  final int reviewCount;
}

Future<_ScriptSummary> _resolveScriptSummary(
  ContentSource source,
  ProgressRepository progressRepository,
  List<ReviewItem> dueReviews,
) async {
  final int totalLessons = (await source.repository.getAllLessons()).length;
  final List<LessonProgress> progressItems =
      await progressRepository.getProgressForContent(source.contentId);
  final int completedLessons =
      progressItems.where((LessonProgress p) => p.isCompleted).length;
  final int completionPercentage = totalLessons == 0
      ? 0
      : ((completedLessons / totalLessons) * 100).round();
  final int reviewCount = dueReviews
      .where(
        (ReviewItem item) => item.lessonId.startsWith('${source.contentId}:'),
      )
      .length;
  return _ScriptSummary(
    completionPercentage: completionPercentage,
    reviewCount: reviewCount,
  );
}

Achievement? _mostRecentlyUnlocked(List<AchievementProgress> progress) {
  final List<AchievementProgress> unlocked = progress
      .where((AchievementProgress p) => p.isUnlocked && p.unlockedAt != null)
      .toList()
    ..sort(
      (AchievementProgress a, AchievementProgress b) =>
          b.unlockedAt!.compareTo(a.unlockedAt!),
    );
  if (unlocked.isEmpty) {
    return null;
  }
  final String mostRecentId = unlocked.first.achievementId;
  for (final Achievement achievement in AchievementService.catalog) {
    if (achievement.id == mostRecentId) {
      return achievement;
    }
  }
  return null;
}

class _ContinueLessonInfo {
  const _ContinueLessonInfo({
    required this.contentId,
    required this.lessonNumber,
    required this.displayTitle,
  });

  final String contentId;
  final int lessonNumber;
  final String displayTitle;
}

Future<_ContinueLessonInfo?> _resolveContinueLesson(String? lastLessonId) async {
  if (lastLessonId == null) {
    return null;
  }

  final List<String> parts = lastLessonId.split(':');
  if (parts.length != 2) {
    return null;
  }

  final String contentId = parts[0];
  final int? lessonNumber = int.tryParse(parts[1]);
  if (lessonNumber == null) {
    return null;
  }

  final repository = ContentRepositoryFactory.tryRepositoryFor(contentId);
  if (repository == null) {
    return null;
  }

  final lesson = await repository.getLesson(lessonNumber);
  if (lesson == null || lesson.characters.isEmpty) {
    return null;
  }
  return _ContinueLessonInfo(
    contentId: contentId,
    lessonNumber: lessonNumber,
    displayTitle: 'Lesson ${lesson.characters.first.character}',
  );
}

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<LearningStatistics> statisticsAsync =
        ref.watch(learningStatisticsProvider);
    final AsyncValue<List<ReviewItem>> dueReviewsAsync =
        ref.watch(dueReviewsProvider);
    final AsyncValue<StreakInfo> streakAsync = ref.watch(streakInfoProvider);
    final AsyncValue<List<AchievementProgress>> achievementsAsync =
        ref.watch(achievementProgressListProvider);
    final List<ContentSource> contentSources =
        ref.watch(contentSourcesProvider);
    final ProgressRepository progressRepository =
        ref.watch(progressRepositoryProvider);
    final AsyncValue<PracticeStatistics> practiceStatisticsAsync =
        ref.watch(practiceStatisticsProvider);
    final AsyncValue<List<PracticeResult>> practiceResultsAsync =
        ref.watch(practiceResultsProvider);
    final AsyncValue<LearningAnalytics> analyticsAsync =
        ref.watch(learningAnalyticsProvider);

    return AppScaffold(
      child: statisticsAsync.when(
        data: (LearningStatistics statistics) => _DashboardContent(
          statistics: statistics,
          dueReviewsAsync: dueReviewsAsync,
          streakAsync: streakAsync,
          achievementsAsync: achievementsAsync,
          contentSources: contentSources,
          progressRepository: progressRepository,
          practiceStatisticsAsync: practiceStatisticsAsync,
          practiceResultsAsync: practiceResultsAsync,
          analyticsAsync: analyticsAsync,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace stackTrace) => _DashboardContent(
          statistics: LearningStatistics.empty,
          dueReviewsAsync: dueReviewsAsync,
          streakAsync: streakAsync,
          achievementsAsync: achievementsAsync,
          contentSources: contentSources,
          progressRepository: progressRepository,
          practiceStatisticsAsync: practiceStatisticsAsync,
          practiceResultsAsync: practiceResultsAsync,
          analyticsAsync: analyticsAsync,
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.statistics,
    required this.dueReviewsAsync,
    required this.streakAsync,
    required this.achievementsAsync,
    required this.contentSources,
    required this.progressRepository,
    required this.practiceStatisticsAsync,
    required this.practiceResultsAsync,
    required this.analyticsAsync,
  });

  final LearningStatistics statistics;
  final AsyncValue<List<ReviewItem>> dueReviewsAsync;
  final AsyncValue<StreakInfo> streakAsync;
  final AsyncValue<List<AchievementProgress>> achievementsAsync;
  final List<ContentSource> contentSources;
  final ProgressRepository progressRepository;
  final AsyncValue<PracticeStatistics> practiceStatisticsAsync;
  final AsyncValue<List<PracticeResult>> practiceResultsAsync;
  final AsyncValue<LearningAnalytics> analyticsAsync;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.md),
          Text(
            'Welcome Back!',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Continue your Japanese journey.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xl),
          FeatureCard(
            icon: Icons.search,
            title: 'Quick Search',
            subtitle: 'Find any Hiragana, Katakana, or Kanji character',
            onTap: () => context.go('/search'),
          ),
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: ProgressSummaryCard(
              percentage: statistics.completionPercentage,
              label: 'Overall Progress',
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Learning Statistics',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              StatisticCard(
                icon: Icons.check_circle_outline,
                label: 'Lessons Completed',
                value: '${statistics.completedLessons}',
              ),
              StatisticCard(
                icon: Icons.pending_outlined,
                label: 'Lessons Remaining',
                value: '${statistics.lessonsRemaining}',
              ),
              StatisticCard(
                icon: Icons.gps_fixed,
                label: 'Average Accuracy',
                value: '${statistics.averageAccuracy.round()}%',
              ),
              StatisticCard(
                icon: Icons.hourglass_top_outlined,
                label: 'Lessons In Progress',
                value: '${statistics.lessonsInProgress}',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          FutureBuilder<_ContinueLessonInfo?>(
            future: _resolveContinueLesson(statistics.lastLessonId),
            builder: (context, snapshot) {
              final _ContinueLessonInfo? info = snapshot.data;
              if (info == null) {
                return ContinueLearningCard(
                  label: 'Get Started',
                  title: 'Begin your first lesson',
                  buttonLabel: 'Start Learning',
                  onPressed: () => context.go('/hiragana'),
                );
              }
              return ContinueLearningCard(
                label: 'Continue',
                title: info.displayTitle,
                buttonLabel: 'Continue',
                onPressed: () => context.go(
                  '/practice/${info.lessonNumber}?content=${info.contentId}',
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            "Today's Reviews",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          ReviewSummaryCard(
            dueCount: dueReviewsAsync.asData?.value.length ?? 0,
            onTap: () => context.go('/review'),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Achievements',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          Builder(
            builder: (context) {
              final StreakInfo streak = streakAsync.asData?.value ?? StreakInfo.empty;
              return StreakCard(
                currentStreak: streak.currentStreak,
                longestStreak: streak.longestStreak,
                onTap: () => context.go('/achievements'),
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          Builder(
            builder: (context) {
              final List<AchievementProgress> achievements =
                  achievementsAsync.asData?.value ?? <AchievementProgress>[];
              final Achievement? recent = _mostRecentlyUnlocked(achievements);
              if (recent == null) {
                return Text(
                  'Complete lessons to earn your first achievement.',
                  style: Theme.of(context).textTheme.bodyMedium,
                );
              }
              return AchievementCard(
                title: recent.title,
                description: recent.description,
                icon: achievementIconForKey(recent.iconKey),
                isUnlocked: true,
              );
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Practice',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          Builder(
            builder: (context) {
              final List<PracticeResult> results =
                  practiceResultsAsync.asData?.value ?? const <PracticeResult>[];
              return SessionSummaryCard(
                label: results.isEmpty ? 'Get Started' : 'Continue',
                title: _practiceSummaryTitle(results),
                buttonLabel:
                    results.isEmpty ? 'Start Practice' : 'Continue Last Practice',
                onPressed: () => context.go('/quiz'),
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          Builder(
            builder: (context) {
              final PracticeStatistics practiceStatistics =
                  practiceStatisticsAsync.asData?.value ?? PracticeStatistics.empty;
              final _WeeklyPracticeSummary weekly = _resolveWeeklyPracticeSummary(
                practiceResultsAsync.asData?.value ?? const <PracticeResult>[],
              );
              return Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: [
                  StatisticCard(
                    icon: Icons.quiz_outlined,
                    label: 'Sessions This Week',
                    value: '${weekly.sessionCount}',
                  ),
                  StatisticCard(
                    icon: Icons.percent,
                    label: 'Weekly Accuracy',
                    value: weekly.sessionCount == 0
                        ? '--'
                        : '${weekly.averageAccuracy.round()}%',
                  ),
                  StatisticCard(
                    icon: Icons.emoji_events_outlined,
                    label: 'Best Quiz Score',
                    value: practiceStatistics.totalSessions == 0
                        ? '--'
                        : '${practiceStatistics.bestScore.round()}%',
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          FeatureCard(
            icon: Icons.insights_outlined,
            title: 'View Analytics',
            subtitle: 'See trends, weak areas, and study insights',
            onTap: () => context.go('/analytics'),
          ),
          const SizedBox(height: AppSpacing.md),
          Builder(
            builder: (context) {
              final LearningAnalytics analytics =
                  analyticsAsync.asData?.value ?? LearningAnalytics.empty;
              final int weeklyActivity = analytics.dailyActivity
                  .where((DailyLearningStat d) => d.hasActivity)
                  .fold<int>(0, (int sum, DailyLearningStat d) => sum + d.activityCount);
              return Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: [
                  StatisticCard(
                    icon: Icons.event_available_outlined,
                    label: 'Weekly Activity',
                    value: '$weeklyActivity',
                  ),
                  StatisticCard(
                    icon: Icons.gps_fixed,
                    label: 'Average Accuracy',
                    value: analytics.totalLessonsCompleted == 0
                        ? '--'
                        : '${_averageScriptAccuracy(analytics).round()}%',
                  ),
                  StatisticCard(
                    icon: Icons.trending_up,
                    label: 'Practice Trend',
                    value: _resolvePracticeTrend(analytics.dailyActivity),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Scripts',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              for (final ContentSource source in contentSources)
                FutureBuilder<_ScriptSummary>(
                  future: _resolveScriptSummary(
                    source,
                    progressRepository,
                    dueReviewsAsync.asData?.value ?? const <ReviewItem>[],
                  ),
                  builder: (context, snapshot) {
                    final _ScriptSummary? summary = snapshot.data;
                    return ScriptCard(
                      icon: _scriptIcons[source.contentId] ??
                          Icons.translate_outlined,
                      title: _scriptTitles[source.contentId] ??
                          source.contentId,
                      subtitle: summary == null
                          ? 'Loading...'
                          : '${summary.completionPercentage}% complete · ${summary.reviewCount} due',
                      enabled: true,
                      onTap: () => context.go('/${source.contentId}'),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}
