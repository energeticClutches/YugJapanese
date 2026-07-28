import '../../../repositories/content_repository_factory.dart';
import '../../../repositories/lesson_repository.dart';
import '../../achievements/models/achievement.dart';
import '../../achievements/models/achievement_progress.dart';
import '../../achievements/models/streak_info.dart';
import '../../achievements/repositories/achievement_repository.dart';
import '../../achievements/services/achievement_service.dart';
import '../../dashboard/models/content_source.dart';
import '../../progress/models/lesson_progress.dart';
import '../../progress/repositories/progress_repository.dart';
import '../../quiz/models/practice_result.dart';
import '../../quiz/models/practice_statistics.dart';
import '../../quiz/repositories/practice_repository.dart';
import '../../quiz/services/practice_generator.dart';
import '../../quiz/services/practice_statistics_service.dart';
import '../../review/models/review_item.dart';
import '../../review/repositories/review_repository.dart';
import '../models/analytics_snapshot.dart';
import '../models/daily_learning_stat.dart';
import '../models/learning_analytics.dart';
import '../models/script_analytics.dart';
import '../models/weak_area.dart';
import '../repositories/analytics_repository.dart';

class _ResolvedItem {
  const _ResolvedItem(this.contentId, this.symbol);
  final String contentId;
  final String symbol;
}

/// Aggregates existing progress/review/practice/achievement data into
/// [LearningAnalytics]. Reads only — never writes to any source repository,
/// and persists nothing except a scalar [AnalyticsSnapshot] cache of its own
/// output. Recomputes fresh on every call, matching every other *Service in
/// this app (`StatisticsService`, `AchievementService`,
/// `PracticeStatisticsService`) — there is no caching precedent to break,
/// and this app's data volume is small enough that this is free.
class AnalyticsService {
  const AnalyticsService({
    required ProgressRepository progressRepository,
    required ReviewRepository reviewRepository,
    required PracticeRepository practiceRepository,
    required PracticeStatisticsService practiceStatisticsService,
    required AchievementService achievementService,
    required AchievementRepository achievementRepository,
    required AnalyticsRepository analyticsRepository,
  }) : _progressRepository = progressRepository,
       _reviewRepository = reviewRepository,
       _practiceRepository = practiceRepository,
       _practiceStatisticsService = practiceStatisticsService,
       _achievementService = achievementService,
       _achievementRepository = achievementRepository,
       _analyticsRepository = analyticsRepository;

  final ProgressRepository _progressRepository;
  final ReviewRepository _reviewRepository;
  final PracticeRepository _practiceRepository;
  final PracticeStatisticsService _practiceStatisticsService;
  final AchievementService _achievementService;
  final AchievementRepository _achievementRepository;
  final AnalyticsRepository _analyticsRepository;

  static const int _activityWindowDays = 30;
  static const double _lowAccuracyThreshold = 70;
  static const double _estimatedMinutesPerLesson = 3;
  static const double _estimatedMinutesPerReview = 1;
  static const int _weakAreasPerType = 5;
  static const int _maxInsights = 5;
  static const int _maxNextAchievements = 3;

