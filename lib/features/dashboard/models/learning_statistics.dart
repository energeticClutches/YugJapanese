class LearningStatistics {
  const LearningStatistics({
    required this.totalLessons,
    required this.completedLessons,
    required this.completionPercentage,
    required this.averageAccuracy,
    required this.lessonsInProgress,
    this.lastLessonId,
  });

  final int totalLessons;
  final int completedLessons;
  final double completionPercentage;
  final double averageAccuracy;
  final int lessonsInProgress;
  final String? lastLessonId;

  int get lessonsRemaining => totalLessons - completedLessons;

  static const LearningStatistics empty = LearningStatistics(
    totalLessons: 0,
    completedLessons: 0,
    completionPercentage: 0,
    averageAccuracy: 0,
    lessonsInProgress: 0,
  );
}
