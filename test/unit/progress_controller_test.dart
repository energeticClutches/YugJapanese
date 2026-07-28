import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_learning/features/progress/models/lesson_progress.dart';
import 'package:japanese_learning/features/progress/repositories/progress_repository.dart';
import 'package:japanese_learning/features/progress/services/progress_controller.dart';

class _FakeProgressRepository implements ProgressRepository {
  final Map<String, LessonProgress> _store = <String, LessonProgress>{};

  String _key(String contentId, int lessonNumber) => '$contentId:$lessonNumber';

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
  }) async => _store[_key(contentId, lessonNumber)];

  @override
  Future<void> saveProgress(LessonProgress progress) async {
    _store[_key(progress.contentId, progress.lessonNumber)] = progress;
  }
}

void main() {
  group('ProgressController mastery', () {
    late _FakeProgressRepository repository;
    late ProgressController controller;

    setUp(() {
      repository = _FakeProgressRepository();
      controller = ProgressController(repository);
    });

    Future<void> complete(int lesson, double accuracy) {
      return controller.completeLesson(
        contentId: 'hiragana',
        lessonNumber: lesson,
        writingAccuracy: accuracy,
      );
    }

    test('a confidently written lesson counts as mastered', () async {
      await complete(1, 0.9);
      expect(controller.isMastered('hiragana', 1), isTrue);
      expect(controller.needsMorePractice('hiragana', 1), isFalse);
    });

    test('a shaky lesson is finished but flagged for more practice', () async {
      await complete(2, 0.4);
      expect(controller.isMastered('hiragana', 2), isFalse);
      expect(controller.needsMorePractice('hiragana', 2), isTrue);
    });

    test(
      'an unfinished lesson is neither mastered nor needing practice',
      () async {
        await controller.startLesson(contentId: 'hiragana', lessonNumber: 3);
        expect(controller.isMastered('hiragana', 3), isFalse);
        expect(controller.needsMorePractice('hiragana', 3), isFalse);
      },
    );

    test('a later strong attempt lifts a lesson to mastered', () async {
      await complete(4, 0.4);
      expect(controller.needsMorePractice('hiragana', 4), isTrue);

      await complete(4, 0.95);
      expect(controller.isMastered('hiragana', 4), isTrue);
      expect(controller.needsMorePractice('hiragana', 4), isFalse);
    });

    test('a later weak attempt does not undo an earned mastery', () async {
      await complete(5, 0.95);
      await complete(5, 0.30);
      expect(
        controller.isMastered('hiragana', 5),
        isTrue,
        reason: 'mastery tracks the learner best, not their most recent slip',
      );
    });

    test('untouched lessons report nothing', () {
      expect(controller.isMastered('hiragana', 9), isFalse);
      expect(controller.needsMorePractice('hiragana', 9), isFalse);
    });
  });
}
