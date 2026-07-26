import 'practice_question.dart';

/// Whether a single question was answered correctly, keyed by the
/// underlying learning item so a completed session's
/// `incorrectItemIds` can drive Weak Items generation later.
class PracticeAnswerRecord {
  const PracticeAnswerRecord({
    required this.questionId,
    required this.itemId,
    required this.contentId,
    required this.wasCorrect,
  });

  final String questionId;
  final String itemId;
  final String contentId;
  final bool wasCorrect;
}

/// In-memory state for an active quiz session. Not persisted — mirrors
/// `LearningSession`'s immutable-state-machine shape but tracks
/// score/answers instead of learning steps. On completion, `PracticeService`
/// reduces this into a persisted `PracticeResult`.
class PracticeSession {
  const PracticeSession({
    required this.modeId,
    required this.questions,
    required this.currentIndex,
    required this.correctAnswers,
    required this.incorrectAnswers,
    required this.startTime,
    this.endTime,
    this.answers = const <PracticeAnswerRecord>[],
  });

  final String modeId;
  final List<PracticeQuestion> questions;
  final int currentIndex;
  final int correctAnswers;
  final int incorrectAnswers;
  final DateTime startTime;
  final DateTime? endTime;
  final List<PracticeAnswerRecord> answers;

  PracticeQuestion? get currentQuestion =>
      currentIndex < questions.length ? questions[currentIndex] : null;

  bool get isComplete => currentIndex >= questions.length;

  double get accuracy {
    final int answered = correctAnswers + incorrectAnswers;
    return answered == 0 ? 0 : (correctAnswers / answered) * 100;
  }

  PracticeSession copyWith({
    int? currentIndex,
    int? correctAnswers,
    int? incorrectAnswers,
    DateTime? endTime,
    List<PracticeAnswerRecord>? answers,
  }) {
    return PracticeSession(
      modeId: modeId,
      questions: questions,
      currentIndex: currentIndex ?? this.currentIndex,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      incorrectAnswers: incorrectAnswers ?? this.incorrectAnswers,
      startTime: startTime,
      endTime: endTime ?? this.endTime,
      answers: answers ?? this.answers,
    );
  }
}
