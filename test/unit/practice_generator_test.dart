import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_learning/features/quiz/models/practice_question.dart';
import 'package:japanese_learning/features/quiz/services/practice_generator.dart';

import '../fakes/fake_audio_repository.dart';
import '../fakes/fake_practice_repository.dart';
import '../fakes/fake_progress_repository.dart';
import '../fakes/fake_review_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PracticeGenerator generator;

  setUp(() {
    generator = PracticeGenerator(
      audioRepository: FakeAudioRepository(),
      progressRepository: FakeProgressRepository(),
      reviewRepository: FakeReviewRepository(),
      practiceRepository: FakePracticeRepository(),
    );
  });

  group('PracticeGenerator.catalog', () {
    test('has exactly six modes with unique ids', () {
      expect(PracticeGenerator.catalog.length, 6);
      final Set<String> ids =
          PracticeGenerator.catalog.map((m) => m.id).toSet();
      expect(ids.length, 6);
      expect(ids, containsAll(<String>[
        'recognition',
        'meaning',
        'reading',
        'listening',
        'mixed',
        'weak_items',
      ]));
    });

    test('modeById resolves a known id and returns null for an unknown one', () {
      expect(PracticeGenerator.modeById('recognition')?.id, 'recognition');
      expect(PracticeGenerator.modeById('does_not_exist'), isNull);
    });
  });

  group('PracticeGenerator.generateSession (recognition mode)', () {
    test('produces the requested number of questions from real Hiragana content', () async {
      final List<PracticeQuestion> questions = await generator.generateSession(
        modeId: 'recognition',
        scripts: <String>['hiragana'],
        questionCount: 10,
      );

      expect(questions.length, 10);
      for (final PracticeQuestion question in questions) {
        expect(question.questionType, QuestionType.recognition);
        expect(question.contentId, 'hiragana');
        // Correct answer must always be one of the offered choices, and
        // choices must not contain duplicates.
        expect(question.choices, contains(question.correctAnswer));
        expect(question.choices.toSet().length, question.choices.length);
        expect(question.choices.length, lessThanOrEqualTo(4));
      }
    });

    test('recognition questions prompt with the symbol and answer with the reading', () async {
      final List<PracticeQuestion> questions = await generator.generateSession(
        modeId: 'recognition',
        scripts: <String>['hiragana'],
        questionCount: 5,
      );

      for (final PracticeQuestion question in questions) {
        expect(question.prompt, question.learningItem.symbol);
        expect(question.correctAnswer, question.learningItem.primaryReading);
      }
    });
  });

  group('PracticeGenerator.generateSession (weak_items mode)', () {
    test('falls back to the full pool when there is no weak-signal data yet', () async {
      final List<PracticeQuestion> questions = await generator.generateSession(
        modeId: 'weak_items',
        scripts: <String>['hiragana'],
        questionCount: 5,
      );

      // No progress/review/practice history exists in the fakes, so the
      // generator should still produce a full session rather than an
      // empty one.
      expect(questions.length, 5);
    });
  });
}
