import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_learning/features/practice/learning_controller.dart';
import 'package:japanese_learning/models/character_model.dart';
import 'package:japanese_learning/models/learning_item.dart';
import 'package:japanese_learning/models/lesson_model.dart';
import 'package:japanese_learning/repositories/lesson_repository.dart';

CharacterModel _character(String id, int lessonNumber) {
  return CharacterModel(
    id: id,
    character: 'あ',
    romaji: 'a',
    englishName: 'a',
    strokeCount: 3,
    lessonNumber: lessonNumber,
    unicode: 'U+3042',
    isLearned: false,
    audioAsset: '',
  );
}

LessonModel _lesson(int lessonNumber) {
  return LessonModel(
    lessonNumber: lessonNumber,
    title: 'Lesson $lessonNumber',
    description: '',
    characters: <CharacterModel>[_character('c$lessonNumber', lessonNumber)],
  );
}

class _FakeLessonRepository implements LessonRepository {
  _FakeLessonRepository(this.lessons);

  final List<LessonModel> lessons;

  @override
  Future<List<LessonModel>> getAllLessons() async => lessons;

  @override
  Future<LessonModel?> getLesson(int lessonNumber) async {
    for (final LessonModel lesson in lessons) {
      if (lesson.lessonNumber == lessonNumber) {
        return lesson;
      }
    }
    return null;
  }

  @override
  Future<LearningItem?> getItem(String id) async => null;
}

void main() {
  group('LearningController.nextLessonNumber (BUG-008)', () {
    test('returns the following lesson mid-script', () async {
      final LearningController controller = LearningController(
        _FakeLessonRepository(<LessonModel>[_lesson(1), _lesson(2), _lesson(3)]),
      );
      await controller.startLesson(2);

      expect(await controller.nextLessonNumber(), 3);
    });

    test('returns null on the last lesson so the script can finish', () async {
      final LearningController controller = LearningController(
        _FakeLessonRepository(<LessonModel>[_lesson(1), _lesson(2)]),
      );
      await controller.startLesson(2);

      expect(await controller.nextLessonNumber(), isNull);
    });

    test('picks the lowest lesson above the current one, not file order',
        () async {
      final LearningController controller = LearningController(
        _FakeLessonRepository(<LessonModel>[_lesson(3), _lesson(1), _lesson(2)]),
      );
      await controller.startLesson(1);

      expect(
        await controller.nextLessonNumber(),
        2,
        reason: 'progression follows lesson numbering, not JSON ordering',
      );
    });

    test('skips gaps in lesson numbering', () async {
      final LearningController controller = LearningController(
        _FakeLessonRepository(<LessonModel>[_lesson(1), _lesson(5)]),
      );
      await controller.startLesson(1);

      expect(await controller.nextLessonNumber(), 5);
    });

    test('reports nothing before a lesson has been started', () async {
      final LearningController controller = LearningController(
        _FakeLessonRepository(<LessonModel>[_lesson(1)]),
      );

      expect(await controller.nextLessonNumber(), isNull);
    });
  });
}
