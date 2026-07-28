import '../../dashboard/models/content_source.dart';
import '../../dashboard/models/learning_statistics.dart';
import '../../dashboard/services/statistics_service.dart';
import '../../progress/models/lesson_progress.dart';
import '../../progress/repositories/progress_repository.dart';
import '../../quiz/models/practice_result.dart';
import '../../quiz/models/practice_statistics.dart';
import '../../quiz/repositories/practice_repository.dart';
import '../../quiz/services/practice_statistics_service.dart';
import '../../review/models/review_item.dart';
import '../../review/repositories/review_repository.dart';
import '../models/achievement.dart';
import '../models/achievement_progress.dart';
import '../models/streak_info.dart';
import '../repositories/achievement_repository.dart';

/// Calculates streaks and unlocks achievements from data already persisted
/// by the progress, statistics, review, and quiz-practice features. Reads
/// only; never hooks into or modifies the learning flow itself.
class AchievementService {
  const AchievementService({
    required AchievementRepository achievementRepository,
    required ProgressRepository progressRepository,
    required StatisticsService statisticsService,
    required ReviewRepository reviewRepository,
    required PracticeStatisticsService practiceStatisticsService,
    required PracticeRepository practiceRepository,
  }) : _achievementRepository = achievementRepository,
       _progressRepository = progressRepository,
       _statisticsService = statisticsService,
       _reviewRepository = reviewRepository,
       _practiceStatisticsService = practiceStatisticsService,
       _practiceRepository = practiceRepository;

  final AchievementRepository _achievementRepository;
  final ProgressRepository _progressRepository;
  final StatisticsService _statisticsService;
  final ReviewRepository _reviewRepository;
  final PracticeStatisticsService _practiceStatisticsService;

  /// Raw results, for the per-day activity dates [calculateStreak] needs —
  /// [PracticeStatistics] only exposes aggregates.
  final PracticeRepository _practiceRepository;

  static const List<Achievement> catalog = <Achievement>[
    Achievement(
      id: 'first_lesson',
      title: 'First Steps',
      description: 'Complete your first lesson.',
      iconKey: 'flag',
      criteria: AchievementCriteria.lessonsCompleted,
      threshold: 1,
    ),
    Achievement(
      id: 'five_lessons',
      title: 'Building Momentum',
      description: 'Complete 5 lessons.',
      iconKey: 'stars',
      criteria: AchievementCriteria.lessonsCompleted,
      threshold: 5,
    ),
    Achievement(
      id: 'streak_3',
      title: 'Getting Consistent',
      description: 'Reach a 3-day streak.',
      iconKey: 'streak',
      criteria: AchievementCriteria.longestStreakDays,
      threshold: 3,
    ),
    Achievement(
      id: 'streak_7',
      title: 'One Week Strong',
      description: 'Reach a 7-day streak.',
      iconKey: 'streak',
      criteria: AchievementCriteria.longestStreakDays,
      threshold: 7,
    ),
    Achievement(
      id: 'first_review',
      title: 'Reinforced',
      description: 'Complete your first review.',
      iconKey: 'review',
      criteria: AchievementCriteria.reviewsCompleted,
      threshold: 1,
    ),
    Achievement(
      id: 'perfect_accuracy',
      title: 'Precision Writer',
      description: 'Reach 100% average accuracy.',
      iconKey: 'target',
      criteria: AchievementCriteria.averageAccuracy,
      threshold: 100,
    ),
    Achievement(
      id: 'first_practice_session',
      title: 'Quiz Novice',
      description: 'Complete your first practice session.',
      iconKey: 'flag',
      criteria: AchievementCriteria.practiceSessionsCompleted,
      threshold: 1,
    ),
    Achievement(
      id: 'perfect_practice_score',
      title: 'Flawless Round',
      description: 'Score 100% on a practice session.',
      iconKey: 'target',
      criteria: AchievementCriteria.perfectPracticeSessions,
      threshold: 1,
    ),
    Achievement(
      id: 'practice_sessions_10',
      title: 'Dedicated Quizzer',
      description: 'Complete 10 practice sessions.',
      iconKey: 'stars',
      criteria: AchievementCriteria.practiceSessionsCompleted,
      threshold: 10,
    ),
    Achievement(
      id: 'practice_questions_100',
      title: 'Century Club',
      description: 'Answer 100 practice questions.',
      iconKey: 'stars',
      criteria: AchievementCriteria.practiceQuestionsAnswered,
      threshold: 100,
    ),
    Achievement(
      id: 'practice_questions_500',
      title: 'Quiz Master',
      description: 'Answer 500 practice questions.',
      iconKey: 'stars',
      criteria: AchievementCriteria.practiceQuestionsAnswered,
      threshold: 500,
    ),
    Achievement(
      id: 'practice_streak_30',
      title: 'Unstoppable',
      description: 'Reach a 30-day practice streak.',
      iconKey: 'streak',
      criteria: AchievementCriteria.practiceStreakDays,
      threshold: 30,
    ),
  ];