  Future<LearningAnalytics> getAnalytics(List<ContentSource> sources) async {
    final DateTime now = DateTime.now();

    final List<ReviewItem> allReviews = await _reviewRepository.getAllReviews();
    final int totalReviews = allReviews.fold(
      0,
      (int sum, ReviewItem item) => sum + item.reviewCount,
    );
    final List<ReviewItem> dueReviews = allReviews
        .where((ReviewItem item) => item.isDue(now))
        .toList();

    final List<PracticeResult> allResults = await _practiceRepository
        .getAllResults();
    final PracticeStatistics practiceStats = await _practiceStatisticsService
        .getStatistics();
    final StreakInfo streak = await _achievementService.calculateStreak(
      sources,
      now: now,
    );

    final List<ScriptAnalytics> scriptBreakdown = <ScriptAnalytics>[];
    final Map<String, List<LessonProgress>> progressByContent =
        <String, List<LessonProgress>>{};
    final Map<String, DateTime?> lastReviewedByScript = <String, DateTime?>{};
    int totalLessons = 0;
    int totalLessonsCompleted = 0;
    final List<double> allAccuracies = <double>[];

    for (final ContentSource source in sources) {
      final int lessonCount = (await source.repository.getAllLessons()).length;
      final List<LessonProgress> items = await _progressRepository
          .getProgressForContent(source.contentId);
      progressByContent[source.contentId] = items;
      totalLessons += lessonCount;

      final List<double> scriptAccuracies = <double>[];
      int completedForScript = 0;
      for (final LessonProgress item in items) {
        if (item.isCompleted) {
          completedForScript++;
          totalLessonsCompleted++;
          allAccuracies.add(item.bestWritingAccuracy);
          scriptAccuracies.add(item.bestWritingAccuracy);
        }
      }

      final int reviewsDueForScript = dueReviews
          .where(
            (ReviewItem item) =>
                item.lessonId.startsWith('${source.contentId}:'),
          )
          .length;
      final List<PracticeResult> sessionsForScript = allResults
          .where(
            (PracticeResult result) =>
                result.contentIds.contains(source.contentId),
          )
          .toList();

      scriptBreakdown.add(
        ScriptAnalytics(
          contentId: source.contentId,
          completionPercentage: lessonCount == 0
              ? 0
              : (completedForScript / lessonCount) * 100,
          averageWritingAccuracy: _average(scriptAccuracies),
          averageQuizAccuracy: _average(
            sessionsForScript.map((PracticeResult r) => r.accuracy).toList(),
          ),
          reviewsDue: reviewsDueForScript,
          practiceSessions: sessionsForScript.length,
        ),
      );

      DateTime? latestReview;
      for (final ReviewItem review in allReviews) {
        if (!review.lessonId.startsWith('${source.contentId}:') ||
            review.lastReviewed == null) {
          continue;
        }
        if (latestReview == null ||
            review.lastReviewed!.isAfter(latestReview)) {
          latestReview = review.lastReviewed;
        }
      }
      lastReviewedByScript[source.contentId] = latestReview;
    }

    final double completionPercentage = totalLessons == 0
        ? 0
        : (totalLessonsCompleted / totalLessons) * 100;
    final double overallWritingAccuracy = _average(allAccuracies);

    final List<DailyLearningStat> dailyActivity = _buildDailyActivity(
      progressByContent: progressByContent,
      allReviews: allReviews,
      allResults: allResults,
      now: now,
    );

    final List<WeakArea> weakAreas = await _buildWeakAreas(
      progressByContent: progressByContent,
      dueReviews: dueReviews,
      allResults: allResults,
      sources: sources,
      now: now,
    );

    final List<AchievementProgress> achievementProgress =
        await _achievementRepository.getAllProgress();
    final Set<String> unlockedIds = achievementProgress
        .where((AchievementProgress p) => p.isUnlocked)
        .map((AchievementProgress p) => p.achievementId)
        .toSet();

    final List<NextAchievement> nextAchievements = _buildNextAchievements(
      unlockedIds: unlockedIds,
      totalLessonsCompleted: totalLessonsCompleted,
      longestStreakDays: streak.longestStreak,
      totalReviews: totalReviews,
      overallWritingAccuracy: overallWritingAccuracy,
      practiceStats: practiceStats,
    );

    final List<String> insights = _buildInsights(
      dailyActivity: dailyActivity,
      practiceStats: practiceStats,
      lastReviewedByScript: lastReviewedByScript,
      currentStreakDays: streak.currentStreak,
      now: now,
    );

    final double practiceMinutes = allResults.fold(
      0.0,
      (double sum, PracticeResult r) => sum + r.duration.inSeconds / 60,
    );
    final int estimatedStudyMinutes =
        (practiceMinutes +
                totalLessonsCompleted * _estimatedMinutesPerLesson +
                totalReviews * _estimatedMinutesPerReview)
            .round();

    final LearningAnalytics analytics = LearningAnalytics(
      totalLessonsCompleted: totalLessonsCompleted,
      completionPercentage: completionPercentage,
      totalPracticeSessions: practiceStats.totalSessions,
      totalReviews: totalReviews,
      estimatedStudyMinutes: estimatedStudyMinutes,
      currentStreakDays: streak.currentStreak,
      longestStreakDays: streak.longestStreak,
      scriptBreakdown: scriptBreakdown,
      dailyActivity: dailyActivity,
      weakAreas: weakAreas,
      insights: insights,
      achievementsUnlocked: unlockedIds.length,
      achievementsTotal: AchievementService.catalog.length,
      nextAchievements: nextAchievements,
      computedAt: now,
    );

    await _analyticsRepository.saveSnapshot(
      AnalyticsSnapshot(
        totalLessonsCompleted: totalLessonsCompleted,
        completionPercentage: completionPercentage,
        totalPracticeSessions: practiceStats.totalSessions,
        totalReviews: totalReviews,
        estimatedStudyMinutes: estimatedStudyMinutes,
        currentStreakDays: streak.currentStreak,
        longestStreakDays: streak.longestStreak,
        computedAt: now,
      ),
    );

    return analytics;
  }

