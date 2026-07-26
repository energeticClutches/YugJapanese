/// Persisted cache of the scalar totals from the most recently computed
/// [LearningAnalytics] — written as a side effect of
/// `AnalyticsService.getAnalytics()`. Deliberately does not duplicate any
/// source data (progress/review/practice records remain the only source of
/// truth); this is just a snapshot of already-derived numbers.
class AnalyticsSnapshot {
  const AnalyticsSnapshot({
    required this.totalLessonsCompleted,
    required this.completionPercentage,
    required this.totalPracticeSessions,
    required this.totalReviews,
    required this.estimatedStudyMinutes,
    required this.currentStreakDays,
    required this.longestStreakDays,
    required this.computedAt,
  });

  final int totalLessonsCompleted;
  final double completionPercentage;
  final int totalPracticeSessions;
  final int totalReviews;
  final int estimatedStudyMinutes;
  final int currentStreakDays;
  final int longestStreakDays;
  final DateTime computedAt;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'totalLessonsCompleted': totalLessonsCompleted,
      'completionPercentage': completionPercentage,
      'totalPracticeSessions': totalPracticeSessions,
      'totalReviews': totalReviews,
      'estimatedStudyMinutes': estimatedStudyMinutes,
      'currentStreakDays': currentStreakDays,
      'longestStreakDays': longestStreakDays,
      'computedAt': computedAt.toIso8601String(),
    };
  }

  factory AnalyticsSnapshot.fromMap(Map<String, dynamic> map) {
    return AnalyticsSnapshot(
      totalLessonsCompleted: map['totalLessonsCompleted'] as int,
      completionPercentage: (map['completionPercentage'] as num).toDouble(),
      totalPracticeSessions: map['totalPracticeSessions'] as int,
      totalReviews: map['totalReviews'] as int,
      estimatedStudyMinutes: map['estimatedStudyMinutes'] as int,
      currentStreakDays: map['currentStreakDays'] as int,
      longestStreakDays: map['longestStreakDays'] as int,
      computedAt: DateTime.parse(map['computedAt'] as String),
    );
  }
}