  /// Computes the current and longest daily learning streak.
  ///
  /// A day counts once it contains at least one *completed* learning
  /// activity — a finished lesson (which is also where writing practice is
  /// graded), a finished quiz session, or a finished review. Repeating any
  /// of them on the same day does not extend the streak further, and a day
  /// with none of them breaks it.
  ///
  /// This used to key off [LessonProgress.lastAccessedAt] alone, so merely
  /// opening a lesson counted as a day's learning while a full quiz or
  /// review session counted for nothing (Milestone 31, Issue 6). Every
  /// source read here is already persisted locally by its own feature, so
  /// the streak survives restarts and stays offline-first without a
  /// parallel record that could drift out of sync with the real activity.
  Future<StreakInfo> calculateStreak(
    List<ContentSource> sources, {
    DateTime? now,
  }) async {
    final Set<DateTime> activeDates = <DateTime>{};

    for (final ContentSource source in sources) {
      final List<LessonProgress> progressItems = await _progressRepository
          .getProgressForContent(source.contentId);
      for (final LessonProgress progress in progressItems) {
        final DateTime? completed =
            progress.lastCompletedAt ?? progress.completedAt;
        if (progress.isCompleted && completed != null) {
          activeDates.add(_dateOnly(completed));
        }
      }
    }

    for (final PracticeResult result
        in await _practiceRepository.getAllResults()) {
      activeDates.add(_dateOnly(result.endTime));
    }

    for (final ReviewItem review in await _reviewRepository.getAllReviews()) {
      final DateTime? reviewed = review.lastReviewed;
      if (reviewed != null) {
        activeDates.add(_dateOnly(reviewed));
      }
    }

    if (activeDates.isEmpty) {
      return StreakInfo.empty;
    }

    final DateTime today = _dateOnly(now ?? DateTime.now());
    return StreakInfo(
      currentStreak: _currentStreak(activeDates, today),
      longestStreak: _longestStreak(activeDates),
      lastActiveDate: activeDates.reduce(
        (DateTime a, DateTime b) => a.isAfter(b) ? a : b,
      ),
    );
  }

  /// Evaluates every catalog achievement against current progress, streak,
  /// and review data, persisting newly unlocked ones. Already-unlocked
  /// achievements are never re-locked.
  Future<List<AchievementProgress>> evaluateAchievements(
    List<ContentSource> sources, {
    DateTime? now,
  }) async {
    final LearningStatistics statistics = await _statisticsService
        .getStatistics(sources);
    final StreakInfo streak = await calculateStreak(sources, now: now);
    final List<ReviewItem> reviews = await _reviewRepository.getAllReviews();
    final int totalReviewCount = reviews.fold(
      0,
      (int sum, ReviewItem item) => sum + item.reviewCount,
    );
    final PracticeStatistics practiceStatistics =
        await _practiceStatisticsService.getStatistics();

    final List<AchievementProgress> results = <AchievementProgress>[];
    for (final Achievement achievement in catalog) {
      final AchievementProgress? existing = await _achievementRepository
          .getProgress(achievement.id);
      if (existing != null && existing.isUnlocked) {
        results.add(existing);
        continue;
      }

      final bool meetsCriteria = _meetsCriteria(
        achievement,
        statistics: statistics,
        streak: streak,
        totalReviewCount: totalReviewCount,
        practiceStatistics: practiceStatistics,
      );

      if (meetsCriteria) {
        final AchievementProgress unlocked = AchievementProgress(
          achievementId: achievement.id,
          isUnlocked: true,
          unlockedAt: now ?? DateTime.now(),
        );
        await _achievementRepository.saveProgress(unlocked);
        results.add(unlocked);
      } else {
        results.add(
          existing ??
              AchievementProgress(
                achievementId: achievement.id,
                isUnlocked: false,
              ),
        );
      }
    }
    return results;
  }

  bool _meetsCriteria(
    Achievement achievement, {
    required LearningStatistics statistics,
    required StreakInfo streak,
    required int totalReviewCount,
    required PracticeStatistics practiceStatistics,
  }) {
    switch (achievement.criteria) {
      case AchievementCriteria.lessonsCompleted:
        return statistics.completedLessons >= achievement.threshold;
      case AchievementCriteria.longestStreakDays:
        return streak.longestStreak >= achievement.threshold;
      case AchievementCriteria.reviewsCompleted:
        return totalReviewCount >= achievement.threshold;
      case AchievementCriteria.averageAccuracy:
        return statistics.averageAccuracy >= achievement.threshold;
      case AchievementCriteria.practiceSessionsCompleted:
        return practiceStatistics.totalSessions >= achievement.threshold;
      case AchievementCriteria.practiceQuestionsAnswered:
        return practiceStatistics.totalQuestionsAnswered >=
            achievement.threshold;
      case AchievementCriteria.perfectPracticeSessions:
        return practiceStatistics.perfectSessionCount >= achievement.threshold;
      case AchievementCriteria.practiceStreakDays:
        return practiceStatistics.longestStreakDays >= achievement.threshold;
    }
  }

  DateTime _dateOnly(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }

  int _currentStreak(Set<DateTime> activeDates, DateTime today) {
    DateTime cursor = today;
    if (!activeDates.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
      if (!activeDates.contains(cursor)) {
        return 0;
      }
    }

    int streak = 0;
    while (activeDates.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  int _longestStreak(Set<DateTime> activeDates) {
    final List<DateTime> sorted = activeDates.toList()..sort();
    int longest = 0;
    int current = 0;
    DateTime? previous;

    for (final DateTime date in sorted) {
      if (previous != null && date.difference(previous).inDays == 1) {
        current++;
      } else {
        current = 1;
      }
      longest = current > longest ? current : longest;
      previous = date;
    }
    return longest;
  }
}