  List<DailyLearningStat> _buildDailyActivity({
    required Map<String, List<LessonProgress>> progressByContent,
    required List<ReviewItem> allReviews,
    required List<PracticeResult> allResults,
    required DateTime now,
  }) {
    final DateTime today = _dateOnly(now);
    final List<DateTime> days = List<DateTime>.generate(
      _activityWindowDays,
      (int i) => today.subtract(Duration(days: _activityWindowDays - 1 - i)),
    );

    final Map<DateTime, int> lessonsByDate = <DateTime, int>{};
    final Map<DateTime, List<double>> writingAccByDate =
        <DateTime, List<double>>{};
    for (final List<LessonProgress> items in progressByContent.values) {
      for (final LessonProgress item in items) {
        final DateTime? completedAt = item.completedAt;
        if (item.isCompleted && completedAt != null) {
          final DateTime day = _dateOnly(completedAt);
          lessonsByDate[day] = (lessonsByDate[day] ?? 0) + 1;
          writingAccByDate
              .putIfAbsent(day, () => <double>[])
              .add(item.bestWritingAccuracy);
        }
      }
    }

    final Map<DateTime, int> reviewsByDate = <DateTime, int>{};
    for (final ReviewItem review in allReviews) {
      final DateTime? lastReviewed = review.lastReviewed;
      if (lastReviewed == null) {
        continue;
      }
      final DateTime day = _dateOnly(lastReviewed);
      reviewsByDate[day] = (reviewsByDate[day] ?? 0) + 1;
    }

    final Map<DateTime, List<PracticeResult>> resultsByDate =
        <DateTime, List<PracticeResult>>{};
    for (final PracticeResult result in allResults) {
      final DateTime day = _dateOnly(result.endTime);
      resultsByDate.putIfAbsent(day, () => <PracticeResult>[]).add(result);
    }

    return <DailyLearningStat>[
      for (final DateTime day in days)
        DailyLearningStat(
          date: day,
          lessonsCompleted: lessonsByDate[day] ?? 0,
          reviewsCompleted: reviewsByDate[day] ?? 0,
          practiceSessions: resultsByDate[day]?.length ?? 0,
          questionsAnswered:
              resultsByDate[day]?.fold<int>(
                0,
                (int sum, PracticeResult r) => sum + r.totalQuestions,
              ) ??
              0,
          averageWritingAccuracy: _averageOrNull(writingAccByDate[day]),
          averageQuizAccuracy: resultsByDate[day] == null
              ? null
              : _average(
                  resultsByDate[day]!
                      .map((PracticeResult r) => r.accuracy)
                      .toList(),
                ),
          reviewSuccessRate: (reviewsByDate[day] ?? 0) > 0 ? 1.0 : null,
        ),
    ];
  }

