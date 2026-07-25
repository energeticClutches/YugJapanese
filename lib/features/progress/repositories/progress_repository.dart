import '../models/lesson_progress.dart';

abstract class ProgressRepository {
  Future<List<LessonProgress>> getProgressForContent(String contentId);

  Future<LessonProgress?> getLessonProgress({
    required String contentId,
    required int lessonNumber,
  });

  Future<void> saveProgress(LessonProgress progress);
}
