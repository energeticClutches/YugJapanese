import '../models/practice_result.dart';
import '../models/practice_statistics.dart';
import '../repositories/practice_repository.dart';

/// Aggregates every persisted [PracticeResult] into [PracticeStatistics].
/// Pure Dart, no UI logic — matches `StatisticsService`'s relationship to
/// `LearningStatistics`.
class PracticeStatisticsService {
  const PracticeStatisticsService(this._repository);

  final PracticeRepository _repository;

  Future<PracticeStatistics> getStatistics() async {
    final List<PracticeResult> results = await _repository.getAllResults();
    if (results.isEmpty) {
      return PracticeStatistics.empty;
    }

    int totalQuestionsAnswered = 0;
    double bestScore = 0;
    int perfectSessionCount = 0;
    Duration totalDuration = Duration.zero;

    final Map<String, List<double>> accuraciesByMode = <String, List<double>>{};
    final Map<String, double> bestScoreByMode = <String, double>{};
    final Map<String, DateTime> lastPlayedByMode = <String, DateTime>{};
    final Map<String, int> sessionsByScript = <String, int>{};
    final Map<String, List<double>> accuraciesByScript = <String, List<double>>{};
    final Set<DateTime> activeDates = <DateTime>{};

    for (final PracticeResult result in results) {
      totalQuestionsAnswered += result.totalQuestions;
      totalDuration += result.duration;
      if (result.accuracy > bestScore) {
        bestScore = result.accuracy;
      }
      if (result.accuracy >= 100) {
        perfectSessionCount++;
      }

      accuraciesByMode
          .putIfAbsent(result.modeId, () => <double>[])
          .add(result.accuracy);
      final double? currentBest = bestScoreByMode[result.modeId];
      if (currentBest == null || result.accuracy > currentBest) {
        bestScoreByMode[result.modeId] = result.accuracy;
      }
      final DateTime? currentLast = lastPlayedByMode[result.modeId];
      if (currentLast == null || result.endTime.isAfter(currentLast)) {
        lastPlayedByMode[result.modeId] = result.endTime;
      }

      for (final String contentId in result.contentIds) {
        sessionsByScript[contentId] = (sessionsByScript[contentId] ?? 0) + 1;
        accuraciesByScript
            .putIfAbsent(contentId, () => <double>[])
            .add(result.accuracy);
      }

      activeDates.add(_dateOnly(result.endTime));
    }

    final Map<String, double> accuracyByMode = accuraciesByMode.map(
      (String modeId, List<double> values) => MapEntry(
        modeId,
        values.reduce((double a, double b) => a + b) / values.length,
      ),
    );

    String? mostPracticedScript;
    int mostSessions = 0;
    sessionsByScript.forEach((String script, int count) {
      if (count > mostSessions) {
        mostSessions = count;
        mostPracticedScript = script;
      }
    });

    String? weakestScript;
    double lowestAccuracy = 101;
    accuraciesByScript.forEach((String script, List<double> values) {
      final double average =
          values.reduce((double a, double b) => a + b) / values.length;
      if (average < lowestAccuracy) {
        lowestAccuracy = average;
        weakestScript = script;
      }
    });

    final DateTime today = _dateOnly(DateTime.now());
    return PracticeStatistics(
      totalSessions: results.length,
      totalQuestionsAnswered: totalQuestionsAnswered,
      accuracyByMode: accuracyByMode,
      bestScoreByMode: bestScoreByMode,
      lastPlayedByMode: lastPlayedByMode,
      averageSessionDurationSeconds: totalDuration.inSeconds / results.length,
      bestScore: bestScore,
      mostPracticedScript: mostPracticedScript,
      weakestScript: weakestScript,
      currentStreakDays: _currentStreak(activeDates, today),
      longestStreakDays: _longestStreak(activeDates),
      perfectSessionCount: perfectSessionCount,
    );
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