  Future<List<WeakArea>> _buildWeakAreas({
    required Map<String, List<LessonProgress>> progressByContent,
    required List<ReviewItem> dueReviews,
    required List<PracticeResult> allResults,
    required List<ContentSource> sources,
    required DateTime now,
  }) async {
    final List<WeakArea> lowAccuracy = <WeakArea>[];
    for (final MapEntry<String, List<LessonProgress>> entry
        in progressByContent.entries) {
      final String contentId = entry.key;
      final repository = ContentRepositoryFactory.tryRepositoryFor(contentId);
      for (final LessonProgress item in entry.value) {
        if (item.isCompleted &&
            item.bestWritingAccuracy < _lowAccuracyThreshold) {
          final label = await _lessonLabel(
            repository,
            contentId,
            item.lessonNumber,
          );
          lowAccuracy.add(
            WeakArea(
              type: WeakAreaType.lowWritingAccuracy,
              contentId: contentId,
              itemId: '$contentId:${item.lessonNumber}',
              label: label,
              description:
                  'Writing accuracy: ${item.bestWritingAccuracy.round()}%',
              severity: 100 - item.bestWritingAccuracy,
            ),
          );
        }
      }
    }
    lowAccuracy.sort(
      (WeakArea a, WeakArea b) => b.severity.compareTo(a.severity),
    );

    final Map<String, int> missCounts = <String, int>{};
    for (final PracticeResult result in allResults) {
      for (final String itemId in result.incorrectItemIds) {
        missCounts[itemId] = (missCounts[itemId] ?? 0) + 1;
      }
    }
    final List<WeakArea> missedItems = <WeakArea>[];
    for (final MapEntry<String, int> entry in missCounts.entries) {
      final _ResolvedItem? resolved = await _resolveItem(entry.key, sources);
      if (resolved == null) {
        continue;
      }
      missedItems.add(
        WeakArea(
          type: WeakAreaType.missedQuizItem,
          contentId: resolved.contentId,
          itemId: entry.key,
          label: resolved.symbol,
          description:
              'Missed ${entry.value} time${entry.value == 1 ? '' : 's'} in quizzes',
          severity: entry.value.toDouble(),
        ),
      );
    }
    missedItems.sort(
      (WeakArea a, WeakArea b) => b.severity.compareTo(a.severity),
    );

    final List<WeakArea> overdue = <WeakArea>[];
    for (final ReviewItem review in dueReviews) {
      final List<String> parts = review.lessonId.split(':');
      if (parts.length != 2) {
        continue;
      }
      final String contentId = parts[0];
      final int? lessonNumber = int.tryParse(parts[1]);
      if (lessonNumber == null) {
        continue;
      }
      final repository = ContentRepositoryFactory.tryRepositoryFor(contentId);
      final label = await _lessonLabel(repository, contentId, lessonNumber);
      final int daysOverdue = _dateOnly(
        now,
      ).difference(_dateOnly(review.nextReview)).inDays;
      overdue.add(
        WeakArea(
          type: WeakAreaType.overdueReview,
          contentId: contentId,
          itemId: review.lessonId,
          label: label,
          description: daysOverdue <= 0
              ? 'Due for review'
              : 'Overdue by $daysOverdue day${daysOverdue == 1 ? '' : 's'}',
          severity: daysOverdue.toDouble(),
        ),
      );
    }
    overdue.sort((WeakArea a, WeakArea b) => b.severity.compareTo(a.severity));

    return <WeakArea>[
      ...lowAccuracy.take(_weakAreasPerType),
      ...missedItems.take(_weakAreasPerType),
      ...overdue.take(_weakAreasPerType),
    ];
  }

  Future<String> _lessonLabel(
    LessonRepository? repository,
    String contentId,
    int lessonNumber,
  ) async {
    if (repository == null) {
      return '$contentId lesson $lessonNumber';
    }
    final lesson = await repository.getLesson(lessonNumber);
    if (lesson == null || lesson.characters.isEmpty) {
      return '$contentId lesson $lessonNumber';
    }
    return 'Lesson ${lesson.characters.first.character}';
  }

  Future<_ResolvedItem?> _resolveItem(
    String itemId,
    List<ContentSource> sources,
  ) async {
    for (final ContentSource source in sources) {
      final item = await source.repository.getItem(itemId);
      if (item != null) {
        return _ResolvedItem(source.contentId, item.symbol);
      }
    }
    return null;
  }

  List<NextAchievement> _buildNextAchievements({
    required Set<String> unlockedIds,
    required int totalLessonsCompleted,
    required int longestStreakDays,
    required int totalReviews,
    required double overallWritingAccuracy,
    required PracticeStatistics practiceStats,
  }) {
    final List<NextAchievement> next = <NextAchievement>[];
    for (final Achievement achievement in AchievementService.catalog) {
      if (unlockedIds.contains(achievement.id)) {
        continue;
      }
      final double currentValue = _currentValueFor(
        achievement.criteria,
        totalLessonsCompleted: totalLessonsCompleted,
        longestStreakDays: longestStreakDays,
        totalReviews: totalReviews,
        overallWritingAccuracy: overallWritingAccuracy,
        practiceStats: practiceStats,
      );
      final double progress = (currentValue / achievement.threshold).clamp(
        0,
        1,
      );
      next.add(
        NextAchievement(
          achievementId: achievement.id,
          title: achievement.title,
          description: achievement.description,
          iconKey: achievement.iconKey,
          progress: progress,
        ),
      );
    }
    next.sort(
      (NextAchievement a, NextAchievement b) =>
          b.progress.compareTo(a.progress),
    );
    return next.take(_maxNextAchievements).toList();
  }

