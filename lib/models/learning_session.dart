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

  /// Whether [previousStep] would actually move somewhere. Every character
  /// begins on [startStep], so the only place with nothing before it is the
  /// first step of the first character — everywhere else, "Previous" either
  /// steps back within the character or crosses into the one before it.
  bool get canGoToPreviousStep =>
      !(currentStep == startStep && currentCharacterIndex == 0);

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
        // Introduction is every character's first step outside review mode,
        // so "Previous" here means "the character before this one", not a
        // no-op — otherwise pressing it anywhere but character 1 silently
        // did nothing (Milestone 31, Issue 2).
        return currentCharacterIndex > 0 ? previousCharacter() : this;
      case LearningStep.strokeOrder:
        if (startStep == LearningStep.strokeOrder) {
          // Review mode starts each character here, so this is that
          // character's first step — same cross-character case as above.
          return currentCharacterIndex > 0 ? previousCharacter() : this;
        }
        return copyWith(currentStep: LearningStep.introduction);
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

  /// The character before [currentCharacterIndex], landing on its first
  /// step — the same place [nextCharacter] lands on the character after it.
  /// A no-op on the first character, where there is nothing before it.
  LearningSession previousCharacter() {
    if (currentCharacterIndex <= 0) {
      return this;
    }
    return copyWith(
      currentCharacterIndex: currentCharacterIndex - 1,
      currentStep: startStep,
      completedCharacters: completedCharacters > 0
          ? completedCharacters - 1
          : 0,
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
      currentCharacterIndex:
          currentCharacterIndex ?? this.currentCharacterIndex,
      currentStep: currentStep ?? this.currentStep,
      totalCharacters: totalCharacters ?? this.totalCharacters,
      completedCharacters: completedCharacters ?? this.completedCharacters,
      startStep: startStep ?? this.startStep,
    );
  }
}
