import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_learning/features/quiz/models/practice_question.dart';
import 'package:japanese_learning/features/quiz/models/practice_session.dart';
import 'package:japanese_learning/models/learning_item.dart';

/// Locks in the state shape behind Milestone 23's Issue 4 (and the
/// functional half of Issue 2).
///
/// `PracticeService` is an app-lifetime singleton and nothing calls its
/// `clearSession()`, so a finished session stays in `currentSession`
/// indefinitely. `PracticeSessionScreen` starts its own session from a
/// post-frame callback, which means its *first* build necessarily observes
/// whatever the previous session left behind. These tests pin down the two
/// facts that combination depends on: a completed session reports
/// `isComplete == true` and hands back a null `currentQuestion`.
///
/// The screen's guard is `!_started || isGenerating || session == null`.
/// Before that `!_started` was added, a stale completed session satisfied
/// none of those, so the screen fell straight into its `isComplete` branch
/// and redirected to `/quiz/results` — every quiz mode landing on the same
/// stale results screen. If someone later "simplifies" that guard away,
/// these tests explain what breaks.
PracticeQuestion _question(String id) {
  return PracticeQuestion(
    id: id,
    learningItem: LearningItem(
      id: 'hiragana-a',
      symbol: 'あ',
      primaryReading: 'a',
      meaning: 'a',
      strokeCount: 3,
      lessonNumber: 1,
      audioAsset: '',
      strokeAsset: '',
    ),
    contentId: 'hiragana',
    questionType: QuestionType.recognition,
    prompt: 'あ',
    choices: const <String>['a', 'i', 'u', 'e'],
    correctAnswer: 'a',
  );
}

PracticeSession _sessionAt(int currentIndex, {int questionCount = 2}) {
  return PracticeSession(
    modeId: 'recognition',
    questions: <PracticeQuestion>[
      for (int i = 0; i < questionCount; i++) _question('q$i'),
    ],
    currentIndex: currentIndex,
    correctAnswers: 0,
    incorrectAnswers: 0,
    startTime: DateTime(2026, 1, 1),
  );
}

void main() {
  group('stale completed session (Milestone 23, Issues 2 & 4)', () {
    test('a finished session reports isComplete', () {
      expect(_sessionAt(2).isComplete, isTrue);
    });

    test('a finished session has no current question to render', () {
      // This is why the screen cannot simply fall through to rendering a
      // stale session — `currentQuestion!` would throw.
      expect(_sessionAt(2).currentQuestion, isNull);
    });

    test('an in-progress session is not complete and has a question', () {
      final PracticeSession inProgress = _sessionAt(0);
      expect(inProgress.isComplete, isFalse);
      expect(inProgress.currentQuestion, isNotNull);
    });

    test('a fresh session for a new quiz starts incomplete at index 0', () {
      // What the screen must end up showing once its own generation
      // finishes — rather than the previous session's completed state.
      final PracticeSession fresh = _sessionAt(0, questionCount: 10);
      expect(fresh.currentIndex, 0);
      expect(fresh.isComplete, isFalse);
      expect(fresh.currentQuestion, isNotNull);
    });
  });
}
