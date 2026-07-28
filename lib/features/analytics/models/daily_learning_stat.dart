/// One day's worth of learning activity, bucketed from existing progress,
/// review, and practice records. Pure computed value — never persisted
/// individually (only the scalar [AnalyticsSnapshot] summary is cached).
///
/// [reviewSuccessRate] is always `1.0` on a day with at least one recorded
/// review: the review scheduler has no failure-tracking path today (see
/// `ReviewScheduler` — every recorded review is `recordSuccessfulReview`),
/// so this reflects that honestly rather than fabricating pass/fail data.
class DailyLearningStat {
  const DailyLearningStat({
    required this.date,
    required this.lessonsCompleted,
    required this.reviewsCompleted,
    required this.practiceSessions,
    required this.questionsAnswered,
    this.averageWritingAccuracy,
    this.averageQuizAccuracy,
    this.reviewSuccessRate,
  });

  final DateTime date;
  final int lessonsCompleted;
  final int reviewsCompleted;
  final int practiceSessions;
  final int questionsAnswered;
  final double? averageWritingAccuracy;
  final double? averageQuizAccuracy;
  final double? reviewSuccessRate;

  bool get hasActivity =>
      lessonsCompleted > 0 || reviewsCompleted > 0 || practiceSessions > 0;

  int get activityCount =>
      lessonsCompleted + reviewsCompleted + practiceSessions;
}
