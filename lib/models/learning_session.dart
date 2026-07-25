import 'learning_step.dart';

class LearningSession {
  const LearningSession({
    required this.lessonNumber,
    required this.currentCharacterIndex,
    required this.currentStep,
    required this.totalCharacters,
    required this.completedCharacters,
    this.startStep = LearningStep.introduction,
  });

  final int lessonNumber;
  final int currentCharacterIndex;
  final LearningStep currentStep;
  final int totalCharacters;
  final int completedCharacters;

  /// The step each character begins on. Defaults to [LearningStep.introduction];
  /// review mode starts at [LearningStep.strokeOrder] instead.
  final LearningStep startStep;

  bool get isLessonComplete => completedCharacters >= totalCharacters;

  LearningSession nextStep() {
    switch (currentStep) {
      case LearningStep.introduction:
        return copyWith(currentStep: LearningStep.strokeOrder);
      case LearningStep.strokeOrder:
        return copyWith(currentStep: LearningStep.tracing);
      case LearningStep.tracing:
        return copyWith(currentStep: LearningStep.freeWriting);
      case LearningStep.freeWriting:
        return copyWith(currentStep: LearningStep.completed);
      case LearningStep.completed:
        return this;
    }
  }

  LearningSession previousStep() {
    switch (currentStep) {
      case LearningStep.introduction:
        return this;
      case LearningStep.strokeOrder:
        return startStep == LearningStep.strokeOrder
            ? this
            : copyWith(currentStep: LearningStep.introduction);
      case LearningStep.tracing:
        return copyWith(currentStep: LearningStep.strokeOrder);
      case LearningStep.freeWriting:
        return copyWith(currentStep: LearningStep.tracing);
      case LearningStep.completed:
        return copyWith(currentStep: LearningStep.freeWriting);
    }
  }

  LearningSession nextCharacter() {
    if (currentCharacterIndex >= totalCharacters - 1) {
      return copyWith(
        currentStep: LearningStep.completed,
        completedCharacters: totalCharacters,
      );
    }

    return copyWith(
      currentCharacterIndex: currentCharacterIndex + 1,
      currentStep: startStep,
      completedCharacters: completedCharacters + 1,
    );
  }

  LearningSession copyWith({
    int? lessonNumber,
    int? currentCharacterIndex,
    LearningStep? currentStep,
    int? totalCharacters,
    int? completedCharacters,
    LearningStep? startStep,
  }) {
    return LearningSession(
      lessonNumber: lessonNumber ?? this.lessonNumber,
      currentCharacterIndex: currentCharacterIndex ?? this.currentCharacterIndex,
      currentStep: currentStep ?? this.currentStep,
      totalCharacters: totalCharacters ?? this.totalCharacters,
      completedCharacters: completedCharacters ?? this.completedCharacters,
      startStep: startStep ?? this.startStep,
    );
  }
}