  /// Mirrors `AchievementService._meetsCriteria`'s switch shape (same
  /// tolerance for small duplication established by
  /// `PracticeStatisticsService`'s streak calc in M17) — returns the
  /// current numeric value for a criteria instead of a threshold
  /// comparison, so progress-toward-unlock can be shown here.
  double _currentValueFor(
    AchievementCriteria criteria, {
    required int totalLessonsCompleted,
    required int longestStreakDays,
    required int totalReviews,
    required double overallWritingAccuracy,
    required PracticeStatistics practiceStats,
  }) {
    switch (criteria) {
      case AchievementCriteria.lessonsCompleted:
        return totalLessonsCompleted.toDouble();
      case AchievementCriteria.longestStreakDays:
        return longestStreakDays.toDouble();
      case AchievementCriteria.reviewsCompleted:
        return totalReviews.toDouble();
      case AchievementCriteria.averageAccuracy:
        return overallWritingAccuracy;
      case AchievementCriteria.practiceSessionsCompleted:
        return practiceStats.totalSessions.toDouble();
      case AchievementCriteria.practiceQuestionsAnswered:
        return practiceStats.totalQuestionsAnswered.toDouble();
      case AchievementCriteria.perfectPracticeSessions:
        return practiceStats.perfectSessionCount.toDouble();
      case AchievementCriteria.practiceStreakDays:
        return practiceStats.longestStreakDays.toDouble();
    }
  }

  List<String> _buildInsights({
    required List<DailyLearningStat> dailyActivity,
    required PracticeStatistics practiceStats,
    required Map<String, DateTime?> lastReviewedByScript,
    required int currentStreakDays,
    required DateTime now,
  }) {
    final List<String> insights = <String>[];

    if (currentStreakDays >= 2) {
      insights.add("You're on a $currentStreakDays-day streak! Keep it going.");
    }

    if (dailyActivity.length >= 14) {
      final List<DailyLearningStat> last7 = dailyActivity.sublist(
        dailyActivity.length - 7,
      );
      final List<DailyLearningStat> prev7 = dailyActivity.sublist(
        dailyActivity.length - 14,
        dailyActivity.length - 7,
      );
      final double? lastAvg = _averageOrNull(
        last7
            .map((DailyLearningStat d) => d.averageWritingAccuracy)
            .whereType<double>()
            .toList(),
      );
      final double? prevAvg = _averageOrNull(
        prev7
            .map((DailyLearningStat d) => d.averageWritingAccuracy)
            .whereType<double>()
            .toList(),
      );
      if (lastAvg != null && prevAvg != null) {
        final double delta = lastAvg - prevAvg;
        if (delta.abs() >= 1) {
          insights.add(
            'Writing accuracy ${delta > 0 ? 'improved' : 'dropped'} by '
            '${delta.abs().round()}% this week.',
          );
        }
      }
    }

    if (practiceStats.accuracyByMode.isNotEmpty) {
      final List<MapEntry<String, double>> sortedModes =
          practiceStats.accuracyByMode.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
      final MapEntry<String, double> strongest = sortedModes.first;
      insights.add(
        '${_modeTitle(strongest.key)} is your strongest practice mode '
        '(${strongest.value.round()}% accuracy).',
      );
      if (sortedModes.length > 1 && sortedModes.last.key != strongest.key) {
        final MapEntry<String, double> weakest = sortedModes.last;
        insights.add(
          '${_modeTitle(weakest.key)} could use more practice '
          '(${weakest.value.round()}% accuracy).',
        );
      }
    }

    lastReviewedByScript.forEach((String contentId, DateTime? lastReviewed) {
      if (lastReviewed == null) {
        return;
      }
      final int days = _dateOnly(
        now,
      ).difference(_dateOnly(lastReviewed)).inDays;
      if (days >= 3) {
        insights.add(
          "You haven't reviewed ${_scriptLabel(contentId)} in $days days.",
        );
      }
    });

    if (insights.isEmpty) {
      return const <String>[
        'Complete a lesson or practice session to start seeing insights.',
      ];
    }
    return insights.take(_maxInsights).toList();
  }

  String _modeTitle(String modeId) =>
      PracticeGenerator.modeById(modeId)?.title ?? modeId;

  String _scriptLabel(String contentId) {
    if (contentId.isEmpty) {
      return contentId;
    }
    return contentId[0].toUpperCase() + contentId.substring(1);
  }

  double _average(List<double> values) => _averageOrNull(values) ?? 0;

  double? _averageOrNull(List<double>? values) {
    if (values == null || values.isEmpty) {
      return null;
    }
    return values.reduce((double a, double b) => a + b) / values.length;
  }

  DateTime _dateOnly(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }
}
