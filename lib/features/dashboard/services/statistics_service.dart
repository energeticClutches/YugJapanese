import '../../progress/models/lesson_progress.dart';
import '../../progress/repositories/progress_repository.dart';
import '../models/content_source.dart';
import '../models/learning_statistics.dart';

class StatisticsService {
  const StatisticsService(this._progressRepository);

  final ProgressRepository _progressRepository;

  Future<LearningStatistics> getStatistics(List<ContentSource> sources) async {
    int totalLessons = 0;
    int completedLessons = 0;
    int lessonsInProgress = 0;
    final List<double> accuracies = <double>[];
    LessonProgress? mostRecentProgress;

    for (final ContentSource source in sources) {
      final lessons = await source.repository.getAllLessons();
      totalLessons += lessons.length;

      final List<LessonProgress> progressItems =
          await _progressRepository.getProgressForContent(source.contentId);
      for (final LessonProgress progress in progressItems) {
        if (progress.isCompleted) {
          completedLessons++;
          accuracies.add(progress.bestWritingAccuracy);
        } else {
          lessonsInProgress++;
        }
        if (mostRecentProgress == null ||
            progress.lastAccessedAt.isAfter(mostRecentProgress.lastAccessedAt)) {
          mostRecentProgress = progress;
        }
      }
    }

    final double completionPercentage =
        totalLessons == 0 ? 0 : (completedLessons / totalLessons) * 100;
    final double averageAccuracy = accuracies.isEmpty
        ? 0
        : accuracies.reduce((double a, double b) => a + b) / accuracies.length;

    return LearningStatistics(
      totalLessons: totalLessons,
      completedLessons: completedLessons,
      completionPercentage: completionPercentage,
      averageAccuracy: averageAccuracy,
      lessonsInProgress: lessonsInProgress,
      lastLessonId: mostRecentProgress == null
          ? null
          : '${mostRecentProgress.contentId}:${mostRecentProgress.lessonNumber}',
    );
  }
}
