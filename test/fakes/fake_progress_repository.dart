import 'package:japanese_learning/features/progress/models/lesson_progress.dart';
import 'package:japanese_learning/features/progress/repositories/progress_repository.dart';

/// Simple in-memory [ProgressRepository] for tests — no Hive involved.
class FakeProgressRepository implements ProgressRepository {
  final Map<String, LessonProgress> _store = <String, LessonProgress>{};

  @override
  Future<List<LessonProgress>> getProgressForContent(String contentId) async {
    return _store.values
        .where((LessonProgress p) => p.contentId == contentId)
        .toList(growable: false);
  }

  @override
  Future<LessonProgress?> getLessonProgress({
    required String contentId,
    required int lessonNumber,
  }) async {
    return _store['$contentId:$lessonNumber'];
  }

  @override
  Future<void> saveProgress(LessonProgress progress) async {
    _store['${progress.contentId}:${progress.lessonNumber}'] = progress;
  }
}
