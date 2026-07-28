import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_learning/features/progress/models/lesson_progress.dart';
import 'package:japanese_learning/features/progress/services/progress_controller.dart';

import '../fakes/fake_progress_repository.dart';

/// A `flutter_test`-based substitute for a device-driven integration test:
/// exercises the real [ProgressController] end to end against a fake
/// repository, covering the same "start lesson → complete lesson →
/// progress persists → completion percentage updates" path a genuine user
/// session would hit, without the `integration_test` package/device
/// runner.
void main() {
  group('Lesson completion flow', () {
    late FakeProgressRepository repository;
    late ProgressController controller;

    setUp(() {
      repository = FakeProgressRepository();
      controller = ProgressController(repository);
    });

    test(
      'starting a lesson records it as in-progress but not completed',
      () async {
        await controller.startLesson(contentId: 'hiragana', lessonNumber: 1);

        final LessonProgress? progress = controller.lessonProgress(
          'hiragana',
          1,
        );
        expect(progress, isNotNull);
        expect(progress!.isCompleted, isFalse);

        final LessonProgress? persisted = await repository.getLessonProgress(
          contentId: 'hiragana',
          lessonNumber: 1,
        );
        expect(persisted, isNotNull);
        expect(persisted!.isCompleted, isFalse);
      },
    );

    test('completing a lesson persists completion and best accuracy', () async {
      await controller.startLesson(contentId: 'hiragana', lessonNumber: 1);
      await controller.completeLesson(
        contentId: 'hiragana',
        lessonNumber: 1,
        writingAccuracy: 0.75,
      );

      final LessonProgress? progress = controller.lessonProgress('hiragana', 1);
      expect(progress, isNotNull);
      expect(progress!.isCompleted, isTrue);
      expect(progress.bestWritingAccuracy, 0.75);

      final LessonProgress? persisted = await repository.getLessonProgress(
        contentId: 'hiragana',
        lessonNumber: 1,
      );
      expect(persisted!.isCompleted, isTrue);
    });

    test('completing a lesson again only keeps the best accuracy', () async {
      await controller.startLesson(contentId: 'hiragana', lessonNumber: 1);
      await controller.completeLesson(
        contentId: 'hiragana',
        lessonNumber: 1,
        writingAccuracy: 0.9,
      );
      await controller.completeLesson(
        contentId: 'hiragana',
        lessonNumber: 1,
        writingAccuracy: 0.4,
      );

      final LessonProgress? progress = controller.lessonProgress('hiragana', 1);
      expect(progress!.bestWritingAccuracy, 0.9);
    });

    test(
      'completion percentage reflects completed lessons out of the total',
      () async {
        await controller.startLesson(contentId: 'hiragana', lessonNumber: 1);
        await controller.completeLesson(
          contentId: 'hiragana',
          lessonNumber: 1,
          writingAccuracy: 0.8,
        );

        expect(controller.completionPercentage('hiragana', 4), 25);
      },
    );

    test(
      'loadProgress hydrates the controller from previously persisted data',
      () async {
        await repository.saveProgress(
          LessonProgress(
            contentId: 'katakana',
            lessonNumber: 2,
            isCompleted: true,
            bestWritingAccuracy: 0.6,
            lastAccessedAt: DateTime(2026, 1, 1),
            completedAt: DateTime(2026, 1, 1),
          ),
        );

        // Simulates an app restart: a fresh controller over the same
        // (persisted) repository should see the earlier session's data.
        final ProgressController freshController = ProgressController(
          repository,
        );
        await freshController.loadProgress('katakana');

        expect(freshController.completionPercentage('katakana', 1), 100);
      },
    );
  });
}
