import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_learning/models/learning_session.dart';
import 'package:japanese_learning/models/learning_step.dart';

LearningSession _session({
  int currentCharacterIndex = 0,
  LearningStep currentStep = LearningStep.introduction,
  int totalCharacters = 3,
  int completedCharacters = 0,
  LearningStep startStep = LearningStep.introduction,
}) {
  return LearningSession(
    lessonNumber: 1,
    currentCharacterIndex: currentCharacterIndex,
    currentStep: currentStep,
    totalCharacters: totalCharacters,
    completedCharacters: completedCharacters,
    startStep: startStep,
  );
}

void main() {
  group('LearningSession.previousStep (Milestone 31, Issue 2)', () {
    test('steps backward within a character as before', () {
      final LearningSession session = _session(
        currentStep: LearningStep.freeWriting,
      );
      expect(session.previousStep().currentStep, LearningStep.tracing);
      expect(
        session.previousStep().previousStep().currentStep,
        LearningStep.strokeOrder,
      );
    });

    test('crosses back into the previous character from the first step, '
        'instead of doing nothing', () {
      final LearningSession session = _session(
        currentCharacterIndex: 1,
        currentStep: LearningStep.introduction,
      );
      final LearningSession previous = session.previousStep();
      expect(previous.currentCharacterIndex, 0);
      expect(previous.currentStep, LearningStep.introduction);
    });

    test('crosses back a character in review mode, whose first step is '
        'strokeOrder rather than introduction', () {
      final LearningSession session = _session(
        currentCharacterIndex: 2,
        currentStep: LearningStep.strokeOrder,
        startStep: LearningStep.strokeOrder,
      );
      final LearningSession previous = session.previousStep();
      expect(previous.currentCharacterIndex, 1);
      expect(previous.currentStep, LearningStep.strokeOrder);
    });

    test(
      'is a genuine no-op only on the first step of the first character',
      () {
        final LearningSession session = _session();
        expect(session.canGoToPreviousStep, isFalse);
        expect(session.previousStep().currentCharacterIndex, 0);
        expect(session.previousStep().currentStep, LearningStep.introduction);
      },
    );

    test('canGoToPreviousStep is true everywhere else, including the first '
        'step of a non-first character', () {
      expect(
        _session(
          currentCharacterIndex: 1,
          currentStep: LearningStep.introduction,
        ).canGoToPreviousStep,
        isTrue,
      );
      expect(
        _session(currentStep: LearningStep.strokeOrder).canGoToPreviousStep,
        isTrue,
      );
    });
  });

  group('LearningSession.previousCharacter', () {
    test('moves to the character before, landing on startStep', () {
      final LearningSession session = _session(
        currentCharacterIndex: 2,
        currentStep: LearningStep.freeWriting,
        completedCharacters: 2,
      );
      final LearningSession previous = session.previousCharacter();
      expect(previous.currentCharacterIndex, 1);
      expect(previous.currentStep, LearningStep.introduction);
      expect(previous.completedCharacters, 1);
    });

    test('is a no-op on the first character', () {
      final LearningSession session = _session();
      final LearningSession previous = session.previousCharacter();
      expect(previous.currentCharacterIndex, 0);
    });
  });
}
