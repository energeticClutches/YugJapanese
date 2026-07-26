import 'package:hive/hive.dart';

import '../../../core/utils/safe_parse.dart';
import '../models/lesson_progress.dart';
import 'progress_repository.dart';

class HiveProgressRepository implements ProgressRepository {
  const HiveProgressRepository();

  static const String boxName = 'lesson_progress';

  Box<dynamic> get _box => Hive.box<dynamic>(boxName);

  @override
  Future<List<LessonProgress>> getProgressForContent(String contentId) async {
    return _box.values
        .whereType<Map>()
        .map((Map value) => safeParse(value, LessonProgress.fromMap))
        .whereType<LessonProgress>()
        .where((LessonProgress progress) => progress.contentId == contentId)
        .toList(growable: false);
  }

  @override
  Future<LessonProgress?> getLessonProgress({
    required String contentId,
    required int lessonNumber,
  }) async {
    final value = _box.get(_key(contentId, lessonNumber));
    if (value is! Map) {
      return null;
    }
    return safeParse(value, LessonProgress.fromMap);
  }

  @override
  Future<void> saveProgress(LessonProgress progress) {
    return _box.put(
      _key(progress.contentId, progress.lessonNumber),
      progress.toMap(),
    );
  }

  String _key(String contentId, int lessonNumber) =>
      '$contentId:$lessonNumber';
}
