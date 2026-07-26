import 'daily_learning_stat.dart';
import 'script_analytics.dart';
import 'weak_area.dart';

/// A locked achievement paired with how close it is to unlocking (0..1),
/// computed from the same current metrics `AchievementService` already
/// tracks. Not persisted — display-only, part of [LearningAnalytics].
class NextAchievement {
  const NextAchievement({
    required this.achievementId,
    required this.title,
    required this.description,
    required this.iconKey,
    required this.progress,
  });

  final String achievementId;
  final String title;
  final String description;
  final String iconKey;
  final double progress;
}

/// The full aggregate computed fresh by `AnalyticsService.getAnalytics()`
/// on every call, reusing existing progress/review/practice/achievement
/// data — nothing here is a new source of truth.
class LearningAnalytics {
  const LearningAnalytics({
    required this.totalLessonsCompleted,
    required this.completionPercentage,
    required this.totalPracticeSessions,
    required this.totalReviews,
    required this.estimatedStudyMinutes,
    required this.currentStreakDays,
    required this.longestStreakDays,
    required this.scriptBreakdown,
    required this.dailyActivity,
    required this.weakAreas,
    required this.insights,
    required this.achievementsUnlocked,
    required this.achievementsTotal,
    required this.nextAchievements,
    required this.computedAt,
  });

  final int totalLessonsCompleted;
  final double completionPercentage;
  final int totalPracticeSessions;
  final int totalReviews;
  final int estimatedStudyMinutes;
  final int currentStreakDays;
  final int longestStreakDays;
  final List<ScriptAnalytics> scriptBreakdown;

  /// Trailing 30 days, oldest first.
  final List<DailyLearningStat> dailyActivity;

  /// Sorted worst-first, capped per type.
  final List<WeakArea> weakAreas;

  /// Deterministic, capped at 5.
  final List<String> insights;

  final int achievementsUnlocked;
  final int achievementsTotal;

  /// Locked achievements sorted by progress descending, capped at 3.
  final List<NextAchievement> nextAchievements;

  final DateTime computedAt;

  static final LearningAnalytics empty = LearningAnalytics(
    totalLessonsCompleted: 0,
    completionPercentage: 0,
    totalPracticeSessions: 0,
    totalReviews: 0,
    estimatedStudyMinutes: 0,
    currentStreakDays: 0,
    longestStreakDays: 0,
    scriptBreakdown: const <ScriptAnalytics>[],
    dailyActivity: const <DailyLearningStat>[],
    weakAreas: const <WeakArea>[],
    insights: const <String>[
      'Complete a lesson or practice session to start seeing insights.',
    ],
    achievementsUnlocked: 0,
    achievementsTotal: 0,
    nextAchievements: const <NextAchievement>[],
    computedAt: DateTime.fromMillisecondsSinceEpoch(0),
  );
}
