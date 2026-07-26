/// Aggregate practice statistics, computed by `PracticeStatisticsService`
/// from every persisted `PracticeResult`. Never persisted directly — same
/// relationship `LearningStatistics` has to `StatisticsService`.
class PracticeStatistics {
  const PracticeStatistics({
    required this.totalSessions,
    required this.totalQuestionsAnswered,
    required this.accuracyByMode,
    required this.bestScoreByMode,
    required this.lastPlayedByMode,
    required this.averageSessionDurationSeconds,
    required this.bestScore,
    this.mostPracticedScript,
    this.weakestScript,
    required this.currentStreakDays,
    required this.longestStreakDays,
    required this.perfectSessionCount,
  });

  final int totalSessions;
  final int totalQuestionsAnswered;
  final Map<String, double> accuracyByMode;
  final Map<String, double> bestScoreByMode;
  final Map<String, DateTime> lastPlayedByMode;
  final double averageSessionDurationSeconds;
  final double bestScore;
  final String? mostPracticedScript;
  final String? weakestScript;
  final int currentStreakDays;
  final int longestStreakDays;
  final int perfectSessionCount;

  static const PracticeStatistics empty = PracticeStatistics(
    totalSessions: 0,
    totalQuestionsAnswered: 0,
    accuracyByMode: <String, double>{},
    bestScoreByMode: <String, double>{},
    lastPlayedByMode: <String, DateTime>{},
    averageSessionDurationSeconds: 0,
    bestScore: 0,
    currentStreakDays: 0,
    longestStreakDays: 0,
    perfectSessionCount: 0,
  );
}
