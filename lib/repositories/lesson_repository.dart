import '../models/learning_item.dart';
import '../models/lesson_model.dart';

abstract class LessonRepository {
  Future<List<LessonModel>> getAllLessons();

  Future<LessonModel?> getLesson(int lessonNumber);

  Future<LearningItem?> getItem(String id);
}
