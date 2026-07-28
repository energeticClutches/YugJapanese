import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_learning/features/quiz/models/practice_result.dart';
import 'package:japanese_learning/features/quiz/models/practice_statistics.dart';
import 'package:japanese_learning/features/quiz/services/practice_generator.dart';
import 'package:japanese_learning/features/quiz/services/practice_statistics_service.dart';

import '../fakes/fake_practice_repository.dart';

PracticeResult _result({
  required String id,
  required String modeId,
  required double accuracy,
}) {
  return PracticeResult(
    id: id,
    modeId: modeId,
    contentIds: const <String>['hiragana'],
    totalQuestions: 10,
    correctAnswers: 5,
    incorrectAnswers: 5,
    accuracy: accuracy,
    startTime: DateTime(2026, 7, 29, 10),
    endTime: DateTime(2026, 7, 29, 10, 5),
  );
}

void main() {
  group('Review Mistakes is its own workflow (Milestone 31, Issue 4)', () {
    test('its mode id is not a selectable practice mode', () {
      expect(
        PracticeGenerator.modeById(PracticeGenerator.reviewMistakesModeId),
        isNull,
        reason: 'it must not render a card on the Practice home',
      );
      expect(
        PracticeGenerator.catalog.any(
          (mode) => mode.id == PracticeGenerator.reviewMistakesModeId,
        ),
        isFalse,
      );
    });

    test('it still resolves to a readable title', () {
      expect(
        PracticeGenerator.titleForModeId(
          PracticeGenerator.reviewMistakesModeId,
        ),
        'Review Mistakes',
      );
      expect(
        PracticeGenerator.titleForModeId('recognition'),
        'Recognition Quiz',
      );
    });

    test(
      'a review run does not overwrite the source quiz mode best score',
      () async {
        final FakePracticeRepository repository = FakePracticeRepository();
        await repository.saveResult(
          _result(id: 'r1', modeId: 'recognition', accuracy: 20),
        );
        // The follow-up review of those mistakes scored higher. Before this
        // fix it was persisted as another 'recognition' run, so Recognition
        // Quiz's "Best" jumped to 50% on the strength of a review.
        await repository.saveResult(
          _result(
            id: 'r2',
            modeId: PracticeGenerator.reviewMistakesModeId,
            accuracy: 50,
          ),
        );

        final PracticeStatistics statistics = await PracticeStatisticsService(
          repository,
        ).getStatistics();

        expect(statistics.bestScoreByMode['recognition'], 20);
        expect(
          statistics.bestScoreByMode[PracticeGenerator.reviewMistakesModeId],
          50,
        );
      },
    );
  });
}
